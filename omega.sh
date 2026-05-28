#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION="${MAW_ORACLE_SESSION:-forge-omega-oracle}"
RUN_ROOT="$DIR/reports/autonomous-fleet"
AGGREGATE="$DIR/reports/progress/forge-omega-oracle-study.md"

usage() {
  cat <<'USAGE'
Forge Omega commands:
  maw omega              Start the Forge Omega study flow (default)
  maw omega study        Start/restart the full tmux study session
  maw omega open         Start the study flow and attach to the tmux session
  maw omega attach       Attach to the current tmux session
  maw omega monitor      Tail the aggregated progress report
  maw omega report       Show the latest progress summary
  maw omega health       Run the Forge/Omega health check
  maw omega status       Show the current Omega session/report status
  maw omega live         Open the live tmux show layout and attach
  maw omega list         Show this help
USAGE
}

start_study() {
  bash "$DIR/scripts/forge-omega-oracle-study.sh" "$@"
}

start_live() {
  bash "$DIR/scripts/spawn-live-5-2-show.sh" "$@"
}

open_live() {
  exec bash "$DIR/scripts/open-tham-oracle-live.sh" "$@"
}

run_study() {
  exec bash "$DIR/scripts/forge-omega-oracle-study.sh" "$@"
}

run_health() {
  exec bash "$DIR/scripts/forge-omega-health.sh" "$@"
}

attach_session() {
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
  fi

  echo "Omega session not running: $SESSION" >&2
  echo "Start it with: maw omega study" >&2
  exit 1
}

monitor_progress() {
  if [[ ! -f "$AGGREGATE" ]]; then
    echo "No aggregated progress file yet: $AGGREGATE" >&2
    echo "Start the study flow first: maw omega study" >&2
    exit 1
  fi

  exec tail -n +1 -f "$AGGREGATE"
}

show_report() {
  if [[ -f "$AGGREGATE" ]]; then
    cat "$AGGREGATE"
    return 0
  fi

  echo "No report available yet: $AGGREGATE" >&2
  echo "Start the study flow first: maw omega study" >&2
  return 1
}

show_status() {
  echo "Session: $SESSION"
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "tmux: running"
  else
    echo "tmux: not running"
  fi

  if [[ -f "$AGGREGATE" ]]; then
    echo "report: $AGGREGATE"
  else
    echo "report: not created yet"
  fi

  if [[ -d "$RUN_ROOT" ]]; then
    echo "runs: $RUN_ROOT"
  fi
}

case "${1:-study}" in
  study)
    shift || true
    run_study "$@"
    ;;
  open)
    shift || true
    start_study "$@"
    attach_session
    ;;
  live)
    shift || true
    open_live "$@"
    ;;
  attach)
    shift || true
    attach_session
    ;;
  monitor)
    shift || true
    monitor_progress
    ;;
  report)
    shift || true
    show_report
    ;;
  health)
    shift || true
    run_health "$@"
    ;;
  status)
    shift || true
    show_status
    ;;
  list|help|-h|--help)
    usage
    ;;
  *)
    # Preserve backwards compatibility: unknown args are treated as study arguments.
    # This keeps maw omega behaving like the original launcher while allowing subcommands.
    run_study "$@"
    ;;
esac
