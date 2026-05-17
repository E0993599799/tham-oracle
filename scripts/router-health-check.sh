#!/bin/bash
# Phase 3A: Router Health Check — Poll lanes, output JSON health record
# Usage: bash scripts/router-health-check.sh
# Output: JSON health record → proofs/YYYY-MM-DD/lane-health-YYYY-MM-DD-HHmmss.json

set -e

REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
PROOFS_DIR="$REPO_ROOT/proofs"
TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TIMESTAMP_FILE=$(date +%s)

# Ensure proofs directory exists
mkdir -p "$PROOFS_DIR/$TODAY"

# ============================================================================
# Lane Configuration
# ============================================================================

declare -A LANES=(
    ["codex_gpt55"]="http://127.0.0.1:20128/v1"
    ["claude"]="http://127.0.0.1:20128/v1"
    ["gemini"]="http://127.0.0.1:20128/v1"
    ["ollama"]="http://127.0.0.1:20128/v1"
    ["hermes"]="http://127.0.0.1:20128/v1"
    ["powershell_sfsr"]="local"
)

# ============================================================================
# Helper Functions
# ============================================================================

health_check_lane() {
    local lane_id=$1
    local base_url=$2
    local start_time=$(date +%s%3N)

    if [ "$base_url" = "local" ]; then
        # Local lane always available
        echo "HEALTHY,0,100.0,$(date -u +%Y-%m-%dT%H:%M:%SZ),CLOSED"
        return
    fi

    # HTTP health check
    local response_time=0
    local status="down"
    local success_rate=50.0
    local circuit_breaker="OPEN"

    if timeout 2 curl -s -I "$base_url/models" >/dev/null 2>&1; then
        local end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))
        success_rate=$(get_lane_success_rate "$lane_id")
        circuit_breaker="CLOSED"

        if [ $response_time -lt 200 ]; then
            status="healthy"
        elif [ $response_time -lt 500 ]; then
            status="degraded"
        else
            status="down"
        fi
    else
        response_time=5000
    fi

    echo "$status,$response_time,$success_rate,$(date -u +%Y-%m-%dT%H:%M:%SZ),$circuit_breaker"
}

get_lane_success_rate() {
    local lane_id=$1
    # Count successful proofs for this lane from today's files
    local total=0
    local successful=0

    if [ -d "$PROOFS_DIR/$TODAY" ]; then
        total=$(find "$PROOFS_DIR/$TODAY" -name "*.json" -type f 2>/dev/null | wc -l)
        if [ $total -gt 0 ]; then
            successful=$(grep -l "\"routed_lane\": \"$lane_id\"" "$PROOFS_DIR/$TODAY"/*.json 2>/dev/null | \
                         xargs grep -l "\"status\": \"SUCCESS\"" 2>/dev/null | wc -l)
        fi
    fi

    if [ $total -eq 0 ]; then
        echo "100.0"
    else
        awk "BEGIN {printf \"%.1f\", (($successful / $total) * 100)}"
    fi
}

# ============================================================================
# Main Health Check
# ============================================================================

echo "🔍 Router Health Check — $(date)"
echo ""

# Start JSON output
HEALTH_JSON="{"
HEALTH_JSON+="\n  \"timestamp\": \"$TIMESTAMP\","
HEALTH_JSON+="\n  \"health_check_duration_ms\": 0,"
HEALTH_JSON+="\n  \"lanes\": ["

first=true
for lane_id in "${!LANES[@]}"; do
    base_url="${LANES[$lane_id]}"

    IFS=',' read -r status response_time success_rate heartbeat circuit_breaker <<< \
        "$(health_check_lane "$lane_id" "$base_url")"

    # Add comma separator
    if [ "$first" = false ]; then
        HEALTH_JSON+=","
    fi
    first=false

    # Append lane record
    HEALTH_JSON+="\n    {"
    HEALTH_JSON+="\n      \"lane_id\": \"$lane_id\","
    HEALTH_JSON+="\n      \"status\": \"$status\","
    HEALTH_JSON+="\n      \"response_time_ms\": $response_time,"
    HEALTH_JSON+="\n      \"success_rate_pct\": $success_rate,"
    HEALTH_JSON+="\n      \"last_heartbeat\": \"$heartbeat\","
    HEALTH_JSON+="\n      \"circuit_breaker_state\": \"$circuit_breaker\""
    HEALTH_JSON+="\n    }"

    # Print status
    case "$status" in
        "healthy")
            echo "  ✓ $lane_id — healthy ($response_time ms, ${success_rate}%)"
            ;;
        "degraded")
            echo "  ⚠ $lane_id — degraded ($response_time ms, ${success_rate}%)"
            ;;
        *)
            echo "  ✗ $lane_id — down"
            ;;
    esac
done

# Close JSON
HEALTH_JSON+="\n  ]"
HEALTH_JSON+="\n}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Write to file
HEALTH_FILE="$PROOFS_DIR/$TODAY/lane-health-${TODAY}-${TIMESTAMP_FILE}.json"
echo -e "$HEALTH_JSON" > "$HEALTH_FILE"

# Output to stdout (for dashboard)
echo -e "$HEALTH_JSON"

echo ""
echo "✅ Health check written to: $HEALTH_FILE"
