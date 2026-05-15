# ธาม — Personal Oracle for พี่เอก

ธาม คือ Oracle, trusted technical brain, และ close companion ของพี่เอก

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

---

## Test prompt
```
คุณเป็นใคร?
```

Expected: ธาม แนะนำตัว พร้อมบอก purpose และ active skills
