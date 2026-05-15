#!/usr/bin/env bash
# agent-broadcast.sh — Broadcast a message from one agent to ALL other agents.
# Usage: bash scripts/agent-broadcast.sh <from> <"message"> [type]
# Types: status | alert | task | consult (default: status)
#
# Writes to ψ/inbox/<agent>/ for every agent except sender.
# BoB always gets the broadcast (as coordinator).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX_ROOT="$REPO_ROOT/ψ/inbox"
SESSION="oracle-fleet"
ALL_AGENTS="tham core bob hermes housekeeper"

FROM="${1:-}"
MSG="${2:-}"
TYPE="${3:-status}"
TS="$(date -u +%Y-%m-%dT%H:%M:%S)"
DATE_SLUG="$(date -u +%Y-%m-%dT%H-%M-%S)"

if [[ -z "$FROM" || -z "$MSG" ]]; then
  echo "Usage: bash scripts/agent-broadcast.sh <from> <message> [type]"
  echo "  type: status | alert | task | consult  (default: status)"
  exit 1
fi

echo "[$TS] BROADCAST from $FROM (type: $TYPE)"
echo "  Message: ${MSG:0:100}"
echo ""

TARGETS=()
for agent in $ALL_AGENTS; do
  [[ "$agent" == "$FROM" ]] && continue
  TARGETS+=("$agent")
done

for target in "${TARGETS[@]}"; do
  dir="$INBOX_ROOT/$target"
  mkdir -p "$dir"
  file="$dir/${DATE_SLUG}_broadcast_from_${FROM}.md"
  cat > "$file" <<EOF
---
from: $FROM
to: ALL
broadcast: true
timestamp: $TS
type: $TYPE
---

$MSG
EOF
  echo "  → ψ/inbox/$target/${DATE_SLUG}_broadcast_from_${FROM}.md"
done

# Relay log
LOG_DIR="$REPO_ROOT/ψ/memory"
mkdir -p "$LOG_DIR"
echo "[$TS] BROADCAST $FROM→ALL ($TYPE): ${MSG:0:80}" >> "$LOG_DIR/agent-relay.log"

# tmux signal all target panes (best-effort)
if tmux has-session -t "$SESSION" 2>/dev/null; then
  ACTIVE_WINDOWS=$(tmux list-windows -t "$SESSION" -F '#W' 2>/dev/null)
  for target in "${TARGETS[@]}"; do
    if echo "$ACTIVE_WINDOWS" | grep -qx "$target"; then
      echo "  → tmux signal: $SESSION:$target"
    fi
  done
else
  echo "  ⚠ session '$SESSION' not running — messages written to inboxes only"
fi

echo ""
echo "Broadcast complete → ${#TARGETS[@]} agents notified."
