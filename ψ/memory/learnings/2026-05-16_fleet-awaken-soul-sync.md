---
pattern: "Read CLI source code before trying flags — ghqFind is case-sensitive, silent on near-misses"
date: 2026-05-16
source: rrr: tham-oracle
concepts: [maw, ghq, fleet, case-sensitivity, oracle-awakening, soul-sync]
---

# Fleet Expansion: Read Source First, Then Act

## What I learned

เมื่อ CLI tool ทำงานไม่ตามที่คาด วิธีที่เร็วที่สุดคืออ่าน source code ไม่ใช่ลอง flags ต่างๆ

`maw oracle` ใช้ `ghqFind(/{name}-oracle$)` ซึ่ง:
- Case-sensitive: `Omega` ≠ `omega`
- ต้องการ dedicated repo ต่อ agent — share repo ไม่ได้
- ไม่ใช้ `project_repos` field ในการ detect local paths — เป็นแค่ metadata

## Why it matters

Silent failures เป็นปัญหามากกว่า loud errors เพราะมันดูเหมือนสำเร็จแต่จริงๆ ไม่ได้ผล
`(not cloned)` แค่หมายความว่า ghqFind หาไม่เจอ — ไม่ได้บอกว่า *ทำไม* ไม่เจอ

การเพิ่ม `project_repos` field โดยไม่อ่าน scan source = dead code ที่เสีย 2-3 รอบ iteration

## Apply next time

1. **อ่าน implementation ก่อน assume behavior** — เมื่อ `maw oracle` ทำงานแปลก ให้ `cat ~/.maw/plugins/oracle/impl-helpers.ts` ก่อนเสมอ
2. **Test ghq detection ก่อน register** — `ghq list | grep -i <name>` เพื่อ confirm path case
3. **ใช้ `--local` เมื่อ sync registry** — `--all` ดูด remote orgs เข้ามาด้วย ต้องลบทีหลัง
4. **Each agent needs its own repo** — maw 1 ghq path = 1 oracle เท่านั้น
