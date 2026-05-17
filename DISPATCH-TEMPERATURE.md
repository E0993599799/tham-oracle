# DISPATCH: Temperature Record Project — Phase 1 + 2 + 3

**Status**: ACTIVE DISPATCH  
**Assigned**: CODEX-A (Phase 1), CLAUDE (Phase 2+3)  
**Deadline**: 4 hours from now (11:35 AM)  
**Critical**: Do not wait for blockers, execute immediately. THAM Monitor verifying continuously.

## PHASE 1: Database + Supabase Schema (CODEX-A Lane)
**ETA**: 1 hour  
**Deadline**: 08:35 AM

### Tasks
1. Create Supabase project (or use existing)
2. Design & create tables:
   - `temperature_records` (id, timestamp, value, location, source)
   - `devices` (id, name, location, active, created_at)
   - `alerts` (id, device_id, threshold, type, created_at)
3. Configure Row-Level Security (RLS) policies
4. Enable Realtime subscriptions on `temperature_records`
5. Setup authentication method (anon/service role)
6. Create migration scripts in `/schema/`
7. Output PROOF: schema-snapshot.json, rls-policies.md, migration-scripts.sql

### Project Location
```
/root/ghq/github.com/E0993599799/temperature-record/
├── schema/          # Database schema files
├── migrations/      # SQL migration scripts
├── docs/           # Documentation
└── src/            # Application code
```

### Evidence Required
- Supabase project ID + URL
- Schema diagram (JSON or markdown)
- RLS policies document
- Test queries proving tables exist and RLS works
- File: `reports/TASK-TEMPERATURE-PHASE1-proof.json`

---

## PHASE 2 + 3: Modern UI/UX + Real-time Dashboard (CLAUDE Lane)
**ETA**: 2 hours  
**Deadline**: 09:35 AM

### Requirements
**Design Style**: Modern, minimal, clean  
**Modes**:
- **Dashboard**: Desktop analytics + status (primary)
- **Signage**: Large display 1920x1080+ (room temp, alerts, big numbers)
- **Mobile**: Responsive, touch-friendly

### Components to Build
1. **Temperature Gauge** — Large, real-time display
2. **Historical Chart** — Trends over time (Recharts/Chart.js)
3. **Device Status Panel** — List of devices, online/offline status
4. **Alert Notifications** — Visual & sound alerts for threshold breach
5. **Settings Panel** — Admin controls (optional for MVP)

### Tech Stack
- React (functional components, hooks)
- Supabase client SDK (real-time subscriptions)
- TailwindCSS or styled-components (modern styling)
- Recharts or Chart.js (charts)
- Optional: Framer Motion (animations)

### Deliverables
1. **src/components/Dashboard.jsx** — Main layout
2. **src/components/TemperatureGauge.jsx** — Real-time gauge
3. **src/components/HistoricalChart.jsx** — Trend chart
4. **src/components/DeviceStatus.jsx** — Device list
5. **src/hooks/useTemperatureSubscription.js** — Supabase real-time hook
6. **src/App.jsx** — Wire everything together
7. **public/index.html** — Entry point with meta tags

### Acceptance Criteria
- [ ] Supabase subscription active (real-time updates)
- [ ] Dashboard renders without errors
- [ ] Signage mode: max font-size ≥48px for temps
- [ ] Mobile: responsive at 375px, 768px, 1920px
- [ ] Lighthouse score ≥85
- [ ] No console errors/warnings

### Evidence Required
- Screenshots: Desktop + Signage + Mobile modes
- Lighthouse report (≥85)
- Working demo (or deployed link)
- File: `reports/TASK-TEMPERATURE-PHASE2-proof.json`

---

## THAM Monitor Checklist (Active Verification)
- [ ] CODEX-A Phase 1 report received by 08:35 AM
- [ ] CLAUDE Phase 2+3 report received by 09:35 AM
- [ ] Both proofs validated (schema exists, UI renders)
- [ ] All evidence files in `/reports/`
- [ ] No blockers — escalate immediately if agent idle >5 min

**Wake Command** (if idle):
```bash
tmux send-keys -t "lanes:1" "echo '🔥 CODEX-A: START TEMPERATURE PHASE 1' && cd /root/ghq/github.com/E0993599799/temperature-record && ls -la" Enter
tmux send-keys -t "lanes:2" "echo '🔥 CLAUDE: START TEMPERATURE PHASE 2+3' && cd /root/ghq/github.com/E0993599799/temperature-record && npm install" Enter
```

---

## Fallback Activation
If THAM Monitor doesn't detect heartbeat every 30 seconds:
1. Scout-1 triggers fallback agent
2. Fallback inherits task queue + proof files
3. Fallback continues without interruption
4. Original agent re-syncs on recovery

**Status**: Fallback system ARMED and monitoring
