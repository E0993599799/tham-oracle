# Omega Agent Self-Evolution System — Architecture (Phase 0/1)

> Status: NOT RUN-PROVEN

## Purpose
Turn every useful Omega event into structured learning:
task → trace → proof → evaluation → reflection → candidate → test → promotion → monitoring.

## Scope
- 12-hour tactical cycle design
- daily strategic review design
- weekly leap review design
- failure harvesting and scorecards
- skill candidate and prompt patch proposals
- memory consolidation rules
- dashboard visibility contract
- Obsidian writeback contract

## Non-goals
- no code execution
- no agent self-promotion without proof
- no policy memory updates without review
- no raw natural-language execution by agents
- no hidden recursion or infinite loops

## Core loop
1. Collect task traces and proof artifacts.
2. Classify result quality.
3. Harvest failures and weak proofs.
4. Produce memory deltas and prompt patch candidates.
5. Compute scorecards and skill candidates.
6. Write a visible dashboard snapshot.
7. Write a human-readable Obsidian review.
8. Require proof before any promotion.

## Component map
- **Tham**: decode intent, choose scope, classify risk, approve promotions.
- **Core**: bridge, queue, gate, proof writer, safe controller.
- **Executor Lane Router**: lane selection and fallback routing.
- **Proof Reader**: verifies artifacts and status transitions.
- **Dashboard**: shows current health, scorecards, failures, and automation status.
- **Obsidian**: durable human memory, reviews, policy notes, and retrospectives.
- **Supabase**: structured runtime state and queryable history.
- **Notion**: optional mirror for summaries only.

## Data flow
Human input → Tham intent decode → memory gate → SOT gate → risk gate → task contract → Core → router → executor → proof reader → dashboard → writeback targets.

## Memory flow
- Episodic memory: traces, logs, actual runs.
- Semantic memory: stable facts, architecture truths, paths, definitions.
- Procedural memory: skills, runbooks, repair patterns.
- Policy memory: hard rules, SOT boundaries, release gates.

Promotion rule:
- episodic may be stored automatically
- semantic requires consistency checks
- procedural requires repeatable proof
- policy requires human approval or severe prevention value

## Evaluation flow
- Validate required fields.
- Verify proofs exist and match task.
- Detect false OK / weak DONE.
- Score latency, cost, usefulness, and safety.
- Emit either PASS, CHECK, FAIL, BLOCKED_BY_SOT_BOUNDARY.

## Skill promotion flow
1. Pattern observed.
2. Candidate created.
3. Proof collected.
4. Benchmark or repeated success confirmed.
5. Rollback exists.
6. Test exists.
7. Dashboard status visible.
8. Obsidian writeback completed.
9. Only then may the skill be promoted.

## Failure handling flow
- classify failure class
- create problem log
- contain the blast radius
- add prevention rule candidate
- add benchmark test candidate
- add prompt patch candidate if needed
- write back a concise human-readable summary

## Human feedback flow
Human feedback is not noise. It becomes:
- failure_event
- problem_log
- prevention_rule_candidate
- prompt_patch_candidate
- benchmark_test_candidate
- skill_update_candidate
- Obsidian note

## Dashboard flow
Dashboard cards must derive from data, not mock text.
Each card must expose:
- data source
- green/yellow/red logic
- click-through proof

## Obsidian writeback flow
Writeback should be append-only and human-readable.
Use Obsidian for:
- daily and weekly reviews
- policy notes
- memory deltas
- skill release notes
- red-team findings
- capability bets

## Safety and rollback model
- automation kill switch required
- per-cycle timeout required
- max retry count required
- rollback path required
- no self-promotion without proof
- no destructive action without explicit contract and backup
- no runtime loop without watchdog and stop condition
