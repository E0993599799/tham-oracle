import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import fs from 'fs'
import os from 'os'
import path from 'path'
import { EXEC_OPTS } from '@/lib/repo'

export const dynamic = 'force-dynamic'

function daysSince(dateStr: string): number {
  if (!dateStr) return 9999
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return 9999
  return Math.floor((Date.now() - d.getTime()) / 86400000)
}

function statusDot(days: number): string {
  if (days < 7)   return '🟢'
  if (days < 30)  return '🟡'
  if (days < 90)  return '🟠'
  if (days < 999) return '🔴'
  return '⚪'
}

function safeExec(cmd: string, cwd: string): string {
  try {
    return execSync(cmd, { ...EXEC_OPTS, cwd, timeout: 3000 }).trim()
  } catch {
    return ''
  }
}

export async function GET() {
  try {
    const configPath = path.join(os.homedir(), '.config/maw/oracles.json')
    if (!fs.existsSync(configPath)) {
      return NextResponse.json({ oracles: [], summary: { total: 0, active: 0, stale: 0, cold: 0, abandoned: 0, zygote: 0 }, error: 'oracles.json not found' })
    }

    const raw = JSON.parse(fs.readFileSync(configPath, 'utf8'))
    const list: Record<string, string>[] = Array.isArray(raw) ? raw : (raw.oracles || [])

    const oracles = list.map(o => {
      const repoPath = o.local_path || o.path || ''
      const exists = repoPath && fs.existsSync(repoPath)

      let lastCommit = ''
      let branch = ''
      let hasAwaken = false

      if (exists) {
        lastCommit = safeExec('git log -1 --format="%ai"', repoPath)
        branch     = safeExec('git branch --show-current', repoPath)
        const awakenOut = safeExec('ls ψ/memory/resonance/ 2>/dev/null | grep -c awaken || echo 0', repoPath)
        hasAwaken  = parseInt(awakenOut) > 0
      }

      const days = daysSince(lastCommit)
      return {
        name: o.name || o.repo || path.basename(repoPath),
        path: repoPath,
        branch,
        lastCommit,
        days,
        status: statusDot(days),
        hasAwaken,
        exists: !!exists,
      }
    })

    const summary = {
      total:     oracles.length,
      active:    oracles.filter(o => o.days < 7).length,
      stale:     oracles.filter(o => o.days >= 7  && o.days < 30).length,
      cold:      oracles.filter(o => o.days >= 30 && o.days < 90).length,
      abandoned: oracles.filter(o => o.days >= 90 && o.days < 999).length,
      zygote:    oracles.filter(o => o.days === 9999).length,
    }

    return NextResponse.json({ oracles, summary })
  } catch (e) {
    return NextResponse.json({ oracles: [], summary: { total: 0, active: 0, stale: 0, cold: 0, abandoned: 0, zygote: 0 }, error: String(e) })
  }
}
