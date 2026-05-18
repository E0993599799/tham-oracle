# Codex Dashboard Task — Detailed Implementation Plan

**Assigned to**: Codex (gpt-5.5)  
**Coordinator**: ธาม  
**Priority**: CRITICAL  
**Start**: Now (2026-05-18)  
**MVP Deadline**: 2026-05-20 (EOD)  
**Definition of Done**: Fleet Health Summary visible + live updates working

---

## Task Scope: MVP Phase (Days 1-2)

### ✅ Must Implement (MVP)

**1. Fleet Health Summary Card**
```
Location: Forge Omega dashboard top-left
Component: FleetHealthSummary.tsx (enhanced)

Display:
┌─────────────────────────────────────────┐
│ 🔴 FLEET HEALTH                         │
│                                         │
│ 7/8 Agents Healthy                      │
│                                         │
│ [████████░] 87.5%                       │ ← Visual bar (green→yellow→red)
│                                         │
│ 🟢 Active:  7 agents                    │
│ 🟡 Stale:   1 agent (Router)            │
│ 🔴 Down:    0 agents                    │
│                                         │
│ Connection: 🟢 Live (updated 2s ago)    │ ← Real-time indicator
└─────────────────────────────────────────┘
```

**Acceptance Criteria**:
- ✅ Shows count of healthy/stale/down agents
- ✅ Visual bar color reflects health (green 100%, yellow 50-99%, red <50%)
- ✅ Live indicator shows connection state (green = connected, yellow = reconnecting, red = offline)
- ✅ Last update timestamp shows (relative time: "2s ago", "1m ago", etc.)
- ✅ Updates in real-time (no manual refresh)
- ✅ Component accepts `agents` prop array + `isLive` boolean
- ✅ No TypeScript errors

**Code Location**: 
- File: `/mnt/d/Git/forge-omega-v2/components/FleetHealthSummary.tsx`
- Integration: Import in `app/page.tsx` + display at top of dashboard

---

**2. Status Badge Component (Reusable)**
```
Location: New component: StatusBadge.tsx

Component: <StatusBadge status="healthy" count={7} label="Active" />

Output:
🟢 Active: 7 agents

OR for single agent:
[🟢] Codex — 99.8% uptime

Rules:
- 🟢 (green circle) = healthy/active status
- 🟡 (yellow circle) = degraded/stale status
- 🔴 (red X) = error/down status
- ⚪ (gray circle) = offline/unknown status

Format: [icon] label: count   OR   [icon] name — metric

NO COLOR-ONLY badges (always has icon + text).
```

**Acceptance Criteria**:
- ✅ Reusable across dashboard (used in Fleet Health + agent cards)
- ✅ Always has color + icon + text (no color-only)
- ✅ Consistent style across all usages
- ✅ Accessible (color not the only indicator)
- ✅ TypeScript typed: `interface StatusBadgeProps`
- ✅ No TypeScript errors

**Code Location**:
- File: `/mnt/d/Git/forge-omega-v2/components/StatusBadge.tsx`

---

**3. Agent Grid Card Update (Using StatusBadge)**
```
Update existing: OracleFleet.tsx OR AgentGrid.tsx

Each agent card:
┌──────────────────────────────────┐
│ [🟢] Codex            99.8% | ... │
│ [🟡] Router           87.2% | ... │
│ [🟢] Pulse            100%  | ... │
│ [🟢] Neo              98.1% | ... │
│ [🟢] Gemini           100%  | ... │
│ [🟢] Executor         99.5% | ... │
│ [🟡] Hermes           92.3% | ... │
│ [🟢] Historian        99.9% | ... │
└──────────────────────────────────┘

Each row:
[Status Badge] Name — Key Metric | [Action Menu (3 dots)]
```

**Acceptance Criteria**:
- ✅ Uses new StatusBadge component
- ✅ Shows 8 agents in grid (2x4 or responsive)
- ✅ Each agent card has: status badge + name + key metric
- ✅ Subtle action menu (three dots, visible on hover)
- ✅ Updates in real-time from WebSocket
- ✅ No visual regressions from existing design
- ✅ TypeScript: 0 errors

