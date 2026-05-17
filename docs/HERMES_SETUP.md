# Hermes Setup — WSL ↔ Windows Routing

**Goal**: Allow Hermes (WSL Ollama/9router connector) to access Windows 9router on `localhost:20128`

## Problem

- 9router runs on Windows (OpenClaw) on `localhost:20128`
- WSL cannot directly access Windows `localhost:20128`
- Hermes runs in WSL and needs to reach 9router
- **Solution**: Windows portproxy redirect `127.0.0.1:20128` → WSL:20128

## Setup (Admin PowerShell)

**Step 1: Open Windows PowerShell as Administrator**
- Right-click PowerShell icon
- Select "Run as administrator"

**Step 2: Run setup script**
```powershell
# Copy-paste entire script from:
# scripts/setup-hermes-portproxy.ps1

# Or one-liner:
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Git\tham-oracle\scripts\setup-hermes-portproxy.ps1"
```

**Step 3: Verify in WSL**
```bash
# In WSL terminal:
nc -zv 127.0.0.1 20128
# Expected: Connection to 127.0.0.1 20128 succeeded

# Test HTTP:
curl http://127.0.0.1:20128/status
# Should return 9router status JSON
```

## What the script does

1. **Detect WSL IP** — `wsl hostname -I`
2. **Clear old rules** — remove existing portproxy
3. **Add rule** — `127.0.0.1:20128` → `WSL:20128`
4. **List all rules** — show active portproxy config

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Not admin" | Right-click PowerShell → "Run as administrator" |
| "WSL IP not found" | Check `wsl --list --verbose` (is WSL2 running?) |
| Port 20128 in use | Check `netstat -ano \| findstr :20128` on Windows |
| WSL nc still fails | 9router may not be running (check Windows port 20128) |

## After Setup

**Hermes config** (`maw.config.json`):
```json
{
  "hermes": {
    "model": "ollama/minimax-m2.5",
    "baseUrl": "http://127.0.0.1:20128"
  }
}
```

Hermes will now route requests through portproxy → 9router → model inference

## Duration

- Setup time: ~30 seconds
- Need to repeat if: WSL IP changes, Windows reboots, remove `netsh rule` manually
