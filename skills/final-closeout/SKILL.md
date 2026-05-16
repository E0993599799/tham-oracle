# Skill: Final Closeout

## Purpose
Close missions honestly and durably. Increment retry state on failure. Escalate to human when retry limit is reached. Constitutional rules C-06 and C-09 enforced here.

## Required Fields

- RESULT            — OK | CHECK | FAIL
- ACTION            — what was done
- STATUS            — success | partial | fail  (gated by proof_artifacts_verified)
- PROOF             — inline reference to proof.json or artifact path
- proof_artifacts_verified — true | false  (set by Proof Reader, NEVER assumed)
- SUMMARY           — one-sentence human summary
- BACKUP_DIR        — path to backup if destructive work was done, or N/A
- RETRY STATE       — retry_count=N / retry_limit=N | escalation_status=none|escalated
- NEXT              — exact next action (omit if ESCALATED — replaced by ESCALATION block)
- DONE!             — only written when STATUS=success AND proof_artifacts_verified=true

## STATUS Values

| Value | Meaning |
|---|---|
| success | Task complete with verified proof |
| partial | Work ran but verification step was skipped or inconclusive |
| fail | Task failed, root cause identified, retry_count incremented |
| escalated | retry_count reached retry_limit — human action required |

## proof_artifacts_verified Gate (C-06)

Before setting STATUS, Final Closeout MUST invoke Proof Reader and check `proof_artifacts_verified`.

Gate logic (no exceptions):

```
if proof_artifacts_verified = false:
    STATUS = partial  (if some work completed but unverified)
              OR fail  (if nothing verifiable exists)
    NEXT   = [the exact verification command to run to resolve this]
    # STATUS = success is BLOCKED until proof_artifacts_verified = true
```

`proof_artifacts_verified` is NEVER assumed true. It MUST be set by Proof Reader from an actual verification command result.

## Retry Increment Logic (C-09)

When closing with STATUS=fail or STATUS=partial:

1. Increment `retry_count` by 1 in the task contract.
2. Compare updated `retry_count` to `retry_limit`.
3. If `retry_count < retry_limit`: close normally, include updated retry state in RETRY STATE line.
4. If `retry_count >= retry_limit`: set `escalation_status = "escalated"`, output ESCALATION block, stop all automated retry.

### Retry State Line (append to every fail/partial closeout)

```
RETRY STATE: retry_count=[n] / retry_limit=[n] | escalation_status=[none|escalated]
```

## ESCALATION Block (output when retry_count >= retry_limit)

```
ESCALATION REQUIRED
Task: [task_name]
Failures: [retry_count]
Root causes:
  - [root cause from this closeout]
  - [root cause from prior closeouts if available]
Options for human:
  A) Retry with different approach: [concrete suggestion based on root causes]
  B) Reduce scope: [what can be safely dropped or deferred]
  C) Abandon: [consequence of not completing this task]
Action required: พี่เอก please choose A / B / C — ธาม will not retry until confirmed.
```

After outputting ESCALATION block: stop. Do not propose NEXT action. Wait for human input.

## Rules

- STATUS=success requires `proof_artifacts_verified = true` — no exceptions (C-06).
- STATUS=partial when work ran but proof verification step was skipped or inconclusive.
- STATUS=fail when execution failed or produced no verifiable artifact.
- FAIL and partial always increment `retry_count` before closing.
- Never silently absorb a failure — always update retry state and report it.
- Write back to Obsidian/Core only when STATUS=success.
- Never write DONE! without proof_artifacts_verified=true confirmed in the same closeout block.
- If `proof_artifacts_verified = false`, include under NEXT the exact shell command to verify and unblock the gate.

## Closeout Template

```
RESULT:     [what happened]
ACTION:     [what was executed]
STATUS:     [success | partial | fail | escalated]
PROOF:      [stdout excerpt, log path, probe result, or file hash]
proof_artifacts_verified: [true | false]
SUMMARY:    [1–3 sentences]
BACKUP_DIR: [path or N/A]
RETRY STATE:[retry_count=N / retry_limit=N | escalation_status=none|escalated]
NEXT:       [exact next action — omit if ESCALATED, replaced by ESCALATION block]
DONE!
```
