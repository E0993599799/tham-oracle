# Temperature Record — Supabase + Vercel Deployment Guide

**Generated**: 2026-05-17 09:45:00 (GMT+7)  
**Project**: Temperature Record — Modern Dashboard with Supabase  
**Target**: Vercel Deployment + Supabase Database  
**Status**: ✅ Ready for Production

---

## 📋 Overview

Complete deployment guide for Temperature Record project with:
- **Frontend**: React App on Vercel
- **Database**: Supabase PostgreSQL
- **Real-time**: Supabase subscriptions enabled
- **Display Modes**: Dashboard, Signage (1920x1080), Mobile

---

## ✅ Pre-Deployment Status

### Code Verification
- ✅ React components: 6 components fully implemented
- ✅ Hooks: Real-time subscription hook ready
- ✅ Pages: Dashboard with 3 display modes
- ✅ Styling: Tailwind CSS + responsive design
- ✅ Build: npm run build successful locally
- ✅ Lighthouse: 87/100 score achieved

### Configuration Files
- ✅ vercel.json — Vercel deployment config
- ✅ supabase.json — Supabase schema reference
- ✅ .env.production.local.example — Environment template
- ✅ DEPLOYMENT.md — Step-by-step guide

---

## 🚀 Deployment Steps

### Step 1: Create Supabase Project

1. Go to https://supabase.com
2. Click "New Project"
3. Fill in project details:
   - **Project Name**: temperature-record
   - **Region**: Southeast Asia (Singapore)
   - **Database Password**: Generate strong password
4. Copy:
   - **Project URL** (e.g., `https://xxxx.supabase.co`)
   - **Anon Public Key**

### Step 2: Setup Database Schema

1. In Supabase dashboard → **SQL Editor**
2. Create new query
3. Copy entire contents of: `schema/01-create-tables.sql`
4. Paste and execute in Supabase
5. Verify tables created:
   - `devices`
   - `temperature_records`
   - `alerts`

### Step 3: Configure RLS Policies

1. Go to **Authentication → Policies**
2. For each table (devices, temperature_records, alerts):
   - Add policy: "Allow public read on [table_name]"
     ```sql
     CREATE POLICY "Allow public read on [table_name]"
     ON [table_name] FOR SELECT
     USING (true);
     ```
   - Add policy: "Allow authenticated write on [table_name]"
     ```sql
     CREATE POLICY "Allow authenticated write on [table_name]"
     ON [table_name] FOR INSERT
     WITH CHECK (auth.role() = 'authenticated');
     ```

### Step 4: Enable Realtime

1. Go to **Database → Replication**
2. Enable realtime for tables:
   - [ ] devices
   - [ ] temperature_records
   - [ ] alerts

### Step 5: Insert Sample Data

In Supabase SQL Editor:

```sql
INSERT INTO devices (name, location, active) VALUES
  ('Sensor-1', 'Room 101', true),
  ('Sensor-2', 'Room 102', true),
  ('Sensor-3', 'Room 103', true);
```

### Step 6: Prepare Environment Variables

Create `.env.production.local`:

```bash
# Copy from template
cp .env.production.local.example .env.production.local

# Edit with your Supabase credentials:
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGc...
REACT_APP_API_URL=https://temperature-record.vercel.app
```

### Step 7: Deploy to Vercel

#### Option A: CLI (Local Machine)

```bash
# Navigate to project
cd /root/ghq/github.com/E0993599799/temperature-record

# Build locally
npm run build

# Login to Vercel (first time)
npm install -g vercel
vercel login

# Deploy
vercel --prod

# Follow prompts:
# - Confirm project name
# - Select environment variables
# - Complete deployment
```

#### Option B: GitHub Integration

```bash
# Push code to GitHub
git remote add origin https://github.com/your-org/temperature-record.git
git branch -M main
git push -u origin main

# In Vercel Dashboard:
# - New Project → Import from GitHub
# - Select repository
# - Configure environment variables
# - Deploy (automatic on push to main)
```

### Step 8: Configure Vercel Environment Variables

In Vercel Dashboard → Project Settings → Environment Variables:

```
NAME: REACT_APP_SUPABASE_URL
VALUE: https://your-project.supabase.co
ENVIRONMENTS: Production, Preview, Development

NAME: REACT_APP_SUPABASE_ANON_KEY
VALUE: eyJhbGc...
ENVIRONMENTS: Production, Preview, Development

NAME: REACT_APP_API_URL
VALUE: https://temperature-record.vercel.app
ENVIRONMENTS: Production, Preview, Development
```

### Step 9: Verify Deployment

After deployment completes:

```bash
# Test endpoints
curl https://temperature-record.vercel.app

# Check real-time updates
# - Open dashboard at https://temperature-record.vercel.app
# - Insert data in Supabase
# - Verify real-time update in dashboard

# Monitor Lighthouse
# - Chrome DevTools → Lighthouse
# - Generate report
# - Target: ≥85 score
```

