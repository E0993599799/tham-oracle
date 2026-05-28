#!/usr/bin/env bash
# Spawn Tham autonomous fleet and dispatch current task contracts immediately.
# Claude/Tham is the orchestrator. All non-orchestrator workers are Codex or Gemini only.
# Safety: workers may inspect/edit workspace files, but must not commit, push, deploy, delete, or force-reset.

set -euo pipefail

SESSION="${SESSION:-tham-oracle-stack}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIN_REPO_DIR="$(wslpath -w "$REPO_DIR")"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-http://127.0.0.1:20128/v1}"
CODEX_MODEL="${CODEX_MODEL:-configured-codex-default}"
GEMINI_MODEL="${GEMINI_MODEL:-configured-gemini-default}"
CLAUDE_MODEL="${CLAUDE_MODEL:-sonnet}"
STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$REPO_DIR/reports/autonomous-fleet/$STAMP"
PROMPT_DIR="$RUN_DIR/prompts"
PROGRESS_DIR="$REPO_DIR/reports/progress"
LOG_DIR="$RUN_DIR/logs"
mkdir -p "$PROMPT_DIR" "$PROGRESS_DIR" "$LOG_DIR" "$REPO_DIR/reports/escalations" "$REPO_DIR/proofs"

# Current requirement memory result:
# - session_search found no matching prior sessions in the local DB during setup.
# - repo-local TASK_BROADCAST.md contains Active Queue (4 Tasks).
# Dispatch remaps old CLAUDE worker tasks to Codex/Gemini workers because current fleet policy says
# Claude is Tham/orchestrator only; non-orchestrator work must be Codex/Gemini.
REQ_COUNT=4
REQ_SOURCE="repo:TASK_BROADCAST.md Active Queue (session memory search returned 0 hits)"

write_prompt() {
  local agent="$1" title="$2" body="$3"
  cat > "$PROMPT_DIR/$agent.md" <<EOF_PROMPT
# $agent — $title

You are agent '$agent' inside the Tham Oracle tmux fleet.
Repository: $REPO_DIR
Windows path: $WIN_REPO_DIR
Orchestrator pane: tmux session '$SESSION', window 'tham'.

Fleet policy:
- Tham/Claude is orchestrator/governor only.
- Every worker must be Codex or Gemini only.
- Do NOT commit, push, merge, deploy, delete, force-reset, force-push, or expose secrets.
- Do NOT edit files outside the repository.
- If a requested path is missing, report a blocker with evidence instead of hallucinating work.
- Before changing files, inspect relevant files and git status.
- Write progress to: reports/progress/$agent.md
- Append any escalation to: reports/escalations/$agent.log
- Final proof must include: exact files inspected/changed, validation command/output, secret-scan statement, risks, rollback path, and next action if incomplete.
- Required reporting cadence: update reports/progress/$agent.md at least every 2 minutes while active. A shell heartbeat wrapper also relays status to Tham every 2 minutes.

Requirement memory result:
- Requirement/task count found: $REQ_COUNT
- Source: $REQ_SOURCE
- Active queue is TASK-001..TASK-004 from TASK_BROADCAST.md. Since Claude is orchestrator-only, any legacy CLAUDE worker task is reassigned to Codex/Gemini workers.

Your task:
$body
EOF_PROMPT
}

COMMON_REPORT="Start by writing 'Task received, starting now' to your progress file with timestamp. End by writing 'Task proof ready, awaiting verification' or 'BLOCKED' with reasons."

write_prompt "tham" "Claude orchestrator / governor" "
Act as Tham, the Claude orchestrator. Supervise the six worker panes: core, codex, bob, gemini, housekeeper, watchdog.

