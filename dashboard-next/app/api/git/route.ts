import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import { REPO_ROOT, EXEC_OPTS } from '@/lib/repo'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const log = execSync(
      `git log -15 --pretty=format:"%h|%s|%an|%ar"`,
      { ...EXEC_OPTS, cwd: REPO_ROOT }
    ).trim()

    const commits = log.split('\n').filter(Boolean).map(line => {
      const [hash, subject, author, ago] = line.split('|')
      return { hash, subject, author, ago }
    })

    const branch = execSync('git branch --show-current', { ...EXEC_OPTS }).trim()
    const dirty  = execSync('git status --short', { ...EXEC_OPTS }).trim()

    return NextResponse.json({
      commits,
      branch,
      dirtyFiles: dirty ? dirty.split('\n').filter(Boolean).length : 0,
    })
  } catch (e) {
    return NextResponse.json({ commits: [], branch: '', dirtyFiles: 0, error: String(e) })
  }
}
