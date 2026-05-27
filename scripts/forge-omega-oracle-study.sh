#!/usr/bin/env bash
set -euo pipefail

SESSION="${MAW_ORACLE_SESSION:-forge-omega-oracle}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$REPO_DIR/reports/autonomous-fleet/$STAMP-forge-omega-oracle-study"
PROMPT_DIR="$RUN_DIR/prompts"
LOG_DIR="$RUN_DIR/logs"
PROGRESS_DIR="$REPO_DIR/reports/progress"
AGGREGATE="$PROGRESS_DIR/forge-omega-oracle-study.md"
STUDY_DIR="${TMPDIR:-/tmp}/forge-omega-oracle-study-repos"

mkdir -p "$PROMPT_DIR" "$LOG_DIR" "$PROGRESS_DIR" "$RUN_DIR"
: > "$AGGREGATE"

clone_repo() {
  local name="$1"
  local url="$2"
  local dir="$STUDY_DIR/$name"
  if [ ! -d "$dir/.git" ]; then
    mkdir -p "$STUDY_DIR"
    git clone --depth 1 "$url" "$dir" >/dev/null 2>&1
  fi
  printf '%s' "$dir"
}

MAW_JS_DIR="$(clone_repo maw-js https://github.com/Soul-Brews-Studio/maw-js)"
MAW_UI_DIR="$(clone_repo maw-ui https://github.com/Soul-Brews-Studio/maw-ui)"
ORACLE_FW_DIR="$(clone_repo oracle-framework-advanced https://github.com/Soul-Brews-Studio/oracle-framework-advanced)"
MAW_PLUGINS_DIR="$(clone_repo maw-plugins https://github.com/Soul-Brews-Studio/maw-plugins)"

cat > "$PROMPT_DIR/task1.md" <<'EOF'
Task 1 — Soul-Brews pattern mapping

Study the Soul-Brews Studio repos and produce a concise mapping of:
- maw-js as the orchestration core
- maw-ui as the visual control plane
- maw-plugins as the extensibility layer
- oracle-framework-advanced as the doctrine / ψ/ / safety shell

Return:
- what each repo does
- what is directly reusable in MarcuzX Forge
- what should not be copied blindly
EOF

cat > "$PROMPT_DIR/task2.md" <<'EOF'
Task 2 — Forge Omega monitor design

Design the tmux/maw monitor surface for Forge Omega.
Focus on:
- visible task panes for each agent
- a monitor pane that tails progress
- stable session naming
- clear pane labels
- readable proof output

Return:
- recommended pane layout
- recommended naming convention
- how to verify the panes are alive
EOF

cat > "$PROMPT_DIR/task3.md" <<'EOF'
Task 3 — README / reuse package

Create the reusable README and launcher text so the user only needs to:
1. open Linux
2. cd into tham-oracle
3. run one command

Return:
- final README text
- exact launcher command
- exact prompt block
- tmux attach command
EOF

append_progress() {
  local title="$1"
  local body="$2"
  {
    printf '\n## %s\n\n' "$title"
    printf '%s\n' "$body"
  } | tee -a "$AGGREGATE" >/dev/null
}

pane_cmd_task1=$(cat <<'EOF'
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
clear
printf '%s\n' '=== Task 1 — Soul-Brews pattern mapping ==='
printf '%s\n' 'Prompt: read the task file in reports/autonomous-fleet/.../prompts/task1.md'
printf '%s\n' 'Sources: maw-js, maw-ui, maw-plugins, oracle-framework-advanced'
python3 - <<'PY'
from pathlib import Path
repo = Path('/tmp/forge-omega-oracle-study-repos')
summary = [
    'maw-js = orchestration core: wake/send/peek/view/team/federation/health',
    'maw-ui = visual control plane: dashboard, fleet, terminals, mission, inbox, workspace',
    'maw-plugins = weighted plugin ecosystem: core, infra, tools, features, customizations',
    'oracle-framework-advanced = doctrine shell: ψ/ structure, safety, subagents, workflows',
    'Transfer to Forge Omega: visible tmux control, durable memory, safety rules, plugin-like routing',
    'Do not copy blindly: UI implementation details, repo-specific paths, and provider-specific commands',
]
for line in summary:
    print(line)
Path('reports/progress/forge-omega-pattern-mapping.md').write_text('# Forge Omega — Pattern Mapping\n\n' + '\n'.join(f'- {x}' for x in summary) + '\n', encoding='utf-8')
print('\nWrote reports/progress/forge-omega-pattern-mapping.md')
PY
printf '\n[task 1] complete\n'
exec bash
EOF
)

