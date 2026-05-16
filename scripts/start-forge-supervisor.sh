#!/usr/bin/env bash
# Tham Oracle — Start Forge Supervisor Runtime (port 8769)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPERVISOR="${REPO_ROOT}/scripts/forge-supervisor/supervisor.py"
SESSION="forge-supervisor"
PORT="${FORGE_SUPERVISOR_PORT:-8769}"

echo "🔮 Forge Supervisor Runtime"
echo ""

command -v python3 >/dev/null || { echo "❌ python3 not found"; exit 1; }

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "⚠️  Killing existing session: $SESSION"
  tmux kill-session -t "$SESSION"
fi

echo "🚀 Starting Forge Supervisor on port $PORT..."
tmux new-session -d -s "$SESSION" -x 220 -y 50 \
  "cd $REPO_ROOT && THAM_REPO_ROOT=$REPO_ROOT FORGE_SUPERVISOR_PORT=$PORT python3 $SUPERVISOR"

sleep 1

if curl -sf "http://localhost:$PORT/" >/dev/null 2>&1; then
  echo "✅ Forge Supervisor running on http://localhost:$PORT"
  echo ""
  echo "  GET  /status    — runtime status"
  echo "  GET  /sessions  — all agent sessions"
  echo "  GET  /goals     — goal queue"
  echo "  GET  /health    — watchdog health"
  echo "  POST /sessions  — register new agent"
  echo "  POST /goal      — submit /goal"
  echo ""
  echo "Attach: tmux attach -t $SESSION"
else
  echo "❌ Supervisor failed to start on port $PORT"
  echo "Check: tmux attach -t $SESSION"
fi
