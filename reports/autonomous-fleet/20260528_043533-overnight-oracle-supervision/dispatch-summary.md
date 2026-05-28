# Overnight Oracle Supervision Dispatch

Timestamp: 20260528_043533
Session: tham-overnight
Control repo: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle
Workspace root: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control
Run dir: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/reports/autonomous-fleet/20260528_043533-overnight-oracle-supervision
Watchdog script: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle/scripts/overnight-oracle-watchdog.sh

Workers:
- core: ORRY deployment/status controller
- codex: temperature implementation lead
- luxi: ORRY UI/UX + code review loop
- watchdog: temperature review + watchdog lane

Rules:
- THAM/Hermes is orchestrator/controller only
- every worker must update progress at least every 3 minutes
- if silent, watchdog will ping the pane and log escalation
- no commit/push/deploy/delete/reset/clean/force ops
