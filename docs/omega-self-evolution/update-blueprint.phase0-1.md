# Omega Agent Self-Evolution System — Update Blueprint

> Phase 0/1 only
> Scope: architecture + memory strategy + proof contracts
> Status: grounded in Obsidian/repo/Notion evidence, but runtime automation is still not run-proven

## 1) Executive decision

The best solution for MarcuzX Omega is not “one more agent” and not “one giant memory store”.
It is a layered operating system with strict separation of concerns:

1. Obsidian = canonical human-readable memory and policy layer
2. Supabase = canonical runtime ledger for traces, proofs, scorecards, failures, and automation runs
3. Git repo = canonical contract/schema/code layer
4. Notion = mirror / inbox / stakeholder-facing summary layer only
5. Terminal dashboard/tmux = live execution visibility and control layer

This matches the strongest repeated pattern across the sources:
- Tham owns reasoning, routing, memory selection, and proof judgment
- Core owns bridge/gate/proof execution discipline
- runtime truth must be structured
- memory truth must stay readable by humans
- “DONE” is invalid without proof

## 2) What the source audit actually says

### Obsidian says
Primary source: `/mnt/d/obsidian/FORGE_OMEGA_SOT.md`

Locked formula already exists:
- Tham (Brain)
- Core (Bridge/Gate/Proof)
- Executor Lane Router
- Supabase (runtime DB)
- Obsidian (human-readable memory)
- 9router/OpenClaw (model gateway)

Other Obsidian files reinforce the same architecture:
- `MarcuzX Omega OS - Memory Gate Evidence Model.md` → no memory read means no execution
- `MarcuzX Forge Omega - Agent Lane Architecture.md` → lane separation + permission model + memory writeback requires proof
- `Tham.md` → Tham is orchestrator only, Hermes is optional/specialist
- `THAM_SELF_EVOLVE_SKILL.md` → self-evolution is operational learning, not model training

### Repo says
Primary repo signals:
- `brain/decisions/log.md` → Supabase over SQLite for runtime persistence
- `brain/memory/2026-05-24-omega-tech-landscape.md` → best ROI = Supabase pgvector + MCP server-memory
- `docs/second-brain/decision.md` → hybrid index + HTML is the right low-token second-brain UI
- `ψ/memory/retrospectives/2026-05/27/15.04_dashboard-tmux-terminal-fleet-wiring.md` → current terminal UX friction is full-pane capture noise; delta output is the right next fix

### Notion says
Notion search returned Forge/Omega pages and inbox/task items, but the accessible results behave like mirror/inbox material, not the deepest canonical architecture store.
That supports a clear rule:
- Notion is useful for sharing, intake, and summaries
- Notion should not be the sole source of operational truth

### Supabase says
Across Obsidian + repo decisions, Supabase is consistently treated as:
- runtime source of truth
- structured event/proof store
- better fit than SQLite for inspection, automation, and remote-safe visibility

Best use of Supabase in Omega:
- task traces
- proof artifacts
- failure events
- scorecards
- automation runs
- semantic memory via pgvector

## 3) Final blueprint decision

Omega self-evolution should be built as a proof-first learning loop:

Human request
→ Tham intent decode
→ memory gate
→ SOT gate
→ risk gate
→ task contract
→ lane routing
→ execution
→ proof validation
→ structured runtime write
→ durable memory writeback
→ reflection/promote-or-reject

Important boundary:
Omega self-evolution is NOT:
- autonomous rule writing without review
- invisible prompt mutation
- endless looping
- model-weight training
- replacing source-of-truth docs with logs

Omega self-evolution IS:
- trace capture
- proof checking
- failure harvesting
- pattern detection
- candidate rule generation
- gated promotion into skill/policy/memory
- dashboard visibility
- bounded continuous improvement

## 4) Canonical role of each system

| Layer | Canonical use | Must not become |
|---|---|---|
| Obsidian | SOT, policy, retros, architecture, memory writeback | high-volume runtime log sink |
| Supabase | runtime ledger, event store, proofs, scorecards, vectors | vague narrative notebook |
| Git repo | contracts, schemas, code, docs, dashboards | ad-hoc human memory dump |
| Notion | mirror, inbox, summaries, collaboration | canonical architecture truth |
| tmux/dashboard | live control + visibility | memory system |

## 5) Concrete memory model for Omega

