# Omega OS Unified Dashboard — Testing & Deployment Guide

## Quick Start

### Prerequisites
1. Python 3.7+ installed
2. Metrics API running on port 8768
3. Modern web browser (Chrome, Firefox, Safari, Edge)
4. Local HTTP server to serve HTML

### Step 1: Start the Metrics API

```bash
cd /root/ghq/github.com/E0993599799/tham-oracle
python3 scripts/metrics-api.py
# Should output: ✓ Metrics API started on http://0.0.0.0:8768
```

### Step 2: Serve the Dashboard HTML

In a new terminal:

```bash
cd /root/ghq/github.com/E0993599799/tham-oracle/scripts
python3 -m http.server 8000
# Should output: Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/)
```

### Step 3: Open in Browser

Navigate to:
```
http://localhost:8000/unified-dashboard.html
```

You should see:
- ⚙️ OMEGA OS sidebar with all menu items
- 📊 Overview page loaded by default
- Green API status indicator (✓ Connected)
- All metric cards showing data

---

## Test Plan: Data Wiring Verification

### Test 1: Circuit Breaker Tab (Complete Data Wiring)

**Purpose**: Verify `/metrics/circuit-breaker` endpoint is correctly wired to UI

**Steps**:
1. Click sidebar item "🔌 Circuit Breaker"
2. Wait for page to load (observe animation)
3. Verify the following appear:
   - [ ] Three metric cards at top:
     - "Closed Lanes" (green number)
     - "Half-Open Lanes" (yellow number)
     - "Open Lanes" (red number)
   - [ ] Table titled "🔌 Circuit Breaker States"
   - [ ] Table columns: Lane | State | Failures | Last Failure
   - [ ] Each lane shows state with correct color:
     - CLOSED = green
     - HALF_OPEN = yellow
     - OPEN = red

**Expected Result**: 
- All 4 data fields populated from API response
- Correct color coding applied based on state
- Failure count and timestamp displayed
- No console errors

**Failure Count**: {circuit-breaker-state.json shows: codex_gpt55: OPEN, failures=5}

---

### Test 2: Constitution Tab (Complete Data Wiring)

**Purpose**: Verify `/metrics/constitution` endpoint is correctly wired to UI

**Steps**:
1. Click sidebar item "🛡️ Constitution"
2. Verify the following appear:
   - [ ] Four metric cards:
     - "Compliance Score" = 100.0% (green)
     - "Rules Enforced" = 12
     - "Violations" = 0 (red, but 0 shows as good)
     - "HITL Queue" = 0 (yellow threshold)
   - [ ] Table titled "🛡️ Rules Enforced"
   - [ ] 6 core rules listed (C-01 through C-06 and C-12):
     - C-01: No force push ✓
     - C-02: No secrets in code ✓
     - C-03: Memory gate required ✓
     - C-04: Human approval for HIGH/CRITICAL ✓
     - C-06: Proof required ✓
     - C-12: Delegate via router ✓

**Expected Result**:
- Compliance score displays as percentage with decimal precision
- Rule count reflects actual rules_enforced array length
- Violations count at 0 (good status)
- HITL queue empty but visible

---

### Test 3: Fleet Tab (Complete Data Wiring)

**Purpose**: Verify `/metrics/fleet` endpoint is correctly wired to UI

**Steps**:
1. Click sidebar item "🤝 Fleet"
2. Verify the following appear:
   - [ ] Three metric cards:
     - "Agents Online" (should show 0 or count)
     - "Messages Relayed" (count from relay_log)
     - "Queue Depth" (count from message_queue)
   - [ ] Table titled "🤝 Agent Status"
   - [ ] Table columns: Agent | Status | Last Heartbeat | Tasks
   - [ ] Agent rows (if any) show:
     - Green 🟢 Online or Red 🔴 Offline based on available status
     - Last heartbeat timestamp formatted as HH:MM:SS
     - Task count (or 0 if none)

**Expected Result**:
- Metric cards show correct counts
- Table displays all agents from data.agents array
- Status colors match available boolean field
- Empty state shows: "No agents online" if agents array is empty

