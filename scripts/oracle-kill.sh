#!/usr/bin/env bash
# Kill the Tham Oracle tmux session.

SESSION="oracle"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
  echo "Session '$SESSION' killed."
else
  echo "No session '$SESSION' found."
fi
