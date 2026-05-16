import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { REPO_ROOT, PSI } from '@/lib/repo'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const metricsPath = path.join(PSI, 'memory/learnings/session-metrics.md')
    let rows: object[] = []
    if (fs.existsSync(metricsPath)) {
      const content = fs.readFileSync(metricsPath, 'utf8')
      const lines = content.split('\n').filter(l => l.startsWith('|') && !l.includes('---') && !l.includes('when'))
      rows = lines.slice(-10).map(line => {
        const cols = line.split('|').map(c => c.trim()).filter(Boolean)
        return { when: cols[0]||'', session: cols[1]||'', done: cols[2]||'', stuck: cols[3]||'', win: cols[4]||'', friction: cols[5]||'', error: cols[6]||'' }
      }).reverse()
    }

    const today = new Date().toISOString().slice(0, 10)
    const dd = today.slice(8, 10)
    const mm = today.slice(0, 7)

    let retrosToday = 0
    const retroDir = path.join(PSI, `memory/retrospectives/${mm}/${dd}`)
    try { retrosToday = fs.readdirSync(retroDir).filter(f => f.endsWith('.md')).length } catch {}

    let learningsThisMonth = 0
    try {
      learningsThisMonth = fs.readdirSync(path.join(PSI, 'memory/learnings'))
        .filter(f => f.startsWith(mm) && f.endsWith('.md')).length
    } catch {}

    // Also count from brain/reflections
    let brainLearnings = 0
    try {
      brainLearnings = fs.readdirSync(path.join(REPO_ROOT, 'brain/reflections'))
        .filter(f => f.endsWith('.md')).length
    } catch {}

    return NextResponse.json({ rows, retrosToday, learningsThisMonth, brainLearnings })
  } catch (e) {
    return NextResponse.json({ rows: [], retrosToday: 0, learningsThisMonth: 0, brainLearnings: 0, error: String(e) })
  }
}
