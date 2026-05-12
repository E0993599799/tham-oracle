# Project: Tham Oracle Build

Status: active
Last updated: 2026-05-12

## Goal
สร้าง Oracle repo ให้เป็น persistent, skilled, memory-aware agent สำหรับพี่เอก

## Current State

| Step | รายการ | สถานะ |
|------|--------|--------|
| 01 | Repo + GitHub | ✅ done |
| 02 | CLAUDE.md identity | ✅ done |
| 03 | Skills (60 อัน) | ✅ done |
| 04 | Brain Structure (7 areas) | ✅ done |
| 05 | Session Workflow | ✅ done |
| 06 | Memory Write-back | ✅ done |

## Proof
- Commit `09b627e` — brain structure
- Scripts: `oracle-session.sh`, `oracle-kill.sh`, `memory-read.sh`, `memory-write.sh`, `session-close.sh`
- Aliases: `oracle`, `tham`, `oracle-kill`, `mem-read`, `mem-write`, `mem-close` ใน `~/.bashrc`

## Risks / Blockers
- alias ต้อง `source ~/.bashrc` ก่อนใช้ในเซสชั่นปัจจุบัน

## Next Action
- Step 07: ระบุจาก พี่เอก
