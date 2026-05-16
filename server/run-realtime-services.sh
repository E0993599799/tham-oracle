#!/bin/bash

# Start all real-time services for the Router Live Dashboard
# Usage: bash server/run-realtime-services.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$REPO_ROOT/logs"

# Create logs directory
mkdir -p "$LOG_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Router Live Dashboard - Service Runner${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Start WebSocket server
echo -e "${YELLOW}Starting WebSocket server...${NC}"
python3 "$SCRIPT_DIR/websocket-server.py" > "$LOG_DIR/websocket-server.log" 2>&1 &
WS_PID=$!
sleep 1

if ! kill -0 $WS_PID 2>/dev/null; then
    echo -e "${RED}✗ WebSocket server failed to start${NC}"
    tail -20 "$LOG_DIR/websocket-server.log"
    exit 1
fi

echo -e "${GREEN}✓ WebSocket server started (PID: $WS_PID)${NC}"

# Start API server
echo -e "${YELLOW}Starting Playback API server...${NC}"
python3 "$SCRIPT_DIR/proof-playback-api.py" > "$LOG_DIR/api-server.log" 2>&1 &
API_PID=$!
sleep 1

if ! kill -0 $API_PID 2>/dev/null; then
    echo -e "${RED}✗ API server failed to start${NC}"
    tail -20 "$LOG_DIR/api-server.log"
    kill $WS_PID 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}✓ API server started (PID: $API_PID)${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All services started successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Services:${NC}"
echo -e "  WebSocket: ${GREEN}ws://localhost:8765${NC} (PID: $WS_PID)"
echo -e "  API:       ${GREEN}http://localhost:8766${NC} (PID: $API_PID)"
echo ""
echo -e "${BLUE}Dashboard:${NC}"
echo -e "  ${GREEN}file:///$REPO_ROOT/dashboard/realtime-dashboard.html${NC}"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo -e "  WebSocket: $LOG_DIR/websocket-server.log"
echo -e "  API:       $LOG_DIR/api-server.log"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services...${NC}"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping services...${NC}"
    kill $WS_PID 2>/dev/null || true
    kill $API_PID 2>/dev/null || true

    # Wait for processes to terminate
    sleep 1

    if ! kill -0 $WS_PID 2>/dev/null && ! kill -0 $API_PID 2>/dev/null; then
        echo -e "${GREEN}✓ WebSocket server stopped${NC}"
        echo -e "${GREEN}✓ API server stopped${NC}"
    else
        # Force kill if needed
        kill -9 $WS_PID 2>/dev/null || true
        kill -9 $API_PID 2>/dev/null || true
    fi

    echo ""
    echo -e "${GREEN}✅ All services stopped.${NC}"
    exit 0
}

# Set trap to cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Keep script running
while true; do
    # Check if either process died unexpectedly
    if ! kill -0 $WS_PID 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}⚠ WebSocket server crashed. Restarting in 5s...${NC}"
        sleep 5
        python3 "$SCRIPT_DIR/websocket-server.py" >> "$LOG_DIR/websocket-server.log" 2>&1 &
        WS_PID=$!
        echo -e "${GREEN}✓ WebSocket server restarted (PID: $WS_PID)${NC}"
    fi

    if ! kill -0 $API_PID 2>/dev/null; then
        echo ""
        echo -e "${YELLOW}⚠ API server crashed. Restarting in 5s...${NC}"
        sleep 5
        python3 "$SCRIPT_DIR/proof-playback-api.py" >> "$LOG_DIR/api-server.log" 2>&1 &
        API_PID=$!
        echo -e "${GREEN}✓ API server restarted (PID: $API_PID)${NC}"
    fi

    sleep 5
done
