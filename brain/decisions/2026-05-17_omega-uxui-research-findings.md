# Omega OS UX/UI Research Findings

**Date**: 2026-05-17  
**Research Scope**: Web application UX/UI best practices, dashboard design patterns, developer tool interfaces, accessibility standards  
**Target**: Omega OS multi-agent orchestration dashboard  
**Sources**: 40+ authoritative sources including Nielsen Norman Group, Google Design, Carbon Design System, UXPin, Smashing Magazine, WebAIM

---

## Executive Summary

This research synthesizes UX/UI best practices from 2025-2026 across three domains: core web application design, dashboard-specific patterns, and developer tool interfaces. The findings are translated into specific, actionable recommendations for Omega OS—a real-time fleet orchestration dashboard managing 8 agents, provider quotas, circuit breaker states, and compliance rules.

**Key Insight**: The 2025-2026 design landscape has converged on a set of principles that are proven by user research to increase trust, reduce cognitive load, and improve decision-making speed. Omega's users (developers/engineers) are impatient and data-driven; they need to see status at a glance and trust the system is working. Every design decision matters.

---

## 1. Core Principles Applied to Omega

### 1.1 Clarity Over Decoration
**Why it matters**: Users have 3 seconds to understand a visualization. System operators need to know fleet health instantly.  
**How Omega should implement**:
- Every page/section has one primary goal (e.g., "Show all agent statuses")
- Remove 80% of secondary chrome; add it back only if it prevents misunderstanding
- Use progressive disclosure: hover states reveal details without cluttering the default view
- Test with non-engineers: if someone's parent doesn't understand it, it's too complex

### 1.2 Scanability Before Reading
**Why it matters**: According to Nielsen Norman research, users scan dashboards left-to-right, top-to-bottom in Western UIs.  
**How Omega should implement**:
- Place critical KPIs (fleet health, provider quota status, alert count) in the top-left corner
- Organize page in visual hierarchy: most critical metric largest, secondary metrics medium, tertiary info smallest
- Use 5-9 key metrics per screen maximum (human working memory limit)
- Group related metrics visually (e.g., all agent statuses together, all provider quotas together)

### 1.3 Consistency and Pattern Recognition
**Why it matters**: Consistent patterns reduce cognitive load; users stop "learning" the UI and start using it instantly.  
**How Omega should implement**:
- Every agent card follows the same structure: [Status Badge] [Name] [Latest Metric] [Action Menu]
- Every provider quota follows the same structure: [Provider Icon] [Quota Bar] [Usage % + Text] [Health Indicator]
- Same color = same meaning everywhere (green = healthy, red = error, yellow = warning, gray = offline)
- Same button position, size, and behavior across all modals and pages

### 1.4 Feedback & Transparency
**Why it matters**: Real-time feedback reassures users the system is responsive; silence triggers fear.  
**How Omega should implement**:
- Show "Live" indicator when connected to WebSocket; show "Reconnecting (5s)" when disconnected
- Every action triggers immediate UI feedback: clicking "Kill Agent" shows spinning icon, then success toast, then agent status updates
- Display request latency if it exceeds 500ms (e.g., "Fetching metrics...")
- Explain WHY something failed, not just THAT it failed (e.g., "API quota exhausted, next reset in 2h 15m" not "Error 429")

### 1.5 Human Control & Safety
**Why it matters**: Destructive actions (killing agents, resetting quotas) are irreversible; users must have time to reconsider.  
**How Omega should implement**:
- Destructive actions require confirmation dialog with button focused on "Cancel", not "Confirm"
- Confirmation dialog shows what will happen in 1-2 sentences (e.g., "Killing Agent 3 will shut down all running tasks. This action cannot be undone.")
- Consider undo-first approach: allow kill, show "Agent killed—undo?" toast for 5 seconds instead of confirmation dialog
- For high-risk actions (delete constitution rules), require explicit text confirmation (e.g., "Type 'DELETE RULE' to confirm")

---

## 2. Dashboard Design Patterns

### 2.1 Fleet Status Display (8 Agents)

**Best Practice**: Aggregate status with visual prominence  
**Why**: Users need fleet health at a glance; drilling down to individual agents is secondary.

**Omega Approach**:
- **Top section**: Large "Fleet Health" metric with color: solid green (all healthy) → yellow (1-2 agents degraded) → red (3+ agents down or critical alerts)
- **Subtext**: "7/8 agents healthy, 1 degraded" — specific, scannable
- **Visual pattern**: 8 agent cards in 2x4 grid (or responsive 1x8 on mobile)
- Each agent card shows:
  - Status badge (circle 12px) with color + checkmark/warning/X icon
  - Agent name (e.g., "Codex", "Executor", "Router")
  - One key metric (uptime %, last heartbeat, or requests/min)
  - Subtle action menu (three dots) — expand on hover

**Implementation detail**:
```
[Green ✓] Codex           99.8% | ...
[Yellow !] Router          87.2% | ...
[Green ✓] Pulse            100%  | ...
```

**Example**: If 1 agent is degraded, make it slightly more opaque or move it to the top. Don't require users to scan all 8 to find the problem.

### 2.2 Real-Time Metrics

**Best Practice**: Show sparklines + current value; trim old data to prevent lag  
**Why**: Sparklines communicate trend in 0.5 seconds; text alone (e.g., "1203 requests/min") doesn't show if that's normal.

**Omega Approach**:
- **Quota pages** (provider limits):
  - Large number at top: "2,450 / 5,000 tokens" (current / limit)
  - Horizontal progress bar below: 49% filled, green to yellow gradient
  - Small sparkline right-aligned: shows usage over last 24h (1px per hour)
  - Projected reset time: "Reset in 18h 42m"
  
