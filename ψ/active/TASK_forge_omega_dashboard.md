# Task: Forge Omega V2 Dashboard Improvements

**Assigned to**: Codex  
**Assigned by**: ธาม (tham-oracle)  
**Date**: 2026-05-18 01:30 UTC+7  
**Status**: Pending Assignment  
**Priority**: High

---

## Mission

Improve **Forge Omega V2 Dashboard** based on comprehensive UX/UI research already completed by Gemini. Make the dashboard beautiful, scannable, and trustworthy for operators.

## Context

- **Research**: Gemini completed 314-item UX/UI research (commit 3f7072c)
  - File: `brain/decisions/2026-05-17_omega-uxui-research-findings.md`
  - Covers: fleet status display, real-time feedback, dark mode palette, accessibility, interactive elements
  
- **Current Dashboard**: `/mnt/d/Git/forge-omega-v2/`
  - Stack: Next.js 16.2.6 + React 19 + TypeScript 5 + Tailwind CSS 4
  - 10+ components built but need visual/UX improvements
  - 0 TypeScript errors currently
  
- **Supervisor**: ธาม will monitor, unblock, coordinate with Gemini if needed

---

## Work Phases (In Priority Order)

### Phase 1: Critical UX (Now)
- [ ] **Fleet Health Summary Card**
  - Show 7/8 agents healthy with visual bar
  - Large green/yellow/red color based on health percentage
  - Live indicator (connected/reconnecting/offline)
  
- [ ] **Status Badges (Consistent)**
  - Use color + icon + text (never color-only)
  - Green checkmark = healthy
  - Yellow warning = degraded
  - Red X = error
  - Gray circle = offline
  
- [ ] **Live/Real-time Indicators**
  - WebSocket status: "Live" (green pulse) / "Reconnecting..." (yellow) / "Offline" (red)
  - Last update timestamp

### Phase 2: Visual Improvements
- [ ] Data density & scanability
  - 5-9 key metrics per screen max
  - Larger primary metrics (2-3x secondary)
  
- [ ] Sparklines for metrics
  - Mini charts for trends (usage over 24h)
  
- [ ] Loading states
  - Skeleton screens preferred over blank
  - Smooth spinners with text if > 2s
  
- [ ] Error messages
  - Explain WHAT happened + WHY + WHEN it resolves + WHAT to do
  - Not just "Error" but "Quota exhausted. Resets in 18h 42m. [Retry?]"

### Phase 3: Interactivity Details
- [ ] Confirmation dialogs for destructive actions
  - Cancel button is default focus
  - Explain consequence in 1-2 sentences
  
- [ ] Toast notifications
  - Success/error/warning toasts appear bottom-right
  - Auto-dismiss 4-6 seconds
  
- [ ] Form validation
  - Progressive (as user leaves field, not on submit)
  - Inline errors with red text + help text

---

## Acceptance Criteria

- [ ] Phase 1 complete: Fleet Health + Live indicator + Status badges visible and working
- [ ] Visual hierarchy clear: primary metrics 2-3x larger than secondary
- [ ] All status indicators use color + icon + text (not color-only)
- [ ] "Live" indicator shows connection state accurately
- [ ] TypeScript check: 0 errors
- [ ] No regressions in existing components
- [ ] Commit(s) with clear messages per phase
- [ ] Report progress at each phase completion

---

## Resources

1. **Research document**: `/root/ghq/github.com/E0993599799/tham-oracle/brain/decisions/2026-05-17_omega-uxui-research-findings.md`
2. **Dashboard repo**: `/mnt/d/Git/forge-omega-v2/`
3. **Design system**: `app/globals.css` (colors, animations already defined)
4. **Existing components**: `components/` (StatusBar, OracleFleet, ModelPalette, ForgeQueue, etc.)
5. **Supervisor**: ธาม (reach out anytime via thread)

---

## Checkins & Updates

- Report progress when each phase is complete
- If blocked, ping ธาม immediately
- If you need Gemini's input on research details, ask ธาม to relay
- Commit work per phase with descriptive messages

---

## Contact

**Supervisor**: ธาม (tham-oracle)  
**Support**: Gemini (research context, analysis)  
**Repository**: `/root/ghq/github.com/E0993599799/tham-oracle` (main coordination)

---

**Status**: Awaiting Codex acceptance ✓
