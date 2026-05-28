#!/usr/bin/env bash
# Start oracle-v2 HTTP server (port 47778) in background.
# Required before running Oracle Studio.

PORT="${ORACLE_PORT:-47778}"
LOG="/route/mission-control/tham-oracle/.oracle-setup/logs/oracle-v2-http.log"

mkdir -p "$(dirname "$LOG")"

echo "Starting oracle-v2 HTTP server on port $PORT..."
nohup bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main \
  --http --port "$PORT" \
  > "$LOG" 2>&1 &

PID=$!
echo "$PID" > /tmp/oracle-v2-http.pid
echo "PID: $PID — log: $LOG"
sleep 2

# Probe
if curl -s "http://localhost:${PORT}/health" > /dev/null 2>&1; then
  echo "✓ oracle-v2 HTTP running at http://localhost:${PORT}"
else
  echo "CHECK — server may still be starting. Check log: $LOG"
fi
