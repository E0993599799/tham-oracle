# Skill: Token Optimizer

> "อ่านน้อย รู้มาก ทำได้จริง"

## Purpose

Minimize token usage per session without sacrificing accuracy or safety.
Applied automatically by ธาม on every session — not invoked manually.

**Target**: reduce context consumption by 40–60% through disciplined reading and output habits.

---

## Rule 1: RTK First, Read Second

Before reading ANY file, check if the answer is already in the RTK block.

```
❌ cat CLAUDE.md          → already in context (identity)
❌ git status             → already in RTK
❌ hostname               → already in RTK
✓  grep "specific_thing" file   → targeted, not full read
✓  git log -3 --oneline         → short, scoped
```

---

## Rule 2: Surgical Reads

Never read a full file when you need one section.

| Pattern | Token cost | Use instead |
|---|---|---|
| `cat large_file.md` | HIGH | `grep -n "keyword" file` → read only those lines |
| `Read(file)` full | HIGH | `Read(file, offset=N, limit=30)` |
| `ls -la dir/` | MED | `ls dir/` — no -la unless sizes needed |
| `git log -20` | MED | `git log -5 --oneline` |
| `git diff` full | HIGH | `git diff --stat` first, then targeted `git diff path/file` |

---

## Rule 3: One-Shot Bash Blocks

Combine multiple queries into one bash call. Never call bash twice for things that can run together.

```bash
# ❌ 3 separate calls
git status
git log -3 --oneline
ls ψ/memory/retrospectives/

# ✓ 1 call
git status --short && git log -3 --oneline && ls ψ/memory/retrospectives/2026-05/
```

---

## Rule 4: No Repeat Reads

If a file was read this session, do not read it again unless:
- It was explicitly modified
- More than 1 hour has passed and it's a live file (oracles.json, ACTIVE_INDEX)

Track what was read mentally: CLAUDE.md, ACTIVE_INDEX, oracle.md, fleet configs.

---

## Rule 5: Short Outputs

Match output length to the question's complexity.

| User asks | Response target |
|---|---|
| Simple status ("done?") | 1–3 lines |
| Technical result | Result + proof + next action (no padding) |
| Architecture question | Structured answer, no preamble |
| Error/debug | Root cause + fix + verify — not "let me look at..." |

**Never**: restate the question, summarize what you just did, add "I hope this helps".

---

## Rule 6: Lazy Subagents

Spawn subagents only when:
- Task is parallelizable AND > 5 independent files
- Task needs isolation (different repo, different context)
- Task is slow (>2min) and can run in background

Do NOT spawn subagents for:
- Single file reads
- Short bash sequences
- Questions answerable from RTK

---

## Rule 7: Memory-Gate Before Long Sessions

Before a session involving 5+ file reads or complex decisions:

```bash
# Read ACTIVE_INDEX instead of reading each project file
cat ~/ghq/github.com/E0993599799/tham-oracle/brain/memory/ACTIVE_INDEX.md 2>/dev/null | head -50
```

ACTIVE_INDEX is the pre-summarized state — reading it once replaces 5–10 individual reads.

---

## Rule 8: Grep Before Read

When looking for a specific value in a file:

```bash
# ❌ Read entire CLAUDE.md to find one rule
# ✓ 
grep -n "force push\|secret\|never" CLAUDE.md | head -10
```

---

## Rule 9: Diff Not Full File

When reviewing changes:

```bash
# ❌ cat file.md (after editing)
# ✓ 
git diff HEAD -- file.md
```

Edit tool already confirms the change succeeded. No need to re-read.

---

## Rule 10: Context Budget Awareness

When session file > 2MB (approaching compaction):

```bash
ENCODED_PWD=$(echo "$(pwd)" | sed 's|^/|-|; s|[/.]|-|g')
ls -lh "$HOME/.claude/projects/${ENCODED_PWD}"/*.jsonl 2>/dev/null | tail -1
```

If > 2MB → switch to `--quick` modes, avoid spawning new subagents, prefer grep over read.
If > 5MB → run `/rrr --quick` now, then `/forward` to preserve state.

---

## Token Budget Targets

| Session type | Target max reads | Target output per turn |
|---|---|---|
| Quick fix / single file | 3–5 reads | ≤10 lines |
| Feature implementation | 8–12 reads | structured, no padding |
| Fleet operation | RTK + targeted | table or list only |
| Debug session | 5–8 reads | root cause + fix only |
| Research | unlimited reads | summary ≤200 words |

---

## Integration

- **rtk-precontext**: Run first → defines what NOT to read again
- **memory-gate**: Reads ACTIVE_INDEX → replaces per-project reads
- **context-cache**: Caches recurring project facts in RTK
- **intent-decode**: Decodes intent before reading files — prevents reading files for unclear tasks

## Self-Check

Before each tool call, ask:
1. Is this in RTK? → skip
2. Is this in ACTIVE_INDEX? → skip
3. Can I grep instead of full read? → grep
4. Can I combine with another bash call? → combine
5. Do I need this at all? → skip
