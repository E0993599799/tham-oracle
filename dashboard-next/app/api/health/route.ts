import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import { REPO_ROOT } from '@/lib/repo'

export const dynamic = 'force-dynamic'

// Probe an HTTP URL with timeout, return status + latency
async function probe(url: string, timeoutMs = 2500): Promise<{ ok: boolean; latency: number; code: number; detail: string }> {
  const t0 = Date.now()
  try {
    const ctrl = new AbortController()
    const timer = setTimeout(() => ctrl.abort(), timeoutMs)
    const res = await fetch(url, { signal: ctrl.signal })
    clearTimeout(timer)
    return { ok: res.ok || res.status < 500, latency: Date.now() - t0, code: res.status, detail: '' }
  } catch (e: unknown) {
    return { ok: false, latency: Date.now() - t0, code: 0, detail: e instanceof Error ? e.message : String(e) }
  }
}

function shell(cmd: string): string {
  try { return execSync(cmd, { encoding: 'utf8', timeout: 3000 }).trim() } catch { return '' }
}

export async function GET() {
  const now = new Date().toISOString()

  // === HTTP access points ===
  const httpServices = [
    { name: 'oracle-v2',      label: 'Oracle v2 API',     url: 'http://localhost:47778/',        category: 'service', fix: 'oracle-v2' },
    { name: 'oracle-v2-swagger', label: 'Oracle v2 Swagger', url: 'http://localhost:47778/swagger', category: 'service', fix: 'oracle-v2' },
    { name: 'dashboard',      label: 'Tham Dashboard',    url: 'http://localhost:3005/',         category: 'service', fix: 'dashboard' },
  ]
  const probeResults = await Promise.all(httpServices.map(async s => ({
    ...s,
    type: 'http',
    ...await probe(s.url),
    checked_at: now,
  })))

  // === tmux sessions ===
  const tmuxRaw = shell('tmux ls 2>/dev/null')
  const tmuxSessions = tmuxRaw
    ? tmuxRaw.split('\n').filter(Boolean).map(line => {
        const [name, ...rest] = line.split(':')
        return { name: name.trim(), detail: rest.join(':').trim(), ok: true, type: 'tmux', category: 'runtime', fix: `tmux-${name.trim()}` }
      })
    : [{ name: 'no tmux sessions', detail: '', ok: false, type: 'tmux', category: 'runtime', fix: 'tmux' }]

  // === maw fleet ===
  const mawRaw = shell('maw oracle list 2>/dev/null | head -20')
  const mawOk = mawRaw.length > 0
  const mawOracles = mawOk
    ? mawRaw.split('\n').filter(l => l.includes('●') || l.includes('○')).map(l => ({
        name: l.replace(/\x1b\[[0-9;]*m/g, '').trim(), ok: l.includes('●'), type: 'maw', category: 'fleet', fix: 'maw',
      }))
    : [{ name: 'maw not responding', ok: false, type: 'maw', category: 'fleet', fix: 'maw' }]

  // === watchdog ===
  const watchdogProcs = shell('ps aux | grep -E "(watchdog|housekeeper)" | grep -v grep')
  const watchdogItems = watchdogProcs
    ? watchdogProcs.split('\n').filter(Boolean).map(l => {
        const parts = l.trim().split(/\s+/)
        return { name: parts.slice(10).join(' ').slice(0, 60), pid: parts[1], ok: true, type: 'process', category: 'watchdog', fix: 'watchdog' }
      })
    : [{ name: 'watchdog not running', pid: '', ok: false, type: 'process', category: 'watchdog', fix: 'watchdog' }]

  // === git + tools runtime ===
  const gitHead   = shell(`git -C ${REPO_ROOT} log -1 --format="%h %s" 2>/dev/null`)
  const gitStatus = shell(`git -C ${REPO_ROOT} status --short 2>/dev/null | wc -l`).trim()
  const bunVer    = shell('bun --version 2>/dev/null')
  const nodeVer   = shell('node --version 2>/dev/null')
  const ghVer     = shell('gh --version 2>/dev/null | head -1')
  const mawVer    = shell('maw --version 2>/dev/null || echo ""')

  const runtimes = [
    { name: 'git',  detail: gitHead,  ok: !!gitHead,  type: 'tool', category: 'runtime', fix: 'git' },
    { name: 'bun',  detail: bunVer,   ok: !!bunVer,   type: 'tool', category: 'runtime', fix: '' },
    { name: 'node', detail: nodeVer,  ok: !!nodeVer,  type: 'tool', category: 'runtime', fix: '' },
    { name: 'gh',   detail: ghVer,    ok: !!ghVer,    type: 'tool', category: 'runtime', fix: '' },
    { name: 'maw',  detail: mawVer,   ok: !!mawVer,   type: 'tool', category: 'runtime', fix: 'maw-install' },
  ]

  const allItems = [...probeResults, ...tmuxSessions, ...runtimes, ...watchdogItems]
  const summary = {
    total:     allItems.length,
    healthy:   allItems.filter((x: { ok: boolean }) => x.ok).length,
    unhealthy: allItems.filter((x: { ok: boolean }) => !x.ok).length,
    git_dirty: parseInt(gitStatus) || 0,
  }

  return NextResponse.json({
    checked_at: now,
    summary,
    http: probeResults,
    tmux: tmuxSessions,
    fleet: mawOracles,
    watchdog: watchdogItems,
    runtimes,
  })
}
