# Active Memory Index

Last updated: 2026-05-27

## Baselines

| Key | Value |
|-----|-------|
| Repo | `/root/ghq/github.com/E0993599799/tham-oracle` |
| GitHub | `https://github.com/E0993599799/tham-oracle` |
| Branch | `sync/alpha-main` (active) |
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
- Never send พี่เอก a foreground `pwsh`, `powershell`, `cmd`, `wt`, or Windows Terminal command for Core/SFSR/Forge/Omega/OpenClaw/poller work. Use connector lane first; if local execution is unavoidable, use a hidden/no-window launcher only.
- For local Windows execution with paths containing spaces such as `D:\01 Main Work\...`, never use fragile `Start-Process -ArgumentList` string/array patterns that can split `D:\01`; use `System.Diagnostics.ProcessStartInfo.ArgumentList.Add()` or `-EncodedCommand`.
- Hermes is not default executor
- Proof required before reporting OK
- oracle-v2 HTTP must be running before using oracle_* tools

## Read-Memory Cache Rule
- At the start of every technical/Core/SFSR/Forge/Omega/OpenClaw/poller response, perform Memory Gate read before acting.
- Use the last successful memory read as a short-lived active cache for the next 5 chat turns only.
- On the 6th chat turn, or when the task changes risk tier, executor lane, repo, runtime, or safety policy, re-read memory before planning or acting.
- If memory is not freshly read or valid from the 5-chat cache, do not execute, do not generate runnable instructions, and do not claim readiness.
- Memory cache does not override live proof. If proof/logs contradict memory, proof/logs win.

## Active Projects
- `tham-oracle` — Oracle repo complete, branch `sync/alpha-main`, 286 files committed 2026-05-27
- `forge-omega-integration` — integration complete, Omega (Core agent) deployed at D:/Git/omega-oracle
- `MFLEET` — Fleet Recovery mission dispatched to 50-tham:codex-gpt55, in progress (2026-05-27)
- `forge-omega-v2` — Dashboard built at D:/Git/forge-omega-v2, pending MFLEET + portproxy verify
- `Backlog queue` — 7 missions in ψ/inbox/codex/ (~30h Codex work), MFLEET is next gate

## Providers (verified 2026-05-13)

| Provider | Endpoint | Model | Status |
|----------|----------|-------|--------|
| 9router (OpenClaw) | port 20128 | — | ✅ active |
| Hermes (via 9router) | port 20128 | `gemini/gemini-3.1-pro-preview` | ✅ updated 2026-05-21 |
| Tham oracle-v2 | port 47778 | — | manual start |
| Omega oracle-v2 | port 47779 | — | manual start |

Available via 9router (43 models, verified 2026-05-27):
- **GLM-CN**: `glm-5.1`, `glm-5`, `glm-4.6`, `glm-4.7`, `GLM-4.7-Flash`, `glm-4.5-air`
- **Gemini**: `gemini-3.1-pro-preview`, `gemini-3-flash-preview`, `gemini-3.1-flash-lite-preview`, `gemma-4-31b-it`
- **Claude**: `cc/claude-sonnet-4-6`, `cc/claude-opus-4-6`, `cc/claude-opus-4-7`, `cc/claude-haiku-4-5-20251001`
- **Kimi**: `kimi-k2.5`, `kimi-k2.5-thinking`, `kimi-k2.6`, `kimi-latest`
- **NVIDIA**: `minimaxai/minimax-m2.7`, `z-ai/glm4.7`
- **Ollama**: `glm-4.7-flash`, `glm-5`, `gpt-oss:120b`, `kimi-k2.5`, `minimax-m2.5`, `qwen3.5`
- **Ollama-local**: `gemma3:4b-cloud`, `gemma4:31b-cloud`, `qwen2.5-coder:7b`
- **OpenRouter**: qwen3-coder:free, gemma-4-31b-it:free, nemotron-*
- **⚠️ REMOVED**: `cx/gpt-5.5` — fictional, not in 9router
- **9router access**: WSL via `http://172.21.112.1:20128` (Windows host IP)

## Forge Omega V2 Command Center
- Location: `D:/Git/forge-omega-v2/` (Next.js 16 + React 19 + TypeScript 5)
- Status: Components built ✅, dashboard ready to run
- Run from: Windows PowerShell only (Turbopack WSL bug)
- Command: `cd D:\Git\forge-omega-v2 && npm run dev` → port 3000
- Hermes review contract ready at `D:/Git/forge-omega-v2/hermes-review-contract.json`

## Risk Flags
- oracle-v2 HTTP server requires manual start (not auto-started) — `bash scripts/start-oracle-v2-http.sh`
- oracle-v2 /api/learn stores `pattern` only — content/tags fields are ignored
- oracle-v2 vector search needs external embedding API (bge-m3/qwen3/nomic) — currently FTS5 only
- Omega (Core agent) deployed + connected to Forge queue (2026-05-13)
- Supabase credentials not yet configured
- WSL→Windows portproxy: ✅ configured 2026-05-27 — `0.0.0.0:20128 → 127.0.0.1:20128` (conflict with old rule; use Windows host IP `172.21.112.1:20128` from WSL)
- mission-control project has `node dev` bug (incorrect dev command caller) — investigation pending (Windows Task Scheduler check)
- Critical safety regression recorded 2026-05-14: do not send foreground PowerShell for Core/SFSR work; previous failure split path at `D:\01` because of unsafe argument handling.

## Last Proof
- Commit `2dbb8af` — steps 04-10 complete (2026-05-12)
- Forge/Omega integration: configs/, docs/forge-omega-integration.md, scripts/forge-omega-health.sh (2026-05-13)
- oracle-v2 HTTP tested: learn ✅ search(FTS5) ✅ list ✅ stats ✅ — MCP stdio ❌ (2026-05-13)
- Omega (Core agent) deployed: D:/Git/omega-oracle — CLAUDE.md, .mcp.json, ψ vault, hooks (2026-05-13)
- Omega ↔ Forge queue bridge: forge-queue-claim.sh + forge-proof-write.sh ✅ (2026-05-13)
- SFSR-23 COMPLETE ✅ — Hermes verdict: REQUIREMENTS_MET 1-8, VERDICT=COMPLETE (2026-05-13)
- 2026-05-14 memory update: Read-memory cache rule added; foreground local runner prohibition strengthened.
- 2026-05-17: Telegram integration pushed (18 commits), Hermes portproxy docs, Forge Omega V2 dashboard components ready
- 2026-05-21: M0 WORKFLOW-AUDIT complete — Hermes middle-hop ineffective, cx/gpt-5.5 fictional, config drift in 4 files
- 2026-05-27: 4 commits (286 files) — executor lane router, dashboard-next, configs, docs/schemas/reports
- 2026-05-27: oracle-v2 HTTP started ✅, 12 documents populated (FTS5 active)
- 2026-05-27: MFLEET dispatched → 50-tham:codex-gpt55 (in progress)

## Hermes Activation (2026-05-18)

- Status: 🟢 ACTIVE
- Model: ollama/minimax-m2.5
- Access: WSL → Windows 9router via 172.21.112.1:20128 (portproxy configured)
- Role: Code/Design reviewer, specialist executor
- Ready: Yes — review contract prepared at D:/Git/forge-omega-v2/hermes-review-contract.json
