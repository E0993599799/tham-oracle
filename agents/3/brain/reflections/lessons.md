# Lessons Learned

---

## 2026-05-12 — Always check step completion before advancing
**What happened**: Step 03 was declared ready but only 3/8 skills were installed.
**Root cause**: No explicit checklist was run against the target list in CLAUDE.md before reporting ready.
**New rule**: Before declaring a step complete, diff the target list in CLAUDE.md against what actually exists on disk.
**Skill to update**: `debugging` — add "verify against spec before reporting OK"

---
