# Skill: Proof Reader

## Purpose
Verify task completion from independently-checked evidence. Self-reports from the executor alone are NEVER sufficient (C-06).

## Proof Sources
- stdout/stderr from the actual command
- summary.txt or proof.json on disk
- run logs / error logs
- git status / git log
- HTTP probe responses
- queue ACK / processed / outbox files
- dashboard route status
- Obsidian note file existence

## Verification Methods by Artifact Type

| Artifact type | Required verification command |
|---|---|
| `file` | `ls -la <path>` OR `git log -- <path>` |
| `http` | `curl -s -o /dev/null -w "%{http_code}" <URL>` |
| `git` | `git log --oneline -1` — must show expected commit hash/message |
| `process` | `ps aux \| grep <name>` — must return a live PID |
| `test` | Test runner output must contain PASS / OK / 0 failures |

## Proof Schema

Every task that calls Proof Reader MUST produce a proof object in this shape:

```json
{
  "task_id": "<id>",
  "proof_artifacts": [
    {
      "type": "file|http|git|process|test",
      "description": "<human-readable description>",
      "verification_command": "<exact command run>",
      "verified": true,
      "verified_at": "<ISO 8601 timestamp>",
      "output_snippet": "<first 100 chars of actual command output>"
    }
  ],
  "proof_artifacts_verified": true,
  "verified_by": "independent_check"
}
```

`proof_artifacts_verified` MUST be `false` if:
- `proof_artifacts` is empty, OR
- any artifact has `verified: false`, OR
- no `verification_command` was actually run (i.e., only executor self-report exists), OR
- `output_snippet` is blank or missing

## Result Codes

| Code | Condition |
|---|---|
| `OK` | `proof_artifacts_verified = true` AND at least one artifact verified |
| `CHECK` | Proof exists but verification command was not run or output is missing |
| `FAIL` | Execution failed or proof explicitly contradicts claimed result |

## Rules
- RESULT=OK only when `proof_artifacts_verified = true`.
- RESULT=CHECK when proof object is incomplete or `verified` fields are missing.
- RESULT=FAIL when execution failed or no proof was produced.
- Always include `output_snippet` — never trust a boolean without the raw output.
- Always include a next repair action when RESULT is CHECK or FAIL.
- Proof Reader is called by Final Closeout before STATUS is set. It is not optional.
- `output_snippet` blank = `verified: false`. No exceptions.
