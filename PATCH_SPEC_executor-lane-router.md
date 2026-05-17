# PATCH SPEC: Executor Lane Router
**Date**: 2026-05-17  
**Status**: 🔒 LOCKED (Ready for implementation)  
**Owner**: THAM + Core  
**Scope**: Core-owned module, NOT service (Phase 1)

---

## 📋 Decision Summary

```
Router Logic Location: Core-owned Module
Module Name: executor-lane-router
Architecture: Modular (can migrate to service later)
Rollback Path: Within Core repo (safe)
Drift Prevention: ✅ Keeps router near queue/proof/schema gate
```

---

## 🔧 Implementation Phases

### Phase 1: Documentation + Schema
**Files**: Patch Core docs + schema  
**Deliverable**:
- [ ] Architecture doc (router flow)
- [ ] Route schema (JSON schema validation)
- [ ] Routing decision table (task → lane mapping)
- [ ] Proof spec (what counts as done)

### Phase 2: Core Module Implementation
**Files**: Patch `Core/executor-lane-router.ts` (or Python/Go equiv)  
**Deliverable**:
- [ ] Module source code
- [ ] Route decision logic
- [ ] Memory gate integration (20s timeout)
- [ ] Risk gate integration (20s timeout)
- [ ] Fallback policies (timeout handling)

### Phase 3: Event Stream (Dashboard)
**Files**: Patch Core dashboard event emitter  
**Deliverable**:
- [ ] Event-per-step JSON stream
- [ ] Event schema (intent_decoded, memory_gate_done, etc.)
- [ ] Fallback: poll_latest_snapshot

### Phase 4: Proof + Completion
**Files**: Patch Core proof writer  
**Deliverable**:
- [ ] Proof JSON schema
- [ ] Completion criteria checklist
- [ ] Summary file template (changed files + rollback)

### Phase 5: Smoke Test
**Test Lanes**: codex, gemini, ollama, hermes-legacy  
**Deliverable**:
- [ ] Sample task → routes to correct lane
- [ ] Proof JSON generated
- [ ] Dashboard events visible
- [ ] Rollback tested

---

## 📐 Schema

```json
{
  "executor_lane_router": {
    "router_location": "core_owned_module",
    "router_module": "executor-lane-router",
    
    "gate_timeout_policy": {
      "memory_gate_timeout_sec": 20,
      "risk_gate_timeout_sec": 20,
      "on_memory_timeout": "continue_with_context_cache_or_minimal_context",
      "on_risk_timeout": "default_risk_level_medium"
    },
    
    "hermes_trigger_conditions": [
      "explicit route.lane == hermes",
      "legacy task contract requires hermes adapter",
      "local hands-runner task with allowlisted tool capability",
      "fallback lane when primary local executor unavailable and risk_level != high"
    ],
    
    "dashboard_event_policy": {
      "mode": "event_per_step",
      "fallback": "poll_latest_snapshot",
      "events": [
        "intent_decoded",
        "memory_gate_done",
        "risk_gate_done",
        "route_decided",
        "lane_started",
        "lane_completed",
        "proof_written",
        "writeback_completed"
      ]
    },
    
    "completion_criteria": {
      "required_files": [
        "architecture_doc",
        "route_schema",
        "routing_decision_table",
        "dashboard_events_json",
        "proof_json",
        "summary_txt",
        "obsidian_writeback"
      ],
      "done_when": [
        "all required_files exist",
        "route_schema validates",
        "at least one sample task resolves route.lane",
        "proof_json.result is OK or CHECK with explicit reason",
        "summary_txt includes changed files and rollback path"
      ]
    }
  }
}
```

---

## 🎯 Why This Approach

| Aspect | Benefit |
|--------|---------|
| **Core-owned** | Router stays near queue/proof/schema → no drift |
| **Module NOT service** | Rollback simple, keep scope minimal Phase 1 |
| **Modular design** | Easy to extract to microservice Phase 2+ |
| **Event stream** | Dashboard can track every decision |
| **Timeout policies** | Doesn't block on slow memory/risk gates |
| **Hermes conditions** | Explicit, not default (safety first) |

---

## 🚀 Next Actions

1. **Create patch branch** on Core repo
2. **Phase 1**: Implement schema + docs (codex-a or codex-b)
3. **Phase 2**: Implement module (codex-b)
4. **Phase 3**: Add dashboard events (claude)
5. **Phase 4**: Add proof + completion (claude)
6. **Phase 5**: Smoke test all lanes (tham verify)

---

## 📝 Rollback Path

If Phase 1-5 fails:
```bash
git revert PATCH_executor-lane-router_phase-N
# Router logic rolls back to old poller
# No state lost (Core repo only)
# Safe to retry or pivot
```

---

**Status**: 🔒 LOCKED  
**Decision**: Approved by พี่เอก + ธาม  
**Ready**: Phase 1 implementation
