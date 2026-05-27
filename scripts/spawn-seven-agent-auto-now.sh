#!/usr/bin/env bash
# Auto-dispatch the current seven-agent Tham Oracle swarm without interactive approval loops.
# Uses a fresh tmux session by default so existing stuck panes are left intact.
# Safety: no commit, push, deploy, delete, git reset/clean, or force operations.

set -euo pipefail

SESSION="${SESSION:-tham-oracle-stack-auto}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$REPO_DIR/reports/autonomous-fleet/$RUN_STAMP-seven-agent-auto"
PROMPT_DIR="$RUN_DIR/prompts"
LOG_DIR="$RUN_DIR/logs"
SCRIPT_DIR="$RUN_DIR/scripts"
PROGRESS_DIR="$REPO_DIR/reports/progress"
mkdir -p "$PROMPT_DIR" "$LOG_DIR" "$SCRIPT_DIR" "$PROGRESS_DIR" "$REPO_DIR/reports/escalations"

COMMON_POLICY="Repository: $REPO_DIR
Required first check: pwd; git rev-parse --show-toplevel; git remote -v.
Expected git root: $REPO_DIR
Expected remote: https://github.com/E0993599799/tham-oracle.git
Safety rules: do NOT commit, push, merge, deploy, delete, git reset, git clean, force-push, or expose secrets. Avoid broad edits. If target paths are missing or evidence is insufficient, report BLOCKED with exact evidence instead of inventing work.
Proof requirements: exact files inspected/changed; validation command/output; secret-scan statement for changed files; risk notes; rollback path; next action if incomplete.
Progress file: reports/progress/AGENT.md. Start by writing 'Task received, starting now'. End with 'Task proof ready, awaiting verification' or 'BLOCKED'."

write_prompt() {
  local agent="$1" title="$2" body="$3"
  cat > "$PROMPT_DIR/$agent.md" <<EOF_PROMPT
# $agent — $title

$COMMON_POLICY

Agent identity and routing:
- tham/Claude is orchestrator/governor only.
- Codex team does implementation, safety, verification, and architecture work: dheva, zeus, warden, verity, stratum.
- Gemini team does research, inspection, and review: luxi, lens.
- Legacy lanes codex/core/bob/gemini/housekeeper/watchdog/hermes are archive/manual only for this run.

Your assigned work:
$body
EOF_PROMPT
  # Substitute literal agent progress path after writing common text.
  perl -0pi -e "s/reports\/progress\/AGENT\.md/reports\/progress\/$agent.md/g" "$PROMPT_DIR/$agent.md"
}

