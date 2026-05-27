import { NextResponse } from 'next/server'
import { spawnSync } from 'child_process'
import { REPO_ROOT } from '@/lib/repo'
import { getCommandExecution, isCommandId } from '@/lib/command-catalog'

export const dynamic = 'force-dynamic'

function cap(text: string, max = 12000): string {
  if (text.length <= max) return text
  return `${text.slice(0, max)}\n…<truncated>`
}

export async function POST(req: Request) {
  const startedAt = Date.now()
  const body = await req.json().catch(() => ({}))
  const commandId = String(body.commandId || '')

  if (!isCommandId(commandId)) {
    return NextResponse.json(
      {
        error: 'commandId must be one of the allowlisted dashboard commands',
      },
      { status: 400 }
    )
  }

  const spec = getCommandExecution(commandId, REPO_ROOT)
  if (!spec) {
    return NextResponse.json(
      {
        error: `No execution spec found for commandId: ${commandId}`,
      },
      { status: 404 }
    )
  }

  const result = spawnSync(spec.executable, spec.args, {
    cwd: spec.cwd ?? REPO_ROOT,
    encoding: 'utf8',
    timeout: spec.timeoutMs,
    shell: false,
    env: {
      ...process.env,
      ...(spec.env ?? {}),
    },
  })

  const stdout = cap(String(result.stdout ?? '').trimEnd())
  const stderr = cap(String(result.stderr ?? '').trimEnd())
  const durationMs = Date.now() - startedAt

  return NextResponse.json({
    commandId,
    executable: spec.executable,
    args: spec.args,
    cwd: spec.cwd ?? REPO_ROOT,
    stdout,
    stderr,
    exitCode: typeof result.status === 'number' ? result.status : null,
    signal: result.signal ?? null,
    durationMs,
    checked_at: new Date().toISOString(),
    ok: typeof result.status === 'number' ? result.status === 0 : false,
    error: result.error ? String(result.error) : '',
  })
}
