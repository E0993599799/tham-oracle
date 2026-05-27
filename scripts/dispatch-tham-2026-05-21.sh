#!/usr/bin/env bash
# Tham Oracle dispatch — 2026-05-21
# Delegates Mission 0 → A → B to Codex GPT-5.5 at 50-tham:codex-gpt55
# พี่เอก: run this with M0 / M1 / M2 / all as argument
# After each mission, REVIEW the proof before triggering the next.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INBOX="${REPO_ROOT}/ψ/inbox/codex"
CODEX_PANE="50-tham:codex-gpt55"

require_pane() {
  if ! tmux has-session -t 50-tham 2>/dev/null; then
    echo "❌ tmux session '50-tham' missing — start codex first" >&2
    exit 1
  fi
  if ! tmux list-windows -t 50-tham -F '#{window_name}' | grep -q '^codex-gpt55'; then
    echo "❌ window 'codex-gpt55' missing in 50-tham" >&2
    exit 1
  fi
  echo "✅ codex pane alive: ${CODEX_PANE}"
}

send_mission() {
  local id="$1" path="$2" body="$3"
  if [[ ! -f "$path" ]]; then
    echo "❌ contract missing: $path" >&2
    exit 1
  fi
  echo "──────────────────────────────────────"
  echo "Dispatching ${id} → ${CODEX_PANE}"
  echo "Contract:    ${path}"
  echo "──────────────────────────────────────"
  maw send-text "${CODEX_PANE}" "${body}"
  echo "✅ ${id} dispatched. Watch progress: tmux attach -t 50-tham \\; select-window -t codex-gpt55"
}

mission_0() {
  local body
  body=$(cat <<EOF
ภารกิจ Tham → Codex GPT-5.5 (Mission 0 — Workflow Fix)

อ่าน contract:
${INBOX}/MISSION-0-workflow-fix.json

อ่าน audit:
${REPO_ROOT}/proofs/2026-05-21/WORKFLOW-AUDIT.md

ทำ F2 + F3 + F4 + F5 ตาม spec — แก้เฉพาะที่ระบุ
proof: ${REPO_ROOT}/proofs/2026-05-21/MISSION-0-workflow-fix.json
ห้าม git commit — รอ พี่เอก review diff
EOF
)
  send_mission "M0" "${INBOX}/MISSION-0-workflow-fix.json" "${body}"
}

mission_a() {
  local body
  body=$(cat <<EOF
ภารกิจ A — Obsidian Full Migration (per claude-obsidian/WIKI.md)

contract: ${INBOX}/MISSION-A-obsidian-reorg.json
schema:   /mnt/d/Obsidian/claude-obsidian/WIKI.md

Phase 1 → 5 ตามลำดับ — checkpoint หลังทุก batch (200 ไฟล์)
backup ด้วย git tag 'pre-migration-2026-05-21' ก่อน
ห้าม touch /mnt/d/Obsidian/claude-obsidian และ /mnt/d/Obsidian/iCloudDrive
ถ้า uncertainty >15% → MISSION-A-block-categorization.md + หยุด
proof หลังทุก phase
EOF
)
  send_mission "M1" "${INBOX}/MISSION-A-obsidian-reorg.json" "${body}"
}

mission_b() {
  local body
  body=$(cat <<EOF
ภารกิจ B — LangGraph runs the wiki

contract: ${INBOX}/MISSION-B-langgraph-wiki.json
schema:   /mnt/d/Obsidian/claude-obsidian/WIKI.md

ลำดับ: research → design → deliverables → smoke test
test กับ /tmp/test-vault เท่านั้น (อย่ารันบน /mnt/d/Obsidian จน M1 lint clean)
checkpoint ทุก node, idempotent ingest, frontmatter strict
EOF
)
  send_mission "M2" "${INBOX}/MISSION-B-langgraph-wiki.json" "${body}"
}

mission_temp() {
  local body
  body=$(cat <<EOF
ภารกิจ Temperature Record + HA Collector — End-to-End Deploy

contract: ${INBOX}/MISSION-TEMP-deploy-collector.json
Phase 0 → 5:
- Phase 0: reconcile 2 Supabase projects (temperature-record SG vs SMD-Project Tokyo) — default option B
- Phase 1: re-issue Supabase CLI token (พี่ทำใน browser, รอ flag file)
- Phase 2: supabase db push migration
- Phase 3: deploy ha_data_collector.py ไป GCE VM (stage commands; ห้ามรัน foreground PowerShell)
- Phase 4: re-point Vercel env (ถ้า option B)
- Phase 5: verify + finish existing Edge Functions (temperature-report-dispatch, temperature-refrigerator-daily)
ห้าม push secrets, ห้าม auto-deploy — stage commands ให้พี่
EOF
)
  send_mission "MTEMP" "${INBOX}/MISSION-TEMP-deploy-collector.json" "${body}"
}

