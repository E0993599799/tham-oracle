#!/usr/bin/env bash
set +e
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle' || exit 2
printf '[%s] dheva fallback: starting Codex fallback because primary lane was missing/stuck\n' "$(date -Iseconds)" | tee -a reports/progress/dheva.md
{
  printf 'FALLBACK CONTROL for agent dheva. Primary runtime stalled or lacked proof, so continue as Codex fallback to prevent stuck auto-run. Preserve the dheva role. Read this prompt file and complete only the proof/report in reports/progress/dheva.md. Use UTF-8 output. No commit, push, deploy, delete, git reset, git clean, or secret exposure. First verify pwd, git root, remote. Then complete the assigned task with exact files inspected, validation command/output, secret-scan statement, risk notes, rollback path, next action.\n\n'
  cat 'reports/autonomous-fleet/20260522_034427-seven-agent-auto/prompts/dheva.md'
} | codex exec -C . --sandbox workspace-write --ignore-rules - 2>&1 | tee -a 'reports/autonomous-fleet/20260522_034427-seven-agent-auto/logs/dheva-fallback.log'
STATUS=${PIPESTATUS[1]}
printf '[%s] dheva fallback exit status: %s\n' "$(date -Iseconds)" "$STATUS" | tee -a reports/progress/dheva.md
exec bash
