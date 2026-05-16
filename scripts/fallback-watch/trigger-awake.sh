#!/usr/bin/env bash
# Tham Oracle — Token Limit Trigger Awake
# Run: every 10 min via cron, or manually
# Detects Claude token limit approaching → activates Codex/Ollama fallback

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NOTIFY="${REPO_ROOT}/scripts/telegram/notify.sh"
FALLBACK_STATE="/tmp/tham-fallback-active.json"
LOG="/tmp/tham-fallback-watch.log"
THRESHOLD="${THAM_TOKEN_THRESHOLD:-10000}"
MIMO_PORT="${MIMO_PORT:-18080}"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# ── Read Anthropic key from providers config ──────────────────────────────────
ANTHROPIC_KEY=""
PROVIDERS_CFG="$HOME/.config/ai-providers/providers.json"
if [ -f "$PROVIDERS_CFG" ]; then
  ANTHROPIC_KEY=$(python3 -c "
import json, sys
cfg = json.load(open('$PROVIDERS_CFG'))
for p in cfg.get('providers', []):
    if p.get('type') == 'anthropic' and p.get('api_key','').startswith('sk-ant'):
        print(p['api_key'])
        break
" 2>/dev/null || echo "")
fi

if [ -z "$ANTHROPIC_KEY" ]; then
  log "⚠️ No Anthropic key found — cannot check token limit"
  exit 0
fi

# ── Probe rate limit headers ──────────────────────────────────────────────────
HEADERS=$(curl -s -I \
  -H "x-api-key: $ANTHROPIC_KEY" \
  -H "anthropic-version: 2023-06-01" \
  "https://api.anthropic.com/v1/models" 2>/dev/null || echo "")

REMAINING=$(echo "$HEADERS" | grep -i "anthropic-ratelimit-tokens-remaining:" \
  | awk '{print $2}' | tr -d '[:space:]\r' | head -1)

RESET_AT=$(echo "$HEADERS" | grep -i "anthropic-ratelimit-tokens-reset:" \
  | awk '{print $2}' | tr -d '[:space:]\r' | head -1)

log "Token check — remaining: ${REMAINING:-unknown}, reset: ${RESET_AT:-unknown}"

# ── Evaluate threshold ────────────────────────────────────────────────────────
if [ -z "$REMAINING" ]; then
  log "Could not read token limit headers (API may be unreachable)"
  exit 0
fi

if [ "$REMAINING" -lt "$THRESHOLD" ] 2>/dev/null; then
  log "⚠️ THRESHOLD HIT: $REMAINING < $THRESHOLD — activating fallback"

  # Write fallback state file
  python3 -c "
import json
from datetime import datetime
state = {
    'active': True,
    'reason': 'token_limit',
    'tokens_remaining': $REMAINING,
    'threshold': $THRESHOLD,
    'reset_at': '${RESET_AT:-unknown}',
    'activated_at': datetime.now().isoformat(),
    'fallback_provider': 'codex_ollama',
}
with open('$FALLBACK_STATE', 'w') as f:
    json.dump(state, f, indent=2)
"
  log "Fallback state written: $FALLBACK_STATE"

  # Telegram alert
  if [ -f "$NOTIFY" ]; then
    bash "$NOTIFY" custom "⚠️ <b>Token Limit Warning</b>
Tokens remaining: <code>$REMAINING</code> (threshold: $THRESHOLD)
Reset at: <code>${RESET_AT:-unknown}</code>
Fallback → Codex + Ollama activated.
Send /status to check provider health."
  fi

  # Check if mimo2codex proxy is running
  if curl -sf "http://localhost:${MIMO_PORT}/health" >/dev/null 2>&1; then
    log "✅ mimo2codex proxy already running on port $MIMO_PORT"
  else
    log "⚠️ mimo2codex not running — Omega must start it (see ψ/inbox/core/)"
    # Omega will handle the actual mimo2codex start on Windows side
    # Write a wake signal for Omega
    mkdir -p "${REPO_ROOT}/ψ/inbox/core"
    cat > "${REPO_ROOT}/ψ/inbox/core/WAKE_$(date +%H%M).signal" << EOF
WAKE_REASON=token_limit
TOKENS_REMAINING=$REMAINING
ACTION=start_mimo2codex_proxy
PORT=$MIMO_PORT
AT=$(date -Iseconds)
EOF
    log "Wake signal written for Omega"
  fi

else
  log "✅ Tokens OK: $REMAINING (threshold: $THRESHOLD)"

  # Clear fallback flag if tokens recovered
  if [ -f "$FALLBACK_STATE" ]; then
    WAS_ACTIVE=$(python3 -c "import json; d=json.load(open('$FALLBACK_STATE')); print(d.get('active','false'))" 2>/dev/null || echo "false")
    if [ "$WAS_ACTIVE" = "True" ] || [ "$WAS_ACTIVE" = "true" ]; then
      log "Tokens recovered — clearing fallback state"
      python3 -c "
import json
from datetime import datetime
state = json.load(open('$FALLBACK_STATE'))
state['active'] = False
state['recovered_at'] = datetime.now().isoformat()
with open('$FALLBACK_STATE', 'w') as f:
    json.dump(state, f, indent=2)
"
      if [ -f "$NOTIFY" ]; then
        bash "$NOTIFY" custom "🟢 <b>Token Limit Recovered</b>
Tokens remaining: <code>$REMAINING</code>
Fallback deactivated — back to Claude."
      fi
    fi
  fi
fi

log "Done."