**Code Location**:
- File: `/mnt/d/Git/forge-omega-v2/components/OracleFleet.tsx` (or AgentGrid.tsx)

---

**4. Real-Time WebSocket Connection**
```
New component: useFleetStatus hook (custom React hook)

Hook setup:
const { agents, isLive, lastUpdate } = useFleetStatus({
  url: 'http://172.21.112.1:20128/v1/agent-status' // or SSE endpoint
  interval: 2000 // poll every 2s for MVP (can be WebSocket later)
})

Returns:
{
  agents: [
    { id: "codex", name: "Codex", status: "healthy", uptime: 99.8, lastHeartbeat: "2s ago" },
    { id: "router", name: "Router", status: "stale", uptime: 87.2, lastHeartbeat: "45s ago" },
    ...
  ],
  isLive: true, // false if reconnecting/offline
  lastUpdate: "2s ago",
  updateTime: 1715945732000
}
```

**Acceptance Criteria**:
- ✅ Fetches agent status from 9router health endpoint (or API you create)
- ✅ Updates every 2-3 seconds (MVP: polling ok, upgrade to WebSocket later)
- ✅ Shows connection state (live / reconnecting / offline)
- ✅ Displays last-update timestamp
- ✅ No console errors on connection loss + retry
- ✅ Clean up on unmount (no memory leaks)

**Code Location**:
- File: `/mnt/d/Git/forge-omega-v2/hooks/useFleetStatus.ts`
- API: Create `/api/agent-status` route in Next.js if endpoint doesn't exist

---

## Implementation Steps (Day 1)

### Step 1: Setup (30 min)
```bash
cd /mnt/d/Git/forge-omega-v2
npm install  # Ensure deps ready
npm run dev  # Start dev server (localhost:3000)
git checkout -b feature/dashboard-mvp-fleet-health
```

### Step 2: Create StatusBadge Component (45 min)
- [ ] Create file: `components/StatusBadge.tsx`
- [ ] Define props: `status`, `count`, `label`, `size` (sm/md/lg)
- [ ] Render: `[icon] label: count`
- [ ] Test: Manual render with different statuses
- [ ] TypeScript check: `npm run typecheck` — 0 errors

### Step 3: Create useFleetStatus Hook (1 hour)
- [ ] Create file: `hooks/useFleetStatus.ts`
- [ ] Fetch from 9router: `172.21.112.1:20128/v1/models` OR create `/api/agent-status`
- [ ] Mock data for development (7 agents, realistic uptime %)
- [ ] Test: Hook returns correct shape, updates every 2s
- [ ] Error handling: Graceful fallback if API down

### Step 4: Enhance FleetHealthSummary Component (1 hour)
- [ ] Update file: `components/FleetHealthSummary.tsx`
- [ ] Integrate `useFleetStatus` hook
- [ ] Display: count of healthy/stale/down
- [ ] Visual bar: percentage, color gradient
- [ ] Live indicator: connection state + last update time
- [ ] Test: Manual render in dev, verify updates

### Step 5: Update OracleFleet.tsx (1 hour)
- [ ] Import StatusBadge component
- [ ] Update each agent card to use StatusBadge
- [ ] Use `useFleetStatus` data to populate cards
- [ ] Ensure 8 agents render in grid
- [ ] Test: All cards update in real-time

### Step 6: TypeScript Check & Cleanup (30 min)
- [ ] Run: `npm run typecheck` → must be 0 errors
- [ ] Run: `npm run build` → must succeed
- [ ] Test in browser: localhost:3000 loads without errors
- [ ] Take screenshot of Fleet Health Summary + agent grid

