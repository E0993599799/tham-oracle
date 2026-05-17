#!/bin/bash
# Listen for Telegram messages and convert to prompts

export TZ='Asia/Bangkok'
PROJECT_DIR="/root/ghq/github.com/E0993599799/tham-oracle"
TELEGRAM_CONFIG="$PROJECT_DIR/.telegram-config"
TELEGRAM_LOG="$PROJECT_DIR/reports/telegram-activity.log"
INBOX_DIR="$PROJECT_DIR/ψ/inbox"

source "$TELEGRAM_CONFIG"

mkdir -p "$INBOX_DIR"
LAST_UPDATE_ID=0

echo "🔉 Telegram Listener Started — $(date '+%d_%b_%y:%H:%M:%S')" >> "$TELEGRAM_LOG"

while true; do
  UPDATES=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=$((LAST_UPDATE_ID + 1))")

  # Parse JSON using Python for proper Unicode handling (via stdin)
  echo "$UPDATES" | python3 << 'PYTHON_EOF'
import json
import sys
from datetime import datetime

try:
    data = json.load(sys.stdin)
except:
    sys.exit(0)

for update in data.get('result', []):
    if 'message' not in update:
        continue

    msg = update['message']
    update_id = update['update_id']
    text = msg.get('text', '')

    if not text:
        continue

    TIMESTAMP = datetime.now().strftime('%d_%b_%y:%H:%M:%S')

    print(f"📨 [{TIMESTAMP}] Message from Telegram: {text}", flush=True)

    # Command mapping
    text_lower = text.lower()
    prompt = text

    if 'temperature' in text_lower and 'status' in text_lower:
        prompt = '/recap temperature'
    elif 'deploy' in text_lower and 'orry' in text_lower:
        prompt = 'Deploy ORRY ERP to Vercel'
    elif 'check' in text_lower and 'lane' in text_lower:
        prompt = 'Check all lane status and report'
    elif 'status' in text_lower and 'temperature' not in text_lower:
        prompt = '/recap'

    print(f"💬 Telegram→Channel: {prompt}", flush=True)
    print(f"🔔 TELEGRAM: {prompt}", flush=True)

    # Write to log and inbox
    with open('/root/ghq/github.com/E0993599799/tham-oracle/reports/telegram-activity.log', 'a') as f:
        f.write(f"📨 [{TIMESTAMP}] Message from Telegram: {text}\n")
        f.write(f"💬 Telegram→Channel: {prompt}\n")

    inbox_file = f"/root/ghq/github.com/E0993599799/tham-oracle/ψ/inbox/{datetime.now().strftime('%Y%m%d_%H%M%S')}_telegram.txt"
    with open(inbox_file, 'w') as f:
        f.write(prompt)

    print(f"📥 Dropped to inbox: {inbox_file.split('/')[-1]}", flush=True)

PYTHON_EOF

  sleep 2
done
