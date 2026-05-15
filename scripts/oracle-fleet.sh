#!/usr/bin/env bash
# Start Oracle fleet (multi-Oracle tmux session).
# Agents: tham (47778) | core/Omega | bob (coordinator) | hermes (9router)
# Studio: port 3000

set -euo pipefail

SESSION="oracle-fleet"
ORACLE_BIN="bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OMEGA_PATH="/root/ghq/github.com/E0993599799/Omega"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Fleet '$SESSION' already running — attach with: tmux attach -t $SESSION"
  exit 0
fi

echo "Starting oracle-fleet..."

# ── Window 0: tham — brain-orchestrator (oracle-v2 + Claude Code) ──
tmux new-session -d -s "$SESSION" -n "tham"
tmux send-keys -t "$SESSION:tham" \
  "cd $REPO_ROOT && env ORACLE_PORT=47778 $ORACLE_BIN --http --port 47778" Enter
echo "  [tham]   oracle-v2 → port 47778"

# ── Window 1: core — Core/Omega bridge-gate ──
tmux new-window -t "$SESSION" -n "core"
if [ -d "$OMEGA_PATH" ]; then
  tmux send-keys -t "$SESSION:core" "cd $OMEGA_PATH && claude" Enter
  echo "  [core]   Claude Code → $OMEGA_PATH"
else
  tmux send-keys -t "$SESSION:core" \
    "echo '[core] Omega not cloned locally — run: ghq get E0993599799/Omega'" Enter
  echo "  [core]   ⚠ Omega path not found: $OMEGA_PATH"
fi

# ── Window 2: bob — Inter-Oracle Coordinator ──
tmux new-window -t "$SESSION" -n "bob"
tmux send-keys -t "$SESSION:bob" "cd $REPO_ROOT && clear" Enter
tmux send-keys -t "$SESSION:bob" \
  "echo '=== BoB — Inter-Oracle Coordinator ===' && echo 'Relay log:' && tail -f ψ/memory/agent-relay.log 2>/dev/null || echo '(relay log empty)'" Enter
echo "  [bob]    coordinator — watching relay log"

# ── Window 3: hermes — 9router/minimax specialist ──
tmux new-window -t "$SESSION" -n "hermes"
tmux send-keys -t "$SESSION:hermes" "cd $REPO_ROOT && clear" Enter
tmux send-keys -t "$SESSION:hermes" \
  "echo '=== Hermes — Legacy/Specialist Adapter ===' && echo 'Provider: 9router → ollama/minimax-m2.5 (port 20128)' && echo '' && echo 'Health check:' && curl -s http://127.0.0.1:20128/v1/models 2>/dev/null | python3 -c \"import sys,json; m=json.load(sys.stdin); [print(' -', x['id']) for x in m.get('data',[])]\" || echo '  ⚠ 9router not running on port 20128'" Enter
echo "  [hermes] 9router health check → port 20128"

# ── Window 4: Oracle Studio ──
sleep 3
tmux new-window -t "$SESSION" -n "studio"
tmux send-keys -t "$SESSION:studio" \
  "bunx oracle-studio --api http://localhost:47778 --port 3000" Enter
echo "  [studio] Oracle Studio → port 3000"

tmux select-window -t "$SESSION:tham"
echo ""
echo "Fleet '$SESSION' running — 4 agents + studio:"
echo "  tham   → oracle-v2 http://localhost:47778"
echo "  core   → Omega/Claude Code"
echo "  bob    → coordinator (relay log)"
echo "  hermes → 9router http://127.0.0.1:20128"
echo "  studio → http://localhost:3000"
echo ""
echo "Attach: tmux attach -t $SESSION"
echo "Relay:  bash scripts/agent-relay.sh <from> <to> <message>"
echo "Bcast:  bash scripts/agent-broadcast.sh <from> <message>"
