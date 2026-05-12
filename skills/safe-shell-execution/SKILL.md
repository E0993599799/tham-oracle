# Skill: Safe Shell Execution

## Purpose
Run shell commands safely — with path validation, blast-radius check, log/proof output, and rollback plan.

## When to use
Use whenever executing Bash, PowerShell, or system commands that touch files, processes, or external services.

## Behavior
- Validate all paths exist before read/write operations
- Prefer read-only inspection before any mutating command
- Estimate blast radius: local-only vs shared/irreversible
- For destructive ops (rm, reset, drop, kill): confirm with พี่เอก before running
- Log command + stdout + stderr + exit code as proof
- Prefer PowerShell for Windows targets, Bash/WSL only when project requires Linux
- No interactive popups or foreground windows unless explicitly requested
- On failure: report exit code, last stderr line, and proposed repair action
