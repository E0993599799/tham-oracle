# multi-agent-workflow-kit Learning Index

## Latest Exploration
**Date**: 2026-05-15

**Files**:
- [[2026-05-15_ARCHITECTURE|Architecture]] — How MAW works, install flow, worktree system, tmux session structure
- [[2026-05-15_CODE-SNIPPETS|Scripts & Commands]] — All maw CLI commands, slash commands, script internals
- [[2026-05-15_QUICK-REFERENCE|Quick Reference]] — Cheatsheet for daily use
- [[2026-05-15_STEP-BY-STEP-GUIDE|Step-by-Step Guide]] — Full teaching guide from install to daily workflow

## What It Is

MAW (Multi-Agent Workflow Kit) runs multiple AI agents simultaneously on the same git repo. Each agent gets: an isolated git worktree (own branch + directory) + a tmux pane. Install with one `uvx` command. Control everything with `maw` bash function.

## Timeline

### 2026-05-15 (First exploration)
- Initial discovery
- Core: git worktrees + tmux + YAML config = parallel agent swarm
- 13 maw subcommands, 6 Claude Code slash commands, 6 tmux layouts
- Sync strategy: root pulls from remote, agents merge local main (context-aware)
- Python entry point is thin — just copies assets and calls shell scripts
- `maw hey` = key primitive: sends any command/prompt to any agent's pane
