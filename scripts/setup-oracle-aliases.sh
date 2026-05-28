#!/usr/bin/env bash
# Setup Oracle aliases in ~/.bashrc or ~/.zshrc
# Idempotent: run safely multiple times
# Usage: bash scripts/setup-oracle-aliases.sh

set -euo pipefail

ORACLE_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
SHELL_RC=""

# Detect shell
if [ -n "${ZSH_VERSION:-}" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
else
  echo "✗ Could not detect shell (.bashrc or .zshrc)"
  exit 1
fi

# Check if already installed
if grep -q "# oracle-aliases-v1.1" "$SHELL_RC" 2>/dev/null; then
  echo "✓ Oracle aliases already installed in $SHELL_RC"
  exit 0
fi

# Create alias block
ALIAS_BLOCK=$(cat << 'EOF'

# ===== oracle-aliases-v1.1 =====
# Oracle Toolkit shortcuts
export ORACLE_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
alias oracle="bash \$ORACLE_ROOT/bin/oracle"
alias cc="bash \$ORACLE_ROOT/scripts/oracle-engine.sh --role tham-oracle --workdir \$PWD"
alias ccd="bash \$ORACLE_ROOT/scripts/oracle-engine.sh --role tham-oracle --workdir \$PWD --dangerously-skip-permissions"
alias gs="git status"
alias gl="git log --oneline -15"
alias gd="git diff"
alias gaa="git add -A && git status"
alias tm="tmux a -t oracle 2>/dev/null || oracle tmux:start"
alias lanes="oracle tmux:lanes"
alias fleet="oracle tmux:fleet"
alias inbox="oracle queue:check"
alias proof="oracle proof:last"
# ===== end oracle-aliases-v1.1 =====
EOF
)

# Append to shell rc
echo "$ALIAS_BLOCK" >> "$SHELL_RC"

echo "✓ Oracle aliases installed in $SHELL_RC"
echo ""
echo "To activate aliases now, run:"
echo "  source $SHELL_RC"
echo ""
echo "Available aliases:"
echo "  oracle    — main CLI"
echo "  cc, ccd   — Claude Code"
echo "  gs, gl, gd, gaa — git shortcuts"
echo "  tm        — attach/start oracle tmux"
echo "  lanes, fleet — start multi-agent sessions"
echo "  inbox, proof  — queue/proof checks"
