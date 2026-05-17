# Fallback Agent — Token Overflow Protection

**Purpose**: Spawn secondary agent when primary (ธาม/Tham) reaches token limit

## Activation Rules

```
Token usage > 85% → Prepare fallback
Token usage > 95% → Activate fallback
Token usage = 100% → CRITICAL: Escalate to fallback
```

## Fallback Agent Capabilities

- **Name**: Tham-Backup (Companion Oracle)
- **Model**: Claude Haiku/Opus (auto-selected)
- **Role**: Continue orchestration if primary token exhausted
- **Access**: Same task queue, proof files, git history

## Fallback Routing

When primary agent token limit approached:

```
┌─────────────────────────────────────────────────┐
│ PRIMARY AGENT (ธาม)                             │
│ Token: 85% → Hand off to fallback               │
│ Token: 95% → Prepare brief-down + standby       │
│ Token: 100% → ESCALATE → Fallback takes control│
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│ FALLBACK AGENT (Tham-Backup)                    │
│ - Read latest task state + proof files          │
│ - Continue from last checkpoint                 │
│ - Coordinate with all lanes                     │
│ - Complete pending tasks                        │
│ - Wire results to dashboard                     │
└─────────────────────────────────────────────────┘
```

## Activation Protocol

1. **Monitor**: Job-follower tracks token usage
2. **Warning**: Alert when >85%
3. **Prepare**: Create fallback context snapshot
4. **Activate**: On 100% token, spawn fallback agent
5. **Handoff**: Pass task queue + proof files + status
6. **Continue**: Fallback takes over orchestration

## Handoff Checklist

```json
{
  "handoff": {
    "current_tasks": ["TASK-002", "TASK-PHASE1", "TASK-TEMPERATURE"],
    "completed_tasks": ["TASK-001-cleanup (if done)"],
    "pending_proofs": ["TASK-002-proof.json waiting"],
    "active_lanes": {
      "lane_1": "CODEX-A — TASK-PHASE1",
      "lane_2": "CLAUDE — TASK-002/003/004",
      "lane_3": "SCOUT-1 — monitoring",
      "lane_4": "THAM-MONITOR — verifying"
    },
    "status": "Ongoing execution",
    "next_action": "Continue TASK-002 → complete TASK-003/004 → Temperature project"
  }
}
```

## Fallback Agent Context

**Must read immediately**:
- CLAUDE.md (identity + rules)
- brain/memory/ACTIVE_INDEX.md (baseline)
- tasks/ directory (all task specs)
- reports/ directory (proof files + logs)
- EXECUTOR_LANES_v1.md (lane routing)
- DISPATCH_ORDERS.md (current execution plan)

**Must preserve**:
- Git history (no force push)
- Proof files (all evidence)
- Lane coordination (don't restart)
- Job-follower monitoring (keep running)

## Status

- **Standby**: Ready to activate
- **Trigger**: Primary token = 100%
- **Location**: Will be spawned automatically
- **Name**: Tham-Backup-[timestamp]
- **Deadline awareness**: Inherit all deadlines from primary

