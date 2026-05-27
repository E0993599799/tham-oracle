#!/bin/bash
# Wake up 9router by opening dashboard in browser
# Usage: bash scripts/9router-wake.sh [--ps | --browser]

WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"
DASHBOARD_URL="http://${WINDOWS_HOST_IP}:20128/dashboard"
API_URL="http://${WINDOWS_HOST_IP}:20128/v1/models"

echo "🔧 9router Wake-up Tool"
echo ""

case "${1:-browser}" in
  --ps|powershell)
    echo "▶ Opening PowerShell command to start 9router..."
    echo ""
    echo "Copy and paste this in Windows PowerShell:"
    echo ""
    echo "  Get-Service 9router | Restart-Service"
    echo ""
    echo "Or start manually:"
    echo "  Start-Service -Name 9router"
    echo ""
    ;;

  --check)
    echo "Checking 9router status..."
    if timeout 2 curl -s http://${WINDOWS_HOST_IP}:20128/health 2>/dev/null >/dev/null; then
      echo "✅ 9router is UP"
      echo ""
      echo "Models available:"
      curl -s http://${WINDOWS_HOST_IP}:20128/v1/models 2>/dev/null | head -50
    else
      echo "⚠️  9router is DOWN"
      echo ""
      echo "To start on Windows, run in PowerShell:"
      echo '  Start 9router with: & "$env:LOCALAPPDATA\Volta\bin\9router.cmd" --port 20128 --host 0.0.0.0 --no-browser --tray --skip-update'
    fi
    ;;

  *)
    echo "Opening dashboard in browser: $DASHBOARD_URL"
    echo ""

    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
      xdg-open "$DASHBOARD_URL" &
    elif command -v open &> /dev/null; then
      open "$DASHBOARD_URL" &
    else
      echo "Cannot auto-open browser. Open manually:"
      echo "  🌐 $DASHBOARD_URL"
    fi

    echo ""
    echo "If dashboard loads but API is slow:"
    echo "  1. Check Windows Task Manager → 9router service status"
    echo "  2. If stopped, start it: Get-Service 9router | Start-Service"
    echo "  3. Refresh page or wait 10 seconds"
    echo ""
    echo "To check API status: bash scripts/9router-wake.sh --check"
    ;;
esac
