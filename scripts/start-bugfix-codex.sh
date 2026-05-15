#!/usr/bin/env bash
# start-bugfix-codex.sh — Start BugFix Agent using opencode + OpenRouter
# Model: openai/codex-mini-latest via openrouter.ai

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HERMES_ENV="/root/.hermes/.env"
OPENCODE="${HOME}/.nvm/versions/node/v24.15.0/bin/opencode"

if [ ! -f "$HERMES_ENV" ]; then
  echo "ERROR: hermes .env not found: $HERMES_ENV"
  exit 1
fi

if [ ! -x "$OPENCODE" ]; then
  OPENCODE="$(command -v opencode 2>/dev/null || true)"
  if [ -z "$OPENCODE" ]; then
    echo "ERROR: opencode not found. Install: npm install -g opencode-ai"
    exit 1
  fi
fi

# Load OPENROUTER_API_KEY
OPENROUTER_API_KEY="$(grep '^OPENROUTER_API_KEY=' "$HERMES_ENV" | cut -d= -f2)"
if [ -z "$OPENROUTER_API_KEY" ]; then
  echo "ERROR: OPENROUTER_API_KEY not found in $HERMES_ENV"
  exit 1
fi
export OPENROUTER_API_KEY

cd "$REPO_ROOT"
exec "$OPENCODE"
