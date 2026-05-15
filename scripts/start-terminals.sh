#!/usr/bin/env bash
# start-terminals.sh — Serve the Fleet Terminal Dashboard on port 3002.
# Shows live tmux pane content for all oracle-fleet windows.
#
# Usage: bash scripts/start-terminals.sh [port] [session]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-3002}"
SESSION="${2:-oracle-fleet}"
NODE="${HOME}/.nvm/versions/node/v24.15.0/bin/node"

# Fallback to system node
if [ ! -x "$NODE" ]; then
  NODE="$(command -v node 2>/dev/null || true)"
fi

if [ -z "$NODE" ]; then
  echo "ERROR: node not found — install via nvm: nvm install 24"
  exit 1
fi

echo "Omega OS Fleet Terminal Dashboard"
echo "  Session  : $SESSION"
echo "  Port     : $PORT"
echo "  URL      : http://localhost:$PORT"
echo ""

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "⚠ Session '$SESSION' not running — dashboard will show empty state."
  echo "  Start it: bash scripts/oracle-fleet.sh"
  echo ""
fi

exec "$NODE" "$REPO_ROOT/scripts/terminal-server.js" "$PORT" "$SESSION"
