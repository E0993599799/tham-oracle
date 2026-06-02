#!/usr/bin/env bash
# Start a cloudflared quick-tunnel exposing oracle-v2 to the internet.
# Prints the public URL — copy it and set as ORACLE_URL in the worker:
#   cd workers/webhook-relay && npx wrangler secret put ORACLE_URL
#
# Usage: bash scripts/start-oracle-tunnel.sh [--bg]
# Install cloudflared once: sudo apt-get install cloudflared
#                           OR: curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && chmod +x /usr/local/bin/cloudflared

set -euo pipefail

PORT="${ORACLE_PORT:-47778}"
LOG="/route/mission-control/tham-oracle/.oracle-setup/logs/oracle-tunnel.log"
PID_FILE="/tmp/oracle-tunnel.pid"

mkdir -p "$(dirname "$LOG")"

if [ "${1:-}" = "--bg" ]; then
  nohup bash "$0" > "$LOG" 2>&1 &
  echo "$!" > "$PID_FILE"
  echo "Tunnel starting in background — watch: tail -f $LOG"
  exit 0
fi

# Wait for oracle-v2 to be up
for i in $(seq 1 10); do
  if curl -s "http://localhost:${PORT}/" > /dev/null 2>&1; then
    break
  fi
  echo "Waiting for oracle-v2 on :${PORT}... ($i/10)"
  sleep 2
done

# Quick tunnel (no login required) — URL printed to stdout
# Capture the URL line for easy copy-paste
cloudflared tunnel --url "http://localhost:${PORT}" 2>&1 | tee -a "$LOG" | \
  grep --line-buffered -E "https://[a-z0-9-]+\.trycloudflare\.com"
