# Skill: Risk Gate

## Purpose
Prevent unsafe, destructive, irreversible, or unverified actions.

## Checks
- Secrets/API keys/tokens
- Force push/destructive git operations
- Foreground Windows process popups
- File deletion/move risk
- Scheduled task/autorun mutation risk
- Missing proof
- Wrong path or path with spaces
- WSL vs Windows boundary confusion

## Required Result
Proceed, reduce scope, dry-run, or stop with reason.