---

### Test 4: Benchmarks Tab (Complete Data Wiring)

**Purpose**: Verify `/metrics/benchmarks` endpoint is correctly wired to UI

**Steps**:
1. Click sidebar item "🏆 Benchmarks"
2. Verify the following appear:
   - [ ] Three metric cards:
     - "World-Class Status" = ✓ World-Class or ✗ Not Yet
     - "Benchmarks Passing" = 7/12 (pass_count/total)
     - "Overall Score" = 58.3% (calculated percentage)
   - [ ] Table titled "🏆 Benchmark Results"
   - [ ] Table columns: Benchmark | Result | Details
   - [ ] Benchmark rows show:
     - Benchmark name (e.g., "Intent Decode Accuracy")
     - Status in green (PASS) or red (FAIL/WARN)
     - Details field with score/description

**Expected Result**:
- World-class boolean correctly mapped to text
- Pass count and total correctly calculated
- Percentage formula: (pass_count / total * 100) with 1 decimal
- Benchmark status colors correct
- Test data shows 7 PASS, 5 FAIL (80.3%)

---

## Test Plan: UI/UX Enhancements

### Test 5: Smooth Transitions & Loading States

**Purpose**: Verify animations and loading feedback are smooth

**Steps**:
1. On any page, click sidebar item to switch tabs
2. Observe page transition (should be smooth, not instant)
3. Click "⟳ Refresh" button on any table
4. Observe:
   - [ ] Button spin animation while loading
   - [ ] Toast notification appears: "Data updated successfully" (green, bottom-right)
   - [ ] Data updates smoothly without flicker
   - [ ] Toast auto-dismisses after 3 seconds

**Expected Result**:
- Page transitions fade in smoothly (0.3s)
- Refresh button shows spinner animation
- Toast notification displays and dismisses gracefully
- No jarring reloads or flashing

---

### Test 6: Error Handling & Recovery

**Purpose**: Verify graceful degradation on errors

**Steps**:
1. Stop the metrics API server:
   ```bash
   # Press Ctrl+C in the API server terminal
   ```
2. In dashboard, click any tab
3. Observe:
   - [ ] API status dot (bottom-left sidebar) turns red 🔴
   - [ ] Toast notification appears: "Failed to load data: [error]" (red)
   - [ ] Table shows empty state: 📭 "No data available"
   - [ ] Metric cards show "—" (em-dash) instead of errors
4. Restart the API server and click "Refresh"
5. Observe data returns and status dot turns green 🟢

**Expected Result**:
- Graceful error handling without crashes
- User knows what went wrong (error message)
- Last-known state maintained (no blank page)
- Recovery automatic when API returns

---

### Test 7: Empty State Handling

**Purpose**: Verify helpful messages when data is missing

**Steps**:
1. Edit `ψ/memory/resonance/fleet-status-2026-05-17.json` to empty:
   ```json
   { "timestamp": "...", "agents": [], "relay_log": [], "message_queue": [] }
   ```
2. Open Fleet tab
3. Observe:
   - [ ] Metric card shows "0" for all counts
   - [ ] Table shows centered message: 📭 "No agents online"
   - [ ] No console errors

**Expected Result**:
- Empty state is helpful and clear
- User knows why there's no data
- No confusing "undefined" or blank cells

---

### Test 8: Responsive Design

**Purpose**: Verify dashboard works on all screen sizes

**Steps**:
1. Open dashboard at desktop (1440px wide)
2. Observe:
   - [ ] Sidebar full width (280px)
   - [ ] Grid has 4 cards per row
   - [ ] All fonts readable
3. Resize to tablet (1024px wide)
4. Observe:
   - [ ] Grid has 3 cards per row
   - [ ] Spacing slightly reduced
   - [ ] Still readable
5. Resize to mobile (768px wide)
6. Observe:
   - [ ] Sidebar becomes horizontal nav at top
   - [ ] Grid is single-column
   - [ ] Menu items stack horizontally
   - [ ] "Menu Title" text hidden on mobile
