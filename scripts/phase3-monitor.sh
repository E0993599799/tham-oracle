#!/usr/bin/env bash
# Real-time Phase 3 progress monitor
# Shows both codex lanes reporting their progress

REPO="/root/ghq/github.com/E0993599799/tham-oracle"
LOG_DIR="$REPO/logs"
STATUS_FILE="$REPO/.phase3-status.json"

mkdir -p "$LOG_DIR"

echo "═══════════════════════════════════════════════════════════════════════════"
echo "                 PHASE 3 PARALLEL EXECUTION MONITOR"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Started: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

# Initialize status
cat > "$STATUS_FILE" << 'STATUS_EOF'
{
  "phase": 3,
  "status": "RUNNING",
  "start_time": "2026-05-17T06:00:00+07:00",
  "lanes": {
    "codex_gpt55": {
      "name": "Codex GPT-55",
      "subtasks": ["3A_health_check", "3B_dashboard"],
      "status": "RUNNING",
      "progress": 0
    },
    "codellama": {
      "name": "Codellama",
      "subtasks": ["3C_aggregator", "3D_daily_summary"],
      "status": "RUNNING",
      "progress": 0
    }
  }
}
STATUS_EOF

# Monitor loop
ITERATION=0
while [ $ITERATION -lt 300 ]; do
  ITERATION=$((ITERATION + 1))
  ELAPSED=$((ITERATION * 2))
  
  clear
  
  echo "═══════════════════════════════════════════════════════════════════════════"
  echo "                 PHASE 3 PARALLEL EXECUTION MONITOR"
  echo "═══════════════════════════════════════════════════════════════════════════"
  echo ""
  echo "Elapsed: ${ELAPSED}s / Expected: 3600s"
  echo "Time: $(date '+%H:%M:%S')"
  echo ""
  
  # Check agent output files
  CODEX_OUTPUT="/tmp/claude-0/-root-ghq-github-com-E0993599799-tham-oracle/b0bfd1db-ea41-4b81-9c69-cc72a99dc4b5/tasks/a2f33a5d9d1b555c4.output"
  CODELLAMA_OUTPUT="/tmp/claude-0/-root-ghq-github-com-E0993599799-tham-oracle/b0bfd1db-ea41-4b81-9c69-cc72a99dc4b5/tasks/a114ba25abebaf1aa.output"
  
  # Codex GPT-55 Status
  echo "┌─ Codex GPT-55 Lane (3A + 3B) ─────────────────────────────────────┐"
  if [ -f "$CODEX_OUTPUT" ]; then
    CODEX_SIZE=$(wc -c < "$CODEX_OUTPUT" 2>/dev/null || echo 0)
    CODEX_LINES=$(wc -l < "$CODEX_OUTPUT" 2>/dev/null || echo 0)
    PROGRESS=$((ELAPSED / 36)) # ~60 min expected
    [ $PROGRESS -gt 100 ] && PROGRESS=100
    echo "│ Status: ACTIVE"
    echo "│ Output size: $CODEX_SIZE bytes ($CODEX_LINES lines)"
    echo "│ Progress: $PROGRESS%"
    # Show bar
    BAR=""
    for ((i=0; i<10; i++)); do
      [ $i -lt $((PROGRESS / 10)) ] && BAR="$BAR█" || BAR="$BAR░"
    done
    echo "│ [$BAR]"
    echo "│"
    echo "│ 3A: router-health-check.sh"
    [ -f "$REPO/scripts/router-health-check.sh" ] && echo "│    ✅ CREATED" || echo "│    ⏳ IN PROGRESS"
    echo "│"
    echo "│ 3B: lane-health.html"
    [ -f "$REPO/dashboard/lane-health.html" ] && echo "│    ✅ CREATED" || echo "│    ⏳ IN PROGRESS"
  else
    echo "│ ⏳ Initializing..."
  fi
  echo "└────────────────────────────────────────────────────────────────────┘"
  echo ""
  
  # Codellama Status
  echo "┌─ Codellama Lane (3C + 3D) ─────────────────────────────────────────┐"
  if [ -f "$CODELLAMA_OUTPUT" ]; then
    LLAMA_SIZE=$(wc -c < "$CODELLAMA_OUTPUT" 2>/dev/null || echo 0)
    LLAMA_LINES=$(wc -l < "$CODELLAMA_OUTPUT" 2>/dev/null || echo 0)
    PROGRESS=$((ELAPSED / 36)) # ~60 min expected
    [ $PROGRESS -gt 100 ] && PROGRESS=100
    echo "│ Status: ACTIVE"
    echo "│ Output size: $LLAMA_SIZE bytes ($LLAMA_LINES lines)"
    echo "│ Progress: $PROGRESS%"
    # Show bar
    BAR=""
    for ((i=0; i<10; i++)); do
      [ $i -lt $((PROGRESS / 10)) ] && BAR="$BAR█" || BAR="$BAR░"
    done
    echo "│ [$BAR]"
    echo "│"
    echo "│ 3C: proof-aggregator.py"
    [ -f "$REPO/scripts/proof-aggregator.py" ] && echo "│    ✅ CREATED" || echo "│    ⏳ IN PROGRESS"
    echo "│"
    echo "│ 3D: router-daily-summary.sh"
    [ -f "$REPO/scripts/router-daily-summary.sh" ] && echo "│    ✅ CREATED" || echo "│    ⏳ IN PROGRESS"
  else
    echo "│ ⏳ Initializing..."
  fi
  echo "└────────────────────────────────────────────────────────────────────┘"
  echo ""
  
  # Summary
  echo "═══════════════════════════════════════════════════════════════════════════"
  CODEX_DONE=0
  LLAMA_DONE=0
  [ -f "$REPO/scripts/router-health-check.sh" ] && [ -f "$REPO/dashboard/lane-health.html" ] && CODEX_DONE=1
  [ -f "$REPO/scripts/proof-aggregator.py" ] && [ -f "$REPO/scripts/router-daily-summary.sh" ] && LLAMA_DONE=1
  
  if [ $CODEX_DONE -eq 1 ] && [ $LLAMA_DONE -eq 1 ]; then
    echo "✅ PHASE 3 COMPLETE — All 4 deliverables ready!"
    break
  fi
  
  sleep 2
done

if [ $CODEX_DONE -eq 1 ] && [ $LLAMA_DONE -eq 1 ]; then
  echo ""
  echo "✅ Phase 3 execution complete at $(date '+%H:%M:%S')"
  echo "📁 Deliverables:"
  ls -lh "$REPO/scripts/router-health-check.sh" "$REPO/dashboard/lane-health.html" \
         "$REPO/scripts/proof-aggregator.py" "$REPO/scripts/router-daily-summary.sh" 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}'
fi
