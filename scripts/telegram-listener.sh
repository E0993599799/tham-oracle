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
