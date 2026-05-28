# Omega Self-Evolution — Phase 2 Runtime Schema Plan

Status: design only
Scope: translate the approved Phase 0/1 contracts into a concrete Supabase/Postgres runtime ledger

## Goal
Implement the minimum structured runtime layer so Omega can record execution truth, proof truth, failure truth, and promotion candidates without mixing those concerns into Obsidian.

## Design principles
1. Supabase is the runtime source of truth.
2. Obsidian remains the human-readable memory source of truth.
3. Git remains the source of truth for contracts, code, and schema evolution.
4. Every runtime table must support proof-first verification.
5. Promotion into durable memory must happen through reviewed writeback, never direct raw log dumping.

## Core entities

### 1. task_traces
One row per task or automation run.
Purpose:
- lifecycle status
- timing/cost/token accounting
- lane/agent/provider routing proof
- links to proofs and failures

Maps to:
- `schemas/omega-self-evolution/task_trace.schema.json`

### 2. proof_artifacts
One row per artifact that can verify a claim.
Purpose:
- URI/hash/verifier tracking
- artifact validity state
- independent proof references

Maps to:
- `schemas/omega-self-evolution/proof_artifact.schema.json`

### 3. failure_events
One row per structured failure.
Purpose:
- class/severity tracking
- containment and root-cause candidate
- prevention-rule candidate generation

Maps to:
- `schemas/omega-self-evolution/failure_event.schema.json`

### 4. agent_scorecards
Periodic summary rows for agents/lane behavior.
Purpose:
- usefulness/stability/cost/latency tracking
- keep / narrow / quarantine / retire decisions

### 5. automation_runs
One row per scheduled automation invocation.
Purpose:
- scheduler visibility
- kill-switch auditability
- timeout/retry/disable-path evidence

### 6. memory_candidates
Candidate distilled lessons before writeback approval.
Purpose:
- hold extracted semantic/procedural/policy memory deltas
- review state before Obsidian promotion

### 7. skill_candidates
Candidate reusable workflows before promotion.
Purpose:
- connect repeated trace evidence to future skill creation/update

### 8. prompt_patch_candidates
Candidate prompt/routing changes before rollout.
Purpose:
- isolate prompt mutations from production behavior
- require review and rollback metadata

### 9. memory_embeddings
Semantic retrieval layer for approved runtime facts/candidates.
Purpose:
- vector search over approved or reviewable memory objects
- keep semantic recall queryable without making logs themselves canonical policy

## Recommended relational links
- `proof_artifacts.trace_id` -> `task_traces.trace_id`
- `failure_events.related_trace_id` -> `task_traces.trace_id`
- `task_traces.failure_event_ids` should be derived/query-linked, not trusted as sole source
- `memory_candidates.source_trace_id` -> `task_traces.trace_id`
- `skill_candidates.source_trace_ids[]` -> one-to-many evidence relationship
- `prompt_patch_candidates.source_failure_ids[]` -> failure evidence relationship

## Recommended enums

### task status
- queued
- running
- passed
- failed
- blocked
- cancelled

### proof status
- valid
- weak
- missing
- rejected
- superseded

### review state
- proposed
- in_review
- approved
- rejected
- superseded
- applied

### candidate type
- semantic_memory
- procedural_memory
- policy_memory
- skill_candidate
- prompt_patch

## Proposed operational views
1. `vw_recent_failures`
2. `vw_weak_proofs`
3. `vw_daily_agent_scoreboard`
4. `vw_pending_memory_candidates`
5. `vw_pending_prompt_patches`
6. `vw_automation_health`

## Required indexes
- task_traces: started_at, status, automation_name, lane, agent_name
- proof_artifacts: trace_id, status, created_at
- failure_events: timestamp, class, severity, component, status
- agent_scorecards: review_date, agent_name, lane
- automation_runs: automation_name, started_at, status
- memory_candidates: review_state, candidate_type, created_at
- skill_candidates: review_state, created_at
- prompt_patch_candidates: review_state, created_at
- memory_embeddings: embedding vector index + source_type/source_id btree

## Promotion boundary
Raw runtime rows do not go directly to Obsidian.
Flow must be:
- traces/proofs/failures in Supabase
- candidate distilled
- reviewed/approved
- append-only writeback to Obsidian

## Phase 2 deliverables
1. SQL migration draft
2. typed DB contract notes
3. dashboard card mapping
4. writeback approval flow
5. kill-switch + retry policy mapping

## Out of scope for this phase
- cron implementation
- workers
- auto-promotion
- live writeback automation
- production retries
