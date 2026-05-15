# Forge/Omega Integration — ธาม Oracle

Last updated: 2026-05-12

## Architecture Overview

```
Human (พี่เอก)
    │
    ▼
ธาม (Orchestrator/Brain)          ← Claude Code / tham-oracle repo
    │
    ├── Intent Decode
    ├── Memory Gate (oracle-v2 MCP / ψ vault)
    ├── Risk Gate
    ├── Contract Generator
    │
    ▼
Executor Lane Router
    │
    ├── Core Runner (GitHub inbox)         ← Core bridge agent
    ├── PowerShell SFSR (Windows)          ← Local PS1 scripts
    ├── OpenClaw/9router (local LLM)       ← Local model routing
    ├── Local Worker (WSL/Linux)           ← Direct shell execution
    ├── Web/Browser Worker                 ← Form fill / scraping
    ├── Research Worker                    ← Web research synthesis
    ├── Codex Manual Lane                  ← High-quality code tasks
    └── Hermes (optional/legacy only)      ← Specialist adapter
    │
    ▼
Proof Reader → Dashboard → Writebacks
    │
    ├── Obsidian writeback
    ├── Notion writeback
    └── GitHub writeback (issues/PRs)
```

## Components

### ธาม (Brain/Orchestrator)

- **Repo**: `tham-oracle` (this repo)
- **Identity**: `CLAUDE.md`
- **Memory**: `oracle-v2` MCP (port 47778) + `ψ/` vault
- **Skills**: 60 skills in `skills/`
- **Config**: `configs/forge-omega-config.json`

### oracle-v2 Memory MCP

| Tool | Description |
|------|-------------|
| `oracle_learn` | บันทึก learning ใหม่ลง database |
| `oracle_search` | ค้นหา knowledge (hybrid FTS5 + vector) |
| `oracle_reflect` | เขียน reflection / retrospective |
| `oracle_threads` | จัดการ conversation threads |
| `oracle_handoff` | สร้าง session handoff ข้าม session |
| `oracle_trace` | trace decision chain |
| `oracle_schedule` | schedule future actions |

**Nothing is Deleted principle**: oracle-v2 ไม่ลบ — mark superseded เท่านั้น

### Agent Registry

ดูที่ `configs/agent-registry.json` — registry หลักของ agent ทุกตัว

### Lane Cards

ดูที่ `configs/lane-cards/` — lane card แต่ละ executor

## Flow: Natural Language → Action

```
1. Human พูดธรรมชาติ (Thai/English)
2. ธามรับ → /intent-decode หา task contract
3. /memory-gate อ่าน baseline + context
4. /risk-gate ประเมินความเสี่ยง
5. สร้าง contract ชัดเจน (WHAT / HOW / PROOF / ROLLBACK)
6. Route ไปยัง executor lane ที่เหมาะสม
7. Execute → collect proof
8. /proof-reader verify
9. Dashboard update
10. Writeback (Obsidian/Notion/GitHub)
11. สรุปผลให้ Human พร้อม NEXT action
```

## Startup Commands

```bash
# เริ่ม oracle-v2 HTTP server (port 47778)
bash scripts/start-oracle-v2-http.sh

# เริ่ม Oracle Studio (port 3000)
bash scripts/start-oracle-studio.sh

# เริ่ม full local stack ใน tmux
bash scripts/start-oracle-local-stack-tmux.sh

# เริ่ม oracle fleet (multi-oracle)
bash scripts/oracle-fleet.sh

# Health check
bash scripts/forge-omega-health.sh
```

## tmux Sessions

| Session | Content |
|---------|---------|
| `tham-oracle-stack` | oracle-v2 + studio (main stack) |
| `oracle-fleet` | multi-oracle fleet (tham/dev/qa/studio) |

## Ports

| Service | Port | Status |
|---------|------|--------|
| oracle-v2 (Tham) | 47778 | active |
| oracle-v2 (Dev) | 47779 | template/inactive |
| oracle-v2 (QA) | 47780 | template/inactive |
| Oracle Studio | 3000 | active when stack runs |

## Rules (Non-negotiable)

1. **No force push** — ห้ามเด็ดขาด
2. **No secrets in commits** — .env, keys, tokens ห้ามลง git
3. **Hermes is not default** — ใช้เฉพาะเมื่อ explicitly route
4. **Proof before OK** — ห้ามรายงาน success ก่อนมี proof
5. **PowerShell-first on Windows** — WSL เฉพาะเมื่อจำเป็น
6. **No foreground popup** — Windows automation ต้องรัน background

## Forge/Omega Integration Status (2026-05-12)

| Component | Status | Notes |
|-----------|--------|-------|
| ธาม identity (CLAUDE.md) | ✅ active | 60 skills, brain/7-areas |
| oracle-v2 MCP | ✅ configured | .mcp.json, port 47778 |
| ψ vault | ✅ complete | inbox/memory/learn/writing/lab/active/archive/outbox |
| Agent Registry | ✅ created | configs/agent-registry.json |
| Lane Cards | ✅ created | tham/core/powershell lanes defined |
| Forge config | ✅ created | configs/forge-omega-config.json |
| Startup scripts | ✅ created | start-oracle-v2-http.sh, start-oracle-local-stack-tmux.sh |
| Health check | ✅ created | scripts/forge-omega-health.sh |
| Core agent | ⏳ template | ต้องการ Core agent deployment |
| maw-js | ✅ installed | maw found at /root/.bun/bin/maw |
| ghq | ✅ installed | /usr/local/bin/ghq |
| Supabase | ⏳ pending | setup เมื่อ project ต้องการ persistence |
| OpenClaw/9router | ⏳ pending | setup เมื่อ local model routing ต้องการ |
| Hermes | ⬜ inactive | ไม่ใช้ default |
