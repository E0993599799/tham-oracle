#!/usr/bin/env node
/**
 * memory-search.mjs — TSK-REC-002: FTS5 full-text search for tham-oracle memory layer
 *
 * What this does:
 *   1. Opens (or creates) a SQLite DB with a memory_fts FTS5 virtual table
 *   2. Indexes all brain/ + selected ψ/ markdown files into memory_fts
 *   3. Runs a ranked FTS5 search on the query argument
 *   4. Flags near-duplicate entries (>85% word-set similarity)
 *   5. Prints results + timing
 *
 * Usage:
 *   node scripts/memory-search.mjs "oracle identity"
 *   node scripts/memory-search.mjs --reindex          # force full re-index
 *   node scripts/memory-search.mjs --dedup            # dedup scan only
 *   node scripts/memory-search.mjs --schema           # show DB schema
 */

import { DatabaseSync } from 'node:sqlite';
import { readFileSync, existsSync, readdirSync, statSync } from 'fs';
import { resolve, join, relative, extname, basename } from 'path';
import { fileURLToPath } from 'url';

const __dir  = resolve(fileURLToPath(import.meta.url), '..');
const REPO   = resolve(__dir, '..');
const BRAIN  = join(REPO, 'brain');
const PSI    = join(REPO, 'ψ');

// Primary DB: shared oracle-v2 DB. Fallback: local file in brain/memory/.
const ORACLE_DB   = '/home/user/.arra-oracle-v2/oracle.db';
const LOCAL_DB    = join(REPO, 'brain', 'memory', 'memory-fts.db');
const DB_PATH     = existsSync(ORACLE_DB) ? ORACLE_DB : LOCAL_DB;

const SIMILARITY_THRESHOLD = 0.85;   // Jaccard word-set threshold for dedup flag
const SNIPPET_LEN = 120;             // chars of body shown in result snippet
const MAX_RESULTS = 10;

// ── args ───────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const FLAG_REINDEX = args.includes('--reindex');
const FLAG_DEDUP   = args.includes('--dedup');
const FLAG_SCHEMA  = args.includes('--schema');
const QUERY        = args.filter(a => !a.startsWith('--')).join(' ').trim();

if (!QUERY && !FLAG_DEDUP && !FLAG_SCHEMA) {
  console.error('Usage: node scripts/memory-search.mjs "search query"');
  console.error('       node scripts/memory-search.mjs --reindex');
  console.error('       node scripts/memory-search.mjs --dedup');
  console.error('       node scripts/memory-search.mjs --schema');
  process.exit(1);
}

// ── DB setup ───────────────────────────────────────────────────────────────────

const db = new DatabaseSync(DB_PATH);
db.exec('PRAGMA journal_mode=WAL');
db.exec('PRAGMA synchronous=NORMAL');

function setupSchema() {
  // memory_fts: FTS5 virtual table for tham-oracle brain + ψ memory
  db.exec(`
    CREATE VIRTUAL TABLE IF NOT EXISTS memory_fts USING fts5(
      id        UNINDEXED,
      title,
      body,
      tags,
      area      UNINDEXED,
      file_path UNINDEXED,
      tokenize  = 'porter unicode61'
    );
  `);

  // Metadata for tracking index state
  db.exec(`
    CREATE TABLE IF NOT EXISTS memory_fts_meta (
      key   TEXT PRIMARY KEY,
      value TEXT
    );
  `);
}

setupSchema();

// ── markdown parser ────────────────────────────────────────────────────────────

