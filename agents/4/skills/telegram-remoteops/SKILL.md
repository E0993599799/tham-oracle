# Skill: Telegram RemoteOps

## Purpose
Route remote commands safely through Telegram into Forge/Omega.

## Flow
Telegram -> Tham Intent Decode -> Memory Gate -> Risk Gate -> Core Inbox -> Executor -> Proof -> Dashboard -> Obsidian.

## Rules
- No raw command execution without contract and allowlist.
- Sanitize tokens.
- Verify outbox/Telegram reply.

