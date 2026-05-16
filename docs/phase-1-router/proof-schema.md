# Proof Schema & Validation (Phase 1D)

**Purpose**: Define proof record structure, validation rules, and sample proof records.

**Status**: SPEC  
**Updated**: 2026-05-17

---

## Proof Record Structure

### Top-Level Fields

```json
{
  "task_id": "task_abc123de",                    // unique task identifier
  "routed_lane": "codex_gpt55",                  // primary lane used
  "fallback_lane": "ollama",                     // fallback lane (null if not used)
  "risk_level": "medium",                        // assessed risk (low/medium/high)
  "status": "SUCCESS",                           // outcome (SUCCESS/BLOCKED/TIMEOUT/ERROR)
  "gates_passed": ["memory_gate", "risk_gate"],  // gates that passed
  "gate_timeouts": {                             // gate execution times
    "memory_gate": 2.3,
    "risk_gate": 1.1,
    "intent_gate": 5.2
  },
  "execution_timestamp": "2026-05-17T12:34:56+07:00",
  "execution_duration_seconds": 42.5,
  "lane_response": { ... },                      // lane-specific response
  "proof_path": "proofs/2026-05-17/task_abc123de.json",
  "proof_summary": "Routed to codex_gpt55 → SUCCESS. Task completed in 42.5s.",
  "next_action": "Write result to Obsidian; queue next batch"
}
```

---

## Field Validation Rules

| Field | Type | Rules | Example |
|---|---|---|---|
| `task_id` | string | 8–64 chars, alphanumeric + `-_` | `task_abc123de` |
| `routed_lane` | enum | one of: codex_gpt55, claude, gemini, ollama, hermes, powershell_sfsr | `codex_gpt55` |
| `fallback_lane` | string OR null | if string: must be valid lane; must ≠ routed_lane | `ollama` or `null` |
| `risk_level` | enum | low, medium, high | `medium` |
| `status` | enum | SUCCESS, BLOCKED, TIMEOUT, ERROR | `SUCCESS` |
| `gates_passed` | array(string) | each element in [memory_gate, risk_gate, intent_gate] | `["memory_gate", "risk_gate"]` |
| `gate_timeouts` | object | keys from {memory_gate, risk_gate, intent_gate}; values are seconds (0–300) | `{"memory_gate": 2.3, "risk_gate": 1.1}` |
| `execution_timestamp` | string (ISO-8601) | YYYY-MM-DDTHH:MM:SS+ZZ:ZZ | `2026-05-17T12:34:56+07:00` |
| `execution_duration_seconds` | number | ≥ 0, max 3600 | `42.5` |
| `lane_response.status_code` | integer | HTTP-like code (200, 4xx, 5xx, timeout=999) | `200` |
| `lane_response.response_time_ms` | integer | ≥ 0 | `2100` |
| `lane_response.output_length` | integer | character count of response | `4567` |
| `proof_path` | string (filepath) | relative or absolute; must exist after write | `proofs/2026-05-17/task_abc123de.json` |
| `proof_summary` | string | 1–200 chars, human-readable summary | `Routed to codex_gpt55 → SUCCESS.` |
| `next_action` | string | 1–200 chars, actionable next step | `Write result to Obsidian; queue next batch` |

---

## Validation Checklist (Phase 2 Automated)

```bash
# 1. JSON schema validation
jq -e '.' proofs/2026-05-17/task_abc123de.json > /dev/null || { echo "FAIL: invalid JSON"; exit 1; }

# 2. Required fields present
jq -e '.task_id and .routed_lane and .status and .execution_timestamp and .proof_path' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: missing required fields"; exit 1; }

# 3. Enum validation
jq -e '.routed_lane | IN("codex_gpt55", "claude", "gemini", "ollama", "hermes", "powershell_sfsr")' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: invalid routed_lane"; exit 1; }
jq -e '.status | IN("SUCCESS", "BLOCKED", "TIMEOUT", "ERROR")' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: invalid status"; exit 1; }
jq -e '.risk_level | IN("low", "medium", "high")' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: invalid risk_level"; exit 1; }

# 4. Fallback lane sanity
jq -e '(.fallback_lane == null) or (.fallback_lane != .routed_lane)' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: fallback_lane == routed_lane"; exit 1; }

# 5. Timestamp format (ISO-8601)
jq -e '.execution_timestamp | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}")' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: invalid timestamp format"; exit 1; }

# 6. Duration non-negative
jq -e '.execution_duration_seconds >= 0' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: negative duration"; exit 1; }

# 7. String length bounds
jq -e '(.proof_summary | length) >= 1 and (.proof_summary | length) <= 200' proofs/2026-05-17/task_abc123de.json || { echo "FAIL: proof_summary out of bounds"; exit 1; }

# 8. Proof file exists
test -f "proofs/2026-05-17/task_abc123de.json" || { echo "FAIL: proof file does not exist"; exit 1; }
```

---

## Sample Proof Records

### Sample 1: SUCCESS — codex_gpt55 (Coding Task)

```json
{
  "task_id": "task_write_auth_middleware",
  "routed_lane": "codex_gpt55",
  "fallback_lane": "ollama",
  "risk_level": "medium",
  "status": "SUCCESS",
  "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
  "gate_timeouts": {
    "memory_gate": 1.2,
    "risk_gate": 0.8,
    "intent_gate": 2.1
  },
  "execution_timestamp": "2026-05-17T10:15:22+07:00",
  "execution_duration_seconds": 34.2,
  "lane_response": {
    "status_code": 200,
    "response_time_ms": 3200,
    "output_length": 2847
  },
  "proof_path": "proofs/2026-05-17/task_write_auth_middleware.json",
  "proof_summary": "write_code intent routed to codex_gpt55. Generated auth middleware + tests in 34.2s. Output 2847 chars.",
  "next_action": "Review output; merge to feature branch; queue unit tests"
}
```

