#!/usr/bin/env bash
# Start Oracle fleet (multi-Oracle tmux session).
# Ports: Tham 47778 | Dev 47779 | QA 47780 | Studio 3000

SESSION="oracle-fleet"
ORACLE_BIN="bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main"

# Find arra-oracle source if cloned locally
ORACLE_SRC=""
for p in "$HOME/repos/arra-oracle" "$HOME/src/arra-oracle"; do
  [ -d "$p" ] && ORACLE_SRC="$p" && break
done

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Fleet '$SESSION' already running — attach with: tmux attach -t $SESSION"
  exit 0
fi

start_oracle() {
  local name="$1" port="$2" db="$3"
  local env_args="ORACLE_PORT=$port"
  [ -n "$db" ] && env_args="$env_args ORACLE_DB=$db"
  tmux new-window -t "$SESSION" -n "$name"
  tmux send-keys -t "$SESSION:$name" "env $env_args $ORACLE_BIN --http --port $port" Enter
  echo "  started: $name → port $port"
}

# Window 0: Tham Oracle (default)
tmux new-session -d -s "$SESSION" -n "tham"
tmux send-keys -t "$SESSION:tham" \
  "env ORACLE_PORT=47778 $ORACLE_BIN --http --port 47778" Enter
echo "  started: tham → port 47778"

# Window 1: Dev Oracle (template/inactive — comment in to activate)
# start_oracle "dev" "47779" "$HOME/.oracle/oracle-dev.db"

# Window 2: QA Oracle (template/inactive — comment in to activate)
# start_oracle "qa" "47780" "$HOME/.oracle/oracle-qa.db"

# Window 3: Oracle Studio → Tham
sleep 3
tmux new-window -t "$SESSION" -n "studio"
tmux send-keys -t "$SESSION:studio" \
  "bunx oracle-studio --api http://localhost:47778 --port 3000" Enter
echo "  started: studio → port 3000"

tmux select-window -t "$SESSION:tham"
echo ""
echo "Fleet '$SESSION' running:"
echo "  Tham Oracle  → http://localhost:47778"
echo "  Oracle Studio → http://localhost:3000"
echo "Attach: tmux attach -t $SESSION"
