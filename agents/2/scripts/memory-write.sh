#!/usr/bin/env bash
# Append a memory entry to the correct brain file.
# Usage: memory-write.sh --type TYPE --body "TEXT"
#   TYPE: baseline | rule | decision | reflection | proof | project
#
# Examples:
#   memory-write.sh --type reflection --body "Learned that X causes Y"
#   memory-write.sh --type decision --body "Use Supabase for all queue storage"

BRAIN="/root/repos/tham-oracle/brain"
DATE=$(date '+%Y-%m-%d')
TYPE=""
BODY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2 ;;
    --body) BODY="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$TYPE" || -z "$BODY" ]]; then
  echo "Usage: memory-write.sh --type TYPE --body \"TEXT\""
  echo "  TYPE: baseline | rule | decision | reflection | proof | project"
  exit 1
fi

case "$TYPE" in
  baseline|rule)
    TARGET="$BRAIN/memory/ACTIVE_INDEX.md"
    ENTRY="
## $DATE — $TYPE
$BODY
"
    echo "$ENTRY" >> "$TARGET"
    # Update last-updated line
    sed -i "s/^Last updated: .*/Last updated: $DATE/" "$TARGET"
    ;;
  decision)
    TARGET="$BRAIN/decisions/log.md"
    ENTRY="
## $DATE — (new)
**Decision**: $BODY
**Why**: (add reason)
**Applies to**: (add scope)
**Revisit when**: (add condition)
"
    echo "$ENTRY" >> "$TARGET"
    ;;
  reflection)
    TARGET="$BRAIN/reflections/lessons.md"
    ENTRY="
## $DATE — (new lesson)
**What happened**: $BODY
**Root cause**: (add cause)
**New rule / pattern**: (add rule)
**Skill to update**: (add skill slug if applicable)
"
    echo "$ENTRY" >> "$TARGET"
    ;;
  proof)
    TARGET="$BRAIN/proofs/$DATE-note.md"
    echo "# Proof note: $DATE" > "$TARGET"
    echo "" >> "$TARGET"
    echo "$BODY" >> "$TARGET"
    ;;
  project)
    echo "For project entries, edit brain/projects/<slug>.md directly."
    exit 0
    ;;
  *)
    echo "Unknown type: $TYPE"
    exit 1
    ;;
esac

echo "✓ Written to $TARGET"