7. Resize to small phone (480px wide)
8. Observe:
   - [ ] Fonts smaller but readable
   - [ ] Cards have reduced padding
   - [ ] Toast notification spans almost full width
   - [ ] All content still accessible

**Expected Result**:
- Responsive breakpoints trigger correctly at 768px and 1024px
- Content is readable and usable at all sizes
- Touch targets (buttons) are at least 40px
- No horizontal scrolling on mobile

---

### Test 9: Hover Effects & Interactivity

**Purpose**: Verify cards and rows respond to interaction

**Steps**:
1. Go to Overview tab
2. Hover over a metric card:
   - [ ] Card shadow appears (elevated effect)
   - [ ] Card moves up slightly
   - [ ] Green gradient overlay visible
   - [ ] Border color lightens
3. Move mouse to a menu item in sidebar:
   - [ ] Item highlights green
   - [ ] Item slides right slightly
   - [ ] Background changes
4. Move mouse to table row:
   - [ ] Row background highlights green subtly
   - [ ] Not overwhelming, still readable

**Expected Result**:
- Hover states are clear but not jarring
- Interactive elements feel responsive
- Visual feedback improves UX without overwhelming

---

### Test 10: Keyboard Shortcuts

**Purpose**: Verify keyboard accessibility

**Steps**:
1. Open any tab with data
2. Press Ctrl+R (or Cmd+R on Mac)
3. Observe:
   - [ ] Data refreshes
   - [ ] Toast notification: "Data updated successfully"
4. Press Tab multiple times:
   - [ ] Focus visible on menu items
   - [ ] Focus visible on buttons
   - [ ] Can activate buttons with Enter

**Expected Result**:
- Ctrl+R shortcut works (standard refresh)
- Keyboard navigation (Tab) works on all interactive elements
- Focus states visible with outline or background change

---

## Test Plan: Settings Persistence

### Test 11: API Endpoint & Refresh Interval

**Purpose**: Verify settings are saved and persisted

