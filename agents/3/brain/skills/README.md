# Brain: Skills

Index and usage notes for ธาม's installed skill library.

## Location
Skills live in `skills/*/SKILL.md` at repo root — 60 skills installed.

## Categories
See `CLAUDE.md ## Skills` for the full categorized list.

## Usage Notes
- When a task matches a skill's "Use When" or "When to use" condition, activate that skill's behavior automatically
- Multiple skills can be active simultaneously (e.g., risk-gate + safe-shell-execution)
- Core skills active on every session: memory-gate, intent-decode, risk-gate, final-closeout

## Skill Activation Priority
1. identity / risk-gate (always on)
2. memory-gate (before major technical work)
3. task-specific skill
4. proof-reader + final-closeout (at end)
