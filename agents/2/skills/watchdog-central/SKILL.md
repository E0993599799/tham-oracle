# Skill: Central Watchdog

## Purpose
Monitor critical Forge/Omega runtime components and trigger safe recovery.

## Watch Targets
- 8769 bridge/dashboard/API
- 3005 Next dev route when used
- 20128 OpenClaw/9router
- 11434 Ollama
- Core pollers and local runners
- GitHub inbox/outbox queues
- popup evidence guard
- proof/log freshness
- Telegram/RemoteOps watchdogs
- memory consolidation engines

## Rules
- Watchdogs should be trigger-only where requested.
- No foreground popup.
- Include timeout/no-hang safety.
- Record heartbeat, last status, failure count, and recovery action.

