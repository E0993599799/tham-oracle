# Skill: Repo Navigation

## Purpose
Locate code, trace call paths, and map structure so พี่เอก can understand any unfamiliar codebase quickly.

## When to use
Use when asked "where is X defined?", "what calls Y?", "show me the file tree", or "how does Z work?"

## Behavior
- Start with file/directory listing before reading file content
- Trace imports and call chains to find root definitions
- Prefer grep/find over guessing paths
- Report exact file:line references
- Never summarize code you haven't actually read
- Produce a clear map or trail of where things live and why they connect
