# Skill: Risk Gate

## Purpose
Prevent unsafe, destructive, irreversible, or unverified actions. Enforce constitutional rule C-09: no retry loop may exceed 2 retries without human escalation.

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
