#!/bin/bash
# One-command health check for Tham Oracle router + tmux fleet
# Usage: bash scripts/tham-oracle-health-check.sh [session]

set -euo pipefail

SESSION="${1:-tham-oracle-stack}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${WINDOWS_HOST_IP}:20128}"

router_status="DOWN"
router_models="0"
router_first="-"
if timeout 3 curl -fsS "${ROUTER_BASE_URL}/v1/models" >/tmp/tham-router-health.json 2>/dev/null; then
  router_status="UP"
  router_models=$(python3 - <<'PY'
import json, sys
try:
    data = json.load(open('/tmp/tham-router-health.json'))
    print(len(data.get('data', [])))
except Exception:
    print('0')
PY
)
  router_first=$(python3 - <<'PY'
import json, sys
try:
    data = json.load(open('/tmp/tham-router-health.json'))
    print(data.get('data', [{}])[0].get('id', '-'))
except Exception:
    print('-')
PY
)
fi
rm -f /tmp/tham-router-health.json 2>/dev/null || true

team_status="MISSING"
window_count="0"
pane_count="0"
if tmux has-session -t "$SESSION" 2>/dev/null; then
  team_status="UP"
  window_count=$(tmux list-windows -t "$SESSION" -F '#{window_index}' 2>/dev/null | wc -l | tr -d ' ')
  pane_count=$(tmux list-panes -t "$SESSION" -F '#{pane_id}' 2>/dev/null | wc -l | tr -d ' ')
fi

printf 'THAM ORACLE HEALTH CHECK\n'
printf 'Router: %s\n' "$router_status"
printf 'Router URL: %s\n' "$ROUTER_BASE_URL"
printf 'Models: %s\n' "$router_models"
printf 'First model: %s\n' "$router_first"
printf 'Tmux session: %s\n' "$SESSION"
printf 'Team status: %s\n' "$team_status"
printf 'Windows: %s\n' "$window_count"
printf 'Panes: %s\n' "$pane_count"

if [ "$router_status" = "UP" ] && [ "$team_status" = "UP" ]; then
  echo 'OVERALL: OK'
  exit 0
fi

echo 'OVERALL: NOT READY'
exit 1
