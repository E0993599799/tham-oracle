# Omega Agent Self-Evolution System — Update Blueprint

> Phase 0/1 only • NOT RUN-PROVEN

## Executive summary
Build Omega as a proof-first self-improvement loop where every task becomes a trace, proof artifact, scorecard update, memory delta, and—when warranted—a skill or prompt patch candidate.

The best solution for MarcuzX Omega is a **hybrid memory stack**:
1. **Obsidian** for policy, retrospectives, and durable human-readable memory
2. **Supabase** for runtime state, logs, proofs, dashboards, scorecards, and automation runs
3. **Git repo** for versioned docs, schemas, and contracts
4. **Notion** only as a mirror for human collaboration, never as the source of truth
5. **Drive D:** as staging/backups/temp workspace only

## What was learned from the source audit
- `FORGE_OMEGA_SOT.md` already defines the core formula: Tham + Core + Executor Lane Router + Supabase + Obsidian + 9router/OpenClaw.
- `wiki/hot.md` and `wiki/index.md` show the vault is already used as a master catalog and recent cache.
- `THAM_SELF_EVOLVE_SKILL.md` already encodes the self-evolve loop: Observe → Diagnose → Reflect → Distill Rule → Gate/Test → Promote Skill → Use on Next Task → Audit Drift.
- The temperature project history in `DISPATCH-TEMPERATURE.md`, `TEMPERATURE-SUPABASE-DEPLOYMENT.md`, and `VERIFICATION-17MAY.md` shows the right pattern: schema-first, phase-separated, proof-first, monitored, and fallback-ready.

## Blueprint decision
Omega self-evolution should **not** be model training. It should be operational improvement through:
- trace collection
- proof validation
- failure harvesting
- scorecard computation
- skill candidate mining
- prompt patch proposals
- memory deltas
- dashboard visibility
- Obsidian writeback

## Phase 0 goal
Establish the canonical design and the data contracts.

### Phase 0 outputs
- architecture document
- folder structure
- JSON schemas
- first 5 automation contracts
- source audit

## Phase 1 goal
Define the log/proof contract that all automation must emit, but do not execute automation yet.

### Phase 1 outputs
- task trace schema
- proof artifact schema
- failure event schema
- automation run schema
- dashboard/status field definitions

## Non-goals for Phase 0/1
- no scheduler implementation
- no agent auto-promotion
- no self-writing runtime automation
- no destructive writeback
- no infinite loops
- no hidden assumptions

## Next phase gate
Phase 2 can begin only after:
- schemas are accepted
- folder structure is accepted
- contract language is stable
- proof fields are unambiguous
- rollback and disable paths are defined
