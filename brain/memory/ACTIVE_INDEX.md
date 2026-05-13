# Active Memory Index

Last updated: 2026-05-13

## Baselines

| Key | Value |
|-----|-------|
| Repo | `/root/ghq/github.com/E0993599799/tham-oracle` |
| GitHub | `https://github.com/E0993599799/tham-oracle` |
| Branch | `main` |
| Skills installed | 60 |
| Brain areas | 7 (identity, memory, projects, skills, decisions, proofs, reflections) |
| ψ vault dirs | 10 (inbox/memory/learn/writing/lab/active/archive/outbox + learnings/retrospectives) |
| Forge/Omega status | integration complete — agent-registry, lane-cards, health-check, docs |
| oracle-v2 MCP | HTTP-only (stdio tools removed in v3) — port 47778, DB: ~/.arra-oracle-v2/ |
| maw | installed (/root/.bun/bin/maw) |
| ghq | installed (/usr/local/bin/ghq) |

## Enforced Rules (always active)
- No force push
- No secrets in commits
- PowerShell-first for Windows; WSL/Linux only when project requires it
- No foreground CMD/PowerShell popup
- Hermes is not default executor
- Proof required before reporting OK
- oracle-v2 HTTP must be running before using oracle_* tools

## Active Projects
- `tham-oracle` — Oracle repo complete (Steps 01-11 done)
- `forge-omega-integration` — integration complete, Omega (Core agent) deployed at D:/Git/omega-oracle

## Providers (verified 2026-05-13)

| Provider | Endpoint | Model | Status |
|----------|----------|-------|--------|
| 9router (OpenClaw) | port 20128 | — | ✅ active |
| Hermes (via 9router) | port 20128 | `ollama/minimax-m2.5` | ✅ verified |
| Tham oracle-v2 | port 47778 | — | manual start |
| Omega oracle-v2 | port 47779 | — | manual start |

Available via 9router: `cc/claude-sonnet-4-6`, `ollama/minimax-m2.5`, `ollama/qwen3.5`, `ollama/glm-4.7-flash`, `ollama/kimi-k2.5`

## Risk Flags
- oracle-v2 HTTP server requires manual start (not auto-started) — `bash scripts/start-oracle-v2-http.sh`
- oracle-v2 /api/learn stores `pattern` only — content/tags fields are ignored
- oracle-v2 vector search needs external embedding API (bge-m3/qwen3/nomic) — currently FTS5 only
- Omega (Core agent) deployed + connected to Forge queue (2026-05-13)
- Supabase credentials not yet configured

## Last Proof
- Commit `2dbb8af` — steps 04-10 complete (2026-05-12)
- Forge/Omega integration: configs/, docs/forge-omega-integration.md, scripts/forge-omega-health.sh (2026-05-13)
- oracle-v2 HTTP tested: learn ✅ search(FTS5) ✅ list ✅ stats ✅ — MCP stdio ❌ (2026-05-13)
- Omega (Core agent) deployed: D:/Git/omega-oracle — CLAUDE.md, .mcp.json, ψ vault, hooks (2026-05-13)
- Omega ↔ Forge queue bridge: forge-queue-claim.sh + forge-proof-write.sh ✅ (2026-05-13)
- SFSR-23 claimed test ✅ | Forge evidence written to tools/logs/ ✅
