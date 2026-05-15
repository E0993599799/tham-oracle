# Agent 1 Task — Database Schema (ERP Foundation)

## งานของคุณ
ออกแบบและสร้าง Supabase SQL migration สำหรับ ERP Foundation module

## Project Context
ERP system ใช้ Next.js 15 + Supabase + TypeScript
ทุก table ต้องมี: org_id (multi-tenancy), RLS policies, UUID pk, timestamps

## สิ่งที่ต้องสร้าง (ใน /root/repos/tham-oracle/agents/1/output/migrations/)

### 1. Organizations table
```sql
-- organizations: root tenant table
-- columns: id, name, slug, plan, settings (jsonb), created_at, updated_at
-- RLS: users ดูได้เฉพาะ org ของตัวเอง
```

### 2. Users / Profiles table
```sql
-- profiles: extend Supabase auth.users
-- columns: id (fk auth.users), org_id, full_name, role (enum), avatar_url
-- roles enum: super_admin, admin, manager, staff, viewer
-- RLS: authenticated users เห็นเฉพาะ org ของตัวเอง
```

### 3. Audit Log table
```sql
-- audit_logs: ทุก action สำคัญต้อง log
-- columns: id, org_id, user_id, action, table_name, record_id, old_data, new_data, ip_address, created_at
-- RLS: admin ขึ้นไปดูได้
```

## Output Format
สร้างไฟล์ SQL แยกแต่ละ table:
- `output/migrations/001_organizations.sql`
- `output/migrations/002_profiles.sql`
- `output/migrations/003_audit_logs.sql`

แต่ละไฟล์ต้องมี:
1. CREATE TYPE (enums ถ้ามี)
2. CREATE TABLE
3. Indexes
4. Triggers (updated_at)
5. ALTER TABLE ENABLE ROW LEVEL SECURITY
6. CREATE POLICY (select/insert/update/delete)

## เมื่อทำเสร็จ
```bash
git add output/migrations/
git commit -m "feat(schema): ERP foundation tables — org, profiles, audit_log"
```
