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
| 07 | Oracle Communication Law | ✅ done |
| 08 | Session Lifecycle | ✅ done |
| 09 | Multi-Oracle config | ✅ done |
| 10 | maw-js setup | ✅ done |
| 11 | Forge/Omega Integration | ✅ done |

## Proof
- Commit `09b627e` — brain structure
- Commit `2dbb8af` — steps 04-10 complete
- Scripts: `oracle-session.sh`, `oracle-kill.sh`, `memory-read.sh`, `memory-write.sh`, `session-close.sh`
- Scripts: `forge-omega-health.sh`, `start-oracle-v2-http.sh`, `oracle-fleet.sh`
- Aliases: `oracle`, `tham`, `oracle-kill`, `mem-read`, `mem-write`, `mem-close` ใน `~/.bashrc`
- Configs: `agent-registry.json`, `forge-omega-config.json`, lane-cards (3)
- ψ vault: complete (10 directories)

## Risks / Blockers
- alias ต้อง `source ~/.bashrc` ก่อนใช้ในเซสชั่นปัจจุบัน
- oracle-v2 HTTP ต้องรัน manually: `bash scripts/start-oracle-v2-http.sh`
- Core agent ยังเป็น template รอ deployment

## Next Action
- Run health check: `bash scripts/forge-omega-health.sh`
- เริ่ม oracle stack: `bash scripts/start-oracle-local-stack-tmux.sh`
