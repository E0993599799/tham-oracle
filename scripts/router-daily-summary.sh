#!/usr/bin/env bash
# Phase 3D: Daily Router Summary Wrapper
# Run daily proof aggregation and commit results

set -e

DATE=$(date +%Y-%m-%d)
REPO="/root/ghq/github.com/E0993599799/tham-oracle"
LOGFILE="$REPO/logs/router-summary-$DATE.log"

mkdir -p "$REPO/logs"

{
    echo "Running router daily summary for $DATE..."
    echo "Start: $(date)"
    echo "---"

    # Run aggregator
    python3 "$REPO/scripts/proof-aggregator.py" "$DATE"
    RESULT=$?

    if [ $RESULT -eq 0 ]; then
        echo ""
        echo "✅ Aggregation complete"
        echo ""

        # Commit summaries if they're new
        cd "$REPO"

        if git status --porcelain | grep -q "ψ/memory/resonance/router-"; then
            echo "Staging files..."
            git add "ψ/memory/resonance/router-stats-$DATE.json"
            git add "ψ/memory/resonance/router-summary-$DATE.md"
            git add "ψ/memory/resonance/router-insights-$DATE.json"

            echo "Creating commit..."
            git commit -m "docs: Daily router summary — $DATE" || true

            echo "✅ Committed summaries"
        else
            echo "ℹ️ No new proof summary files to commit"
        fi
    else
        echo "❌ Aggregation failed (exit code $RESULT)"
        exit 1
    fi

    echo ""
    echo "End: $(date)"

} | tee "$LOGFILE"

exit 0
