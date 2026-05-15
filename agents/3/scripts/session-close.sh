#!/usr/bin/env bash
# Session closeout: capture proof, commit brain changes, push.
# Run at end of every major work session.

REPO="/root/repos/tham-oracle"
BRAIN="$REPO/brain"
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')

echo "╔══════════════════════════════════════════╗"
echo "║        SESSION CLOSE — ธาม               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Collect session result from user
read -rp "RESULT (ok/check/fail): " RESULT
read -rp "ACTION (what was done):  " ACTION
read -rp "NEXT   (exact next step): " NEXT

# 2. Write proof entry
PROOF_FILE="$BRAIN/proofs/$DATE-session.md"
cat >> "$PROOF_FILE" << EOF

## $TIME — Session Closeout
RESULT: $(echo "$RESULT" | tr '[:lower:]' '[:upper:]')
ACTION: $ACTION
NEXT:   $NEXT
EOF

echo ""
echo "✓ Proof written → $PROOF_FILE"

# 3. Update ACTIVE_INDEX last-updated
sed -i "s/^Last updated: .*/Last updated: $DATE $TIME/" "$BRAIN/memory/ACTIVE_INDEX.md"

# 4. Git commit if dirty
cd "$REPO" || exit 1
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  git add -A
  git commit -m "Session close $DATE $TIME — RESULT=$(echo "$RESULT" | tr '[:lower:]' '[:upper:]'): $ACTION

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
  echo "✓ Committed"

  # 5. Push
  read -rp "Push to GitHub? (y/n): " PUSH
  if [[ "$PUSH" == "y" || "$PUSH" == "Y" ]]; then
    git push origin main && echo "✓ Pushed"
  fi
else
  echo "  (no changes to commit)"
fi

echo ""
echo "────────────────────────────────────────────"
echo "  RESULT : $(echo "$RESULT" | tr '[:lower:]' '[:upper:]')"
echo "  ACTION : $ACTION"
echo "  NEXT   : $NEXT"
echo "  STATUS : DONE"
echo "────────────────────────────────────────────"
