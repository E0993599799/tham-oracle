#!/bin/bash
# Spawn all agents via tmux session
# Usage: bash scripts/spawn-agents-tmux.sh

set -e

SESSION="tham-oracle-stack"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${WINDOWS_HOST_IP}:20128}"
ROUTER_WAIT_SECS="${ROUTER_WAIT_SECS:-60}"
ROUTER_POLL_SECS="${ROUTER_POLL_SECS:-2}"

wait_for_router() {
  echo "🔎 Waiting for 9router at ${WINDOWS_HOST_IP}:20128..."
  local waited=0
  while [ "$waited" -lt "$ROUTER_WAIT_SECS" ]; do
    if timeout 2 curl -s "${ROUTER_BASE_URL}/v1/models" >/dev/null 2>&1; then
      echo "✅ 9router ready: ${ROUTER_BASE_URL}/v1/models"
      return 0
    fi
    waited=$((waited + ROUTER_POLL_SECS))
    echo "   ⏳ ${waited}/${ROUTER_WAIT_SECS}s"
    sleep "$ROUTER_POLL_SECS"
  done
  echo "❌ 9router not ready after ${ROUTER_WAIT_SECS}s"
  echo "   Start on Windows with: powershell -ExecutionPolicy Bypass -File scripts\\Start-9router.ps1"
  return 1
}

echo "🚀 Spawning Tham Oracle agents via tmux..."
echo ""

if ! wait_for_router; then
  exit 1
fi

echo ""

# Kill existing session if running
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "⚠️  Session $SESSION already exists. Killing..."
  tmux kill-session -t "$SESSION"
fi

# Create new session
echo "📌 Creating tmux session: $SESSION"
tmux new-session -d -s "$SESSION" -x 250 -y 50

# Pane 0: Tham Orchestrator (port 47778)
echo "  1️⃣  tham orchestrator (port 47778)"
tmux send-keys -t "$SESSION:0" "cd '$REPO_DIR' && echo '=== THAM ORCHESTRATOR ===' && sleep 2" C-m

# Pane 1: Core/Omega (port 47779)
echo "  2️⃣  core/omega (port 47779)"
tmux new-window -t "$SESSION:1" -n "core"
tmux send-keys -t "$SESSION:1" "cd '$REPO_DIR' && echo '=== CORE BRIDGE/GATE ===' && sleep 2" C-m

# Pane 2: Codex Agent
echo "  3️⃣  codex builder (9router)"
tmux new-window -t "$SESSION:2" -n "codex"
tmux send-keys -t "$SESSION:2" "cd '$REPO_DIR' && echo '=== CODEX BUILDER ===' && sleep 2" C-m

# Pane 3: Gemini Agent
echo "  4️⃣  gemini inspector (9router)"
tmux new-window -t "$SESSION:3" -n "gemini"
tmux send-keys -t "$SESSION:3" "cd '$REPO_DIR' && echo '=== GEMINI INSPECTOR ===' && sleep 2" C-m

# Pane 4: BoB Coordinator
echo "  5️⃣  bob coordinator"
tmux new-window -t "$SESSION:4" -n "bob"
tmux send-keys -t "$SESSION:4" "cd '$REPO_DIR' && echo '=== BOB COORDINATOR ===' && sleep 2" C-m

# Pane 5: Hermes Reviewer
echo "  6️⃣  hermes reviewer"
tmux new-window -t "$SESSION:5" -n "hermes"
tmux send-keys -t "$SESSION:5" "cd '$REPO_DIR' && echo '=== HERMES REVIEWER ===' && sleep 2" C-m

# Pane 6: Housekeeper Maintenance
echo "  7️⃣  housekeeper maintenance"
tmux new-window -t "$SESSION:6" -n "housekeeper"
tmux send-keys -t "$SESSION:6" "cd '$REPO_DIR' && echo '=== HOUSEKEEPER MAINTENANCE ===' && sleep 2" C-m

# Pane 7: Watchdog Monitor
echo "  8️⃣  watchdog system monitor"
tmux new-window -t "$SESSION:7" -n "watchdog"
tmux send-keys -t "$SESSION:7" "cd '$REPO_DIR' && echo '=== WATCHDOG MONITOR ===' && sleep 2" C-m

echo ""
echo "✅ Agent spawn complete!"
echo ""
echo "📊 Active tmux session:"
echo "   Session: $SESSION"
echo "   Windows:"
tmux list-windows -t "$SESSION"
echo ""
echo "🎯 Commands:"
echo "   Attach:  tmux attach -t $SESSION"
echo "   Detach:  Ctrl+B, D"
echo "   Navigate: Ctrl+B, [0-7]"
echo "   Kill:    tmux kill-session -t $SESSION"
echo ""