Immediate duties:
1. Record that requirement/task count is 4 from TASK_BROADCAST.md; no matching prior session-memory hits were found.
2. Monitor reports/progress/*.md and reports/escalations/*.log.
3. Verify worker proof before declaring success.
4. Re-route work only to Codex/Gemini workers. Do not perform implementation yourself except orchestration notes/proof review.
5. Keep the tmux session usable for human commands.
6. Every 2 minutes, read the worker progress files and produce a short orchestration status in reports/progress/tham.md.

Do not commit/push/deploy/delete. If a worker finishes or blocks, write next instruction in reports/progress/tham.md and, when useful, send tmux instructions to that worker pane.
"

write_prompt "gemini" "TASK-001 cleanup inspector" "
TASK-001 from TASK_BROADCAST.md: Code Cleanup — Phase 4 Refactor.
Targets: src/dashboard/, src/api/, src/services/.
Constraint: zero behavior change, tests pass unchanged.
Proof: git diff cleanup only + test summary.

Because this repository may not contain those target paths, first verify whether the paths exist. If absent, do not invent files; report BLOCKED with exact evidence and recommend the correct next target. If present, perform safe cleanup only. $COMMON_REPORT
"

write_prompt "codex" "TASK-002 tests builder" "
TASK-002 from TASK_BROADCAST.md, reassigned from legacy CLAUDE worker to Codex because Claude is now orchestrator-only: Test Suite — Phase 4 APIs & Components.
Targets: src/api/, src/dashboard/components/.
Constraint: coverage >=80%, all tests passing.
Proof: test results + coverage report.

First inspect package/test tooling and target paths. If targets are absent, report BLOCKED with exact evidence and propose the smallest next task. If present, add tests only where appropriate and run validation. $COMMON_REPORT
"

write_prompt "core" "TASK-003 docs/proof bridge" "
TASK-003 from TASK_BROADCAST.md, reassigned from legacy CLAUDE worker to Codex/Core: Documentation — Phase 4 Features + API Reference.
Deliver docs/phase-4/ overview/API/architecture/deployment/troubleshooting if source material exists. If source material is incomplete, create a concise audit/proof note identifying missing inputs rather than fabricating docs.
Constraint: clear, concise, examples + diagrams only if grounded in repo evidence.
Proof: markdown docs with navigation or blocker proof. $COMMON_REPORT
"

write_prompt "bob" "TASK-004 research coordinator" "
TASK-004 from TASK_BROADCAST.md, reassigned from legacy CLAUDE worker to Codex/Bob: Research — Frontend Skills + Figma Integration.
Deliverable: RESEARCH-frontend-figma.md.
Constraint: actionable recommendations for Phase 5, grounded in repo context. Use available repo docs first; if web access is unavailable, say so and provide repo-grounded recommendations.
Proof: research doc with findings, assumptions, and next actions. $COMMON_REPORT
"

write_prompt "housekeeper" "repo hygiene and safety proof" "
Inspect current repo hygiene for autonomous fleet readiness:
- git status/diff summary;
- verify AGENTS.md, .agents/agents.yaml, configs/* registries, spawn scripts;
- identify pre-existing dirty files vs current autonomous run artifacts;
- run lightweight secret scan over changed/untracked orchestration files only using safe local commands.
Do not modify unless a tiny typo blocks validation. $COMMON_REPORT
"

write_prompt "watchdog" "monitor and circuit breaker" "
Act as watchdog for the tmux fleet. Monitor the session '$SESSION', reports/progress/*.md, and reports/escalations/*.log.
Every 2 minutes, update reports/progress/watchdog.md with:
- tmux windows alive/dead;
- latest progress timestamp per agent;
- stale agents over 4 minutes;
- missing proof/escalation status.
Do not edit product code. Keep monitoring until stopped by Tham/human. $COMMON_REPORT
"

# Worker runner inserted into each tmux pane. It runs an agent command and relays a heartbeat to Tham every 120 seconds.
make_worker_command() {
  local agent="$1" runtime="$2"
  local prompt="$PROMPT_DIR/$agent.md" log="$LOG_DIR/$agent.log" progress="$PROGRESS_DIR/$agent.md"
  cat <<EOF_CMD
cd '$REPO_DIR'
mkdir -p '$PROGRESS_DIR' '$LOG_DIR'
printf '[%s] %s: Task received, starting now\n' "\$(date -Iseconds)" '$agent' | tee -a '$progress'
(
  while true; do
    sleep 120
    printf '[%s] %s heartbeat: still active; latest progress follows.\n' "\$(date -Iseconds)" '$agent' >> '$REPO_DIR/reports/progress/tham-inbox.log'
    tail -n 20 '$progress' >> '$REPO_DIR/reports/progress/tham-inbox.log' 2>/dev/null || true
    tmux send-keys -t '$SESSION:tham' "[heartbeat:$agent] \$(date -Iseconds) latest status written to reports/progress/$agent.md" C-m 2>/dev/null || true
  done
) & HEARTBEAT_PID=\$!
trap 'kill \$HEARTBEAT_PID 2>/dev/null || true' EXIT
EOF_CMD
  if [ "$runtime" = "codex" ]; then
    cat <<EOF_CMD
set +e
OPENAI_BASE_URL='$ROUTER_BASE_URL' cmd.exe /c cd /d '$WIN_REPO_DIR' '&&' codex exec --sandbox workspace-write -C '$WIN_REPO_DIR' - < '$prompt' 2>&1 | tee -a '$log'
STATUS=\$?
echo "agent exit status: \$STATUS" | tee -a '$progress'
exec bash
EOF_CMD
  elif [ "$runtime" = "gemini" ]; then
    cat <<EOF_CMD
set +e
OPENAI_BASE_URL='$ROUTER_BASE_URL' cmd.exe /c cd /d '$WIN_REPO_DIR' '&&' gemini --approval-mode auto_edit -p 'Read the full task instructions from stdin and execute them.' < '$prompt' 2>&1 | tee -a '$log'
STATUS=\$?
echo "agent exit status: \$STATUS" | tee -a '$progress'
exec bash
EOF_CMD
  else
    cat <<EOF_CMD
set +e
bash '$REPO_DIR/scripts/oracle-engine.sh' --role tham-orchestrator --workdir '$REPO_DIR' --name tham-orchestrator --model '$CLAUDE_MODEL' --permission-mode auto "\$(cat '$prompt')" 2>&1 | tee -a '$log'
STATUS=\$?
echo "tham exit status: \$STATUS" | tee -a '$progress'
exec bash
EOF_CMD
  fi
}

# Fix shell variable status placeholders in generated tmux commands.
# Keep status tokens as plain text in heredocs, then replace after generation so
# the generated scripts contain executable shell (`STATUS=$?`, `$STATUS`) rather
# than malformed escapes such as `STATUS=\` or `\STATUS`.
clean_cmd_file() {
  local file="$1"
  perl -0pi -e 's/__STATUS_QMARK__/\$?/g; s/__STATUS_VAR__/\$STATUS/g; s/STATUS=\\\s*\n/STATUS=\$?\n/g; s/\\STATUS/\$STATUS/g' "$file"
}

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

# Create command files for easier tmux startup and auditability.
make_worker_command "tham" "claude" > "$RUN_DIR/tham.sh"
make_worker_command "core" "codex" > "$RUN_DIR/core.sh"
make_worker_command "codex" "codex" > "$RUN_DIR/codex.sh"
make_worker_command "bob" "codex" > "$RUN_DIR/bob.sh"
make_worker_command "gemini" "gemini" > "$RUN_DIR/gemini.sh"
make_worker_command "housekeeper" "gemini" > "$RUN_DIR/housekeeper.sh"
make_worker_command "watchdog" "gemini" > "$RUN_DIR/watchdog.sh"
for f in "$RUN_DIR"/*.sh; do clean_cmd_file "$f"; chmod +x "$f"; done

tmux new-session -d -s "$SESSION" -n tham -x 250 -y 50 "bash '$RUN_DIR/tham.sh'"
tmux new-window -t "$SESSION" -n core "bash '$RUN_DIR/core.sh'"
tmux new-window -t "$SESSION" -n codex "bash '$RUN_DIR/codex.sh'"
tmux new-window -t "$SESSION" -n bob "bash '$RUN_DIR/bob.sh'"
tmux new-window -t "$SESSION" -n gemini "bash '$RUN_DIR/gemini.sh'"
tmux new-window -t "$SESSION" -n housekeeper "bash '$RUN_DIR/housekeeper.sh'"
tmux new-window -t "$SESSION" -n watchdog "bash '$RUN_DIR/watchdog.sh'"

tmux set-option -t "$SESSION" remain-on-exit on >/dev/null

cat > "$RUN_DIR/dispatch-summary.md" <<EOF_SUMMARY
# Autonomous fleet dispatch — $STAMP

Session: $SESSION
Run dir: $RUN_DIR
Requirement count: $REQ_COUNT
Requirement source: $REQ_SOURCE
Agents: tham(Claude orchestrator), core/codex/bob(Codex), gemini/housekeeper/watchdog(Gemini)
Report cadence: worker shell heartbeat to Tham every 120 seconds; agents instructed to update reports/progress/*.md every 2 minutes.
Safety: no commit/push/merge/deploy/delete/force-reset/force-push.
EOF_SUMMARY

printf 'AUTONOMOUS_FLEET_SPAWNED\n'
printf 'session=%s\n' "$SESSION"
printf 'run_dir=%s\n' "$RUN_DIR"
printf 'requirement_count=%s\n' "$REQ_COUNT"
printf 'requirement_source=%s\n' "$REQ_SOURCE"
tmux list-windows -t "$SESSION"
