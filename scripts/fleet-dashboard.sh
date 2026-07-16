#!/bin/bash
# Fleet Status Dashboard
# Human-friendly summary of broadcast events

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOG_FILE="$REPO_ROOT/ψ/fleet/BROADCAST-LOG.ndjson"

if [ ! -f "$LOG_FILE" ]; then
  echo "❌ Broadcast log not found: $LOG_FILE"
  exit 1
fi

echo "╭─────────────────────────────────────────────────╮"
echo "│ ⚡ Fleet Status Dashboard                       │"
echo "│ $(date '+%Y-%m-%d %H:%M:%S %Z')                │"
echo "╰─────────────────────────────────────────────────╯"
echo ""

# Count events by type
echo "📊 Events by Type:"
if command -v jq &>/dev/null; then
  jq -r '.event_type' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | awk '{printf "   %-30s %3d\n", $2, $1}' || echo "   (no events yet)"
else
  grep -o '"event_type":"[^"]*' "$LOG_FILE" 2>/dev/null | cut -d'"' -f4 | sort | uniq -c | sort -rn | awk '{printf "   %-30s %3d\n", $2, $1}' || echo "   (no events yet)"
fi
echo ""

# Active oracles
echo "🟢 Active Oracles:"
if command -v jq &>/dev/null; then
  jq -r '.oracle' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | awk '{printf "   %s (%d events)\n", $2, $1}' || echo "   (no events yet)"
else
  grep -o '"oracle":"[^"]*' "$LOG_FILE" 2>/dev/null | cut -d'"' -f4 | sort | uniq -c | sort -rn | awk '{printf "   %s (%d events)\n", $2, $1}' || echo "   (no events yet)"
fi
echo ""

# Projects touched
echo "📦 Projects:"
if command -v jq &>/dev/null; then
  jq -r 'select(.project != null) | .project' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | awk '{printf "   %s (%d events)\n", $2, $1}' || echo "   (no project-specific events yet)"
else
  grep -o '"project":"[^"]*' "$LOG_FILE" 2>/dev/null | cut -d'"' -f4 | grep -v '^$' | sort | uniq -c | sort -rn | awk '{printf "   %s (%d events)\n", $2, $1}' || echo "   (no project-specific events yet)"
fi
echo ""

# Blockers (if any)
echo "🔴 Critical Issues:"
if command -v jq &>/dev/null; then
  jq -r 'select(.severity == "critical" or .severity == "error") | "\(.oracle): \(.message)"' "$LOG_FILE" 2>/dev/null | while read -r line; do
    echo "   ⚠️  $line"
  done
  [ -z "$(jq -r 'select(.severity == "critical" or .severity == "error")' "$LOG_FILE" 2>/dev/null)" ] && echo "   ✓ None (all clear)"
else
  grep '"severity":"critical\|"severity":"error' "$LOG_FILE" 2>/dev/null | while read -r line; do
    oracle=$(echo "$line" | grep -o '"oracle":"[^"]*' | cut -d'"' -f4)
    message=$(echo "$line" | grep -o '"message":"[^"]*' | cut -d'"' -f4)
    echo "   ⚠️  $oracle: $message"
  done
  [ -z "$(grep '"severity":"critical\|"severity":"error' "$LOG_FILE" 2>/dev/null)" ] && echo "   ✓ None (all clear)"
fi
echo ""

# Recent events (last 5)
echo "📡 Recent Events:"
if command -v jq &>/dev/null; then
  jq -r '[reverse | .[0:5] | .[] | "\(.timestamp | .[0:16]) [\(.oracle)] \(.message)"] | .[]' "$LOG_FILE" 2>/dev/null | while read -r line; do
    echo "   $line"
  done
else
  tail -5 "$LOG_FILE" 2>/dev/null | while read -r line; do
    timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*' | cut -d'"' -f4 | cut -c1-16)
    oracle=$(echo "$line" | grep -o '"oracle":"[^"]*' | cut -d'"' -f4)
    message=$(echo "$line" | grep -o '"message":"[^"]*' | cut -d'"' -f4)
    echo "   $timestamp [$oracle] $message"
  done
fi
echo ""

# Total event count
TOTAL=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total Events: $TOTAL"
