import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import { REPO_ROOT } from '@/lib/repo'

export const dynamic = 'force-dynamic'

const WIKI_FILES = [
  { key: 'home', title: 'wiki/home.md', rel: 'wiki/home.md' },
  { key: 'index', title: 'wiki/index.md', rel: 'wiki/index.md' },
  { key: 'hot', title: 'wiki/hot.md', rel: 'wiki/hot.md' },
  { key: 'log', title: 'wiki/log.md', rel: 'wiki/log.md' },
  { key: 'decisions', title: 'wiki/decisions.md', rel: 'wiki/decisions.md' },
  { key: 'questions', title: 'wiki/questions.md', rel: 'wiki/questions.md' },
  { key: 'obsidian-memory', title: 'wiki/domains/obsidian-memory/index.md', rel: 'wiki/domains/obsidian-memory/index.md' },
]

const VAULT_CANDIDATES = [
  process.env.OBSIDIAN_VAULT_PATH,
  '/mnt/d/obsidian',
  '/mnt/d/Obsidian',
  path.join(REPO_ROOT, 'obsidian'),
].filter((v): v is string => Boolean(v))

function firstExistingPath(candidates: string[]): string {
  for (const candidate of candidates) {
    try {
      if (fs.existsSync(candidate)) return candidate
    } catch {
      // ignore
    }
  }
  return candidates[0] ?? '/mnt/d/obsidian'
}

function readText(filePath: string): string {
  try {
    return fs.readFileSync(filePath, 'utf8')
  } catch {
    return ''
  }
}

function safeStat(filePath: string) {
  try {
    const stat = fs.statSync(filePath)
    return {
      exists: true,
      mtime: stat.mtime.toISOString(),
      sizeKB: Math.max(0, Math.round((stat.size / 1024) * 10) / 10),
    }
  } catch {
    return { exists: false, mtime: '', sizeKB: 0 }
  }
}

function previewLines(content: string, max = 4): string[] {
  return content
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .filter(line => !line.startsWith('---'))
    .slice(0, max)
}

function pickHighlights(content: string, patterns: RegExp[], limit = 8): string[] {
  const lines = content
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .filter(line => !line.startsWith('---'))
  const matches = lines.filter(line => patterns.some(pattern => pattern.test(line)))
  return matches.slice(0, limit)
}

export async function GET() {
  try {
    const vaultPath = firstExistingPath(VAULT_CANDIDATES)
    const wikiRoot = path.join(vaultPath, 'wiki')

    const notes = WIKI_FILES.map(file => {
      const abs = path.join(vaultPath, file.rel)
      const stat = safeStat(abs)
      const content = stat.exists ? readText(abs) : ''
      return {
        key: file.key,
        title: file.title,
        path: abs,
        exists: stat.exists,
        mtime: stat.mtime,
        sizeKB: stat.sizeKB,
        preview: previewLines(content, 4),
      }
    })

    const hotContent = readText(path.join(wikiRoot, 'hot.md'))
    const logContent = readText(path.join(wikiRoot, 'log.md'))

    const hotHighlights = pickHighlights(hotContent, [
      /omega/i,
      /oracle/i,
      /bridge/i,
      /obsidian/i,
      /tham/i,
      /hermes/i,
      /active/i,
    ], 8)

    const logHighlights = pickHighlights(logContent, [
      /omega/i,
      /oracle/i,
      /obsidian/i,
      /bridge/i,
      /dashboard/i,
      /memory/i,
      /index/i,
      /hot/i,
    ], 8)

    const wikiReady = notes.slice(0, 4).every(note => note.exists)
    const bridgeReady = wikiReady && hotHighlights.length > 0 && logHighlights.length > 0

    return NextResponse.json({
      vaultPath,
      wikiReady,
      bridgeReady,
      notes,
      hotHighlights,
      logHighlights,
    })
  } catch (error) {
    return NextResponse.json({
      vaultPath: '/mnt/d/obsidian',
      wikiReady: false,
      bridgeReady: false,
      notes: [],
      hotHighlights: [],
      logHighlights: [],
      error: String(error),
    }, { status: 500 })
  }
}
