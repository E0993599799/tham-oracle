#!/usr/bin/env bash
# housekeeper-run.sh — Full maintenance cycle for Forge/Omega environment.
# Safe: archives only, never deletes, never commits.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PSI="$REPO_ROOT/ψ"
LOG="$PSI/memory/housekeeper.log"
TS="$(date -u +%Y-%m-%dT%H:%M:%S)"
RELAY_SCRIPT="$REPO_ROOT/scripts/agent-relay.sh"

mkdir -p "$PSI/memory" "$PSI/archive"

log() { echo "[$TS] $*" | tee -a "$LOG"; }

echo "═══════════════════════════════════════"
echo "  Housekeeper — maintenance cycle"
echo "  $TS"
echo "═══════════════════════════════════════"

REPORT=""

# ── 1. Inbox scan ────────────────────────────────────────────────────
log "=== INBOX SCAN ==="
for agent in tham core bob hermes housekeeper; do
  INBOX="$PSI/inbox/$agent"
  [ -d "$INBOX" ] || continue
  UNREAD=$(find "$INBOX" -maxdepth 1 -name "*.md" ! -name "_*" 2>/dev/null | wc -l)
  OLD=$(find "$INBOX" -maxdepth 1 -name "*.md" ! -name "_*" -mtime +7 2>/dev/null | wc -l)
  log "  $agent: $UNREAD unread, $OLD older than 7 days"
  if [ "$OLD" -gt 0 ]; then
    ARCH="$PSI/archive/inbox-$agent-$(date -u +%Y%m%d)"
    mkdir -p "$ARCH"
    find "$INBOX" -maxdepth 1 -name "*.md" ! -name "_*" -mtime +7 -exec mv {} "$ARCH/" \;
    log "  → archived $OLD old messages to $ARCH"
    REPORT="${REPORT}\n  [$agent] archived $OLD old messages"
  fi
  if [ "$UNREAD" -gt 10 ]; then
    log "  ⚠ $agent inbox backlog: $UNREAD unread"
    REPORT="${REPORT}\n  ⚠ [$agent] inbox backlog: $UNREAD unread"
  fi
done

# ── 2. Relay log rotation ─────────────────────────────────────────────
log "=== RELAY LOG ==="
RELAY_LOG="$PSI/memory/agent-relay.log"
if [ -f "$RELAY_LOG" ]; then
  LINES=$(wc -l < "$RELAY_LOG")
  log "  relay log: $LINES lines"
  if [ "$LINES" -gt 1000 ]; then
    ARCH_LOG="$PSI/archive/agent-relay-$(date -u +%Y%m%d-%H%M).log"
    cp "$RELAY_LOG" "$ARCH_LOG"
    echo "" > "$RELAY_LOG"
    log "  → rotated relay log → $ARCH_LOG"
    REPORT="${REPORT}\n  relay log rotated ($LINES lines archived)"
  fi
else
  log "  relay log: empty"
fi

# ── 3. active → archive ───────────────────────────────────────────────
log "=== ACTIVE ITEMS ==="
ACTIVE_DIR="$PSI/active"
if [ -d "$ACTIVE_DIR" ]; then
  DONE=$(find "$ACTIVE_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | xargs grep -l "status: done\|STATUS: DONE" 2>/dev/null | wc -l || echo 0)
  if [ "$DONE" -gt 0 ]; then
    ARCH_ACTIVE="$PSI/archive/active-done-$(date -u +%Y%m%d)"
    mkdir -p "$ARCH_ACTIVE"
    find "$ACTIVE_DIR" -maxdepth 1 -name "*.md" | xargs grep -l "status: done\|STATUS: DONE" 2>/dev/null | while read -r f; do
      mv "$f" "$ARCH_ACTIVE/"
    done
    log "  → archived $DONE done items to $ARCH_ACTIVE"
    REPORT="${REPORT}\n  archived $DONE completed active items"
  else
    log "  active: no done items to archive"
  fi
fi

# ── 4. Health check ───────────────────────────────────────────────────
log "=== HEALTH CHECK ==="
check_port() {
  local name="$1" port="$2"
  if curl -s --max-time 2 "http://127.0.0.1:$port" >/dev/null 2>&1 || \
     curl -s --max-time 2 "http://127.0.0.1:$port/health" >/dev/null 2>&1 || \
     curl -s --max-time 2 "http://127.0.0.1:$port/v1/models" >/dev/null 2>&1; then
    log "  ✓ $name (port $port): alive"
  else
    log "  ✗ $name (port $port): not responding"
    REPORT="${REPORT}\n  ✗ $name (port $port) down"
  fi
}
check_port "oracle-v2/tham" 47778
check_port "9router/hermes" 20128
check_port "oracle-studio" 3000

# ── 5. Git uncommitted reminder ───────────────────────────────────────
log "=== GIT STATUS ==="
cd "$REPO_ROOT"
DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
if [ "$DIRTY" -gt 0 ]; then
  log "  ⚠ $DIRTY uncommitted changes in tham-oracle — remember to /rrr + commit"
  REPORT="${REPORT}\n  ⚠ $DIRTY uncommitted changes — /rrr needed"
else
  log "  ✓ git clean"
fi

# ── 6. Report to BoB ─────────────────────────────────────────────────
log "=== REPORTING TO BOB ==="
SUMMARY="Housekeeper cycle complete @ $TS${REPORT:-\n  All clean.}"
if [ -x "$RELAY_SCRIPT" ]; then
  bash "$RELAY_SCRIPT" housekeeper bob "$SUMMARY" status 2>/dev/null || true
fi

echo ""
echo "═══════════════════════════════════════"
echo "  Housekeeper done. Log: $LOG"
echo "═══════════════════════════════════════"
