# Multi-Agent Workflow Kit — Scripts & Commands Reference

**Date**: 2026-05-15

---

## maw CLI Commands (Full Reference)

All commands available after `source .envrc` (or direnv loads it automatically).

```bash
maw install          # Provision worktrees from agents.yaml + install tmux plugins
maw start [profile]  # Launch tmux session (profile0–5, default: profile0)
maw attach           # Connect to running session
maw kill             # Kill all MAW tmux sessions (prompts confirmation)
maw agents list      # Show all agents and their worktree status
maw agents create N  # Add a new agent (creates worktree + branch)
maw remove [agent]   # Delete agent worktree (--force for dirty, --dry-run preview)
maw hey <agent> <msg> # Send message/command to a pane
maw send "<cmd>"     # Broadcast command to all panes
maw zoom <agent>     # Toggle tmux pane zoom for an agent
maw warp <agent>     # cd to agents/<agent> worktree directory
maw warp root        # cd back to repo root
maw sync             # Context-aware git sync (see below)
maw issue            # Create GitHub issue via gh CLI
maw catlab           # Download CLAUDE.md from gist
maw uninstall        # Remove entire toolkit from repo
maw version          # Show toolkit version
```

---

## Slash Commands (Inside Claude Code)

Available in any Claude Code session in the repo:

| Command | What It Does |
|---------|-------------|
| `/maw.sync` | Smart sync: pull (root) or merge main (agents) |
| `/maw.hey <agent> <msg>` | Send message to agent pane |
| `/maw.issue --title "X"` | Create GitHub issue |
| `/maw.zoom <agent>` | Toggle zoom on agent pane |
| `/maw.codex <prompt>` | Send prompt to Codex pane (pane 1) |
| `/maw.agents-create create <name>` | Create new agent worktree |
| `/maw.agents-create list` | List all agents |

---

## hey.sh — Message Broadcasting

Send any command or prompt to a specific agent's tmux pane.

```bash
# By agent number
maw hey 1 "git status"
maw hey 2 "analyse this repository"

# By agent name (if named in agents.yaml)
maw hey backend-api "review the schema changes"

# Broadcast to ALL agents (skips root pane)
maw hey all "git pull"
maw hey all "/maw.sync"

# Send to root pane (main branch)
maw hey root "git status"

# List available agents and their pane mapping
maw hey --list
maw hey --map
```

**How it works internally**:
```bash
tmux send-keys -t "ai-repo:0.<pane_index>" "$message"
sleep 0.05
tmux send-keys -t "ai-repo:0.<pane_index>" Enter
```

Pane index = `PANE_BASE + agent_index` (sorted alphabetically by agent name).

---

## sync Command Logic

```bash
maw sync
# OR inside Claude Code:
/maw.sync
```

**Context detection**:
```
On main branch:    git pull --ff-only origin main
                   → then broadcasts /maw.sync to all agents

On agents/* branch: git merge main
                    (brings in latest changes from local main)
```

**Broadcast a sync to specific agent**:
```bash
maw hey 1 "/maw.sync"    # Tell agent 1 to sync
/maw.sync 1              # Same via slash command
```

**Full team sync flow**:
```bash
# In root pane (main branch):
maw sync                 # Pull from remote, then auto-broadcasts to all agents
# Each agent pane will auto-run: git merge main
```

---

## agents.sh — Worktree Lifecycle

```bash
maw agents list              # Show git worktrees + agents/ subdirs
maw agents create codex2     # Add new agent (reads agents.yaml for config)
```

**agents.yaml entry required before create**:
```yaml
agents:
  codex2:
    branch: agents/codex2
    worktree_path: agents/codex2
    model: codex
    description: "Secondary Codex agent"
```

