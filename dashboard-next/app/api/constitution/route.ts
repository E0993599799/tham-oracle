import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import os from 'os'

export const dynamic = 'force-dynamic'

const REPO_ROOT = process.env.THAM_REPO_ROOT ||
  path.join(os.homedir(), 'ghq/github.com/E0993599799/tham-oracle')

interface ConstitutionRule {
  id: string
  title: string
  description: string
  index: number
}

export async function GET() {
  const filePath = path.join(REPO_ROOT, 'brain/identity/constitution.md')

  let content: string
  try {
    content = fs.readFileSync(filePath, 'utf8')
  } catch {
    return NextResponse.json({ rules: [], error: 'constitution.md not found' })
  }

  const rules: ConstitutionRule[] = []
  const lines = content.split('\n')
  let i = 0
  let index = 0

  while (i < lines.length) {
    const line = lines[i]
    // Match "## Rule C-XX: Title"
    const match = line.match(/^## Rule (C-\d{2}):\s*(.+)$/)
    if (match) {
      const id = match[1]
      const title = match[2].trim()
      // Grab first non-empty line of the body (bold definition line or first paragraph)
      let description = ''
      let j = i + 1
      while (j < lines.length && lines[j].trim() === '') j++
      if (j < lines.length) {
        // Strip markdown bold markers
        description = lines[j].replace(/\*\*/g, '').trim()
        // If it starts with "NEVER" or "ALWAYS" use it; otherwise try next non-empty
        if (!description || description.startsWith('##')) {
          description = ''
        }
      }
      rules.push({ id, title, description, index })
      index++
    }
    i++
  }

  return NextResponse.json({ rules, total: rules.length })
}
