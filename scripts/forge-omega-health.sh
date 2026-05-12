#!/usr/bin/env bash
# forge-omega-health.sh — Health check for Forge/Omega local stack
# Checks: oracle-v2 HTTP, oracle studio, tmux sessions, tool availability

set -euo pipefail

ORACLE_PORT="${ORACLE_PORT:-47778}"
STUDIO_PORT="${STUDIO_PORT:-3000}"
PASS=0
FAIL=0

check() {
  local name="$1"
  local result="$2"
  if [ "$result" = "ok" ]; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name — $result"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Forge/Omega Health Check ($(date '+%Y-%m-%d %H:%M')) ==="
echo ""

echo "[ Tools ]"
command -v bun >/dev/null 2>&1 && check "bun" "ok" || check "bun" "NOT FOUND"
command -v node >/dev/null 2>&1 && check "node" "ok" || check "node" "NOT FOUND"
command -v tmux >/dev/null 2>&1 && check "tmux" "ok" || check "tmux" "NOT FOUND"
command -v gh >/dev/null 2>&1 && check "gh" "ok" || check "gh" "NOT FOUND"
command -v ghq >/dev/null 2>&1 && check "ghq" "ok" || check "ghq" "NOT FOUND"
command -v maw >/dev/null 2>&1 && check "maw" "ok" || check "maw" "NOT FOUND"
command -v go >/dev/null 2>&1 && check "go" "ok" || check "go" "NOT FOUND"

echo ""
echo "[ Oracle v2 HTTP (port $ORACLE_PORT) ]"
if curl -sf "http://localhost:${ORACLE_PORT}/" >/dev/null 2>&1; then
  VERSION=$(curl -s "http://localhost:${ORACLE_PORT}/" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  check "oracle-v2 HTTP (v${VERSION})" "ok"
else
  check "oracle-v2 HTTP" "NOT running — run: bash scripts/start-oracle-v2-http.sh"
fi

echo ""
echo "[ Oracle Studio (built-in Swagger UI) ]"
if curl -sf "http://localhost:${ORACLE_PORT}/swagger" >/dev/null 2>&1; then
  check "oracle-studio (swagger @ :${ORACLE_PORT}/swagger)" "ok"
else
  check "oracle-studio" "NOT running — run: bash scripts/start-oracle-studio.sh"
fi

echo ""
echo "[ tmux sessions ]"
if tmux has-session -t "tham-oracle-stack" 2>/dev/null; then
  check "tham-oracle-stack session" "ok"
else
  check "tham-oracle-stack session" "NOT running — run: bash scripts/start-oracle-local-stack-tmux.sh"
fi

if tmux has-session -t "oracle-fleet" 2>/dev/null; then
  check "oracle-fleet session" "ok"
else
  check "oracle-fleet session" "NOT running (optional) — run: bash scripts/oracle-fleet.sh"
fi

echo ""
echo "[ Repo structure ]"
[ -f "CLAUDE.md" ] && check "CLAUDE.md" "ok" || check "CLAUDE.md" "MISSING"
[ -f ".mcp.json" ] && check ".mcp.json" "ok" || check ".mcp.json" "MISSING"
[ -f "configs/agent-registry.json" ] && check "agent-registry.json" "ok" || check "agent-registry.json" "MISSING"
[ -d "ψ/memory/resonance" ] && check "ψ vault" "ok" || check "ψ vault" "MISSING"
[ -d "brain/memory" ] && check "brain structure" "ok" || check "brain structure" "MISSING"

echo ""
echo "[ gh auth ]"
if gh auth status >/dev/null 2>&1; then
  check "GitHub auth" "ok"
else
  check "GitHub auth" "NOT authenticated — run: gh auth login"
fi

echo ""
echo "================================================"
echo "PASS: $PASS | FAIL: $FAIL"
if [ $FAIL -eq 0 ]; then
  echo "STATUS: ✅ ALL OK"
else
  echo "STATUS: ⚠️  $FAIL checks failed — see above"
fi
