# HERMES TASK: Legacy Compatibility Scan

## RESULT
The scan identified a significant divergence between the current AGENTS.md orchestration instructions and the existing .agents/agents.yaml registry, as well as several legacy tmux scripts that do not align with the 8-agent two-window fleet.

### Key Findings:
1. **Registry Mismatch**: .agents/agents.yaml contains an entirely different fleet (Dheva, Zeus, Warden, Verity, Stratum, Luxi, Lens) and has marked the requested 8-agent fleet (Core, Codex, Bob, Gemini, Housekeeper, Watchdog, Hermes) as disabled_agents.
2. **Orphaned Scripts**: Multiple scripts in gents/1/scripts/, gents/2/scripts/, etc., refer to sessions like oracle-fleet and oracle-v2 rather than the 	ham-oracle-stack.
3. **Legacy Frameworks**: Presence of multi-agent-workflow-kit and 	hemion in ψ/learn/repo suggests residues of previous agent frameworks that may be referenced in documentation or scripts.

## PROOF
**Inspected Paths:**
- .agents/agents.yaml (Direct conflict with AGENTS.md)
- gents/*/scripts/*.sh (Referencing legacy sessions: oracle-fleet, oracle-v2)
- ψ/learn/repo/github.com/laris-co/multi-agent-workflow-kit/... (Legacy framework)
- ψ/learn/repo/github.com/tasanakorn/themion/... (Legacy framework)
- AGENTS.md (Source of truth for current orchestration)

## RISKS
- **Execution Conflict**: Running ash scripts/spawn-agents-tmux.sh (if it relies on .agents/agents.yaml) will spawn the wrong fleet.
- **Operational Confusion**: Workers may find legacy scripts in their paths and attempt to use them, leading to session errors.
- **Registry Drift**: The active AGENTS.md is the only current source of truth; the YAML registry is actively contradictory.

## MEMORY_DELTA
- The repository currently possesses two competing agent definitions: the "Hermes Swarm" (YAML) and the "Tham Oracle 8-Agent Fleet" (AGENTS.md).
- Legacy tmux automation scripts are currently incompatible with the 	ham-oracle-stack two-window architecture.
