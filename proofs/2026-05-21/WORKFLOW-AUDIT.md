---
type: proof
mission_id: WORKFLOW-AUDIT-2026-05-21
auditor: Tham Oracle (claude-sonnet-4-6)
timestamp: 2026-05-21T22:10:00+07:00
scope: "Tham → Hermes → Codex GPT-5.5 routing effectiveness"
status: ineffective_routing_detected
---

# Workflow Audit — Tham → Hermes → Codex (gpt-5.5)

## Verdict
**INEFFECTIVE.** Hermes-in-the-middle adds latency without value when Codex GPT-5.5 is directly addressable. Multiple config drifts detected. **Recommended fix: direct Tham→Codex routing + config sync (F2-F5).**

## Evidence

### 1. Hermes is disabled, but lane card still claims Codex routing role
- `configs/agent-registry.json` → Hermes is in `disabled_agents`: "Legacy/manual specialist only; not spawned by default"
- `configs/lane-cards/hermes-optional.json` (lines 36-41) declares `codex_executor_route` to `50-tham:codex-gpt55` — but Hermes is itself Gemini (`gemini/gemini-3.1-pro-preview`), so it performs no real coding work, only a tmux forward
- Net effect: Tham → Hermes → Codex = 3 hops with zero value added by middle hop

### 2. Config mismatch across 3 source-of-truth files
| Source | codex model | codex location | reality |
|---|---|---|---|
| `agent-registry.json` (line 99) | `cx/gpt-5.5` | `routes_through: 9router` | ❌ 9router has NO `cx/*` models |
| `pane-registry.json` (line 73) | `cx/gpt-5.5` | `tmux_target: tham-oracle-stack:codex` | ❌ that pane is broken |
| `hermes-optional.json` (line 39) | `gpt-5.5` | `tmux_window: 50-tham:codex-gpt55` | ✅ matches live pane |
| `.agents/agents.yaml` (line 17) | `cx/gpt-5.5` | `9router-codex` | ❌ same myth |

### 3. Runtime probe results
```
$ tmux ls
50-tham: 2 windows (created Thu May 21 18:34:08 2026) (attached)
tham-oracle-stack: 7 windows (created Thu May 21 20:33:33 2026)
...

$ tmux list-windows -t 50-tham
0: tham-oracle* (1 panes)
1: codex-gpt55- (4 panes) ← LIVE Codex GPT-5.5 (` ⚕ gpt-5.5 · 7% · 5m`)

$ tmux capture-pane -t tham-oracle-stack:codex -p | tail
codex.sh: line 16: agent exit status: \STATUS: command not found ← BROKEN
```

### 4. 9router model probe
```
$ curl -s http://127.0.0.1:20128/v1/models | jq '.data[].id' | grep -E '^(cx|codex|gpt-5)'
(empty — no codex models in 9router)
```
Codex GPT-5.5 reaches OpenAI direct, not via 9router. The `cx/gpt-5.5` identifier across registries is a fiction.

## Recommended Fixes (all delegated to Codex via MISSION-0)

| ID | Action | Target file |
|---|---|---|
| F2 | Repoint `codex.tmux_target` → `50-tham:codex-gpt55`; mark `tham-oracle-stack:codex` as autonomous-fleet experimental | `configs/pane-registry.json` |
| F3 | Update codex agent: `model: "gpt-5.5"`, `provider: "openai-direct"`, drop `routes_through: 9router`, drop `base_url`; same in `.agents/agents.yaml` | `configs/agent-registry.json`, `.agents/agents.yaml` |
| F4 | Fix `agent exit status: \STATUS:` shell escape bug in autonomous-fleet script | `reports/autonomous-fleet/<ts>/codex.sh` (and its generator under `scripts/spawn-autonomous-fleet-now.sh`) |
| F5 | Drop `codex_executor_route` block from Hermes lane card; redefine Hermes as "Gemini specialist review only — never Codex middleware" | `configs/lane-cards/hermes-optional.json`, `skills/hermes-legacy-adapter/SKILL.md` |

## New Approved Routing Pattern

```
Tham (orchestrator, claude-sonnet-4-6)
  │
  ├── delegate code work → Codex GPT-5.5 @ 50-tham:codex-gpt55 (OpenAI direct)
  ├── delegate research → Gemini @ tham-oracle-stack:gemini (gemini-3.1-pro via 9router)
  ├── inter-oracle relay → BoB @ tham-oracle-stack:bob (Codex via 9router)
  └── specialist review (optional) → Hermes — only when Gemini-3.1-pro fits
                                     (never for plain coding tasks)
```

## Decided By
พี่เอก — 2026-05-21 (selected "Direct Tham→Codex" + "Fix F2+F3+F4+F5")
