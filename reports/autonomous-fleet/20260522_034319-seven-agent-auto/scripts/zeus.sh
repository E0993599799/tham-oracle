#!/usr/bin/env bash
set +e
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle' || exit 2
mkdir -p '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034319-seven-agent-auto/logs' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/escalations'
printf '[%s] zeus: Task received, starting now\n' "$(date -Iseconds)" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/zeus.md'
(
  while true; do
    sleep 120
    printf '[%s] zeus heartbeat: still active\n' "$(date -Iseconds)" >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
    tail -n 20 '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/zeus.md' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log' 2>/dev/null || true
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
cat '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034319-seven-agent-auto/prompts/zeus.md' | codex exec -C '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle' --sandbox workspace-write --ignore-rules - 2>&1 | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034319-seven-agent-auto/logs/zeus.log'
STATUS=${PIPESTATUS[1]}
printf '[%s] zeus exit status: %s\n' "$(date -Iseconds)" "$STATUS" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/zeus.md'
exec bash