### Sample 2: SUCCESS — claude (Architecture Review)

```json
{
  "task_id": "task_review_api_design",
  "routed_lane": "claude",
  "fallback_lane": "codex_gpt55",
  "risk_level": "low",
  "status": "SUCCESS",
  "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
  "gate_timeouts": {
    "memory_gate": 0.9,
    "risk_gate": 0.5,
    "intent_gate": 1.8
  },
  "execution_timestamp": "2026-05-17T10:20:45+07:00",
  "execution_duration_seconds": 28.5,
  "lane_response": {
    "status_code": 200,
    "response_time_ms": 5100,
    "output_length": 3456
  },
  "proof_path": "proofs/2026-05-17/task_review_api_design.json",
  "proof_summary": "review intent routed to claude (deep reasoning lane). Provided architectural feedback + alternative designs in 28.5s.",
  "next_action": "Discuss findings with team; iterate design; queue Phase 2"
}
```

### Sample 3: TIMEOUT — Primary lane times out, fallback succeeds

```json
{
  "task_id": "task_classify_logs",
  "routed_lane": "ollama",
  "fallback_lane": null,
  "risk_level": "low",
  "status": "SUCCESS",
  "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
  "gate_timeouts": {
    "memory_gate": 0.8,
    "risk_gate": 0.4,
    "intent_gate": 1.2
  },
  "execution_timestamp": "2026-05-17T10:25:10+07:00",
  "execution_duration_seconds": 12.3,
  "lane_response": {
    "status_code": 200,
    "response_time_ms": 850,
    "output_length": 456
  },
  "proof_path": "proofs/2026-05-17/task_classify_logs.json",
  "proof_summary": "classify intent (low risk, cheap operation) routed to ollama. Completed in 12.3s.",
  "next_action": "Log classifications; queue batch tagging"
}
```

### Sample 4: BLOCKED — High-risk task, no suitable lane

```json
{
  "task_id": "task_delete_user_data",
  "routed_lane": null,
  "fallback_lane": null,
  "risk_level": "high",
  "status": "BLOCKED",
  "gates_passed": ["memory_gate"],
  "gate_timeouts": {
    "memory_gate": 1.1,
    "risk_gate": 10.0,
    "intent_gate": null
  },
  "execution_timestamp": "2026-05-17T10:30:00+07:00",
  "execution_duration_seconds": 11.1,
  "lane_response": {
    "status_code": null,
    "response_time_ms": null,
    "output_length": 0
  },
  "proof_path": "proofs/2026-05-17/task_delete_user_data.json",
  "proof_summary": "Risk gate timeout → risk_level escalated to HIGH. No lane suitable for destructive task. BLOCKED pending manual approval.",
  "next_action": "Escalate to พี่เอก; require explicit human approval + confirmation"
}
```

### Sample 5: ERROR — Lane returns error

```json
{
  "task_id": "task_search_docs",
  "routed_lane": "gemini",
  "fallback_lane": "ollama",
  "risk_level": "low",
  "status": "ERROR",
  "gates_passed": ["memory_gate", "risk_gate", "intent_gate"],
  "gate_timeouts": {
    "memory_gate": 0.7,
    "risk_gate": 0.3,
    "intent_gate": 1.5
  },
  "execution_timestamp": "2026-05-17T10:35:22+07:00",
  "execution_duration_seconds": 5.2,
  "lane_response": {
    "status_code": 503,
    "response_time_ms": 2100,
    "output_length": 0
  },
  "proof_path": "proofs/2026-05-17/task_search_docs.json",
  "proof_summary": "search_web intent routed to gemini. Gemini returned 503 (Service Unavailable). Tried fallback=ollama but not in glossary for web search. ERROR + manual handling required.",
  "next_action": "Check gemini API health; retry task or assign to alternate lane; log incident"
}
```

---

## Completion Criteria (DONE_WHEN)

✅ Proof schema is DONE when:

1. **All sample records pass validation** — run jq checks above on all 5 samples
2. **Schema and runtime-flow are consistent** — no field mismatches, gate names match
3. **Writeback format defined** — Phase 1E can consume these proof records
4. **Test expectations clear** — Phase 2 knows what success looks like

---

## Phase 1E: Obsidian Writeback

Proof records → `ψ/memory/resonance/router-proof-summary.md`:
- Summary table of tasks routed today
- Success/failure counts
- Risk distribution
- Next actions for human review

Example:
```markdown
## Router Proof Summary — 2026-05-17

| Task ID | Intent | Lane | Status | Duration | Next Action |
|---|---|---|---|---|---|
| task_write_auth_middleware | write_code | codex_gpt55 | SUCCESS | 34.2s | Review + merge |
| task_review_api_design | review | claude | SUCCESS | 28.5s | Discuss findings |
| task_classify_logs | classify | ollama | SUCCESS | 12.3s | Log classifications |
| task_delete_user_data | N/A | — | BLOCKED | 11.1s | Escalate to พี่เอก |
| task_search_docs | search_web | gemini | ERROR | 5.2s | Check gemini health |

**Summary**: 3 SUCCESS, 1 BLOCKED, 1 ERROR. Avg duration: 18.2s. Risk distribution: 4 low, 1 high.
```

---

## Next: Phase 1E (Obsidian Writeback)

Implement writeback integration + sample note generation.
