# Oracle Toolkit — Quick Reference

Oracle Toolkit is a CLI wrapper for Omega/Forge orchestration, providing shortcuts for tmux sessions, lane dispatch, inbox management, and git workflows.

## Installation

```bash
# Install aliases (one-time)
bash scripts/setup-oracle-aliases.sh
source ~/.bashrc  # or ~/.zshrc
```

After this, `oracle` command is available everywhere.

## Commands

### Tmux Session Management

| Command | Purpose |
|---------|---------|
| `oracle tmux:start` | Start oracle-session (4-window: chat, memory, shell, brain) |
| `oracle tmux:fleet` | Start oracle-fleet (3×2 pane orchestration layer) |
| `oracle tmux:lanes` | Start 5-lane multi-agent session (THAM, CODEX-A, CODEX-B, GEMINI, CLAUDE) |
| `oracle tmux:attach` | Attach to running session (auto-detect oracle, oracle-fleet, or lanes) |

### Lane Dispatch (requires `lanes` session)

Send tasks to running agent windows via `tmux send-keys`:

| Command | Target |
|---------|--------|
| `oracle lane:codex "implement feature"` | CODEX-A backend builder pane |
| `oracle lane:research "investigate X"` | GEMINI fast inspector pane |
| `oracle lane:core "execute task"` | THAM orchestrator pane |

Example:
```bash
oracle tmux:lanes              # Start session first
oracle lane:codex "fix bug #42"  # Send task to codex-a
```

### Queue & Inbox

| Command | Purpose |
|---------|---------|
| `oracle queue:check` | List ψ/inbox/ folders and file counts |
| `oracle inbox` | Alias for queue:check |

### Proof & Results

| Command | Purpose |
|---------|---------|
| `oracle proof:last` | Show last proof summary from ψ/memory/resonance/ |
| `oracle proof` | Alias for proof:last |

### Status & Health

| Command | Purpose |
|---------|---------|
| `oracle status` | Quick health check: 9router, oracle-v2, tmux sessions, git branch |
| `oracle rtk` | Print RTK precontext block (for shell scripts) |

### Git & PR Workflow

| Command | Purpose |
|---------|---------|
| `oracle pr-create [branch]` | Safe PR creation: check dirty, push, create via `gh` |

## Aliases

After `bash scripts/setup-oracle-aliases.sh`:

| Alias | Expands To |
|-------|-----------|
| `oracle` | `bash /root/ghq/.../bin/oracle` |
| `cc` | `claude` |
| `ccd` | `claude --dangerously-skip-permissions` |
| `gs` | `git status` |
| `gl` | `git log --oneline -15` |
| `gd` | `git diff` |
| `gaa` | `git add -A && git status` |
| `tm` | Attach to oracle tmux session or start it |
| `lanes` | Start 5-lane session |
| `fleet` | Start oracle-fleet session |
| `inbox` | Check queue |
| `proof` | Show last proof |

## Session Layouts

### oracle-session (4-window)
```
[0] chat      — Claude Code session
[1] memory    — Memory Gate reads
[2] shell     — Free shell
[3] brain     — brain/ file browser
```
Quick start: `oracle tmux:start` or `tm`

### oracle-fleet (3×2 pane)
```
Window: brain  |  Window: exec         |  Window: ops
├─ tham       | ├─ core (Omega)       | ├─ housekeeper
└─ bob        | └─ hermes (specialist)| └─ studio (dashboard)
```
Quick start: `oracle tmux:fleet` or `fleet`

### lanes (5-window)
```
[0] THAM (orchestrator)
[1] CODEX-A (backend builder)
[2] CODEX-B (database specialist)
[3] GEMINI (fast inspector)
[4] CLAUDE (UI/architecture)
```
Quick start: `oracle tmux:lanes` or `lanes`

## Examples

### Start an orchestration session
```bash
oracle tmux:lanes     # Start 5-lane session
```

### Send work to agents
```bash
oracle lane:codex "implement user authentication"
oracle lane:research "find best Next.js patterns for RLS"
oracle lane:core "verify proof schema"
```

### Check system health
```bash
oracle status         # Services up/down
oracle queue:check    # Pending inbox tasks
oracle proof:last     # Latest completed task
```

### Git workflow
```bash
gs                    # git status
oracle pr-create      # Safe: push + create PR
```

### Use RTK in scripts
```bash
eval "$(oracle rtk)"
echo "Branch: $GIT_BRANCH"
echo "9router at: $PORT_9ROUTER"
```

## Tmux Configuration

Custom statusline is configured in `configs/tmux.conf`.

Load it:
```bash
tmux source-file configs/tmux.conf
```

Or set permanently in ~/.tmux.conf:
```
source-file /root/ghq/github.com/E0993599799/tham-oracle/configs/tmux.conf
```

Features:
- Oracle-branded statusline (🧠 session name)
- Time/date display
- Vi-like pane navigation (h/j/k/l)
- Keyboard-only (mouse off)

## Troubleshooting

### `oracle` command not found
Make sure you ran `setup-oracle-aliases.sh` and sourced your shell rc:
```bash
bash scripts/setup-oracle-aliases.sh
source ~/.bashrc
```

### Lane dispatch fails ("no lanes session")
Start the lanes session first:
```bash
oracle tmux:lanes
```

### 9router or oracle-v2 not responding
Start the full stack:
```bash
bash scripts/startup-full-stack.sh
```

Or check individually:
```bash
oracle status
```

### Attach to wrong session
Explicitly specify session:
```bash
tmux a -t oracle-fleet
```

## Integration with Omega/Forge

Oracle Toolkit is the visual frontend to Omega/Forge orchestration:

```
User Intent
    ↓
oracle lane:codex "task"    ← CLI wrapper
    ↓
tmux send-keys → codex-a pane
    ↓
Agent executes task
    ↓
Proof written to ψ/memory/resonance/
    ↓
oracle proof:last           ← Verify result
```

The lanes session maps to executor lanes defined in `configs/lane-cards/`.

## Architecture

- `bin/oracle` — Main CLI script with all commands
- `scripts/oracle-session.sh` — tmux session launcher (4-window)
- `scripts/oracle-fleet.sh` — Fleet orchestration (3×2)
- `scripts/launch-lanes.sh` — 5-lane multi-agent (advanced)
- `configs/tmux.conf` — Statusline + keybindings
- `configs/pane-registry.json` — Agent pane mapping

For deeper integration, see:
- `skills/executor-lane-router/SKILL.md` — Routing logic
- `skills/forge-omega-orchestration/SKILL.md` — Full flow
- `docs/phase-1-router/` — Decision tables
