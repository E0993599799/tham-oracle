#!/bin/bash
# Test Telegram connection and send test message

export TZ='Asia/Bangkok'

PROJECT_DIR="/root/ghq/github.com/E0993599799/tham-oracle"
TELEGRAM_CONFIG="$PROJECT_DIR/.telegram-config"
TEST_LOG="$PROJECT_DIR/reports/telegram-test.log"

mkdir -p "$(dirname "$TEST_LOG")"

echo "🤖 Telegram Connection Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

# Check if config exists
if [ ! -f "$TELEGRAM_CONFIG" ]; then
  echo "❌ ERROR: .telegram-config not found" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "📋 SETUP NEEDED:" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Step 1: Get Telegram Bot Token" | tee -a "$TEST_LOG"
  echo "  • Open Telegram app" | tee -a "$TEST_LOG"
  echo "  • Search for @BotFather" | tee -a "$TEST_LOG"
  echo "  • Send: /newbot" | tee -a "$TEST_LOG"
  echo "  • Follow instructions" | tee -a "$TEST_LOG"
  echo "  • Copy the token (example: 123456:ABC-DEF1234ghIkl...)" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Step 2: Get Your Telegram Chat ID" | tee -a "$TEST_LOG"
  echo "  • Search for @userinfobot" | tee -a "$TEST_LOG"
  echo "  • Send any message to it" | tee -a "$TEST_LOG"
  echo "  • Bot replies with your User ID" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Step 3: Create .telegram-config" | tee -a "$TEST_LOG"
  echo "  cp $PROJECT_DIR/.telegram-config.example $TELEGRAM_CONFIG" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Step 4: Edit .telegram-config with your credentials" | tee -a "$TEST_LOG"
  echo "  export TELEGRAM_BOT_TOKEN='your-bot-token'" | tee -a "$TEST_LOG"
  echo "  export TELEGRAM_CHAT_ID='your-chat-id'" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Step 5: Run this test again" | tee -a "$TEST_LOG"
  echo "  bash $PROJECT_DIR/scripts/test-telegram.sh" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  exit 1
fi

echo "📋 Loading configuration..." | tee -a "$TEST_LOG"
source "$TELEGRAM_CONFIG"

# Validate credentials
if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
  echo "❌ ERROR: TELEGRAM_BOT_TOKEN is empty" | tee -a "$TEST_LOG"
  exit 1
fi

if [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "❌ ERROR: TELEGRAM_CHAT_ID is empty" | tee -a "$TEST_LOG"
  exit 1
fi

echo "✅ Config loaded successfully" | tee -a "$TEST_LOG"
echo "   Bot Token: ${TELEGRAM_BOT_TOKEN:0:20}..." | tee -a "$TEST_LOG"
echo "   Chat ID: $TELEGRAM_CHAT_ID" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

# Send test message
TIMESTAMP=$(date '+%d_%b_%y:%H:%M:%S')
TEST_MSG="🤖 *Oracle Test Message*

✅ Connection test successful
⏰ Time: $TIMESTAMP (GMT+7)

Status: Telegram integration working! 🎉"

echo "📨 Sending test message..." | tee -a "$TEST_LOG"

RESPONSE=$(curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=${TEST_MSG}" \
  -d "parse_mode=Markdown")

echo "$RESPONSE" | tee -a "$TEST_LOG"
echo "" | tee -a "$TEST_LOG"

# Check result
if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "✅ SUCCESS! Message sent to Telegram" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "📱 Check your Telegram:" | tee -a "$TEST_LOG"
  echo "   1. Open Telegram app" | tee -a "$TEST_LOG"
  echo "   2. Look for message from your bot" | tee -a "$TEST_LOG"
  echo "   3. You should see the test message above" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "✨ Telegram integration is working!" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$TEST_LOG"
  exit 0
else
  echo "❌ FAILED! Could not send message" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Possible issues:" | tee -a "$TEST_LOG"
  echo "  • Invalid bot token" | tee -a "$TEST_LOG"
  echo "  • Invalid chat ID" | tee -a "$TEST_LOG"
  echo "  • Network connectivity issue" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "Log saved to: $TEST_LOG" | tee -a "$TEST_LOG"
  echo "" | tee -a "$TEST_LOG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$TEST_LOG"
  exit 1
fi
