# Oracle Communication Law

กฎการสื่อสารระหว่าง Oracles — ห้ามละเมิด

---

## 2 ช่องทางหลัก

### 1. /talk-to (Primary)
```
/talk-to dev "ช่วย review PR #42 ให้หน่อย"
/talk-to bob "cc: เสร็จ task แล้ว — commit abc1234"
```
- สร้าง audit trail ใน oracle-v2 database
- ทุก Oracle เห็นได้ใน threads
- BoB ตรวจสอบได้

### 2. maw hey (Fallback)
```bash
maw hey dev "ช่วย review PR #42 ให้หน่อย"
maw hey bob "cc: เสร็จ task แล้ว"
```
- ใช้เมื่อ /talk-to ใช้ไม่ได้
- ส่งผ่าน file → Oracle อื่นอ่านเมื่อ wake

---

## THE LAW (ห้ามละเมิด)

### 1. ตอบทุกข้อความ
Oracle อื่นส่งมา → **ต้องตอบ**
ตอบ, ทำ, หรือ push back ก็ได้ — แต่ **ห้ามเงียบ**

### 2. cc BoB ทุกครั้ง
เมื่อคุยกับ Oracle อื่น → cc BoB ด้วยเสมอ:
```
/talk-to bob "cc: คุยกับ dev เรื่อง PR #42"
```

### 3. รายงานเมื่อเสร็จ
```
/talk-to bob "เสร็จแล้ว — สรุป: review PR #42, approve แล้ว"
```

### 4. รายงานทันทีเมื่อติดปัญหา
```
/talk-to bob "ติดปัญหา — ต้องการ access to staging DB"
```

---

## ตัวอย่าง Workflow

```
Dev → QA: /talk-to qa "test branch feat/api ด้วย"
Dev → BoB: /talk-to bob "cc: ส่ง feat/api ให้ QA แล้ว"

QA → Dev: /talk-to dev "พบ bug line 45 — ส่ง fix มา"
QA → BoB: /talk-to bob "cc: QA found bug in feat/api"

Dev → QA: /talk-to qa "fix แล้ว commit def5678"
Dev → BoB: /talk-to bob "cc: fix bug ใน feat/api แล้ว"

QA → Dev: /talk-to dev "approve ✓"
QA → BoB: /talk-to bob "cc: feat/api QA passed"
```

---

## สำหรับ ธาม (ตอนนี้ยัง single Oracle)

- ใช้ `/talk-to` และ `maw hey` เมื่อ multi-Oracle พร้อม
- BoB = manager Oracle เมื่อมี fleet
- ตอนนี้ cc BoB ใน brain/proofs หรือ session-close แทน
