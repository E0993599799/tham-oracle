#!/usr/bin/env bash
# Install maw-js and its dependencies (go, ghq, maw).
# Safe to run multiple times — checks before installing.
# Does NOT auto-start any server. Does NOT commit any secret.

set -e
LOG="/route/mission-control/tham-oracle/.oracle-setup/logs/install-maw-js.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "=== install-maw-js.sh ==="
echo "Date: $(date)"
echo ""

# --- 1. Go ---
if command -v go &>/dev/null; then
  echo "✓ go already installed: $(go version)"
else
  echo "Installing Go via apt..."
  apt-get update -qq && apt-get install -y golang-go
  echo "✓ go installed: $(go version)"
fi

# Add Go bin to PATH for this script
export PATH="$HOME/go/bin:$PATH"

# --- 2. ghq ---
if command -v ghq &>/dev/null; then
  echo "✓ ghq already installed"
else
  echo "Installing ghq..."
  go install github.com/x-motemen/ghq@latest
  echo "✓ ghq installed"
fi

# Symlink so tmux/cron can find it
if [ ! -f /usr/local/bin/ghq ] && [ -f "$HOME/go/bin/ghq" ]; then
  ln -sf "$HOME/go/bin/ghq" /usr/local/bin/ghq && echo "✓ symlinked ghq → /usr/local/bin/ghq"
fi

# --- 3. maw-js ---
if command -v maw &>/dev/null; then
  echo "✓ maw already installed: $(maw --version 2>/dev/null || echo found)"
else
  echo "Cloning maw-js via ghq..."
  ghq get https://github.com/Soul-Brews-Studio/maw-js

  MAW_DIR="$(ghq root)/github.com/Soul-Brews-Studio/maw-js"
  echo "maw source: $MAW_DIR"

  cd "$MAW_DIR/src"
  bun install
  bun link
  echo "✓ maw linked via bun"

  # Symlink for global access
  if [ -f "$HOME/.bun/bin/maw" ]; then
    ln -sf "$HOME/.bun/bin/maw" /usr/local/bin/maw && echo "✓ symlinked maw → /usr/local/bin/maw"
  fi
fi

# Symlink bun for tmux/cron safety
if [ ! -f /usr/local/bin/bun ] && [ -f "$HOME/.bun/bin/bun" ]; then
  ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun && echo "✓ symlinked bun → /usr/local/bin/bun"
fi

# --- 4. Verify ---
echo ""
echo "=== Verification ==="
command -v maw &>/dev/null && echo "✓ maw: $(maw --version 2>/dev/null || which maw)" || echo "✗ maw: NOT FOUND"
command -v ghq &>/dev/null && echo "✓ ghq: $(which ghq)" || echo "✗ ghq: NOT FOUND"
command -v go  &>/dev/null && echo "✓ go:  $(go version)" || echo "✗ go: NOT FOUND"
command -v bun &>/dev/null && echo "✓ bun: $(bun --version)" || echo "✗ bun: NOT FOUND"

echo ""
echo "=== Next: create maw config ==="
echo "Run: bash scripts/setup-maw-config.sh"
echo "Log: $LOG"
