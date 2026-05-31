import { execSync } from 'child_process'
import fs from 'fs'
import { PSI, EXEC_OPTS } from '@/lib/repo'

export const dynamic = 'force-dynamic'

interface SseEvent {
  type: 'fleet' | 'tasks' | 'health'
  payload: unknown
}

function send(controller: ReadableStreamDefaultController, event: SseEvent): void {
  const data = `data: ${JSON.stringify(event)}\n\n`
  controller.enqueue(new TextEncoder().encode(data))
}

function safeExec(cmd: string): string {
  try {
    return execSync(cmd, { ...EXEC_OPTS, timeout: 5000 }).trim()
  } catch {
    return ''
  }
}

function getFleetPayload(): unknown {
  try {
    const out = safeExec('maw oracle ls 2>/dev/null || echo "[]"')
    return { raw: out, updatedAt: new Date().toISOString() }
  } catch {
    return { raw: '', updatedAt: new Date().toISOString() }
  }
}

function getTasksPayload(): unknown {
  try {
    const inboxPath = `${PSI}/inbox`
    if (!fs.existsSync(inboxPath)) return { files: [], updatedAt: new Date().toISOString() }
    const files = fs.readdirSync(inboxPath).filter(f => !f.startsWith('.')).map(f => ({
      name: f,
      mtime: fs.statSync(`${inboxPath}/${f}`).mtime.toISOString(),
    }))
    return { files, count: files.length, updatedAt: new Date().toISOString() }
  } catch {
    return { files: [], updatedAt: new Date().toISOString() }
  }
}

function getHealthPayload(): unknown {
  const services = [
    { name: 'dashboard', port: 3000, url: 'http://127.0.0.1:3000' },
    { name: 'mission-control', port: 3005, url: 'http://127.0.0.1:3005' },
  ]
  const results = services.map(svc => {
    try {
      const out = safeExec(`curl -s -o /dev/null -w "%{http_code}" --max-time 3 ${svc.url} 2>/dev/null`)
      const code = parseInt(out, 10)
      return { ...svc, ok: code > 0 && code < 500, code }
    } catch {
      return { ...svc, ok: false, code: 0 }
    }
  })
  return { services: results, checkedAt: new Date().toISOString() }
}

export async function GET(req: Request): Promise<Response> {
  const timers: ReturnType<typeof setInterval>[] = []

  const stream = new ReadableStream({
    start(controller) {
      // Initial push
      send(controller, { type: 'tasks',  payload: getTasksPayload() })
      send(controller, { type: 'fleet',  payload: getFleetPayload() })
      send(controller, { type: 'health', payload: getHealthPayload() })

      // Watch ψ/inbox/ for task changes (poll every 5s as fs.watch is unreliable in WSL)
      timers.push(setInterval(() => {
        try { send(controller, { type: 'tasks', payload: getTasksPayload() }) } catch { /* stream closed */ }
      }, 5000))

      // Fleet status every 5s
      timers.push(setInterval(() => {
        try { send(controller, { type: 'fleet', payload: getFleetPayload() }) } catch { /* stream closed */ }
      }, 5000))

      // Health every 10s
      timers.push(setInterval(() => {
        try { send(controller, { type: 'health', payload: getHealthPayload() }) } catch { /* stream closed */ }
      }, 10000))
    },
    cancel() {
      timers.forEach(t => clearInterval(t))
    },
  })

  req.signal.addEventListener('abort', () => {
    timers.forEach(t => clearInterval(t))
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
    },
  })
}
