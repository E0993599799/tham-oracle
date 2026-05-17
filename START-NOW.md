# 🔥 START NOW — Immediate Work Instructions

**Time**: 17_MAY_26:08:00:00  
**Status**: Dispatch Active, Ready for Execution

---

## 🔷 CODEX-A — Phase 1 (Supabase Database)

### ทำตรงนี้เลย (Do this NOW)

1. **เปิด Supabase dashboard**
   - ไปที่ https://supabase.com
   - Sign in หรือ Create new project
   - Copy: Project URL และ Anon Public Key

2. **สร้าง Database Schema**
   - ไป SQL Editor ใน Supabase dashboard
   - Open file: `/root/ghq/github.com/E0993599799/temperature-record/schema/01-create-tables.sql`
   - Copy ทั้ง SQL
   - Paste เข้า Supabase SQL Editor
   - Run ✓

3. **สร้าง RLS Policies**
   - Reference: `/root/ghq/github.com/E0993599799/temperature-record/schema/rls-policies.md`
   - ใน Supabase: Authentication → Policies
   - สร้าง policy ตามที่เขียนในไฟล์

4. **Enable Realtime**
   - Database → Replication
   - Enable สำหรับ: `devices`, `temperature_records`, `alerts`

5. **Test Schema**
   ```sql
   SELECT * FROM devices;
   SELECT COUNT(*) FROM temperature_records;
   SELECT * FROM alerts;
   ```

6. **สร้าง Proof File**
   ```bash
   cat > /root/ghq/github.com/E0993599799/tham-oracle/reports/TASK-TEMPERATURE-PHASE1-proof.json << 'EOF'
   {
     "task_id": "TASK-TEMPERATURE-PHASE1",
     "status": "COMPLETED",
     "timestamp": "$(date -Iseconds)",
     "supabase_url": "YOUR-URL-HERE",
     "supabase_key": "YOUR-ANON-KEY-HERE",
     "deliverables": {
       "tables_created": ["devices", "temperature_records", "alerts"],
       "rls_enabled": true,
       "realtime_enabled": true
     }
   }
   EOF
   ```

### ⏰ Deadline: 08:35 AM (55 minutes from now)

---

## 🔶 CLAUDE — Phase 2+3 (React UI/UX)

### ทำตรงนี้เลย (Do this NOW)

1. **Wait for CODEX-A Supabase credentials**
   - ต้องรับ Supabase URL + Anon Key จาก CODEX-A
   - Proof file: `TASK-TEMPERATURE-PHASE1-proof.json`

2. **Setup Environment**
   ```bash
   cd /root/ghq/github.com/E0993599799/temperature-record
   cp .env.example .env.local
   # Edit .env.local:
   # REACT_APP_SUPABASE_URL=<from-CODEX-A>
   # REACT_APP_SUPABASE_ANON_KEY=<from-CODEX-A>
   ```

3. **Install Dependencies**
   ```bash
   npm install
   npm start
   ```

4. **Implement Components** (ตามลำดับ)
   - [ ] Dashboard.jsx — Wire all sub-components
   - [ ] TemperatureGauge.jsx — Add CSS styling
   - [ ] HistoricalChart.jsx — Complete Recharts integration
   - [ ] DeviceStatus.jsx — Style device cards
   - [ ] AlertNotifications.jsx — Wire Supabase subscription
   - [ ] useTemperatureSubscription.js — Test real-time updates

5. **Test Display Modes**
   - [ ] Dashboard mode (default) — Check grid layout
   - [ ] Signage mode (large) — Font size ≥48px
   - [ ] Mobile mode (responsive) — Test at 375px, 768px, 1920px

6. **Quality Checks**
   - [ ] No console errors
   - [ ] Real-time updates working
   - [ ] Lighthouse score ≥85
   - Screenshots: desktop, signage, mobile

7. **สร้าง Proof File**
   ```bash
   cat > /root/ghq/github.com/E0993599799/tham-oracle/reports/TASK-TEMPERATURE-PHASE2-proof.json << 'EOF'
   {
     "task_id": "TASK-TEMPERATURE-PHASE2",
     "status": "COMPLETED",
     "timestamp": "$(date -Iseconds)",
     "deliverables": {
       "components": ["Dashboard.jsx", "TemperatureGauge.jsx", "HistoricalChart.jsx", "DeviceStatus.jsx", "AlertNotifications.jsx"],
       "display_modes": ["dashboard", "signage", "mobile"],
       "features": ["real-time", "responsive", "accessible"]
     },
     "quality": {
       "lighthouse_score": 85,
       "console_errors": 0,
       "responsive_breakpoints": ["375px", "768px", "1920px"]
     }
   }
   EOF
   ```

### ⏰ Deadline: 09:35 AM (95 minutes from now)

### ⚠️ Important
- **Dependency**: Requires Phase 1 to complete first
- **Env vars**: Need Supabase URL + Key from CODEX-A
- **Can't proceed until**: Phase 1 proof file exists

---

## 🛡️ SCOUT-1 — Heartbeat Watchdog

Running continuously. Your job:
- Monitor THAM Monitor heartbeat every 30 seconds
- If no heartbeat for >90 seconds, activate fallback
- Log all status to `reports/scout-heartbeat-*.log`

✅ **Status**: Running

---

## 👁️ THAM MONITOR — Verification Loop

Running continuously. Your job:
- Check agent status every 30 seconds
- Verify proof files when they arrive
- Escalate if agents are idle or blocking
- Log decisions to `reports/escalation-*.log`

✅ **Status**: Running

---

## 📋 Summary

**Immediate Actions**:
1. CODEX-A: Supabase setup (1 hour)
2. CLAUDE: npm install (starts when CODEX-A done)
3. CLAUDE: React components (while CODEX-A works, can prep)
4. Both: Create proof files immediately when done

**Critical Path**: CODEX-A Phase 1 → CLAUDE Phase 2+3

**Monitoring**: THAM + Scout running continuously

**No Waiting**: Execute now, escalate immediately if blocked

---

## 🎯 Success Criteria

✅ **PHASE 1 Complete** when:
- Supabase project has 3 tables (devices, temperature_records, alerts)
- RLS policies enabled
- Realtime subscriptions active
- Proof file exists with URL + key

✅ **PHASE 2+3 Complete** when:
- 5 React components implemented
- All 3 display modes working
- Lighthouse score ≥85
- Screenshots captured
- Proof file exists

✅ **Overall Success** when:
- Both proof files in `/reports/` directory
- THAM Monitor validates both proofs
- No escalations logged
- All work committed to git

---

**Time Now**: 17_MAY_26:08:00:00  
**Start**: ตรงนี้เลย  
**Go**: ไปเลย
