#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/mnt/d/01 Main Work/Boots/Agentic AI/mission-control"
CONTROL_DIR="$ROOT_DIR/tham-oracle"
SESSION="${SESSION:-tham-overnight}"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$CONTROL_DIR/reports/autonomous-fleet/${RUN_STAMP}-overnight-oracle-supervision"
PROMPT_DIR="$RUN_DIR/prompts"
SCRIPT_DIR="$RUN_DIR/scripts"
LOG_DIR="$RUN_DIR/logs"
PROGRESS_DIR="$CONTROL_DIR/reports/progress"
INBOX="$PROGRESS_DIR/tham-inbox.log"
WATCHDOG_SCRIPT="$CONTROL_DIR/scripts/overnight-oracle-watchdog.sh"
mkdir -p "$PROMPT_DIR" "$SCRIPT_DIR" "$LOG_DIR" "$PROGRESS_DIR" "$CONTROL_DIR/reports/escalations"
: > "$INBOX"

echo "$RUN_DIR" > "$CONTROL_DIR/reports/autonomous-fleet/LATEST_OVERNIGHT_RUN"

declare -A RUNTIME
RUNTIME[core]="codex"
RUNTIME[codex]="codex"
RUNTIME[luxi]="gemini"
RUNTIME[watchdog]="gemini"

COMMON_POLICY="
ภาษา: ไทยเป็นหลัก, อังกฤษเสริมได้เมื่อจำเป็น.
Control repo: $CONTROL_DIR
Workspace root: $ROOT_DIR
Before doing real work, verify: pwd ; git rev-parse --show-toplevel ; git remote -v (inside the repo you are editing/checking).
Safety rules: ห้าม commit, push, merge, deploy, delete, git reset, git clean, force-push, หรือเปิดเผย secrets. แก้ไขเฉพาะส่วนที่จำเป็นและอธิบายหลักฐานทุกครั้ง. ถ้าเส้นทาง/ข้อมูลไม่ชัด ให้รายงาน BLOCKED พร้อมหลักฐาน แทนการเดา.
Reporting contract: ทุกไม่เกิน 3 นาที ต้อง append อัปเดตสั้น ๆ ลง progress file ของคุณ พร้อมสถานะ CURRENT / BLOCKER / NEXT. เมื่อทำงานสำคัญเสร็จให้เขียน RESULT / PROOF / RISKS / NEXT.
Shared inbox: $INBOX
Proof requirements: exact files inspected/changed, commands run, validation output, secret-scan statement for changed files, risks, rollback path, next action.
"

write_prompt() {
  local agent="$1"
  local title="$2"
  local body="$3"
  cat > "$PROMPT_DIR/$agent.md" <<EOF
# $agent — $title

คุณเป็น worker ใต้การควบคุมของ THAM/Hermes orchestrator ใน overnight run นี้.

$COMMON_POLICY

Progress file ของคุณ: $PROGRESS_DIR/$agent.md

Active task list from human:
1) check-deploy — ตรวจสถานะ deployment ของโปรเจกต์ ORRY บน Vercel และ smoke/admin login
2) luxi-review-loop — เรียก agent รีวิว UI/UX และ code review สำหรับ ORRY แล้วแก้ตามรีวิวแบบ loop จนไม่มีประเด็นสำคัญ
3) temperature-standard — วิเคราะห์ระบบบันทึกอุณหภูมิและเพิ่มหน้าฟอร์มมาตรฐาน + dashboard ลงอุณหภูมิรายเวลาให้สวยทันสมัย
4) temperature-review-loop — ทำ review loop สำหรับงานอุณหภูมิด้วย UI/UX + code review agents

Important project paths:
- ORRY app: $ROOT_DIR/orry
- Temperature app candidate: $ROOT_DIR/cloudflare-temperature-portal
- Temperature schema reference: $ROOT_DIR/supabase/sql/temperature_monitoring_core.sql
- Prior proof area: $CONTROL_DIR/reports/

งานของคุณ:
$body

ตอบสนองแบบลงมือทำทันที. ทุกครั้งที่เปลี่ยนสถานะ ให้ append progress file ของคุณและสรุป 1-2 บรรทัดลง $INBOX ด้วย.
EOF
}

