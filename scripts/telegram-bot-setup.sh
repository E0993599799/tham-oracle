#!/bin/bash
# Telegram Bot Setup — Bidirectional messaging without credential rotation
# Messages from Oracle → Telegram (human-readable)
# Messages from Telegram → Prompts to this channel

export TZ='Asia/Bangkok'

PROJECT_DIR="/root/ghq/github.com/E0993599799/tham-oracle"
TELEGRAM_CONFIG="$PROJECT_DIR/.telegram-config"
TELEGRAM_LOG="$PROJECT_DIR/reports/telegram-activity.log"

mkdir -p "$(dirname "$TELEGRAM_LOG")"

echo "🤖 Telegram Bot Setup — Bidirectional Connection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Check if credentials exist
echo "1️⃣ Checking Telegram credentials..."
if [ -f "$TELEGRAM_CONFIG" ]; then
  echo "   ✅ Telegram config found"
  source "$TELEGRAM_CONFIG"
  echo "   Bot Token: ${TELEGRAM_BOT_TOKEN:0:10}***"
  echo "   Chat ID: $TELEGRAM_CHAT_ID"
else
  echo "   ⚠️ Telegram config not found"
  echo ""
  echo "   To set up, create $TELEGRAM_CONFIG with:"
  echo "   export TELEGRAM_BOT_TOKEN='your-bot-token-here'"
  echo "   export TELEGRAM_CHAT_ID='your-chat-id-here'"
  echo ""
  echo "   Get token from: @BotFather on Telegram"
  exit 1
fi

echo ""
echo "2️⃣ Testing Telegram connection..."

# Test message to Telegram
TEST_MESSAGE="🤖 Oracle Test Message at $(date '+%d_%b_%y:%H:%M:%S')"

RESPONSE=$(curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=${TEST_MESSAGE}" \
  -d "parse_mode=HTML")

if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "   ✅ Telegram connection working"
  echo "   Message sent successfully"
  echo "   Log: $TELEGRAM_LOG"
else
  echo "   ❌ Telegram connection failed"
  echo "   Response: $RESPONSE"
  exit 1
fi

echo ""
echo "3️⃣ Setting up message listeners..."
echo "   Starting Telegram message listener..."
echo "   Listening for messages in: $TELEGRAM_CHAT_ID"
echo ""

# Create listener script
cat > "$PROJECT_DIR/scripts/telegram-listener.sh" << 'LISTENER_EOF'
#!/bin/bash
# Listen for Telegram messages and convert to prompts

export TZ='Asia/Bangkok'
PROJECT_DIR="/root/ghq/github.com/E0993599799/tham-oracle"
TELEGRAM_CONFIG="$PROJECT_DIR/.telegram-config"
TELEGRAM_LOG="$PROJECT_DIR/reports/telegram-activity.log"

source "$TELEGRAM_CONFIG"

LAST_UPDATE_ID=0

echo "🔉 Telegram Listener Started — $(date '+%d_%b_%y:%H:%M:%S')" >> "$TELEGRAM_LOG"

while true; do
  # Get updates from Telegram
  UPDATES=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=$((LAST_UPDATE_ID + 1))")

  # Parse messages
  echo "$UPDATES" | grep -o '"message_id":[0-9]*' | while read -r msg_id; do
    MSG_ID=$(echo "$msg_id" | cut -d: -f2)
    LAST_UPDATE_ID=$MSG_ID

    # Get message text
    TEXT=$(echo "$UPDATES" | grep -A 5 "\"message_id\":$MSG_ID" | grep -o '"text":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$TEXT" ]; then
      TIMESTAMP=$(date '+%d_%b_%y:%H:%M:%S')
      echo "📨 [$TIMESTAMP] Message from Telegram: $TEXT" >> "$TELEGRAM_LOG"

      # Log as prompt to channel
      echo "💬 Telegram→Channel: $TEXT" >> "$TELEGRAM_LOG"
    fi
  done

  sleep 2
done
LISTENER_EOF

chmod +x "$PROJECT_DIR/scripts/telegram-listener.sh"

echo "   ✅ Telegram listener created"
echo ""

# Create formatter
echo "4️⃣ Creating message formatter..."

cat > "$PROJECT_DIR/scripts/telegram-formatter.js" << 'FORMATTER_EOF'
// Telegram Message Formatter — Convert Oracle messages to human-readable format

function formatForTelegram(data) {
  if (typeof data === 'string') {
    return data; // Already formatted
  }

  if (data.status === 'COMPLETED' || data.status === '✅') {
    return `✅ ${data.title || 'Task'} — COMPLETE\n${data.message || ''}`;
  }

  if (data.status === 'IN_PROGRESS' || data.status === '🟡') {
    return `🟡 ${data.title || 'Task'} — IN PROGRESS\n${data.message || ''}`;
  }

  if (data.status === 'ERROR' || data.status === '❌') {
    return `❌ ${data.title || 'Error'}\n${data.error || data.message || ''}`;
  }

  if (data.status === 'ALERT' || data.status === '🔴') {
    return `🔴 ALERT: ${data.message || data.title || ''}\nAction: ${data.action || ''}`;
  }

  if (data.agent) {
    return `🔷 ${data.agent} — ${data.message || data.status || ''}\nTime: ${data.timestamp || ''}`;
  }

  if (data.progress) {
    return `📊 Progress: ${data.progress}%\n${data.message || ''}\nTime: ${data.eta || ''}`;
  }

  // Fallback to JSON compact format
  return JSON.stringify(data, null, 2);
}

function formatFromTelegram(message) {
  // Parse Telegram message and convert to prompt
  // Examples:
  // "temperature phase 1 status" → prompt
  // "deploy orry" → command
  // "check lanes" → query

  const cmd = message.toLowerCase().trim();

  if (cmd.includes('temperature') && cmd.includes('status')) {
    return '/recap temperature';
  }

  if (cmd.includes('deploy') && cmd.includes('orry')) {
    return 'Deploy ORRY ERP to Vercel';
  }

  if (cmd.includes('check') && cmd.includes('lanes')) {
    return 'Check all lane status and report';
  }

  if (cmd.includes('status')) {
    return '/recap';
  }

  // Passthrough as prompt
  return message;
}

module.exports = {
  formatForTelegram,
  formatFromTelegram
};
FORMATTER_EOF

echo "   ✅ Message formatter created"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Telegram Setup Complete"
echo ""
echo "📋 Configuration:"
echo "   Config file: $TELEGRAM_CONFIG"
echo "   Log file: $TELEGRAM_LOG"
echo "   Listener: $PROJECT_DIR/scripts/telegram-listener.sh"
echo "   Formatter: $PROJECT_DIR/scripts/telegram-formatter.js"
echo ""
echo "🚀 Usage:"
echo "   Send: Start listener with: bash scripts/telegram-listener.sh"
echo "   Message format: Compact, human-readable"
echo "   Bidirectional: Telegram ↔ Claude Channel"
echo ""
