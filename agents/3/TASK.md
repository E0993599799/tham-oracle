# Agent 3 Task — Backend API & Auth (ERP Foundation)

## งานของคุณ
สร้าง Next.js API routes และ Supabase Edge Functions สำหรับ auth + RBAC

## Tech Stack
- Next.js 15 API Routes (App Router)
- Supabase (@supabase/ssr, service_role for admin)
- TypeScript + Zod (validation)
- RBAC roles: super_admin, admin, manager, staff, viewer

## สิ่งที่ต้องสร้าง (ใน /root/repos/tham-oracle/agents/3/output/)

### 1. Supabase Middleware (`middleware.ts`)
```typescript
// ทุก request ผ่าน middleware
// - refresh session cookie
// - redirect unauthenticated users → /login
// - redirect authenticated → /erp/dashboard (ถ้าอยู่ที่ / หรือ /login)
// ใช้ createMiddlewareClient from @supabase/ssr
```

### 2. Auth API Routes
- `app/api/auth/callback/route.ts` — Supabase OAuth callback handler
- `app/api/auth/logout/route.ts` — Sign out + clear cookies

### 3. User API Routes
- `GET app/api/users/me/route.ts` — คืน current user + role + org
- `PUT app/api/users/me/route.ts` — Update profile (name, avatar)
- `GET app/api/users/route.ts` — List users in org (admin ขึ้นไปเท่านั้น)

### 4. RBAC Helper (`lib/rbac.ts`)
```typescript
// ฟังก์ชัน:
// - getUserRole(supabase): Promise<Role>
// - requireRole(supabase, minRole): throws if not authorized
// - hasPermission(role, action): boolean
// Role hierarchy: super_admin > admin > manager > staff > viewer
```

### 5. Supabase Server Client (`lib/supabase/server.ts`)
```typescript
// createServerClient — สำหรับ Server Components
// createAdminClient — service_role สำหรับ admin ops
// ใช้ cookies() from next/headers
```

## Output Format
```
output/
  middleware.ts
  lib/
    rbac.ts
    supabase/
      server.ts
      client.ts    (browser client)
  src/app/api/
    auth/callback/route.ts
    auth/logout/route.ts
    users/me/route.ts
    users/route.ts
```

## เมื่อทำเสร็จ
```bash
git add output/
git commit -m "feat(backend): middleware, auth routes, RBAC helper, Supabase clients"
```