write_prompt "dheva" "ORRY implementation lead / TASK-001 cleanup feasibility" "
Read AGENTS.md, .agents/agents.yaml, TASK_BROADCAST.md, configs/agent-registry.json, and relevant package/test files.
Own TASK-001 implementation feasibility: Code Cleanup — Phase 4 Refactor, targets src/dashboard/, src/api/, src/services/.
Because this repo may use dashboard-next/server instead of src/*, first verify target existence. If old paths are absent, do not fabricate cleanup. Produce a precise blocker/proposal mapping old targets to actual repo paths and identify the smallest safe cleanup candidate. Only make tiny zero-behavior cleanup edits if evidence is clear and validation is available.
Write proof to reports/progress/dheva.md.
"

write_prompt "zeus" "Codex build/test worker / TASK-002 test plan" "
Own TASK-002 test-suite feasibility: Phase 4 APIs & Components. Inspect package/test tooling and actual app structure, especially dashboard-next, server, docs/phase-4.
If src/api or src/dashboard/components are absent, report BLOCKED with exact evidence and propose the correct smallest test target in this repo. If tests can safely run, run read-only/lightweight validation first. Do not add large tests unless the target and runner are clear.
Write proof to reports/progress/zeus.md.
"

write_prompt "warden" "Safety/risk/code guard" "
Inspect deployment/repo safety for this autonomous run and ORRY/Vercel assumptions. Check .gitignore, .vercelignore if present, package scripts, env examples, changed/untracked orchestration files, and obvious secret risks. Do not expose secret values. Recommend fixes; only edit ignore files if a tiny high-confidence safety fix is necessary.
Write proof to reports/progress/warden.md.
"

write_prompt "verity" "Verification/proof auditor" "
Audit the current run. Verify that every active worker writes proof under the nested repo only. Check for misplaced parent mission-control artifacts from earlier Lens/Luxi work and list them as risk. Verify root/remote and summarize which proof files are ready, missing, or blocked. Do not perform implementation.
Write proof to reports/progress/verity.md.
"

write_prompt "stratum" "Systems architecture / TASK-003 docs architecture" "
Own architecture interpretation for TASK-003 documentation. Inspect actual repo layout and existing docs/phase-4. Determine whether docs are already present and what gaps remain. Produce an architecture/docs gap report grounded in files. Only edit docs if the missing section is small and evidence-grounded; otherwise report next steps.
Write proof to reports/progress/stratum.md.
"

write_prompt "luxi" "Gemini research inspector / TASK-004" "
Own research/inspection for TASK-004: frontend skills + Figma integration recommendations for Phase 5. Use repo context first; web is optional. Verify you are in the nested tham-oracle repo before writing. Update or create only reports/progress/luxi.md unless a research deliverable is explicitly justified; do not write to the parent mission-control folder.
Write proof to reports/progress/luxi.md.
"

write_prompt "lens" "Gemini inspection lens / review and misplaced artifact audit" "
Act as inspection/review lens. Inspect current swarm state, repo root correctness, progress files, and misplaced artifacts from previous parent mission-control writes. Review Dheva/Zeus/Warden/Stratum/Verity/Luxi outputs if they exist. Produce findings and confidence levels; do not implement product code.
Write proof to reports/progress/lens.md.
"

make_runner() {
  local agent="$1" runtime="$2"
  local prompt="$PROMPT_DIR/$agent.md"
  local log="$LOG_DIR/$agent.log"
  local progress="$PROGRESS_DIR/$agent.md"
  cat > "$SCRIPT_DIR/$agent.sh" <<EOF_RUNNER
#!/usr/bin/env bash
set +e
cd '$REPO_DIR' || exit 2
mkdir -p '$PROGRESS_DIR' '$LOG_DIR' '$REPO_DIR/reports/escalations'
printf '[%s] $agent: Task received, starting now\n' "\$(date -Iseconds)" | tee -a '$progress'
(
  while true; do
    sleep 120
    printf '[%s] $agent heartbeat: still active\n' "\$(date -Iseconds)" >> '$REPO_DIR/reports/progress/tham-inbox.log'
    tail -n 20 '$progress' >> '$REPO_DIR/reports/progress/tham-inbox.log' 2>/dev/null || true
  done
) & HEARTBEAT_PID=\$!
trap 'kill \$HEARTBEAT_PID 2>/dev/null || true' EXIT
EOF_RUNNER
  if [ "$runtime" = "codex" ]; then
    cat >> "$SCRIPT_DIR/$agent.sh" <<EOF_RUNNER
cat '$prompt' | codex exec -C . --sandbox workspace-write --ignore-rules - 2>&1 | tee -a '$log'
STATUS=\${PIPESTATUS[1]}
printf '[%s] $agent exit status: %s\n' "\$(date -Iseconds)" "\$STATUS" | tee -a '$progress'
exec bash
EOF_RUNNER
  else
    cat >> "$SCRIPT_DIR/$agent.sh" <<EOF_RUNNER
# Prefer Gemini Pro briefly; if quota/high-demand stalls/fails, retry same Gemini runtime on Flash preview.
timeout 45 gemini --approval-mode auto_edit -m 'gemini-3.1-pro-preview' -p "Read the full task from stdin and execute it. Keep edits scoped to the repository and proof file." < '$prompt' 2>&1 | tee -a '$log'
STATUS=\${PIPESTATUS[0]}
if [ "\$STATUS" = "124" ] || grep -qiE 'high demand|rate limit|quota|capacity|try again|experiencing high demand|exhausted your capacity' '$log'; then
  printf '[%s] $agent: Gemini Pro unavailable/high-demand; retrying Gemini Flash fallback\n' "\$(date -Iseconds)" | tee -a '$progress'
  timeout 240 gemini --approval-mode auto_edit -m 'gemini-3-flash-preview' -p "Read the full task from stdin and execute it. Keep edits scoped to the repository and proof file." < '$prompt' 2>&1 | tee -a '$log'
  STATUS=\${PIPESTATUS[0]}
fi
printf '[%s] $agent exit status: %s\n' "\$(date -Iseconds)" "\$STATUS" | tee -a '$progress'
exec bash
EOF_RUNNER
  fi
  chmod +x "$SCRIPT_DIR/$agent.sh"
}

make_runner dheva codex
make_runner zeus codex
make_runner warden codex
make_runner verity codex
make_runner stratum codex
make_runner luxi gemini
make_runner lens gemini

cat > "$RUN_DIR/dispatch-summary.md" <<EOF_SUMMARY
# Seven-agent auto dispatch — $RUN_STAMP

Session: $SESSION
Repo: $REPO_DIR
Run dir: $RUN_DIR
Agents: dheva/zeus/warden/verity/stratum (Codex), luxi/lens (Gemini)
Safety: no commit/push/deploy/delete/reset/clean/force operations.
Routing source: AGENTS.md + .agents/agents.yaml + configs/agent-registry.json + TASK_BROADCAST.md.
EOF_SUMMARY

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n codex-team -x 240 -y 60 "bash '$SCRIPT_DIR/dheva.sh'"
tmux split-window -t "$SESSION:codex-team.0" -v "bash '$SCRIPT_DIR/zeus.sh'"
tmux split-window -t "$SESSION:codex-team.1" -v "bash '$SCRIPT_DIR/warden.sh'"
tmux split-window -t "$SESSION:codex-team.2" -v "bash '$SCRIPT_DIR/verity.sh'"
tmux split-window -t "$SESSION:codex-team.3" -v "bash '$SCRIPT_DIR/stratum.sh'"
tmux select-layout -t "$SESSION:codex-team" tiled >/dev/null || true
for i in 0 1 2 3 4; do tmux select-pane -t "$SESSION:codex-team.$i" -T "$(printf '%s' "dheva zeus warden verity stratum" | cut -d' ' -f$((i+1)))"; done

tmux new-window -t "$SESSION" -n gemini-team "bash '$SCRIPT_DIR/luxi.sh'"
tmux split-window -t "$SESSION:gemini-team.0" -v "bash '$SCRIPT_DIR/lens.sh'"
tmux select-layout -t "$SESSION:gemini-team" tiled >/dev/null || true
tmux select-pane -t "$SESSION:gemini-team.0" -T luxi
tmux select-pane -t "$SESSION:gemini-team.1" -T lens

tmux set-option -t "$SESSION" remain-on-exit on >/dev/null
tmux set-window-option -t "$SESSION:codex-team" pane-border-status top >/dev/null
tmux set-window-option -t "$SESSION:gemini-team" pane-border-status top >/dev/null

echo "SEVEN_AGENT_AUTO_DISPATCHED"
echo "session=$SESSION"
echo "run_dir=$RUN_DIR"
tmux list-windows -t "$SESSION" -F '#{window_index}:#{window_name} panes=#{window_panes}'
tmux list-panes -t "$SESSION:codex-team" -F '#{window_name}.#{pane_index} #{pane_title} #{pane_current_command} #{pane_current_path}'
tmux list-panes -t "$SESSION:gemini-team" -F '#{window_name}.#{pane_index} #{pane_title} #{pane_current_command} #{pane_current_path}'
