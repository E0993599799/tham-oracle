#!/bin/bash
# Launch 5-lane orchestration tmux session
set -e

PROJECT_ROOT="/root/ghq/github.com/E0993599799/tham-oracle"
SESSION_NAME="lanes"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-$(awk '/^nameserver /{print $2; exit}' /etc/resolv.conf 2>/dev/null)}"
WINDOWS_HOST_IP="${WINDOWS_HOST_IP:-127.0.0.1}"

cd "$PROJECT_ROOT"
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
sleep 1

echo "🚀 Launching 5-lane orchestration..."

# Create session with window 0 (THAM)
tmux new-session -d -s "$SESSION_NAME" -x 240 -y 60

# Window 0: THAM
tmux send-keys -t "$SESSION_NAME" "cd '$PROJECT_ROOT' && clear" Enter
tmux send-keys -t "$SESSION_NAME" "cat << 'BANNER'
╔════════════════════════════════════════════════════════════╗
║          🧠 THAM ORCHESTRATOR (ธาม ผู้บัญชาการ)           ║
╚════════════════════════════════════════════════════════════╝

Status: ✅ ACTIVE — Dispatching & Verifying

Lanes (Ctrl+B → 1-4):
  1 = CODEX-A (Backend Builder)
  2 = CODEX-B (Database Specialist)
  3 = GEMINI (Fast Inspector)
  4 = CLAUDE (UI/Orchestrator)

Waiting for task dispatch... 📋
BANNER
sleep 999999" Enter

# Window 1: CODEX-A
tmux new-window -t "$SESSION_NAME" -n "codex-a"
tmux send-keys -t "$SESSION_NAME:codex-a" "cd '$PROJECT_ROOT' && clear" Enter
tmux send-keys -t "$SESSION_NAME:codex-a" "cat << 'BANNER'
╔════════════════════════════════════════════════════════════╗
║       ⚙️  CODEX-A BUILDER (Backend Logic)                ║
╚════════════════════════════════════════════════════════════╝

Status: ✅ READY
Role: API logic, core features, backend business logic
Memory: ✓ CLAUDE.md ✓ skills ✓ context ready

Waiting for task contract... 📋
Ready! ⏳
BANNER
sleep 999999" Enter

# Window 2: CODEX-B
tmux new-window -t "$SESSION_NAME" -n "codex-b"
tmux send-keys -t "$SESSION_NAME:codex-b" "cd '$PROJECT_ROOT' && clear" Enter
tmux send-keys -t "$SESSION_NAME:codex-b" "cat << 'BANNER'
╔════════════════════════════════════════════════════════════╗
║    🗄️  CODEX-B BACKEND (Database & Infrastructure)       ║
╚════════════════════════════════════════════════════════════╝

Status: ✅ READY
Role: Schema, migrations, RLS, infrastructure
Memory: ✓ CLAUDE.md ✓ skills ✓ context ready

Waiting for task contract... 📋
Ready! ⏳
BANNER
sleep 999999" Enter

# Window 3: GEMINI
tmux new-window -t "$SESSION_NAME" -n "gemini"
tmux send-keys -t "$SESSION_NAME:gemini" "cd '$PROJECT_ROOT' && clear && echo '⏳ Checking 9router health...'" Enter

# Check 9router
if timeout 2 curl -s "http://${WINDOWS_HOST_IP}:20128/v1/models" 2>/dev/null | grep -q "gemini"; then
  GEMINI_STATUS="✅ READY — 9router ALIVE"
else
  GEMINI_STATUS="⚠️  BLOCKED — 9router not responding"
fi

tmux send-keys -t "$SESSION_NAME:gemini" "cat << 'BANNER'
╔════════════════════════════════════════════════════════════╗
║    ⚡ GEMINI INSPECTOR (Code Cleanup & Fast Analysis)     ║
╚════════════════════════════════════════════════════════════╝

Status: $GEMINI_STATUS
Provider: Gemini 2.5 Flash via 9router (http://${WINDOWS_HOST_IP}:20128)
Role: Code cleanup, refactor, beautify, fast inspection

Waiting for task contract... 📋
Ready! ⏳
BANNER
sleep 999999" Enter

# Window 4: CLAUDE
tmux new-window -t "$SESSION_NAME" -n "claude"
tmux send-keys -t "$SESSION_NAME:claude" "cd '$PROJECT_ROOT' && clear" Enter
tmux send-keys -t "$SESSION_NAME:claude" "cat << 'BANNER'
╔════════════════════════════════════════════════════════════╗
║       🎨 CLAUDE (UI/Architecture/Orchestration)           ║
╚════════════════════════════════════════════════════════════╝

Status: ✅ READY (This session)
Role: UI/React, architecture, tests, orchestration
Memory: ✓ CLAUDE.md ✓ context ✓ dispatch ready

Current: Setting up 5-lane orchestration ✅
Next: Dispatch first task

Ready for dispatch! ⏳
BANNER
sleep 999999" Enter

# Select window 0 (THAM)
tmux select-window -t "$SESSION_NAME:0"

echo ""
echo "✅ 5-lane session created: '$SESSION_NAME'"
echo "   Window 0: THAM (Orchestrator)"
echo "   Window 1: CODEX-A (Backend Builder)"
echo "   Window 2: CODEX-B (Database Specialist)"
echo "   Window 3: GEMINI (Inspector) - $GEMINI_STATUS"
echo "   Window 4: CLAUDE (UI/Orchestrator)"
echo ""
echo "Controls:"
echo "   Ctrl+B, 0-4  = Switch to window"
echo "   Ctrl+B, C    = New window"
echo "   Ctrl+B, :kill-session lanes = Close"
echo ""
sleep 2

tmux attach-session -t "$SESSION_NAME"