write_prompt core "ORRY deploy/status controller" "
โฟกัสงาน check-deploy.
- Inspect $ROOT_DIR/orry แบบ read-first.
- ตรวจ git branch/status, package scripts, และ deployment clues ของ Vercel.
- ถ้ามี Vercel CLI/config พร้อม ให้ตรวจสถานะ production deployment แบบปลอดภัย (read-only) และทำ smoke checks ที่ root/login/admin login path ที่หาเจอจากโค้ด.
- ถ้าต้องใช้ credential หรือ env ที่ไม่มี ให้รายงาน BLOCKED พร้อม exact missing item.
- เป้าหมายคืนนี้คือให้ได้ governor-ready status ที่ชัดเจน: deployed/not deployed, latest blocker, admin login route, smoke result.
- ถ้ามีการแก้ไขเล็กน้อยเพื่อเพิ่ม observability หรือ safer smoke automation ได้ และเป็น high-confidence, scoped, no-deploy edit ก็ทำได้.
"

write_prompt codex "Temperature implementation lead" "
โฟกัสงาน temperature-standard.
- สำรวจ $ROOT_DIR/cloudflare-temperature-portal และ schema reference $ROOT_DIR/supabase/sql/temperature_monitoring_core.sql
- หา flow ปัจจุบันของ temperature logging, hourly records, forms, dashboard, และ data model.
- ถ้าพบตำแหน่งแก้ไขชัดเจน ให้ implement หน้าฟอร์มมาตรฐานสำหรับบันทึกอุณหภูมิ + dashboard รายชั่วโมงที่ดู modern/clean โดยแก้แบบ scoped และ validate เท่าที่ทำได้.
- ถ้าโปรเจกต์/เส้นทางไม่ตรงกัน ให้รายงาน BLOCKED พร้อม path mapping ที่ถูกต้องและ smallest safe next action.
- ทำงานแบบ proof-first: ระบุไฟล์ที่แก้, screenshot-equivalent evidence ถ้ามี, และคำสั่ง build/test ที่รัน.
"

write_prompt luxi "ORRY UI/UX + code review loop" "
โฟกัสงาน luxi-review-loop สำหรับ ORRY.
- ตรวจ $ROOT_DIR/orry ทั้งจากโค้ดและ asset/reports ที่มีอยู่.
- ทำ review loop แบบ reviewer: UI/UX, information architecture, admin login flow, accessibility, responsiveness, code quality, regression risk.
- ถ้าพบประเด็นสำคัญและมี fix ที่ scoped/high-confidence ให้แก้เองได้ภายใน repo ORRY โดยยังห้าม deploy/commit.
- ทุก cycle ให้เขียนว่า REVIEW FINDINGS / FIX APPLIED / REMAINING RISKS.
- เป้าหมายคือทำซ้ำจนเหลือ no major issue หรือชัดเจนว่าติด blocker อะไร.
"

write_prompt watchdog "Temperature review + watchdog lane" "
โฟกัสงาน temperature-review-loop.
- ตรวจงานใน $ROOT_DIR/cloudflare-temperature-portal และ cross-check กับ schema reference $ROOT_DIR/supabase/sql/temperature_monitoring_core.sql
- ทำ review loop เชิง UI/UX + code review + data integrity สำหรับงาน temperature.
- อ่าน progress ของ codex lane จาก $PROGRESS_DIR/codex.md ถ้ามี แล้ว review/critique พร้อมเสนอ patch set เล็ก ๆ หรือแก้เองได้เมื่อ high-confidence.
- จับ consistency ของ labels, units, timestamps, hourly aggregation, empty/error/loading states, and form validation.
- เป้าหมายคือให้ THAM ได้สถานะว่า implementation พร้อมแค่ไหน, risk อะไรเหลือ, และควร iterate จุดไหนต่อ.
"

