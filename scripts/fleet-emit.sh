#!/bin/bash
# Fleet Status Broadcast Utility
# Shared emission function for all oracles to emit high-signal events

# oracle_emit ORACLE EVENT_TYPE MESSAGE [SEVERITY] [PROJECT] [DETAILS_JSON]
oracle_emit() {
  local oracle="$1"
  local event_type="$2"
  local message="$3"
  local severity="${4:-info}"
  local project="${5:-null}"
  local details="${6:-{}}"

  if [ -z "$oracle" ] || [ -z "$event_type" ] || [ -z "$message" ]; then
    echo "❌ oracle_emit: missing required args (oracle, event_type, message)" >&2
    return 1
  fi

  # Ensure we're in a git repo (need to find ψ/fleet/)
  local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$repo_root" ]; then
    echo "❌ oracle_emit: not in a git repository" >&2
    return 1
  fi

  local log_file="$repo_root/ψ/fleet/BROADCAST-LOG.ndjson"
  if [ ! -d "$(dirname "$log_file")" ]; then
    mkdir -p "$(dirname "$log_file")" 2>/dev/null
  fi

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Escape JSON strings (minimal: quotes, backslashes, newlines)
  message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/ /; s/ $//' | tr '\n' ' ')

  # Build JSON
  local json="{\"timestamp\":\"$timestamp\",\"oracle\":\"$oracle\",\"event_type\":\"$event_type\",\"project\":$project,\"message\":\"$message\",\"severity\":\"$severity\",\"tags\":[],\"details\":$details}"

  # Append (create file if missing, with flock to prevent concurrent writes)
  if command -v flock &>/dev/null; then
    (
      flock 9 || exit 1
      echo "$json" >> "$log_file"
    ) 9>"$log_file.lock"
    rm -f "$log_file.lock"
  else
    # Fallback: direct append (less safe but works offline)
    echo "$json" >> "$log_file"
  fi

  return 0
}

# Export for use in hooks
export -f oracle_emit