pane_cmd_task2=$(cat <<'EOF'
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
clear
printf '%s\n' '=== Task 2 — Forge Omega monitor design ==='
printf '%s\n' 'Prompt: read the task file in reports/autonomous-fleet/.../prompts/task2.md'
python3 - <<'PY'
from pathlib import Path
layout = [
    'Session: forge-omega-oracle',
    'Pane 0: task-1 mapping',
    'Pane 1: task-2 monitor design',
    'Pane 2: task-3 README reuse package',
    'Pane 3: monitor/tail progress',
    'Verification: tmux list-panes + visible pane titles + progress files',
]
for line in layout:
    print(line)
text = '# Forge Omega — Monitor Design\n\n' + '\n'.join(f'- {x}' for x in layout) + '\n'
Path('reports/progress/forge-omega-monitor-design.md').write_text(text, encoding='utf-8')
print('\nWrote reports/progress/forge-omega-monitor-design.md')
PY
printf '\n[task 2] complete\n'
exec bash
EOF
)

pane_cmd_task3=$(cat <<'EOF'
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
clear
printf '%s\n' '=== Task 3 — README / reuse package ==='
printf '%s\n' 'Prompt: read the task file in reports/autonomous-fleet/.../prompts/task3.md'
python3 - <<'PY'
from pathlib import Path
readme = Path('docs/forge-omega-oracle/README.md').read_text(encoding='utf-8')
launcher = 'bash scripts/forge-omega-oracle-study.sh'
attach = 'tmux attach -t forge-omega-oracle'
summary = [
    'Reusable README created at docs/forge-omega-oracle/README.md',
    f'Launcher command: {launcher}',
    f'Tmux attach command: {attach}',
]
for line in summary:
    print(line)
Path('reports/progress/forge-omega-launcher-spec.md').write_text('# Forge Omega — Launcher Spec\n\n' + '\n'.join(f'- {x}' for x in summary) + '\n', encoding='utf-8')
print('\nWrote reports/progress/forge-omega-launcher-spec.md')
PY
printf '\n[task 3] complete\n'
exec bash
EOF
)

monitor_cmd=$(cat <<EOF
cd '/mnt/d/01 Main Work/Boots/Agentic AI/mission-control/tham-oracle'
clear
printf '%s\n' '=== Forge Omega monitor ==='
printf '%s\n' 'Watching reports/progress/forge-omega-oracle-study.md'
exec tail -n +1 -f '$AGGREGATE'
EOF
)

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

# Use maw to create the session shell first, then let tmux split it into the requested panes.
maw new "$SESSION" --no-attach >/dev/null

# Rebuild the single lead shell into a visible 2x2 dashboard.
tmux rename-window -t "$SESSION:0" "forge-omega"
tmux split-window -h -t "$SESSION:0" -c "$REPO_DIR"
tmux split-window -v -t "$SESSION:0.0" -c "$REPO_DIR"
tmux split-window -v -t "$SESSION:0.1" -c "$REPO_DIR"
tmux select-layout -t "$SESSION:0" tiled >/dev/null || true

tmux select-pane -t "$SESSION:0.0" -T "task-1"
tmux select-pane -t "$SESSION:0.1" -T "task-2"
tmux select-pane -t "$SESSION:0.2" -T "task-3"
tmux select-pane -t "$SESSION:0.3" -T "monitor"

tmux set-window-option -t "$SESSION:0" pane-border-status top >/dev/null
tmux set-option -t "$SESSION" remain-on-exit on >/dev/null

tmux send-keys -l -t "$SESSION:0.0" "$pane_cmd_task1" C-m
tmux send-keys -l -t "$SESSION:0.1" "$pane_cmd_task2" C-m
tmux send-keys -l -t "$SESSION:0.2" "$pane_cmd_task3" C-m
tmux send-keys -l -t "$SESSION:0.3" "$monitor_cmd" C-m

append_progress "launcher" "Session: $SESSION\nRun dir: $RUN_DIR\nRepos cloned under: $STUDY_DIR\nPanes: task-1, task-2, task-3, monitor\n"
append_progress "task-1 prompt" "$(cat "$PROMPT_DIR/task1.md")"
append_progress "task-2 prompt" "$(cat "$PROMPT_DIR/task2.md")"
append_progress "task-3 prompt" "$(cat "$PROMPT_DIR/task3.md")"

printf '%s\n' "Forge Omega Oracle study session ready."
printf '%s\n' "Attach: tmux attach -t $SESSION"
printf '%s\n' "Summary: $RUN_DIR"
printf '%s\n' "Panes:"
tmux list-panes -t "$SESSION:0" -F '#{pane_index} #{pane_title} #{pane_width}x#{pane_height} #{pane_current_command} #{pane_current_path}'
