cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
mkdir -p '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress' '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260521_202847/logs'
printf '[%s] %s: Task received, starting now\n' "$(date -Iseconds)" 'gemini' | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/gemini.md'
(
  while true; do
    sleep 120
    printf '[%s] %s heartbeat: still active; latest progress follows.\n' "$(date -Iseconds)" 'gemini' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log'
    tail -n 20 '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/gemini.md' >> '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/tham-inbox.log' 2>/dev/null || true
    tmux send-keys -t 'tham-oracle-stack:tham' "[heartbeat:gemini] $(date -Iseconds) latest status written to reports/progress/gemini.md" C-m 2>/dev/null || true
  done
) & HEARTBEAT_PID=$!
trap 'kill $HEARTBEAT_PID 2>/dev/null || true' EXIT
set +e
OPENAI_BASE_URL='http://127.0.0.1:20128/v1' cmd.exe /c cd /d 'D:\01 Main Work\Boots\Agentic AI\mission-control\tham-oracle' '&&' gemini -m gemini/gemini-3.1-pro-preview --approval-mode auto_edit -p 'Read the full task instructions from stdin and execute them.' < '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260521_202847/prompts/gemini.md' 2>&1 | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260521_202847/logs/gemini.log'
STATUS=\
echo "agent exit status: \STATUS" | tee -a '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/progress/gemini.md'
exec bash
