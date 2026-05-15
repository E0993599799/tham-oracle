# Project: Forge/Omega Integration

Status: active
Last updated: 2026-05-13

## Goal

เชื่อม ธาม Oracle เข้ากับ Forge/Omega agentic OS อย่างสมบูรณ์ —
agent registry, lane router, proof system, multi-oracle fleet, writebacks

## Current State

| Component | Status | Notes |
|-----------|--------|-------|
| ธาม identity (CLAUDE.md) | ✅ done | 60 skills, brain/7-areas |
| oracle-v2 MCP (.mcp.json) | ✅ done | port 47778 |
| ψ vault (complete) | ✅ done | all 10 directories |
| Agent Registry | ✅ done | configs/agent-registry.json |
| Forge/Omega config | ✅ done | configs/forge-omega-config.json |
| Lane cards | ✅ done | tham/core/powershell |
| Integration docs | ✅ done | docs/forge-omega-integration.md |
| Health check script | ✅ done | scripts/forge-omega-health.sh |
| Core agent | ⏳ template | ต้องการ Core agent deployment |
| maw-js | ✅ done | /root/.bun/bin/maw |
| ghq | ✅ done | /usr/local/bin/ghq |
| Supabase persistence | ⏳ pending | setup เมื่อ project ต้องการ |
| OpenClaw/9router | ⏳ pending | setup เมื่อ local LLM routing ต้องการ |

## Architecture

```
พี่เอก → ธาม (brain) → Lane Router → Core/PS/Worker/Research/Codex
                    ↓
              oracle-v2 MCP (memory)
                    ↓
              Proof → Dashboard → Writebacks
```

## Proof

- configs/agent-registry.json ✅
- configs/forge-omega-config.json ✅
- configs/lane-cards/ (3 cards) ✅
- docs/forge-omega-integration.md ✅
- scripts/forge-omega-health.sh ✅
- ψ vault complete (10 dirs) ✅

## Risks / Blockers

- oracle-v2 HTTP server ต้องรัน manually ก่อนใช้ oracle_* tools ใน Claude Code
- Core agent ยังเป็น template — Forge/Omega orchestration ยังต้องการ Core deployment
- Supabase credentials ยังไม่ได้ setup — ใช้ sqlite-local เป็น fallback ชั่วคราว

## Next Actions

1. `bash scripts/forge-omega-health.sh` — ตรวจสอบ health
2. `bash scripts/start-oracle-v2-http.sh` — เริ่ม oracle-v2 HTTP
3. Setup Supabase credentials (ลง .env.local ที่ไม่ commit)
4. Deploy Core agent เมื่อ Forge/Omega Core repo พร้อม
