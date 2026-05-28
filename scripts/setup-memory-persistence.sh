#!/usr/bin/env bash
# One-time setup: make memory auto-save work on every WSL boot.
# Run once as: sudo bash scripts/setup-memory-persistence.sh

set -e

if [ "$(id -u)" != "0" ]; then
  echo "ERROR: run with sudo"
  echo "  sudo bash /route/mission-control/tham-oracle/scripts/setup-memory-persistence.sh"
  exit 1
fi

echo "[1/3] Adding cron start to WSL boot..."
# Add [boot] section to wsl.conf if not already there
if grep -q '^\[boot\]' /etc/wsl.conf 2>/dev/null; then
  if ! grep -q 'service cron start' /etc/wsl.conf; then
    sed -i '/^\[boot\]/a command = service cron start' /etc/wsl.conf
    echo "  → added cron to existing [boot] section"
  else
    echo "  → already configured"
  fi
else
  printf '\n[boot]\ncommand = service cron start\n' >> /etc/wsl.conf
  echo "  → [boot] section added"
fi

echo "[2/3] Allowing user to start cron without password..."
SUDOERS_FILE=/etc/sudoers.d/tham-cron
echo "user ALL=(ALL) NOPASSWD: /usr/sbin/service cron start, /usr/sbin/service cron restart, /usr/sbin/service cron status" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
echo "  → $SUDOERS_FILE written"

echo "[3/3] Starting cron now..."
service cron start
echo "  → cron started"

echo ""
echo "Done. Memory auto-save is active."
echo "Cron will also auto-start on every WSL reboot."
