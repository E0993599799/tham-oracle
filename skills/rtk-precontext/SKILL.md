# Skill: RTK Pre-Context

> "อ่านครั้งเดียว ใช้ตลอด session"

## Purpose

Collect runtime/toolkit context **once** at the start of a technical session.
Output a compact RTK block that can be referenced throughout — eliminating
repeated file reads, git status checks, and environment probes.

**Token saving**: RTK replaces ~10–20 redundant reads per session with 1 upfront read.

---

## When to Run

- Start of any technical session involving code, Forge/Omega, or shell execution
- After `/recap` — RTK extends recap with live environment data
- Before executor-lane-router — RTK provides the lane context it needs
- When a new repo/project is entered mid-session

---

## RTK Collection Script

Run this as a single bash block. Captures everything in one shot:

```bash
echo "=== RTK PRE-CONTEXT ===" && \
echo "📍 Repo: $(git rev-parse --show-toplevel 2>/dev/null || pwd)" && \
echo "🌿 Branch: $(git branch --show-current 2>/dev/null || echo 'n/a')" && \
echo "📦 Status: $(git status --short 2>/dev/null | wc -l | tr -d ' ') changed files" && \
echo "🕐 Last commit: $(git log -1 --oneline 2>/dev/null || echo 'n/a')" && \
echo "🖥️  Host: $(hostname) | Model: ${ANTHROPIC_MODEL:-claude-sonnet-4-6}" && \
echo "🐚 Shell: $SHELL | CWD: $(pwd)" && \
echo "📋 maw fleet: $(maw oracle list 2>/dev/null | grep '●' | awk '{print $3}' || echo 'n/a')" && \
echo "🔧 Tools: $(which bun gh maw python3 2>/dev/null | xargs -I{} basename {} | tr '\n' ' ')" && \
echo "📊 Active memory: $(ls ~/ghq/github.com/E0993599799/tham-oracle/ψ/memory/retrospectives/$(date +%Y-%m/%d)/ 2>/dev/null | wc -l | tr -d ' ') retros today" && \
echo "=== END RTK ==="
```

---

## RTK Output Format

Store the result as a compact block at the top of your working context:

```
=== RTK PRE-CONTEXT ===
📍 Repo:        /root/ghq/github.com/E0993599799/tham-oracle
🌿 Branch:      main
📦 Status:      2 changed files
🕐 Last commit: 6b32456 rrr: fleet awaken session 2026-05-16
🖥️  Host:        MARCUZ | Model: claude-sonnet-4-6
🐚 Shell:       /bin/bash | CWD: /root/ghq/github.com/E0993599799/tham-oracle
📋 maw fleet:   tham (awake)
🔧 Tools:       bun gh maw python3
📊 Retros today: 1
=== END RTK ===
```

---

## Extended RTK (for Forge/Omega sessions)

When working with Forge/Omega lanes, add:

```bash
echo "=== RTK FORGE CONTEXT ===" && \
echo "🚦 Omega lanes: $(ls ~/.config/omega/lanes/ 2>/dev/null | tr '\n' ' ' || echo 'n/a')" && \
echo "📥 Inbox: $(ls ~/ghq/github.com/E0993599799/tham-oracle/ψ/inbox/ 2>/dev/null | wc -l | tr -d ' ') items" && \
echo "📤 Outbox: $(ls ~/ghq/github.com/E0993599799/tham-oracle/ψ/outbox/ 2>/dev/null | wc -l | tr -d ' ') items" && \
echo "🔑 Core proof: $(ls ~/ghq/github.com/E0993599799/tham-oracle/ψ/outbox/PROOF-* 2>/dev/null | tail -1 | xargs basename 2>/dev/null || echo 'none')" && \
echo "=== END FORGE RTK ==="
```

---

## Token-Saving Rules (from RTK)

Once RTK is captured, apply these rules for the rest of the session:

| Instead of | Use |
|---|---|
| `cat CLAUDE.md` | Reference RTK — identity already known |
| `git status` again | Reference RTK status count |
| `hostname` | Reference RTK host |
| `maw oracle list` | Reference RTK fleet line |
| `ls ψ/memory/` | Reference RTK retro count |
| `git log -10` | Reference RTK last commit, then `git log -3` only when needed |

**Rule**: If it was in the RTK block, do not read it again. Read only NEW information.

---

## Integration with Other Skills

- **memory-gate**: Run RTK *after* memory-gate reads ACTIVE_INDEX — adds live env to static memory
- **intent-decode**: Pass RTK context to intent-decode so it knows current environment
- **executor-lane-router**: RTK `🔧 Tools` line tells the router which lanes are available
- **token-optimizer**: RTK is the primary input to token-optimizer's "what do we already know?" check

---

## Output

RTK is **not written to disk** — it lives in active context only.
It expires at session end. Run fresh each session.

If a session is long and RTK data may be stale (>2h), re-run the script.
