#!/bin/bash
#
# Phase 5E: Run Telegram Services — Orchestrate all Telegram bot components
#
# Starts:
# - 5A: telegram-bot.py (Flask webhook receiver on port 8767)
# - 5B: proof-notifier.py (background proof monitor)
# - Also requires Phase 4 services running (API on 8766, WebSocket on 8765)
#
# Usage:
#   bash server/run-telegram-services.sh
#   TELEGRAM_BOT_TOKEN=YOUR_TOKEN bash server/run-telegram-services.sh
#
# Environment:
#   TELEGRAM_BOT_TOKEN (required) — bot token from @BotFather
#   TELEGRAM_WEBHOOK_URL (optional) — webhook URL for Telegram (default: http://localhost:8767)
#   TELEGRAM_AUTHORIZED_USERS (optional) — comma-separated user IDs (default: all)
#

set -e

REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
SERVER_DIR="$REPO_ROOT/server"
LOG_DIR="$REPO_ROOT/logs"

# Create logs directory
mkdir -p "$LOG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Signal handlers
cleanup() {
    echo -e "${YELLOW}Shutting down Telegram services...${NC}"

    # Kill all background jobs
    jobs -p | xargs -r kill 2>/dev/null || true

    echo -e "${GREEN}All services stopped.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo -e "${RED}ERROR: TELEGRAM_BOT_TOKEN not set${NC}"
        echo "  Set: export TELEGRAM_BOT_TOKEN='your-bot-token'"
        exit 1
    fi

    echo -e "${GREEN}✓ Bot token configured${NC}"

    # Check if Phase 4 API is running
    if ! curl -s http://localhost:8766/health > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Phase 4 API (port 8766) not responding${NC}"
        echo "  Start Phase 4 services: bash server/run-realtime-services.sh"
    else
        echo -e "${GREEN}✓ Phase 4 API is running${NC}"
    fi
}

# Start telegram-bot (5A) — webhook receiver
start_telegram_bot() {
    echo -e "${YELLOW}Starting telegram-bot.py (5A, port 8767)...${NC}"

    cd "$REPO_ROOT"
    python3 "$SERVER_DIR/telegram-bot.py" \
        > "$LOG_DIR/telegram-bot.log" 2>&1 &

    BOT_PID=$!
    echo $BOT_PID > "$LOG_DIR/telegram-bot.pid"
    echo -e "${GREEN}✓ telegram-bot started (PID: $BOT_PID)${NC}"
}

# Start proof-notifier (5B) — proof monitor
start_proof_notifier() {
    echo -e "${YELLOW}Starting proof-notifier.py (5B)...${NC}"

    cd "$REPO_ROOT"
    python3 "$SERVER_DIR/proof-notifier.py" \
        > "$LOG_DIR/proof-notifier.log" 2>&1 &

    NOTIFIER_PID=$!
    echo $NOTIFIER_PID > "$LOG_DIR/proof-notifier.pid"
    echo -e "${GREEN}✓ proof-notifier started (PID: $NOTIFIER_PID)${NC}"
}

# Main
main() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Omega OS — Telegram Services (Phase 5)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""

    check_prerequisites

    echo ""
    echo -e "${YELLOW}Starting services...${NC}"
    echo ""

    start_telegram_bot
    sleep 1

    start_proof_notifier
    sleep 1

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}All Telegram services started${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Logs:"
    echo "  - Bot:       $LOG_DIR/telegram-bot.log"
    echo "  - Notifier:  $LOG_DIR/proof-notifier.log"
    echo ""
    echo "Bot webhook listening on: http://localhost:8767/webhook"
    echo ""
    echo "Press Ctrl+C to stop all services"
    echo ""

    # Wait for background jobs
    wait
}

main "$@"
