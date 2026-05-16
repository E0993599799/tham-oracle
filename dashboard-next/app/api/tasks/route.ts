import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { PSI, REPO_ROOT } from '@/lib/repo'

export const dynamic = 'force-dynamic'

interface Task {
  id: string
  name: string
  column: 'inbox' | 'active' | 'outbox' | 'proofs' | 'archive'
  mtime: string
  sizeKB: number
  type: string
}

function scanDir(dir: string, column: Task['column']): Task[] {
  try {
    return fs.readdirSync(dir)
      .filter(f => !f.startsWith('.'))
      .map(f => {
        const abs = path.join(dir, f)
        const stat = fs.statSync(abs)
        return {
          id: `${column}-${f}`,
          name: f.replace(/\.(md|json|txt)$/, ''),
          column,
          mtime: stat.mtime.toISOString(),
          sizeKB: Math.round(stat.size / 1024),
          type: path.extname(f).slice(1) || 'dir',
        }
      })
      .sort((a, b) => b.mtime.localeCompare(a.mtime))
  } catch {
    return []
  }
}

export async function GET() {
  const columns = {
    inbox:   scanDir(path.join(PSI, 'inbox'), 'inbox'),
    active:  scanDir(path.join(PSI, 'active'), 'active'),
    outbox:  scanDir(path.join(PSI, 'outbox'), 'outbox'),
    proofs:  scanDir(path.join(REPO_ROOT, 'brain/proofs'), 'proofs'),
    archive: scanDir(path.join(PSI, 'archive'), 'archive'),
  }
  const total = Object.values(columns).reduce((s, arr) => s + arr.length, 0)
  return NextResponse.json({ columns, total })
}
