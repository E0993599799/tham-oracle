#!/bin/bash
# Poll GitHub inbox for new messages from ChatGPT
# Same pattern as telegram-monitor.sh

export TZ='Asia/Bangkok'
INBOX_DIR="/root/ghq/github.com/E0993599799/tham-oracle/ψ/inbox/github"
PROCESSED_FILE="/tmp/github-processed.txt"

echo "🔔 GitHub Inbox Monitor"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Watching GitHub inbox for messages..."
echo ""

# Create inbox directory if not exists
mkdir -p "$INBOX_DIR"

# Initialize processed tracker
touch "$PROCESSED_FILE"

while true; do
  # Get list of github message files, sorted by modification time
  ls -t "$INBOX_DIR"/*_github.txt 2>/dev/null | while read file; do
    filename=$(basename "$file")

    # Check if we've already shown this one
    if ! grep -q "$filename" "$PROCESSED_FILE" 2>/dev/null; then
      # New message! Show it
      text=$(cat "$file")

      # Extract timestamp from filename: YYYYMMDD_HHMMSS
      timestamp=$(echo "$filename" | sed 's/\([0-9]\{8\}\)_\([0-9]\{6\}\).*/\1_\2/')

      echo "📬 [$timestamp] GitHub Message:"
      echo "   → $text"
      echo ""

      # Mark as shown
      echo "$filename" >> "$PROCESSED_FILE"
    fi
  done

  sleep 30
done
