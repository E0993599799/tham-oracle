# Windows Next Steps — Forge Omega V2 + Hermes Activation

**Date**: 2026-05-17  
**For**: พี่เอก  
**Status**: Awaiting Windows execution

---

## Quick Overview

ธาม prepared 3 things, need พี่ to execute 2 things on Windows:

| Task | Owner | Status |
|------|-------|--------|
| Telegram monitor fix | ธาม ✅ | Done — pushed |
| Hermes portproxy setup script | ธาม ✅ | Done — `scripts/setup-hermes-portproxy.ps1` |
| Run portproxy script | **พี่** | ⏳ Pending |
| Run Forge Omega V2 dashboard | **พี่** | ⏳ Pending |
| Fix mission-control `node dev` bug | **พี่** | ⏳ Pending (investigation) |

---

## Step 1: Setup Hermes Portproxy (15 min)

**Why**: WSL needs to reach 9router on Windows `localhost:20128`

**How**:
1. Open **Windows PowerShell as Administrator**
2. Copy-paste the script:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Git\tham-oracle\scripts\setup-hermes-portproxy.ps1"
   ```
3. Wait for ✅ confirmation
4. Test from WSL:
   ```bash
   nc -zv 127.0.0.1 20128
   # Expected: "succeeded"
   ```

**Docs**: `/root/ghq/github.com/E0993599799/tham-oracle/docs/HERMES_SETUP.md`

---

## Step 2: Run Forge Omega V2 Dashboard (3 min to start)

**Why**: Visual mission control for Forge/Omega — see queue, models, agents, health

**Location**: `D:\Git\forge-omega-v2`

**How**:
1. Open **Windows PowerShell** (any mode)
2. Run:
   ```powershell
   cd D:\Git\forge-omega-v2
   npm run dev
   ```
3. Wait for: `Ready in X ms`
4. Open browser: **http://localhost:3000**

**What you'll see**:
- Oracle Fleet (ธาม, Omega, Hermes, Gemini Brain)
- 74+ models from 9router (color-coded by provider)
- Kanban queue (5 lanes)
- Health status (refreshes every 15 sec)
- Live logs + quick actions

**Stop**: Ctrl+C

---

## Step 3: Investigation — mission-control `node dev` Bug (10-15 min)

**Problem**: Some process calls `node dev` instead of `npm run dev`

**Location**: `D:\01 Main Work\Boots\Agentic AI\mission-control\`

**What to check**:
1. **Windows Task Scheduler** — any task with `node dev`?
   - Win+R → `taskschd.msc`
   - Look for tasks mentioning "mission-control", "dev", or "node"
   
2. **PowerShell background scripts**:
   - Check: `D:\Tools\...` or any auto-startup folder
   - Look for: `$Commands = @("dev", ...)`
   
3. **Process Monitor** (if available):
   - Run ProcessMonitor
   - Filter by `node.exe`
   - Look for arguments containing "dev"

**Report back**:
- Which file/process calls `node dev`?
- What is the correct command? (should be `npm run dev`)

---

## After All Steps

- [ ] Portproxy: `nc -zv 127.0.0.1 20128` ✅
- [ ] Dashboard: http://localhost:3000 loads ✅
- [ ] mission-control bug: identified + noted ✅
- [ ] Everything: push the findings to git?

---

## Why This Matters

1. **Portproxy**: Unlocks Hermes review (currently can't reach 9router from WSL)
2. **Dashboard**: Visual proof Forge/Omega system is alive + see all components
3. **mission-control bug**: Blocks proper dev workflow in that project

---

## If You Get Stuck

All configs + proof paths are in Git:
- Portproxy script: `scripts/setup-hermes-portproxy.ps1`
- Portproxy docs: `docs/HERMES_SETUP.md`
- Forge Omega V2: `D:\Git\forge-omega-v2` (fully built, ready)
- ACTIVE_INDEX (latest status): `brain/memory/ACTIVE_INDEX.md`

Call or message ธาม if needed.

---

**Next session**: ธาม will activate Hermes review once portproxy is live ✨
