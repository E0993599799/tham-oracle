---
name: memory-rules
description: Systematic rules for what to save where in ψ/, when, and for how long
metadata:
  type: reference
  ttl: ∞
---

# Memory Consolidation Rules

## Core Principle

**Write Once, Find Always.** Every fact is recorded exactly once in the right place. No re-deriving, no scattered notes, no ambiguity about where to look.

## Memory Types & Locations

### 1. User Profile (`memory/learnings/user-*.md`)

**What**: Information about the user's role, knowledge, preferences, communication style.

**When to Save**:
- User tells you their job/role/expertise
- User gives feedback on how they like to work
- User states a preference ("I don't like X", "Always do Y")
- User corrects an assumption about themselves

**Examples**:
- "I'm a senior engineer with 10 years Go; new to React"
- "Don't use bold headers, I find them hard to scan"
- "Always suggest the reversible option first"

**Updates**: Only when user clarifies or contradicts prior info. Never delete unless user says to forget.

**TTL**: ∞ (permanent — user identity doesn't expire)

### 2. Feedback (`memory/learnings/feedback-*.md`)

**What**: Rules about how to work with this user/project. What worked, what didn't, what to do/avoid.

**When to Save**:
- User corrects your approach ("no, do it this way instead")
- User confirms a non-obvious choice worked ("yes, exactly")
- You notice a pattern in what user approves vs. rejects

**Examples**:
- "When recommending between reversible and hard-to-undo options for wide blast-radius changes, default to reversible first."
- "User prefers single bundled PR over many small ones for refactors in this area."
- "Don't summarize what you just did at the end of every response, user can read the diff."

**Structure**: Lead with the rule, then **Why:** (reason/incident) and **How to apply:** (when/where).

**Updates**: Update if the rule changes or you learn an exception. Keep the history comment showing when it changed.

**TTL**: ∞ (never expires — patterns don't reverse)

### 3. Project Context (`memory/learnings/project-*.md`)

**What**: Current goals, deadlines, constraints, initiatives, stakeholder decisions.

**When to Save**:
- Sprint/phase starts with specific goals/deadlines
- User states a constraint ("legal flagged this", "must ship by Friday")
- You learn who's doing what and why
- A decision is made that affects scope/direction

**Examples**:
- "Merge freeze starts 2026-03-05 for mobile release cut. Flag any non-critical PR work after that date."
- "Auth middleware rewrite driven by legal/compliance, not tech-debt. Scope decisions should favor compliance over ergonomics."

**Structure**: Lead with fact/decision, then **Why:** (motivation) and **How to apply:** (how this shapes suggestions).

**Updates**: Update when goals change or deadlines shift. Add dates in ISO format (convert "Thursday" → "2026-03-05").

**TTL**: ~3 months (expires when phase/sprint ends; but reference in retros if relevant)

### 4. Decision Record (`memory/learnings/decision-*.md`)

**What**: Why a choice was made. Locked-in-time reasoning.

**When to Save**:
- "We chose A over B because X, Y, Z"
- An architectural choice is made
- A tradeoff is explicitly evaluated

**Examples**:
- "Hard-block agent spawn vs. written mandate RTK: chose written mandate 2026-07-16 because it's reversible, lower blast-radius, can escalate to hard-block if soft version doesn't hold."

**Structure**: Decision date, options considered, chosen option, reasoning, constraints.

**Updates**: Never update — decisions are immutable. If a decision is reversed, write a NEW record explaining why, don't edit the old one.

**TTL**: ∞ (history)

### 5. Session Metrics (`memory/learnings/session-metrics.md`)

**What**: Aggregate data across sessions for trend detection. Token usage, patterns, decision outcomes.

**When to Update**: End of every session. Add one row to the metrics table.

**Example Row**:
```
| 2026-07-16 d4366c5b | zeus-oracle | ~1h | 45% | rtk-setup | ✓ | — | 5 commits | 0 blockers |
```

**Columns**: Date | Session ID | Project | Duration | Token % | Focus | Completed | Friction | Deliverables | Blockers

**Updates**: Append only, never delete. If a session result changes (e.g., follow-up work), add a note in the "Follow-up" column.

**TTL**: ∞ (trend data)

### 6. Retrospectives (`memory/retrospectives/YYYY-MM/DD/HH.MM_title.md`)

**What**: End-of-session reflection. What happened, timeline, AI diary, honest feedback, lessons learned.

**When to Save**: `/rrr` at session end. Always.

**Structure**:
- Session metadata (date, duration, focus)
- What we did (bullet summary)
- Timeline (with specific times/decisions)
- Files modified (repo-relative paths)
- AI Diary (honest self-reflection, not rationalization)
- Honest Feedback (friction, surprises, what could be better)
- Lessons Learned (1-3 insights to apply next time)
- Next Steps (what's pending/open)
- Self-Audit (shipped, blocked, uncomfortable truth, friction points, next steps, rationalizations caught)

**Updates**: Never update — retros are immutable. If you need to correct something, write a follow-up note in the next session's retro.

**TTL**: ∞ (immutable history)

### 7. Resonance (`memory/resonance/*.md`)

**What**: Moments when something clicked, felt right, sparked joy.

**When to Save**: Whenever user or work feels like a breakthrough or beautiful connection.

**Trigger phrases**: "yes exactly", "love it", "that's it", "very cool", "huh, I never thought of it that way"

**Structure**: What felt right, when, why, how. Short + poetic.

**Updates**: Never — resonance is preserved as-is.

**TTL**: ∞ (keep the spark)

### 8. Reference (`memory/reference/*.md`)

**What**: Pointers to external systems. Where bugs are tracked, where decisions live, dashboards to monitor.

**When to Save**:
- "Bugs tracked in Linear project X"
- "Feedback in Slack channel #Y"
- "Oncall watches Grafana board Z"

**Structure**: What system, its purpose, how to use it, when to check it.

**Updates**: Only if URL/path changes or the system is replaced.

**TTL**: ∞ (pointers are stable)

## Ephemeral Memories (Expire — Clean Up)

### Handoff (`inbox/handoff/DATE_title.md`)

**What**: Wrap-up note for the next session. What's pending, context, next steps.

**When**: `/forward` before session end.

**TTL**: 14 days (expires after next session reads it). After that, archive to dated backup.

**Example**: `/inbox/handoff/2026-07-16_phase3-rtk-work.md` → archive to `memory/archive/2026-07/` if not used by 2026-07-30.

### Escalation (`inbox/escalation/DATE_title.md`)

**What**: Decision blocks or bugs that need Boss input.

**When**: Something is blocked waiting for human decision.

**TTL**: 14 days until resolved.

**Example**: `2026-07-16_verification-gap-pattern.md` — flags recurring issue, asks for rule change decision.

### Active Sprint (`active/SPRINT-GOALS.md`)

**What**: Current sprint/phase goals, blockers, daily status.

**When**: Sprint starts.

**TTL**: Sprint end (clear and archive when sprint closes).

**Updates**: Daily — remove completed, add new blockers, update status.

## MEMORY.md Index (< 200 lines)

**Purpose**: Fast lookup of relevant memories without reading all files.

**Format**:
```
- [Title](file.md) — one-line hook. Type/TTL in parentheses (user | feedback | decision | retro | ∞ | 14d)
```

**Maintenance**:
- Add pointer when saving a new memory
- Remove pointer if memory expires (14-day memories only)
- Keep newest first within each type
- One line per memory, max 150 chars per line
- If approaching 200 lines, archive old memories to `memory/archive/2026-MM/MEMORY-snapshot.md`

**Example**:
```
# ธาม-Zeus Oracle Memories

## User
- [Zeus execution boundary — RESOLVED](zeus-execution-boundary-question.md) — Zeus decides execute-vs-delegate per task (user | ∞)

## Feedback
- [RTK protocol scope: all agent types](rtk-protocol-scope-all-agents.md) — RTK mandated for true/fallback/background agents (feedback | ∞)
- [Recommend reversible first](recommend-reversible-option-first.md) — When large blast-radius choice, default reversible (feedback | ∞)

## Project
- [Phase 3 active, due 2026-07-20](phase3-status.md) — Mobile release, merge freeze 2026-07-05 (project | sprint-end)

## Retro (Latest 5)
- [2026-07-16 RTK mandate & boundary resolution](retrospectives/2026-07/16/04.26_rtk-mandate.md) — Soft mandate chosen (retro | ∞)
- [2026-07-16 Hook fixes & claude-mem PR](retrospectives/2026-07/16/03.13_hook-fixes.md) — SessionStart/PreToolUse fixed (retro | ∞)
```

## Loading & Expiry

**Every session RTK (automatic)**:
1. Read `ψ/memory/MEMORY.md`
2. Load entries described as relevant
3. Skip if > 7 days old (unless user asks)
4. Skip ephemeral if expired

**Archive (end of sprint/phase)**:
1. Move expired handoff/escalation files to `memory/archive/YYYY-MM/`
2. Move completed sprint files to `memory/archive/YYYY-MM/`
3. Keep retros, learnings, resonance forever

## Questions to Verify Saving

Before saving a new memory, ask:

1. **Is this write-once or frequently updating?** (Write-once → memory. Frequent updates → active/. Expired → inbox/)
2. **Will this be needed in future sessions?** (Yes → learnings/retro/resonance. No → inbox/)
3. **Is this already written elsewhere?** (Check MEMORY.md index. If yes, update that file instead of creating new.)
4. **What's the TTL?** (∞ for learnings/decisions/retros. 14d for handoff/escalation. Sprint-end for active. 7d for reference if stale.)
5. **Can I find it later?** (Should appear in MEMORY.md index. One-line hook should be searchable.)

---

**Last Updated**: 2026-07-16  
**Version**: 1.0 — Systematic memory rules, enforced per-session
