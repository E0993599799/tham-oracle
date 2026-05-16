import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'
import { REPO_ROOT, EXEC_OPTS } from '@/lib/repo'

export const dynamic = 'force-dynamic'

const FILES = [
  { key: 'ACTIVE_INDEX', rel: 'brain/memory/ACTIVE_INDEX.md', maxAge: 3600 },
  { key: 'oracle.md',    rel: 'ψ/memory/resonance/oracle.md',  maxAge: 3600 },
  { key: 'profile.md',  rel: 'brain/identity/profile.md',      maxAge: 7200 },
]

export async function GET() {
  const results = FILES.map(f => {
    const abs = path.join(REPO_ROOT, f.rel)
    const exists = fs.existsSync(abs)
    let hash = ''
    let lastModified = ''
    let sizeKB = 0
    let snippet = ''

    if (exists) {
      try {
        hash = execSync(`git log -1 --format="%h" -- "${f.rel}"`, { ...EXEC_OPTS }).trim()
        lastModified = execSync(`git log -1 --format="%ar" -- "${f.rel}"`, { ...EXEC_OPTS }).trim()
        sizeKB = Math.round(fs.statSync(abs).size / 1024)
        snippet = fs.readFileSync(abs, 'utf8').split('\n').slice(0, 2).join(' ').slice(0, 120)
      } catch {}
    }

    return { key: f.key, path: f.rel, exists, hash: hash || '—', lastModified, sizeKB, snippet, maxAge: f.maxAge }
  })

  const constPath = path.join(REPO_ROOT, 'brain/identity/constitution.md')
  let constitutionRules: string[] = []
  if (fs.existsSync(constPath)) {
    const content = fs.readFileSync(constPath, 'utf8')
    constitutionRules = (content.match(/## Rule (C-\d+): (.+)/g) || [])
      .map(m => m.replace('## Rule ', ''))
  }

  return NextResponse.json({ files: results, constitutionRules })
}
