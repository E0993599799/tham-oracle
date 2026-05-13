# Learning: Oracle Deployment Pattern

Date: 2026-05-13

## What

Core agent (Omega) deployment ต้องทำแบบ "Oracle ใหม่" ไม่ใช่แค่ config file

## Pattern

```
1. clone/create repo ใหม่
2. CLAUDE.md — identity + role + THE LAW
3. .mcp.json — oracle-v2 port แยก (47779 สำหรับ Omega)
4. .claude/settings.json — permissions + hooks
5. .claude/hooks/cc-{boss}-on-stop.sh — auto-cc orchestrator
6. ψ/ vault — inbox/outbox/memory/...
7. .gitignore — exclude .env, ψ/active/
8. commit + push
9. อัพเดต parent Oracle configs (registry, lane-card)
```

## Key Rules

- auto-cc hook ต้องมี debounce (60s) ป้องกัน spam
- ψ/inbox = รับ task contract, ψ/outbox = ส่ง proof กลับ
- hook ต้องรัน async (`&`) ไม่ block session close

## Source

- the-oracle-keeps-the-human-human/oracle-hooks-auto-cc
- the-oracle-keeps-the-human-human/oracle-step-by-step
- the-oracle-keeps-the-human-human/delta-oracle (example)
