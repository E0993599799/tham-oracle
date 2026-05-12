#!/usr/bin/env bash
# Start Oracle Studio (port 3000).
# oracle-v2 HTTP server must be running at port 47778 first.

API_URL="${ORACLE_API_URL:-http://localhost:47778}"
STUDIO_PORT="${ORACLE_STUDIO_PORT:-3000}"

echo "Starting Oracle Studio → API: $API_URL  Studio port: $STUDIO_PORT"

# Probe oracle-v2 first
if ! curl -s "${API_URL}/health" > /dev/null 2>&1; then
  echo "WARN — oracle-v2 not responding at ${API_URL}. Start it first:"
  echo "  bash scripts/start-oracle-v2-http.sh"
fi

bunx oracle-studio --api "$API_URL" --port "$STUDIO_PORT"
