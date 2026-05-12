#!/usr/bin/env bash
# Start or attach to the Tham Oracle tmux session.
# Usage: ./scripts/oracle-session.sh [attach-only]

SESSION="oracle"
REPO="/root/repos/tham-oracle"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already running — attaching..."
  tmux attach-session -t "$SESSION"
  exit 0
fi

# Window 0: oracle chat (claude)
tmux new-session -d -s "$SESSION" -n "chat" -c "$REPO"
tmux send-keys -t "$SESSION:chat" "claude" Enter

# Window 1: free shell
tmux new-window -t "$SESSION" -n "shell" -c "$REPO"

# Window 2: brain / logs viewer
tmux new-window -t "$SESSION" -n "brain" -c "$REPO/brain"
tmux send-keys -t "$SESSION:brain" "ls -la" Enter

# Return to chat window
tmux select-window -t "$SESSION:chat"

echo "Oracle session started. Windows: chat | shell | brain"
tmux attach-session -t "$SESSION"
