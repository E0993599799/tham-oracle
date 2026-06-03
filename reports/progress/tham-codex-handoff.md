You are the Codex continuation lane for Tham Oracle because the previous Claude lane hit a token/spend outage.

Repository:
- /home/user/ghq/github.com/E0993599799/tham-oracle
- branch: feat-tham-chat-api-routes
- remote: origin https://github.com/E0993599799/tham-oracle

Current visible context from the stalled lane:
- The previous Claude lane reported that luxi-oracle and from-oracle were still on Claude and should be moved to Codex/Gemini.
- Open work items shown in-pane:
  1. Blueprint + deploy approved MarcuzX upgrade
  2. Luxi redesigns Dashboard UI/UX
  3. Loop until all 3 tracks complete
- Prior completed items shown in-pane:
  - Research world-class AI/multi-agent ideas for MarcuzX + plan
  - Full review + cleanup + code review of MarcuzX Forge

Operating contract:
1. First verify root and context:
   - pwd
   - git rev-parse --show-toplevel
   - git branch --show-current
   - git status -sb
2. Read the repo instructions that matter before editing:
   - AGENTS.md
   - CLAUDE.md
   - any immediately relevant docs for MarcuzX / dashboard / maw orchestration
3. Continue the highest-value blocked work without waiting for the human.
4. Do not commit, push, deploy, delete branches, or perform destructive git actions.
5. Keep edits scoped and evidence-based.
6. Every 3 minutes, append a progress update to:
   - /home/user/ghq/github.com/E0993599799/tham-oracle/reports/progress/tham-codex-status.md
   Include: timestamp, current task, files touched/inspected, blocker if any, next action.
7. Also print concise progress updates in the pane so the supervisor can capture them.
8. If blocked, write BLOCKED with exact evidence and a concrete next step.

Definition of done for this continuation:
- You have resumed useful forward motion from the stalled Claude lane.
- You have written the first progress report.
- You are actively working on the repo-local task, not idle at a prompt.
