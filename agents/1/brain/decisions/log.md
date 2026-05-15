# Decisions Log

---

## 2026-05-12 — Use Supabase over SQLite for Forge/Omega runtime persistence
**Decision**: Prefer Supabase as runtime persistence source of truth. Do not default to better-sqlite3 or native SQLite.
**Why**: SQLite caused native module/runtime issues and is harder to inspect remotely.
**Applies to**: All Forge/Omega runners and Core persistence decisions.
**Revisit when**: Supabase is unavailable or explicitly replaced.

---

## 2026-05-12 — Hermes is optional/specialist only, not default executor
**Decision**: Hermes is routed only when explicitly requested. Core/Executor Lane Router is the default path.
**Why**: Hermes had shim recursion issues and missing real binary problems in legacy setups.
**Applies to**: All Forge/Omega task routing decisions.
**Revisit when**: Hermes is rebuilt with verified binary and proof.

---

## 2026-05-12 — Skills stored as SKILL.md per directory under skills/
**Decision**: Each skill lives in `skills/<slug>/SKILL.md` with a flat structure.
**Why**: Simple to navigate, easy to grep, compatible with Claude Code context loading.
**Applies to**: All skill creation and updates.
**Revisit when**: Skill count exceeds 200 and discovery becomes slow.

---

## 2026-05-12 — Brain structure lives in brain/ at repo root
**Decision**: 7 brain areas: identity, memory, projects, skills, decisions, proofs, reflections.
**Why**: Separates durable knowledge by type; memory and proofs can grow without polluting identity.
**Applies to**: All knowledge storage in tham-oracle repo.
**Revisit when**: Step 05+ introduces a different structure.

---

## 2026-05-13 — ψ vault is primary session memory; brain/ is durable knowledge

**Decision**: ψ/ vault = session memory (learnings, retrospectives, active, archive, lab, writing, learn). brain/ = durable structured knowledge (identity, decisions, proofs, reflections).
**Why**: ψ/ grows fast and is ephemeral-ish; brain/ should stay clean and stable. Separation makes grep faster.
**Applies to**: All writes — ask "is this durable knowledge or session artifact?" before choosing path.
**Revisit when**: oracle-v2 MCP replaces flat-file memory fully.

---

## 2026-05-13 — Forge/Omega integration: configs/ as structured registry

**Decision**: All Forge/Omega configs (agent-registry, lane-cards, forge-omega-config) live in `configs/` at repo root.
**Why**: Separates runtime config from docs and brain knowledge. Easy to read programmatically.
**Applies to**: Agent registry, lane card definitions, fleet configs.
**Revisit when**: Config needs secret values — then split into public config + encrypted secrets store.
