import { NextResponse } from 'next/server'
import { spawnSync } from 'child_process'

export const dynamic = 'force-dynamic'

const TIMEOUT = 5000

function tmuxRun(args: string[]): { stdout: string; stderr: string; ok: boolean } {
  const r = spawnSync('tmux', args, { encoding: 'utf8', timeout: TIMEOUT, shell: false })
  return {
    stdout: String(r.stdout ?? '').trimEnd(),
    stderr: String(r.stderr ?? '').trimEnd(),
    ok: r.status === 0,
  }
}

function stripAnsi(str: string): string {
  // eslint-disable-next-line no-control-regex
  return str.replace(/\x1b\[[0-9;]*[mGKHFJABCDEFnsuhl]/g, '').replace(/\x1b\].*?\x07/g, '')
}

function normalizeOutput(str: string): string {
  return stripAnsi(str).replace(/\r\n/g, '\n').replace(/\r/g, '\n')
}

interface Pane {
  target: string
  session: string
  window: string
  paneIndex: string
  cmd: string
  title: string
  active: boolean
}

function comparePaneTargets(a: Pane, b: Pane): number {
  if (a.active !== b.active) return a.active ? -1 : 1
  if (a.session !== b.session) return a.session.localeCompare(b.session)
  if (a.window !== b.window) return a.window.localeCompare(b.window)
  return Number(a.paneIndex) - Number(b.paneIndex)
}

function listPanes(): Pane[] {
  const r = tmuxRun([
    'list-panes', '-a',
    '-F', '#{session_name}|#{window_name}|#{pane_index}|#{pane_current_command}|#{pane_title}|#{pane_active}',
  ])
  if (!r.ok || !r.stdout) return []
  return r.stdout
    .split('\n')
    .filter(Boolean)
    .map(line => {
      const parts = line.split('|')
      const session = parts[0] ?? ''
      const window = parts[1] ?? ''
      const paneIdx = parts[2] ?? '0'
      const cmd = parts[3] ?? '?'
      const title = parts[4] ?? ''
      const active = parts[5] === '1'
      return {
        target: `${session}:${window}.${paneIdx}`,
        session,
        window,
        paneIndex: paneIdx,
        cmd,
        title,
        active,
      }
    })
    .sort(comparePaneTargets)
}

function capturePane(target: string, lines = 200): string {
  const r = tmuxRun(['capture-pane', '-t', target, '-p', '-S', String(-lines)])
  return normalizeOutput(r.stdout)
}

function extractDelta(before: string, after: string): string {
  const beforeLines = before.split('\n')
  const afterLines = after.split('\n')

  let prefix = 0
  while (prefix < beforeLines.length && prefix < afterLines.length && beforeLines[prefix] === afterLines[prefix]) {
    prefix += 1
  }

  const delta = afterLines.slice(prefix).join('\n').trim()
  return delta || after.trim()
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const target = url.searchParams.get('target') ?? ''
  const action = url.searchParams.get('action') ?? 'list'
  const lines = Math.min(Number(url.searchParams.get('lines') ?? '100'), 500)

  const panes = listPanes()

  if (target) {
    const valid = panes.find(p => p.target === target)
    if (!valid) {
      return NextResponse.json({ error: `pane not found: ${target}`, panes }, { status: 404 })
    }
    if (action === 'capture' || action === 'list') {
      const output = capturePane(target, lines)
      return NextResponse.json({ target, output, panes, captured_at: new Date().toISOString() })
    }
  }

  return NextResponse.json({ panes, captured_at: new Date().toISOString() })
}

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}))
  const target = String(body.target ?? '').trim()
  const cmd = String(body.cmd ?? '').trim()
  const delay = Math.min(Number(body.delayMs ?? 500), 3000)
  const beforeLines = Math.min(Number(body.beforeLines ?? 120), 400)
  const afterLines = Math.min(Number(body.afterLines ?? 160), 500)

  if (!target || !cmd) {
    return NextResponse.json({ error: 'target and cmd are required' }, { status: 400 })
  }

  const panes = listPanes()
  const pane = panes.find(p => p.target === target)
  if (!pane) {
    return NextResponse.json({ error: `pane not found: ${target}`, panes }, { status: 404 })
  }

  const beforeOutput = capturePane(target, beforeLines)
  const send = tmuxRun(['send-keys', '-t', target, cmd, 'Enter'])

  await new Promise(resolve => setTimeout(resolve, delay))

  const fullOutput = capturePane(target, afterLines)
  const delta = extractDelta(beforeOutput, fullOutput)

  return NextResponse.json({
    target,
    cmd,
    sent: send.ok,
    send_error: send.stderr || '',
    output: delta,
    delta,
    full_output: fullOutput,
    before_output: beforeOutput,
    sent_at: new Date().toISOString(),
  })
}
