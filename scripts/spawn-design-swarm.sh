#!/usr/bin/env bash
# spawn-design-swarm.sh — Spawn 1 tmux window with 2 agents:
#   Left : UX/UI Design Agent (claude + uxui-prompt)
#   Right: BugFix Agent Codex-style (claude + bugfix-prompt)
#
# Both agents are forced to research before starting work.
# Window added to oracle-fleet session if running, else creates standalone.
#
# Usage:
#   bash scripts/spawn-design-swarm.sh [project-dir]
#
# project-dir defaults to current working directory.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPT_DIR="$REPO_ROOT/configs/agent-prompts"
UXUI_PROMPT="$PROMPT_DIR/uxui-prompt.md"
BUGFIX_PROMPT="$PROMPT_DIR/bugfix-prompt.md"
PROJECT_DIR="${1:-$(pwd)}"
SESSION="oracle-fleet"
WINDOW="design"

# ── Validate ────────────────────────────────────────────────────────
if [ ! -f "$UXUI_PROMPT" ]; then
  echo "ERROR: uxui-prompt.md not found at $UXUI_PROMPT"
  exit 1
fi
if [ ! -f "$BUGFIX_PROMPT" ]; then
  echo "ERROR: bugfix-prompt.md not found at $BUGFIX_PROMPT"
  exit 1
fi

# ── Session target ──────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  TARGET_SESSION="$SESSION"
else
  # Standalone: create a new session named "design-swarm"
  TARGET_SESSION="design-swarm"
  tmux new-session -d -s "$TARGET_SESSION" -n "$WINDOW"
  echo "  Created standalone session: $TARGET_SESSION"
fi

# ── Create window ───────────────────────────────────────────────────
if tmux list-windows -t "$TARGET_SESSION" -F '#W' 2>/dev/null | grep -qx "$WINDOW"; then
  echo "  ⚠ Window '$WINDOW' already exists in $TARGET_SESSION"
  tmux select-window -t "$TARGET_SESSION:$WINDOW"
else
  tmux new-window -t "$TARGET_SESSION" -n "$WINDOW"
fi

# ── Left pane: UX/UI Agent ──────────────────────────────────────────
tmux send-keys -t "$TARGET_SESSION:$WINDOW" "cd $PROJECT_DIR && clear" Enter
tmux send-keys -t "$TARGET_SESSION:$WINDOW" \
  "printf '\033[1;36m╔═══════════════════════════════════╗\n║  UX/UI Design Agent               ║\n║  MUST research before working     ║\n╚═══════════════════════════════════╝\033[0m\n'" Enter
sleep 0.3
tmux send-keys -t "$TARGET_SESSION:$WINDOW" \
  "claude --name 'UX-UI' --append-system-prompt-file $UXUI_PROMPT" Enter

# ── Right pane: BugFix Agent ────────────────────────────────────────
tmux split-window -h -t "$TARGET_SESSION:$WINDOW"
tmux send-keys -t "$TARGET_SESSION:$WINDOW.right" "cd $PROJECT_DIR && clear" Enter
tmux send-keys -t "$TARGET_SESSION:$WINDOW.right" \
  "printf '\033[1;33m╔═══════════════════════════════════╗\n║  BugFix Agent (Codex-Style)       ║\n║  MUST research before working     ║\n╚═══════════════════════════════════╝\033[0m\n'" Enter
sleep 0.3
tmux send-keys -t "$TARGET_SESSION:$WINDOW.right" \
  "claude --name 'BugFix' --append-system-prompt-file $BUGFIX_PROMPT" Enter

# ── Apply equal tiled layout ────────────────────────────────────────
tmux select-layout -t "$TARGET_SESSION:$WINDOW" even-horizontal

# ── Focus left (UX/UI) ──────────────────────────────────────────────
tmux select-pane -t "$TARGET_SESSION:$WINDOW.left"
tmux select-window -t "$TARGET_SESSION:$WINDOW"

echo ""
echo "Design swarm spawned in '$TARGET_SESSION:$WINDOW'"
echo ""
echo "  LEFT  │ UX/UI Design Agent"
echo "        │ Prompt: configs/agent-prompts/uxui-prompt.md"
echo "        │ RESEARCH REQUIRED before any design work"
echo ""
echo "  RIGHT │ BugFix Agent (Codex-Style)"
echo "        │ Prompt: configs/agent-prompts/bugfix-prompt.md"
echo "        │ RESEARCH REQUIRED before any fix"
echo ""
echo "Attach : tmux attach -t $TARGET_SESSION"
echo "Jump   : Ctrl+b ←→  (switch pane)"
echo ""
echo "Both agents will enforce research-first via their system prompts."
