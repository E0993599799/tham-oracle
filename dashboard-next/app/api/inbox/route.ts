import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { REPO_ROOT, PSI } from '@/lib/repo'

export const dynamic = 'force-dynamic'

function countMd(dir: string): number {
  try { return fs.readdirSync(dir).filter(f => f.endsWith('.md')).length } catch { return 0 }
}
function listFiles(dir: string, limit = 5): string[] {
  try { return fs.readdirSync(dir).filter(f => !f.startsWith('.')).slice(-limit).reverse() } catch { return [] }
}

export async function GET() {
  return NextResponse.json({
    inbox:  { count: countMd(path.join(PSI, 'inbox')),  files: listFiles(path.join(PSI, 'inbox'), 3) },
    outbox: { count: countMd(path.join(PSI, 'outbox')), files: listFiles(path.join(PSI, 'outbox'), 3) },
    proofs: { count: countMd(path.join(REPO_ROOT, 'brain/proofs')), recent: listFiles(path.join(REPO_ROOT, 'brain/proofs'), 3) },
    active: { count: countMd(path.join(PSI, 'active')), files: listFiles(path.join(PSI, 'active'), 3) },
  })
}
