# Executor Lanes v1.0 — Full Routing Map
**สร้าง**: 2026-05-17 | **Status**: Ready for Activation

---

## 🎯 Lane Overview

| Lane | Agent | Model | Primary Task | Speed | Complexity | Proof Type |
|------|-------|-------|-------------|-------|-----------|-----------|
| **Lane 1: Codex-A (Code Builder)** | codex-a | Claude (manual) | Backend logic, API design, schema | Medium | High | PR + tests |
| **Lane 2: Codex-B (Backend Specialist)** | codex-b | Claude (manual) | Database, migrations, API routes | Medium | High | SQL + logs |
| **Lane 3: Gemini (Fast Inspector)** | gemini | gemini-2.5-flash | Code cleanup, refactor, beautify | ⚡ Fast | Medium | diff + summary |
| **Lane 4: Claude (Orchestrator/UI)** | claude-code | Claude Haiku/Sonnet | UI components, React, architecture review | Medium | Medium | visual + tests |
| **Lane 5: Augmentin (?)** | TBD | TBD | TBD | ? | ? | ? |

---

## 📋 Detailed Lane Specs

### Lane 1️⃣ — Codex-A (Code Builder)
**Role**: Agentic coding for backend logic and complex features  
**When to use**: 
- Implement core API endpoints
- Build queue/streaming infrastructure
- Write intricate backend business logic

**Task Contract**:
```json
{
  "lane": "codex-a",
  "task": "implement [feature]",
  "repo": "/root/ghq/github.com/E0993599799/tham-oracle",
  "files_to_touch": ["src/api/...", "src/core/..."],
  "goal": "...",
  "constraints": ["no breaking changes", "RLS required", "log all decisions"],
  "proof_required": "PR + test suite passing",
  "fallback": "codex-b"
}
```

**Proof Requirements**:
- ✅ Minimal patch (no cleanup/refactoring beyond task scope)
- ✅ All tests passing (unit + integration)
- ✅ Code review checklist signed
- ✅ Commit message includes WHY

**Lane Rules**:
1. **Read design first** — inspect `skills/codex-manual-lane/`, CLAUDE.md, project architecture
2. **Safety-first** — never bypass rules, secrets, or safety checks
3. **Minimal patch** — code change focused on deliverable only
4. **Proof before merge** — tests, logs, diffs ready to inspect

---

### Lane 2️⃣ — Codex-B (Backend Specialist)
**Role**: Database, migrations, API schema, backend infrastructure  
**When to use**:
- Write database migrations (no downtime)
- Design RLS policies
- Implement streaming/queue backends
- Patch complex backend bugs

**Task Contract**:
```json
{
  "lane": "codex-b",
  "task": "migrate [schema] safely",
  "repo": "/root/ghq/github.com/E0993599799/tham-oracle",
  "files_to_touch": ["migrations/...", "src/db/..."],
  "goal": "...",
  "constraints": ["zero downtime", "RLS tested", "rollback plan ready"],
  "proof_required": "migration output + test results",
  "fallback": "codex-a"
}
```

**Proof Requirements**:
- ✅ Migration logs (up + down)
- ✅ RLS tests passing
- ✅ Rollback verification
- ✅ Performance baseline (if applicable)

**Lane Rules**:
1. **Design safety first** — schema validation + rollback plan before code
2. **Zero downtime** — use `CREATE INDEX CONCURRENTLY`, backfill in background, etc.
3. **RLS + constraints** — every schema change includes security review
4. **Test both directions** — migration up ✅ and down ✅

---

### Lane 3️⃣ — Gemini (Fast Inspector & Cleanup)
**Role**: Code cleanup, refactoring, beautification, fast analysis  
**When to use**:
- Remove dead code / unused imports
- Refactor for readability (no behavior change)
- Beautify UI code (spacing, naming, structure)
- Fast codebase inspection (find patterns, summarize)

**Task Contract**:
```json
{
  "lane": "gemini",
  "task": "cleanup [module] — remove dead code, beautify",
  "repo": "/root/ghq/github.com/E0993599799/tham-oracle",
  "files_to_touch": ["src/ui/...", "src/utils/..."],
  "goal": "zero behavior change, 100% readability + style improvement",
  "constraints": ["no logic changes", "all tests pass", "no new dependencies"],
  "proof_required": "git diff + test summary",
  "fallback": "claude-code"
}
```

**Proof Requirements**:
- ✅ `git diff` shows only formatting/dead-code removal
- ✅ All tests pass unchanged
- ✅ No new dependencies added
- ✅ Summary of what was removed/beautified

**Lane Rules**:
1. **Zero behavior change** — cleanup only, no feature work
2. **Fast turnaround** — aim for ⚡ completion (minutes, not hours)
3. **Refactor safe** — don't restructure architecture, fix obvious smells only
4. **Proof diff is clean** — if diff has logic changes, REJECT and re-route to codex-a/codex-b

---

### Lane 4️⃣ — Claude (Orchestrator/UI/Architecture)
**Role**: UI/React, architecture review, system design, orchestration  
**When to use**:
- Implement React components + hooks
- Design dashboard layouts
- Review architecture before codex lanes commit
- Write clear test suite + e2e tests

