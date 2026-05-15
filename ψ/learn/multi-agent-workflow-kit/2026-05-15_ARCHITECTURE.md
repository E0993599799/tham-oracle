# Multi-Agent Workflow Kit — Architecture

**Date**: 2026-05-15  
**Version**: 0.5.1  
**Repo**: https://github.com/laris-co/multi-agent-workflow-kit

---

## What It Is

MAW is a Python-based orchestration tool that lets multiple AI agents (or developers) work simultaneously on the same Git repository without stepping on each other. It solves coordination by combining three primitives:

1. **Git Worktrees** — each agent gets an isolated directory + dedicated branch (`agents/1`, `agents/2`, `agents/3`)
2. **Tmux** — all agent panes visible in one terminal session
3. **YAML Registry** — `.agents/agents.yaml` is the single source of truth for agent definitions

---

## Installation Flow

```bash
uvx --from git+https://github.com/laris-co/multi-agent-workflow-kit.git multi-agent-kit init
```

What happens internally (`cli.py`):

1. `ensure_binaries()` — check git, tmux, yq are installed
2. `ensure_git_repo()` — validate/init git repo at CWD
3. `ensure_initial_commit()` — create empty commit if needed (worktrees require a commit)
4. `AssetInstaller.ensure_assets()` — recursively copy toolkit files into repo
5. `maybe_commit_assets()` — prompt to commit toolkit to git
6. `run_script(setup.sh)` — create worktrees, install tmux plugins
7. `run_script(start-agents.sh)` — launch tmux session
8. Print session name + next steps

---

## Directory Structure (After Install)

```
my-repo/
├── .agents/                        # Toolkit core
│   ├── agents.yaml                 # Agent registry (edit this)
│   ├── scripts/
│   │   ├── setup.sh                # Create worktrees + install plugins
│   │   ├── start-agents.sh         # Launch tmux session
│   │   ├── agents.sh               # Create/list/remove agents
│   │   ├── hey.sh                  # Send messages to panes
│   │   ├── zoom.sh                 # Toggle pane zoom
│   │   ├── attach.sh               # Connect to existing session
│   │   ├── kill-all.sh             # Kill sessions
│   │   ├── remove.sh               # Delete agent worktree
│   │   ├── issue.sh                # Create GitHub issues
│   │   ├── send-commands.sh        # Broadcast to all panes
│   │   ├── uninstall.sh            # Remove toolkit
│   │   └── direnv-allow.sh         # Auto-trust .envrc in worktrees
│   ├── profiles/                   # 6 tmux layouts
│   │   ├── profile0.sh             # 3-pane (default)
│   │   ├── profile1.sh             # Left + stacked right
│   │   ├── profile2.sh             # Top row + full-width bottom
│   │   ├── profile3.sh             # Single full-width
│   │   ├── profile4.sh             # Three-pane
│   │   └── profile5.sh             # Six-pane dashboard
│   ├── config/
│   │   └── tmux.conf               # Mouse, theming, TPM
│   ├── maw.env.sh                  # maw() function dispatcher
│   ├── maw.completion.bash
│   └── maw.completion.zsh
├── agents/                         # Worktree root
│   ├── 1/                          # Agent 1 worktree (branch: agents/1)
│   ├── 2/                          # Agent 2 worktree (branch: agents/2)
│   └── 3/                          # Agent 3 worktree (branch: agents/3)
├── .claude/
│   └── commands/                   # Slash commands for Claude Code
│       ├── maw.sync.md + .sh
│       ├── maw.hey.md + .sh
│       ├── maw.issue.md + .sh
│       ├── maw.zoom.md + .sh
│       ├── maw.codex.md + .sh
│       └── maw.agents-create.md
├── .codex/
│   └── prompts/                    # Mirrors .claude/commands/ for Codex
├── .envrc                          # Auto-loads maw() alias via direnv
├── MAW-AGENTS.md                   # Collaboration guidelines
└── .gitignore                      # /.agents, /agents added
```

---

## Core Components

### Python: `cli.py`

Thin orchestrator — no runtime deps beyond stdlib. Routes subcommands and calls shell scripts.

