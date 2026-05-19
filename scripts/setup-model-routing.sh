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

# Check 9router status
echo "2️⃣  Checking 9router status..."
if timeout 2 curl -s http://127.0.0.1:20128/health >/dev/null 2>&1; then
  echo "   ✅ 9router running @ localhost:20128"
  curl -s http://127.0.0.1:20128/v1/models 2>/dev/null | python3 -m json.tool | grep '"id"' | head -5 || echo "   (models loading...)"
else
  echo "   ⚠️  9router not responding"
  echo "   Start with: bash scripts/9router-startup.sh (Windows only)"
fi
echo ""

# Check Tham-oracle exception
echo "3️⃣  Tham-oracle Exception Setup..."
if [ -f .env.tham ]; then
  echo "   ✓ .env.tham found"
  echo ""
  echo "   To use Tham-oracle with Claude API:"
  echo "   $ source .env.tham"
  echo "   $ claude ..."
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
echo "   2. Check 9router: curl -s http://127.0.0.1:20128/health"
echo "   3. For Tham-oracle: source .env.tham && claude ..."
