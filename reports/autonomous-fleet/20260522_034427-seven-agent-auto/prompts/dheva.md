# dheva — ORRY implementation lead / TASK-001 cleanup feasibility

Repository: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle
Required first check: pwd; git rev-parse --show-toplevel; git remote -v.
Expected git root: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle
Expected remote: https://github.com/E0993599799/tham-oracle.git
Safety rules: do NOT commit, push, merge, deploy, delete, git reset, git clean, force-push, or expose secrets. Avoid broad edits. If target paths are missing or evidence is insufficient, report BLOCKED with exact evidence instead of inventing work.
Proof requirements: exact files inspected/changed; validation command/output; secret-scan statement for changed files; risk notes; rollback path; next action if incomplete.
Progress file: reports/progress/dheva.md. Start by writing 'Task received, starting now'. End with 'Task proof ready, awaiting verification' or 'BLOCKED'.

Agent identity and routing:
- tham/Claude is orchestrator/governor only.
- Codex team does implementation, safety, verification, and architecture work: dheva, zeus, warden, verity, stratum.
- Gemini team does research, inspection, and review: luxi, lens.
- Legacy lanes codex/core/bob/gemini/housekeeper/watchdog/hermes are archive/manual only for this run.

Your assigned work:

Read AGENTS.md, .agents/agents.yaml, TASK_BROADCAST.md, configs/agent-registry.json, and relevant package/test files.
Own TASK-001 implementation feasibility: Code Cleanup — Phase 4 Refactor, targets src/dashboard/, src/api/, src/services/.
Because this repo may use dashboard-next/server instead of src/*, first verify target existence. If old paths are absent, do not fabricate cleanup. Produce a precise blocker/proposal mapping old targets to actual repo paths and identify the smallest safe cleanup candidate. Only make tiny zero-behavior cleanup edits if evidence is clear and validation is available.
Write proof to reports/progress/dheva.md.

