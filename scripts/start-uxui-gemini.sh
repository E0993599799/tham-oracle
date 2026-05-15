#!/usr/bin/env bash
# start-uxui-gemini.sh — Start UX/UI Design Agent using Gemini CLI
# Injects uxui-prompt.md as initial interactive prompt (research-first enforced)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPT_FILE="$REPO_ROOT/configs/agent-prompts/uxui-prompt.md"
GEMINI="${HOME}/.nvm/versions/node/v24.15.0/bin/gemini"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: uxui-prompt.md not found: $PROMPT_FILE"
  exit 1
fi

if [ ! -x "$GEMINI" ]; then
  # Fallback: try gemini in PATH
  GEMINI="$(command -v gemini 2>/dev/null || true)"
  if [ -z "$GEMINI" ]; then
    echo "ERROR: gemini CLI not found. Install: npm install -g @google/gemini-cli"
    exit 1
  fi
fi

INITIAL_PROMPT="$(cat "$PROMPT_FILE")"

exec "$GEMINI" -i "$INITIAL_PROMPT"
