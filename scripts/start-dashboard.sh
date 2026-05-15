#!/usr/bin/env bash
# start-dashboard.sh — Serve the Omega OS Fleet Dashboard on port 3001.
# Also runs dashboard-update.sh every 15s in background to keep data.json live.
#
# Usage: bash scripts/start-dashboard.sh [port]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DASH_DIR="$REPO_ROOT/dashboard"
PORT="${1:-3001}"
UPDATE_SCRIPT="$REPO_ROOT/scripts/dashboard-update.sh"

echo "Starting Omega OS Fleet Dashboard on port $PORT..."
echo "Dashboard dir: $DASH_DIR"
echo ""

# Initial data.json generation
bash "$UPDATE_SCRIPT"

# Background updater — runs every 15s
(
  while true; do
    sleep 15
    bash "$UPDATE_SCRIPT" 2>/dev/null || true
  done
) &
UPDATER_PID=$!

echo "Data updater running (PID $UPDATER_PID) — every 15s"
echo "Dashboard: http://localhost:$PORT"
echo ""
echo "Ctrl+C to stop"

cleanup() {
  kill "$UPDATER_PID" 2>/dev/null || true
  echo "Dashboard stopped."
}
trap cleanup EXIT INT TERM

# Serve with Python (available in WSL) or Node
if command -v python3 &>/dev/null; then
  cd "$DASH_DIR"
  exec python3 -m http.server "$PORT"
elif command -v node &>/dev/null; then
  exec node -e "
    const http = require('http');
    const fs = require('fs');
    const path = require('path');
    const dir = '${DASH_DIR}';
    const mime = {'.html':'text/html','.json':'application/json','.js':'text/javascript','.css':'text/css'};
    http.createServer((req, res) => {
      const file = path.join(dir, req.url === '/' ? 'index.html' : req.url);
      fs.readFile(file, (err, data) => {
        if (err) { res.writeHead(404); res.end('Not found'); return; }
        res.writeHead(200, {'Content-Type': mime[path.extname(file)] || 'text/plain'});
        res.end(data);
      });
    }).listen(${PORT}, () => console.log('Listening on :${PORT}'));
  "
else
  echo "ERROR: neither python3 nor node found — cannot serve dashboard"
  exit 1
fi
