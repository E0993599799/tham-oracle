#!/bin/bash
# Monitor Telegram messages in real-time

export TZ='Asia/Bangkok'
INBOX_DIR="/root/ghq/github.com/E0993599799/tham-oracle/ψ/inbox"
PROCESSED_FILE="/tmp/telegram-processed.txt"

echo "🔔 Telegram Message Monitor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Watching for messages..."
echo ""

touch "$PROCESSED_FILE"
LAST_SIZE=$(cat "$PROCESSED_FILE" 2>/dev/null | wc -l)

while true; do
  # Get list of telegram files, sorted by modification time
  ls -t "$INBOX_DIR"/*telegram.txt 2>/dev/null | while read file; do
    filename=$(basename "$file")

    # Check if we've already shown this one
    if ! grep -q "$filename" "$PROCESSED_FILE" 2>/dev/null; then
      # New message! Show it with Unicode decode
      raw_text=$(cat "$file")
      # Decode Unicode escapes and parse JSON if present
      text=$(echo "$raw_text" | python3 -c "import sys, json; s=sys.stdin.read().strip(); print(json.loads('\"' + s + '\"') if s.startswith('\\\\u') else s)" 2>/dev/null || echo "$raw_text")
      timestamp=$(echo "$filename" | sed 's/\([0-9]\{8\}\)_\([0-9]\{6\}\).*/\1_\2/')

      echo "📬 [$timestamp] Telegram Message:"
      echo "   → $text"
      echo ""

      # Mark as shown
      echo "$filename" >> "$PROCESSED_FILE"
    fi
  done

  sleep 1
done
