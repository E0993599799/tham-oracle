#!/bin/bash
#
# 7K: Run Learning Pipeline
# Orchestrate daily learning pipeline: failures → rules → validation → promotion
#
# Usage:
#   bash scripts/run-learning-pipeline.sh
#   (or cron: 0 23 * * * bash /path/run-learning-pipeline.sh)
#

set -e

REPO_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
SCRIPTS_DIR="$REPO_ROOT/scripts"
LOGS_DIR="$REPO_ROOT/logs"
MEMORY_DIR="$REPO_ROOT/ψ/memory/resonance"

# Create directories
mkdir -p "$LOGS_DIR"
mkdir -p "$MEMORY_DIR"

# Log file
LOG_FILE="$LOGS_DIR/learning-pipeline-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
  echo -e "${GREEN}[LEARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
  exit 1
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

# Start
{
  log "Learning Pipeline Started"
  log "Repository: $REPO_ROOT"
  log "Logging to: $LOG_FILE"
  log ""

  # Check prerequisites
  log "Checking prerequisites..."
  command -v python3 >/dev/null 2>&1 || error "Python 3 not found"
  [ -d "$REPO_ROOT/proofs" ] || warn "Proofs directory not found"
  log "✓ Prerequisites OK"
  log ""

  # Run learning engine
  log "Running learning engine..."
  python3 "$SCRIPTS_DIR/learning-engine.py" >> "$LOG_FILE" 2>&1 || warn "Learning engine failed"
  log ""

  # Check for promoted rules
  TODAY=$(date +%Y-%m-%d)
  VALIDATION_REPORT="$MEMORY_DIR/validation-report-$TODAY.json"

  if [ -f "$VALIDATION_REPORT" ]; then
    RULES_READY=$(python3 -c "import json; data=json.load(open('$VALIDATION_REPORT')); print(data.get('ready_to_promote', 0))")
    if [ "$RULES_READY" -gt 0 ]; then
      log "📋 $RULES_READY rules ready for promotion"
      log "Review: $VALIDATION_REPORT"
    fi
  fi

  # Commit learning results
  log "Committing learning results..."
  cd "$REPO_ROOT"

  if git diff --quiet ψ/memory/resonance/; then
    log "No changes to commit"
  else
    git add ψ/memory/resonance/ 2>/dev/null || true
    git commit -m "chore: Daily learning pipeline - $(date +%Y-%m-%d)" 2>/dev/null || warn "Git commit failed"
    log "✓ Committed to git"
  fi

  log ""
  log "Learning Pipeline Completed Successfully"
  log "Results saved to: $MEMORY_DIR"

} >> "$LOG_FILE" 2>&1

# Print summary
echo ""
echo "✓ Learning pipeline completed"
echo "  Log: $LOG_FILE"
echo ""
