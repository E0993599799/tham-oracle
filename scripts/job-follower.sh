#!/bin/bash
# Job Follower — Track agent progress, alert on idle/stuck
# Prevents work from falling through the cracks

set -e

PROJECT="/root/ghq/github.com/E0993599799/tham-oracle"
FOLLOW_LOG="$PROJECT/reports/job-follower-$(date +%Y%m%d_%H%M%S).log"
IDLE_THRESHOLD=300  # 5 min idle = alert
CHECK_INTERVAL=60   # Check every 1 min

mkdir -p "$(dirname "$FOLLOW_LOG")"

cd "$PROJECT"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$FOLLOW_LOG"
}

alert() {
    echo "🚨 ALERT: $1" | tee -a "$FOLLOW_LOG"
}

track_job() {
    local lane=$1
    local task=$2
    local deadline=$3

    local output=$(tmux capture-pane -t "lanes:$lane" -p | tail -5 | grep -v "^$" | wc -l)
    local current_hour=$(date +%H)
    local current_min=$(date +%M)

    # Check if idle
    if [ "$output" -eq 0 ]; then
        alert "LANE-$lane ($task): NO OUTPUT — possible idle"
        return 1
    fi

    # Check deadline
    local deadline_hour=$(echo $deadline | cut -d: -f1)
    local deadline_min=$(echo $deadline | cut -d: -f2)
    local current_secs=$((current_hour * 3600 + current_min * 60))
    local deadline_secs=$((deadline_hour * 3600 + deadline_min * 60))

    if [ "$current_secs" -gt "$deadline_secs" ]; then
        alert "LANE-$lane ($task): DEADLINE PASSED ($deadline)"
        return 1
    fi

    local mins_until=$((($deadline_secs - $current_secs) / 60))
    log "✅ LANE-$lane ($task): ACTIVE | Deadline: ${mins_until}m remaining"
    return 0
}

# Main tracking loop
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "📋 JOB FOLLOWER — Tracking agent progress"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ITERATION=0
ALERTS=0

while true; do
    ITERATION=$((ITERATION + 1))
    clear

    cat << "HEADER"
╔════════════════════════════════════════════════════════════╗
║          📋 JOB FOLLOWER — Progress Tracking              ║
╚════════════════════════════════════════════════════════════╝

HEADER

    log "Iteration #$ITERATION | $(date '+%H:%M:%S')"

    # Track each lane
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "📊 LANE PROGRESS CHECK"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # LANE-1: TASK-PHASE1 (deadline 11:00)
    if ! track_job "1" "TASK-PHASE1" "11:00"; then
        ALERTS=$((ALERTS + 1))
    fi

    # LANE-2: TASK queue (deadline 09:30)
    if ! track_job "2" "TASK-queue" "09:30"; then
        ALERTS=$((ALERTS + 1))
    fi

    # LANE-3: SCOUT-1 (always running)
    if ! track_job "3" "SCOUT-1" "23:59"; then
        ALERTS=$((ALERTS + 1))
    fi

    # LANE-4: THAM MONITOR (always running)
    if ! track_job "4" "THAM-MONITOR" "23:59"; then
        ALERTS=$((ALERTS + 1))
    fi

    # Check for proof files
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "📋 PROOF STATUS CHECK"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    for task in TASK-001 TASK-PHASE1 TASK-DASHBOARD TASK-002 TASK-003 TASK-004; do
        if [ -f "$PROJECT/reports/${task}-proof.json" ]; then
            log "✅ $task: Proof ready"
        else
            log "⏳ $task: Waiting for proof"
        fi
    done

    # Summary
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "📊 SUMMARY"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Iterations: $ITERATION"
    log "Alerts: $ALERTS"

    if [ "$ALERTS" -gt 0 ]; then
        log "⚠️  ESCALATE: Check lanes for stuck/idle work"
    fi

    log "Next check: ${CHECK_INTERVAL}s"
    echo ""
    sleep "$CHECK_INTERVAL"
done