make_runner() {
  local agent="$1"
  local runtime="${RUNTIME[$agent]}"
  local prompt="$PROMPT_DIR/$agent.md"
  local progress="$PROGRESS_DIR/$agent.md"
  local log="$LOG_DIR/$agent.log"
  local runner="$SCRIPT_DIR/$agent.sh"
  cat > "$runner" <<EOF
#!/usr/bin/env bash
set +e
ROOT_DIR='$ROOT_DIR'
CONTROL_DIR='$CONTROL_DIR'
PROGRESS='$progress'
INBOX='$INBOX'
LOG='$log'
PROMPT='$prompt'
AGENT='$agent'
RUNTIME='$runtime'
mkdir -p "\$(dirname "$progress")" "\$(dirname "$log")"
printf '[%s] %s CURRENT: task received, starting now\n' "\$(date -Iseconds)" "$agent" | tee -a "$progress" "$INBOX"
(
  while true; do
    sleep 150
    last_line="\$(tail -n 1 "$progress" 2>/dev/null || true)"
    printf '[%s] %s HEARTBEAT: %s\n' "\$(date -Iseconds)" "$agent" "\${last_line:-no progress yet}" >> "$INBOX"
  done
) & HEARTBEAT_PID=\$!
trap 'kill \$HEARTBEAT_PID 2>/dev/null || true' EXIT
cd "\$ROOT_DIR" || exit 2
QUERY="\$(cat "\$PROMPT")"
TOOLSETS='terminal,file,web,session_search,skills'
SKILLS=''
case "\$AGENT" in
  core) SKILLS='vercel-production-deployment,debug-mantra' ;;
  codex) SKILLS='cross-platform-node-production-validation,debug-mantra' ;;
  luxi) SKILLS='scrutinize,debug-mantra' ;;
  watchdog) SKILLS='scrutinize,debug-mantra' ;;
esac
if [ -n "\$SKILLS" ]; then
  hermes chat -Q -t "\$TOOLSETS" -s "\$SKILLS" -q "\$QUERY" 2>&1 | tee -a "\$LOG"
else
  hermes chat -Q -t "\$TOOLSETS" -q "\$QUERY" 2>&1 | tee -a "\$LOG"
fi
STATUS=\${PIPESTATUS[0]}
printf '[%s] %s EXIT: %s\n' "\$(date -Iseconds)" "\$AGENT" "\$STATUS" | tee -a "\$PROGRESS" "\$INBOX"
exec bash
EOF
  chmod +x "$runner"
}

for agent in core codex luxi watchdog; do
  make_runner "$agent"
done

cat > "$RUN_DIR/dispatch-summary.md" <<EOF
# Overnight Oracle Supervision Dispatch

Timestamp: $RUN_STAMP
Session: $SESSION
Control repo: $CONTROL_DIR
Workspace root: $ROOT_DIR
Run dir: $RUN_DIR
Watchdog script: $WATCHDOG_SCRIPT

Workers:
- core: ORRY deployment/status controller
- codex: temperature implementation lead
- luxi: ORRY UI/UX + code review loop
- watchdog: temperature review + watchdog lane

Rules:
- THAM/Hermes is orchestrator/controller only
- every worker must update progress at least every 3 minutes
- if silent, watchdog will ping the pane and log escalation
- no commit/push/deploy/delete/reset/clean/force ops
EOF

if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n overnight -c "$CONTROL_DIR" "bash -lc 'cd \"$CONTROL_DIR\" && printf \"[%s] THAM orchestrator awake. Waiting for worker updates.\\n\" \"\$(date -Iseconds)\" | tee -a \"$INBOX\" && tail -n 200 -F \"$INBOX\"'"
tmux split-window -t "$SESSION:overnight.0" -h -c "$ROOT_DIR" "bash '$SCRIPT_DIR/core.sh'"
tmux split-window -t "$SESSION:overnight.1" -v -c "$ROOT_DIR" "bash '$SCRIPT_DIR/codex.sh'"
tmux split-window -t "$SESSION:overnight.2" -v -c "$ROOT_DIR" "bash '$SCRIPT_DIR/luxi.sh'"
tmux split-window -t "$SESSION:overnight.3" -v -c "$ROOT_DIR" "bash '$SCRIPT_DIR/watchdog.sh'"
tmux select-layout -t "$SESSION:overnight" tiled >/dev/null || true
for pair in "0 THAM" "1 core" "2 codex" "3 luxi" "4 watchdog"; do
  pane="${pair%% *}"
  title="${pair#* }"
  tmux select-pane -t "$SESSION:overnight.$pane" -T "$title"
done

tmux set-option -t "$SESSION" remain-on-exit on >/dev/null
tmux set-window-option -t "$SESSION:overnight" pane-border-status top >/dev/null

echo "OVERNIGHT_ORACLE_SUPERVISION_DISPATCHED"
echo "session=$SESSION"
echo "run_dir=$RUN_DIR"
tmux list-panes -t "$SESSION:overnight" -F '#{pane_index} title=#{pane_title} cmd=#{pane_current_command} path=#{pane_current_path}'
