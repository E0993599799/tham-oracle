#!/bin/bash
##
## Phase 3A: Execution Lane Health Check
## Real-time health status of all 6 execution lanes
## Pure bash JSON generation (no jq, no python)
##
## Usage: ./scripts/router-health-check.sh
## Output: JSON to stdout + proofs/YYYY-MM-DD/lane-health-*.json
##

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PROOFS_DIR="${PROJECT_ROOT}/proofs/$(date +%Y-%m-%d)"

# Ensure proofs directory exists
mkdir -p "$PROOFS_DIR"

# Configuration: Lane endpoints
declare -A LANES=(
    [codex_gpt55]="http://localhost:20128/v1/completions"
    [claude]="http://localhost:20128/v1/messages"
    [gemini]="http://localhost:20128/v1/completions"
    [ollama]="http://localhost:11434/api/generate"
    [hermes]="http://localhost:11434/api/generate"
)

# Persistent state file for tracking success rates (plain text format)
STATE_FILE="/tmp/lane-health-state.txt"
if [[ ! -f "$STATE_FILE" ]]; then
    touch "$STATE_FILE"
fi

##
## Helper: Escape JSON string
##
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"  # backslash
    s="${s//\"/\\\"}"  # quotes
    s="${s//$'\t'/\\t}"  # tabs
    s="${s//$'\n'/\\n}"  # newlines
    s="${s//$'\r'/\\r}"  # carriage returns
    printf '%s' "$s"
}

##
## Helper: Probe a single lane
##
probe_lane() {
    local lane=$1
    local endpoint=$2
    local timeout=2

    local start_time=$(date +%s%3N)
    local http_code
    local response_time_ms=0

    # Special case: PowerShell direct execution is always healthy
    if [[ "$lane" == "powershell_sfsr" ]]; then
        echo "healthy|0|200|true"
        return 0
    fi

    # HTTP probe with timeout
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout "$timeout" \
        --max-time "$timeout" \
        "$endpoint" 2>/dev/null || echo "000")

    local end_time=$(date +%s%3N)
    response_time_ms=$((end_time - start_time))

    # Determine success based on HTTP code
    local success="false"
    if [[ "$http_code" =~ ^[2][0-9][0-9]$ ]]; then
        success="true"
    fi

    echo "ok|$response_time_ms|$http_code|$success"
}

##
## Helper: Get rolling success rate (last 10 probes)
##
get_success_rate() {
    local lane=$1

    # Read state for this lane (format: lane:probe1,probe2,probe3,...)
    local state_line=$(grep "^${lane}:" "$STATE_FILE" 2>/dev/null || echo "")
    local history=""

    if [[ -n "$state_line" ]]; then
        history="${state_line#${lane}:}"
    fi

    # Parse history: count successes
    if [[ -z "$history" ]]; then
        echo 0
        return
    fi

    IFS=',' read -ra probes <<< "$history"
    local total=${#probes[@]}
    local success_count=0

    for probe in "${probes[@]}"; do
        [[ "$probe" == "true" ]] && ((success_count++))
    done

    if [[ $total -eq 0 ]]; then
        echo 0
    else
        echo $((success_count * 100 / total))
    fi
}

##
## Helper: Update rolling success rate
##
update_success_rate() {
    local lane=$1
    local is_success=$2

    # Get existing history
    local state_line=$(grep "^${lane}:" "$STATE_FILE" 2>/dev/null || echo "")
    local history=""

    if [[ -n "$state_line" ]]; then
        history="${state_line#${lane}:}"
    fi

    # Add new result
    if [[ -z "$history" ]]; then
        history="$is_success"
    else
        history="${history},$is_success"
    fi

    # Keep only last 10 results
    IFS=',' read -ra probes <<< "$history"
    if [[ ${#probes[@]} -gt 10 ]]; then
        probes=("${probes[@]: -10}")
        history=$(IFS=','; echo "${probes[*]}")
    fi

    # Update state file (remove old line, add new)
    grep -v "^${lane}:" "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null || true
    mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "${lane}:${history}" >> "$STATE_FILE"

    # Return success rate
    get_success_rate "$lane"
}

##
## Helper: Format JSON string
##
to_json_string() {
    printf '"%s"' "$(json_escape "$1")"
}

##
## Main: Collect health for all lanes
##
main() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local lanes_json=""
    local first_lane=true

    # Always include PowerShell as a lane (direct execution, always OK)
    LANES[powershell_sfsr]="local_direct_execution"

    echo "Probing ${#LANES[@]} execution lanes..." >&2

    for lane in "${!LANES[@]}"; do
        local endpoint="${LANES[$lane]}"
        local probe_result
        local response_time_ms
        local http_code
        local is_success
        local status

        echo -n "  → $lane... " >&2

        probe_result=$(probe_lane "$lane" "$endpoint")
        IFS='|' read -r _ response_time_ms http_code is_success <<< "$probe_result"

        # Determine health status
        if [[ "$is_success" == "true" ]]; then
            if [[ $response_time_ms -lt 1000 ]]; then
                status="healthy"
            else
                status="degraded"
            fi
            echo "✓ $status ($response_time_ms ms)" >&2
        else
            status="offline"
            echo "✗ offline" >&2
        fi

        # Update rolling success rate
        success_rate=$(update_success_rate "$lane" "$is_success")

        # Get last heartbeat
        local last_heartbeat="never"
        if [[ "$is_success" == "true" ]]; then
            last_heartbeat="$timestamp"
        fi

        # Build lane record (pure bash JSON)
        # Strip leading zeros from http_code for valid JSON
        http_code=$((10#$http_code))
        local lane_record="\"$lane\":{\"status\":\"$status\",\"response_time_ms\":$response_time_ms,\"success_rate_pct\":$success_rate,\"last_heartbeat\":$(to_json_string "$last_heartbeat"),\"http_code\":$http_code}"

        if [[ "$first_lane" == true ]]; then
            lanes_json="$lane_record"
            first_lane=false
        else
            lanes_json="${lanes_json},$lane_record"
        fi
    done

    # Final output (pure bash JSON)
    local output="{\"timestamp\":$(to_json_string "$timestamp"),\"lane_count\":${#LANES[@]},\"lanes\":{$lanes_json}}"

    # Save proof file
    local proof_file="${PROOFS_DIR}/lane-health-$(date +%Y%m%d-%H%M%S).json"
    echo "$output" > "$proof_file"
    echo "Proof saved: $proof_file" >&2

    # Output to stdout with pretty-printing
    echo "$output" | python3 -m json.tool 2>/dev/null || echo "$output"
}

main "$@"
