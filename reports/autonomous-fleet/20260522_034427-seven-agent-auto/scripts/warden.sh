#!/usr/bin/env bash
set +e
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle' || exit 2
mkdir -p '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/escalations'
printf '[%s] warden: Task received, starting now\n' "$(date -Iseconds)" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/warden.md'
(
  while true; do
    sleep 120
    printf '[%s] warden heartbeat: still active\n' "$(date -Iseconds)" >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
    tail -n 20 '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/warden.md' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log' 2>/dev/null || true
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
cat '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/prompts/warden.md' | codex exec -C . --sandbox workspace-write --ignore-rules - 2>&1 | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs/warden.log'
STATUS=${PIPESTATUS[1]}
printf '[%s] warden exit status: %s\n' "$(date -Iseconds)" "$STATUS" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/warden.md'
exec bash
