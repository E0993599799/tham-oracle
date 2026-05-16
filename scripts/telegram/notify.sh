#!/usr/bin/env bash
# Tham Oracle — Telegram Notification Sender
# Usage: notify.sh <type> [message]
# Types: service-down, fleet-summary, task-done, git-push, omega-tasks, custom
#
# Credentials read from ~/.config/tham/telegram.env (never committed)

set -euo pipefail

CONFIG="$HOME/.config/tham/telegram.env"

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: Config not found: $CONFIG"
  echo "Create it with: TELEGRAM_BOT_TOKEN=xxx and TELEGRAM_CHAT_ID=yyy"
  exit 1
fi

source "$CONFIG"

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "ERROR: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set in $CONFIG"
  exit 1
fi

TG_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DASHBOARD="http://localhost:3000"
NOW=$(date "+%H:%M %d %b")

send() {
  local text="$1"
  curl -s -X POST "$TG_URL" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": $(echo "$text" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'), \"parse_mode\": \"HTML\"}" \
    > /dev/null
}

TYPE="${1:-custom}"
MSG="${2:-}"

case "$TYPE" in
  service-down)
    SVC="${MSG:-unknown}"
    send "🔴 <b>SERVICE DOWN</b> — ${NOW}
Service: <code>${SVC}</code>
Action needed — run /fix ${SVC} to attempt restart
Dashboard: ${DASHBOARD}"
    ;;

  service-up)
    SVC="${MSG:-unknown}"
    send "🟢 <b>Service Restored</b> — ${NOW}
Service: <code>${SVC}</code> is back online"
    ;;

  fleet-summary)
    cd "$REPO_ROOT"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    COMMITS=$(git log --since="24 hours ago" --oneline 2>/dev/null | wc -l | tr -d ' ')
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    DIRTY_FLAG=""
    if [ "$DIRTY" -gt 0 ]; then
      DIRTY_FLAG="
⚠️ Uncommitted: ${DIRTY} files"
    fi
    send "📊 <b>Daily Fleet Summary</b> — ${NOW}
Branch: <code>${BRANCH}</code>
Commits (24h): ${COMMITS}${DIRTY_FLAG}
Dashboard: ${DASHBOARD}/api/fleet"
    ;;

  task-done)
    TASK="${MSG:-task}"
    send "✅ <b>Task Completed</b> — ${NOW}
<code>${TASK}</code>"
    ;;

  git-push)
    cd "$REPO_ROOT"
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    LAST=$(git log -1 --pretty=format:"%h %s" 2>/dev/null || echo "unknown")
    send "⚡ <b>Git Push</b> — ${NOW}
Branch: <code>${BRANCH}</code>
Last commit: <code>${LAST}</code>"
    ;;

  git-commit)
    cd "$REPO_ROOT"
    LAST=$(git log -1 --pretty=format:"%h %s" 2>/dev/null || echo "unknown")
    send "📝 <b>Git Commit</b> — ${NOW}
<code>${LAST}</code>"
    ;;

  omega-tasks)
    # List today's tasks from ψ/active/
    PSI="${REPO_ROOT}/ψ"
    ACTIVE_DIR="${PSI}/active"
    COUNT=0
    TASK_LIST=""
    if [ -d "$ACTIVE_DIR" ]; then
      while IFS= read -r f; do
        COUNT=$((COUNT + 1))
        TASK_LIST="${TASK_LIST}• $(basename "$f" .md)\n"
      done < <(find "$ACTIVE_DIR" -name "*.md" ! -name ".*" 2>/dev/null | head -10)
    fi
    if [ "$COUNT" -eq 0 ]; then
      send "📋 <b>Omega Tasks Today</b> — ${NOW}
No active tasks in ψ/active/"
    else
      send "📋 <b>Omega Tasks Today</b> — ${NOW}
${COUNT} active tasks:
$(echo -e "$TASK_LIST")"
    fi
    ;;

  health-check)
    # Quick health probe — used by health-monitor.sh
    STATUS=$(curl -s "${DASHBOARD}/api/health" 2>/dev/null | python3 -c "
import json,sys
try:
  d = json.load(sys.stdin)
  svcs = d.get('services',[])
  down = [s['name'] for s in svcs if s.get('status') != 'up']
  up = len(svcs) - len(down)
  print(f'{up}/{len(svcs)} up')
  if down: print('DOWN: ' + ', '.join(down))
except: print('parse error')
" 2>/dev/null || echo "dashboard unreachable")
    send "🔍 <b>Health Check</b> — ${NOW}
${STATUS}"
    ;;

  custom|*)
    if [ -z "$MSG" ]; then
      echo "Usage: notify.sh <type> [message]"
      echo "Types: service-down, service-up, fleet-summary, task-done, git-push, git-commit, omega-tasks, health-check, custom"
      exit 1
    fi
    send "🔮 <b>Tham Oracle</b> — ${NOW}
${MSG}"
    ;;
esac

echo "[notify] Sent: $TYPE"
