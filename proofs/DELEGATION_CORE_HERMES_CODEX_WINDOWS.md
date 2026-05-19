---
delegation_id: CORE-20260520-HERMES-CODEX-FIX
timestamp: 2026-05-20T12:00:00Z
delegated_by: Tham Oracle
delegated_to: Core Agent (Windows/PowerShell lane)
status: pending
---

# Mission: Fix Hermes Spawn Codex GPT-5.5 in Windows

## Problem Statement
- พี่เอก ต้อง spawn Codex ผ่าน Hermes adapter บน Windows
- ติด model access (OpenAI API no budget) → ต้องใช้ local 9router routing
- Current state: spawn command fails, ไม่ชัดว่า error เนื่องจากอะไร

## Context
- **Environment**: Windows + WSL (?)
- **Routing**: 9router local @ http://127.0.0.1:20128/v1
- **API Key**: sk-codex-9router
- **Constraint**: CLI-only access (no OpenAI API)
- **Legacy**: Hermes is adapter only (check if deprecated)

## Execution Contract

### Phase 1: Diagnostic (MUST COMPLETE)
Run on Windows environment:
```powershell
# 1. Check 9router health
curl.exe http://127.0.0.1:20128/v1/models

# 2. Check Codex CLI
codex --version

# 3. Test local routing
$env:ANTHROPIC_API_BASE_URL = "http://127.0.0.1:20128/v1"
$env:ANTHROPIC_API_KEY = "sk-codex-9router"
codex --help

# 4. Find Hermes spawn script
Get-ChildItem -Path . -Filter "*hermes*" -Recurse
Get-ChildItem -Path . -Filter "*spawn*" -Recurse
```

### Phase 2: Root Cause Analysis
From diagnostic output, identify:
- [ ] 9router running? (200 status or error?)
- [ ] Codex CLI installed? (version output)
- [ ] Environment routing works? (can call codex with local API?)
- [ ] Hermes spawn script location? (where is it?)
- [ ] Exact error message from Hermes spawn attempt

### Phase 3: Fix (based on diagnosis)
**If 9router not running:**
- Start 9router service (check `scripts/start-9router.sh` or equivalent)
- Verify it listens on 127.0.0.1:20128

**If Codex CLI not installed:**
- Install via package manager or build from source
- Verify codex binary is in PATH

**If environment routing fails:**
- Update Hermes spawn script to set:
  ```powershell
  $env:ANTHROPIC_API_BASE_URL = "http://127.0.0.1:20128/v1"
  $env:ANTHROPIC_API_KEY = "sk-codex-9router"
  ```
- Or create `.env` file if Hermes reads from it

**If Hermes deprecated:**
- Check CLAUDE.md: "hermes-legacy-adapter — Use Hermes as optional/specialist/legacy adapter only"
- If truly deprecated, bypass Hermes and call Codex directly

### Phase 4: Verification (PROOF REQUIRED)
After fix:
- [ ] `codex --version` returns version number
- [ ] Local routing test succeeds (returns model list)
- [ ] Hermes spawn completes without error
- [ ] Spawn result returns valid Codex model response

## Proof Requirements
- stdout/stderr from all diagnostic commands
- Before/after screenshots if UI involved
- Exact error message (if any)
- Timestamp of successful spawn
- Model output from test call

## Success Criteria
✓ Hermes successfully spawns Codex on Windows
✓ Local 9router routing active (no OpenAI API needed)
✓ No hanging processes or environment pollution
✓ Proof file uploaded with full diagnostic trail

## Escalation Path
If Core cannot resolve:
- Route to Codex agent (model/SDK issue)
- Route to Hermes maintainer (legacy adapter deprecation)
- Escalate to พี่เอก with full diagnostic log

---

**Next Action**: Core agent run Phase 1 diagnostic, report findings to Tham.
