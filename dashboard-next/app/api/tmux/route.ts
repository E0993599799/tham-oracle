import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export const dynamic = 'force-dynamic'

function safeExec(cmd: string): string {
  try {
    return execSync(cmd, { encoding: 'utf8', timeout: 5000 }).trim()
  } catch {
    return ''
  }
}

export async function GET(): Promise<NextResponse> {
  try {
    const raw = safeExec('tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null')
    if (!raw) {
      return NextResponse.json({ sessions: [], error: 'No tmux sessions found or tmux not running' })
    }
    const sessions = raw.split('\n').filter(Boolean).map(line => {
      const [name, windows, attached] = line.split('|')
      return { name: name ?? '', windows: parseInt(windows ?? '0', 10), attached: attached === '1' }
    })
    return NextResponse.json({ sessions })
  } catch (e) {
    return NextResponse.json({ sessions: [], error: String(e) }, { status: 500 })
  }
}