Key args for `multi-agent-kit init`:
```
[profile]           # profile0–5 (default: profile0)
--prefix PREFIX     # Custom tmux session prefix
--detach            # Launch without attaching
--skip-setup        # Skip setup.sh
--setup-only        # Run setup but don't start session
--force-assets      # Overwrite existing files
```

### Python: `install.py` — `AssetInstaller`

Copies `src/multi_agent_kit/assets/` → target repo. Smart behaviors:
- **.envrc**: wraps MAW config in `# === BEGIN/END Multi-Agent Workflow Kit ===` markers, preserves user content
- **.gitignore**: appends ignore patterns without overwriting existing rules
- **Shell scripts**: ensures `chmod +x` on all `.sh` files

### Shell: `agents.yaml` Schema

```yaml
agents:
  1:                              # Agent ID (used as worktree name)
    branch: agents/1             # Git branch
    worktree_path: agents/1      # Relative path (must start with agents/)
    model: claude                # Optional: model hint
    description: "Primary agent" # Optional: label

  2:
    branch: agents/2
    worktree_path: agents/2
```

### Shell: `maw.env.sh` — The `maw` Dispatcher

Sourced by `.envrc`. Defines the `maw()` bash function that routes all subcommands to scripts:

```
maw install/setup → setup.sh
maw start         → start-agents.sh
maw attach        → attach.sh
maw kill          → kill-all.sh
maw agents        → agents.sh
maw remove        → remove.sh
maw hey           → hey.sh
maw zoom          → zoom.sh
maw issue         → issue.sh
maw send          → send-commands.sh
maw uninstall     → uninstall.sh
maw warp <agent>  → built-in: cd agents/<agent>
maw sync          → context-aware git sync
maw catlab        → catlab.sh
maw version       → version.sh
```

---

## Tmux Session Architecture

```
Session: ai-<repo-name>   (or <prefix>-ai-<repo-name>)
  └── Window 0
        ├── Pane 0  → Agent 1  (cd agents/1, branch agents/1)
        ├── Pane 1  → Agent 2  (cd agents/2, branch agents/2)
        ├── Pane 2  → Agent 3  (cd agents/3, branch agents/3)
        └── Pane N  → Root     (cd repo-root, branch main)
```

**Auto-warp**: On startup, `start-agents.sh` sends `maw warp <agent>` to each pane, navigating it to the correct worktree directory.

### Profiles

| Profile | Layout | Agents |
|---------|--------|--------|
| 0 | Top pane + split bottom (default) | 2–3 |
| 1 | Left full-height + right stacked | 3–4 |
| 2 | Top row + full-width bottom | 3 |
| 3 | Single full-width | 1 |
| 4 | Three equal panes | 3 |
| 5 | Six-pane grid (root corners + 4 agents) | 4–6 |

---

## Sync Strategy

The key design: **main is always the source of truth**.

```
Root pane (main branch):    git pull --ff-only origin main
Agent panes (agents/* branch): git merge main
```

`maw sync` is context-aware — detects which branch you're on and runs the right command. When root syncs, it broadcasts `/maw.sync` to all agents so they pull in the latest changes.

---

## Safety Guarantees

- No force-push anywhere — root uses `--ff-only`, agents use regular merge
- Sync refuses if worktree has uncommitted changes
- `maw remove` shows dry-run by default; requires `--force` for dirty trees
- `maw uninstall` prompts for confirmation before deleting
- `.gitignore` patterns prevent accidental commits of agent state
- No API keys in toolkit — user is responsible for secrets

---

## Dependencies

| Tool | Required | Purpose |
|------|----------|---------|
| `git` ≥2.5 | Yes | Worktrees |
| `tmux` ≥3.2 | Yes | Terminal multiplexing |
| `yq` | Yes | Parse agents.yaml |
| `bash` ≥4.0 | Yes | Scripts |
| Python ≥3.9 | Yes (install only) | uvx entry point |
| `direnv` | Optional | Auto-load .envrc |
| `rsync` | Optional | Efficient prompt sync (falls back to cp) |
| `gh` | Optional | GitHub issue creation |
