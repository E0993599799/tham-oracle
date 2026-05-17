#!/bin/bash
# Monitor oasync/inbox/ for new ChatGPT messages
# Sends Telegram alert when message arrives
# Integrated with existing Telegram bot

export TZ='Asia/Bangkok'
OASYNC_INBOX="/tmp/oasync-inbox-check"
PROCESSED_FILE="/tmp/oasync-processed.txt"
REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
NOTIFY_SCRIPT="$REPO_ROOT/scripts/telegram/notify.sh"

echo "🔔 oasync Inbox Monitor (Telegram alerts)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Watching E0993599799/oasync/inbox/ → sends Telegram alert on new message"
echo ""

# Initialize processed tracker
touch "$PROCESSED_FILE"

while true; do
  # Check oasync inbox via GitHub API
  gh api repos/E0993599799/oasync/contents/inbox \
    --jq '.[] | select(.name | endswith(".json")) | .name' 2>/dev/null | while read filename; do

    if [ -z "$filename" ]; then
      continue
    fi

    # Check if we've already alerted about this
    if ! grep -q "$filename" "$PROCESSED_FILE" 2>/dev/null; then
      # New message! Extract metadata
      MSG_ID=$(echo "$filename" | sed 's/.json//')

      # Get message content via GitHub API
      MSG_CONTENT=$(gh api repos/E0993599799/oasync/contents/inbox/$filename \
        --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "?")

      # Parse JSON to get body
      BODY=$(echo "$MSG_CONTENT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('body', '?')[:100])
except:
    print('?')
" 2>/dev/null)

      # Send Telegram alert
      ALERT="📬 <b>ChatGPT Message (oasync)</b>
<code>$MSG_ID</code>

💬 $BODY…

(Processing...)"

      echo "Sending alert: $MSG_ID"
      bash "$NOTIFY_SCRIPT" custom "$ALERT" || echo "⚠️ Telegram send failed"

      # Mark as processed
      echo "$filename" >> "$PROCESSED_FILE"
    fi
  done

  sleep 30
done
