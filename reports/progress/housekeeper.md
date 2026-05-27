## Repo Hygiene Scan

### RESULT
- Scan completed. Significant noise detected in git tracking.

### PROOF
- Git status shows numerous absolute paths (C:\, D:\) being tracked or modified outside the workspace root, indicating a likely `.git` directory placement issue or incorrect repository root configuration.

- Specific Noise:
  - Absolute paths to Desktop, Temp, and other users' folders are appearing in `git status`.
  - Untracked orchestration files identified: `AGENTS.md`, `.agents/`, `scripts/spawn-autonomous-fleet-now.sh`, etc.
  - Modified config files: `configs/agent-registry.json`, `configs/pane-registry.json`, `configs/maw.config.json`.

### RISKS
- **Critical Repository Corruption**: The git index appears to be tracking files across the entire system drive, which could lead to catastrophic accidental deletions or massive performance degradation during git operations.
- **Configuration Drift**: Multiple orchestration files (`AGENTS.md` and various `spawn-*.sh` scripts) exist in untracked states, suggesting a lack of version control for the current agent fleet configuration.

### MEMORY_DELTA
- The repository is currently in a "noisy" state where the git root may be misconfigured or contaminated with absolute paths from the host system. All future housekeeper tasks should prioritize stabilizing the git index.
