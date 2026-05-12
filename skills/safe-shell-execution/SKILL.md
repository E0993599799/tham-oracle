# Skill: Safe Shell Execution

## Purpose
Run shell commands safely across WSL/Linux and Windows.

## Rules
- Know whether command is running in WSL or Windows.
- Prefer explicit paths for ambiguous commands.
- Validate cwd.
- Avoid destructive commands unless explicitly intended.
- Use timeout for long-running commands.
- Preserve logs.

