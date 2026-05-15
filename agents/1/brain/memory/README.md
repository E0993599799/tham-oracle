# Brain: Memory

Persistent operational memory across sessions.

## Structure
- `ACTIVE_INDEX.md` — current active memory entries (keep small, high-value)
- `archive/` — older entries moved here when superseded or resolved

## Rules
- Active index: only facts that change behavior right now
- Archive when resolved, outdated, or replaced by a better entry
- Each entry: date, type (baseline / decision / rule / proof-pointer), body
- Conflicts with live proof → update memory, not live reality
