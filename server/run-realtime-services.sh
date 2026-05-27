#!/bin/bash
# Phase 4E: Run Real-time Services
# Starts WebSocket server, Proof watcher, terminal dashboard, and API server together
# Usage: bash server/run-realtime-services.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="$REPO_ROOT/server"
LOGS_DIR="$REPO_ROOT/logs"
TERMINAL_PORT="${TERMINAL_PORT:-3002}"
TERMINAL_SESSION="${THAM_ORACLE_SESSION:-${TMUX_SESSION:-tham-oracle-stack}}"

mkdir -p "$LOGS_DIR"

cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    jobs -p | xargs -r kill 2>/dev/null || true
    wait 2>/dev/null || true
    echo "✓ Services stopped"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

echo "🚀 Starting Real-time Services"
echo ""

# Start API server
echo "📡 Starting Proof Playback API on http://localhost:8766..."
python3 "$SERVER_DIR/proof-playback-api.py" > "$LOGS_DIR/api-server.log" 2>&1 &
API_PID=$!
sleep 1
if curl -s http://localhost:8766/health >/dev/null 2>&1; then
    echo "  ✅ API server running"
else
    echo "  ⚠️  API server not responding yet"
fi

# Start WebSocket server (optional dependency)
echo "📡 Starting WebSocket Server on ws://localhost:8765..."
if python3 -c "import websockets" 2>/dev/null; then
    python3 "$SERVER_DIR/websocket-server.py" > "$LOGS_DIR/websocket-server.log" 2>&1 &
    WS_PID=$!
    sleep 1
    echo "  ✅ WebSocket server started"
else
    echo "  ⚠️  websockets package not installed"
    echo "  💡  Install: pip install websockets"
    echo "  💡  Dashboard will use API polling fallback"
fi

# Start terminal dashboard (tmux pane viewer + command input)
echo "🖥️  Starting Terminal Dashboard on http://localhost:${TERMINAL_PORT}..."
if command -v node >/dev/null 2>&1; then
    THAM_ORACLE_SESSION="$TERMINAL_SESSION" node "$REPO_ROOT/scripts/terminal-server.js" "$TERMINAL_PORT" "$TERMINAL_SESSION" > "$LOGS_DIR/terminal-server.log" 2>&1 &
    TERM_PID=$!
    sleep 1
    echo "  ✅ Terminal dashboard started"
else
    echo "  ⚠️  node not found; terminal dashboard unavailable"
fi

echo ""
echo "✅ Services running:"
echo "   API:       http://localhost:8766/api/dashboard?date=$(date +%Y-%m-%d)"
echo "   WebSocket: ws://localhost:8765 (if websockets installed)"
echo "   Terminal:  http://localhost:${TERMINAL_PORT} (session: ${TERMINAL_SESSION})"
echo "   Dashboard:  file://$REPO_ROOT/dashboard/realtime-dashboard.html"
echo ""
echo "Logs:"
echo "   API:       $LOGS_DIR/api-server.log"
echo "   WebSocket: $LOGS_DIR/websocket-server.log"
echo "   Terminal:  $LOGS_DIR/terminal-server.log"
echo ""
echo "Press Ctrl+C to stop services"
echo ""

wait
