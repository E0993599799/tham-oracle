#!/usr/bin/env bash
# Start or attach to the Tham Oracle tmux session.
# Usage: ./scripts/oracle-session.sh [attach-only]

SESSION="oracle"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MODE="${1:-detach}"
ATTACH=0
case "$MODE" in
  attach|--attach)
    ATTACH=1
    ;;
  detach|--detach|"")
    ATTACH=0
    ;;
  *)
    echo "Usage: $0 [detach|attach]"
    exit 1
    ;;
esac

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already running."
  if [ "$ATTACH" -eq 1 ]; then
    tmux attach-session -t "$SESSION"
  else
    echo "Attach: tmux attach-session -t '$SESSION'"
  fi
  exit 0
fi

# Start oracle-v2 HTTP in background (silent, no popup)
bash "$REPO/scripts/start-oracle-v2-http.sh" > /dev/null 2>&1 &

# Start maw server in background if not running
if ! curl -s http://localhost:3456/health > /dev/null 2>&1; then
  maw bg "maw serve" --name maw-server > /dev/null 2>&1 || true
fi

# Ensure cron is running for 5-min memory auto-save fallback
if ! pgrep -x cron > /dev/null 2>&1; then
  sudo /usr/sbin/service cron start > /dev/null 2>&1 || true
fi

# Window 0: oracle chat (claude)
tmux new-session -d -s "$SESSION" -n "chat" -c "$REPO"
tmux send-keys -t "$SESSION:chat" "claude" Enter

# Window 1: memory gate — auto-read on open
tmux new-window -t "$SESSION" -n "memory" -c "$REPO"
tmux send-keys -t "$SESSION:memory" "bash $REPO/scripts/memory-read.sh" Enter

# Window 2: free shell
tmux new-window -t "$SESSION" -n "shell" -c "$REPO"

# Window 3: brain / logs viewer
tmux new-window -t "$SESSION" -n "brain" -c "$REPO/brain"
tmux send-keys -t "$SESSION:brain" "ls -la" Enter

# Return to chat window
tmux select-window -t "$SESSION:chat"

echo "Oracle session started. Windows: chat | memory | shell | brain"
if [ "$ATTACH" -eq 1 ]; then
  tmux attach-session -t "$SESSION"
else
  echo "Attach: tmux attach-session -t '$SESSION'"
fi
