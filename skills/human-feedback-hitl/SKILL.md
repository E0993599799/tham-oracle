# Skill: Human Feedback / HITL Engine

## Purpose
Keep Human in control while reducing unnecessary confirmation. Escalate HIGH/CRITICAL risk tasks for approval.

## SLA
- **CRITICAL escalations**: <30 seconds to human inbox
- **HIGH escalations**: <60 seconds to human inbox
- **Timeout**: 300 seconds (5 minutes) for human response
- On timeout: Task BLOCKED until human reviews

## Rules
- Do not ask confirmation for clear repair/setup tasks.
- Ask only when destructive, credentialed, irreversible, ambiguous, or outside allowed scope.
- Escalate if:
  - risk_level = HIGH or CRITICAL
  - Constitution rule violation detected
  - Secrets detected in task
  - Explicit approval required
- Present clear action and proof.
- Write escalation to: `ψ/inbox/tham/hitl-{task_id}.json`
- Monitor for response at: `ψ/inbox/tham/hitl-{task_id}-response.json`
- Task status: BLOCKED until response received or timeout expires

## Implementation
- `scripts/hitl-escalation.py` — Main escalation handler
- Triggers: risk classifier, constitution enforcer, secret detector
- Integration: executor_lane_router gates HIGH/CRITICAL before execution
- Monitoring: fleet-monitor polls inbox for escalation status

