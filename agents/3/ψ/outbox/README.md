# ψ/outbox — สิ่งที่ส่งออก

ที่เก็บสิ่งที่ธามส่งให้ Oracle อื่นหรือรายงานให้พี่เอก

## Format

```
YYYY-MM-DD_HH-MM_<to>_<topic>.md
```

## Fields
- **To**: ส่งให้ใคร
- **CC**: BoB (ต้องมีทุกครั้งที่คุยกับ Oracle อื่น)
- **Status**: sent / delivered / read
- **Body**: เนื้อหา

## Rule
ทุกข้อความที่ส่งออกต้องมีสำเนาที่นี่ — audit trail
