#!/usr/bin/env bash
# Live tmux show layout for Tham Oracle
# Layout goal:
#   - Main page: 5 left panes + 2 right panes
#   - Top-left pane: THAM ORACLE
#   - Extra page(s): remaining active agents
#
# Usage:
#   bash scripts/spawn-live-5-2-show.sh

set -euo pipefail

SESSION="${THAM_ORACLE_SHOW_SESSION:-tham-oracle-live}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

windows_host_ip() {
  awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null || true
}

ROUTER_HOST="${ROUTER_HOST:-$(windows_host_ip)}"
ROUTER_HOST="${ROUTER_HOST:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${ROUTER_HOST}:20128/v1}"

start_tham() {
  cat <<EOF
cd '$REPO_DIR'
[ -f .env.tham ] && source .env.tham || true
printf '%s\n' '=== THAM ORACLE ==='
printf '%s\n' 'top-left / governor / RTK context engine'
if command -v claude >/dev/null 2>&1; then
  exec claude --model sonnet
fi
printf '%s\n' 'Claude command missing; staying in shell.'
exec bash
EOF
}

start_codex() {
  local label="$1"
  cat <<EOF
cd "$REPO_DIR"
export OPENAI_BASE_URL='$ROUTER_BASE_URL'
export CODEX_MODEL='${CODEX_MODEL:-cx/gpt-5.5}'
printf '%s\n' '=== $label ==='
printf '%s\n' 'Codex lane: live terminal surface'
if command -v codex >/dev/null 2>&1; then
  exec codex
fi
printf '%s\n' 'Codex command missing; staying in shell.'
exec bash
EOF
}

start_gemini() {
  local label="$1"
  cat <<EOF
cd '$REPO_DIR'
export OPENAI_BASE_URL='$ROUTER_BASE_URL'
export GEMINI_MODEL='${GEMINI_MODEL:-gemini/gemini-3.1-pro-preview}'
printf '%s\n' '=== $label ==='
printf '%s\n' 'Gemini lane: live terminal surface'
if command -v gemini >/dev/null 2>&1; then
  gemini -p "You are $label. Respond exactly with RESULT / PROOF / RISKS / MEMORY_DELTA. Mention that 9router is reachable via ${ROUTER_HOST}:20128 and whether you can proceed." --output-format text
fi
printf '%s\n' 'Gemini status run complete; staying in shell.'
exec bash
EOF
}

spawn_pane() {
  local target="$1"
  local script="$2"
  tmux send-keys -t "$target" "bash -lc $(printf '%q' "$script")" C-m
}

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n main -x 220 -y 60

# Pane layout:
# left column (5 panes): THAM, CORE, CODEX, BOB, HERMES
# right column (2 panes): HOUSEKEEPER, WATCHDOG

# Start top-left THAM, create the right column root first, then build the left stack
spawn_pane "$SESSION:main.0" "$(start_tham)"
right_root="$(tmux split-window -h -t "$SESSION:main.0" -P -F '#{pane_id}')"
left_targets=()
current_target="$SESSION:main.0"
for _ in 1 2 3 4; do
  new_target="$(tmux split-window -v -t "$current_target" -P -F '#{pane_id}')"
  left_targets+=("$new_target")
  current_target="$new_target"
done
right_child="$(tmux split-window -v -t "$right_root" -P -F '#{pane_id}')"

# Populate left column panes
spawn_pane "${left_targets[0]}" "$(start_codex 'CORE')"
spawn_pane "${left_targets[1]}" "$(start_codex 'CODEX')"
spawn_pane "${left_targets[2]}" "$(start_codex 'BOB')"
spawn_pane "${left_targets[3]}" "$(start_codex 'HERMES')"

# Populate right column panes
spawn_pane "$right_root" "$(start_codex 'HOUSEKEEPER')"
spawn_pane "$right_child" "$(start_gemini 'WATCHDOG')"

# Normalize main page layout as two vertical stacks
# (left has 5 panes, right has 2 panes)
tmux select-pane -t "$SESSION:main.0" >/dev/null
tmux setw -t "$SESSION:main" pane-border-status top >/dev/null

tmux new-window -d -t "$SESSION" -n extra
spawn_pane "$SESSION:extra.0" "$(start_gemini 'LUXI')"
tmux split-window -h -t "$SESSION:extra.0" >/dev/null
spawn_pane "$SESSION:extra.1" "$(start_gemini 'LENS')"
tmux select-layout -t "$SESSION:extra" even-horizontal >/dev/null

# Pane titles for easier live reading

tmux select-pane -t "$SESSION:main.0" -T "THAM ORACLE"
tmux select-pane -t "$SESSION:main.1" -T "CORE"
tmux select-pane -t "$SESSION:main.2" -T "CODEX"
tmux select-pane -t "$SESSION:main.3" -T "BOB"
tmux select-pane -t "$SESSION:main.4" -T "HERMES"
tmux select-pane -t "$SESSION:main.5" -T "HOUSEKEEPER"
tmux select-pane -t "$SESSION:main.6" -T "WATCHDOG"
tmux select-pane -t "$SESSION:extra.0" -T "LUXI"
tmux select-pane -t "$SESSION:extra.1" -T "LENS"

tmux rename-window -t "$SESSION:main" "main"
tmux rename-window -t "$SESSION:extra" "extra"
# Keep our manual labels visible instead of letting apps rename panes/windows.
tmux setw -t "$SESSION:main" allow-rename off >/dev/null
tmux setw -t "$SESSION:extra" allow-rename off >/dev/null
tmux setw -t "$SESSION:main" automatic-rename off >/dev/null
tmux setw -t "$SESSION:extra" automatic-rename off >/dev/null
tmux select-window -t "$SESSION:main"
tmux select-pane -t "$SESSION:main.0"

echo "SESSION=$SESSION"
echo "Main page: 5 left panes + 2 right panes (top-left = THAM ORACLE)"
echo "Extra page: LUXI | LENS"
echo "Attach: tmux attach -t $SESSION"
echo "Switch pages: Ctrl+b n / Ctrl+b p"
echo ""
tmux list-windows -t "$SESSION" -F '#{window_index}:#{window_name} panes=#{window_panes} layout=#{window_layout}'
