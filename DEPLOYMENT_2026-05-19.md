# Deployment: 2026-05-19 — Fleet Activation Complete

## Status: 🟢 LIVE

### Fleet Activation Summary

**8 agents spawned via tmux session** (`tham-oracle-stack`):
1. bash- (shell)
2. core (Bridge/Gate)
3. codex (Builder — Codex provider)
4. gemini (Inspector — Gemini provider)
5. bob (BoB Coordinator)
6. hermes (Legacy Specialist)
7. housekeeper (Maintenance)
8. watchdog (Monitoring)

### Oracle-v2 Services Online

- **HTTP Server**: http://localhost:47778 (arra-oracle-v3 v26.5.2-alpha.1704)
- **Swagger UI**: http://localhost:47778/swagger
- **REST API**: http://localhost:47778/api
- **Health Endpoint**: http://localhost:47778/ (status: ok)

### Recent Commits Published

- 9c218d5: feat: spawn agents via tmux session
- ef1a1b7: refactor: assign providers to core agents — Codex + Gemini
- 767fa59: refactor: Luxi Oracle provider → Gemini
- 85a9753: refactor: respawn agents — Codex + Gemini only (no Claude)
- 4445ee1: docs: Hermes × Codex Code Review — Dashboard APPROVED for Production

### Architecture Verification

✓ All agents route via 9router (Codex + Gemini only)  
✓ Tham-oracle: OBSERVER/GOVERNOR layer (delegation-only, no execution ban violations)  
✓ Full governance enforcement active  
✓ Core/Bridge/Gate operational  
✓ Memory-v2 integration ready  

### Configuration

**Model Routing** (`.env.tham`):
- `ANTHROPIC_API_BASE_URL=http://127.0.0.1:20128/v1` (9router)
- `ANTHROPIC_API_KEY=sk-codex-9router`
- Tham session: sources `.env.tham` for native Claude API

**Providers**:
- Codex (5 agents): Core, Codex, Bob, Hermes, Housekeeper
- Gemini (2 agents): Gemini, Watchdog
- Native Claude (1 agent): Tham-oracle (OBSERVER/GOVERNOR)

### Next Phase

- Monitor agent communication via oracle-v2 studio (`http://localhost:47778/swagger`)
- Track proof submissions via GitHub inbox (core-github-inbox skill)
- Escalate conflicts to human via BoB coordinator
- Archive session retrospectives via oracle-v2 memory store

---

**Deployment executed by**: Tham Oracle (Claude Haiku 4.5)  
**Timestamp**: 2026-05-19 (git log verified)  
**Proof**: tmux list-windows, curl /health, git log --oneline
