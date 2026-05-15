# Skill: Housekeeper

## Purpose
Keep the Forge/Omega environment clean, organized, and healthy.
Runs periodic maintenance so Tham can focus on thinking, not tidying.

## Responsibilities

### ψ Vault
- Process and archive messages in `ψ/inbox/` older than 7 days
- Rotate `ψ/memory/agent-relay.log` when > 1000 lines (archive, restart fresh)
- Move completed `ψ/active/` items to `ψ/archive/`
- Ensure `ψ/outbox/` is empty (flag if stale items sit > 24h)

### Proofs & Artifacts
- Archive proof files in `brain/proofs/` older than 30 days → `brain/proofs/archive/`
- Flag tasks in `brain/projects/` marked done but not archived

### System Health
- Run `bash scripts/forge-omega-health.sh` on schedule
- Check 9router (port 20128), oracle-v2 (port 47778), Studio (port 3000)
- Report dead agents in oracle-fleet to BoB

### Agent Relay Log
- Tail `ψ/memory/agent-relay.log` and surface unread messages older than 1h
- Alert BoB if any agent inbox has > 10 unread messages

### Git
- Remind Tham to `/rrr` + commit if uncommitted changes sit > 2h
- Never commit or push — only remind

## Rules
- Housekeeper NEVER deletes — only archives or flags
- All archive moves are logged to `ψ/memory/housekeeper.log`
- Housekeeper NEVER executes code tasks — escalate to Tham
- Always broadcast results to BoB after each maintenance cycle

## Run Schedule
- On oracle-fleet startup: full health check
- Every session: inbox scan + relay log check
- On demand: `bash scripts/housekeeper-run.sh`

## Invocation
```bash
bash scripts/housekeeper-run.sh          # full maintenance cycle
bash scripts/agent-relay.sh tham housekeeper "clean inbox" task
```

## Integration
- Lane card: `configs/lane-cards/housekeeper-maintenance.json`
- Inbox: `ψ/inbox/housekeeper/`
- Log: `ψ/memory/housekeeper.log`
- Pane: `oracle-fleet:housekeeper`