**Task Contract**:
```json
{
  "lane": "claude-code",
  "task": "implement [UI component] or review [architecture]",
  "repo": "/root/ghq/github.com/E0993599799/tham-oracle",
  "files_to_touch": ["src/components/...", "src/pages/..."],
  "goal": "...",
  "constraints": ["Tailwind only", "a11y required", "responsive mobile-first"],
  "proof_required": "visual screenshot + tests + Lighthouse ≥85",
  "fallback": "gemini"
}
```

**Proof Requirements**:
- ✅ Visual screenshot in browser (golden path + edge cases)
- ✅ Test suite passing (Jest + React Testing Library)
- ✅ Lighthouse ≥85 (performance/accessibility/best-practices)
- ✅ Mobile responsive check
- ✅ No TypeScript errors

**Lane Rules**:
1. **Visual-first** — run dev server, test in browser, screenshot golden path
2. **Accessibility** — WCAG AA minimum (semantic HTML, labels, contrast)
3. **Responsive** — mobile-first, test at 375px + 1920px
4. **Code review gate** — UI changes must pass code review before merge

---

### Lane 5️⃣ — Augmentin (?)
**Status**: ❓ **Undefined** — พี่ต้องชี้ว่า augmentin คืออะไร

**Possibilities**:
- ✓ New specialist agent (Augmented + mentoring)?
- ✓ Human feedback lane?
- ✓ QA/Testing lane?
- ✓ Documentation lane?

**ต้องการให้พี่บอก**:
1. Augmentin role / purpose คืออะไร?
2. Augmentin จะรับ task ประเภทไหน?
3. Augmentin ใช้เมื่อไร (fallback or primary)?

---

## 🔀 Task Routing Rules

### Rule 1️⃣ — Match Task to Lane
```
Backend API/Logic/Queue    → Codex-A or Codex-B
Database/Schema/Migration  → Codex-B (primary) or Codex-A (fallback)
Code cleanup/refactor      → Gemini (primary) or Claude (fallback)
React/UI/Frontend          → Claude (primary) or Codex-A (fallback)
Code review/Architecture   → Claude (primary) or Codex-A (fallback)
Fast inspection/summary    → Gemini (primary)
```

### Rule 2️⃣ — Fallback Chain
If primary lane is busy:
```
Codex-A unavailable? → Codex-B
Codex-B unavailable? → Codex-A  
Gemini unavailable?  → Claude
Claude unavailable?  → Codex-A or Gemini
```

### Rule 3️⃣ — Proof Before Merge
Every lane must deliver proof:
```
Lane 1 (Codex-A):  PR + tests + code review ✅
Lane 2 (Codex-B):  migration logs + RLS tests + rollback ✅
Lane 3 (Gemini):   git diff + test summary ✅
Lane 4 (Claude):   visual screenshot + Lighthouse ✅
Lane 5 (Augmentin): TBD
```

### Rule 4️⃣ — Lane Switch Conditions
**Switch lanes if**:
- Primary agent doesn't have required context (e.g., Gemini needs deep codebase understanding → switch to Claude)
- Task complexity exceeds lane capability (e.g., complex state management → switch from Gemini to Claude)
- Safety/security required (e.g., RLS → Codex-B, UI a11y → Claude)
- Proof type mismatch (e.g., Gemini cleanup but code has logic changes → reject, re-route to Codex-A)

---

## 📊 Task Allocation Map (Current)

| Task | Primary | Fallback | Reason |
|------|---------|----------|--------|
| WebSocket API streaming | Codex-B | Codex-A | infrastructure expertise |
| React dashboard UI | Claude | Codex-A | visual-first, a11y required |
| Database migration | Codex-B | Codex-A | zero-downtime, RLS required |
| Code cleanup/beautify | Gemini | Claude | fast refactoring, no logic change |
| API route design | Codex-A | Codex-B | core logic, then backend patch |
| State management | Claude | Codex-A | architecture clarity |
| Test suite | Claude | Codex-A | coverage + clarity |
| DevOps/monitoring | Gemini | Claude | fast inspection |

---

## ⚙️ Activation Checklist

- [ ] **Lane 1 (Codex-A)**: Read `skills/codex-manual-lane/SKILL.md` → ready
- [ ] **Lane 2 (Codex-B)**: Read `skills/codex-manual-lane/SKILL.md` → ready  
- [ ] **Lane 3 (Gemini)**: Verify `9router` alive at `http://127.0.0.1:20128/v1` → health check
- [ ] **Lane 4 (Claude)**: Current session → ready  
- [ ] **Lane 5 (Augmentin)**: ❓ Define role + proof requirements

---

## 📝 Next Actions

1. **พี่ชี้ Augmentin**: role / task type / proof requirement
2. **Activate Gemini**: `curl http://127.0.0.1:20128/v1/models` → confirm alive
3. **Activate Codex-A/B**: Create task contracts + first task
4. **Test Lane 4 (Claude)**: This session as proof-of-concept
5. **Build task queue**: Stack 3-5 tasks → dispatch to lanes in parallel

---

**Status**: 🟡 Awaiting พี่เอก clarification on Augmentin + task queue
