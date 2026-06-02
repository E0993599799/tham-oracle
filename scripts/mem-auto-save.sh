#!/usr/bin/env bash
# Auto-save memory: commit brain/ and ψ/ silently.
# Called by cron every 5 min + Claude Code Stop hook.
# NO interactive prompts. NO popup. NO foreground window.

REPO="/route/mission-control/tham-oracle"
LOG="$REPO/brain/memory/auto-save.log"
LOCK="$REPO/brain/memory/.auto-save.lock"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Lock: prevent concurrent runs
if [ -f "$LOCK" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
  if [ "$AGE" -lt 120 ]; then
    exit 0  # another run is in progress
  fi
  rm -f "$LOCK"  # stale lock
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

cd "$REPO" || exit 1

# Check for changes in memory areas only
DIRTY=$(git status --porcelain brain/ ψ/ 2>/dev/null)
if [ -z "$DIRTY" ]; then
  exit 0  # nothing to save
fi

# Stage memory files
git add brain/ ψ/ 2>/dev/null

# Commit silently
GIT_AUTHOR_NAME="tham-oracle" \
GIT_AUTHOR_EMAIL="tham@oracle.local" \
GIT_COMMITTER_NAME="tham-oracle" \
GIT_COMMITTER_EMAIL="tham@oracle.local" \
git commit \
  --no-verify \
  -m "auto: memory snapshot ${TIMESTAMP}" \
  >> "$LOG" 2>&1

STATUS=$?
if [ $STATUS -eq 0 ]; then
  # Push in background — non-blocking, no window
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  git push origin "$BRANCH" >> "$LOG" 2>&1 &
  echo "[${TIMESTAMP}] SAVED + pushing ${BRANCH} (bg)" >> "$LOG"
else
  echo "[${TIMESTAMP}] WARN: commit exit ${STATUS}" >> "$LOG"
fi

# Rotate log if > 200 lines
LOG_LINES=$(wc -l < "$LOG" 2>/dev/null || echo 0)
if [ "$LOG_LINES" -gt 200 ]; then
  tail -100 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi
