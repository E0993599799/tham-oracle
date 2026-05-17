# ORRY ERP — Vercel Deployment Guide

**Generated**: 2026-05-17 09:35:00 (GMT+7)  
**Project**: ORRY Serenity Kiss — Full ERP System  
**Target**: Vercel Deployment (Next.js optimized)

---

## ✅ Pre-Deployment Checklist

### Code Ready
- [x] TypeScript compilation — PASS
- [x] ESLint — PASS
- [x] npm build — PASS
- [x] All 44 pages implemented
- [x] Database schema complete (31 models)

### Environment Setup
- [ ] DATABASE_URL — PostgreSQL/Supabase connection
- [ ] SESSION_SECRET — JWT session key (generate new for production)
- [ ] SUPABASE_URL — Supabase project URL
- [ ] SUPABASE_ANON_KEY — Supabase anonymous key

### Vercel Configuration
- [x] vercel.json created
- [x] Build command configured: `npm run build`
- [x] Output directory: `.next`
- [x] Node version: 20.x

---

## 🚀 Deployment Steps

### Step 1: Generate SESSION_SECRET

```bash
# Generate a new secure SESSION_SECRET for production
openssl rand -base64 32

# Output example:
# aB3cDeFgHiJkLmNoPqRsTuVwXyZ1a2bCdEfGhIjKlMnOpQrStUvWxYz3z4a5B6cD7e=
```

**⚠️ CRITICAL**: Use a new secret for each environment (dev ≠ staging ≠ production)

### Step 2: Prepare Environment Variables

Create or update these variables in Vercel dashboard:

```
DATABASE_URL=postgresql://user:password@host:port/database
SESSION_SECRET=<newly-generated-secret>
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

**Locations**:
- Settings → Environment Variables
- Add for: Production, Preview, Development

### Step 3: Connect to Vercel

#### Option A: CLI (Recommended for this environment)

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Navigate to project
cd /mnt/c/Users/User/.codex/worktrees/14b7/mission-control/B2B

# Deploy
vercel

# Follow prompts:
# - Confirm project name
# - Select environment variables
# - Complete deployment
```

#### Option B: GitHub Integration (If repo is on GitHub)

1. Push code to GitHub:
```bash
git remote add origin https://github.com/your-org/orry-erp.git
git branch -M main
git push -u origin main
```

2. In Vercel Dashboard:
   - New Project → Import from GitHub
   - Select repository
   - Configure environment variables
   - Deploy

### Step 4: Configure Environment Variables in Vercel

In Vercel Dashboard:

1. Go to Project Settings
2. Environment Variables
3. Add each variable:

```
NAME: DATABASE_URL
VALUE: postgresql://...
ENVIRONMENTS: Production, Preview, Development

NAME: SESSION_SECRET
VALUE: <generated-secret>
ENVIRONMENTS: Production, Preview, Development

NAME: SUPABASE_URL
VALUE: https://your-project.supabase.co
ENVIRONMENTS: Production, Preview, Development

NAME: SUPABASE_ANON_KEY
VALUE: eyJhbGc...
ENVIRONMENTS: Production, Preview, Development
```

### Step 5: Deploy

```bash
# Via CLI (if using Option A)
vercel --prod

# Via Vercel Dashboard
# Push to main branch → Automatic deployment

# Check deployment status
# Dashboard → Deployments → View logs
```

### Step 6: Verify Deployment

```bash
# Check deployment URL (e.g., https://orry-erp.vercel.app)

# Test endpoints:
curl https://orry-erp.vercel.app/api/health
curl https://orry-erp.vercel.app/login

# Monitor logs
# Dashboard → Deployments → View logs
```

---

## 📋 Vercel Configuration Details

