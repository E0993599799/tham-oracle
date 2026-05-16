---
date: 2026-05-17
type: router-proof
phase: 3C-aggregation
source: proofs/2026-05-17/
aggregated: true
---

# Router Proof Summary — 2026-05-17

## Quick Stats

| Metric | Value |
|---|---|
| **Tasks Routed** | 35 |
| **SUCCESS** | 2 |
| **BLOCKED** | 0 |
| **TIMEOUT** | 0 |
| **ERROR** | 31 |
| **Success Rate** | 5.71% |
| **Avg Duration** | 0.15s |

## Success Rate by Lane

| Lane | Tasks | Success Rate | Avg Duration |
|---|---|---|---|
| claude | 8 | 0.0% | 0.0s |
| codex_gpt55 | 18 | 5.56% | 0.15s |
| gemini | 2 | 0.0% | 0.0s |
| ollama | 4 | 0.0% | 0.0s |
| powershell_sfsr | 1 | 100.0% | 0.0s |
| unknown | 2 | 0.0% | 0.0s |

## Success Rate by Intent

| Intent | Tasks | Success Rate | Primary Lane |
|---|---|---|---|
| classify | 2 | 0.0% | ollama |
| patch | 2 | 0.0% | unknown |
| search | 2 | 0.0% | gemini |
| unknown | 2 | 50.0% | powershell_sfsr |
| write_code | 27 | 3.7% | codex_gpt55 |

## Risk Distribution

| Risk Level | Count | % |
|---|---|---|
| Low | 16 | 45.7% |
| Medium | 17 | 48.6% |
| High | 2 | 5.7% |

## Successful Tasks

| Task ID | Lane | Duration |
|---|---|---|
| phase2-implementation | codex_gpt55 | 0.15s |
| test_hermes_allow_low_risk | powershell_sfsr | 0s |

**Summary**: 2 tasks completed successfully. Avg gate time: 0.15s.

## Error Tasks

**Count**: 31

**Errors**:
- classify_intent: Primary ollama failed (Lane returned 404). No fallback available.
- coding_intent: Primary codex_gpt55 failed (Lane error: HTTPConnectionPool(host='localhost', port=20128): Max retrie
- complete_cycle_test: Primary codex_gpt55 failed (Lane error: HTTPConnectionPool(host='localhost', port=20128): Max retrie
- review_intent: Primary claude failed (Lane error: HTTPConnectionPool(host='localhost', port=20128): Max retries exc
- sample_classify_001: Primary ollama failed (Lane returned 404). No fallback available.

## Blocked Tasks

**Count**: 0

**No blocked tasks.**


## Timeout Tasks

**Count**: 0

**No timeout tasks.**


## Anomalies Detected

- **fallback_used**: coding_intent
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: complete_cycle_test
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: review_intent
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: sample_design_001
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: sample_fix_bug_001
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: sample_patch_001
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: sample_performance_001
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: sample_refactor_001
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: sample_review_001
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: sample_search_001
  - Recommendation: Primary gemini failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: sample_security_audit_001
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: sample_write_code_001
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: schema_test
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: search_intent
  - Recommendation: Primary gemini failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_fallback_chain
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_gate_timeouts
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_gates_passed
  - Recommendation: Primary claude failed; fallback codex_gpt55 attempted. Monitor primary lane health.
- **fallback_used**: test_hermes_block_high_risk
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_intent_classify
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_intent_fix
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_intent_review
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_intent_write
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_memory_timeout
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_proof_schema
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_risk_escalation
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_risk_high
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.
- **fallback_used**: test_risk_medium
  - Recommendation: Primary codex_gpt55 failed; fallback ollama attempted. Monitor primary lane health.


## Recommendations

1. Monitor lane health for any degraded services
2. Escalate blocked high-risk tasks for human review
3. Review slow routes to optimize execution
4. Track fallback usage to identify primary lane issues

---

**Generated**: 2026-05-16 23:07:51 UTC
**Aggregated from**: `proofs/2026-05-17/`
**Source**: Phase 3C Proof Aggregator
