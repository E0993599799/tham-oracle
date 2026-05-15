# Multi-Agent Workflow Kit — Step-by-Step Guide

**Date**: 2026-05-15  
**Goal**: Run multiple AI agents in parallel on your repo, each isolated in its own git worktree + tmux pane.

---

## What You'll Build

```
Your terminal after setup:
┌─────────────────┬─────────────────┐
│  Agent 1        │  Agent 2        │
│  (Claude Code)  │  (Claude Code)  │
│  branch:        │  branch:        │
│  agents/1       │  agents/2       │
├─────────────────┴─────────────────┤
│  Agent 3 / Root (main branch)     │
└───────────────────────────────────┘
Each pane is independent. Each has its own branch.
They can all work simultaneously without conflicts.
```

---

## Step 0: Prerequisites

Install these tools first:

```bash
# git (need 2.5+ for worktrees)
git --version

# tmux (terminal multiplexer)
# Ubuntu/Debian:
sudo apt install tmux

# yq (YAML parser — required by MAW scripts)
# Ubuntu/Debian:
sudo snap install yq
# macOS:
brew install yq

# Python 3.9+ and uvx
pip install uv     # installs uvx

# Optional but recommended:
sudo apt install direnv   # auto-loads .envrc when you cd
```

Verify:
```bash
git --version && tmux -V && yq --version && uvx --version
```

---

## Step 1: Initialize MAW in Your Repo

Navigate to your existing project (or create one):

```bash
cd /path/to/your/project

# If new project:
git init && git commit --allow-empty -m "init"

# Install MAW:
uvx --from git+https://github.com/laris-co/multi-agent-workflow-kit.git multi-agent-kit init
```

**What happens**:
- Toolkit files copied into `.agents/`, `.claude/`, `.codex/`
- `agents.yaml` created with 3 default agents (1, 2, 3)
- Git worktrees created at `agents/1`, `agents/2`, `agents/3`
- Tmux session launched automatically
- You land in a split-pane tmux session

**If you have direnv**, run this after init:
```bash
direnv allow
```

---

## Step 2: Load the `maw` Command

Every time you open a new terminal in this repo:

```bash
# With direnv (auto):
cd /path/to/your/project   # maw is auto-loaded

# Without direnv (manual):
source .envrc

# Verify:
maw version
```

---

## Step 3: Understand the Default Setup

After init, your repo looks like:

```
your-project/
├── agents/
│   ├── 1/    ← Agent 1's isolated working directory (branch: agents/1)
│   ├── 2/    ← Agent 2's isolated working directory (branch: agents/2)
│   └── 3/    ← Agent 3's isolated working directory (branch: agents/3)
├── .agents/
│   ├── agents.yaml    ← Agent definitions (edit this)
│   └── scripts/       ← All the scripts
├── .claude/commands/  ← Slash commands for Claude Code
└── MAW-AGENTS.md      ← Guidelines doc
```

Check your agents:
```bash
maw agents list
# Shows: agent name, branch, worktree path, git status
```

---

## Step 4: Configure Your Agents (agents.yaml)

Open `.agents/agents.yaml` and customize:

```yaml
agents:
  1:
    branch: agents/1
    worktree_path: agents/1
    description: "Frontend agent — Next.js components"

  2:
    branch: agents/2
    worktree_path: agents/2
    description: "Backend agent — API routes & DB"

  3:
    branch: agents/3
    worktree_path: agents/3
    description: "QA agent — tests & review"
```

After editing, re-provision:
```bash
maw install
```

---

## Step 5: Start the Tmux Session

```bash
# Default layout (3 panes)
maw start

# Or choose a layout:
maw start 0   # 3-pane (default): top + split bottom
maw start 1   # Left full + right stacked (4 agents)
maw start 5   # 6-pane grid (full visibility)
```

**Inside tmux navigation**:
```
Ctrl+B then arrow keys   → Move between panes
Ctrl+B then z            → Zoom/unzoom current pane
Ctrl+B then d            → Detach (session stays running)
```

If you detached or got disconnected:
```bash
maw attach
```

---

## Step 6: Navigate to an Agent's Worktree

From any terminal in the repo:

```bash
maw warp 1        # cd to agents/1/
maw warp 2        # cd to agents/2/
maw warp root     # cd back to repo root

# Or navigate manually:
cd agents/1
git branch        # shows: * agents/1
```

Each agent's worktree is a full checkout of the repo on its own branch. Changes there don't affect main or other agents.

---

## Step 7: Open Claude Code in Each Agent Pane

