#!/usr/bin/env bash
# Tham Oracle — Start Telegram Bot
# Runs in background with tmux session "tham-telegram"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOT="${REPO_ROOT}/scripts/telegram/bot.py"
CONFIG="$HOME/.config/tham/telegram.env"
SESSION="tham-telegram"

echo "🔮 Tham Oracle — Telegram Bot Launcher"
echo ""

# Check config
if [ ! -f "$CONFIG" ]; then
  echo "❌ Config not found: $CONFIG"
  echo ""
  echo "Create it first:"
  echo "  mkdir -p ~/.config/tham"
  echo "  nano ~/.config/tham/telegram.env"
  echo ""
  echo "Add these lines:"
  echo "  TELEGRAM_BOT_TOKEN=your_token_here"
  echo "  TELEGRAM_CHAT_ID=your_chat_id_here"
  exit 1
fi

# Check python3
if ! command -v python3 &>/dev/null; then
  echo "❌ python3 not found"
  exit 1
fi

# Check requests module
if ! python3 -c "import requests" 2>/dev/null; then
  echo "📦 Installing requests..."
  pip3 install requests --quiet
fi

# Kill existing session if running
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "⚠️  Killing existing session: $SESSION"
  tmux kill-session -t "$SESSION"
fi

# Start new tmux session
echo "🚀 Starting bot in tmux session: $SESSION"
tmux new-session -d -s "$SESSION" -x 220 -y 50 \
  "cd $REPO_ROOT && python3 $BOT; echo 'Bot stopped. Press Enter to exit.'; read"

sleep 1

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "✅ Bot running in tmux session: $SESSION"
  echo ""
  echo "Commands:"
  echo "  tmux attach -t $SESSION    # View bot output"
  echo "  tmux kill-session -t $SESSION  # Stop bot"
  echo ""
  echo "Cron setup (run once):"
  echo "  bash ${REPO_ROOT}/scripts/telegram/setup-cron.sh"
else
  echo "❌ Bot failed to start. Check: python3 $BOT"
fi
