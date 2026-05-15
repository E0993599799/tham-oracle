#!/usr/bin/env bash
# agent-relay.sh — Send a message from one agent to another.
# Usage: bash scripts/agent-relay.sh <from> <to> <"message"> [type]
# Types: task | consult | status | reply (default: consult)
#
# Writes to ψ/inbox/<to>/ and cc's BoB automatically.
# Optionally pastes into target tmux pane if oracle-fleet session is running.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX_ROOT="$REPO_ROOT/ψ/inbox"
SESSION="oracle-fleet"
VALID_AGENTS="tham core bob hermes"

FROM="${1:-}"
TO="${2:-}"
MSG="${3:-}"
TYPE="${4:-consult}"
TS="$(date -u +%Y-%m-%dT%H:%M:%S)"
DATE_SLUG="$(date -u +%Y-%m-%dT%H-%M-%S)"

# --- Validate ---
if [[ -z "$FROM" || -z "$TO" || -z "$MSG" ]]; then
  echo "Usage: bash scripts/agent-relay.sh <from> <to> <message> [type]"
  echo "  type: task | consult | status | reply  (default: consult)"
  echo "  agents: tham core bob hermes"
  exit 1
fi

for a in $FROM $TO; do
  if ! echo "$VALID_AGENTS" | grep -qw "$a"; then
    echo "ERROR: Unknown agent '$a'. Valid: $VALID_AGENTS"
    exit 1
  fi
done

if [[ "$FROM" == "$TO" ]]; then
  echo "ERROR: cannot relay to self"
  exit 1
fi

# --- Write message to recipient inbox ---
write_msg() {
  local target="$1" cc_flag="$2"
  local dir="$INBOX_ROOT/$target"
  mkdir -p "$dir"
  local file="$dir/${DATE_SLUG}_from_${FROM}.md"
  cat > "$file" <<EOF
---
from: $FROM
to: $target
cc: $([ "$cc_flag" = "cc" ] && echo "bob (cc)" || echo "$TO")
timestamp: $TS
type: $TYPE
---

$MSG
EOF
  echo "  → wrote: ψ/inbox/$target/${DATE_SLUG}_from_${FROM}.md"
}

echo "[$TS] relay: $FROM → $TO  (type: $TYPE)"
write_msg "$TO" ""

# cc bob on every relay (unless bob is sender or recipient)
if [[ "$FROM" != "bob" && "$TO" != "bob" ]]; then
  write_msg "bob" "cc"
fi

# --- Relay log ---
LOG_DIR="$REPO_ROOT/ψ/memory"
mkdir -p "$LOG_DIR"
echo "[$TS] $FROM→$TO ($TYPE): ${MSG:0:80}" >> "$LOG_DIR/agent-relay.log"

# --- tmux paste (best-effort) ---
if tmux has-session -t "$SESSION" 2>/dev/null; then
  if tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null | grep -qx "$TO"; then
    NOTICE="[BoB relay] Message from $FROM — check ψ/inbox/$TO/"
    tmux send-keys -t "$SESSION:$TO" "" ""  # focus pane gently
    echo "  → tmux signal sent to pane: $SESSION:$TO"
  else
    echo "  ⚠ pane '$TO' not found in $SESSION — message written to inbox only"
  fi
else
  echo "  ⚠ session '$SESSION' not running — message written to inbox only"
fi

echo "Done."
