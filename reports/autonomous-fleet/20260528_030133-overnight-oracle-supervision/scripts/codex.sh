#!/usr/bin/env bash
set +e
ROOT_DIR='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control'
CONTROL_DIR='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
PROGRESS='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/codex.md'
INBOX='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
LOG='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030133-overnight-oracle-supervision/logs/codex.log'
PROMPT='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030133-overnight-oracle-supervision/prompts/codex.md'
AGENT='codex'
mkdir -p "$(dirname "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/codex.md")" "$(dirname "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030133-overnight-oracle-supervision/logs/codex.log")"
printf '[%s] %s CURRENT: task received, starting now\n' "$(date -Iseconds)" "codex" | tee -a "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/codex.md" "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log"
(
  while true; do
    sleep 150
    last_line="$(tail -n 1 "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/codex.md" 2>/dev/null || true)"
    printf '[%s] %s HEARTBEAT: %s\n' "$(date -Iseconds)" "codex" "${last_line:-no progress yet}" >> "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log"
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
cd "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control" || exit 2
cat "$PROMPT" | codex exec -C "$ROOT_DIR" --sandbox workspace-write --ignore-rules - 2>&1 | tee -a "$LOG"
STATUS=${PIPESTATUS[1]}
printf '[%s] %s EXIT: %s
' "$(date -Iseconds)" "$AGENT" "$STATUS" | tee -a "$PROGRESS" "$INBOX"
exec bash
