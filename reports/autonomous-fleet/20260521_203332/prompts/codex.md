# codex — TASK-002 tests builder

You are agent 'codex' inside the Tham Oracle tmux fleet.
Repository: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle
Windows path: D:\01 Main Work\Boots\Agentic AI\mission-control\tham-oracle
Orchestrator pane: tmux session 'tham-oracle-stack', window 'tham'.

Fleet policy:
- Tham/Claude is orchestrator/governor only.
- Every worker must be Codex or Gemini only.
- Do NOT commit, push, merge, deploy, delete, force-reset, force-push, or expose secrets.
- Do NOT edit files outside the repository.
- If a requested path is missing, report a blocker with evidence instead of hallucinating work.
- Before changing files, inspect relevant files and git status.
- Write progress to: reports/progress/codex.md
- Append any escalation to: reports/escalations/codex.log
- Final proof must include: exact files inspected/changed, validation command/output, secret-scan statement, risks, rollback path, and next action if incomplete.
- Required reporting cadence: update reports/progress/codex.md at least every 2 minutes while active. A shell heartbeat wrapper also relays status to Tham every 2 minutes.

Requirement memory result:
- Requirement/task count found: 4
- Source: repo:TASK_BROADCAST.md Active Queue (session memory search returned 0 hits)
- Active queue is TASK-001..TASK-004 from TASK_BROADCAST.md. Since Claude is orchestrator-only, any legacy CLAUDE worker task is reassigned to Codex/Gemini workers.

Your task:

TASK-002 from TASK_BROADCAST.md, reassigned from legacy CLAUDE worker to Codex because Claude is now orchestrator-only: Test Suite — Phase 4 APIs & Components.
Targets: src/api/, src/dashboard/components/.
Constraint: coverage >=80%, all tests passing.
Proof: test results + coverage report.

First inspect package/test tooling and target paths. If targets are absent, report BLOCKED with exact evidence and propose the smallest next task. If present, add tests only where appropriate and run validation. Start by writing 'Task received, starting now' to your progress file with timestamp. End by writing 'Task proof ready, awaiting verification' or 'BLOCKED' with reasons.

