#!/usr/bin/env bash
# Print Memory Gate READ summary — run at session start.

BRAIN="/root/repos/tham-oracle/brain"
DATE=$(date '+%Y-%m-%d %H:%M')

echo "╔══════════════════════════════════════════╗"
echo "║         MEMORY GATE READ — ธาม           ║"
echo "╚══════════════════════════════════════════╝"
echo "  $DATE"
echo ""

echo "── ACTIVE INDEX ────────────────────────────"
if [ -f "$BRAIN/memory/ACTIVE_INDEX.md" ]; then
  # Print non-empty, non-header lines
  grep -v "^#\|^---\|^$\|^\-\-" "$BRAIN/memory/ACTIVE_INDEX.md" | head -30
else
  echo "  (not found)"
fi

echo ""
echo "── LAST 3 DECISIONS ────────────────────────"
if [ -f "$BRAIN/decisions/log.md" ]; then
  grep "^## " "$BRAIN/decisions/log.md" | tail -3
else
  echo "  (not found)"
fi

echo ""
echo "── LAST LESSON ─────────────────────────────"
if [ -f "$BRAIN/reflections/lessons.md" ]; then
  grep "^## " "$BRAIN/reflections/lessons.md" | tail -1
else
  echo "  (not found)"
fi

echo ""
echo "── ACTIVE PROJECTS ─────────────────────────"
if ls "$BRAIN/projects/"*.md 2>/dev/null | head -5; then
  :
else
  echo "  (none)"
fi

echo ""
echo "────────────────────────────────────────────"
echo "  oracle     → open oracle session"
echo "  mem-write  → update memory entry"
echo "  mem-close  → close session + commit proof"
echo "────────────────────────────────────────────"
