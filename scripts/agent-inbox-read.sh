#!/usr/bin/env bash
# agent-inbox-read.sh — Read an agent's unread inbox messages.
# Usage: bash scripts/agent-inbox-read.sh [agent]
# If no agent given, reads THAM inbox by default.
# Mark as read by prefixing filename with '_'.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX_ROOT="$REPO_ROOT/ψ/inbox"
AGENT="${1:-tham}"
INBOX_DIR="$INBOX_ROOT/$AGENT"

if [[ ! -d "$INBOX_DIR" ]]; then
  echo "No inbox found for agent: $AGENT"
  echo "Valid agents: tham core bob hermes"
  exit 1
fi

# Unread = files NOT prefixed with '_' and NOT .gitkeep
UNREAD=$(find "$INBOX_DIR" -maxdepth 1 -name "*.md" ! -name "_*" 2>/dev/null | sort)
COUNT=$(echo "$UNREAD" | grep -c "\.md" 2>/dev/null || echo 0)

if [[ -z "$UNREAD" || "$COUNT" -eq 0 ]]; then
  echo "[$AGENT inbox] No unread messages."
  exit 0
fi

echo "[$AGENT inbox] $COUNT unread message(s)"
echo "══════════════════════════════════════"

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  echo ""
  echo "▶ $(basename "$file")"
  echo "──────────────────────────────────────"
  cat "$file"
  echo ""
  echo "──────────────────────────────────────"
  read -r -p "Mark as read? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    dir=$(dirname "$file")
    base=$(basename "$file")
    mv "$file" "$dir/_${base}"
    echo "  ✓ marked read"
  fi
done <<< "$UNREAD"

echo ""
echo "Done. ($AGENT inbox)"
