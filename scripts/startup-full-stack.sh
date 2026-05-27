#!/bin/bash
# Full-stack startup: Wait for 9router → Start all services → Verify health

set -e

REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${WINDOWS_HOST_IP}:20128}"

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║              Full-Stack Startup: Executor Lane Router                 ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Wait for 9router
echo "📍 Step 1: Waiting for 9router on ${WINDOWS_HOST_IP}:20128..."
RETRY=0
MAX_RETRIES=30
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s "${ROUTER_BASE_URL}/v1/models" > /dev/null 2>&1; then
        echo "✅ 9router is online"
        break
    fi
    RETRY=$((RETRY + 1))
    echo "   ⏳ Retry $RETRY/$MAX_RETRIES... (waiting for 9router)"
    sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "❌ 9router not found on ${WINDOWS_HOST_IP}:20128"
    echo ""
    echo "Fix: Start 9router from Windows PowerShell:"
    echo "     & \"\$env:LOCALAPPDATA\\Volta\\bin\\9router.cmd\" --port 20128 --host 0.0.0.0 --no-browser --tray --skip-update"
    echo ""
    exit 1
fi

echo ""

# Step 2: Start WebSocket + API servers
echo "📍 Step 2: Starting real-time services..."
bash "$REPO_ROOT/server/run-realtime-services.sh" > /dev/null 2>&1 &
SERVICES_PID=$!
sleep 2
echo "✅ Services started (PID: $SERVICES_PID)"

echo ""

# Step 3: Verify all endpoints
echo "📍 Step 3: Health check..."
echo ""

# Check 9router
if curl -s "${ROUTER_BASE_URL}/v1/models" > /dev/null; then
    echo "  ✅ 9router (port 20128): ONLINE"
else
    echo "  ❌ 9router (port 20128): OFFLINE"
fi

# Check WebSocket
sleep 1
if lsof -i :8765 > /dev/null 2>&1 || netstat -tlnp 2>/dev/null | grep 8765 > /dev/null; then
    echo "  ✅ WebSocket (port 8765): ONLINE"
else
    echo "  ⏳ WebSocket (port 8765): Starting..."
fi

# Check API
sleep 1
if curl -s http://localhost:8766/health > /dev/null; then
    echo "  ✅ REST API (port 8766): ONLINE"
else
    echo "  ⏳ REST API (port 8766): Starting..."
fi

echo ""

# Step 4: Display dashboard URL
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                        🚀 READY TO USE 🚀                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Services Running:"
echo "  • 9router (Model routing):"
echo "    ${ROUTER_BASE_URL}/v1"
echo ""
echo "  • WebSocket (Real-time streaming):"
echo "    ws://localhost:8765"
echo ""
echo "  • REST API (Historical queries):"
echo "    http://localhost:8766"
echo ""
echo "Open Dashboard:"
echo "  file://$REPO_ROOT/dashboard/realtime-dashboard.html"
echo ""
echo "Test APIs:"
echo "  curl ${ROUTER_BASE_URL}/v1/models         # List models"
echo "  curl http://localhost:8766/health              # API health"
echo "  curl http://localhost:8766/api/proofs?date=2026-05-17  # Proofs"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "ธาม ready. Press Ctrl+C to stop all services."
echo ""

# Keep running
wait $SERVICES_PID
