# Skill: Background No-Window Execution

## Purpose
Run Windows automation without disruptive CMD/PowerShell popups.

## Rules
- Default to background/no-window for non-human-in-loop process calls.
- Use CreateNoWindow, WindowStyle Hidden, detached runner, watchdog, and timeout where appropriate.
- Avoid WSH, wscript.exe, cscript.exe, and .vbs launchers.
- Do not kill important processes blindly.
- Collect live evidence before patching popup causes.

