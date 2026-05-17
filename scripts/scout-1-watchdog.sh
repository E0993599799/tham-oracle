#!/bin/bash
# Scout 1 — Activity Monitor + Agent Awakener
# Monitors agent activity, countdown timer, pulls tasks from Core inbox

set -e

PROJECT="/root/ghq/github.com/E0993599799/tham-oracle"
IDLE_TIMEOUT=300  # 5 minutes = 300 seconds
CHECK_INTERVAL=10  # Check every 10 seconds
LAST_ACTIVITY=$(date +%s)
IDLE_SINCE=""

cd "$PROJECT"

echo "🔍 Scout 1 — Agent Watchdog"
echo "   Monitoring: GEMINI (LANE-1), CLAUDE (LANE-2)"
echo "   Idle timeout: ${IDLE_TIMEOUT}s"
echo "   Check interval: ${CHECK_INTERVAL}s"
echo ""

# Check if Core is available
echo "🔗 Checking Core connection..."
if [ -d "$HOME/omega-oracle" ] || [ -d "D:/Git/omega-oracle" ]; then
    CORE_AVAILABLE="✅ AVAILABLE"
    CORE_PATH=$(find "$HOME" "D:" -name "omega-oracle" -type d 2>/dev/null | head -1)
else
    CORE_AVAILABLE="⏳ NOT DETECTED"
    CORE_PATH=""
fi

echo "   Core status: $CORE_AVAILABLE"
if [ -n "$CORE_PATH" ]; then
    echo "   Core path: $CORE_PATH"
fi
echo ""

# Monitor loop
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - LAST_ACTIVITY))

    # Check agent activity via tmux
    LANE1_OUTPUT=$(tmux capture-pane -t lanes:1 -p 2>/dev/null | tail -5 | grep -v "^$" | wc -l)
    LANE2_OUTPUT=$(tmux capture-pane -t lanes:2 -p 2>/dev/null | tail -5 | grep -v "^$" | wc -l)

    ACTIVITY=$((LANE1_OUTPUT + LANE2_OUTPUT))

    if [ "$ACTIVITY" -gt 0 ]; then
        # Agents are active
        LAST_ACTIVITY=$CURRENT_TIME
        IDLE_SINCE=""
        STATUS="✅ ACTIVE"
        COUNTDOWN=""
    else
        # Agents idle
        if [ -z "$IDLE_SINCE" ]; then
            IDLE_SINCE=$CURRENT_TIME
        fi

        IDLE_ELAPSED=$((CURRENT_TIME - IDLE_SINCE))
        REMAINING=$((IDLE_TIMEOUT - IDLE_ELAPSED))

        if [ "$REMAINING" -le 0 ]; then
            STATUS="⚠️  IDLE → WAKE UP"
            COUNTDOWN="NOW!"
        else
            STATUS="😴 IDLE"
            COUNTDOWN="Waking in ${REMAINING}s"
        fi
    fi

    # Display status
    clear
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║          🔍 SCOUT 1 — AGENT WATCHDOG                      ║
╚════════════════════════════════════════════════════════════╝

EOF

    echo "⏰ Time: $(date '+%H:%M:%S')"
    echo "🧠 THAM: Orchestrator active"
    echo "⚡ GEMINI (LANE-1): $STATUS"
    echo "🎨 CLAUDE (LANE-2): $STATUS"
    echo "   $COUNTDOWN"
    echo ""
    echo "🔗 Core Status: $CORE_AVAILABLE"
    if [ -n "$CORE_PATH" ]; then
        echo "   Inbox path: $CORE_PATH/inbox/"
        # Check for pending tasks
        if [ -d "$CORE_PATH/inbox" ]; then
            TASK_COUNT=$(find "$CORE_PATH/inbox" -type f 2>/dev/null | wc -l)
            if [ "$TASK_COUNT" -gt 0 ]; then
                echo "   📋 Pending tasks: $TASK_COUNT"
            fi
        fi
    fi
    echo ""
    echo "📊 Activity Check:"
    echo "   LANE-1 updates: $LANE1_OUTPUT"
    echo "   LANE-2 updates: $LANE2_OUTPUT"
    echo "   Total activity: $ACTIVITY"
    echo ""

    # Wake up if idle timeout reached
    if [ "$STATUS" = "⚠️  IDLE → WAKE UP" ]; then
        echo "🚨 WAKING AGENTS..."

        # Send wake signal to lanes
        tmux send-keys -t lanes:1 "# Scout 1: Wake up! Check tasks" Enter
        tmux send-keys -t lanes:2 "# Scout 1: Wake up! Check tasks" Enter

        # Pull tasks from Core inbox if available
        if [ -n "$CORE_PATH" ] && [ -d "$CORE_PATH/inbox" ]; then
            echo "📥 Pulling tasks from Core inbox..."
            INBOX_TASKS=$(find "$CORE_PATH/inbox" -type f -name "*.json" 2>/dev/null)
            if [ -n "$INBOX_TASKS" ]; then
                echo "$INBOX_TASKS" | head -3
            fi
        fi

        # Reset idle counter
        IDLE_SINCE=""
        LAST_ACTIVITY=$(date +%s)
    fi

    echo ""
    echo "Next check: ${CHECK_INTERVAL}s"
    sleep "$CHECK_INTERVAL"
done
