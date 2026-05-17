# Skill: Dashboard UI — 100% Lifecycle Observability

## Purpose
Design and wire compact live dashboards for Omega OS with full task lifecycle visibility.

## Observability Requirements
**100% Event Coverage**: Track all task lifecycle events from intent decode → proof written

### Event Lifecycle Tracking
1. **Intent Decoded** — Task intent parsed and classified
2. **Memory Gate Done** — Memory context validated
3. **Risk Gate Done** — Risk level assigned
4. **Route Decided** — Primary + fallback lanes selected
5. **Lane Started** — Execution on primary lane begins
6. **Lane Completed** — Execution on primary lane finishes
7. **Fallback Started** (if needed) — Fallback lane execution begins
8. **Proof Written** — Task proof finalized and persisted
9. **Writeback Done** — Result synced to memory/outbox

### Dashboard Pages
- **Overview** — Success rate, throughput, health
- **Learning** — Failure classification, rules generated, promotion
- **Lanes** — Per-lane performance, SLA, health
- **Performance** — Latency (p50/p95/p99), error rate
- **Real-time** — Live event stream
- **Health** — System status, probes
- **Circuit Breaker** — Per-lane state (CLOSED/HALF_OPEN/OPEN)
- **Constitution** — Compliance score, rules enforced, violations
- **Fleet** — Agent status, relay log
- **Benchmarks** — World-class test results (12/12 passing)

### Data Sources
- `ψ/memory/resonance/events-{date}.jsonl` — All lifecycle events
- `ψ/memory/resonance/proofs/` — Task proof archive
- `ψ/memory/resonance/learning-summary-{date}.json` — Phase 7 results
- `ψ/memory/resonance/performance-metrics-{date}.json` — Lane metrics
- `ψ/memory/resonance/circuit-breaker-state.json` — CB state
- `ψ/memory/resonance/fleet-status-{date}.json` — Agent status
- `ψ/memory/resonance/benchmark-results-{date}.json` — Test results

### Style
- Compact Tailwind UI
- Lucide icons
- Small shadow cards
- readable 15-16px fonts
- No mock data — real API endpoints
- Auto-refresh (30s default, configurable)
- CORS-enabled for cross-origin requests
- WebSocket-ready for real-time event streaming

### API Endpoints (metrics-api.py)
- GET /metrics/learning — Learning engine metrics
- GET /metrics/lanes — Per-lane metrics
- GET /metrics/intents — Intent distribution
- GET /metrics/confidence — Confidence scores
- GET /metrics/circuit-breaker — Circuit breaker state
- GET /metrics/constitution — Constitution compliance
- GET /metrics/fleet — Multi-agent fleet status
- GET /metrics/benchmarks — World-class test results
- GET /health — System health check

