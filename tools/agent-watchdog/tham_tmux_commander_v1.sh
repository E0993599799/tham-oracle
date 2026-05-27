#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/route/mission-control/tham-oracle}" 
LOGDIR="$ROOT/tools/logs/agent-watchdog"
STATE="$LOGDIR/state.tsv"
RUNLOG="$LOGDIR/tham_tmux_commander_run.log"
DASH="$LOGDIR/tmux-agent-dashboard.txt"
mkdir -p "$LOGDIR"

now(){ date '+%Y-%m-%d %H:%M:%S %z'; }

PROMPT='THAM COMMAND: You are under Tham orchestration. Every 3 minutes print exactly one PROGRESS_REPORT with fields: agent_name, tmux_pane, current_task, last_action, next_action, blockers, eta, timestamp. If idle, ask Tham for next task. Continue work autonomously. Do not stay silent.'

WAKE='THAM WAKE: No fresh PROGRESS_REPORT detected. Resume work now. Print PROGRESS_REPORT immediately, then continue the assigned task. If blocked, state blocker and next safe action.'

echo "[$(now)] START tham tmux commander" | tee -a "$RUNLOG"

if ! command -v tmux >/dev/null 2>&1; then
  echo "RESULT=FAIL reason=tmux_not_found" | tee -a "$RUNLOG"
  exit 1
fi

if ! tmux ls >/dev/null 2>&1; then
  echo "RESULT=FAIL reason=no_tmux_server" | tee -a "$RUNLOG"
  exit 1
fi

tmux set -g mouse on >/dev/null 2>&1 || true
tmux set -g pane-border-status top >/dev/null 2>&1 || true
tmux set -g pane-border-format '#{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_title}' >/dev/null 2>&1 || true
tmux set -g status-right '#(date "+%H:%M:%S") | Tham Watch' >/dev/null 2>&1 || true

# Send first command to likely agent panes only; avoid pure monitor/watch panes.
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}|#{pane_id}|#{pane_current_command}|#{pane_title}' |
while IFS='|' read -r target paneid cmd title; do
  case "$cmd:$title:$target" in
    *watch*|*less*|*vim*|*nano*|*top*|*htop*|*tham-watch*|*agent-watchdog*) continue ;;
  esac
  tmux send-keys -t "$target" "$PROMPT" C-m || true
  echo "[$(now)] COMMAND_SENT target=$target pane=$paneid cmd=$cmd title=$title" >> "$RUNLOG"
done

# Create visible dashboard window.
SESSION="$(tmux display-message -p '#S' 2>/dev/null || tmux ls | head -n1 | cut -d: -f1)"
if ! tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -qx 'tham-watch'; then
  tmux new-window -t "$SESSION" -n tham-watch "watch -n 5 'printf \"THAM TMUX ACTIVE PANES\\n\\n\"; tmux list-panes -a -F \"#{session_name}:#{window_index}.#{pane_index} | #{pane_id} | active=#{pane_active} | cmd=#{pane_current_command} | title=#{pane_title}\"; printf \"\\nLATEST REPORTS\\n\\n\"; tail -n 40 \"$RUNLOG\" 2>/dev/null'"
fi

# Background watchdog loop inside tmux window.
if ! tmux list-windows -a -F '#{window_name}' | grep -qx 'tham-guard'; then
  tmux new-window -d -t "$SESSION" -n tham-guard "bash -lc '
    ROOT=\"$ROOT\"
    LOGDIR=\"$LOGDIR\"
    RUNLOG=\"$RUNLOG\"
    STATE=\"$STATE\"
    WAKE=\"$WAKE\"
    now(){ date \"+%Y-%m-%d %H:%M:%S %z\"; }
    mkdir -p \"\$LOGDIR\"
    touch \"\$STATE\"
    while true; do
      : > \"\$LOGDIR/current.tsv\"
      tmux list-panes -a -F \"#{session_name}:#{window_index}.#{pane_index}|#{pane_id}|#{pane_current_command}|#{pane_title}\" |
      while IFS=\"|\" read -r target paneid cmd title; do
        case \"\$cmd:\$title:\$target\" in
          *watch*|*less*|*vim*|*nano*|*top*|*htop*|*tham-watch*|*tham-guard*|*agent-watchdog*) continue ;;
        esac
        CAP=\"\$(tmux capture-pane -p -t \"\$target\" -S -250 2>/dev/null || true)\"
        HASH=\"\$(printf \"%s\" \"\$CAP\" | sha256sum | awk \"{print \\\$1}\")\"
        HAS_REPORT=\"\$(printf \"%s\" \"\$CAP\" | grep -c \"PROGRESS_REPORT\" || true)\"
        OLD=\"\$(grep -F \"\$paneid	\" \"\$STATE\" 2>/dev/null | tail -n1 || true)\"
        OLDHASH=\"\$(printf \"%s\" \"\$OLD\" | awk -F \"	\" \"{print \\\$2}\")\"
        if [ \"\$HAS_REPORT\" = \"0\" ] || [ \"\$HASH\" = \"\$OLDHASH\" ]; then
          tmux send-keys -t \"\$target\" \"\$WAKE\" C-m || true
          echo \"[\$(now)] WAKE_SENT target=\$target pane=\$paneid cmd=\$cmd reason=no_fresh_progress_report\" >> \"\$RUNLOG\"
        else
          echo \"[\$(now)] OK_REPORT target=\$target pane=\$paneid cmd=\$cmd\" >> \"\$RUNLOG\"
        fi
        printf \"%s\t%s\t%s\t%s\n\" \"\$paneid\" \"\$HASH\" \"\$target\" \"\$cmd\" >> \"\$LOGDIR/current.tsv\"
      done
      mv \"\$LOGDIR/current.tsv\" \"\$STATE\"
      sleep 180
    done
  '"
fi

tmux select-window -t "$SESSION:tham-watch" || true

{
  echo "RESULT=OK"
  echo "ACTION=THAM_COMMAND_AGENT_PROGRESS_WATCHDOG"
  echo "STATUS=ACTIVE"
  echo "LOG=$RUNLOG"
  echo "DASHBOARD_WINDOW=tham-watch"
  echo "GUARD_WINDOW=tham-guard"
  echo "NEXT=tmux attach -t $SESSION"
  echo "DONE!"
} | tee -a "$RUNLOG"

printf "RESULT=OK ACTION=THAM_COMMAND_AGENT_PROGRESS_WATCHDOG STATUS=ACTIVE\nLOG=%s\nNEXT=tmux attach -t %s\nDONE!\n" "$RUNLOG" "$SESSION" | clip.exe 2>/dev/null || true