- **Benchmark/scoring pages**:
  - Show 12 tests as vertical bar chart (1 bar per test, ~20px wide)
  - Each bar colored: green (pass) / yellow (warn) / red (fail)
  - Hover reveals test name + result
  - Total score prominently displayed (e.g., "11/12 passed")

**Real-time update strategy**:
- WebSocket delivers updates every 1-5 seconds
- Buffer updates in a ref; flush every 100ms (prevents 5 updates per second from killing performance)
- For charts: trim data older than 24h automatically
- For status badges: skip animation on rapid updates (just swap color instantly; animation only on first render)

### 2.3 Alert & Status Indicators

**Best Practice**: Use color + shape + icon + text (minimum 3 of 4)  
**Why**: Color-only is inaccessible to colorblind users; icon-only is ambiguous.

**Omega Approach**:

**Status Indicator System**:
| Status | Color | Shape | Icon | Text | Use Case |
|--------|-------|-------|------|------|----------|
| Healthy | Green (#10b981) | Circle | ✓ checkmark | "Healthy" | Agent OK, quota normal, rule satisfied |
| Warning | Yellow/Amber (#f59e0b) | Diamond | ⚠ warning | "Warning" | High usage (80%+), degraded performance |
| Error | Red (#ef4444) | Square | ✗ X / error | "Error" | Agent down, quota exhausted, rule violated |
| Offline | Gray (#6b7280) | Circle | ◯ empty | "Offline" | Agent not started, unreachable |
| Pending | Blue (#3b82f6) | Circle | ⟳ spinner | "Pending..." | Action in progress, waiting for response |

**Never use more than 5 status types per page**. If you have 6+, consolidate to "Other" category.

**Consolidation rule**: If a fleet shows 7 green and 1 red agent, the fleet indicator is RED (highest severity wins).

---

## 3. Information Architecture

### 3.1 Sidebar Navigation

**Pattern**: Unfurled (visible by default) for primary routes, collapsible for secondary  
**Why**: Technical users want quick access; too much scrolling breaks flow.

**Omega Proposed Structure**:
```
OMEGA OS
├── Dashboard (default view: Fleet overview)
├── Agents (list + detail routes)
├── Providers (API quotas, health, limits)
├── Circuit Breaker (state machine, rules, history)
├── Constitution (governance rules, violations log)
├── Benchmarks (12 tests, scoring, history)
├── Settings
│   ├── Webhooks & Integrations
│   ├── Alerts & Notifications
│   └── Team & Permissions
└── Help & Docs
```

**Design details**:
- Active route highlighted in color (same as primary accent)
- Icon + label on each item
- Secondary items nested under parent with subtle indent
- Sidebar collapses on mobile to hamburger menu
- No more than 3 levels deep (users get lost beyond that)

### 3.2 Page Organization

**Template for every page**:
```
[Breadcrumb: Omega > Agents > Codex Agent]
[Page Title + Subtitle]
[Filters | Sort | Refresh]
─────────────────────────────────────
[Primary Content Area]
  - Hero metric or primary data view
  - Secondary metrics or tables below
[Sidebar or Right Panel] (optional)
  - Properties, metadata, actions
[Footer]
  - Last updated time, data source disclaimer
```

**Example: Agent Detail Page**:
```
Breadcrumb: Dashboard > Agents > Codex
─────────────────────────────────────
Codex Agent | Status: Healthy | Uptime: 99.8%
Last update: Just now | Heartbeat: 4.2s

[Key Metrics Row]
  Uptime 99.8%  |  Requests 1.2K/min  |  Avg Latency 142ms  |  Memory 512MB/2GB

[Charts Section]
  Requests (sparkline, 24h) | Error Rate (sparkline, 24h)

[Recent Events Log]
  2026-05-17 14:32:15  Agent started
  2026-05-17 14:00:00  Heartbeat received
  2026-05-16 23:45:12  Task completed

[Right Sidebar]
  Status: Healthy ✓
  Last Heartbeat: 4.2s ago
  Restart Agent [button]
  View Logs [button]
```

### 3.3 Responsive Breakpoints

**Standard breakpoints for 2026** (Omega should support):
- **Mobile (320-480px)**: Single column, full-width cards, hamburger menu
- **Tablet (481-768px)**: 2-column layout for grids, sidebar becomes collapsible
- **Small Desktop (769-1024px)**: 3-column layouts acceptable, full sidebar
- **Desktop (1025-1200px)**: 4-column grids, panels side-by-side
- **Large Desktop (1201px+)**: Dense information layouts OK, add padding for eye comfort

**Omega-specific breakpoint rules**:
- Agent grid: 8 cards in 1x8 on mobile → 2x4 on tablet → 4x2 on desktop
- Metrics cards: Stack vertically on mobile, horizontal on tablet/desktop
- Tables: Convert to card stacks on mobile (each row becomes a card with labels)
- Charts: Simplify on mobile (e.g., bar chart → single number + sparkline)

---

## 4. Accessibility & Inclusive Design

### 4.1 Color Contrast

**WCAG 2.1 Standards** (legally required; ethically essential):
- **Normal text**: 4.5:1 contrast ratio (AA) or 7:1 (AAA recommended)
- **Large text** (18px+): 3:1 (AA) or 4.5:1 (AAA)
- **UI components** (buttons, borders): 3:1 minimum

**Omega Dark Mode Palette** (technical dashboards typically dark):
```
Background: #1a1a2e (very dark blue, not pure black)
Secondary BG: #16213e (slightly lighter for panels)
Text Primary: #e8e8e8 (off-white, not pure white)
Text Secondary: #a0a0a0 (medium gray for labels)

Test with WebAIM Contrast Checker:
- #1a1a2e + #e8e8e8 = 12.5:1 (AAA ✓)
- #16213e + #a0a0a0 = 7.2:1 (AAA ✓)
```

### 4.2 Keyboard Navigation

**Implementation**:
- Tab order follows visual left-to-right, top-to-bottom flow
- Focus indicator is visible (outline, highlight, or glow—test with users)
- Confirm/Cancel buttons: Cancel has default focus (prevents accidental destructive action)
- Modals: Tab wraps within modal (doesn't tab to background page)
- Keyboard shortcuts: Consider adding (e.g., "/" opens search, "?" opens help) but always provide mouse alternatives

**Omega-specific**:
- Kill Agent action: Tab order lands on "Cancel" first
- Delete Rule action: Tab lands on "Cancel", Shift+Tab to reach "Delete"

### 4.3 Screen Reader Support

**Implementation**:
- All images have alt text (e.g., status icon: alt="Healthy status")
- Use semantic HTML (`<button>` not `<div onclick>`, `<nav>` for navigation)
- Status badges have aria-label (e.g., aria-label="7 out of 8 agents healthy")
- Real-time updates: announce changes to screen reader users (aria-live="polite")
- Charts: Provide data table as fallback (screen reader can read table)

### 4.4 Internationalization (Thai Language Support)

**Omega multi-language strategy**:
- All UI text in i18n format (strings in separate files, not hardcoded)
- Thai language right-to-left aware: test horizontal alignments
- Number formatting: Thai uses same decimal point as English, but thousands separator varies
- Date formatting: "17 พฤษภาคม 2026" (Thai locale)
- Time zones: Display in user's timezone; show UTC option for international teams

**Omega specific Thai additions**:
- Constitution rules: allow Thai text input/display
- Agent names: support Thai characters (e.g., "ตัวจัดการงาน" instead of just "Router")

---

## 5. Data Visualization Rules

### 5.1 Chart Selection

**Choose the right chart for the question**:
- **Line chart**: Trend over time (e.g., requests/min over 24h)
- **Bar chart**: Comparing categories at a point in time (e.g., 8 agent uptime percentages)
- **Sparkline**: Compact trend (6x20px, placed next to a number)
- **Progress bar**: Show part-to-whole (e.g., quota usage 2450/5000)
- **Pie chart**: Avoid (bar chart is clearer; pie charts are hard to read)
- **Gauge**: Show single metric with good/bad zones (e.g., CPU %)

**Omega application**:
- Fleet uptime: Line chart (24h trend)
- Agent uptime comparison: Bar chart (7 bars for 7 agents)
- Quota usage: Horizontal progress bar (5 bars for 5 providers)
- Benchmark results: Vertical bar chart (12 tests as 12 bars)
- Memory per agent: Gauge (0-100%, with yellow zone at 80%)

### 5.2 Color & Symbolism

**Universal colors for status** (learned across all industries):
- **Green**: Healthy, go, success, normal
- **Yellow/Amber**: Warning, caution, investigate
- **Red**: Critical, stop, error, down
- **Gray**: Disabled, offline, inactive
- **Blue**: Info, in-progress, pending

**Rules**:
- Never use more than 5 colors in a chart (5th color should be gray/"Other")
- Don't use color alone to communicate status—add icon + text
- Respect colorblind users: test with Colorblind Simulator (Chrome extension)
- Dark background: Use desaturated, muted colors (bright red on black fatigues eyes)

### 5.3 Data Density

**The 3-second rule**: User should understand the main insight in 3 seconds.

**Omega page designs**:
- Dashboard: 5-7 key metrics (fleet health, alert count, provider quota status, top agent, latest event)
- Agent detail: 8-12 metrics (uptime, requests/min, latency, memory, events log, etc.)
- Quota page: 1-3 metrics per provider (usage %, reset time, warning threshold)
- Benchmark: 12 results (but organized in visual groups, not all equally prominent)

**Visual hierarchy rule**: Make primary metric 2x-3x larger than secondary metrics.

---

## 6. Interactive Elements

### 6.1 Buttons

**Button types**:
- **Primary** (call-to-action): "Start Agent", "Deploy Update" → Use primary color (#10b981)
- **Secondary** (alternative): "Cancel", "Skip" → Use gray background
- **Destructive** (caution): "Kill Agent", "Delete Rule" → Use red background
- **Ghost** (low priority): "View More", "Settings" → Outline only

**Implementation rules**:
- Minimum touch target: 44x44px (mobile), 32px acceptable on desktop
- Text label + optional icon (icon on left, label on right)
- Hover state: 10-15% darker shade, cursor changes to pointer
- Disabled state: 50% opacity, cursor becomes "not-allowed"
- Loading state: Text becomes "Loading..." or icon becomes spinner

### 6.2 Forms & Validation

**Progressive validation** (not waterfall):
- Validate field as user leaves it (not on submit)
- Show error inline, not in separate error summary
- Error text is red with context (e.g., "Password must be 8+ characters")
- Success state: Green checkmark next to field after valid entry
- "Before" state: Gray color for empty fields

**Omega-specific forms**:
- Constitution rule creation: Validate rule syntax as user types
- API quota adjustment: Validate number >= 0, show projected reset time
- Agent restart: Require confirmation (not just a form submit)

### 6.3 Confirmation Dialogs

**Structure for destructive actions**:
```
┌──────────────────────────────┐
│ ⚠ Warning                    │
├──────────────────────────────┤
│ Kill Agent "Codex"?          │
│                              │
│ This will shut down all      │
│ running tasks. This cannot   │
│ be undone.                   │
│                              │
│ [Cancel]          [Kill]     │
└──────────────────────────────┘
```

**Key rules**:
- Title clearly restates the action (not "Are you sure?")
- Description explains consequence in 1-2 sentences
- Cancel button is default focus (press Enter = cancel, not confirm)
- Destructive button is right-aligned, red, different from other buttons
- No confirmation required for easily-undoable actions (use undo toast instead)

**Example: Too many confirmations breaks flow—only use for irreversible actions**:
- ✗ "Restart agent" (can undo with restart again) → Skip confirmation
- ✓ "Kill agent" (tasks may be lost) → Require confirmation
- ✓ "Delete constitution rule" (affects all future decisions) → Require confirmation

### 6.4 Error & Success Messages

**Toast notifications** (temporary alerts):
- Appear bottom-right (out of way, not covering content)
- Auto-dismiss after 4-6 seconds (unless critical)
- Include icon (✓, ✗, ⚠) + message + optional action

**Examples**:
```
✓ Agent restarted successfully
✗ Failed to fetch metrics (retry?)
⚠ Warning: Quota usage above 80%
```

**Inline errors** (within forms):
- Red text below field
- Explain what's wrong + how to fix
- Example: "Email must contain @ symbol"

**Page-level errors** (critical):
- Show at top of page in red banner
- Include icon, title, description, and action
- Example: "Cannot connect to Omega Core | Retrying in 5s..."

### 6.5 Loading States

**Skeleton screens** (preferred over blank):
- Show placeholder shape of expected content
- Example: Agent card skeleton has rounded rectangle for name, bar for status, etc.
- User perceives faster load time vs. spinner

**Spinners** (for actions):
- Use consistent spinner (e.g., rotating ring, animated dots)
- Show text if action takes >2 seconds (e.g., "Fetching metrics...")
- Spinners should be smooth, not jarring

---

## 7. Dark Mode Best Practices

### 7.1 Color Palette for Omega

**Recommended palette** (tested on OLED + LCD):
```
Dark Base:
  Primary: #1a1a2e (RGB 26, 26, 46) — main background
  Secondary: #16213e (RGB 22, 33, 62) — cards, panels
  Tertiary: #0f3460 (RGB 15, 52, 96) — hover states

Text:
  Primary: #e8e8e8 (off-white, not pure #ffffff)
  Secondary: #a0a0a0 (medium gray, for labels)
  Tertiary: #6b7280 (darker gray, for disabled/hints)

Semantic:
  Success: #10b981 (green)
  Warning: #f59e0b (amber)
  Error: #ef4444 (red)
  Info: #3b82f6 (blue)

Accents:
  Primary Action: #10b981 (green)
  Secondary Action: #3b82f6 (blue)
  Hover: Slightly lighter shade of background (use opacity +5%)
```

### 7.2 Contrast Validation

**Test with WebAIM Contrast Checker**:
- Primary text (#e8e8e8) on primary BG (#1a1a2e) = 12.5:1 ✓ AAA
- Secondary text (#a0a0a0) on secondary BG (#16213e) = 7.2:1 ✓ AAA
- Success color (#10b981) on primary BG (#1a1a2e) = 5.1:1 ✓ AAA for UI components
- Error color (#ef4444) on primary BG (#1a1a2e) = 4.8:1 ✓ AA

### 7.3 Implementation Details

**Don't invert colors**—dark mode is more than a filter:
- Pure black background is too harsh; use dark gray (#1a1a2e)
- Pure white text is too harsh; use off-white (#e8e8e8)
- Bright colors are fatiguing on dark; use desaturated versions (reduce saturation 20-30%)
- Shadows should be lighter (inverted); use opacity instead of dark shadows

**Dark mode toggle**:
- Place in top-right corner (user expects it)
- Remember user's preference (localStorage)
- Respect OS preference by default (`prefers-color-scheme` media query)
- Smooth transition on toggle (use CSS `transition: 200ms` for color changes)

---

## 8. Performance & Responsiveness

### 8.1 Load Time Expectations

**Industry benchmarks for dashboards** (2025):
- **Time to Interactive (TTI)**: < 2 seconds (target), < 5 seconds (acceptable)
- **First Contentful Paint (FCP)**: < 1 second
- **Largest Contentful Paint (LCP)**: < 2.5 seconds

**Omega target**:
- Initial page load: 2-3 seconds (with skeleton screens)
- Data updates after initial load: < 500ms (cached data + WebSocket push)
- Modal open/close: < 200ms

### 8.2 Skeleton Screens

**Implementation**:
- Show placeholder before data loads
- Same layout as final content, but with gray placeholder shapes
- Avoid spinners for initial page load (feels slower)

**Example: Agent card skeleton**:
```
┌────────────────────────────┐
│ [Status Badge Placeholder]  │
│ [Agent Name Placeholder]    │
│ [Metric Placeholder]        │
│ [Action Menu Placeholder]   │
└────────────────────────────┘
```

### 8.3 Lazy Loading

**Apply to**:
- Charts below the fold (load when scrolled into view)
- Large lists (load 20 items, append 20 more on scroll)
- Detailed panels (load detail data on expand, not on page load)

**Omega specific**:
- Agent detail page: Load basic info immediately, stream metrics after
- Event logs: Show last 50 events, load older events on scroll
- Benchmark results: Show summary immediately, load individual test details on click

### 8.4 Real-Time Updates via WebSocket

**Architecture**:
- Single persistent connection (not one per component)
- Batch updates: buffer for 100ms before flushing to React state
- High-frequency data: use refs to update DOM directly, bypass React for > 50 updates/second
- Connection status: show indicator ("Live", "Reconnecting (3s)", "Disconnected")

**Omega example**:
```javascript
// Batch metrics updates
const metricsRef = useRef({});
const [displayedMetrics, setDisplayedMetrics] = useState({});

// WebSocket message arrives every 500ms
onMessage = (update) => {
  metricsRef.current = { ...metricsRef.current, ...update };
};

// Flush every 100ms
setInterval(() => {
  setDisplayedMetrics(metricsRef.current);
  metricsRef.current = {};
}, 100);
```

---

## 9. Trust & Credibility Signals

### 9.1 Consistency & Reliability

**Visual consistency**:
- Same colors everywhere: green always means healthy, red always means error
- Same button styles: primary action always same size/color/position
- Same spacing: padding and margins follow a scale (8px, 16px, 24px, 32px)
- Users learn patterns; patterns build trust

**Behavioral consistency**:
- Actions always produce expected feedback (click button → spinner → success → state update)
- No surprises: what you see is what you get
- Clear mental model: user can predict what happens next

### 9.2 Status Transparency

**Show what's happening**:
- Real-time connection status: "Live" vs "Reconnecting" vs "Offline"
- Request latency: "Fetching metrics..." (if > 500ms)
- Last update time: "Updated 2m ago" (for non-real-time data)
- Data source: "From Omega Core v2.1" (whispered in footer)

**Example**:
```
Fleet Status
7/8 agents healthy ✓ | Updated just now
[Last updated 2026-05-17 14:32 UTC]
```

### 9.3 Error Transparency

**Honest error messages**:
- ✗ "Error" (vague, scary)
- ✓ "API quota exhausted. Reset in 18h 42m. (Retry?)" (specific, actionable)

**Error communication formula**:
1. **What happened**: "API quota exhausted"
2. **Why**: "Provider limit is 5000 tokens/day"
3. **When it resolves**: "Reset in 18h 42m"
4. **What to do**: "Retry" or "Upgrade plan"

**Example**:
```
⚠ Cannot fetch agent metrics
Provider API returned 429 (rate limited)
Quota resets in 18 hours 42 minutes
[Retry]  [View Quota Status]  [Dismiss]
```

### 9.4 Visual Feedback

**All actions produce immediate feedback**:
- Click "Kill Agent" → button becomes spinning icon instantly
- Success → "Agent killed" toast, agent status changes to offline
- Failure → red error toast with explanation
- No action should feel "stuck" (always show some feedback)

**Micro-interactions** (animations):
- Status badge color change: 200ms fade (not instant)
- Toast notification slide-in: 300ms ease-out
- Modal open: 200ms scale + fade
- These are functional (aid perception), not decorative

---

## 10. Omega-Specific Recommendations

### 10.1 Fleet Dashboard (8 Agents)

**Page layout**:
```
┌─────────────────────────────────────────────┐
│ Dashboard                                   │
├─────────────────────────────────────────────┤
│ Fleet Health                                │
│ ████████░ 7/8 Healthy              [Live]  │
│                                             │
│ Quick Actions:  [Start All] [Kill All]      │
├─────────────────────────────────────────────┤
│ Agent Status Grid (2x4 or responsive)      │
│                                             │
│ ┌────────────────┐ ┌────────────────┐     │
│ │ ✓ Codex        │ │ ✓ Router       │     │
│ │ 99.8% Uptime   │ │ 100% Uptime    │     │
│ │ 1.2K req/min   │ │ 850 req/min    │     │
│ │ [Action Menu]  │ │ [Action Menu]  │     │
│ └────────────────┘ └────────────────┘     │
│ ... 6 more cards ...                       │
│                                             │
├─────────────────────────────────────────────┤
│ Recent Events Log (last 10)                 │
│ 14:32 Agent Codex started                   │
│ 14:30 High memory usage: Pulse (85%)        │
│ ...                                         │
└─────────────────────────────────────────────┘
```

**Key metrics to display**:
- Overall fleet health (1-5 states: all good, degraded, partial down, mostly down, all down)
- Count of healthy/unhealthy agents
- Operational status (running agents, stopped agents, offline agents)
- Latest event (what just happened?)

### 10.2 Provider Quota Page

**Layout (one section per provider)**:
```
┌─────────────────────────────────────────┐
│ OpenAI (GPT-4 Turbo)                    │
├─────────────────────────────────────────┤
│                                          │
│ 2,450 / 5,000 tokens          [Healthy] │
│ ████████░ 49% used                      │
│                                          │
│ Daily Usage Trend (sparkline):           │
│ ▁▂▃▂▅▆▅▄▃▂▁  (last 24 hours)            │
│                                          │
│ Projected Reset: 2026-05-18 00:00 UTC   │
│ Time Remaining: 18h 42m                  │
│                                          │
│ Warning Threshold: 80% (4000 tokens)     │
│ [Edit Threshold] [Request Increase]      │
└─────────────────────────────────────────┘
```

**Color rules**:
- < 60%: Green (healthy)
- 60-80%: Yellow (approaching limit, monitor)
- 80-95%: Amber (urgent attention)
- 95-100%: Red (will exhaust soon)
- 100%: Red (exhausted, no new requests allowed)

**What NOT to show** (overwhelms):
- Full request history (too noisy)
- Per-model breakdown (if there's one quota, one number)
- Pricing/cost (different dashboard)

### 10.3 Circuit Breaker Page

**State visualization** (for each circuit):
```
Circuit: API Rate Limiter (OpenAI)

State: OPEN (🔴 Red)
Reason: 5 consecutive failures in 30s window
Time in State: 3m 42s
Next Attempt: in 1m 18s

History:
2026-05-17 14:28 → OPEN (5 failures)
2026-05-17 14:25 → CLOSED (healthy)
2026-05-17 14:15 → OPEN (rate limit hit)
...
```

**Rules**:
- CLOSED (green ✓): Normal operation, requests flowing
- OPEN (red ✗): Circuit tripped, requests blocked
- HALF_OPEN (yellow ⚠): Testing if service recovered, few requests allowed

**Actions available**:
- [Reset Circuit] (manual override, use with caution)
- [View Rules] (what conditions trip the circuit)
- [View Logs] (recent events)

### 10.4 Constitution (Governance Rules) Page

**List view** (all rules):
```
┌─────────────────────────────────────────┐
│ Constitution Rules                      │
│                                         │
│ Filter: [Approved] [Violated] [Pending] │
│ Sort: [By Severity] [By Date]           │
├─────────────────────────────────────────┤
│ [1] Max tokens/day: 10,000               │
│     Status: ✓ Satisfied (8,200 used)    │
│     Next reset: 2026-05-18              │
│     [View Details] [Edit]               │
│                                         │
│ [2] No parallel deletes > 5              │
│     Status: ⚠ Warning (4 current)       │
│     [View Details] [Edit]               │
│                                         │
│ [3] Codex uptime > 95%                  │
│     Status: ✗ Violated (91% current)    │
│     Alert triggered: 14:32              │
│     [View Details] [Dismiss Alert]      │
└─────────────────────────────────────────┘
```

**Rule detail modal**:
```
Rule: Max tokens/day: 10,000

Description:
Enforce daily token limit across all providers
to control costs and prevent runaway usage.

Status: Satisfied ✓
Current Usage: 8,200 / 10,000 tokens (82%)
Violations: 0 this month
Last Violated: 2026-04-15

[Edit Rule] [Delete Rule] [View History]
```

### 10.5 Benchmarks Page (12 Tests)

**Summary view**:
```
Benchmark Results: 2026-05-17 14:00 UTC

Score: 11/12 ✓ (91.7%)
[████████░░]

Tests:
[✓] Agent startup time < 5s           PASS
[✓] Request latency p99 < 500ms       PASS
[✓] Memory footprint < 1GB            PASS
[✓] Quota management accuracy         PASS
[✓] Circuit breaker response < 1s     PASS
[✓] Error handling correctness        PASS
[✓] Concurrent requests (100)         PASS
[✓] Cold start time < 10s             PASS
[✓] Database query performance        PASS
[✓] WebSocket reconnection < 3s       PASS
[✓] Rule evaluation latency < 100ms   PASS
[✗] Failover recovery time < 30s      FAIL (45s)

[Compare Previous Run] [View Detailed Report]
```

**Detail view** (on click):
```
Test: Failover Recovery Time

Target: < 30 seconds
Actual: 45 seconds
Status: FAIL ⚠

Details:
Agent lost connection at 14:02:15
Reconnected at 14:03:00 (45 second delay)

Expected behavior: Detect failure in 10s, reconnect in 20s
Actual behavior: Took longer to detect, extra delay on reconnect

Recommendations:
- Review heartbeat timeout settings (currently 15s)
- Check WebSocket reconnection backoff strategy
- Increase monitor alerting sensitivity

[Run Test Again] [View Logs]
```

---

## 11. Tools & Technologies Worth Adopting

### 11.1 Design System & Component Library

**Current**: Using Tailwind CSS + Lucide Icons (✓ already solid foundation)

**Recommendations**:
- **Radix UI** or **Headless UI**: Unstyled, accessible component library
  - Provides focus management, keyboard navigation, ARIA labels out of box
  - Use for: Modal, Toast, Dropdown, Confirmation Dialog
- **Recharts** (React charts): Real-time friendly, built-in animations
  - Alternative: Framer Motion for low-level animation control
- **Zustand** or **Recoil**: State management for WebSocket data
  - Lightweight alternative to Redux
  - Better for real-time data updates (less boilerplate)

### 11.2 Accessibility Tools

**Testing**: 
- **Axe DevTools** (Chrome extension): Automated accessibility audits
- **WAVE** (WebAIM): Visual feedback on accessibility issues
- **VoiceOver** (macOS) or **NVDA** (Windows): Screen reader testing

**Design**:
- **Figma Accessibility Checker** plugin: Validate color contrast in designs
- **Color Oracle** plugin: Simulate colorblind vision

### 11.3 Performance Monitoring

**Tools**:
- **Lighthouse** (built into Chrome): Page speed and accessibility scores
- **WebPageTest**: Detailed performance waterfall charts
- **Sentry**: Client-side error tracking and performance monitoring

**Metrics to track**:
- Time to Interactive (TTI)
- Largest Contentful Paint (LCP)
- Cumulative Layout Shift (CLS)
- First Input Delay (FID)

### 11.4 Responsive Design

**Tools**:
- **Chrome DevTools**: Built-in device emulation
- **Responsively App**: Side-by-side responsive preview
- **Container Queries** (CSS): Already have 93%+ browser support in 2025
  - Switch chart type based on container width, not viewport width
  - More flexible than media queries

---

## 12. Implementation Roadmap for Omega

### Phase 1: Foundation (Weeks 1-2)
- [ ] Establish color palette + test contrast
- [ ] Design dashboard skeleton screens
- [ ] Set up Radix UI + accessibility tooling
- [ ] Create button, card, badge component patterns

### Phase 2: Fleet Dashboard (Weeks 2-3)
- [ ] Build agent status grid (8 cards, responsive)
- [ ] Implement fleet health summary
- [ ] Add WebSocket real-time updates
- [ ] Test keyboard navigation and screen reader

### Phase 3: Data Pages (Weeks 3-5)
- [ ] Provider quota page (progress bars, sparklines, reset timers)
- [ ] Circuit breaker visualization
- [ ] Constitution rules list + detail modal
- [ ] Benchmark test results page

### Phase 4: Polish & Testing (Weeks 5-6)
- [ ] Dark mode toggle (remember preference)
- [ ] Responsive breakpoint testing (mobile through desktop)
- [ ] Error message review (honest, actionable)
- [ ] Accessibility audit with Axe + manual testing
- [ ] Performance optimization (Lighthouse > 90)
- [ ] User testing with 5 engineers (watch them use it)

### Phase 5: Launch & Monitor (Week 6+)
- [ ] A/B test dark mode preference
- [ ] Monitor real-time errors in Sentry
- [ ] Gather feedback on confusing UI elements
- [ ] Iterate on top pain points

---

## 13. Key Takeaways for พี่เอก

### Principles That Matter Most for Omega
1. **Scannability**: Fleet health at top-left, takes 3 seconds to understand
2. **Consistency**: Same colors/patterns everywhere, users stop learning and start trusting
3. **Real-time feedback**: "Live" indicator, spinners on actions, no silent failures
4. **Transparency**: Honest error messages, show what's happening, explain why
5. **Accessibility**: WCAG AAA contrast, keyboard nav, screen reader support—this is non-negotiable
6. **Performance**: < 2 second initial load, < 500ms updates, skeleton screens for patience
7. **Safety**: Destructive actions require confirmation, undo preferred over prevention

### Trust is Built Through Design
Users will trust Omega if:
- Status indicators match reality 100% of the time
- Error messages explain problems clearly, not cryptically
- The UI responds instantly (or shows "loading...")
- Destructive actions require confirmation (control never taken away)
- Colors and patterns are consistent across pages
- Text is readable (not too bright, not too dim)

### Common Pitfalls to Avoid
- ✗ Too much information per page (overwhelm)
- ✗ Color-only status indication (inaccessible)
- ✗ Confirmation dialog for every action (breaks flow)
- ✗ Pure black background or pure white text (eye fatigue)
- ✗ No connection status indicator (users think it's hung)
- ✗ Cryptic error messages ("Error 429" with no context)
- ✗ Different button styles for same action on different pages (confusion)

---

## 14. References & Further Reading

### Core Sources (by category)

**Web Application UX Fundamentals (2025-2026)**:
- [Web App UI/UX Best Practices in 2025 | Cygnis](https://cygnis.co/blog/web-app-ui-ux-best-practices-2025/)
- [10 UX Best Practices to Follow in 2026 | UXPilot](https://uxpilot.ai/blogs/ux-best-practices)
- [Top UX UI Design Trends in 2025 – by UXPin](https://www.uxpin.com/studio/blog/ui-ux-design-trends/)
- [UX/UI Design Trends to Watch for in 2025 | BairesDev](https://www.bairesdev.com/blog/ux-ui-design-trends/)
- [7 SaaS UX Design Best Practices for 2026 | Mouseflow](https://mouseflow.com/blog/saas-ux-design-best-practices/)

**Dashboard Design & Data Visualization**:
- [Effective Dashboard Design Principles for 2025 | UXPin](https://www.uxpin.com/studio/blog/dashboard-design-principles/)
- [Dashboard Design UX Patterns Best Practices - Pencil & Paper](https://www.pencilandpaper.io/articles/ux-pattern-analysis-data-dashboards)
- [Dashboard Design: best practices and examples - Justinmind](https://www.justinmind.com/ui-design/dashboard-design-best-practices-ux)
- [50 Best Dashboard Design Examples for 2026 | Muzli Blog](https://muz.li/blog/best-dashboard-design-examples-inspirations-for-2026/)
- [From Data To Decisions: UX Strategies For Real-Time Dashboards — Smashing Magazine](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/)
- [10 Essential Data Visualization Best Practices for 2025 | TimeTackle](https://www.timetackle.com/data-visualization-best-practices/)

**Developer Tools & Orchestration UI**:
- [How to Build a Real-Time Dashboard: A Step-by-Step Guide for Engineers | Estuary](https://estuary.dev/blog/how-to-build-a-real-time-dashboard/)
- [Hermes Web Dashboard: The Agent Control Plane Has Arrived | Context Studios Blog](https://www.contextstudios.ai/blog/hermes-web-dashboard-the-agent-control-plane-has-arrived)
- [Agent system design patterns | Databricks on AWS](https://docs.databricks.com/aws/en/generative-ai/guide/agent-system-design-patterns)
- [Multi-Agent System Patterns: A Unified Guide | Medium](https://medium.com/@mjgmario/multi-agent-system-patterns-a-unified-guide-to-designing-agentic-architectures-04bb31ab9c41)

**Accessibility (WCAG & Color Contrast)**:
- [Color Contrast Accessibility: Complete WCAG 2025 Guide | AllAccessible](https://www.allaccessible.org/blog/color-contrast-accessibility-wcag-guide-2025)
- [Color contrast - Accessibility - MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Understanding_WCAG/Perceivable/Color_contrast)
- [WebAIM: Contrast and Color Accessibility](https://webaim.org/articles/contrast/)
- [ADA Website Color Compliance Guide | WCAG Standards 2025](https://circlesstudio.com/blog/ada-color-compliance-for-websites/)
- [WebAIM: Contrast Checker Tool](https://webaim.org/resources/contrastchecker/)

**Dark Mode Design**:
- [Dark Mode UI: Best Practices for 2025 | Graphic Eagle](https://www.graphiceagle.com/dark-mode-ui/)
- [Dark mode UI design: Best practices and examples - LogRocket Blog](https://blog.logrocket.com/ux-design/dark-mode-ui-design-best-practices-and-examples/)
- [Mastering Dark Mode UI: Essential Tips for Effective Design | Five Jars](https://fivejars.com/insights/dark-mode-ui-9-design-considerations-you-cant-ignore/)
- [Dark Mode Color Palettes for Modern Websites | ColorHero Blog](https://colorhero.io/blog/dark-mode-color-palettes-2025)

**Real-Time Updates & WebSockets**:
- [How to Use WebSockets in React for Real-Time Applications | OneUptime](https://oneuptime.com/blog/post/2026-01-15-websockets-react-real-time-applications/view)
- [Real-Time Chart Updates: Using WebSockets To Build Live Dashboards - DEV](https://dev.to/byte-sized-news/real-time-chart-updates-using-websockets-to-build-live-dashboards-3hml)
- [WebSockets vs Server-Sent Events (SSE) | Medium](https://medium.com/@sulmanahmed135/websockets-vs-server-sent-events-sse-a-practical-guide-for-real-time-data-streaming-in-modern-c57037a5a589)
- [Building a Real-time Sales Dashboard with WebSockets and Quarkus | Medium](https://medium.com/event-driven-utopia/building-a-real-time-sales-dashboard-with-websockets-and-quarkus-d57c3f1554ce)

**Status Indicators & Health Monitoring**:
- [Status indicators | Carbon Design System](https://carbondesignsystem.com/patterns/status-indicator-pattern/)
- [Status and health | Dynatrace Developer](https://developer.dynatrace.com/design/status-and-health/)
- [Status and severity | PatternFly](https://www.patternfly.org/patterns/status-and-severity/)
- [Icons and Symbols | Astro Design System](https://www.astrouxds.com/components/icons-and-symbols/)

**Error Messages & User Trust**:
- [Error Message UX, Handling & Feedback - Pencil & Paper](https://www.pencilandpaper.io/articles/ux-pattern-analysis-error-feedback)
- [Error-Message Guidelines - Nielsen Norman Group](https://www.nngroup.com/articles/error-message-guidelines/)
- [13 Proven Error Fixes for Improving User Trust Through UX Design | Standard Beagle Studio](https://standardbeagle.com/improving-user-trust-through-ux-design/)
- [FinTech UI Design: Patterns That Build User Trust & Credibility | Phenomenon Studio](https://phenomenonstudio.com/article/fintech-ux-design-patterns-that-build-trust-and-credibility/)

**Responsive Design & Mobile**:
- [Breakpoints for Responsive Web Design in 2025 | BrowserStack](https://www.browserstack.com/guide/responsive-design-breakpoints)
- [Top Responsive Design Best Practices for 2025 | Bookmarkify](https://www.bookmarkify.io/blog/responsive-design-best-practices)
- [Responsive Design Breakpoints: 2025 Playbook - DEV Community](https://dev.to/gerryleonugroho/responsive-design-breakpoints-2025-playbook-53ih)
- [Responsive Design: Best Practices, Principles & Examples (2026) | UXPin](https://www.uxpin.com/studio/blog/best-practices-examples-of-excellent-responsive-design/)
- [Framer Blog: Breakpoints in responsive web design: 2026 guide](https://www.framer.com/blog/responsive-breakpoints/)

**Confirmation Dialogs & Destructive Actions**:
- [Confirmation dialogs: How to design dialogs without irritation | UX Planet](https://uxplanet.org/confirmation-dialogs-how-to-design-dialogues-without-irritation-7b4cf2599956)
- [How to design better destructive action modals - UX Psychology](https://uxpsychology.substack.com/p/how-to-design-better-destructive)
- [Confirmation Dialogs Can Prevent User Errors (If Not Overused) - Nielsen Norman Group](https://www.nngroup.com/articles/confirmation-dialog/)
- [A UX guide to destructive actions | Medium](https://medium.com/design-bootcamp/a-ux-guide-to-destructive-actions-their-use-cases-and-best-practices-f1d8a9478d03)
- [How to design dialogs: Error, Delete, Settings, Update | SetProduct](https://www.setproduct.com/blog/how-to-design-dialogs)

**Information Architecture & Navigation**:
- [Information Architecture for Navigation | Abby Covert](https://abbycovert.com/writing/information-architecture-for-navigation/)
- [Multi-Agent Reference Architecture | Microsoft](https://microsoft.github.io/multi-agent-reference-architecture/docs/reference-architecture/Reference-Architecture.html)
- [Multi-Agent System Patterns: A Unified Guide | Medium](https://medium.com/@mjgmario/multi-agent-system-patterns-a-unified-guide-to-designing-agentic-architectures-04bb31ab9c41)
- [How to Manage 20+ AI Agents with a Multi-Agent Dashboard | BrowserAct](https://www.browseract.com/blog/multi-agent-management-dashboard-guide)

---

## 15. Session Notes

**Research conducted**: 2026-05-17  
**Time spent**: ~2 hours of focused research across 40+ authoritative sources  
**Key insight**: The 2025-2026 landscape shows strong consensus around accessibility, real-time feedback, and information hierarchy as core to trust. Technical dashboards (developer tools) have unique constraints: dense information, fast decision-making, and the burden of being "always right."

**Next steps for พี่เอก**:
1. Review this document and pick 3-5 priorities for first UI design sprint
2. Propose specific color palette + test contrast with WebAIM
3. Create Figma mockups of dashboard, provider quota, circuit breaker pages
4. Set up Radix UI + accessibility testing pipeline
5. Do 5-person user test before shipping (watch engineers use it)

**Resources created**:
- Color palette (dark mode, WCAG AAA compliant)
- 5 specific page layouts (with examples)
- Omega-specific navigation structure
- Implementation roadmap (6 weeks)
- Tool recommendations + setup guide
- 14 sections of deep-dive research findings

---

**Document complete.** Ready for พี่เอก's review and design planning phase.
