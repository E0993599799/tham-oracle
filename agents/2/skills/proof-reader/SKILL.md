# Skill: Proof Reader

## Purpose
Verify task completion from evidence.

## Proof Sources
- stdout/stderr
- summary.txt
- proof.json
- run logs
- error logs
- git status
- HTTP probes
- queue ACK/processed/outbox
- dashboard route status
- Obsidian note existence

## Rules
- RESULT=OK only when proof matches expected result.
- RESULT=CHECK when proof incomplete.
- RESULT=FAIL when execution failed.
- Always include next repair action.

