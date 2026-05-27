# Handoff: Forge Omega V2 Dashboard Build + Mission Control Bug

**Date**: 2026-05-15 07:07
**Context**: ~70%
**From**: ธาม session (claude-sonnet-4-6)

---

## What We Did

### 1. Activated Hermes
- Confirmed 9router (OpenClaw) LIVE on Windows `localhost:20128`
- 74+ models available across cc/cx/gc/gemini/ollama/glm-cn/nvidia/openrouter/ollama-local
- Hermes model: `ollama/minimax-m2.5` — ✅ verified available
- WSL→Windows 9router: ❌ portproxy NOT yet configured (blocks Hermes from WSL)

### 2. Built MarcuzX Forge Omega V2 Command Center
- Location: `D:/Git/forge-omega-v2/` (accessible from WSL as `/mnt/d/Git/forge-omega-v2/`)
- Stack: Next.js 16.2.6 + React 19 + TypeScript 5 + Tailwind CSS 4
- TypeScript check: ✅ 0 errors

**Components built:**
| File | Status |
|------|--------|
| `app/layout.tsx` | ✅ dark theme |
| `app/page.tsx` | ✅ 3-row grid layout |
| `app/globals.css` | ✅ cyberpunk dark glassmorphism |
| `components/StatusBar.tsx` | ✅ health polling 15s |
| `components/OracleFleet.tsx` | ✅ ธาม/Omega/Hermes/Gemini Brain |
| `components/ModelPalette.tsx` | ✅ 74+ models color coded by provider |
| `components/ForgeQueue.tsx` | ✅ Kanban 5 columns |
| `components/LaneRouter.tsx` | ✅ 6 lanes + status |
| `components/ProofFeed.tsx` | ✅ SFSR proof entries |
| `components/LiveLogs.tsx` | ✅ terminal log stream |
| `components/QuickActions.tsx` | ✅ 6 quick actions |
| `lib/providers.ts` | ✅ color config all providers |
| `lib/nine-router.ts` | ✅ 9router API client |
| `app/api/models/route.ts` | ✅ proxy to 9router |
| `app/api/health/route.ts` | ✅ health check oracle-v2 + 9router |
| `.env.local` | ✅ NINE_ROUTER_URL + ORACLE_V2_URL |
| `hermes-review-contract.json` | ✅ Hermes review ready |

**Build issue**: Turbopack fails on Windows filesystem path from WSL.
**Fix**: Run `npm run dev` from **Windows PowerShell** only — NOT from WSL.

### 3. Found Mission Control `node dev` Bug
- Project: `D:\01 Main Work\Boots\Agentic AI\mission-control\`
- Error: `Cannot find module '...\mission-control\dev'` → something calls `node dev` instead of `npm run dev`
- `Starting: dev` message source not yet found (grep searches all returned empty)
- Correct dev command: `npm run dev` (uses `cross-env ... next dev --turbo --hostname 127.0.0.1 --port 3005`)
- Correct reset command: `node scripts/dev-reset.js` (clears .next, rebuilds scheduler, starts both)
- Known tools: `start-mission-control.bat` → calls `npm run dev:reset` (which doesn't exist in current package.json!)

### 4. New Models Found in 9router (not in ACTIVE_INDEX yet)
- `ollama/gpt-oss:120b` — NEW
- `ollama/glm-5` — upgraded from glm-4.7-flash
- `nvidia/minimaxai/minimax-m2.7` — newer than m2.5
- `glm-cn/glm-5.1`, `glm-cn/glm-5` — NEW
- `gemini/gemini-3.1-pro-preview`, `gemini/gemini-3-flash-preview` — NEW
- `cx/gpt-5.5` and many codex variants — NEW

---

## Pending

- [ ] Fix `node dev` bug in mission-control (find caller)
- [ ] Set up WSL→9router portproxy (Windows PowerShell):
  ```powershell
  netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=20128 connectaddress=127.0.0.1 connectport=20128
  netsh advfirewall firewall add rule name="9router-WSL" dir=in action=allow protocol=TCP localport=20128
  ```
- [ ] Run forge-omega-v2 dashboard from Windows: `cd D:\Git\forge-omega-v2 && npm run dev`
- [ ] Send Hermes review contract (`hermes-review-contract.json`) after portproxy
- [ ] Update ACTIVE_INDEX.md with new 9router models
- [ ] Answer: Is `mumudevx` = พี่เอก's GitHub handle? (found `mumudevx/openclaw-mission-control`)

---

## Next Session — Specific Actions

1. **Fix mission-control `node dev` bug first:**
   - Check Windows Task Scheduler: any task running `node dev`?
   - Check `tools/core-runner/core-local-runner-background-loop.ps1` — is there a `$Commands = @("dev", ...)` pattern?
   - Or look at the actual process that printed `Starting: dev` using Process Monitor

2. **Start dashboard:**
   ```powershell
   cd D:\Git\forge-omega-v2
   npm run dev
   # Opens at http://localhost:3000
   ```

3. **Setup portproxy** then test Hermes review:
   ```bash
   curl -s http://172.21.112.1:20128/v1/models | head -5
   ```

4. **Update ACTIVE_INDEX** at `/root/repos/tham-oracle/brain/memory/ACTIVE_INDEX.md`

---

## Key Files

- Dashboard: `/mnt/d/Git/forge-omega-v2/` (all components built)
- Hermes review contract: `/mnt/d/Git/forge-omega-v2/hermes-review-contract.json`
- Mission control: `/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/`
- Oracle fleet: omega-oracle at `/mnt/d/Git/omega-oracle/`
- tham-oracle: `/root/repos/tham-oracle/`
- ACTIVE_INDEX: `/root/repos/tham-oracle/brain/memory/ACTIVE_INDEX.md`

---

## Context: Role Split

- **ธาม** = Orchestrator + Writer (built dashboard components)
- **Gemini** = Brain/Research (researched GitHub + Figma patterns)
- **Hermes (minimax-m2.5)** = Reviewer (waiting for portproxy to activate)
- **Omega** = Core/Gate (deployed at D:/Git/omega-oracle)