### A. Durable memory
Store in Obsidian:
- architecture decisions
- operating rules
- retrospectives
- approved lessons
- human-readable summaries
- promotion decisions

### B. Structured runtime memory
Store in Supabase:
- task_trace
- proof_artifact
- failure_event
- agent_scorecard
- automation_run
- memory_candidate
- prompt_patch_candidate
- skill_candidate
- vectorized memory chunks / embeddings

### C. Versioned implementation memory
Store in Git:
- JSON schemas
- automation contracts
- dashboard logic
- prompts
- tools
- migration files

### D. Mirror memory
Store in Notion only when useful for humans:
- weekly summaries
- project overview
- inbox capture
- stakeholder digest

## 6) Best solution for Omega Phase 0/1

Phase 0/1 should lock six things before any deeper automation:

1. Source hierarchy
   - Obsidian = memory truth
   - Supabase = runtime truth
   - Git = implementation truth

2. Promotion pipeline
   - raw event
   - clustered issue/pattern
   - candidate rule/skill/prompt patch
   - proof + review
   - approved writeback

3. Runtime schemas
   - every loop emits structured records
   - no free-text-only success reporting

4. Bounded automations
   - each automation has timeout, disable path, kill switch, and proof contract

5. Dashboard observability
   - terminal control for operators
   - status cards for proofs/failures/health
   - no opaque background behavior

6. UX discipline
   - operators should see delta/new output, not drown in raw pane history
   - second brain should stay low-token and drillable

## 7) Phase 0/1 deliverables that should be treated as approved direction

Already aligned with the sources and should remain the core plan:
- `docs/omega-self-evolution/source-audit.md`
- `docs/omega-self-evolution/architecture.phase0-1.md`
- `docs/omega-self-evolution/automation-contracts.phase0-1.md`
- `schemas/omega-self-evolution/*.schema.json`

## 8) Recommended additions to the blueprint

Add these explicit rules to avoid drift:

### Rule 1 — No proof, no promotion
A memory delta, rule, skill, or prompt patch cannot be promoted from one run alone unless it has:
- concrete evidence
- repeatability or clear severity
- bounded scope
- rollback path

### Rule 2 — Runtime facts and human memory must stay separate
Do not write noisy runtime traces into Obsidian.
Write distilled conclusions to Obsidian; keep raw traces in Supabase.

### Rule 3 — Notion is optional, not authoritative
If Notion and Obsidian disagree, Obsidian wins.
If Notion and repo contracts disagree, repo contracts win for implementation.

### Rule 4 — Terminal control is an execution surface, not a memory surface
The terminal dashboard should optimize operator speed and proof visibility, not become the place where durable memory lives.

### Rule 5 — Self-evolution is a gated compiler, not a free-form diary
Raw events become candidates.
Candidates become approved rules only after validation.

## 9) Suggested Supabase logical tables

Minimum recommended tables for Omega self-evolution:
- `task_traces`
- `proof_artifacts`
- `failure_events`
- `agent_scorecards`
- `automation_runs`
- `memory_candidates`
- `skill_candidates`
- `prompt_patch_candidates`
- `memory_embeddings`

If you want entity/relation memory too:
- use MCP `server-memory` for lightweight graph memory
- sync approved entities/relations into Supabase only where analytics/search needs them

## 10) UX direction for terminal control

Current repo evidence shows the biggest friction is noisy output.
So the right UX direction is:
- show new delta after a command, not the entire last 100 lines by default
- keep full capture available as secondary detail
- let operator filter by tmux session quickly
- keep live capture visible and lightweight
- preserve tmux as the live surface, dashboard as the smoother control layer

## 11) Phase 2 gate

Do not move to runtime self-evolution until these are true:
- schemas accepted
- source hierarchy accepted
- promotion rules accepted
- kill switch + disable path specified
- dashboard cards mapped to proof fields
- writeback rules explicit for Obsidian vs Supabase vs Notion
- no unresolved ambiguity about what counts as success

## 12) Bottom line

The best Omega solution is:
- Tham as sole memory-owning governor
- Core as contract/proof bridge
- Obsidian for durable human memory
- Supabase for structured runtime state and semantic memory
- Git for contracts and code
- Notion as optional mirror
- dashboard/tmux as observable execution control

This is the strongest design because it matches the existing MarcuzX/Omega thinking already present in the vault, avoids memory-role confusion, preserves proof discipline, and can evolve safely without turning the system into an unbounded black box.
