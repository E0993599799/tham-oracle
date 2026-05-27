# Oracle Session Metrics

Rule (parent CLAUDE.md §"Self-Evaluation Loop"): same friction 3 sessions → fix root cause, not another workaround.

| when | session | done | stuck | win | friction | error |
|---|---|---|---|---|---|---|
| 2026-05-16 14:25 | 6c37b413 | 5 oracle repos created+awakened+soul-synced, fleet 29→34, arra-oracle-v3 #1155-1159, Omega+tham-oracle pushed | n/a | fleet expansion 29→34 with full soul-sync for all 5 new oracles | case-sensitive ghqFind silent failure, fleet config iteration loops (project_repos dead code), --all pulling unwanted remote oracles | added project_repos field to fleet configs without reading scan implementation first — wasted 2-3 iteration rounds |
| 2026-05-17 11:09 | 60e2ae3d | telegram-fix, hermes-setup, github-connector-v1, active-index-update, windows-docs | oasync-repo-creation (user) | GitHub Connector (mailbox-v1 schema) — ChatGPT→inbox flow complete, 6 commits | assumption-lock-in (oasync design before verify), context-budget early-warning | designed oasync integration without checking repo exists (should verify before commit) |
| 2026-05-25 23:40 | 419f5e8b | trivial — /rrr only | n/a | trivial | oracle root detection mismatch (ψ not at git root in multi-oracle monorepo), ENCODED_PWD space-handling bug | assumed ψ at git root; should have used tham-oracle identity from memory first |

## 🔁 Recurring Pattern Detected

"acted on assumption without verifying current state first" appeared in **3 of last 3 sessions** (6c37b413, 60e2ae3d, 419f5e8b) in the **error** column. Per parent CLAUDE.md §"Self-Evaluation Loop" — consider root-cause fix instead of another workaround.

Pattern: Tham consistently makes structural assumptions (field exists, repo exists, directory layout) and acts on them before a single verification read. Each time the assumption was wrong and cost extra iteration rounds.

Suggested: raise in standup. Candidate fix — add a mandatory "verify before act" gate to Tham's intent-decode/risk-gate skills, or add a standing order: *"For any assumed path/resource, grep/stat it before advising action."*
| 2026-05-27 15:04 | f90718c7 | providers/status timeout fix, tmux Chat Terminal UI, fix-button REPO_ROOT quote fix, oracle-v2 dual-port, inbox cleared (8 missions) | MFLEET Phase 5 (awaiting human), tmux output diff (deferred) | providers 4/4 live + tmux terminal in dashboard | rebuild-while-running corrupted .next/ (30min lost), stale curl flood loops, token waste from 4 prod builds | rebuilt .next/ with server running — knew the rule, didn't apply it |

## 🔁 Recurring Pattern Detected (updated 2026-05-27)

"acted without verifying / applied known rule late" now appears in **4 of last 4 sessions** (6c37b413, 60e2ae3d, 419f5e8b, f90718c7) in the **error** column. Previous flag was 3/3 — pattern not resolved, now 4/4.

- 6c37b413: added field to config without reading scan implementation
- 60e2ae3d: designed integration without checking repo exists first
- 419f5e8b: assumed ψ at git root without verifying oracle layout
- f90718c7: rebuilt .next/ while server running — knew kill-first rule, didn't apply it

This is a structural agent habit, not an isolated mistake. Each instance has the same shape: Tham knew a prerequisite check was required, skipped it to "save time", paid the cost downstream.

**Root cause hypothesis**: The intent-decode / risk-gate chain does not have a mandatory "pre-condition check" step. Tham reasons about the task and jumps to execution without running a structured pre-flight.

**Suggested fix (for standup)**: Add to `skills/risk-gate/SKILL.md` a required checklist:
1. Does this action depend on an assumed state (server running? file exists? path valid)?
2. If yes → verify it with a read/stat/grep BEFORE advising or acting.
3. Only proceed after the assumption is confirmed or corrected.

Escalation: raise with พี่เอก — this is a systematic error costing 20-30min per session.