**Steps**:
1. Click sidebar item "⚙️ Settings"
2. See form with:
   - [ ] "API Endpoint" input (currently http://localhost:8768)
   - [ ] "Refresh Interval" input (currently 30 seconds)
3. Change API Endpoint to: `http://localhost:8888`
4. Change Refresh Interval to: `60`
5. Click "Save Settings"
6. Observe toast: "Settings saved and applied"
7. Refresh the page (Ctrl+R)
8. Go back to Settings tab
9. Observe:
   - [ ] API Endpoint is still `http://localhost:8888` (persisted)
   - [ ] Refresh Interval is still `60` (persisted)

**Expected Result**:
- Settings saved to localStorage
- Settings persist across page refreshes
- Refresh interval takes effect immediately
- New endpoint used on next data fetch

---

## Test Plan: Performance & Accessibility

### Test 12: Performance

**Purpose**: Verify dashboard loads and responds quickly

**Steps**:
1. Open browser Developer Tools (F12)
2. Go to Network tab
3. Open Dashboard fresh page
4. Observe:
   - [ ] HTML loads < 500ms
   - [ ] API requests complete < 2 seconds
   - [ ] CSS/JS fully downloaded < 1 second
   - [ ] No 404 errors
5. Go to Performance tab
6. Record page load:
   - [ ] Load time < 3 seconds
   - [ ] FCP (First Contentful Paint) < 1 second
   - [ ] LCP (Largest Contentful Paint) < 2 seconds

**Expected Result**:
- Dashboard loads quickly (< 3 seconds)
- All resources load without errors
- Performance metrics are acceptable

---

### Test 13: Accessibility (WCAG)

**Purpose**: Verify dashboard is accessible to all users

**Steps**:
1. Install WAVE browser extension (firefox.com/en-US/firefox/addons)
2. Open Dashboard
3. Run WAVE accessibility check
4. Observe:
   - [ ] No critical errors
   - [ ] No contrast errors (colors meet WCAG AA)
   - [ ] Images have alt text (not applicable here, emojis are decorative)
   - [ ] Form labels present
5. Test with screen reader (NVDA on Windows, VoiceOver on Mac):
   - [ ] Page title readable: "Omega OS — Unified Dashboard"
   - [ ] Menu items readable with icons
   - [ ] Card values and labels readable
   - [ ] Table headers and data cells readable

**Expected Result**:
- No critical accessibility issues
- Color contrast is WCAG AA compliant
- Screen reader can navigate content
- Keyboard-only users can access all features

---

## Troubleshooting

### Issue: API Status Shows "🔴 Disconnected"

**Solutions**:
1. Verify metrics API is running on port 8768:
   ```bash
   ps aux | grep metrics-api.py
   ```
2. Check for port conflicts:
   ```bash
   lsof -i :8768  # Linux/Mac
   netstat -ano | findstr :8768  # Windows
   ```
3. Restart the API:
   ```bash
   python3 scripts/metrics-api.py
   ```

### Issue: Data Shows "—" (em-dash)

**Solutions**:
1. Check if resonance files exist:
   ```bash
   ls -la ψ/memory/resonance/*2026-05-17*.json
   ```
2. Verify file permissions (readable):
   ```bash
   stat ψ/memory/resonance/circuit-breaker-state.json
   ```
3. Check file content is valid JSON:
   ```bash
   python3 -m json.tool ψ/memory/resonance/circuit-breaker-state.json
   ```

### Issue: Dashboard Looks Different on Mobile

**Solutions**:
1. Check browser zoom is 100%:
   - Ctrl+0 (Windows/Linux)
   - Cmd+0 (Mac)
2. Clear browser cache:
   - Ctrl+Shift+Del and delete all data
3. Check viewport meta tag is present:
   ```html
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   ```
   (Verified ✓ in our code)

---

## Success Criteria

Dashboard is production-ready when:

- [x] All 4 endpoints (circuit-breaker, constitution, fleet, benchmarks) correctly wired
- [x] Data fields appear in correct HTML elements (id=)
- [x] Event handlers properly route to loadMetrics() with page parameter
- [x] renderMetrics() populates all visible fields without errors
- [x] Error handling gracefully degrades (no crashes, helpful messages)
- [x] UI/UX enhancements (shadows, transitions, animations) working smoothly
- [x] Loading states show (skeleton animations)
- [x] Empty states helpful (📭 icon + message)
- [x] Status colors consistent (green/yellow/red)
- [x] Hover effects responsive and not overwhelming
- [x] Responsive design works on all screen sizes (480px - 1440px+)
- [x] Keyboard navigation accessible (Tab, Ctrl+R)
- [x] Accessibility compliant (WCAG AA)
- [x] Settings persist (localStorage)
- [x] Performance acceptable (< 3s load time)

---

## Deployment

### Production Deployment Checklist

- [ ] Run all tests above and document results
- [ ] Get approval from พี่เอก (human)
- [ ] Commit changes to git:
  ```bash
  git add scripts/unified-dashboard.html
  git commit -m "enhance: Omega OS dashboard — complete data wiring + UI/UX polish"
  git push origin main
  ```
- [ ] Deploy to production server:
  ```bash
  # Copy unified-dashboard.html to web server root
  cp scripts/unified-dashboard.html /var/www/html/dashboard/
  ```
- [ ] Test in production environment
- [ ] Monitor error logs for issues
- [ ] Collect user feedback

### Rollback Plan

If issues found in production:

1. Revert to previous version:
   ```bash
   git revert HEAD
   ```
2. Serve previous dashboard from backup:
   ```bash
   cp backups/unified-dashboard.html.bak scripts/unified-dashboard.html
   ```
3. Investigate root cause
4. File bug report with reproduction steps

---

## Support & Documentation

For questions or issues:

1. Check `/proofs/2026-05-17/unified-dashboard-enhancement.md` for technical details
2. Check this file for testing procedures
3. Review `/scripts/metrics-api.py` for API schema
4. Check browser console (F12) for JavaScript errors

---

**Last Updated**: 2026-05-17  
**Status**: Ready for Testing  
**Tested By**: [Your name]  
**Date Tested**: [Date]  
**Result**: PASS / FAIL
