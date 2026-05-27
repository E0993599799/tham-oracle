# Execution Queue Plan: Fleet Routing Strategy
**Agent:** ob (Coordinator)
**Date:** 2026-05-22

## RESULT
Based on AGENTS.md and configs/maw.config.json, I have designed the routing logic for the 8-agent/3-provider fleet. Tham (Governor) will use the internal RTK Context Engine to map tasks to the following execution lanes.

### 1. Routing Matrix (The Lane Map)

| Task Lane | Primary Agent | Secondary/Review Agent | Provider | Routing Logic |
| :--- | :--- | :--- | :--- | :--- |
| **Code** | codex | gemini | Codex $\rightarrow$ Gemini | Direct build/patch $\rightarrow$ Inspector review. |
| **QA/Verification** | gemini | watchdog | Gemini $\rightarrow$ Gemini | High-context inspection $\rightarrow$ Anomaly detection. |
| **Research/Analysis** | gemini | 	ham-oracle | Gemini $\rightarrow$ Claude | Large-scale extraction $\rightarrow$ Synthesis. |
| **Ops/Planning** | ob | core | Codex $\rightarrow$ Codex | Decomposition $\rightarrow$ Bridge/Gate execution. |
| **Legacy/Migration** | hermes | codex | Codex $\rightarrow$ Codex | Compatibility analysis $\rightarrow$ Implementation. |
| **Maintenance** | housekeeper | codex | Codex $\rightarrow$ Codex | Cleanup/Formatting $\rightarrow$ Build check. |
| **Memory/Strategy** | 	ham-oracle | N/A | Native Claude | Sole memory owner; final decision. |

### 2. The Execution Queue Flow (The "Tham Pipeline")

For any incoming human request, Tham executes this sequence:

1. **Intake (RTK-R):** Classify into one of the 7 lanes above.
2. **Contracting (RTK-T):** Define the OUTPUT_CONTRACT (Proof, Result, Memory\_Delta).
3. **Packing (S-K):** Extract 200-1200 tokens of relevant memory.
4. **Dispatch:** Send CONTEXT_PACK to the selected agent.
5. **The Proof Gate:** Tham verifies the PROOF section before accepting the RESULT.
6. **Closure:** Write MEMORY_DELTA to the vault if the fact is stable and reusable.

### 3. Provider Specialization
- **Codex (deterministic):** Implementation, scripting, patching.
- **Gemini (expansive):** Large-context reviews, visual/doc analysis, monitoring.
- **Native Claude (governance):** Reasoning, memory ownership, final synthesis.

## PROOF
- Verified AGENTS.md for agent roles and providers.
- Verified configs/maw.config.json for fleet lineage and team window layout.
- Aligned routing lanes with the tk_context_engine functions listed in config.

## RISKS
- **Latency:** Multi-agent hops (e.g., codex $\rightarrow$ gemini $\rightarrow$ 	ham-oracle) increase response time.
- **Context Leak:** Risk of workers requesting more memory than necessary via MEMORY_REQUEST if the initial CONTEXT_PACK is too narrow.

## MEMORY_DELTA
- Routing Matrix: Established map of Task Lane $\rightarrow$ Agent $\rightarrow$ Provider.
- Pipeline Sequence: Defined the 6-step flow from Intake to Closure.
