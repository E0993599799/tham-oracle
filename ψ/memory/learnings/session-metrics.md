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
