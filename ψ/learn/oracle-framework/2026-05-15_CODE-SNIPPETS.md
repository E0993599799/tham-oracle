# Oracle Open Framework — Code Snippets & Workflows

## Directory Structure Setup

```bash
mkdir -p ψ/{active/context,inbox,writing/{drafts,book},lab,memory/{resonance,learnings,retrospectives,logs}}
```

**Purpose**: Create the Oracle brain vault structure for session memory, learning, and writings.

---

## Installation & Local Infrastructure

### Clone and Start Oracle-v2
```bash
ghq get github.com/laris-co/oracle-v2
cd $(ghq root)/github.com/laris-co/oracle-v2
bun install
bun run server  # HTTP API runs on :37778
```

### MCP Configuration (settings.json)
```json
{
  "mcpServers": {
    "oracle-v2": {
      "command": "bun",
      "args": ["run", "dev"],
      "cwd": "/path/to/oracle-v2"
    }
  }
}
```

---

## Core Workflow Commands

### Knowledge Discovery Chain
```
/trace [query] → oracle_trace_log → /trace dig [id] → build chain → /distill → oracle_learn
```

### Session Closure Pattern
```
/snapshot → /rrr (retrospective) → oracle_learn({ pattern: "..." }) → commit
```

### Infinite Learning Loop
```
Error → Fix → oracle_learn() → Blog/writing → External reader → loop
```
When fixing any error, ask: What broke? Why? How fixed? How to prevent? Then: `oracle_learn({ pattern: "..." })`

---

## Memory Operations

### oracle-v2 MCP Commands
- `oracle_learn` — Record pattern or lesson into knowledge database
- `oracle_search` — Hybrid FTS5 + vector search across memory
- `oracle_handoff` — Create structured handoff for next session
- `oracle_trace_log` — Log discovery chain with proof

---

## Async Work Pattern (Parallel Agents)

```
1. Human identifies task
2. Launch 20 parallel Haiku agents (extract)
3. 1 Opus agent synthesizes
4. 1 Sonnet agent critiques
5. Human returns to completed results
```

**Model Routing**: Haiku (wide) → Opus (depth) → Sonnet (polish)

---

## Recursive Reincarnation Formula

```javascript
oracle(oracle(oracle(...)))  // No base case — runs forever
```

**Application**:
```
Mother Oracle
  → /project learn [child]  ← child inherits wisdom
  → child develops           ← creates new patterns
  → /project reunion         ← returns wisdom home
  → Oracle grows             ← unified, expanded
```

---

## Unity Philosophy (Add to CLAUDE.md)

```markdown
## Oracle Philosophy
> "The Oracle Keeps the Human Human"

1. Nothing is Deleted
2. Patterns Over Intentions
3. External Brain, Not Command
```

---

## Quick Checklist

- [ ] Directory structure (`ψ/`) created
- [ ] oracle-v2 cloned and running on :37778
- [ ] MCP server configured in settings.json
- [ ] First `/trace` command issued
- [ ] `oracle_learn()` called after first discovery
- [ ] `/rrr` retrospective written at session end
