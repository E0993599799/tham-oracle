# maw-js Setup Guide

maw คือ CLI สำหรับ orchestrate Oracle fleet — ส่งข้อความ, ปลุก/หลับ Oracle, ดูหน้าจอ

## สถานะตอนนี้

| Component | สถานะ |
|-----------|--------|
| bun | ✅ v1.3.13 |
| go | ❌ ต้องติดตั้ง |
| ghq | ❌ ต้องติดตั้ง |
| maw | ❌ ต้องติดตั้ง |

## ติดตั้ง

```bash
bash scripts/install-maw-js.sh
```

จะติดตั้ง: go → ghq → maw-js → symlinks

## ตั้งค่า

```bash
bash scripts/setup-maw-config.sh
```

สร้าง: `~/.config/maw/maw.config.json` + fleet config

> ⚠️ `federationToken` ถูก generate แบบ local เท่านั้น — ห้าม commit

## คำสั่งหลัก

```bash
# ดู Oracle sessions
maw ls

# ปลุก Oracle
maw wake tham

# ส่งข้อความ
maw hey tham "สวัสดี — ทดสอบ maw"

# ดูหน้าจอ
maw peek tham

# ปลุกทั้งทีม + /recap
maw wake all --resume

# จบ session
maw done tham
```

## ข้อควรระวัง

| ปัญหา | สาเหตุ | วิธีแก้ |
|--------|--------|--------|
| `maw: not found` ใน tmux | PATH ขาด | `sudo ln -sf ~/.bun/bin/maw /usr/local/bin/maw` |
| session ซ้ำ exponential | `peers` ไม่ว่าง | `"peers": []` เสมอ (bug maw-js#175) |
| `ghq: not found` | go ไม่อยู่ใน PATH | `export PATH=$HOME/go/bin:$PATH` |

## Fleet Config

```
~/.config/maw/fleet/
└── 01-tham.json    ← Tham Oracle (E0993599799/tham-oracle)
```

เพิ่ม Oracle ใหม่ → สร้างไฟล์ `02-<name>.json` ใน fleet/
