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
| oracle-v2 MCP | configured (.mcp.json), HTTP port 47778 |
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
- `forge-omega-integration` — integration files created, Core agent pending deployment

## Risk Flags
- oracle-v2 HTTP server requires manual start (not auto-started)
- Core agent is template only — not deployed
- Supabase credentials not yet configured

## Last Proof
- Commit `2dbb8af` — steps 04-10 complete (2026-05-12)
- Forge/Omega integration: configs/, docs/forge-omega-integration.md, scripts/forge-omega-health.sh (2026-05-13)
