#!/usr/bin/env bash
# Create a dated /rrr retrospective file.
# Usage: new-rrr.sh "session-slug"
# Output: ψ/memory/retrospectives/YYYY-MM/DD/HH.MM_slug.md
#
# Does NOT auto-commit — run git commit manually after filling in the file.

SLUG="${1:-session}"
SLUG=$(echo "$SLUG" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

YEAR=$(date '+%Y')
MONTH=$(date '+%m')
DAY=$(date '+%d')
TIME=$(date '+%H.%M')

DIR="ψ/memory/retrospectives/${YEAR}-${MONTH}/${DAY}"
FILE="${DIR}/${TIME}_${SLUG}.md"

mkdir -p "$DIR"

# Copy template if exists, else create minimal file
TEMPLATE="templates/rrr-retrospective-template.md"
if [ -f "$TEMPLATE" ]; then
  cp "$TEMPLATE" "$FILE"
  # Replace date/time placeholders
  sed -i "s/YYYY-MM-DD/${YEAR}-${MONTH}-${DAY}/g" "$FILE"
  sed -i "s/HH:MM/${TIME//./:}/g" "$FILE"
  sed -i "s/short-kebab-slug/${SLUG}/g" "$FILE"
else
  cat > "$FILE" << EOF
# /rrr — ${YEAR}-${MONTH}-${DAY} ${TIME//./:} — ${SLUG}

## Session Summary

## Timeline

## Lessons Learned

## Next Steps
EOF
fi

echo "✓ Created: $FILE"
echo ""
echo "Fill in the retrospective, then:"
echo "  git add ψ/memory/"
echo "  git commit -m \"docs: /rrr ${YEAR}-${MONTH}-${DAY} ${SLUG}\""
echo "  git push"
