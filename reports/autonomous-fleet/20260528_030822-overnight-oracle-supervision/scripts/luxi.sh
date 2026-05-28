#!/usr/bin/env bash
set +e
ROOT_DIR='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control'
CONTROL_DIR='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
PROGRESS='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md'
INBOX='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
LOG='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030822-overnight-oracle-supervision/logs/luxi.log'
PROMPT='/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030822-overnight-oracle-supervision/prompts/luxi.md'
AGENT='luxi'
RUNTIME='gemini'
mkdir -p "$(dirname "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md")" "$(dirname "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_030822-overnight-oracle-supervision/logs/luxi.log")"
printf '[%s] %s CURRENT: task received, starting now\n' "$(date -Iseconds)" "luxi" | tee -a "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md" "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log"
(
  while true; do
    sleep 150
    last_line="$(tail -n 1 "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md" 2>/dev/null || true)"
    printf '[%s] %s HEARTBEAT: %s\n' "$(date -Iseconds)" "luxi" "${last_line:-no progress yet}" >> "/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log"
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
cd "$ROOT_DIR" || exit 2
QUERY="$(cat "$PROMPT")"
TOOLSETS='terminal,file,web,session_search,skills'
SKILLS=''
case "$AGENT" in
  core) SKILLS='vercel-production-deployment,debug-mantra' ;;
  codex) SKILLS='cross-platform-node-production-validation,debug-mantra' ;;
  luxi) SKILLS='scrutinize,debug-mantra' ;;
  watchdog) SKILLS='scrutinize,debug-mantra' ;;
esac
if [ -n "$SKILLS" ]; then
  hermes chat -Q -t "$TOOLSETS" -s "$SKILLS" -q "$QUERY" 2>&1 | tee -a "$LOG"
else
  hermes chat -Q -t "$TOOLSETS" -q "$QUERY" 2>&1 | tee -a "$LOG"
fi
STATUS=${PIPESTATUS[0]}
printf '[%s] %s EXIT: %s\n' "$(date -Iseconds)" "$AGENT" "$STATUS" | tee -a "$PROGRESS" "$INBOX"
exec bash
