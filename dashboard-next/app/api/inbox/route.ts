import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { REPO_ROOT, PSI } from '@/lib/repo'

export const dynamic = 'force-dynamic'

interface FileEntry {
  name: string
  mtime: string
  sizeKB: number
}

function listWithMeta(dir: string, limit = 5): FileEntry[] {
  try {
    return fs.readdirSync(dir)
      .filter(f => !f.startsWith('.'))
      .map(f => {
        const abs = path.join(dir, f)
        const stat = fs.statSync(abs)
        return { name: f, mtime: stat.mtime.toISOString(), sizeKB: Math.round(stat.size / 1024) }
      })
      .sort((a, b) => b.mtime.localeCompare(a.mtime))
      .slice(0, limit)
  } catch {
    return []
  }
}

function countMd(dir: string): number {
  try { return fs.readdirSync(dir).filter(f => !f.startsWith('.')).length } catch { return 0 }
}

export async function GET() {
  return NextResponse.json({
    inbox:  { count: countMd(path.join(PSI, 'inbox')),  files: listWithMeta(path.join(PSI, 'inbox'), 5) },
    outbox: { count: countMd(path.join(PSI, 'outbox')), files: listWithMeta(path.join(PSI, 'outbox'), 5) },
    proofs: { count: countMd(path.join(REPO_ROOT, 'brain/proofs')), files: listWithMeta(path.join(REPO_ROOT, 'brain/proofs'), 5) },
    active: { count: countMd(path.join(PSI, 'active')), files: listWithMeta(path.join(PSI, 'active'), 5) },
  })
}
