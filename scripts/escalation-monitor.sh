#!/bin/bash
# Escalation Monitor — Aggressive idle detection + wake-up
# Runs every 2 minutes, escalates stalled agents

PROJECT="/root/ghq/github.com/E0993599799/tham-oracle"
ESCALATION_LOG="$PROJECT/reports/escalation-$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$(dirname "$ESCALATION_LOG")"
cd "$PROJECT"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$ESCALATION_LOG"
}

escalate() {
    local lane=$1
    local reason=$2
    local severity=$3

    log "🚨 ESCALATION ($severity): LANE-$lane — $reason"

    # Send wake-up command
    tmux send-keys -t "lanes:$lane" "echo '🚨 ESCALATION: $reason — START WORKING NOW'" Enter

    # Log escalation
    echo "ESCALATED: $lane @ $(date '+%H:%M:%S') — $reason" >> "$ESCALATION_LOG"
}

check_lane_activity() {
    local lane=$1
    local lane_name=$2

    # Get recent output
    local output=$(tmux capture-pane -t "lanes:$lane" -p | tail -20 | grep -v "^$" | wc -l)

    if [ "$output" -lt 3 ]; then
        # Very low activity = escalate
        escalate "$lane" "$lane_name: No activity detected" "CRITICAL"
        return 1
    else
        log "✅ LANE-$lane ($lane_name): ACTIVE ($output lines)"
        return 0
    fi
}

check_proof_deadlines() {
    local current_hour=$(date +%H)
    local current_min=$(date +%M)

    # TASK-001: deadline 08:00
    if [ "$current_hour" -ge 8 ] && [ "$current_hour" -lt 9 ]; then
        if [ ! -f "$PROJECT/reports/TASK-001-proof.json" ]; then
            escalate "1" "TASK-001 deadline approaching (08:00) — NO PROOF" "CRITICAL"
        fi
    fi

    # TASK-PHASE1: deadline 11:00
    if [ "$current_hour" -ge 11 ]; then
        if [ ! -f "$PROJECT/reports/TASK-PHASE1-proof.json" ]; then
            escalate "1" "TASK-PHASE1 DEADLINE PASSED (11:00)" "CRITICAL"
        fi
    fi
}

# Main escalation loop
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🚨 ESCALATION MONITOR — Active idle detection"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ITERATION=0

while true; do
    ITERATION=$((ITERATION + 1))

    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       🚨 ESCALATION MONITOR — Iteration $ITERATION              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    log "Iteration #$ITERATION | $(date '+%H:%M:%S')"

    # Check each lane
    echo "🔍 CHECKING LANES..."
    echo ""

    check_lane_activity "1" "CODEX-A"
    check_lane_activity "2" "CLAUDE"
    check_lane_activity "3" "SCOUT-1"
    check_lane_activity "4" "THAM-MONITOR"

    echo ""

    # Check deadlines
    echo "⏰ CHECKING DEADLINES..."
    check_proof_deadlines

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Log: $ESCALATION_LOG"
    echo "Next check: 2 min"

    sleep 120
done
