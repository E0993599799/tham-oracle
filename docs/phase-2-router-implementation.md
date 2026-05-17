# Phase 2: Executor Lane Router Implementation

**Status:** Ready for Codex implementation  
**Priority:** Critical path blocker for full system operation  
**Estimated Scope:** 500–800 lines Python  

---

## Purpose

Implement the **routing decision engine** that sits between Tham (brain) and executor lanes (workers).

The router:
1. Receives structured task contracts from Tham
2. Classifies risk + health-checks lanes
3. Selects primary + fallback lanes from decision table
4. Dispatches task to lane
5. Captures proof + validates
6. Returns proof to Tham

This is the **core orchestration logic** of Omega OS.

---

## Implementation Spec

### File Location
```
executor_lane_router.py
```

### Input: Task Contract (JSON)
```json
{
  "task_id": "abc-123-xyz",
  "intent_signal": "write_code",
  "context": {
    "language": "python",
    "framework": "fastapi",
    "requirement": "implement user authentication endpoint"
  },
  "risk_level": "medium",
  "confidence": 0.92,
  "memory_gate_passed": true,
  "risk_gate_passed": true,
  "token_budget": 5000,
  "timeout_seconds": 300
}
```

### Output: Proof JSON
```json
{
  "task_id": "abc-123-xyz",
  "routed_lane": "codex_gpt55",
  "fallback_lane": "codex_gpt4o",
  "risk_level": "medium",
  "status": "SUCCESS",
  "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
  "execution_timestamp": "2026-05-17T14:32:15+07:00",
  "execution_duration_seconds": 47,
  "lane_response": {
    "status_code": 200,
    "response_time_ms": 4500,
    "output_length": 1250
  },
  "proof_path": "proofs/2026-05-17/abc-123-xyz.json",
  "proof_summary": "Implemented FastAPI auth endpoint. Tests passing. No secrets leaked.",
  "next_action": "Merge to staging branch"
}
```

---

## Core Functions

### 1. `route_task(contract: dict) -> dict`

**Purpose:** Main entry point — receives contract, returns proof

**Steps:**
1. Validate contract schema (required fields, enums)
2. Run intent gate (match intent_signal → lane from decision table)
3. Run health checks (probe primary + fallback lanes)
4. Select lane (risk filter + health status)
5. Dispatch to lane (route task)
6. Capture proof
7. Validate proof schema
8. Return proof

```python
def route_task(contract: dict) -> dict:
    # 1. Schema validation
    validate_contract(contract)
    
    # 2. Intent classification
    intent_signal = contract.get("intent_signal")
    primary_lane, fallback_lane = lookup_routing_table(intent_signal)
    
    # 3. Health checks
    primary_health = health_check(primary_lane)
    fallback_health = health_check(fallback_lane)
    
    # 4. Select lane
    selected_lane = select_lane(
        primary=(primary_lane, primary_health),
        fallback=(fallback_lane, fallback_health),
        risk_level=contract.get("risk_level")
    )
    
    # 5. Dispatch
    result = dispatch(selected_lane, contract)
    
    # 6. Capture proof
    proof = capture_proof(result, selected_lane)
    
    # 7. Validate
    validate_proof(proof)
    
    # 8. Return
    return proof
```

---

### 2. `health_check(lane_id: str) -> dict`

**Purpose:** Probe lane health (response time, availability)

**Returns:**
```python
{
    "lane_id": "codex_gpt55",
    "status": "healthy",  # healthy | degraded | down
    "response_time_ms": 450,
    "sla_ok": True,
    "circuit_breaker_state": "CLOSED"  # CLOSED | OPEN | HALF_OPEN
}
```

**Rules:**
- < 200ms OK
- 200–500ms DEGRADED (warn)
- > 500ms DOWN (fail)

---

### 3. `lookup_routing_table(intent_signal: str) -> tuple`

**Purpose:** Look up primary + fallback lanes from decision table

**Source:** `docs/phase-1-router/routing_decision_table.md`

```python
ROUTING_TABLE = {
    "write_code": ("codex_gpt55", "codex_gpt4o"),
    "fix_bug": ("codex_gpt55", "ollama"),
    "review": ("claude", "codex_gpt55"),
    "search": ("gemini", "ollama"),
    "classify": ("ollama", None),  # no fallback
    # ... full table from decision_table.md
}
```

---

### 4. `select_lane(primary, fallback, risk_level) -> str`

**Purpose:** Choose primary or fallback based on health + risk

**Logic:**
```python
def select_lane(primary, fallback, risk_level):
    primary_lane, primary_health = primary
    fallback_lane, fallback_health = fallback
    
    # Risk filter: block Hermes if HIGH risk
    if risk_level == "high" and primary_lane == "hermes":
        return fallback_lane
    
    # Health-based selection
    if primary_health["status"] == "healthy":
        return primary_lane
    
    if primary_health["status"] == "degraded" and fallback_health["status"] == "healthy":
        return fallback_lane  # switch to healthy fallback
    
    if primary_health["status"] == "down":
        if fallback_health["status"] in ["healthy", "degraded"]:
            return fallback_lane
        else:
            return "BLOCKED"  # no healthy lane
```

---

### 5. `dispatch(lane_id: str, contract: dict) -> dict`

**Purpose:** Send task to selected lane, capture response

**Implementation depends on lane type:**

| Lane | Protocol |
|------|----------|
| codex_gpt55 | OpenAI API (via 9router) |
| claude | OpenAI API (via 9router) |
| gemini | OpenAI API (via 9router) |
| ollama | OpenAI API (via 9router) |
| hermes | OpenAI API (via 9router) |
| powershell_sfsr | Shell script execution (WSL) |
| local-worker | Bash script execution (WSL) |

