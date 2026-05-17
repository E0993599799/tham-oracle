# Omega OS Deployment — Quick Start

## Start 9router (Windows)

**Method 1: Desktop Shortcut**
```
C:\desktop\Start 9router.cmd
```
Double-click or run in Windows Terminal.

**Method 2: Windows Terminal CLI**
```powershell
# Open Windows Terminal
# Run: C:\desktop\Start 9router.cmd
```

**Verify 9router is running:**
```bash
# Linux/WSL
9router-check
# or
bash scripts/9router-wake.sh --check

# Shows models available and API status
```

---

## Start THAM Memory Server (Linux/WSL)

```bash
cd /root/ghq/github.com/E0993599799/tham-oracle

# Start oracle-v2 HTTP server (port 47778)
bash scripts/start-oracle-v2-http.sh

# Verify
curl http://127.0.0.1:47778/health
```

---

## Start Lanes Session

```bash
# Once 9router and THAM are running:
oracle tmux:lanes

# Or: tmux attach-session -t lanes
```

---

## Deployment Checklist

```
✅ THAM (oracle-v2, port 47778)      — bash scripts/start-oracle-v2-http.sh
⏳ 9router (port 20128)             — C:\desktop\Start 9router.cmd [Windows]
✅ Lanes session (tmux)              — oracle tmux:lanes
✅ Agent registry locked             — configs/agent-registry.json
✅ Lane cards ready                  — configs/lane-cards/

When ALL above ✅ → Ready for benchmarks and Phase 2 router
```

---

## Test First Task (Once All Services Running)

```bash
# In lanes session tmux, send to Codex:
oracle lane:codex "write a hello world function in Python"

# Codex will:
1. Receive task (contract)
2. Execute on Codex lane (via 9router)
3. Generate proof (code + test result)
4. Return to THAM
5. THAM validates proof + archives
```

---

## Shortcuts (Linux/WSL)

```bash
oracle status           # All service health
oracle tmux:lanes       # Start 5-lane session
oracle lane:codex "task"    # Send to Codex
oracle queue:check      # Check inbox
oracle proof:last       # Last proof summary

9router-wake            # Open 9router dashboard (http://localhost:20128/dashboard)
9router-check           # Check 9router API status
tm                      # Attach to tmux oracle session
lanes                   # Start lanes session
```

---

## Troubleshooting

### 9router not responding
```bash
# Windows: 
# 1. Open C:\desktop\Start 9router.cmd
# 2. Or: Windows Terminal → Get-Service 9router | Start-Service

# Verify:
9router-check
```

### THAM memory server not starting
```bash
bash scripts/start-oracle-v2-http.sh

# Check logs:
tail /root/repos/tham-oracle/.oracle-setup/logs/oracle-v2-http.log
```

### Tmux lanes not responding
```bash
# Kill and restart:
tmux kill-session -t lanes
oracle tmux:lanes
```

---

## Next: Phase 2 Router Implementation

Once services are running:

```bash
# Implement executor-lane-router.py
oracle lane:codex "implement executor-lane-router.py based on routing_decision_table.md"

# Then run benchmarks:
bash docs/world-class-benchmarks.sh
```

---

**Version:** 1.0  
**Updated:** 2026-05-17  
**Status:** Ready for deployment
