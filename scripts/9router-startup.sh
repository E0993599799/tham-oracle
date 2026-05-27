#!/bin/bash
# 9router Startup Helper — Open dashboard & wait for API ready
# Usage: bash scripts/9router-startup.sh

echo "🚀 9router Startup Helper"
echo ""
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://${WINDOWS_HOST_IP}:20128}"
echo "Instructions for Windows (9router service):"
echo ""
echo "  OPTION 1: Double-click desktop shortcut"
echo "    📁 C:\\desktop\\Start 9router.cmd"
echo ""
echo "  OPTION 2: Windows Terminal"
echo "    🖥️  powershell -ExecutionPolicy Bypass -File scripts\\Start-9router.ps1"
echo ""
echo "  OPTION 3: PowerShell Admin"
echo '    PS> & "$env:LOCALAPPDATA\Volta\bin\9router.cmd" --port 20128 --host 0.0.0.0 --no-browser --tray --skip-update'
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Waiting for 9router dashboard to respond..."
echo "(This may take 10-20 seconds after service starts)"
echo ""

# Try to connect to dashboard
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
  if timeout 2 curl -s -I "${ROUTER_BASE_URL}/dashboard" 2>/dev/null | head -1 | grep -q "HTTP"; then
    echo -e "✅ 9router dashboard is responding!"
    echo ""
    echo "Access dashboard:"
    echo "  🌐 ${ROUTER_BASE_URL}/dashboard"
    echo ""

    # Wait a bit for API to warm up
    sleep 2

    # Check API
    echo "Checking API (v1/models)..."
    if timeout 2 curl -s "${ROUTER_BASE_URL}/v1/models" 2>/dev/null | head -c 100 >/dev/null; then
      echo "✅ API responding - Ready for routes!"
      echo ""
      echo "Available models:"
      curl -s "${ROUTER_BASE_URL}/v1/models" 2>/dev/null | python3 -m json.tool | grep '"id"' | head -10 || echo "  (checking...)"
      exit 0
    else
      echo "⏳ API warming up... (will be ready shortly)"
    fi

    exit 0
  fi

  attempt=$((attempt + 1))
  progress=$(( (attempt * 100) / max_attempts ))
  echo -ne "\r  Attempt $attempt/$max_attempts ($progress%)..."
  sleep 1
done

echo ""
echo ""
echo "⚠️  9router dashboard not responding after ${max_attempts}s"
echo ""
echo "Troubleshooting:"
echo "  1. Check if C:\\desktop\\Start 9router.cmd was executed"
echo "  2. Windows Task Manager → Services → 9router (should be 'Running')"
echo "  3. Try manual restart: Get-Service 9router | Restart-Service"
echo "  4. Check Windows Event Viewer for errors"
echo ""
echo "Once 9router is running:"
echo "  bash scripts/run-world-class-benchmarks.sh"