In each tmux pane (each agent's worktree), start Claude Code:

```bash
# In agents/1/ pane:
cd agents/1
claude

# In agents/2/ pane:
cd agents/2
claude
```

Each Claude Code instance operates independently on its own branch.

---

## Step 8: Send Tasks to Agents

From your main terminal or root pane — you can send commands/prompts to any agent without switching panes:

```bash
# Send a prompt to agent 1
maw hey 1 "Implement the user profile page at src/app/profile/page.tsx"

# Send to agent 2
maw hey 2 "Add the /api/users/[id] GET route with Supabase"

# Send to all agents simultaneously
maw hey all "git status"
maw hey all "git pull"

# Send to root pane
maw hey root "git log --oneline -5"
```

**From inside Claude Code** (slash commands):
```
/maw.hey 1 implement the billing page
/maw.hey all git pull
```

---

## Step 9: Keep Agents in Sync

When main gets new commits (from PRs, merges, your own work):

```bash
# In root pane (main branch):
maw sync
# → runs: git pull --ff-only origin main
# → then broadcasts /maw.sync to ALL agents
# → each agent runs: git merge main
```

Each agent can also sync individually:
```bash
# In an agent pane (agents/1 branch):
maw sync
# → runs: git merge main (brings in latest from local main)
```

**From Claude Code**:
```
/maw.sync    # syncs whichever branch you're on
```

---

## Step 10: Monitor Agent Work

```bash
# See agent worktrees and their git status
maw agents list

# Check what changed in agent 1's worktree
cd agents/1 && git diff main

# Zoom in on agent 1's pane to read its output
maw zoom 1   # toggle maximize
maw zoom 1   # toggle back to normal view
```

---

## Step 11: Merge Agent Work

When an agent finishes a task, merge its branch into main:

```bash
# In root pane (on main branch):

# Option A: Merge agent 1's branch
git merge agents/1

# Option B: Squash merge (cleaner history)
git merge --squash agents/1
git commit -m "feat: implement user profile page"

# Option C: Create a PR via gh
cd agents/1
gh pr create --base main --title "feat: user profile page"
```

After merging:
```bash
# Sync all other agents with the new main
maw sync   # in root pane → auto-broadcasts to all agents
```

---

## Step 12: Add a New Agent

```yaml
# 1. Add to .agents/agents.yaml:
agents:
  4:
    branch: agents/4
    worktree_path: agents/4
    description: "Documentation agent"
```

```bash
# 2. Create the worktree:
maw agents create 4

# 3. Restart session to add new pane:
maw kill
maw start 5   # use 6-pane layout for 4 agents
```

---

## Step 13: Clean Up When Done

```bash
# Remove a specific agent (keeps code on branch)
maw remove 3

# Remove all agents
maw remove

# Kill tmux session (agents/worktrees preserved)
maw kill

# Full uninstall (remove entire toolkit)
maw uninstall
```

---

## Daily Workflow Summary

```bash
# Morning
cd my-repo
source .envrc        # or direnv auto-loads
maw sync             # pull latest from remote
maw start            # launch tmux session

# Working
maw hey 1 "build feature X"
maw hey 2 "fix bug Y"
maw zoom 1           # focus on agent 1
maw hey all "/maw.sync"  # keep everyone updated

# End of day
maw kill             # close session
# Worktrees and branches persist for tomorrow
```

---

## Common Workflows

### Parallel Feature Development

```bash
maw hey 1 "Implement the frontend billing page at src/app/billing/page.tsx"
maw hey 2 "Implement the backend /api/billing/subscribe POST route"
maw hey 3 "Write tests for the billing flow in tests/billing.test.ts"
# All 3 run simultaneously on separate branches
```

### Code Review

```bash
# In root pane — see all diffs
cd agents/1 && git diff main
cd agents/2 && git diff main

# Or send review prompt to an agent
maw hey 3 "Review the changes in agents/1 and agents/2, report issues"
```

### Bug Fix

```bash
# Assign to agent 2
maw hey 2 "Fix the null pointer crash in src/api/orders/[id]/route.ts when order has no line items"

# Monitor
maw zoom 2

# When done, merge
git merge agents/2 -m "fix: null pointer in orders API"
```

### Create GitHub Issue from Claude Code

```
/maw.issue --title "Bug: login fails on Safari" --body "Steps: 1. Open Safari 2. Click login..." --label bug
```

---

## Troubleshooting

**Session already exists**:
```bash
maw kill && maw start
# or attach:
maw attach
```

**Agent has uncommitted changes, won't sync**:
```bash
cd agents/1
git add . && git commit -m "wip"
maw sync
```

**Worktree missing but still in agents.yaml**:
```bash
maw install   # recreates missing worktrees
```

**Can't find maw command**:
```bash
source .envrc   # reload
# or:
direnv allow
```

**Wrong pane gets the message from maw hey**:
```bash
maw hey --map   # see agent-to-pane mapping
maw hey --list  # see available agents
```

**Start fresh**:
```bash
maw uninstall
uvx --from git+https://github.com/laris-co/multi-agent-workflow-kit.git multi-agent-kit init
```

---

## Glossary

| Term | Meaning |
|------|---------|
| **Worktree** | A separate checkout of the same git repo in a different directory, on its own branch |
| **Agent** | An AI instance (Claude Code, Codex, etc.) running in a dedicated worktree + tmux pane |
| **Root pane** | The main branch pane — the source of truth |
| **Hey** | Broadcasting a command/prompt to a specific agent's pane |
| **Sync** | Pull from remote (root) or merge local main (agents) |
| **Warp** | Navigate to an agent's worktree directory |
| **Profile** | A tmux pane layout configuration (0–5) |
| **Session** | The tmux session: `ai-<repo-name>` |
| **MAW** | Multi-Agent Workflow — the toolkit itself |
