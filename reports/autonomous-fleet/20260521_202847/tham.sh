cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
mkdir -p '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260521_202847/logs'
printf '[%s] %s: Task received, starting now\n' "$(date -Iseconds)" 'tham' | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham.md'
(
  while true; do
    sleep 120
    printf '[%s] %s heartbeat: still active; latest progress follows.\n' "$(date -Iseconds)" 'tham' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
    tail -n 20 '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham.md' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log' 2>/dev/null || true
    tmux send-keys -t 'tham-oracle-stack:tham' "[heartbeat:tham] $(date -Iseconds) latest status written to reports/progress/tham.md" C-m 2>/dev/null || true
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
set +e
claude --name tham-orchestrator --model 'sonnet' --permission-mode auto "$(cat '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260521_202847/prompts/tham.md')" 2>&1 | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260521_202847/logs/tham.log'
STATUS=\
echo "tham exit status: \STATUS" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham.md'
exec bash
