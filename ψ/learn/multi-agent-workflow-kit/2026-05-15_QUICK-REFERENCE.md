# Multi-Agent Workflow Kit — Quick Reference

**Date**: 2026-05-15

---

## What It Is

MAW is a toolkit that orchestrates multiple AI agents working simultaneously on the same git repo. Each agent gets an isolated git worktree (its own branch + directory) and a tmux pane. One Python command installs everything. A `maw` bash function manages the whole system.

---

## Install

```bash
uvx --from git+https://github.com/laris-co/multi-agent-workflow-kit.git multi-agent-kit init
```

Prerequisites: `git` ≥2.5, `tmux`, `yq`, `bash` ≥4.0, Python ≥3.9

---

## Essential Commands

```bash
source .envrc          # Load maw command (or use direnv)
maw install            # Create/recreate worktrees from agents.yaml
maw start [0-5]        # Launch tmux session with layout 0-5
maw attach             # Reconnect to running session
maw kill               # Kill session (worktrees preserved)
maw sync               # Smart git sync (pull or merge based on branch)
maw hey <N> "<msg>"    # Send message to agent N's pane
maw hey all "<msg>"    # Broadcast to all agent panes
maw hey root "<msg>"   # Send to root (main branch) pane
maw zoom <N>           # Toggle pane zoom for agent N
maw warp <N>           # cd to agents/N worktree
maw warp root          # cd back to repo root
maw agents list        # List agents and their status
maw agents create <N>  # Add new agent worktree
maw remove [N]         # Delete agent worktree
maw issue --title "X"  # Create GitHub issue via gh
maw uninstall          # Remove entire toolkit
```

---

## Slash Commands (Claude Code)

```
/maw.sync              # Pull (root) or merge main (agents)
/maw.hey N <msg>       # Send to agent N
/maw.zoom N            # Toggle zoom
/maw.issue --title "X" # Create GitHub issue
/maw.codex <prompt>    # Send to Codex pane
/maw.agents-create list|create <N>
```

---

## Profiles

```bash
maw start 0   # Top + split bottom (default, 3 agents)
maw start 1   # Left + stacked right (4 agents)
maw start 3   # Single full-width (focus)
maw start 5   # Six-pane grid (max visibility)
```

---

## agents.yaml Format

```yaml
agents:
  1:
    branch: agents/1        # must start with agents/
    worktree_path: agents/1
    description: "Frontend"

  2:
    branch: agents/2
    worktree_path: agents/2
    description: "Backend"
```

Edit this file, then run `maw install` to apply.

---

## Sync Rules

```
Root pane (main branch) → git pull --ff-only origin main
                        → then broadcasts /maw.sync to all agents

Agent pane (agents/*) → git merge main
```

---

## Tmux Navigation

```
Ctrl+B arrows    Move between panes
Ctrl+B z         Zoom/unzoom pane
Ctrl+B d         Detach (session stays alive)
```

---

## Daily Flow

```bash
cd my-repo && source .envrc
maw sync                          # pull latest
maw start                         # open tmux
maw hey 1 "build feature X"       # assign task
maw hey 2 "build feature Y"       # assign task
maw hey all "/maw.sync"           # keep in sync
maw zoom 1                        # check on agent 1
git merge agents/1                # merge when done
maw kill                          # end session
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Session exists | `maw kill && maw start` |
| maw not found | `source .envrc` |
| Sync fails (dirty) | `cd agents/N && git commit -am "wip"` |
| Worktree missing | `maw install` |
| Wrong pane mapping | `maw hey --map` |
