# Skill: Memory Management

## Purpose
Read, write, update, and prune ธาม's persistent memory so future sessions start with accurate context.

## When to use
Use when พี่เอก asks to remember/forget something, when starting a major task (read first), or when ending a session (write summary).

## Behavior
- Always read MEMORY.md index before writing to avoid duplicates
- Save: user preferences, project decisions, feedback corrections, external resource pointers
- Do NOT save: code patterns derivable from the repo, git history, ephemeral task state
- Update stale memories rather than appending new conflicting ones
- Verify that file paths and function names in memories still exist before recommending them
- On session end: write RESULT / STATUS / NEXT to appropriate memory file
