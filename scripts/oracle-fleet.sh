#!/usr/bin/env bash
# Start Oracle fleet — 3 windows, 2 panes each (1 หน้า = 2 agents)
#
# Layout:
#   win 0 "brain"  │ tham (left) │ bob (right)        │
#   win 1 "exec"   │ core (left) │ hermes (right)      │
#   win 2 "ops"    │ housekeeper (left) │ studio (right)│

set -euo pipefail

SESSION="oracle-fleet"
ORACLE_BIN="bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OMEGA_PATH="/root/ghq/github.com/E0993599799/Omega"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Fleet '$SESSION' already running — attach with: tmux attach -t $SESSION"
  exit 0
fi

echo "Starting oracle-fleet (3 windows × 2 panes)..."

# ════════════════════════════════════════════════════════
# Window 0: "brain" — tham (left) | bob (right)
# ════════════════════════════════════════════════════════
tmux new-session -d -s "$SESSION" -n "brain"

# Left pane: tham oracle-v2
tmux send-keys -t "$SESSION:brain" \
  "cd $REPO_ROOT && printf '\033[1;36m=== THAM — Brain/Orchestrator (port 47778) ===\033[0m\n' && env ORACLE_PORT=47778 $ORACLE_BIN --http --port 47778" Enter

# Right pane: bob relay log
tmux split-window -h -t "$SESSION:brain"
tmux send-keys -t "$SESSION:brain.right" \
  "cd $REPO_ROOT && printf '\033[1;33m=== BOB — Inter-Oracle Coordinator ===\033[0m\n' && mkdir -p ψ/memory && tail -f ψ/memory/agent-relay.log 2>/dev/null || (echo '(relay log empty — waiting...)' && sleep 9999)" Enter

tmux select-pane -t "$SESSION:brain.left"
echo "  [brain]  tham (L) | bob (R)"

# ════════════════════════════════════════════════════════
# Window 1: "exec" — core (left) | hermes (right)
# ════════════════════════════════════════════════════════
tmux new-window -t "$SESSION" -n "exec"

# Left pane: core/Omega
if [ -d "$OMEGA_PATH" ]; then
  tmux send-keys -t "$SESSION:exec" \
    "cd $OMEGA_PATH && printf '\033[1;32m=== CORE — Bridge/Gate (Omega) ===\033[0m\n' && claude" Enter
else
  tmux send-keys -t "$SESSION:exec" \
    "printf '\033[1;32m=== CORE — Bridge/Gate (Omega) ===\033[0m\n' && echo '⚠ Omega not cloned — run: ghq get E0993599799/Omega'" Enter
fi

# Right pane: hermes 9router
tmux split-window -h -t "$SESSION:exec"
tmux send-keys -t "$SESSION:exec.right" \
  "cd $REPO_ROOT && printf '\033[1;35m=== HERMES — Specialist/Legacy (9router:20128) ===\033[0m\n' && echo 'Model: ollama/minimax-m2.5' && echo '' && echo '── Health ──' && curl -s http://127.0.0.1:20128/v1/models 2>/dev/null | python3 -c \"import sys,json; m=json.load(sys.stdin); [print(' ✓', x['id']) for x in m.get('data',[])]\" || echo '  ⚠ 9router not running on port 20128' && echo '' && echo 'Inbox:' && ls ψ/inbox/hermes/ 2>/dev/null || echo '  (empty)'" Enter

tmux select-pane -t "$SESSION:exec.left"
echo "  [exec]   core (L) | hermes (R)"

# ════════════════════════════════════════════════════════
# Window 2: "ops" — housekeeper (left) | studio (right)
# ════════════════════════════════════════════════════════
tmux new-window -t "$SESSION" -n "ops"

# Left pane: housekeeper — run maintenance cycle
tmux send-keys -t "$SESSION:ops" \
  "cd $REPO_ROOT && printf '\033[1;31m=== HOUSEKEEPER — Maintenance ===\033[0m\n' && bash scripts/housekeeper-run.sh" Enter

# Right pane: Oracle Studio (wait for tham to start)
tmux split-window -h -t "$SESSION:ops"
tmux send-keys -t "$SESSION:ops.right" \
  "printf '\033[1;34m=== STUDIO — Oracle Studio (port 3000) ===\033[0m\n' && sleep 4 && bunx oracle-studio --api http://localhost:47778 --port 3000" Enter

tmux select-pane -t "$SESSION:ops.left"
echo "  [ops]    housekeeper (L) | studio (R)"

# ════════════════════════════════════════════════════════
# Focus: brain window, tham pane
# ════════════════════════════════════════════════════════
tmux select-window -t "$SESSION:brain"
tmux select-pane -t "$SESSION:brain.left"

echo ""
echo "Fleet '$SESSION' ready — 3 windows × 2 panes:"
echo ""
echo "  brain  [win 0]  tham       │  bob"
echo "  exec   [win 1]  core       │  hermes"
echo "  ops    [win 2]  housekeeper│  studio"
echo ""
echo "Attach : tmux attach -t $SESSION"
echo "Switch : Ctrl+b n/p  (next/prev window)"
echo "Pane   : Ctrl+b ←→   (switch pane)"
echo "Relay  : bash scripts/agent-relay.sh <from> <to> <message>"
echo "Bcast  : bash scripts/agent-broadcast.sh <from> <message>"
echo "Clean  : bash scripts/housekeeper-run.sh"
