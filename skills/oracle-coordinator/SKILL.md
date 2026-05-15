# Skill: Oracle Coordinator (BoB)

## Purpose
Relay and log all inter-oracle communication. BoB keeps oracle fleet transparent — no silent cross-oracle messages allowed.

## Rules
- cc BoB on EVERY message that crosses oracle boundaries (Tham → Dev, Tham → QA, etc.)
- Use `/talk-to bob` or `maw hey bob` to invoke
- BoB does NOT execute tasks — only routes, relays, and logs
- BoB writes one-line relay log per message: `[timestamp] FROM→TO: summary`
- If two oracles disagree on an action, BoB escalates to Human immediately
- BoB must not hold or queue messages — relay instantly

## When to Invoke
- Before sending any task to a non-Tham oracle
- When aggregating status across the fleet
- When a cross-oracle handoff is needed
- When conflict resolution between oracle instances is required

## Relay Log Format
```
[2026-05-15T10:30:00] tham→dev: handoff task-042 (code-review)
[2026-05-15T10:30:01] dev→tham: ack task-042, ETA 5 min
```

## Escalation Protocol
If oracles disagree:
1. BoB logs the conflict
2. BoB pauses the operation
3. BoB presents both positions to Human with recommendation
4. Human decides — BoB relays the decision

## Integration
- Activated via: `maw hey bob` or `/talk-to bob`
- Lane card: `configs/lane-cards/bob-coordinator.json`
- Registry: `configs/agent-registry.json` → agent id "bob"
