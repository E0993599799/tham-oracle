# Skill: PowerShell SFSR

## Purpose
Create one-file one-run PowerShell repair/setup scripts for Windows workflows.

## Default Pattern
Use Direct-Safe Add-Line Generator / Flat Add-Line SFSR Pattern.

## Rules
- Generate .ps1.txt first.
- Convert .ps1.txt to .ps1 and validate conversion when runnable.
- Never paste long runnable code into console.
- Use path validation before every read/write.
- Use safe ArgumentList quoting or EncodedCommand for paths with spaces.
- Write logs under tools/logs.
- Update tools/LAST_BACKUP_DIR.txt.
- Produce summary, proof, run log, error log, and backup dir.
- No RESULT=OK without strong proof.

