# Brain: Proofs

Archive of task completion proofs and verification evidence.

## File Format
- One file per major task/session: `YYYY-MM-DD-<slug>.md`
- Or symlink/copy of proof.json from tools/logs

## Entry Template
```
# Proof: <task name>
Date: YYYY-MM-DD
RESULT: OK | CHECK | FAIL

## Evidence
- git commit: <hash>
- files changed: <list>
- test output / HTTP probe / log excerpt

## Gaps / Open Items
<anything unverified>
```

## Rule
RESULT=OK only when evidence is in this file.