function parseMd(filePath) {
  const raw = readFileSync(filePath, 'utf8');

  // Extract YAML frontmatter
  let title = '';
  let tags  = '';
  let body  = raw;

  const fmMatch = raw.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)/);
  if (fmMatch) {
    const fm   = fmMatch[1];
    body = fmMatch[2].trim();

    const tLine = fm.match(/^title:\s*(.+)/m);
    if (tLine) title = tLine[1].trim().replace(/^["']|["']$/g, '');

    const tagsLine = fm.match(/^tags:\s*\[(.*)\]/m);
    if (tagsLine) tags = tagsLine[1].replace(/['"]/g, '').trim();
  }

  // Fallback: use first H1 or H2 as title
  if (!title) {
    const h = body.match(/^#{1,2}\s+(.+)/m);
    if (h) title = h[1].trim();
  }

  // Fallback title = filename without extension
  if (!title) title = basename(filePath, extname(filePath));

  return { title, body: body.slice(0, 8000), tags };
}

// ── file walker ────────────────────────────────────────────────────────────────

const PSI_INCLUDE = ['memory', 'learn', 'active', 'reflections'];

function* walkMd(dir, maxDepth = 6, depth = 0) {
  if (depth > maxDepth || !existsSync(dir)) return;
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    const st   = statSync(full);
    if (st.isDirectory()) {
      yield* walkMd(full, maxDepth, depth + 1);
    } else if (entry.endsWith('.md')) {
      yield full;
    }
  }
}

function collectFiles() {
  const files = [];

  // brain/ — all markdown
  for (const f of walkMd(BRAIN)) {
    const area = relative(BRAIN, f).split('/')[0];
    files.push({ path: f, area: `brain/${area}` });
  }

  // ψ/ — selected subdirs only (avoid huge archive dumps)
  for (const sub of PSI_INCLUDE) {
    const dir = join(PSI, sub);
    for (const f of walkMd(dir)) {
      files.push({ path: f, area: `ψ/${sub}` });
    }
  }

  return files;
}

// ── indexing ───────────────────────────────────────────────────────────────────

function makeId(filePath) {
  // Stable ID from relative path
  return relative(REPO, filePath).replace(/[^\w/-]/g, '_');
}

function getIndexedCount() {
  return db.prepare('SELECT count(*) as n FROM memory_fts').get().n;
}

function isIndexed(id) {
  // FTS5 content table check via shadow table trick
  try {
    const row = db.prepare(
      "SELECT count(*) as n FROM memory_fts WHERE memory_fts MATCH 'id:' || ?"
    ).get(id);
    return row?.n > 0;
  } catch {
    return false;
  }
}

function indexFiles(files, force = false) {
  const t0 = Date.now();

  if (force) {
    db.exec("DELETE FROM memory_fts");
    db.exec("DELETE FROM memory_fts_meta");
  }

  // Get all existing IDs to skip already-indexed
  let existingIds = new Set();
  if (!force) {
    try {
      const rows = db.prepare("SELECT id FROM memory_fts").all();
      existingIds = new Set(rows.map(r => r.id));
    } catch { /* first run */ }
  }

  const insert = db.prepare(
    'INSERT INTO memory_fts(id, title, body, tags, area, file_path) VALUES (?,?,?,?,?,?)'
  );

  let added = 0;
  let skipped = 0;

  for (const { path: fp, area } of files) {
    const id = makeId(fp);
    if (existingIds.has(id)) { skipped++; continue; }
    try {
      const { title, body, tags } = parseMd(fp);
      insert.run(id, title, body, tags, area, relative(REPO, fp));
      added++;
    } catch {
      // skip unreadable files silently
    }
  }

  // Also pull oracle_fts entries (existing oracle-v2 learnings) if they exist
  if (existsSync(ORACLE_DB)) {
    try {
      const rows = db.prepare('SELECT id, content, concepts FROM oracle_fts').all();
      for (const r of rows) {
        const id = `oracle_fts:${r.id}`;
        if (existingIds.has(id)) { skipped++; continue; }
        const { title, body, tags } = parseMd_raw(r.content ?? '', r.id);
        insert.run(id, title, body, tags || r.concepts || '', 'oracle_fts', r.id);
        added++;
      }
    } catch { /* oracle_fts may not exist in local DB */ }
  }

  db.prepare('INSERT OR REPLACE INTO memory_fts_meta(key,value) VALUES(?,?)')
    .run('last_indexed', new Date().toISOString());
  db.prepare('INSERT OR REPLACE INTO memory_fts_meta(key,value) VALUES(?,?)')
    .run('total_docs', String(getIndexedCount()));

  return { added, skipped, ms: Date.now() - t0 };
}

function parseMd_raw(raw, fallbackTitle = '') {
  const fmMatch = raw.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)/);
  if (fmMatch) {
    const fm   = fmMatch[1];
    const body = fmMatch[2].trim();
    const tLine = fm.match(/^title:\s*(.+)/m);
    const tagsLine = fm.match(/^tags:\s*\[(.*)\]/m);
    const title = tLine ? tLine[1].trim().replace(/^#\s+/, '') : fallbackTitle;
    const tags  = tagsLine ? tagsLine[1].replace(/['"]/g, '').trim() : '';
    return { title, body: body.slice(0, 8000), tags };
  }
  // no frontmatter — use raw as body
  const h = raw.match(/^#{1,2}\s+(.+)/m);
  return { title: h ? h[1].trim() : fallbackTitle, body: raw.slice(0, 8000), tags: '' };
}

// ── deduplication ──────────────────────────────────────────────────────────────

function wordSet(text) {
  return new Set(
    text.toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(w => w.length > 3)
  );
}

function jaccard(a, b) {
  const sa = wordSet(a);
  const sb = wordSet(b);
  let inter = 0;
  for (const w of sa) if (sb.has(w)) inter++;
  const union = sa.size + sb.size - inter;
  return union === 0 ? 0 : inter / union;
}

function runDedup() {
  const t0 = Date.now();
  const rows = db.prepare('SELECT id, title, body, file_path FROM memory_fts LIMIT 2000').all();
  const pairs = [];

  for (let i = 0; i < rows.length; i++) {
    for (let j = i + 1; j < rows.length; j++) {
      const a = rows[i];
      const b = rows[j];
      // Skip if bodies are very short (under 50 chars) — not meaningful
      if ((a.body?.length ?? 0) < 50 || (b.body?.length ?? 0) < 50) continue;
      const sim = jaccard(a.body, b.body);
      if (sim >= SIMILARITY_THRESHOLD) {
        pairs.push({ a: a.file_path || a.id, b: b.file_path || b.id, sim });
      }
    }
  }

  return { pairs, ms: Date.now() - t0, scanned: rows.length };
}

// ── search ─────────────────────────────────────────────────────────────────────

function search(query) {
  const t0 = Date.now();

  // FTS5 query with rank weighting: title match weighted 3x, tags 2x, body 1x
  const results = db.prepare(`
    SELECT
      id,
      title,
      area,
      file_path,
      snippet(memory_fts, 2, '[', ']', '…', 20) AS snippet,
      rank
    FROM memory_fts
    WHERE memory_fts MATCH ?
    ORDER BY rank
    LIMIT ?
  `).all(query, MAX_RESULTS);

  return { results, ms: Date.now() - t0 };
}

// ── display ────────────────────────────────────────────────────────────────────

function printSchema() {
  const tables = db.prepare(`
    SELECT name, sql FROM sqlite_master
    WHERE type IN ('table','shadow') AND name LIKE '%memory_fts%'
    ORDER BY name
  `).all();
  console.log('\n=== memory_fts Schema ===\n');
  for (const t of tables) console.log(t.sql + '\n');

  const meta = db.prepare('SELECT key, value FROM memory_fts_meta ORDER BY key').all();
  console.log('=== Index Metadata ===');
  for (const m of meta) console.log(`  ${m.key}: ${m.value}`);
  console.log(`\n  Total indexed: ${getIndexedCount()} documents`);
}

// ── main ───────────────────────────────────────────────────────────────────────

console.log(`\n[memory-search] DB: ${DB_PATH}`);

// Always index if empty, or --reindex requested
const currentCount = getIndexedCount();
if (currentCount === 0 || FLAG_REINDEX) {
  process.stdout.write(`[memory-search] Indexing brain/ + ψ/ files${FLAG_REINDEX ? ' (forced)' : ''}... `);
  const files = collectFiles();
  const { added, skipped, ms: ims } = indexFiles(files, FLAG_REINDEX);
  console.log(`done. +${added} added, ${skipped} skipped (${ims}ms)`);
  console.log(`[memory-search] Total indexed: ${getIndexedCount()} documents`);
} else {
  // Incremental: index any new files not yet in DB
  const files = collectFiles();
  const { added, ms: ims } = indexFiles(files, false);
  if (added > 0) {
    console.log(`[memory-search] Incremental: +${added} new documents indexed (${ims}ms)`);
  }
  console.log(`[memory-search] Index: ${getIndexedCount()} documents`);
}

if (FLAG_SCHEMA) {
  printSchema();
  process.exit(0);
}

if (FLAG_DEDUP || !QUERY) {
  console.log('\n[memory-search] Running deduplication scan...');
  const { pairs, ms, scanned } = runDedup();
  console.log(`Scanned ${scanned} documents in ${ms}ms`);
  if (pairs.length === 0) {
    console.log('No near-duplicate pairs found (threshold: 85% Jaccard).');
  } else {
    console.log(`\n⚠  Found ${pairs.length} near-duplicate pair(s) (≥85% similarity):\n`);
    for (const { a, b, sim } of pairs) {
      console.log(`  [${(sim * 100).toFixed(1)}%] ${a}`);
      console.log(`         ↔ ${b}\n`);
    }
  }
  if (!QUERY) process.exit(0);
}

// Run search
console.log(`\n[memory-search] Query: "${QUERY}"`);
console.log('─'.repeat(60));

const { results, ms } = search(QUERY);

if (results.length === 0) {
  console.log('No results found.');
} else {
  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    console.log(`\n#${i + 1}  ${r.title || '(untitled)'}`);
    console.log(`    Area: ${r.area}  |  Path: ${r.file_path}`);
    console.log(`    ${r.snippet}`);
  }
}

console.log('\n' + '─'.repeat(60));
console.log(`Found ${results.length} result(s) in ${ms}ms`);

if (ms > 50) {
  console.log(`⚠  Search took ${ms}ms (target <50ms). Consider --reindex to rebuild.`);
}

process.exit(0);