**What `create` does**:
1. Reads config from agents.yaml
2. Validates worktree_path starts with `agents/`
3. `git branch agents/codex2` (if branch doesn't exist)
4. `git worktree add agents/codex2 agents/codex2`
5. Prunes stale registrations: `git worktree prune`

---

## setup.sh — Full Bootstrap

```bash
maw install     # Alias: maw setup
```

Sequence:
1. Check direnv (optional, suggest `direnv allow`)
2. Install TPM to `~/.tmux/plugins/tpm`
3. Install tmux plugins from `.agents/config/tmux.conf`
4. Sync `.claude/commands/` → `.codex/prompts/`
5. `git worktree prune` (clean stale registrations)
6. Create worktrees for all agents in `agents.yaml`

---

## start-agents.sh — Session Launch

```bash
maw start           # Use default profile0
maw start 1         # Use profile1 (left + stacked right)
maw start 5         # Use profile5 (six-pane dashboard)
maw start --detach  # Launch without attaching
maw start --prefix myproject  # Custom session prefix
```

**Session naming**:
```
Default: ai-<repo-name>
Custom:  <prefix>-ai-<repo-name>
Example: ai-multi-agent-workflow-kit
```

**Startup sequence**:
1. Load profile (gets layout variables)
2. Detect agents: `ls agents/` directory
3. `tmux new-session -s ai-<name> -d`
4. Split panes per profile layout
5. Broadcast `direnv allow` to all panes
6. Auto-warp: each pane runs `maw warp <agent>` → navigates to `agents/<N>/`
7. Reload tmux config

---

## remove.sh — Safe Cleanup

```bash
maw remove               # Remove all agents (prompts confirmation)
maw remove 1             # Remove just agent 1
maw remove --dry-run     # Preview what would be deleted
maw remove --force       # Force-remove even dirty worktrees
```

**Safety checks before removal**:
1. Detect uncommitted changes → warns (requires --force to override)
2. Check if branch is merged → warns if unmerged
3. Kill running tmux sessions first
4. `git worktree remove --force agents/<N>`
5. `git branch -d agents/<N>` (if not in use)

---

## issue.sh — GitHub Issue Creation

```bash
# Basic
maw issue --title "Bug: null pointer in /api/orders" --body "Steps to reproduce..."

# With labels and assignees
maw issue --title "Feature X" --body "Do Y and Z" --label feature --assignee username

# From file
maw issue --title "Refactor auth" --body-file docs/tasks/auth-refactor.md

# Piped body
echo "Implement billing" | maw issue --title "Feature: billing"

# Open in browser after creation
maw issue --title "Fix login" --web

# Preview without creating
maw issue --title "Test" --dry-run
```

---

## zoom.sh — Pane Focus

```bash
maw zoom 1        # Toggle zoom for agent 1 (maximize/restore)
maw zoom 2        # Toggle zoom for agent 2
maw zoom root     # Toggle zoom for root pane
maw zoom --list   # List available agents
```

Uses `tmux resize-pane -Z` on the calculated pane index.

---

## uninstall.sh — Full Removal

```bash
maw uninstall            # Remove toolkit (prompts confirmation)
maw uninstall --dry-run  # Preview what will be deleted
maw uninstall --force    # Skip confirmation
maw uninstall --remove-agents  # Also remove agents/ directory
```

Removes: `.agents/`, `.envrc` (MAW sections), `.claude/commands/maw*`, `.codex/`, `MAW-AGENTS.md`

---

## .envrc — Auto Environment

The `.envrc` wraps MAW config in markers so it doesn't conflict with your own env setup:

```bash
# === BEGIN Multi-Agent Workflow Kit ===
export CODEX_HOME="$PWD/.codex"
source .agents/maw.env.sh  # defines maw() function
# === END Multi-Agent Workflow Kit ===

# Your existing .envrc content is preserved above/below the markers
```

With `direnv`: entering the repo directory auto-loads everything. Without `direnv`: `source .envrc` manually.

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SESSION_PREFIX` | `ai` | Prefix for tmux session name |
| `CODEX_HOME` | `.codex/` | Path to Codex prompts |
| `MAW_REPO_ROOT` | CWD at source time | Repo root for warp |
| `SKIP_DIRENV_ALLOW` | unset | Set to `1` to skip direnv broadcast |
| `ANTHROPIC_API_KEY` | — | Your API key (not set by MAW) |

---

## Profiles Quick Reference

```bash
maw start 0   # 3-pane: top dominant + split bottom
maw start 1   # Left full-height + right 3 stacked
maw start 2   # Top row + full-width bottom
maw start 3   # Single full-width (focus mode)
maw start 4   # Three equal horizontal panes
maw start 5   # Six-pane grid (full visibility)
```

Profile variables (in profile*.sh):
- `LAYOUT_TYPE` — key that determines split logic
- `RIGHT_WIDTH` — right column width %
- `BOTTOM_HEIGHT` — bottom row height %
- `TOP_RIGHT_HEIGHT` — top-right pane height %
