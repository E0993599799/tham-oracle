#!/usr/bin/env bash
# Live tmux show layout for Tham Oracle
# Layout goal:
#   - Main page: 5 panes total
#   - Left column: 2 panes (top-left = THAM ORACLE)
#   - Right column: 3 panes
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

THAM_RUNTIME="${THAM_RUNTIME:-free}"
THAM_MODEL="${THAM_MODEL:-gemini-2.5-flash}"
CODEX_MODEL="${CODEX_MODEL:-cx/gpt-5.5}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-2.5-flash}"

main_left_roles=("THAM ORACLE" "CORE")
main_right_roles=("CODEX" "BOB" "WATCHDOG")
extra_roles=("HERMES" "HOUSEKEEPER" "LUXI" "LENS")

gemini_lane_script() {
  local label="$1"
  local model="$2"
  cat <<EOF
cd '$REPO_DIR'
export OPENAI_BASE_URL='$ROUTER_BASE_URL'
export GEMINI_MODEL='$model'
printf '%s\n' '=== $label ==='
printf '%s\n' 'Gemini live terminal surface'
printf '%s\n' 'Model: $model'
if command -v gemini >/dev/null 2>&1; then
  exec gemini --model "$model" --approval-mode auto_edit --prompt-interactive "You are $label in the Tham Oracle live tmux surface. Keep working inside this repository and stay concise."
fi
printf '%s\n' 'Gemini command missing; staying in shell.'
exec bash
EOF
}

codex_lane_script() {
  local label="$1"
  local model="$2"
  cat <<EOF
cd '$REPO_DIR'
export OPENAI_BASE_URL='$ROUTER_BASE_URL'
export CODEX_MODEL='$model'
printf '%s\n' '=== $label ==='
printf '%s\n' 'Codex live terminal surface'
printf '%s\n' 'Model: $model'
if command -v codex >/dev/null 2>&1; then
  exec codex -c model=\"$model\" "You are $label in the Tham Oracle live tmux surface. Keep working inside this repository and stay concise."
fi
printf '%s\n' 'Codex command missing; staying in shell.'
exec bash
EOF
}

tham_script() {
  case "$THAM_RUNTIME" in
    codex)
      codex_lane_script "THAM ORACLE" "$CODEX_MODEL"
      ;;
    gemini|free)
      gemini_lane_script "THAM ORACLE" "$THAM_MODEL"
      ;;
    *)
      printf '%s\n' "Unsupported THAM_RUNTIME=$THAM_RUNTIME; defaulting to Gemini." >&2
      gemini_lane_script "THAM ORACLE" "$THAM_MODEL"
      ;;
  esac
}

lane_script() {
  local label="$1"
  case "$label" in
    WATCHDOG|LUXI|LENS)
      gemini_lane_script "$label" "$GEMINI_MODEL"
      ;;
    *)
      codex_lane_script "$label" "$CODEX_MODEL"
      ;;
  esac
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

tmux setw -t "$SESSION:main" allow-rename off >/dev/null
tmux setw -t "$SESSION:main" automatic-rename off >/dev/null
tmux setw -t "$SESSION:main" pane-border-status top >/dev/null

# Main page: 2 left panes + 3 right panes
spawn_pane "$SESSION:main.0" "$(tham_script)"
left_bottom="$(tmux split-window -v -t "$SESSION:main.0" -P -F '#{pane_id}')"
right_top="$(tmux split-window -h -t "$SESSION:main.0" -P -F '#{pane_id}')"
right_mid="$(tmux split-window -v -t "$right_top" -P -F '#{pane_id}')"
right_bottom="$(tmux split-window -v -t "$right_mid" -P -F '#{pane_id}')"

spawn_pane "$left_bottom" "$(lane_script 'CORE')"
spawn_pane "$right_top" "$(lane_script 'CODEX')"
spawn_pane "$right_mid" "$(lane_script 'BOB')"
spawn_pane "$right_bottom" "$(lane_script 'WATCHDOG')"

tmux select-pane -t "$SESSION:main.0" -T "THAM ORACLE"
tmux select-pane -t "$left_bottom" -T "CORE"
tmux select-pane -t "$right_top" -T "CODEX"
tmux select-pane -t "$right_mid" -T "BOB"
tmux select-pane -t "$right_bottom" -T "WATCHDOG"

tmux new-window -d -t "$SESSION" -n extra
tmux setw -t "$SESSION:extra" allow-rename off >/dev/null
tmux setw -t "$SESSION:extra" automatic-rename off >/dev/null
tmux setw -t "$SESSION:extra" pane-border-status top >/dev/null

spawn_pane "$SESSION:extra.0" "$(lane_script 'HERMES')"
extra_p1="$(tmux split-window -h -t "$SESSION:extra.0" -P -F '#{pane_id}')"
extra_p2="$(tmux split-window -v -t "$SESSION:extra.0" -P -F '#{pane_id}')"
extra_p3="$(tmux split-window -v -t "$extra_p1" -P -F '#{pane_id}')"

spawn_pane "$extra_p1" "$(lane_script 'HOUSEKEEPER')"
spawn_pane "$extra_p2" "$(lane_script 'LUXI')"
spawn_pane "$extra_p3" "$(lane_script 'LENS')"

tmux select-pane -t "$SESSION:extra.0" -T "HERMES"
tmux select-pane -t "$extra_p1" -T "HOUSEKEEPER"
tmux select-pane -t "$extra_p2" -T "LUXI"
tmux select-pane -t "$extra_p3" -T "LENS"

tmux select-window -t "$SESSION:main"
tmux select-pane -t "$SESSION:main.0"

echo "SESSION=$SESSION"
echo "Main page: 5 panes total = 2 left + 3 right (top-left = THAM ORACLE)"
echo "Main roles: ${main_left_roles[*]} | ${main_right_roles[*]}"
echo "Extra page roles: ${extra_roles[*]}"
echo "THAM runtime: $THAM_RUNTIME"
echo "THAM model: $THAM_MODEL"
echo "Codex model: $CODEX_MODEL"
echo "Gemini model: $GEMINI_MODEL"
echo "Attach: tmux attach -t $SESSION"
echo "Switch pages: Ctrl+b n / Ctrl+b p"
echo ""
tmux list-windows -t "$SESSION" -F '#{window_index}:#{window_name} panes=#{window_panes} layout=#{window_layout}'
tmux list-panes -a -t "$SESSION" -F '#{session_name}:#{window_index}.#{pane_index} title=#{pane_title} cmd=#{pane_current_command} size=#{pane_width}x#{pane_height}'
