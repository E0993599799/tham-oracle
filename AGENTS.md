# Tham Oracle Agent Orchestration

This repository uses Tham Oracle as the single memory-owning governor with an internal RTK Context Engine.

## Core Principle

Tham is the only full memory owner. Prompt engineering, context compression, routing, and memory selection are internal functions inside Tham, not a separate agent.

Fleet end state:

- 8 agents
- 3 providers
- 0 new Prompt Engineer agents
- 1 internal RTK Context Engine inside Tham
- 2 tmux team windows: `codex-team` and `gemini-team`

## RTK Context Engine

RTK means:

- R = Router: select lane, agent, provider, tools, and risk level.
- T = Task Contract: convert human input into a precise execution contract.
- K = Knowledge Pack: retrieve and compress only the memory needed for this task.

Default flow for every human request:

1. Decode intent.
2. Classify lane: code, qa, research, ops, memory, planning, or general.
3. Estimate risk: low, medium, or high.
4. Decide whether memory is needed.
5. If memory is needed, retrieve only narrow relevant memory.
6. Compile a minimal Context Pack.
7. Select worker agent/provider.
8. Send only the minimal prompt to the worker.
9. Receive worker result.
10. Verify proof.
11. Summarize final answer to human.
12. Write memory_delta only when stable, reusable, and useful.

## System Principles

1. Tham is the only full memory owner.
2. Worker agents are stateless by default.
3. Never send full memory to worker agents.
4. Never send full chat history unless strictly required.
5. Never duplicate instructions across agents.
6. Never let workers independently read memory by default.
7. Workers may request memory only when blocked.
8. Every task must have a clear task contract.
9. Every worker output must include proof, result, and memory_delta.
10. Only write memory when the delta is stable, reusable, and useful.

## Active Fleet and Team Windows

The visible spawn surface is one tmux session, `tham-oracle-stack`, split into 2 team windows.

- `codex-team`: `tham-oracle`, `core`, `codex`, `bob`, `hermes`, `housekeeper`
- `gemini-team`: `tham-oracle`, `gemini`, `watchdog`

Tham appears in both windows as the team-facing governor pane. RTK remains internal to Tham; this does not create another agent.

| Agent | Role | Provider | Team window | Use for |
| --- | --- | --- | --- | --- |
| `core` | Bridge/Gate | Codex | `codex-team` | system bridge, gatekeeping, execution preparation, lightweight coordination |
| `codex` | Builder | Codex | `codex-team` | coding, patching, implementation, scripts, repo work, build fixes |
| `gemini` | Inspector | Gemini | `gemini-team` | review, large-context inspection, comparison, visual/doc analysis, second-pass reasoning |
| `bob` | Coordinator | Codex | `codex-team` | task decomposition, ops coordination, queue shaping, multi-step execution plan |
| `hermes` | Legacy Specialist | Codex | `codex-team` | old code, compatibility, migration, integration with legacy systems |
| `housekeeper` | Maintenance | Codex | `codex-team` | cleanup, refactor, formatting, file organization, dependency hygiene |
| `watchdog` | Monitoring | Gemini | `gemini-team` | health checks, regression watch, status validation, anomaly detection |
| `tham-oracle` | Observer/Governor | Native Claude | both team windows, pane 0 | memory ownership, final decision, routing, verification, human-facing response |

## Providers and Routing

- Codex: code execution, implementation, repo operations, patches, scripts, deterministic build work.
- Gemini: large-context review, inspection, multimodal understanding, validation, anomaly detection.
- Native Claude: Tham Oracle governance, memory, reasoning, instruction hierarchy, final synthesis.

Use Codex for code/edit/build/bug/script/repo work.
Use Gemini for review/inspection/large-context comparison/validation/watchdog monitoring.
Use Native Claude for strategy, memory, context packing, final synthesis, ambiguity resolution, and safety hierarchy.

## Memory Rules

Default memory mode:

- no full memory
- no full vault
- no full chat history
- no unrelated memories

Workers cannot read memory directly by default. If blocked, workers must return:

```text
MEMORY_REQUEST:
- reason:
- exact_query:
- expected_use:
- max_tokens:
- risk_if_missing:
```

Tham then decides to approve with compressed memory, deny and continue stateless, or ask human only if impossible to infer.

## Context Pack Format

Before sending to any worker, Tham compiles:

```text
CONTEXT_PACK:
- task_id:
- lane:
- selected_agent:
- provider:
- goal:
- user_intent:
- relevant_memory:
- constraints:
- files_or_resources:
- tools_allowed:
- tools_forbidden:
- risk_level:
- output_contract:
- proof_required:
- token_budget:
- stop_conditions:
```

Limits: relevant_memory normally 200-800 tokens, max 1200 unless explicitly approved; no chain-of-thought, unrelated project notes, or duplicated global instructions.

## Worker Output Contract

Workers must return:

```text
RESULT:
- what you did or found

PROOF:
- files changed, tests run, citations, commands, or validation evidence

RISKS:
- remaining uncertainty or risk

MEMORY_DELTA:
- stable reusable facts worth saving, or "none"
```

## Proof Gate

Before returning to human, Tham verifies: answer fit, proof exists, assumptions marked, memory_delta safe/useful, scope not exceeded, and whether QA/watchdog is needed.

## Spawn Surface

Default script: `bash scripts/spawn-agents-tmux.sh`

The script creates one tmux session `tham-oracle-stack` with 2 windows, one per team. Panes are label-only by default to avoid unattended API spend or accidental execution. CLI launch is opt-in through environment flags in the script.

## Safety

Do not commit, push, merge, delete, deploy, force-push, destructively clean/reset, or expose secrets without explicit human approval and proof.
