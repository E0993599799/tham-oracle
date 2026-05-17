#!/bin/bash
# Push message to E0993599799/oasync inbox via GitHub Connector
# Usage: bash scripts/oasync-push.sh "message text"
# Example: bash scripts/oasync-push.sh "ให้ run git status"

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "❌ Usage: bash scripts/oasync-push.sh \"message text\""
  echo ""
  echo "Example:"
  echo "  bash scripts/oasync-push.sh \"ให้ run git status ดูมีไฟล์เปลี่ยนไหม\""
  exit 1
fi

MESSAGE_TEXT="$*"
OASYNC_REPO="/tmp/oasync-push-$$"
OASYNC_GITHUB_URL="https://github.com/E0993599799/oasync.git"

# Get current timestamp (Bangkok time)
TIMESTAMP=$(TZ='Asia/Bangkok' date '+%Y%m%d_%H%M%S')
DATE_BKK=$(TZ='Asia/Bangkok' date '+%Y-%m-%dT%H:%M:%S%z' | sed 's/\([0-9][0-9]\)$/:\1/')

MESSAGE_ID="${TIMESTAMP}_chatgpt_human"

echo "📤 Pushing message to oasync..."
echo "   Message ID: $MESSAGE_ID"
echo "   Text: $MESSAGE_TEXT"
echo ""

# Clone oasync repo to temp location
echo "1️⃣ Cloning oasync repo..."
if ! git clone "$OASYNC_GITHUB_URL" "$OASYNC_REPO" --depth=1 2>&1; then
  echo ""
  echo "❌ ERROR: Cannot access $OASYNC_GITHUB_URL"
  echo ""
  echo "📋 Setup required:"
  echo "   1. Ensure repo E0993599799/oasync exists on GitHub"
  echo "   2. Copy .github/workflows/github-connector.yml from tham-oracle to oasync"
  echo "   3. Verify GitHub credentials are configured: gh auth status"
  echo ""
  rm -rf "$OASYNC_REPO"
  exit 1
fi

cd "$OASYNC_REPO"

# Create inbox JSON message
INBOX_FILE="inbox/${MESSAGE_ID}.json"
mkdir -p inbox

cat > "$INBOX_FILE" << EOF
{
  "message_id": "$MESSAGE_ID",
  "created_at_bkk": "$DATE_BKK",
  "from": "human-chatgpt connector",
  "to": "tham",
  "intent": "Human message via /oasync",
  "body": "$MESSAGE_TEXT",
  "risk_gate": {
    "foreground_allowed": false
  }
}
EOF

echo "2️⃣ Created inbox message: $INBOX_FILE"

# Configure git
git config user.name "oasync-push-bot"
git config user.email "oasync@local"

# Commit and push
echo "3️⃣ Committing..."
git add "$INBOX_FILE"
git commit -m "oasync: human message from tham-oracle

From: human-chatgpt connector
Time: $DATE_BKK
Message: $MESSAGE_TEXT" 2>&1 | grep -v "^\[" || true

echo "4️⃣ Pushing..."
if git push origin main 2>&1 | grep -q "Everything up-to-date"; then
  echo "   (no changes — message already pushed)"
elif git push origin main 2>&1 | grep -q "main -> main"; then
  echo "   ✓ Pushed to GitHub"
else
  # Try rebase in case of conflict
  echo "   (conflict detected, rebasing...)"
  git fetch origin main
  git rebase origin/main
  git push origin main 2>&1 | tail -3 || true
fi

# Cleanup
cd /
rm -rf "$OASYNC_REPO"

echo ""
echo "✅ Message delivered to oasync/inbox/"
echo ""
echo "Next: GitHub Workflow triggers → processes message → output lands in tham-oracle/ψ/inbox/github/"
