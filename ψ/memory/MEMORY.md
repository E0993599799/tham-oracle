# ธาม-Zeus Oracle Memories

> **Index of all persistent memories** — fast lookup, one-line hooks. < 200 lines.

**Last Updated**: 2026-07-16 · **Total Entries**: 2 · **Index Size**: ~200 tokens

---

## System & Process Documentation
- [Memory consolidation rules](MEMORY-RULES.md) — Systematic rules for what to save where, when, TTL (∞)
- [Worktree isolation protocol](learnings/worktree-isolation-protocol.md) — Git worktree workflow for large changes (∞)

---

**How to Use**:
1. Scan description for relevance
2. Load if <7 days old OR explicitly referenced
3. Archive expired memories to `memory/archive/YYYY-MM/` after 14 days

**Add New Memory**: Read `MEMORY-RULES.md` first. Save with frontmatter (name, description, type, ttl). Add pointer here.

---

**Related Locations**:
- Cache (L1): `~/.claude/projects/<project>/cache.json`
- Vault (persistent): `ψ/memory/{learnings,retrospectives,reference}/`
- Inbox (ephemeral): `ψ/inbox/{handoff,escalation}/` — expires 14d
