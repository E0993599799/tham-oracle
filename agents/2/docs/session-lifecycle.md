# Session Lifecycle — ธาม

ทุก session มีจังหวะที่ต้องทำตาม ไม่มีข้อยกเว้น

```
/recap → ทำงาน → /rrr → commit → push → จบ
```

---

## 1. เริ่ม Session — /recap

ก่อนทำงานทุกครั้ง ธามจะ:
1. อ่าน retrospective ล่าสุด (ψ/memory/retrospectives/)
2. ดู git status
3. อ่าน ψ/ files ล่าสุด
4. อ่าน brain/memory/ACTIVE_INDEX.md
5. แนะนำว่าทำอะไรต่อ

### template output ของ /recap
```
## Recap — ธาม
HH:MM | YYYY-MM-DD

### Last Session
📡 Last retro: <date> | <topic>

### Git
main — clean / dirty (N files changed)

### Memory Gate
- baseline: <current state>
- risk flags: <any>

### What's next?
1. <suggested next action>
```

---

## 2. ระหว่าง Session — ทำงาน

- ทำ task ที่ได้รับ
- commit บ่อยๆ (อย่าสะสม uncommitted changes)
- ถ้าติดปัญหา → รายงานทันที
- ถ้าเรียนรู้อะไรใหม่ → `oracle_learn` หรือ mem-write

---

## 3. จบ Session — /rrr

ก่อนปิด session ธามจะสร้าง retrospective:

```bash
bash scripts/new-rrr.sh "slug-ของ-session"
```

สร้างไฟล์ที่: `ψ/memory/retrospectives/YYYY-MM/DD/HH.MM_slug.md`

### เนื้อหา /rrr
1. Session Summary
2. Timeline (สิ่งที่ทำ)
3. Files Modified
4. AI Diary (150+ words, first-person)
5. Honest Feedback (100+ words, 3 friction points)
6. Lessons Learned
7. Next Steps

---

## 4. DocCon — Commit + Push

หลัง /rrr — **ห้ามข้าม**:

```bash
git add ψ/memory/
git commit -m "docs: session retrospective + lessons — <date>"
git push
```

---

## 5. Handoff (ถ้าต้องการ)

```bash
# สร้าง handoff file
# ใช้ templates/handoff-template.md
```

/recap ของ session ถัดไปจะอ่าน handoff นี้

---

## สรุป Standing Orders

| จังหวะ | Action | บังคับ |
|--------|--------|--------|
| ต้น session | `/recap` หรือ `mem-read` | ✅ |
| ระหว่าง session | commit บ่อยๆ | ✅ |
| จบ session | `/rrr` → `new-rrr.sh` | ✅ |
| หลัง /rrr | `git commit + push` | ✅ |
| คุยกับ Oracle อื่น | cc BoB | ✅ |
