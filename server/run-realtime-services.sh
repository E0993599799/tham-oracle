#!/bin/bash
# Phase 4E: Run Real-time Services
# Starts WebSocket server, Proof watcher, and API server together
# Usage: bash server/run-realtime-services.sh

set -e

REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
SERVER_DIR="$REPO_ROOT/server"
LOGS_DIR="$REPO_ROOT/logs"

# Create logs directory
mkdir -p "$LOGS_DIR"

# Cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    jobs -p | xargs -r kill 2>/dev/null || true
    wait
    echo "✓ Services stopped"
    exit 0
}
trap cleanup SIGINT SIGTERM

# Start services
echo "🚀 Starting Real-time Services"
echo ""

# Start API server (uses stdlib, doesn't need websockets)
echo "📡 Starting Proof Playback API on http://localhost:8766..."
python3 "$SERVER_DIR/proof-playback-api.py" > "$LOGS_DIR/api-server.log" 2>&1 &
API_PID=$!
sleep 1

# Test API health
if curl -s http://localhost:8766/health >/dev/null 2>&1; then
    echo "  ✅ API server running"
else
    echo "  ⚠️  API server not responding yet"
fi

# Try to start WebSocket server (requires websockets package)
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

echo ""
echo "✅ Services running:"
echo "   API:       http://localhost:8766/api/proofs?date=$(date +%Y-%m-%d)"
echo "   WebSocket: ws://localhost:8765 (if websockets installed)"
echo "   Dashboard: file://$REPO_ROOT/dashboard/realtime-dashboard.html"
echo ""
echo "Logs:"
echo "   API:       $LOGS_DIR/api-server.log"
echo "   WebSocket: $LOGS_DIR/websocket-server.log"
echo ""
echo "Press Ctrl+C to stop services"
echo ""

# Keep script running
wait $API_PID 2>/dev/null || true