mission_dash() {
  local body
  body=$(cat <<EOF
ภารกิจ Forge Omega V2 Dashboard — Phase 1-3 UX/UI

contract: ${INBOX}/MISSION-DASH-forge-omega-v2.json
research:  brain/decisions/2026-05-17_omega-uxui-research-findings.md
repo:      /mnt/d/Git/forge-omega-v2 (Next.js 16 + React 19 + Tailwind 4)

Phase 1: Critical UX (Fleet Health Card, Status Badges, Live indicator)
Phase 2: Real-time Feedback (skeletons, optimistic UI, toasts, error UX)
Phase 3: Interactivity (confirm dialogs, form validation, keyboard nav)

Code edits จาก WSL; build/screenshot จาก Windows PS เท่านั้น (Turbopack bug)
EOF
)
  send_mission "MDASH" "${INBOX}/MISSION-DASH-forge-omega-v2.json" "${body}"
}

mission_tests() {
  local body
  body=$(cat <<EOF
ภารกิจ TASK-002 Test Suite Completion

contract: ${INBOX}/MISSION-TESTS-task002.json
Remaining: api-routes.integration.ts (25 tests) + coverage report (target ≥80%)
Target paths: server/proof-playback-api.py, server/websocket-server.py, dashboard-next/app/api/

ห้าม modify production code เพื่อให้ tests ผ่าน — fix tests หรือ report bug
EOF
)
  send_mission "MTESTS" "${INBOX}/MISSION-TESTS-task002.json" "${body}"
}

mission_docs() {
  local body
  body=$(cat <<EOF
ภารกิจ Phase 4 Docs Polish

contract: ${INBOX}/MISSION-DOCS-phase4.json
ไฟล์: docs/phase-4/{api,architecture,deployment,overview,troubleshooting}.md

- Strip UTF-8 BOM และแก้ garbled text (ealtime → realtime, un-realtime → run-realtime)
- Cross-link 5 docs
- เพิ่ม Quick Start ใน overview.md
- Mermaid diagram ใน architecture.md
- Save UTF-8 NO BOM
EOF
)
  send_mission "MDOCS" "${INBOX}/MISSION-DOCS-phase4.json" "${body}"
}

mission_fleet() {
  local body
  body=$(cat <<EOF
ภารกิจ Fleet Recovery (queue หลัง M0 — gated on M0 proof)

contract: ${INBOX}/MISSION-FLEET-RECOVERY.json
อ่าน M0 proof ก่อน: ${REPO_ROOT}/proofs/2026-05-21/MISSION-0-workflow-fix.json

PHASE 1 → 6 ตามลำดับ:
- Phase 1: gate on M0 (อย่าทำถ้า M0 ไม่ green)
- Phase 2: เปลี่ยน fictional cx/gpt-5.5 → real 9router model (default: glm-cn/glm-5.1)
- Phase 3: fix Gemini CLI หรือ bypass ผ่าน 9router HTTP
- Phase 4: Ollama decision (default: skip)
- Phase 5: respawn fleet 1 worker ต่อครั้ง — ห้าม touch 50-tham
- Phase 6: emit MISSION-FLEET-RECOVERY.json proof

ห้าม run foreground PowerShell, ห้าม commit, ห้าม kill 50-tham panes
EOF
)
  send_mission "MFLEET" "${INBOX}/MISSION-FLEET-RECOVERY.json" "${body}"
}

usage() {
  cat <<EOF
Usage: $0 {M0|MFLEET|M1|M2|all|status}

  M0       Send Mission 0  (workflow fix — F2+F3+F4+F5)
  MFLEET   Send Fleet Recovery (gated on M0 proof)
  TEMP     Send Mission TEMP — Temperature Record + HA Collector deploy (พี่ priority)
  DASH     Send Mission DASH — Forge Omega V2 Dashboard Phase 1-3
  M1       Send Mission A  — Obsidian full migration
  M2       Send Mission B  — LangGraph + Obsidian
  TESTS    Send Mission TESTS — TASK-002 test suite completion
  DOCS     Send Mission DOCS  — Phase 4 docs polish
  all      Send M0 only; wait for พี่เอก approval between each subsequent
  status   Show Codex pane state + recent proofs

Recommended:
  $0 status        # confirm pane health
  $0 M0            # run, wait, review proof
  $0 M1            # after M0 proof clean
  $0 M2            # after M1 lint clean
EOF
}

show_status() {
  require_pane
  echo
  echo "── Codex pane tail ──"
  tmux capture-pane -t "${CODEX_PANE}" -p | tail -15
  echo
  echo "── Recent proofs ──"
  ls -lt "${REPO_ROOT}/proofs/2026-05-21/" 2>/dev/null | head -10 || echo "(no proofs yet)"
}

case "${1:-}" in
  M0)      require_pane; mission_0 ;;
  MFLEET)  require_pane; mission_fleet ;;
  TEMP)    require_pane; mission_temp ;;
  DASH)    require_pane; mission_dash ;;
  M1)      require_pane; mission_a ;;
  M2)      require_pane; mission_b ;;
  TESTS)   require_pane; mission_tests ;;
  DOCS)    require_pane; mission_docs ;;
  all) require_pane; mission_0
       echo
       echo "▶ M0 sent. After Codex finishes and พี่ reviews proof, re-run with: $0 M1"
       ;;
  status) show_status ;;
  *)   usage; exit 1 ;;
esac
