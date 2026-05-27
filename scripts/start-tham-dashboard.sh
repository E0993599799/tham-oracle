#!/usr/bin/env bash
# start-tham-dashboard.sh — Start Tham Oracle Next.js Dashboard on port 3005
# Sections: Fleet (34 oracles), Git, Memory Gate, Session Metrics, Queue

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DASH_DIR="$REPO_ROOT/dashboard-next"
PORT="${1:-3005}"

export THAM_REPO_ROOT="$REPO_ROOT"

echo "=== Tham Oracle Dashboard ==="
echo "  Repo:   $REPO_ROOT"
echo "  Dir:    $DASH_DIR"
echo "  Port:   $PORT"
echo ""

if [ ! -d "$DASH_DIR/node_modules" ]; then
  echo "Installing dependencies..."
  bun install --cwd "$DASH_DIR"
fi

if [ ! -d "$DASH_DIR/.next" ]; then
  echo "Building..."
  bun run --cwd "$DASH_DIR" build
fi

echo "  Dashboard → http://localhost:$PORT"
echo "  Ctrl+C to stop"
echo ""

cd "$DASH_DIR"
exec "$DASH_DIR/node_modules/.bin/next" start -p "$PORT"
