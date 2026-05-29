# Skill: Risk Gate

## Purpose
Prevent unsafe, destructive, irreversible, or unverified actions. Enforce constitutional rule C-09: no retry loop may exceed 2 retries without human escalation.

## MANDATORY PRE-FLIGHT CHECKLIST (Run Before Every Action)

Recurring pattern: 4/4 sessions lost 20-30min from acting on unverified assumptions.
Fix: Check these BEFORE advising or acting — not after.

| # | Question | Verify with |
|---|----------|-------------|
| 1 | Does this action depend on a path/file existing? | `ls <path>` or `stat <path>` |
| 2 | Does this action depend on a server/process running? | `pgrep -f <process>` or `curl -s <url>` |
| 3 | Does this action depend on a field/value existing in a file? | `grep <pattern> <file>` |
| 4 | Does this action depend on a repo/branch existing? | `git status` or `gh repo view` |
| 5 | Does this action assume a git-clean or committed state? | `git status --short` |

**Rule**: If ANY answer is "assumed, not verified" → verify FIRST, then act.
**Rule**: If verification fails → report the mismatch, do NOT proceed with the original plan.
**Rule**: This checklist applies even when "saving time" seems worth it — the cost of skipping is always higher.

## Checks

### Safety Checks
- Secrets/API keys/tokens
- Force push/destructive git operations
- Foreground Windows process popups
- File deletion/move risk
- Scheduled task/autorun mutation risk
- Missing proof
- Wrong path or path with spaces
- WSL vs Windows boundary confusion

### Retry Limit Check (C-09)
- Every task contract must carry `retry_count`, `retry_limit`, and `escalation_status`
- Before routing any task: check `retry_count` against `retry_limit`
- If `retry_count > retry_limit` → BLOCK routing, do not execute, escalate immediately
- If `retry_count == retry_limit` → warn human before allowing one final attempt
- If `escalation_status == "escalated"` → BLOCK all automated retries unconditionally

## Task Contract Schema (Required Fields)

Every task contract submitted to Risk Gate must include:

```json
{
  "task_name": "<string>",
  "retry_count": 0,
  "retry_limit": 2,
  "escalation_status": "none"
}
```

Field rules:
- `retry_count`: integer, starts at 0, incremented by Final Closeout on FAIL or CHECK
- `retry_limit`: integer, default 2, may be reduced for high-risk tasks (e.g. destructive ops → limit 1)
- `escalation_status`: enum `"none" | "escalated"` — once escalated, stays escalated until human resets

## Routing Decision Table

| retry_count | escalation_status | Decision |
|---|---|---|
| 0 | none | Proceed normally |
| 1 | none | Proceed, note retry in log |
| 2 | none | Warn human, allow one final attempt |
| > 2 | none | BLOCK — escalate, output ESCALATION block |
| any | escalated | BLOCK — human must reset before any retry |

## Required Result
Proceed, reduce scope, dry-run, or STOP with reason and ESCALATION block when retry limit exceeded.

## ESCALATION Block Format (output when blocking)

```
ESCALATION REQUIRED
Task: [task_name]
Failures: [retry_count]
Retry limit: [retry_limit]
Root causes: [list from prior FAIL/CHECK closeouts]
Options for human:
  A) Retry with different approach: [suggestion based on root causes]
  B) Reduce scope: [what can be safely dropped or deferred]
  C) Abandon: [consequence of not completing this task]
Action required: พี่เอก please choose A / B / C before ธาม proceeds.
```
