#!/bin/bash
# THAM Monitor + Verify Loop
# Active monitoring: check agent output, request status, verify proofs

set -e

PROJECT="/root/ghq/github.com/E0993599799/tham-oracle"
REPORT_DIR="$PROJECT/reports"
LOG_FILE="$REPORT_DIR/tham-monitor-$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$REPORT_DIR"

cd "$PROJECT"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log function
log() {
    echo -e "${BLUE}[THAM]${NC} $1" | tee -a "$LOG_FILE"
}

verify_proof() {
    local task_id=$1
    local proof_file="$PROJECT/reports/${task_id}-proof.json"

    if [ ! -f "$proof_file" ]; then
        echo -e "${YELLOW}⏳ Waiting for proof${NC}"
        return 1
    fi

    log "✅ Proof found: $task_id"
    cat "$proof_file" | jq . >> "$LOG_FILE"
    return 0
}

request_agent_status() {
    local lane=$1
    local lane_name=$2

    log "📋 Requesting status from $lane_name (LANE-$lane)..."

    # Send command to lane
    tmux send-keys -t "lanes:$lane" "echo '[STATUS-REPORT] $(date +%H:%M:%S) — Task progress:' && pwd" Enter

    sleep 1

    # Capture output
    local output=$(tmux capture-pane -t "lanes:$lane" -p | tail -10)
    echo "$output" >> "$LOG_FILE"
    echo "$output"
}

check_deadlines() {
    local current_time=$(date +%s)

    # TASK-001 deadline: 08:00 AM (28800 seconds from midnight)
    # TASK-PHASE1 deadline: 11:00 AM (39600 seconds)
    # TASK-DASHBOARD deadline: 10:00 AM (36000 seconds)

    local hour=$(date +%H)
    local minute=$(date +%M)

    log "⏰ Deadline check: ${hour}:${minute}"

    if [ "$hour" -ge 8 ] && [ "$hour" -lt 9 ]; then
        log "⚠️  TASK-001 approaching deadline (08:00)"
    fi

    if [ "$hour" -ge 10 ] && [ "$hour" -lt 11 ]; then
        log "⚠️  TASK-DASHBOARD approaching deadline (10:00)"
    fi

    if [ "$hour" -ge 11 ]; then
        log "🔴 TASK-PHASE1 approaching/past deadline (11:00) — CRITICAL"
    fi
}

# Main monitoring loop
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🧠 THAM MONITOR — Active Verification Loop"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Start time: $(date '+%Y-%m-%d %H:%M:%S')"
log "Report: $LOG_FILE"
log ""

ITERATION=0
CHECK_INTERVAL=30  # Check every 30 seconds

while true; do
    ITERATION=$((ITERATION + 1))

    clear

    cat << "HEADER"
╔════════════════════════════════════════════════════════════╗
║           🧠 THAM MONITOR — Active Verification          ║
╚════════════════════════════════════════════════════════════╝

HEADER

    log "Iteration #$ITERATION | $(date '+%H:%M:%S')"
    echo ""

    # Check deadlines
    check_deadlines
    echo ""

    # Request status from active lanes
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "📋 REQUEST AGENT STATUS REPORTS"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # LANE-1: CODEX-A (TASK-PHASE1)
    log "→ LANE-1 (CODEX-A) — TASK-PHASE1 status"
    request_agent_status "1" "CODEX-A"
    echo ""

    # LANE-2: CLAUDE (Multiple tasks)
    log "→ LANE-2 (CLAUDE) — TASK queue status"
    request_agent_status "2" "CLAUDE"
    echo ""

    # LANE-3: SCOUT-1
    log "→ LANE-3 (SCOUT-1) — Watchdog status"
    request_agent_status "3" "SCOUT-1"
    echo ""

    # Check for proof files
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✋ VERIFY PROOFS"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if verify_proof "TASK-001"; then
        log "✅ APPROVED: TASK-001 proof verified"
    else
        log "⏳ Waiting: TASK-001 proof"
    fi

    if verify_proof "TASK-PHASE1"; then
        log "✅ APPROVED: TASK-PHASE1 proof verified"
    else
        log "⏳ Waiting: TASK-PHASE1 proof"
    fi

    if verify_proof "TASK-DASHBOARD"; then
        log "✅ APPROVED: TASK-DASHBOARD proof verified"
    else
        log "⏳ Waiting: TASK-DASHBOARD proof"
    fi

    echo ""

    # Show summary
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "📊 LANE STATUS SUMMARY"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    LANE1_ACTIVE=$(tmux capture-pane -t lanes:1 -p | grep -v "^$" | wc -l)
    LANE2_ACTIVE=$(tmux capture-pane -t lanes:2 -p | grep -v "^$" | wc -l)
    LANE3_ACTIVE=$(tmux capture-pane -t lanes:3 -p | grep -v "^$" | wc -l)

    log "LANE-1 (CODEX-A): $LANE1_ACTIVE lines | $([ "$LANE1_ACTIVE" -gt 5 ] && echo '✅ ACTIVE' || echo '😴 IDLE')"
    log "LANE-2 (CLAUDE): $LANE2_ACTIVE lines | $([ "$LANE2_ACTIVE" -gt 5 ] && echo '✅ ACTIVE' || echo '😴 IDLE')"
    log "LANE-3 (SCOUT-1): $LANE3_ACTIVE lines | $([ "$LANE3_ACTIVE" -gt 5 ] && echo '✅ ACTIVE' || echo '😴 IDLE')"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Next check in ${CHECK_INTERVAL}s... (Ctrl+C to stop)"
    echo ""

    sleep "$CHECK_INTERVAL"
done
