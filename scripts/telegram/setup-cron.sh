#!/usr/bin/env bash
# Tham Oracle — Setup Cron Jobs for Telegram Alerts
# Idempotent: safe to run multiple times

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HEALTH_MONITOR="${REPO_ROOT}/scripts/telegram/health-monitor.sh"
DAILY_SUMMARY="${REPO_ROOT}/scripts/telegram/daily-summary.sh"
TOKEN_WATCH="${REPO_ROOT}/scripts/fallback-watch/trigger-awake.sh"
LOG_DIR="/tmp/tham-cron"

mkdir -p "$LOG_DIR"
chmod +x "$HEALTH_MONITOR" "$DAILY_SUMMARY"
[ -f "$TOKEN_WATCH" ] && chmod +x "$TOKEN_WATCH"

# Build crontab entries
HEALTH_CRON="*/5 * * * * bash $HEALTH_MONITOR >> $LOG_DIR/health.log 2>&1"
DAILY_CRON="0 9 * * * bash $DAILY_SUMMARY >> $LOG_DIR/daily.log 2>&1"
TOKEN_CRON="*/10 * * * * bash $TOKEN_WATCH >> $LOG_DIR/token-watch.log 2>&1"

# Remove old tham entries, add new ones
(crontab -l 2>/dev/null | grep -v "tham-oracle/scripts"; \
 echo "# Tham Oracle — health check every 5 min"; \
 echo "$HEALTH_CRON"; \
 echo "# Tham Oracle — daily summary at 09:00"; \
 echo "$DAILY_CRON"; \
 echo "# Tham Oracle — token limit watch every 10 min"; \
 echo "$TOKEN_CRON") | crontab -

echo "✅ Cron jobs installed:"
echo "   Every 5 min:  health-monitor.sh"
echo "   Every 10 min: token-watch/trigger-awake.sh"
echo "   09:00 daily:  daily-summary.sh"
echo ""
echo "Current crontab (tham entries):"
crontab -l | grep "tham"
