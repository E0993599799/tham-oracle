#!/usr/bin/env bash
# Tham Oracle — Daily Summary (run at 09:00 via cron)
# Sends fleet + git + task summary to Telegram

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NOTIFY="${REPO_ROOT}/scripts/telegram/notify.sh"
CONFIG="$HOME/.config/tham/telegram.env"

source "$CONFIG" 2>/dev/null || { echo "No config"; exit 1; }

TG_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
NOW=$(date "+%H:%M %d %b %Y")
DASHBOARD="http://localhost:3000"

# Gather data
cd "$REPO_ROOT"
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
COMMITS_24H=$(git log --since="24 hours ago" --oneline 2>/dev/null | wc -l | tr -d ' ')
COMMITS_7D=$(git log --since="7 days ago" --oneline 2>/dev/null | wc -l | tr -d ' ')
LAST_COMMIT=$(git log -1 --pretty=format:"%h %s" 2>/dev/null || echo "—")

# PSI counts
PSI="${REPO_ROOT}/ψ"
INBOX_COUNT=$(ls "${PSI}/inbox/" 2>/dev/null | grep -v '^\.' | wc -l | tr -d ' ')
ACTIVE_COUNT=$(ls "${PSI}/active/" 2>/dev/null | grep -v '^\.' | wc -l | tr -d ' ')
OUTBOX_COUNT=$(ls "${PSI}/outbox/" 2>/dev/null | grep -v '^\.' | wc -l | tr -d ' ')

# Fleet health from API
FLEET_HEALTH=$(curl -s "${DASHBOARD}/api/fleet" 2>/dev/null | python3 -c "
import json,sys
try:
  d = json.load(sys.stdin)
  oracles = d.get('oracles',[])
  active = sum(1 for o in oracles if o.get('status') == 'active')
  total = len(oracles)
  pct = int(active/total*100) if total else 0
  print(f'{active}/{total} active ({pct}%)')
except: print('API unavailable')
" 2>/dev/null || echo "API unavailable")

# Service health
SVC_HEALTH=$(curl -s "${DASHBOARD}/api/health" 2>/dev/null | python3 -c "
import json,sys
try:
  d = json.load(sys.stdin)
  svcs = d.get('services',[])
  up = sum(1 for s in svcs if s.get('status') == 'up')
  total = len(svcs)
  print(f'{up}/{total} up')
except: print('unavailable')
" 2>/dev/null || echo "unavailable")

# Active tasks list
TASK_LIST=""
if [ -d "${PSI}/active" ]; then
  while IFS= read -r f; do
    TASK_LIST="${TASK_LIST}  • $(basename "$f" .md)\n"
  done < <(find "${PSI}/active" -name "*.md" ! -name ".*" 2>/dev/null | head -5)
fi

# Build message
MSG=$(cat <<EOF
🌅 <b>Good morning — Daily Summary</b>
${NOW}

🔮 <b>Fleet</b>: ${FLEET_HEALTH}
⚙️ <b>Services</b>: ${SVC_HEALTH}

📋 <b>Queue</b>
📥 Inbox: ${INBOX_COUNT}  ⚡ Active: ${ACTIVE_COUNT}  📤 Outbox: ${OUTBOX_COUNT}

⚡ <b>Git — ${BRANCH}</b>
Commits 24h: ${COMMITS_24H}  |  7d: ${COMMITS_7D}
Last: <code>${LAST_COMMIT}</code>
EOF
)

if [ -n "$TASK_LIST" ]; then
  MSG="${MSG}

📌 <b>Active tasks</b>:
$(echo -e "$TASK_LIST")"
fi

# Send
curl -s -X POST "$TG_URL" \
  -H "Content-Type: application/json" \
  -d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": $(echo "$MSG" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'), \"parse_mode\": \"HTML\"}" \
  > /dev/null

echo "[daily-summary] Sent at $NOW"
