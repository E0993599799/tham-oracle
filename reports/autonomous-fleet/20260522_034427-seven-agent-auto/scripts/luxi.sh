#!/usr/bin/env bash
set +e
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle' || exit 2
mkdir -p '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/escalations'
printf '[%s] luxi: Task received, starting now\n' "$(date -Iseconds)" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md'
(
  while true; do
    sleep 120
    printf '[%s] luxi heartbeat: still active\n' "$(date -Iseconds)" >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
    tail -n 20 '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log' 2>/dev/null || true
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
# Prefer Gemini Pro briefly; if quota/high-demand stalls/fails, retry same Gemini runtime on Flash preview.
timeout 45 gemini --approval-mode auto_edit -m 'gemini-3.1-pro-preview' -p "Read the full task from stdin and execute it. Keep edits scoped to the repository and proof file." < '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/prompts/luxi.md' 2>&1 | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs/luxi.log'
STATUS=${PIPESTATUS[0]}
if [ "$STATUS" = "124" ] || grep -qiE 'high demand|rate limit|quota|capacity|try again|experiencing high demand|exhausted your capacity' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs/luxi.log'; then
  printf '[%s] luxi: Gemini Pro unavailable/high-demand; retrying Gemini Flash fallback\n' "$(date -Iseconds)" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md'
  timeout 240 gemini --approval-mode auto_edit -m 'gemini-3-flash-preview' -p "Read the full task from stdin and execute it. Keep edits scoped to the repository and proof file." < '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/prompts/luxi.md' 2>&1 | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs/luxi.log'
  STATUS=${PIPESTATUS[0]}
fi
printf '[%s] luxi exit status: %s\n' "$(date -Iseconds)" "$STATUS" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/luxi.md'
exec bash