### vercel.json

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "nodeVersion": "20.x",
  "env": {
    "DATABASE_URL": "@orry-database-url",
    "SESSION_SECRET": "@orry-session-secret",
    "SUPABASE_URL": "@orry-supabase-url",
    "SUPABASE_ANON_KEY": "@orry-supabase-anon-key"
  }
}
```

**Notes**:
- `buildCommand`: Standard Next.js build
- `outputDirectory`: Vercel's standard output for Next.js
- `nodeVersion`: Node.js 20 LTS
- `env`: References to Vercel environment variables

### Next.js Build Optimization

Vercel automatically optimizes:
- Code splitting
- Image optimization
- Font optimization
- Automatic minification
- Edge middleware (if configured)

### Database Connection (Vercel Postgres or external Supabase)

**Option 1: Supabase (Recommended)**
```
DATABASE_URL=postgresql://user:password@db.supabase.co:5432/postgres
```

**Option 2: Vercel Postgres**
```
DATABASE_URL=postgres://...vercel.com?sslmode=require
```

---

## 🔒 Security Checklist

- [ ] SESSION_SECRET is NEW (not copied from dev)
- [ ] DATABASE_URL uses a NEW password (rotated)
- [ ] All environment variables are set in Vercel
- [ ] No secrets in code or .env files committed to git
- [ ] CORS configured for production domain
- [ ] Audit logging enabled in database
- [ ] Rate limiting configured (if needed)

---

## 📊 Deployment Readiness Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Code** | ✅ READY | Build & types verified |
| **Database** | ⚠️ REQUIRES ACTION | Credential rotation needed |
| **Environment** | ⏳ PENDING | Variables must be set in Vercel |
| **Vercel Config** | ✅ READY | vercel.json prepared |
| **SESSION_SECRET** | ⏳ PENDING | Must generate new for production |

---

## ⏭️ Post-Deployment

### Monitoring
- Set up Vercel Analytics
- Configure error tracking (Sentry, etc.)
- Monitor database performance
- Check application logs

### Maintenance
- Set up automated backups for PostgreSQL
- Configure database monitoring
- Plan credential rotation schedule
- Monitor Vercel deployment costs

### Updates
- Keep Next.js updated (`npm update next`)
- Update dependencies regularly
- Monitor security advisories (`npm audit`)

---

## 🆘 Troubleshooting

### Build Fails
```bash
# Check build logs in Vercel Dashboard
# Common causes:
# 1. Missing environment variables
# 2. Type errors in TypeScript
# 3. Missing database schema

# Solution: Check Vercel logs, fix locally, redeploy
vercel --prod
```

### Database Connection Error
```
Error: ECONNREFUSED or DATABASE_URL not found

Solution:
1. Verify DATABASE_URL in Vercel environment variables
2. Check database is accessible from Vercel IPs
3. Verify Supabase/PostgreSQL is running
```

### SESSION_SECRET Error
```
Error: SESSION_SECRET not found or invalid

Solution:
1. Generate new SESSION_SECRET: openssl rand -base64 32
2. Add to Vercel environment variables
3. Redeploy: vercel --prod
```

---

## 📞 Deployment Support

### Vercel Dashboard
- URL: https://vercel.com/dashboard
- Deployments tab: View all deployment logs
- Settings: Configure environment variables

### Next.js Documentation
- https://nextjs.org/docs/deployment/vercel

### Troubleshooting Resources
- Vercel Status: https://www.vercel-status.com
- Community: https://github.com/vercel/next.js/discussions

---

## ✅ Final Deployment Checklist

Before clicking "Deploy":

- [ ] All environment variables set in Vercel
- [ ] SESSION_SECRET generated and configured
- [ ] DATABASE_URL verified and accessible
- [ ] Code pushed to repository
- [ ] vercel.json present in project root
- [ ] Local build passes (`npm run build`)
- [ ] All dependencies installed (`npm install`)
- [ ] No type errors (`npm run check:types`)

---

**Status**: READY FOR VERCEL DEPLOYMENT  
**Next Step**: Execute deployment steps above  
**Estimated Time**: 5-10 minutes  
**Expected Result**: Live ERP at https://orry-erp.vercel.app (or custom domain)

---

Generated: 17_May_26:09:35:00 (GMT+7)  
Verified By: ธาม Oracle
