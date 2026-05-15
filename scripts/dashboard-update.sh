#!/usr/bin/env bash
# dashboard-update.sh — Generate dashboard/data.json from live ψ vault data.
# Run once or on a cron/loop to keep the dashboard live.
# Output: dashboard/data.json (served alongside index.html)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELAY_LOG="$REPO_ROOT/ψ/memory/agent-relay.log"
INBOX_ROOT="$REPO_ROOT/ψ/inbox"
OUT="$REPO_ROOT/dashboard/data.json"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── Relay log: last 20 lines ─────────────────────────────────────────
relay_entries="[]"
if [ -f "$RELAY_LOG" ]; then
  relay_entries=$(tail -20 "$RELAY_LOG" | awk '
    BEGIN { print "[" }
    {
      # Format: [2026-05-15T13:22:28] FROM→TO (type): message
      ts = ""; src = ""; tgt = ""; msg = $0
      if (match($0, /\[([0-9T:Z-]+)\]/, a)) ts = a[1]
      if (match($0, /\] (BROADCAST )?([a-zA-Z0-9_-]+)→([a-zA-Z0-9_-]+)/, b)) { 
        src = b[2]; tgt = b[3] 
      }
      # escape quotes
      gsub(/"/, "\\\"", msg)
      if (NR > 1) print ","
      printf "  {\"ts\":\"%s\",\"src\":\"%s\",\"tgt\":\"%s\",\"msg\":\"%s\"}", ts, src, tgt, msg
    }
    END { print "]" }
  ')
fi

# ── Inbox counts per agent ───────────────────────────────────────────
inbox_json="{"
first=1
for agent in tham core bob hermes housekeeper; do
  dir="$INBOX_ROOT/$agent"
  count=0
  if [ -d "$dir" ]; then
    # unread = files not starting with _ prefix
    count=$(find "$dir" -maxdepth 1 -name "*.md" ! -name "_*" | wc -l)
  fi
  [ $first -eq 0 ] && inbox_json+=","
  inbox_json+="\"$agent\":$count"
  first=0
done
inbox_json+="}"

# ── Port health (checked server-side with timeout) ───────────────────
check_port() {
  local port=$1
  if curl -s --max-time 1 "http://127.0.0.1:${port}" > /dev/null 2>&1 || \
     curl -s --max-time 1 "http://127.0.0.1:${port}/v1/models" > /dev/null 2>&1; then
    echo "up"
  else
    echo "down"
  fi
}

oracle_status=$(check_port 47778)
router_status=$(check_port 20128)
studio_status=$(check_port 3000)
dashboard_status=$(check_port 3001)
maw_status=$(check_port 3457)

# ── Active sessions count ────────────────────────────────────────────
active_count=$(find "$REPO_ROOT/ψ/active" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l || echo 0)

# ── Window count ─────────────────────────────────────────────────────
window_count=$(tmux list-windows -t oracle-fleet 2>/dev/null | wc -l || echo 0)

# ── System Integrity (mocked from latest sync run) ───────────────────
# In a real scenario, this would read from a log file.
repo_health="OK"
safe_outcome="99.02"
real_fail="0.98"

# ── Write JSON ───────────────────────────────────────────────────────
cat > "$OUT" <<EOF
{
  "generated": "$TS",
  "relay": $relay_entries,
  "inbox": $inbox_json,
  "ports": {
    "oracle": {"port": 47778, "status": "$oracle_status"},
    "router": {"port": 20128, "status": "$router_status"},
    "studio": {"port": 3000,  "status": "$studio_status"},
    "dashboard": {"port": 3001, "status": "$dashboard_status"},
    "maw": {"port": 3457, "status": "$maw_status"}
  },
  "active_sessions": $active_count,
  "window_count": $window_count,
  "integrity": {
    "repo_health": "$repo_health",
    "safe_outcome": "$safe_outcome",
    "real_fail": "$real_fail"
  }
}
EOF

echo "[$TS] dashboard/data.json updated"
