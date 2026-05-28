#!/usr/bin/env bash
# Start oracle-v2 HTTP servers (tham: 47778, omega: 47779) in background.
# Usage: start-oracle-v2-http.sh [port]
#   no args  → start BOTH 47778 and 47779
#   47778    → start tham only
#   47779    → start omega only

LOG_DIR="/route/mission-control/tham-oracle/.oracle-setup/logs"
mkdir -p "$LOG_DIR"

start_instance() {
  local PORT="$1"
  local LABEL="$2"
  local LOG="$LOG_DIR/oracle-v2-${PORT}.log"

  # Skip if already running
  if curl -s --max-time 1 "http://localhost:${PORT}/" > /dev/null 2>&1; then
    echo "✓ oracle-v2 ${LABEL} already running at http://localhost:${PORT}"
    return 0
  fi

  echo "Starting oracle-v2 ${LABEL} on port ${PORT}..."
  ORACLE_PORT="$PORT" nohup bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main \
    --http --port "$PORT" \
    > "$LOG" 2>&1 &

  local PID=$!
  echo "$PID" > "/tmp/oracle-v2-${PORT}.pid"
  echo "  PID: $PID — log: $LOG"
  sleep 2

  if curl -s --max-time 2 "http://localhost:${PORT}/" > /dev/null 2>&1; then
    echo "✓ oracle-v2 ${LABEL} running at http://localhost:${PORT}"
  else
    echo "CHECK — server may still be starting. Check: $LOG"
  fi
}

REQUESTED="${1:-all}"

if [ "$REQUESTED" = "47778" ]; then
  start_instance 47778 "tham"
elif [ "$REQUESTED" = "47779" ]; then
  start_instance 47779 "omega"
else
  start_instance 47778 "tham"
  start_instance 47779 "omega"
fi
