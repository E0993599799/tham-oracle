#!/usr/bin/env bash
# Start full local Oracle stack in tmux session: oracle-v2 HTTP + Oracle Studio.
# Session name: tham-oracle-stack
# oracle-v2 HTTP: port 47778
# Oracle Studio:  port 3000

SESSION="tham-oracle-stack"
REPO="/root/repos/tham-oracle"
API_PORT="47778"
STUDIO_PORT="3000"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already running."
  echo "Attach: tmux attach -t $SESSION"
  exit 0
fi

# Window 0: oracle-v2 HTTP server
tmux new-session -d -s "$SESSION" -n "oracle-v2" -c "$REPO"
tmux send-keys -t "$SESSION:oracle-v2" \
  "bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main --http --port $API_PORT" \
  Enter

# Window 1: Oracle Studio
tmux new-window -t "$SESSION" -n "studio" -c "$REPO"
tmux send-keys -t "$SESSION:studio" \
  "sleep 3 && bunx oracle-studio --api http://localhost:${API_PORT} --port $STUDIO_PORT" \
  Enter

# Window 2: logs
tmux new-window -t "$SESSION" -n "logs" -c "$REPO"
tmux send-keys -t "$SESSION:logs" \
  "tail -f .oracle-setup/logs/oracle-v2-http.log 2>/dev/null || echo 'no log yet'" \
  Enter

tmux select-window -t "$SESSION:oracle-v2"

echo "Stack session started: $SESSION"
echo "  oracle-v2 HTTP → http://localhost:${API_PORT}"
echo "  Oracle Studio  → http://localhost:${STUDIO_PORT}"
echo "Attach: tmux attach -t $SESSION"
