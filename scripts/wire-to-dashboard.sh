#!/bin/bash
# Wire Task Proofs to Dashboard
# Pushes task completion + proof results → live dashboard update

set -e

PROJECT="/root/ghq/github.com/E0993599799/tham-oracle"
DASHBOARD_STATE="$PROJECT/dashboard/state.json"
PROOF_DIR="$PROJECT/reports"

cd "$PROJECT"

# Initialize dashboard state file if not exists
if [ ! -f "$DASHBOARD_STATE" ]; then
    mkdir -p "$(dirname "$DASHBOARD_STATE")"
    cat > "$DASHBOARD_STATE" << 'EOF'
{
  "orchestration": {
    "status": "active",
    "start_time": "2026-05-17T07:00:00Z",
    "lanes": {
      "tham": { "status": "active", "role": "orchestrator" },
      "lane_1": { "status": "active", "role": "codex-a", "task": "TASK-PHASE1", "progress": 0 },
      "lane_2": { "status": "active", "role": "claude", "tasks": ["TASK-002", "TASK-003", "TASK-004", "TASK-DASHBOARD"], "progress": 0 },
      "lane_3": { "status": "active", "role": "scout-1", "task": "monitor" },
      "lane_4": { "status": "active", "role": "tham-monitor", "task": "verify" }
    }
  },
  "tasks": {},
  "proofs": [],
  "last_update": "2026-05-17T07:00:00Z"
}
EOF
    echo "✅ Dashboard state initialized"
fi

# Wire proof to dashboard
wire_proof() {
    local task_id=$1
    local proof_file=$2
    local status=$3  # APPROVED, PENDING, FAILED

    if [ ! -f "$proof_file" ]; then
        echo "❌ Proof file not found: $proof_file"
        return 1
    fi

    echo "📍 Wiring $task_id → dashboard"

    # Read proof content
    local proof_content=$(cat "$proof_file")

    # Update dashboard state with new proof
    local temp_state=$(mktemp)
    jq \
        --arg task_id "$task_id" \
        --arg status "$status" \
        --arg proof "$(echo "$proof_content" | jq -c .)" \
        '.tasks[$task_id] = {
            "id": $task_id,
            "status": $status,
            "proof": ($proof | fromjson),
            "wired_at": now | todate
        } |
        .proofs += [{
            "task_id": $task_id,
            "status": $status,
            "timestamp": now | todate
        }] |
        .last_update = (now | todate)' \
        "$DASHBOARD_STATE" > "$temp_state"

    mv "$temp_state" "$DASHBOARD_STATE"

    echo "✅ Wired $task_id to dashboard"

    # Display updated state
    jq ".tasks[$task_id]" "$DASHBOARD_STATE"
}

# Update lane progress
update_lane_progress() {
    local lane_id=$1
    local progress=$2  # 0-100

    local temp_state=$(mktemp)
    jq \
        --arg lane_id "$lane_id" \
        --arg progress "$progress" \
        '.lanes[$lane_id].progress = ($progress | tonumber) |
        .last_update = (now | todate)' \
        "$DASHBOARD_STATE" > "$temp_state"

    mv "$temp_state" "$DASHBOARD_STATE"

    echo "📈 Updated $lane_id progress: $progress%"
}

# Check for new proofs and wire them
check_and_wire_proofs() {
    echo "🔍 Checking for new proofs..."

    if [ ! -d "$PROOF_DIR" ]; then
        echo "⏳ No proofs directory yet"
        return
    fi

    # Check for TASK-001 proof
    if [ -f "$PROOF_DIR/TASK-001-proof.json" ]; then
        wire_proof "TASK-001" "$PROOF_DIR/TASK-001-proof.json" "APPROVED"
    fi

    # Check for TASK-PHASE1 proof
    if [ -f "$PROOF_DIR/TASK-PHASE1-proof.json" ]; then
        wire_proof "TASK-PHASE1" "$PROOF_DIR/TASK-PHASE1-proof.json" "APPROVED"
    fi

    # Check for TASK-DASHBOARD proof
    if [ -f "$PROOF_DIR/TASK-DASHBOARD-proof.json" ]; then
        wire_proof "TASK-DASHBOARD" "$PROOF_DIR/TASK-DASHBOARD-proof.json" "APPROVED"
    fi
}

# Main dashboard wire loop
if [ "$1" = "loop" ]; then
    echo "🔌 WIRE-TO-DASHBOARD Loop (every 30s)"
    while true; do
        clear
        echo "🔌 Wire-to-Dashboard Monitor"
        echo "   $(date '+%H:%M:%S')"
        echo ""
        check_and_wire_proofs
        echo ""
        echo "Dashboard state:"
        jq . "$DASHBOARD_STATE" | head -40
        echo ""
        echo "Next check: 30s"
        sleep 30
    done
else
    # One-shot check
    check_and_wire_proofs
    echo ""
    echo "Current dashboard state:"
    jq . "$DASHBOARD_STATE"
fi
