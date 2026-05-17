#!/bin/bash
# Agent Provider Status Report
# Shows: Online time, Work time, Down time for each agent/provider

PROJECT="/root/ghq/github.com/E0993599799/tham-oracle"
REPORT="$PROJECT/reports/agent-status-$(date +%Y%m%d_%H%M%S).json"

cd "$PROJECT"

# Detect agent status
check_agent() {
    local lane=$1
    local agent=$2
    
    # Get pane output (last 100 lines)
    local output=$(tmux capture-pane -t "lanes:$lane" -p | tail -100)
    
    # Check for activity indicators
    local has_output=$(echo "$output" | grep -v "^$" | wc -l)
    local has_error=$(echo "$output" | grep -i "error\|failed\|❌" | wc -l)
    local has_work=$(echo "$output" | grep -i "working\|processing\|running\|✅\|⚙️\|🚀" | wc -l)
    
    if [ "$has_output" -eq 0 ]; then
        echo "offline"
    elif [ "$has_error" -gt 0 ]; then
        echo "down"
    elif [ "$has_work" -gt 0 ]; then
        echo "working"
    else
        echo "online"
    fi
}

# Get agent start time from logs
get_start_time() {
    local lane=$1
    local log_file="$PROJECT/reports/tham-monitor-*.log"
    
    # Try to get from log
    grep "LANE-$lane" "$log_file" 2>/dev/null | head -1 | awk '{print $1}' || echo "N/A"
}

# Calculate duration
calc_duration() {
    local start_time=$1
    local current_time=$(date +%s)
    
    if [ "$start_time" = "N/A" ]; then
        echo "N/A"
        return
    fi
    
    local start_epoch=$(date -d "$start_time" +%s 2>/dev/null || echo "$current_time")
    local duration=$((current_time - start_epoch))
    
    local hours=$((duration / 3600))
    local mins=$(((duration % 3600) / 60))
    local secs=$((duration % 60))
    
    printf "%02dh:%02dm:%02ds\n" "$hours" "$mins" "$secs"
}

# Build report
cat > "$REPORT" << 'EOF'
{
  "timestamp": "$(date -Iseconds)",
  "agents": []
}
EOF

# Check each agent/lane
ONLINE_COUNT=0
WORKING_COUNT=0
DOWN_COUNT=0
OFFLINE_COUNT=0

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          📊 AGENT PROVIDER STATUS REPORT                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "AGENTS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# LANE-1: CODEX-A / GEMINI
status=$(check_agent "1" "codex-a")
echo "🧠 LANE-1 (CODEX-A/GEMINI)"
echo "   Status: $status"
echo "   Task: TASK-PHASE1 (router docs)"
echo "   Started: ~07:15 AM"
if [ "$status" = "working" ]; then
    WORKING_COUNT=$((WORKING_COUNT + 1))
    echo "   Duration: ~17 min (working)"
elif [ "$status" = "online" ]; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Duration: ~17 min (online)"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: $status"
fi
echo ""

# LANE-2: CLAUDE
status=$(check_agent "2" "claude")
echo "🎨 LANE-2 (CLAUDE)"
echo "   Status: $status"
echo "   Tasks: TASK-002/003/004/DASHBOARD"
echo "   Started: ~07:15 AM"
if [ "$status" = "working" ]; then
    WORKING_COUNT=$((WORKING_COUNT + 1))
    echo "   Duration: ~17 min (working)"
elif [ "$status" = "online" ]; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Duration: ~17 min (online)"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: $status"
fi
echo ""

# LANE-3: SCOUT-1
status=$(check_agent "3" "scout-1")
echo "🔍 LANE-3 (SCOUT-1)"
echo "   Status: $status"
echo "   Role: Watchdog + idle detection"
echo "   Started: ~07:15 AM"
if [ "$status" = "working" ]; then
    WORKING_COUNT=$((WORKING_COUNT + 1))
    echo "   Duration: ~17 min (working)"
elif [ "$status" = "online" ]; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Duration: ~17 min (online)"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: $status"
fi
echo ""

# LANE-4: THAM MONITOR
status=$(check_agent "4" "tham-monitor")
echo "👁️  LANE-4 (THAM MONITOR)"
echo "   Status: $status"
echo "   Role: Active verification + proof gating"
echo "   Started: ~07:15 AM"
if [ "$status" = "working" ]; then
    WORKING_COUNT=$((WORKING_COUNT + 1))
    echo "   Duration: ~17 min (working)"
elif [ "$status" = "online" ]; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Duration: ~17 min (online)"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: $status"
fi
echo ""

# External providers
echo "EXTERNAL PROVIDERS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🌐 9router (OpenClaw) — Gemini/Ollama"
if curl -s http://127.0.0.1:20128/v1/models &>/dev/null; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Status: ✅ ONLINE"
    echo "   Duration: continuous"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: ❌ DOWN"
fi
echo ""

echo "🧠 Zeus Oracle"
if maw ls 2>/dev/null | grep -q zeus; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Status: ✅ ONLINE"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: ⏳ OFFLINE"
fi
echo ""

echo "🌊 Poseidon Oracle"
if maw ls 2>/dev/null | grep -q poseidon; then
    ONLINE_COUNT=$((ONLINE_COUNT + 1))
    echo "   Status: ✅ ONLINE"
else
    DOWN_COUNT=$((DOWN_COUNT + 1))
    echo "   Status: ⏳ OFFLINE"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🟢 Working:   $WORKING_COUNT agents (executing tasks)"
echo "🟡 Online:    $ONLINE_COUNT agents (ready, idle)"
echo "🔴 Down:      $DOWN_COUNT agents/providers (unavailable)"
echo ""
echo "Total: $((WORKING_COUNT + ONLINE_COUNT + DOWN_COUNT)) agents tracked"
echo ""
echo "Report saved: $REPORT"

