# Obsidian Writeback Template — Router Proof Summary

**Purpose**: Template for Phase 1E writeback. Consume proof records from `proofs/` + generate daily summary note in `ψ/memory/resonance/`.

**Filename**: `router-proof-summary-YYYY-MM-DD.md`  
**Location**: `ψ/memory/resonance/router-proof-summary-YYYY-MM-DD.md`  
**Updated**: 2026-05-17

---

## TEMPLATE

```markdown
---
date: YYYY-MM-DD
type: router-proof
phase: 1E-writeback
source: proofs/YYYY-MM-DD/
aggregated: true
---

# Router Proof Summary — YYYY-MM-DD

## Quick Stats

| Metric | Value |
|---|---|
| **Tasks Routed** | N |
| **SUCCESS** | N_success |
| **BLOCKED** | N_blocked |
| **TIMEOUT** | N_timeout |
| **ERROR** | N_error |
| **Avg Duration** | X.Xs |
| **Total Processing Time** | XXXs |

## Success Rate by Lane

| Lane | Tasks | Success Rate | Avg Duration |
|---|---|---|---|
| codex_gpt55 | N | X% | X.Xs |
| claude | N | X% | X.Xs |
| gemini | N | X% | X.Xs |
| ollama | N | X% | X.Xs |
| hermes | N | X% | X.Xs |
| powershell_sfsr | N | X% | X.Xs |

## Success Rate by Intent

| Intent | Tasks | Success Rate | Primary Lane |
|---|---|---|---|
| write_code | N | X% | codex_gpt55 |
| review | N | X% | claude |
| search | N | X% | gemini |
| classify | N | X% | ollama |
| tool_call | N | X% | hermes |
| (unknown) | N | X% | codex_gpt55 |

## Risk Distribution

| Risk Level | Count | % |
|---|---|---|
| low | N | X% |
| medium | N | X% |
| high | N | X% |

## Task Details

### ✅ SUCCESS

| Task ID | Intent | Lane | Duration | Proof |
|---|---|---|---|---|
| task_id_1 | intent | lane | X.Xs | [proof-link] |
| task_id_2 | intent | lane | X.Xs | [proof-link] |

**Summary**: All successful tasks completed without fallback. Avg gate time: X.Xs. No notable issues.

### ⏱️ BLOCKED

| Task ID | Intent | Reason | Risk Level |
|---|---|---|---|
| task_id_1 | intent | Gate timeout → high risk | high |

**Summary**: [describe each BLOCKED task + next action]

Example: `task_delete_user_data` was blocked due to risk escalation during Risk Gate timeout. Requires explicit human approval before proceeding.

### ⚠️ TIMEOUT

| Task ID | Intent | Lane | Gate Failed | New Risk Level |
|---|---|---|---|---|
| task_id_1 | intent | lane_name | gate_name | medium→high |

**Summary**: [describe timeout incidents]

### ❌ ERROR

| Task ID | Intent | Primary Lane | Error | Fallback Attempted |
|---|---|---|---|---|
| task_id_1 | search | gemini | 503 Service Unavailable | ollama (N/A) |

**Summary**: [describe each ERROR + remediation]

Example: `task_search_docs` hit gemini unavailability. Fallback not applicable for web search intent. Recommend retrying when gemini recovers or assigning to alternate lane.

## Gate Performance

### Memory Gate

| Metric | Min | Avg | Max |
|---|---|---|---|
| Execution Time | 0.5s | X.Xs | 2.0s |
| Pass Rate | 100% | — | — |

### Risk Gate

| Metric | Min | Avg | Max |
|---|---|---|---|
| Execution Time | 0.3s | X.Xs | 10.0s |
| Pass Rate | 95% | — | — |
| Timeouts | 0 | — | 1 |

### Intent Gate

| Metric | Min | Avg | Max |
|---|---|---|---|
| Execution Time | 1.0s | X.Xs | 5.2s |
| Pass Rate | 100% | — | — |

**Insights**: [Note any gate anomalies, slow gates, consistent timeouts]

Example: Risk Gate occasionally times out when risk signal is ambiguous. Consider pre-classifying high-ambiguity intents or increasing timeout threshold to 15s.

## Lane Health

| Lane | Status | Avg Response Time | Success Rate | Notes |
|---|---|---|---|---|
| codex_gpt55 | ✅ OK | X.Xms | X% | Stable, reliable |
| claude | ✅ OK | X.Xms | X% | Slow but comprehensive |
| gemini | ⚠️ Degraded | XXXms | X% | High latency; 503 incident |
| ollama | ✅ OK | XXms | X% | Fast, low latency |
| hermes | ✅ OK | XXms | X% | Stable legacy |
| powershell_sfsr | ✅ OK | XXXms | X% | Works for local tasks |

**Recommendations**:
- Gemini: Monitor availability; consider increasing fallback timeout
- Ollama: Excellent performance; good candidate for low/medium-risk batch tasks
- Codex: Reliable; consider raising weight for coding tasks

## Fallback Analysis

| Primary → Fallback | Attempts | Success | Fail Reason |
|---|---|---|---|
| codex_gpt55 → ollama | N | Y | — |
| gemini → ollama | N | N | gemini down, search not in ollama glossary |

**Insights**: Fallback chain works as designed. One instance of glossary mismatch (search → ollama).

## Recommendations for Next Session

1. **Gemini**: Check API status; consider expanding fallback chain or pre-routing web search to ollama when gemini is degraded
2. **Risk Gate**: If timeouts persist, consider pre-classification or threshold increase
3. **Hermes**: Low utilization; good for legacy/local tasks but not heavily used. Keep as optional specialist.
4. **Load Balancing**: Codex and Ollama are workhorses. Consider capacity monitoring.

## Proof Files Generated

- [proof-list with links]

Example:
- `proofs/2026-05-17/task_write_auth_middleware.json`
- `proofs/2026-05-17/task_review_api_design.json`
- ... (N files total)

## Next Actions

- [ ] Review BLOCKED/ERROR tasks + escalate or retry
- [ ] Check gemini health + update lane status
- [ ] Monitor gate performance; tune timeouts if needed
- [ ] Archive proofs from today once reviewed
- [ ] Update dashboard event stream log

---

## Notes

- **Generated**: YYYY-MM-DD HH:MM:SS UTC+7
- **Aggregated from**: `proofs/YYYY-MM-DD/`
- **Next review**: YYYY-MM-DD (next business day)
- **Phase**: 1E (writeback) ✅ DONE
```

