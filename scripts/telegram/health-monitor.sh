#!/usr/bin/env bash
# Tham Oracle — Health Monitor (run every 5 min via cron)
# Probes /api/health, sends Telegram alert on status change
# State file tracks last known status to avoid duplicate alerts

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NOTIFY="${REPO_ROOT}/scripts/telegram/notify.sh"
DASHBOARD="http://localhost:3000"
STATE_FILE="/tmp/tham-health-state.json"
LOG_FILE="/tmp/tham-health-monitor.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

# Read previous state
prev_state=""
if [ -f "$STATE_FILE" ]; then
  prev_state=$(cat "$STATE_FILE")
fi

# Probe health API
probe=$(curl -s --max-time 5 "${DASHBOARD}/api/health" 2>/dev/null || echo "")

if [ -z "$probe" ]; then
  # Dashboard itself is down
  curr_state="dashboard-down"
  if [ "$prev_state" != "$curr_state" ]; then
    log "Dashboard unreachable — alerting"
    bash "$NOTIFY" service-down "dashboard (port 3000)"
    echo "$curr_state" > "$STATE_FILE"
  fi
  exit 0
fi

# Parse down services
down_svcs=$(echo "$probe" | python3 -c "
import json,sys
try:
  d = json.load(sys.stdin)
  svcs = d.get('services',[])
  down = [s['name'] for s in svcs if s.get('status') != 'up']
  print(','.join(down))
except: print('')
" 2>/dev/null || echo "")

curr_state="${down_svcs:-ok}"

if [ "$curr_state" != "$prev_state" ]; then
  if [ "$curr_state" = "ok" ]; then
    if [ -n "$prev_state" ] && [ "$prev_state" != "ok" ] && [ "$prev_state" != "" ]; then
      log "All services recovered — alerting"
      bash "$NOTIFY" service-up "all services"
    fi
  else
    log "Services down: $curr_state — alerting"
    IFS=',' read -ra SVCS <<< "$curr_state"
    for svc in "${SVCS[@]}"; do
      bash "$NOTIFY" service-down "$svc"
    done
  fi
  echo "$curr_state" > "$STATE_FILE"
fi

log "Health: $curr_state"
