# Runtime Flow — Executor Lane Router (Phase 1A)

**Purpose**: Define execution sequence, gate timeouts, fallback logic, and proof capture.

**Status**: SPEC (Phase 1A, ready for Phase 2 implementation)  
**Updated**: 2026-05-17

---

## High-Level Sequence

```
Task arrives (inbox/queue)
    ↓
[Memory Gate] read ACTIVE_INDEX + profile + oracle.md
    ↓ PASS (or timeout → medium risk)
[Intent Gate] classify intent signal + risk level
    ↓ PASS (or timeout → unrouted, use default)
[Routing Decision] consult decision table + fallback policy
    ↓
[Health Check] verify primary lane + fallback lane available
    ↓ OK (or degraded → log warning)
[Execute on Lane] send task to routed executor
    ↓
[Proof Capture] collect stdout, stderr, execution time, result
    ↓
[Validate Proof] schema check + completion criteria
    ↓ PASS
[Write Proof] save to `proofs/` directory + log summary
    ↓
[Update Queue] mark task DONE + emit summary + next action
```

---

## Gate Timeout Policy

### Gate Execution Order & Timeout Windows

| Gate | Order | Timeout | Trigger | Action on Timeout |
|---|---|---|---|---|
| **Memory Gate** | 1 | 5s | Read ACTIVE_INDEX (max age 60m) + profile.md (max age 120m) + oracle.md | Set `risk_level = medium`; proceed with shallow context |
| **Risk Gate** | 2 | 10s | Classify risk level (low/medium/high) based on intent + metadata | Default to `medium`; allow non-high lanes |
| **Intent Gate** | 3 | 30s | Parse intent signal → match against decision table | Default to `unknown` task type; route to `codex_gpt55` + `ollama` fallback |

**Cumulative timeout**: 45s total (gates 1–3) before task is blocked.

### Timeout Escalation Rules

```
If any gate times out:
  risk_level → escalate by 1 tier (low → medium → high)
  log: [GATE_TIMEOUT] gate=<name> elapsed=<time>s risk_escalated=<new_level>
  
If risk_level reaches "high":
  block Hermes lane (always)
  use only claude + codex_gpt55 + ollama lanes
  emit warning to dashboard
  
If all gates timeout (45s+ with no progress):
  task = BLOCKED
  return to queue for manual inspection or escalation
  proof: timeout_log + gate_attempts + recommendation
```

---

## Routing Decision Flow

### Step 1: Consult Decision Table

```
Input: intent_signal, risk_level, explicit_lane
Output: primary_lane, fallback_lane

Logic:
  IF explicit_lane is set → use it (bypass table)
  ELSE
    match intent_signal against decision table rows
    select primary_lane from matched row
    select fallback_lane from matched row
    verify fallback_lane != primary_lane (no self-fallback)
  
  IF no match found → use default (unknown/unrouted)
    primary_lane = codex_gpt55
    fallback_lane = ollama
```

### Step 2: Apply Risk-Level Filters

```
If risk_level = high:
  IF primary_lane == hermes OR fallback_lane == hermes:
    remove hermes, use next-best lane
    log: [HERMES_BLOCKED] risk_level=high
    
If primary_lane unavailable:
  immediately transition to fallback_lane
  log: [LANE_UNAVAILABLE] lane=<name> switching_to_fallback
```

### Step 3: Fallback Chain Logic

```
Fallback policy = sequential (default):
  1. Try primary_lane (with timeout = task_timeout / 2)
  2. If primary fails/timeout → try fallback_lane (with timeout = task_timeout / 2)
  3. If fallback fails/timeout → return BLOCKED + proof

Fallback policy = random (optional):
  1. Randomly select between primary + fallback (weighted by health)
  2. If selected lane fails → try other lane once
  3. If both fail → return BLOCKED + proof

Fallback policy = weighted (future):
  1. Rank lanes by recent success rate
  2. Route proportional to reliability
  3. Fallback to lowest-ranked lane if primary fails
```

---

## Health Check Polling

### Pre-Routing Health Check (every task)

```bash
For primary_lane, fallback_lane:
  Ping endpoint (e.g., 9router port 20128 + /health)
  
  If response < 200ms: status = ok
  If response 200–500ms: status = degraded (log warning, allow routing)
  If response > 500ms: status = down (skip lane, use fallback)
  If no response (timeout): status = down
```

### Dashboard Event Emission

```
Every health check emits:
  { 
    event: "health_check_complete",
    lane: "<name>",
    status: "ok|degraded|down",
    response_time_ms: <int>,
    timestamp: "<ISO-8601>"
  }
```

---

## Proof Capture & Validation

### Proof Structure

