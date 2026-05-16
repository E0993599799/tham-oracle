#!/usr/bin/env bash
# Tham Oracle — Install Git post-commit hook for Telegram notifications
# Hook sends notification after every git commit

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_DIR="${REPO_ROOT}/.git/hooks"
HOOK_FILE="${HOOKS_DIR}/post-commit"
NOTIFY="${REPO_ROOT}/scripts/telegram/notify.sh"

cat > "$HOOK_FILE" << EOF
#!/usr/bin/env bash
# Tham Oracle — post-commit Telegram notification
# Installed by install-git-hook.sh
NOTIFY="${NOTIFY}"
if [ -f "\$NOTIFY" ]; then
  bash "\$NOTIFY" git-commit &
fi
EOF

chmod +x "$HOOK_FILE"
echo "✅ Git post-commit hook installed at: $HOOK_FILE"
echo "   Will send Telegram notification on every commit"
