# oracle-v2 — ความทรงจำถาวรของธาม

oracle-v2 (arra-oracle) คือ HTTP memory server สำหรับ tham-oracle
ให้ hybrid search (FTS5 + vector) และ persistent learning storage

## สถานะจริง (ทดสอบ 2026-05-13)

| สิ่งที่คาดหวัง | ความจริง |
|---|---|
| MCP stdio tools (`oracle_learn` ฯลฯ) | ❌ ถูกถอดออกใน v3 — HTTP-only แล้ว |
| Data เก็บใน repo `ψ/` | ❌ เก็บที่ `~/.arra-oracle-v2/` แทน |
| `/api/learn` เก็บ content + tags | ❌ เก็บแค่ `pattern` field เป็น title/body |
| Vector search | ⚠️ ต้องการ external embedding API — FTS5 ใช้ได้ปกติ |

## ติดตั้งและ Start

```bash
# Start HTTP server (port 47778) — ต้อง start เองก่อนใช้งานทุกครั้ง
bash scripts/start-oracle-v2-http.sh

# ดู log
tail -f .oracle-setup/logs/oracle-v2-http.log
```

ข้อมูลถูกเก็บที่ `~/.arra-oracle-v2/`
- `oracle.db` — SQLite FTS5 index
- `ψ/memory/learnings/` — learning files (markdown)
- `lancedb/` — vector index (bge-m3, qwen3, nomic)

## HTTP API (ใช้งานได้จริง)

Base URL: `http://localhost:47778`

### `/api/learn` — POST
บันทึก learning ใหม่

```bash
curl -s http://localhost:47778/api/learn -X POST \
  -H "Content-Type: application/json" \
  -d '{"pattern": "เนื้อหาที่ต้องการจำ"}'
```

**หมายเหตุ:** เก็บเฉพาะ `pattern` field — `content`, `tags`, `title` ถูก ignore

Response:
```json
{"success": true, "file": "ψ/memory/learnings/YYYY-MM-DD_slug.md", "id": "learning_..."}
```

### `/api/search` — GET
ค้นหา knowledge (FTS5)

```bash
curl -s "http://localhost:47778/api/search?q=forge+omega"
```

Parameters: `q` (required), `limit`, `offset`, `type`

### `/api/list` — GET
ดู documents ทั้งหมด

```bash
curl -s "http://localhost:47778/api/list"
```

### `/api/stats` — GET
สถิติ knowledge base

```bash
curl -s "http://localhost:47778/api/stats"
```

### `/api/reflect` — GET
Semantic reflect — ดึง document ตาม query

```bash
curl -s "http://localhost:47778/api/reflect?q=forge"
```

### `/api/inbox` — GET
ดู inbox (handoff/tasks)

```bash
curl -s "http://localhost:47778/api/inbox"
```

### `/api/supersede` — POST
Mark document เก่าว่าถูก supersede (ไม่ลบ)

```bash
curl -s http://localhost:47778/api/supersede -X POST \
  -H "Content-Type: application/json" \
  -d '{"old_path": "ψ/memory/learnings/old.md", "new_path": "ψ/memory/learnings/new.md"}'
```

### `/api/schedule` — GET
ดูตาราง scheduled events

```bash
curl -s "http://localhost:47778/api/schedule"
```

## Endpoints ที่ไม่มีแล้ว (v3)

ใน docs เก่าระบุว่ามี แต่ตรวจสอบแล้วไม่มี:
- `/api/concepts` — 404
- `/api/verify` — 404
- `/api/trace` — 404
- `/api/thread` — 404
- `/api/handoff` — 404

## Vector Search

Vector search ต้องการ embedding API ที่ accessible จาก server:
- `bge-m3` (collection: `oracle_knowledge_bge_m3`)
- `qwen3-embedding` (collection: `oracle_knowledge_qwen3`)
- `nomic-embed-text` (collection: `oracle_knowledge`)

ตอนนี้ FTS5 เป็น fallback ที่ใช้ได้จริง — `"mode": "hybrid"` แต่ vector part จะ error ถ้าไม่มี endpoint

## Dashboard (Oracle Studio)

```bash
bash scripts/start-oracle-studio.sh
# เปิด browser: http://localhost:3000
```

## .mcp.json (ปัจจุบัน)

```json
{
  "mcpServers": {
    "oracle-v2": {
      "command": "bunx",
      "args": ["--bun", "arra-oracle@github:Soul-Brews-Studio/arra-oracle#main"],
      "env": {"ORACLE_PORT": "47778"}
    }
  }
}
```

**หมายเหตุ:** config นี้ launch HTTP server ผ่าน stdio แต่ไม่ expose MCP tools ใดๆ เข้า Claude Code
ใช้ HTTP API โดยตรงแทน
