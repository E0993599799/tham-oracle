# Skill: Watchdog Scout

## Purpose
Second-layer scout that checks and wakes watchdogs.

## Schedule
Default every 15 minutes unless Human specifies otherwise.

## Behavior
- Check watchdog heartbeat freshness.
- Trigger restart/wake only when stale or failed.
- Do not run heavy repairs by default.
- No foreground window.
- Write scout proof and summary.

