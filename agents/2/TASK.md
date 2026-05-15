# Agent 2 Task — Frontend Layout (ERP Foundation)

## งานของคุณ
สร้าง Next.js 15 base layout, navigation, และ auth pages สำหรับ ERP system

## Tech Stack
- Next.js 15 App Router + TypeScript
- Tailwind CSS + shadcn/ui
- Supabase Auth (@supabase/ssr)
- Zustand (state management)

## สิ่งที่ต้องสร้าง (ใน /root/repos/tham-oracle/agents/2/output/src/)

### 1. Root Layout (`app/layout.tsx`)
- HTML shell + Tailwind
- Supabase session provider
- Toaster (shadcn/ui)

### 2. ERP Shell Layout (`app/(erp)/layout.tsx`)
- Sidebar navigation
- Top header (user avatar, org name, logout)
- Main content area
- Mobile responsive

### 3. Sidebar Component (`components/layout/Sidebar.tsx`)
- Nav links: Dashboard, Finance, HR, Inventory, Purchasing, Sales, Projects, Reports
- Active state highlight
- Collapsible on mobile
- Role-based visibility (hide links user doesn't have access to)

### 4. Auth Pages
- `app/(auth)/login/page.tsx` — Email/password login + Supabase signIn
- `app/(auth)/register/page.tsx` — Register + create org flow
- Redirect authenticated users to /erp/dashboard

### 5. Dashboard Page (`app/(erp)/dashboard/page.tsx`)
- Welcome card (org name, user name)
- Quick stats cards (placeholder KPIs)
- Recent activity feed (placeholder)

## Output Format
สร้างไฟล์ใน `output/src/`:
```
output/src/
  app/
    layout.tsx
    (auth)/login/page.tsx
    (auth)/register/page.tsx
    (erp)/layout.tsx
    (erp)/dashboard/page.tsx
  components/layout/
    Sidebar.tsx
    Header.tsx
```

## เมื่อทำเสร็จ
```bash
git add output/
git commit -m "feat(frontend): ERP base layout, sidebar, auth pages, dashboard"
```