---

## Integration Steps (Phase 2)

1. **Proof Aggregator Script** — Read all `proofs/YYYY-MM-DD/*.json`, compute stats
2. **Template Renderer** — Fill template with aggregated data
3. **Obsidian Writeback** — Write note to `ψ/memory/resonance/router-proof-summary-YYYY-MM-DD.md`
4. **Dashboard Update** — Link proof summary to dashboard

Example aggregator (pseudocode):
```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d)
PROOF_DIR="proofs/$DATE"

# Count by status
SUCCESS=$(jq -r 'select(.status=="SUCCESS")' $PROOF_DIR/*.json | wc -l)
BLOCKED=$(jq -r 'select(.status=="BLOCKED")' $PROOF_DIR/*.json | wc -l)
ERROR=$(jq -r 'select(.status=="ERROR")' $PROOF_DIR/*.json | wc -l)

# Compute averages
AVG_DURATION=$(jq -s 'map(.execution_duration_seconds) | add / length' $PROOF_DIR/*.json)

# Render template
envsubst < docs/phase-1-router/OBSIDIAN_WRITEBACK_TEMPLATE.md > ψ/memory/resonance/router-proof-summary-$DATE.md
```

---

## Phase 1 Complete ✅

All Phase 1 deliverables ready for Phase 2 implementation:
- [x] routing_decision_table.md
- [x] executor-lane-router.schema.json
- [x] runtime-flow.md
- [x] proof-schema.md
- [x] OBSIDIAN_WRITEBACK_TEMPLATE.md