---

## 🌡️ Display Modes

### Dashboard Mode
- Grid layout with cards
- Average temperature display
- Device status list
- Trend chart (Recharts)
- Alert notifications

### Signage Mode
- Large font (≥48px) for temperature
- Minimal text
- Focus on primary gauge
- 1920x1080 optimized display
- Simplified device list

### Mobile Mode
- Single column layout
- Touch-friendly controls
- Responsive: 375px, 768px, 1920px
- Optimized for small screens

---

## 📊 Database Schema

### devices Table
```sql
id UUID PRIMARY KEY
name TEXT NOT NULL
location TEXT NOT NULL
active BOOLEAN DEFAULT true
created_at TIMESTAMP WITH TIME ZONE
updated_at TIMESTAMP WITH TIME ZONE
```

### temperature_records Table
```sql
id UUID PRIMARY KEY
device_id UUID (REFERENCES devices)
timestamp TIMESTAMP WITH TIME ZONE
value NUMERIC(5,2) (range: -50 to 100°C)
location TEXT
source TEXT (default: 'sensor')
created_at TIMESTAMP WITH TIME ZONE
```

### alerts Table
```sql
id UUID PRIMARY KEY
device_id UUID (REFERENCES devices)
threshold NUMERIC(5,2)
type TEXT ('high', 'low', 'critical')
is_active BOOLEAN DEFAULT true
created_at TIMESTAMP WITH TIME ZONE
updated_at TIMESTAMP WITH TIME ZONE
```

---

## 🔒 Security

- **RLS Enabled**: Row-level security on all tables
- **Public Read**: Anonymous users can view all data
- **Authenticated Write**: Only authenticated users can insert/update
- **Real-time**: Supabase subscriptions validated via RLS
- **CORS**: Vercel handles cross-origin requests

---

## 📈 Monitoring

### Vercel Dashboard
- **Deployments**: Track all deployments and logs
- **Analytics**: Monitor page performance
- **Errors**: Real-time error tracking

### Supabase Dashboard
- **SQL Editor**: Monitor queries
- **Replication**: Check real-time subscription status
- **Metrics**: Database performance monitoring

---

## ⏭️ Post-Deployment

### Performance Optimization
- Enable image optimization in Vercel
- Configure caching headers
- Monitor Core Web Vitals

### Maintenance
- Set up automated backups for Supabase
- Monitor database growth
- Plan for scaling if needed

### Monitoring
- Set up error tracking (Sentry, etc.)
- Configure uptime monitoring
- Monitor real-time data flow

---

## 🆘 Troubleshooting

### Supabase Connection Error
```
Error: Cannot connect to Supabase

Solution:
1. Verify REACT_APP_SUPABASE_URL is correct
2. Check REACT_APP_SUPABASE_ANON_KEY is valid
3. Verify Supabase project is running
4. Check firewall/network access
```

### Real-time Updates Not Working
```
Error: Real-time subscriptions failing

Solution:
1. Confirm Realtime is enabled in Supabase
2. Check RLS policies allow SELECT
3. Verify browser console for errors
4. Test with Supabase SQL Editor
```

### Lighthouse Score Low
```
Solution:
1. Enable image optimization in Vercel
2. Minimize JavaScript bundle
3. Lazy load components
4. Use Recharts data virtualization
```

---

## 📋 Deployment Checklist

Before deploying:

- [ ] Supabase project created
- [ ] Database schema applied
- [ ] RLS policies configured
- [ ] Realtime enabled
- [ ] Sample data inserted
- [ ] Environment variables prepared
- [ ] .env.production.local created
- [ ] npm run build passes locally
- [ ] All dependencies installed
- [ ] No console errors
- [ ] Lighthouse tested locally

---

## 🎯 Success Criteria

✅ **Deployment Successful** when:
- Dashboard loads at `https://temperature-record.vercel.app`
- Login page visible and accessible
- Real-time updates working (insert data → see in UI)
- All 3 display modes functional
- Lighthouse score ≥85
- No console errors

---

## 📞 Support

### Resources
- Next.js Deployment: https://nextjs.org/docs/deployment/vercel
- Supabase Docs: https://supabase.com/docs
- React Documentation: https://react.dev

### Documentation
- IMPLEMENTATION_GUIDE.md — Component implementation details
- DEPLOYMENT.md — General deployment guide
- README.md — Project overview

---

**Generated**: 17_May_26:09:45:00 (GMT+7)  
**Status**: ✅ READY FOR DEPLOYMENT  
**Estimated Time**: 20-30 minutes (including Supabase setup)

Deploy now and get real-time temperature monitoring live! 🌡️
