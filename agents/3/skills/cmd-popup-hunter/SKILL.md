# Skill: CMD Popup Hunter

## Purpose
Find and fix recurring CMD/PowerShell/Windows Terminal popups.

## Audit Targets
- cmd.exe
- powershell.exe
- pwsh.exe
- WindowsTerminal.exe / wt.exe
- conhost.exe
- scheduled tasks
- startup shortcuts
- registry Run keys
- shell wrappers
- core/hermes/forge runners

## Rules
- Prefer live event evidence over static guesses.
- Quarantine or patch only confirmed spawners.
- No WSH fallback.
- Verify new events = 0 before closeout.