```
Proof directory: proofs/<YYYY-MM-DD>/<task_id>.json

Content:
{
  "task_id": "task_abc123de",
  "routed_lane": "codex_gpt55",
  "fallback_lane": "ollama",
  "risk_level": "medium",
  "status": "SUCCESS|BLOCKED|TIMEOUT|ERROR",
  "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
  "gate_timeouts": {
    "memory_gate": 2.3,
    "risk_gate": 1.1,
    "intent_gate": 5.2
  },
  "execution_timestamp": "2026-05-17T12:34:56+07:00",
  "execution_duration_seconds": 42.5,
  "lane_response": {
    "status_code": 200,
    "response_time_ms": 2100,
    "output_length": 4567
  },
  "proof_path": "proofs/2026-05-17/task_abc123de.json",
  "proof_summary": "Routed to codex_gpt55 → SUCCESS. Task completed in 42.5s.",
  "next_action": "Write result to Obsidian; queue next batch"
}
```

### Completion Criteria (DONE_WHEN)

✅ Task is DONE when ALL of the following are true:

1. **Schema validates**: proof JSON matches `executor-lane-router.schema.json`
2. **Sample route passes gates**: a representative task successfully transits gates 1–3
3. **Proof exists**: proof file written to `proofs/<YYYY-MM-DD>/<task_id>.json` + readable
4. **Proof linked**: `proof_path` field populated + cross-reference in task queue summary
5. **Next action clear**: `next_action` field describes exact next step (not "TBD")

### Validation Check (Phase 2 automated)

```bash
jq -e '.routed_lane | IN("codex_gpt55", "claude", "gemini", "ollama", "hermes", "powershell_sfsr")' proofs/2026-05-17/task_abc123de.json
jq -e '.status | IN("SUCCESS", "BLOCKED", "TIMEOUT", "ERROR")' proofs/2026-05-17/task_abc123de.json
jq -e '.execution_timestamp | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T")' proofs/2026-05-17/task_abc123de.json
```

---

## Dashboard Event Stream

### Events Emitted Per Task

| Event | Trigger | Payload |
|---|---|---|
| `task_arrive` | Task enters router | `task_id`, `intent` |
| `gate_pass` | Gate 1/2/3 passes | `gate_name`, `elapsed_seconds` |
| `gate_timeout` | Gate times out | `gate_name`, `timeout_seconds`, `new_risk_level` |
| `lane_routed` | Task assigned to lane | `primary_lane`, `fallback_lane`, `risk_level` |
| `health_check` | Lane availability checked | `lane`, `status`, `response_time_ms` |
| `execution_start` | Task sent to lane | `task_id`, `lane`, `timestamp` |
| `execution_complete` | Task returns result | `task_id`, `lane`, `duration_seconds`, `status` |
| `proof_written` | Proof saved to disk | `task_id`, `proof_path`, `proof_summary` |
| `task_done` | Task fully processed | `task_id`, `next_action` |

Each event includes `timestamp`, `source`, `level` (INFO/WARN/ERROR).

---

## Error Handling & Retry Logic

### Task Failure Modes

| Failure | Cause | Response |
|---|---|---|
| **Gate Timeout** | Memory/Risk/Intent gate exceeds threshold | Log timeout + escalate risk + proceed with degraded context |
| **Lane Unavailable** | Health check fails for primary | Skip to fallback immediately; log warning |
| **Execution Timeout** | Lane does not respond within task deadline | Log timeout + try fallback (if available) |
| **Execution Error** | Lane returns error code (4xx/5xx) | Log error + try fallback (if available) |
| **Proof Validation Fail** | Proof schema invalid or incomplete | Block task completion; emit error + return to manual queue |

### Retry Policy

```
Primary lane fails → try fallback once
Fallback fails → return BLOCKED + proof + request manual inspection

No automatic retry loop (prevents infinite loops + ensures auditability)
Manual retry via queue + explicit next_action
```

---

## Integration with Multi-Agent System

### Task Queue Interface

```
Task inbox: `tham-node` / `json inbox`
    ↓ read task
    ↓ execute router (this flow)
    ↓ write proof
    ↓ update inbox status
    ↓ emit next_action
```

### Proof Writeback

```
proofs/ directory → Obsidian writeback (Phase 1E)
    ↓
Summary note: `ψ/memory/resonance/router-proof-summary.md`
```

---

## Phase 1 Completion Checklist

- [x] Routing decision table + glossary
- [x] Schema (JSON)
- [x] Runtime flow (this document)
- [ ] Proof schema (Phase 1D)
- [ ] Obsidian writeback (Phase 1E)
- [ ] Sample route test (Phase 2)
- [ ] Full implementation (Phase 2+)

---

## Next: Phase 1D (proof-schema.md)

Define proof validation criteria + sample proof records + test expectations.
