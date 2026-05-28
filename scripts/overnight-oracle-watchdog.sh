#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/mnt/d/01 Main Work/Boots/Agentic AI/mission-control"
CONTROL_DIR="$ROOT_DIR/tham-oracle"
SESSION="${SESSION:-tham-overnight}"
PROGRESS_DIR="$CONTROL_DIR/reports/progress"
INBOX="$PROGRESS_DIR/tham-inbox.log"
MAX_AGE="${MAX_AGE:-210}"

agents=(core codex luxi watchdog)
panes=(1 2 3 4)

printf 'THAM watchdog %s\n' "$(date -Iseconds)"
printf 'session=%s\n' "$SESSION"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  printf 'status=SESSION_MISSING\n'
  exit 0
fi

for idx in "${!agents[@]}"; do
  agent="${agents[$idx]}"
  pane="${panes[$idx]}"
  progress="$PROGRESS_DIR/$agent.md"
  target="$SESSION:overnight.$pane"
  status="OK"
  age="NA"
  last_line="no-progress-file"
  nudge="none"

  if [ -f "$progress" ]; then
    now=$(date +%s)
    mtime=$(stat -c %Y "$progress")
    age=$((now - mtime))
    last_line=$(tail -n 1 "$progress" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-220)
    if [ "$age" -gt "$MAX_AGE" ]; then
      status="SILENT"
      nudge="sent"
      tmux send-keys -t "$target" "โปรดรายงานสถานะตอนนี้: CURRENT / BLOCKER / NEXT ลง $progress และสรุปสั้นใน $INBOX ภายใน 3 นาที" C-m || true
      printf '[%s] THAM NUDGE -> %s age=%ss\n' "$(date -Iseconds)" "$agent" "$age" >> "$INBOX"
    fi
  else
    status="MISSING"
    nudge="sent"
    tmux send-keys -t "$target" "ยังไม่พบ progress file กรุณาสร้าง $progress แล้วรายงาน CURRENT / BLOCKER / NEXT ทันที" C-m || true
    printf '[%s] THAM NUDGE -> %s missing progress file\n' "$(date -Iseconds)" "$agent" >> "$INBOX"
  fi

  pane_tail=$(tmux capture-pane -pt "$target" | tail -n 2 | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-180)
  printf '%s | status=%s | age=%s | nudge=%s | progress=%s | pane=%s\n' "$agent" "$status" "$age" "$nudge" "$last_line" "$pane_tail"
done
