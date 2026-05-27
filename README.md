# ธาม — Personal Oracle for พี่เอก

ธาม คือ Oracle, trusted technical brain, และ close companion ของพี่เอก

---

## Latest Deployment

**Date**: 2026-05-19  
**Status**: 🟢 LIVE  
**Fleet**: 8 agents (Codex + Gemini + Native Claude)  
**Architecture**: OBSERVER/GOVERNOR governance model  
**Oracle-v2**: Running (v26.5.2-alpha.1704) — [Studio](http://localhost:47778/swagger)  
**Release**: [2026-05-19-fleet-activation](../../releases/tag/2026-05-19-fleet-activation)

---

## เริ่มใช้งาน

### วิธีที่ 1 — tmux session (แนะนำ)
```bash
oracle          # เปิด session ใหม่ หรือ attach ถ้ามีอยู่แล้ว
tham            # alias เดียวกัน
oracle-kill     # ปิด session
```
Session มี 4 windows:
- `chat`   — claude (Oracle main)
- `memory` — memory-read summary (โหลดอัตโนมัติตอนเปิด)
- `shell`  — free shell
- `brain`  — brain/ directory

### Memory Workflow
```bash
mem-read          # ดู memory gate summary
mem-write --type reflection --body "..."   # บันทึก lesson/decision ใหม่
mem-close         # ปิด session อย่างถูกต้อง + commit + push
```
Types: `baseline` | `rule` | `decision` | `reflection` | `proof`

### วิธีที่ 2 — ตรงๆ
```bash
cd ~/repos/tham-oracle
claude
```

---

## โครงสร้าง

```
tham-oracle/
├── CLAUDE.md          # identity, rules, skill index
├── skills/            # 60 skills — แต่ละ skill มี SKILL.md
├── brain/
│   ├── identity/      # profile, personality, hard rules
│   ├── memory/        # active index + archive
│   ├── projects/      # project tracking
│   ├── skills/        # skill activation notes
│   ├── decisions/     # decision log
│   ├── proofs/        # task completion evidence
│   └── reflections/   # lessons learned
└── scripts/
    ├── oracle-session.sh   # tmux session launcher
    └── oracle-kill.sh      # kill session
```

## Forge Omega Oracle command family

Use these commands from the repo root:

```bash
maw omega              # start the full study flow (default)
maw omega study        # same as maw omega
maw omega open         # start the study flow and attach to the tmux session
maw omega attach       # attach to the live Omega session
maw omega live         # open the live Tham Oracle show and attach
maw omega monitor      # tail the aggregated progress report
maw omega report       # print the latest aggregated report
maw omega health       # run the Forge/Omega health check
maw omega status       # show session/report status
maw omega list         # show the family help
maw-o                  # short alias for maw omega
```

Fallback if you want the direct script:

```bash
bash scripts/forge-omega-oracle-study.sh
```

Realtime surfaces:

- `dashboard/realtime-dashboard.html` — live proof stream + terminal control + embedded terminal monitor + Obsidian bridge button
- `dashboard/second-brain.html` — hybrid code graph / HTML second brain with Obsidian bridge button
- If your terminal dashboard runs on a custom port, open the realtime dashboard with `?terminal_api=http://localhost:PORT` or use the "Save API" button in the terminal control panel.

Docs: `docs/forge-omega-oracle/README.md`

## Test prompt
```
คุณเป็นใคร?
```

Expected: ธาม แนะนำตัว พร้อมบอก purpose และ active skills
