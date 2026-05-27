#!/usr/bin/env bash
# Convenience launcher: spawn the live Tham Oracle tmux show and attach to it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/spawn-live-5-2-show.sh"
exec tmux attach -t "${THAM_ORACLE_SHOW_SESSION:-tham-oracle-live}"
