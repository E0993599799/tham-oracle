#!/usr/bin/env bash
# Oracle engine wrapper.
# Default: run Claude.
# If /tmp/tham-fallback-active.json says fallback is active, route Oracle launches to Codex GPT-5.5 via 9router.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FALLBACK_STATE="${FALLBACK_STATE:-/tmp/tham-fallback-active.json}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${WINDOWS_HOST_IP}:20128/v1}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
CODEX_BIN="${CODEX_BIN:-/mnt/c/Users/User/AppData/Local/Volta/bin/codex}"
CODEX_MODEL="${CODEX_MODEL:-cx/gpt-5.5}"
ROLE="tham-oracle"
WORKDIR="$(pwd)"

fallback_active() {
  python3 - "$FALLBACK_STATE" <<'PY'
import json, os, sys
path = sys.argv[1]
if not os.path.exists(path):
    print("false")
    raise SystemExit(0)
try:
    with open(path, "r", encoding="utf-8") as fh:
        state = json.load(fh)
    print("true" if state.get("active") else "false")
except Exception:
    print("false")
PY
}

fallback_summary() {
  python3 - "$FALLBACK_STATE" <<'PY'
import json, os, sys
path = sys.argv[1]
if not os.path.exists(path):
    raise SystemExit(0)
try:
    with open(path, "r", encoding="utf-8") as fh:
        state = json.load(fh)
except Exception:
    raise SystemExit(0)
provider = state.get("fallback_provider", "codex_gpt55_9router")
remaining = state.get("tokens_remaining", "?")
reason = state.get("reason", "token_limit")
print(f"reason={reason} tokens_remaining={remaining} provider={provider}")
PY
}

SUPPORTED_NOTE="[oracle-engine] Claude fallback active -> Codex GPT-5.5 via 9router"

if [ "$(fallback_active)" != "true" ]; then
  exec "$CLAUDE_BIN" "$@"
fi

if [ ! -x "$CODEX_BIN" ] && ! command -v codex >/dev/null 2>&1; then
  echo "[oracle-engine] fallback requested but Codex CLI is unavailable; continuing with Claude" >&2
  exec "$CLAUDE_BIN" "$@"
fi

if [ ! -x "$CODEX_BIN" ]; then
  CODEX_BIN="$(command -v codex)"
fi

PROMPT_FILE=""
PROMPT_TEXT=""
UNSUPPORTED_ARGS=()
POSITIONAL_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role)
      ROLE="${2:-$ROLE}"
      shift 2
      ;;
    --workdir)
      WORKDIR="${2:-$WORKDIR}"
      shift 2
      ;;
    --name)
      ROLE="${2:-$ROLE}"
      shift 2
      ;;
    --append-system-prompt-file)
      PROMPT_FILE="${2:-}"
      shift 2
      ;;
    --model|--permission-mode)
      shift 2
      ;;
    --dangerously-skip-permissions|--dangerously-bypass-approvals-and-sandbox)
      shift
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        POSITIONAL_ARGS+=("$1")
        shift
      done
      ;;
    -*)
      UNSUPPORTED_ARGS+=("$1")
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ ${#POSITIONAL_ARGS[@]} -gt 0 ]; then
  PROMPT_TEXT="${POSITIONAL_ARGS[*]}"
fi

if [ ${#UNSUPPORTED_ARGS[@]} -gt 0 ]; then
  echo "[oracle-engine] ignoring unsupported Claude args during fallback: ${UNSUPPORTED_ARGS[*]}" >&2
fi

echo "$SUPPORTED_NOTE ($(fallback_summary))" >&2

ROLE_NOTE=$(cat <<EOF
You are continuing the Oracle role '$ROLE'.
Claude token fallback is active, so run on Codex GPT-5.5 via 9router instead of Claude.
Preserve the same goal, constraints, and safety posture. Do not widen scope.
EOF
)

PROMPT_TMP="$(mktemp)"
cleanup() {
  rm -f "$PROMPT_TMP"
}
trap cleanup EXIT

{
  printf '%s\n' "$ROLE_NOTE"
  if [ -n "$PROMPT_FILE" ] && [ -f "$PROMPT_FILE" ]; then
    printf '\n[system prompt file: %s]\n' "$PROMPT_FILE"
    cat "$PROMPT_FILE"
    printf '\n'
  fi
  if [ -n "$PROMPT_TEXT" ]; then
    printf '\n[user prompt]\n%s\n' "$PROMPT_TEXT"
  fi
  if ! [ -t 0 ]; then
    printf '\n[stdin]\n'
    cat
    printf '\n'
  fi
} > "$PROMPT_TMP"

export OPENAI_BASE_URL="$ROUTER_BASE_URL"
export CODEX_MODEL

if [ -s "$PROMPT_TMP" ] && { [ -n "$PROMPT_FILE" ] || [ -n "$PROMPT_TEXT" ] || ! [ -t 0 ]; }; then
  exec "$CODEX_BIN" exec -m "$CODEX_MODEL" -C "$WORKDIR" -s workspace-write -a never - < "$PROMPT_TMP"
fi

exec "$CODEX_BIN" -m "$CODEX_MODEL" -C "$WORKDIR" -s workspace-write -a on-request "$ROLE_NOTE"
