import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import { REPO_ROOT } from '@/lib/repo'

export const dynamic = 'force-dynamic'

const R = `"${REPO_ROOT}"`  // quoted for shell — REPO_ROOT contains spaces

const FIX_COMMANDS: Record<string, { cmd: string; safe: boolean; description: string }> = {
  'oracle-v2': {
    cmd: `bash ${R}/scripts/start-oracle-v2-http.sh`,
    safe: true,
    description: 'Restart oracle-v2 HTTP server on port 47778',
  },
  'dashboard': {
    cmd: `bash ${R}/scripts/start-tham-dashboard.sh 3005 &`,
    safe: true,
    description: 'Restart Tham dashboard on port 3005',
  },
  'watchdog': {
    cmd: `bash ${R}/scripts/housekeeper-run.sh 2>/dev/null || echo "housekeeper script not found"`,
    safe: true,
    description: 'Run housekeeper to restore watchdog',
  },
  'tmux': {
    cmd: `tmux new-session -d -s tham 2>/dev/null && echo "tham session created"`,
    safe: true,
    description: 'Create default tmux session',
  },
  'maw-install': {
    cmd: `which maw || echo "maw not in PATH — install via npm/bun globally"`,
    safe: true,
    description: 'Check maw CLI installation',
  },
}

function diagnose(service: string): string {
  const checks: string[] = []
  try {
    if (service === 'oracle-v2') {
      const port = execSync('lsof -i:47778 2>/dev/null | head -3', { encoding: 'utf8', timeout: 2000 }).trim()
      checks.push(port ? `Port 47778 in use by: ${port}` : 'Port 47778: nothing listening')
      const proc = execSync('ps aux | grep oracle | grep -v grep | head -3', { encoding: 'utf8', timeout: 2000 }).trim()
      checks.push(proc ? `Oracle processes: ${proc}` : 'No oracle processes found')
    }
    if (service === 'dashboard') {
      const port = execSync('lsof -i:3005 2>/dev/null | head -3', { encoding: 'utf8', timeout: 2000 }).trim()
      checks.push(port ? `Port 3005: ${port}` : 'Port 3005: nothing listening')
    }
  } catch {
    // ignore errors in diagnostics
  }
  return checks.join('\n') || 'No specific diagnostics available'
}

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}))
  const service = body.service as string

  if (!service) {
    return NextResponse.json({ error: 'service field required' }, { status: 400 })
  }

  const diagnosis = diagnose(service)
  const fix = FIX_COMMANDS[service]

  if (!fix) {
    return NextResponse.json({
      service,
      status: 'no_fix_available',
      diagnosis,
      message: `No automated fix configured for "${service}". Diagnosis:\n${diagnosis}`,
      agent_prompt: `ธาม: service "${service}" is unhealthy. Diagnosis: ${diagnosis}. Find root cause and propose fix.`,
    })
  }

  let fixOutput = ''
  let fixError = ''
  try {
    fixOutput = execSync(fix.cmd, { encoding: 'utf8', timeout: 5000, cwd: REPO_ROOT }).trim()
  } catch (e) {
    fixError = String(e)
  }

  return NextResponse.json({
    service,
    status: fixError ? 'fix_attempted_with_error' : 'fix_attempted',
    description: fix.description,
    diagnosis,
    fix_output: fixOutput,
    fix_error: fixError,
    agent_prompt: `ธาม: "${service}" was unhealthy. Fix attempted: ${fix.description}. Output: ${fixOutput || fixError}. Verify it is now healthy and report next steps.`,
    checked_at: new Date().toISOString(),
  })
}
