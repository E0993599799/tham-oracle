RESULT:
- Verified that AGENTS.md, configs/agent-registry.json, configs/pane-registry.json, and scripts/spawn-agents-tmux.sh are internally consistent. All define the 8-agent, 2-window (codex-team/gemini-team) contract.
- Identified a critical contradiction in .agents/agents.yaml: it contains a completely different fleet (dheva, zeus, warden, verity, stratum, luxi, lens) and marks the current active fleet (core, bob, etc.) as disabled. This file is a legacy remnant and must be ignored.
- The high-value summary for the governor: The "ground truth" fleet is correctly implemented in the markdown and JSON configs + spawn script. The .agents/agents.yaml file is a "ghost" and should be purged or explicitly deprecated to avoid agent confusion.

PROOF:
- Comparison of agent lists: AGENTS.md (8 agents) == agent-registry.json (8 agents) == pane-registry.json (8 agents) == spawn-agents-tmux.sh (8 agents).
- Inspection of .agents/agents.yaml reveals agents like "dheva" and "zeus" which do not exist in the active contract.
- Git status shows AGENTS.md and .agents/ as untracked, suggesting they were recently introduced or are outside the current branch tracking.

RISKS:
- Any automated tool reading .agents/agents.yaml instead of AGENTS.md/JSON configs will attempt to spawn the wrong fleet.

MEMORY_DELTA:
- Fleet Contract: 8 agents / 2 windows. Verified consistent across AGENTS.md, registry JSONs, and spawn script.
- Legacy Conflict: .agents/agents.yaml is outdated and contradicts the active fleet. Recommend deletion.

TOP 3 NEXT ACTIONS:
1. Delete .agents/agents.yaml to remove legacy contradiction.
2. Add .agents/ to .gitignore if not already there (since it is currently untracked).
3. Verify that the `tham-oracle-stack` tmux session is currently running with the correct roles via `tmux list-panes`.
