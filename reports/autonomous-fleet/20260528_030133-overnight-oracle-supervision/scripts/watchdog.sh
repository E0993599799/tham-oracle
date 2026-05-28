#!/usr/bin/env bash
set +e
ROOT_DIR='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control'
CONTROL_DIR='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
PROGRESS='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/watchdog.md'
INBOX='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
LOG='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030133-overnight-oracle-supervision/logs/watchdog.log'
PROMPT='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030133-overnight-oracle-supervision/prompts/watchdog.md'
AGENT='watchdog'
mkdir -p "$(dirname "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/watchdog.md")" "$(dirname "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030133-overnight-oracle-supervision/logs/watchdog.log")"
printf '[%s] %s CURRENT: task received, starting now\n' "$(date -Iseconds)" "watchdog" | tee -a "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/watchdog.md" "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log"
(
  while true; do
    sleep 150
    last_line="$(tail -n 1 "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/watchdog.md" 2>/dev/null || true)"
    printf '[%s] %s HEARTBEAT: %s\n' "$(date -Iseconds)" "watchdog" "${last_line:-no progress yet}" >> "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log"
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
cd "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control" || exit 2
timeout 420 gemini --approval-mode auto_edit -m 'gemini-3.1-pro-preview' -p "Read the full task from stdin and execute it. Keep edits scoped and keep progress updates flowing every 3 minutes." < "$PROMPT" 2>&1 | tee -a "$LOG"
STATUS=${PIPESTATUS[0]}
if [ "$STATUS" != "0" ] || grep -qiE 'high demand|rate limit|quota|capacity|exhausted your capacity|try again later|failed|error' "$LOG"; then
  printf '[%s] %s CURRENT: Gemini unavailable or blocked, falling back to Codex\n' "$(date -Iseconds)" "$AGENT" | tee -a "$PROGRESS" "$INBOX"
  cat "$PROMPT" | codex exec -C "$ROOT_DIR" --sandbox workspace-write --ignore-rules - 2>&1 | tee -a "$LOG"
  STATUS=${PIPESTATUS[1]}
fi
printf '[%s] %s EXIT: %s
' "$(date -Iseconds)" "$AGENT" "$STATUS" | tee -a "$PROGRESS" "$INBOX"
exec bash