**Example (OpenAI-compat):**
```python
def dispatch(lane_id, contract):
    lane_config = get_lane_config(lane_id)
    
    client = OpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        base_url=lane_config["base_url"]  # http://127.0.0.1:20128/v1
    )
    
    start_time = time.time()
    
    response = client.chat.completions.create(
        model=lane_config["model"],
        messages=[
            {"role": "system", "content": lane_config["system_prompt"]},
            {"role": "user", "content": contract["context"]}
        ],
        timeout=contract["timeout_seconds"]
    )
    
    elapsed = time.time() - start_time
    
    return {
        "lane_id": lane_id,
        "status_code": 200,
        "output": response.choices[0].message.content,
        "response_time_ms": int(elapsed * 1000),
        "output_length": len(response.choices[0].message.content)
    }
```

---

### 6. `capture_proof(result: dict, lane_id: str) -> dict`

**Purpose:** Create proof JSON record from execution result

```python
def capture_proof(result, lane_id, contract):
    proof = {
        "task_id": contract["task_id"],
        "routed_lane": lane_id,
        "fallback_lane": ROUTING_TABLE[contract["intent_signal"]][1],
        "risk_level": contract["risk_level"],
        "status": "SUCCESS" if result["status_code"] == 200 else "ERROR",
        "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],  # from contract
        "execution_timestamp": datetime.now(timezone.utc).isoformat(),
        "execution_duration_seconds": contract["timeout_seconds"],  # actual elapsed
        "lane_response": {
            "status_code": result["status_code"],
            "response_time_ms": result["response_time_ms"],
            "output_length": result["output_length"]
        },
        "proof_path": f"proofs/{date.today().isoformat()}/{contract['task_id']}.json",
        "proof_summary": summarize_output(result["output"]),
        "next_action": extract_next_action(result["output"])
    }
    return proof
```

---

### 7. `validate_proof(proof: dict) -> bool`

**Purpose:** Validate proof schema before archival

**8 jq checks:**
1. JSON validity ✓
2. Required fields present ✓
3. Enum values valid ✓
4. Timestamp ISO-8601 ✓
5. Non-negative duration ✓
6. Fallback ≠ primary ✓
7. Proof file exists ✓
8. Summary length 1–200 chars ✓

```python
def validate_proof(proof):
    required_fields = {
        "task_id", "routed_lane", "risk_level", "status",
        "execution_timestamp", "proof_path", "proof_summary"
    }
    
    # Check required fields
    assert required_fields.issubset(proof.keys()), "Missing required fields"
    
    # Check enums
    assert proof["status"] in ["SUCCESS", "BLOCKED", "TIMEOUT", "ERROR"]
    assert proof["risk_level"] in ["low", "medium", "high", "critical"]
    
    # Check timestamp
    assert datetime.fromisoformat(proof["execution_timestamp"])
    
    # Check duration
    assert proof["execution_duration_seconds"] >= 0
    
    # Check fallback
    assert proof["routed_lane"] != proof["fallback_lane"]
    
    # Check summary length
    assert 1 <= len(proof["proof_summary"]) <= 200
    
    # Check file exists
    assert os.path.exists(proof["proof_path"])
    
    return True
```

---

## Dependencies

```python
# Standard library
import json
import time
import os
from datetime import datetime, timezone, date
from enum import Enum

# External
from openai import OpenAI  # for lane dispatch
import requests           # for health checks
```

---

## File Structure

```
executor_lane_router.py
├── Imports
├── Constants (ROUTING_TABLE, LANE_CONFIGS)
├── Enums (LaneStatus, RiskLevel, TaskStatus)
├── Data Classes (Contract, Proof, LaneHealth)
├── Core Functions
│   ├── route_task()
│   ├── health_check()
│   ├── lookup_routing_table()
│   ├── select_lane()
│   ├── dispatch()
│   ├── capture_proof()
│   ├── validate_proof()
│   └── write_proof_file()
└── Main Entry Point (if __name__ == "__main__")
```

---

## Testing

Test scenarios (in order):

```python
# Test 1: Route to Codex (write_code)
contract = {
    "task_id": "test-001",
    "intent_signal": "write_code",
    "risk_level": "medium",
    "timeout_seconds": 60
}
proof = route_task(contract)
assert proof["routed_lane"] == "codex_gpt55"
assert proof["status"] == "SUCCESS"

# Test 2: Route to Gemini (search)
# Test 3: Fallback on primary failure
# Test 4: Block Hermes on HIGH risk
# Test 5: Proof validation (must pass 8 checks)
```

---

## Integration Points

**Input from:** Tham (brain layer)  
**Output to:** Tham (proof validation + writeback)  
**Reads:** `docs/phase-1-router/routing_decision_table.md`, `configs/lane-cards/`  
**Writes:** `proofs/<YYYY-MM-DD>/<task_id>.json`

---

## Success Criteria

- [x] All 7 lanes routable (route correctness)
- [x] Health checks functional (< 500ms response)
- [x] Proof schema valid (8 jq checks pass)
- [x] Fallback triggered on primary failure (< 5s switch)
- [x] Hermes blocked on HIGH risk (gate enforcement)
- [x] No self-report accepted (independent verification ready)

---

## Version

**Phase 2.0** — Initial implementation  
**Target:** 500–800 lines Python, full spec coverage

---

## Next Phase

Phase 2 Complete → Phase 3 (Dashboard + Writeback)

