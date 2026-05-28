#!/bin/bash
# Setup Model Routing: Codex + Gemini via 9router (Tham-oracle uses native Claude only)
# Usage: bash scripts/setup-model-routing.sh

echo "🎯 Model Routing Setup"
echo ""

# Check global environment
echo "1️⃣  Checking global environment..."
if grep -q "ANTHROPIC_API_BASE_URL" ~/.bashrc; then
  echo "   ✓ Global routing found in ~/.bashrc"
  echo "   URL: $(grep 'ANTHROPIC_API_BASE_URL=' ~/.bashrc | tail -1)"
else
  echo "   ❌ No global routing in ~/.bashrc"
  echo "   Run: source ~/.bashrc to load routing"
fi
echo ""

WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${WINDOWS_HOST_IP}:20128}"
echo "2️⃣  Checking 9router status..."
if timeout 2 curl -s "${ROUTER_BASE_URL}/health" >/dev/null 2>&1; then
  echo "   ✅ 9router running @ ${WINDOWS_HOST_IP}:20128"
  curl -s "${ROUTER_BASE_URL}/v1/models" 2>/dev/null | python3 -m json.tool | grep '"id"' | head -5 || echo "   (models loading...)"
else
  echo "   ⚠️  9router not responding"
  echo "   Start on Windows with: powershell -ExecutionPolicy Bypass -File scripts\\Start-9router.ps1"
fi
echo ""

# Check Tham-oracle exception
echo "3️⃣  Tham-oracle Exception Setup..."
if [ -f .env.tham ]; then
  echo "   ✓ .env.tham found"
  echo ""
  echo "   To use Tham-oracle with Claude primary + automatic Codex fallback:"
  echo "   $ source .env.tham"
  echo "   $ bash scripts/oracle-engine.sh --role tham-oracle --workdir $(pwd)"
else
  echo "   ❌ .env.tham not found"
fi
echo ""

# Test routing
echo "4️⃣  Test Routing..."
echo "   Current ANTHROPIC_API_BASE_URL: ${ANTHROPIC_API_BASE_URL:-'not set'}"
echo "   Current ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:20}... (hidden)"
echo ""

if [ -z "$ANTHROPIC_API_BASE_URL" ]; then
  echo "   ℹ️  Reload shell: source ~/.bashrc"
fi

echo "✅ Setup complete"
echo ""
echo "📌 Next steps:"
echo "   1. Reload shell: source ~/.bashrc"
echo "   2. Check 9router: curl -s ${ROUTER_BASE_URL}/health"
echo "   3. For Tham-oracle: source .env.tham && bash scripts/oracle-engine.sh --role tham-oracle --workdir $(pwd)"