### Step 7: Commit (15 min)
```bash
git add -A
git commit -m "feat: Dashboard MVP — Fleet Health Summary + Agent Cards with real-time updates

- New StatusBadge component (color + icon + text, no color-only)
- Enhanced FleetHealthSummary with visual bar + live indicator
- Custom useFleetStatus hook (polls every 2s, updates in real-time)
- Updated OracleFleet cards to show agent status + metrics
- WebSocket ready (currently polling, upgrade available)
- TypeScript: 0 errors
- Build: passing

Components:
- components/StatusBadge.tsx (new, reusable)
- components/FleetHealthSummary.tsx (enhanced)
- components/OracleFleet.tsx (updated to use StatusBadge)
- hooks/useFleetStatus.ts (new, real-time data)

Testing:
- Manual: localhost:3000 — Fleet Health + 8 agents visible
- Updates: Real-time refresh every 2-3 seconds
- Errors: 0 TypeScript errors, clean console

Proof:
- git diff output
- npm run typecheck log
- npm run build log
- screenshot: Fleet Health card visible
- screenshot: Agent grid with 8 cards

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Day 2: Polish + Proof

### Step 8: Visual Polish (1 hour)
- [ ] Match Gemini UX research palette (colors, spacing, typography)
- [ ] Ensure component responsive (mobile view)
- [ ] Add subtle animations (fade-in, color pulse for live indicator)
- [ ] Verify accessibility (WCAG AA)

### Step 9: Test Real 9router Data (1 hour)
- [ ] Connect to live 9router agent-status endpoint
- [ ] Verify agents update from real health data
- [ ] Test with various agent states (some down, some stale)
- [ ] Screenshot with real data

### Step 10: Final Proof Package (1 hour)
- [ ] Run full test suite
- [ ] Generate screenshots (Fleet Health + agent grid)
- [ ] Create diff summary
- [ ] Write proof document (see below)

---

## Proof Requirements (Must submit)

**When task complete, Codex must provide**:

```markdown
# Dashboard MVP — Proof of Completion

## 1. Code Diff
\`\`\`bash
git diff main feature/dashboard-mvp-fleet-health | head -500
\`\`\`

## 2. TypeScript Check
\`\`\`bash
npm run typecheck
# Output: 0 errors
\`\`\`

## 3. Build Success
\`\`\`bash
npm run build
# Output: ✓ Build successful
\`\`\`

## 4. Component Structure
- ✅ StatusBadge.tsx created
- ✅ FleetHealthSummary.tsx enhanced
- ✅ useFleetStatus.ts created
- ✅ OracleFleet.tsx updated

## 5. Feature Checklist
- ✅ Fleet Health Summary visible (7/8 agents healthy)
- ✅ Visual bar shows health percentage (green/yellow/red)
- ✅ Live indicator shows connection state
- ✅ Last update timestamp displayed
- ✅ 8 agent cards in grid
- ✅ Each card shows status badge + name + metric
- ✅ Real-time updates every 2-3 seconds
- ✅ No console errors

## 6. Screenshots
[Fleet Health Summary card screenshot]
[Agent grid with 8 cards screenshot]
[Both showing real data from 9router]

## 7. Commit Hash
d48f9c2a...
```

---

## Success Metrics

| Metric | Target | How to Verify |
|--------|--------|---------------|
| Components Created | 3 new (StatusBadge, hook, enhancement) | `git diff --name-only` |
| TypeScript Errors | 0 | `npm run typecheck` |
| Build Passing | ✅ | `npm run build` |
| Real-time Updates | Every 2-3s | Browser DevTools network tab |
| Screenshot Proof | 2 images (health + grid) | Uploaded to proof doc |
| Agent Count | 8 visible | Count in screenshot |
| Status Indicators | All have icon+text | No color-only badges |

---

## Blockers? Ask ธาม Immediately

- API endpoint for agent-status doesn't exist? → Create it or mock data
- Design questions? → Reference Gemini UX research (available in brain/decisions/)
- Dependencies missing? → Install via npm
- Deployment questions? → ธาม handles
- Scope creep? → ธาม scope-gates, keep MVP focused

---

## Timeline

- **Today (Day 1)**: Steps 1-7, commit by EOD
- **Tomorrow (Day 2)**: Steps 8-10, full proof by EOD
- **By 2026-05-20 EOD**: Dashboard visible at localhost:3000 + proof submitted

**Codex**: This is your high-leverage task. Complete this = dashboard foundation done ✅

---

**Task Assigned**: 2026-05-18 21:40 UTC+7  
**Expected Completion**: 2026-05-20 23:59 UTC+7  
**Status**: 🟢 READY TO START

Codex — **Accept task?** Start immediately with Step 1 (Setup).
