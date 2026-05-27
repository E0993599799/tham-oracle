# Tham Oracle Fleet Inspection Report
**Date:** 2026-05-22
**Inspector:** Gemini

## RESULT
The Tham Oracle fleet configuration is **CONSISTENT** across all reviewed files. The system architecture adheres strictly to the mandated 8-agent, 3-provider, 2-window model with internal RTK logic and no separate Prompt Engineer agent.

## PROOF
- **8 Agents Verified:** `tham-oracle`, `core`, `codex`, `bob`, `hermes`, `housekeeper`, `gemini`, `watchdog` are present in `AGENTS.md`, `configs/agent-registry.json`, `configs/pane-registry.json`, and `scripts/spawn-agents-tmux.sh`.
- **3 Providers Verified:**
    - **Codex:** Powers `core`, `codex`, `bob`, `hermes`, `housekeeper`.
    - **Gemini:** Powers `gemini`, `watchdog`.
    - **Native Claude:** Powers `tham-oracle`.
- **2 Tmux Team Windows Verified:**
    - `codex-team`: Contains `tham-oracle` (pane 0) + 5 workers.
    - `gemini-team`: Contains `tham-oracle` (pane 0) + 2 workers.
- **RTK Internal to Tham Verified:** All documents (including JSON comments and script headers) explicitly state "RTK Context Engine is internal to tham-oracle; it is not an agent."
- **No Prompt Engineer Agent Verified:** `AGENTS.md` and `configs/agent-registry.json` explicitly set `prompt_engineer_agents: 0`.
- **Output Contract Consistency:** All worker agents are configured to return `RESULT`, `PROOF`, `RISKS`, and `MEMORY_DELTA`.

## RISKS
- **Tmux Dependency:** The fleet setup depends on a specific tmux environment (`tham-oracle-stack`). Any deviation in tmux version or environment variables (e.g., `ROUTER_BASE_URL`) may cause the `spawn-agents-tmux.sh` script to fail.
- **Stateless Worker Constraint:** Workers are "stateless by default." If the internal RTK engine in `tham-oracle` fails to provide a high-quality "Context Pack," workers may repeatedly hit `MEMORY_REQUEST` loops, increasing latency.
- **Path Sensitivity:** `configs/pane-registry.json` contains hardcoded local paths (`/mnt/d/01 Main Work/...`). While valid for the current environment, these will break if the repo is moved or accessed from a different mount point.

## MEMORY_DELTA
- **Confirmed:** The fleet end state is 8 agents and 3 providers.
- **Confirmed:** `RTK` is a functional component of `tham-oracle`, not a standalone entity.
- **Confirmed:** The prompt engineering role has been internalized within the governor's logic.
