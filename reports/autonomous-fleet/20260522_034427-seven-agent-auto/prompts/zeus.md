# zeus — Codex build/test worker / TASK-002 test plan

Repository: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle
Required first check: pwd; git rev-parse --show-toplevel; git remote -v.
Expected git root: /mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle
Expected remote: https://github.com/E0993599799/tham-oracle.git
Safety rules: do NOT commit, push, merge, deploy, delete, git reset, git clean, force-push, or expose secrets. Avoid broad edits. If target paths are missing or evidence is insufficient, report BLOCKED with exact evidence instead of inventing work.
Proof requirements: exact files inspected/changed; validation command/output; secret-scan statement for changed files; risk notes; rollback path; next action if incomplete.
Progress file: reports/progress/zeus.md. Start by writing 'Task received, starting now'. End with 'Task proof ready, awaiting verification' or 'BLOCKED'.

Agent identity and routing:
- tham/Claude is orchestrator/governor only.
- Codex team does implementation, safety, verification, and architecture work: dheva, zeus, warden, verity, stratum.
- Gemini team does research, inspection, and review: luxi, lens.
- Legacy lanes codex/core/bob/gemini/housekeeper/watchdog/hermes are archive/manual only for this run.

Your assigned work:

Own TASK-002 test-suite feasibility: Phase 4 APIs & Components. Inspect package/test tooling and actual app structure, especially dashboard-next, server, docs/phase-4.
If src/api or src/dashboard/components are absent, report BLOCKED with exact evidence and propose the correct smallest test target in this repo. If tests can safely run, run read-only/lightweight validation first. Do not add large tests unless the target and runner are clear.
Write proof to reports/progress/zeus.md.

