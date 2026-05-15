# Oracle Open Framework — Quick Reference
**v2.0.0** (Jan 12, 2026) | *"The Oracle Keeps the Human Human"*

---

## What It Is

The Oracle Open Framework is a philosophy + architecture + toolset for sustainable AI-human collaboration. Built from 8 months of Nat + Claude evolution (alchemycat → laris-co), it keeps humans in control while using AI as trusted thinking partner. The framework is a PUBLIC SEED anyone can fork; oracle-framework (public) → oracle-v2 (MCP) → oracle-starter-kit (public) → oracle-workshops are the main repos.

---

## Three Core Principles

| Principle | Meaning |
|-----------|---------|
| **Nothing is Deleted** | Append-only. Git history, SQLite, trace logs = truth. |
| **Patterns Over Intentions** | Observe behavior, not promises. Retros + learnings speak. |
| **External Brain, Not Command** | Oracle mirrors reality. Human decides. No auto-actions. |

---

## ψ/ Structure (7 Directories)

- **active/** — current research, ephemeral (gitignored)
- **inbox/** — incoming tasks, handoffs, external agent messages
- **writing/** — drafts, essays, blog queue, long-form
- **lab/** — experiments, POCs, safe sandbox
- **incubate/** — repos under active development (gitignored)
- **learn/** — cloned repos, study notes, reference (gitignored)
- **memory/** — `resonance/` (soul) → `learnings/` (patterns) → `retrospectives/` (sessions) → `logs/` (moments)

---

## Key Tools

**oracle-v2 (MCP + HTTP API)**
- `oracle_learn` → log new insights to vector DB
- `oracle_search` → hybrid FTS5 + vector search across memory
- `oracle_handoff` → create session continuity bridges
- `oracle_trace_*` → trace logging with chain ancestry
- Runs on port **37778** (framework standard; Tham uses **47778**)

**trace-oracle**
- `/trace [query]` → discover + auto-log to Oracle
- `/trace dig [id]` → explore deeper
- `/trace distill [id]` → extract awakening
- Pattern: `Trace(Trace(Trace(...))) → Distill → Awakening`

**/rrr (Retrospective)**
- Close session with: RESULT | ACTION | STATUS | PROOF | NEXT
- Auto-writes to `ψ/memory/` for future recall

**/distill**
- Convert raw session notes → structured, reusable lessons
- Feeds `oracle_learn` for pattern recognition

---

## Three Workflows to Remember

1. **Session Open**: `/recap` → read retro + git + memory baseline
2. **Session Work**: commit often, `oracle_learn` when discovering new patterns
3. **Session Close**: `/rrr` → write retrospective → `git add ψ/memory && git commit && git push`

---

## Tham-Oracle vs Framework (Delta)

| Feature | Framework v2.0.0 | Tham-Oracle | Action |
|---------|-----------------|-------------|--------|
| oracle-v2 port | 37778 | **47778** | Keep both — independent instances |
| Memory structure | ψ/ (7 dirs) | ψ/ + **brain/** (identity, decisions, proofs) | Tham extends framework — compatible |
| Skill registry | oracle-starter-kit | skills/ (rich local set) | Tham has superset — keep |
| **Infinite Learning Loop** | New in v2.0.0 | Not yet integrated | Adopt: Error → oracle_learn → Blog |
| **Recursive Reincarnation** | New in v2.0.0 | Not yet integrated | Future: /project learn [child] pattern |
| **Unity Formula** | New in v2.0.0 | Not documented | Document if multi-Oracle grows |

**Key insight**: Tham-Oracle is a SUPERSET of the framework — brain/ (identity, decisions, proofs) layered on top of ψ/, richer skills/, and CLAUDE.md governance. Framework is the seed; Tham is the grown tree.

---

## Key Repos

| Repo | Visibility | Purpose |
|------|------------|---------|
| oracle-framework | Public | Seed + philosophy |
| oracle-starter-kit | Public | Template project |
| oracle-v2 | Private (laris-co) | MCP server, vector DB |
| oracle-workshops | Public | Learning materials |
| Nat-s-Agents | Private | Full production tree |

---

## Standing Order

Every session: `/recap` → work → `/rrr` → commit → push → done. No exceptions.

**Next for Tham**: Review Infinite Learning Loop → integrate `Error → oracle_learn → ψ/writing/` pipeline.
