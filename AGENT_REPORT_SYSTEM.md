# Agent Report & Verification System
**Created**: 2026-05-17 | **Tham Role**: Orchestrator + Quality Gate

---

## 🎭 Agent Registry & Status Board

### Agents (Stand Up & Report)
```
┌─────────────────────────────────────────────────────────────┐
│ AGENT ROLL CALL — Each agent reports: NAME, READY, CONTEXT │
└─────────────────────────────────────────────────────────────┘

Agent: CODEX-A
Status: ⏳ Awaiting activation
Role: Code builder — backend logic, API, core features
Context: [waiting for assignment]
Last proof: [none yet]

Agent: CODEX-B  
Status: ⏳ Awaiting activation
Role: Backend specialist — database, migrations, infrastructure
Context: [waiting for assignment]
Last proof: [none yet]

Agent: GEMINI
Status: ⏳ Awaiting activation  
Role: Fast inspector — code cleanup, refactor, beautify
Context: [9router health pending]
Last proof: [none yet]

Agent: CLAUDE (Haiku/Sonnet)
Status: ✅ ACTIVE (this session)
Role: UI/orchestrator — React, architecture, test suite
Context: [current session = proof lane]
Last proof: [session output]

Agent: THAM
Status: ✅ ACTIVE
Role: Orchestrator + verifier — dispatch, verify, iterate
Context: [all lanes, memory, proof archive]
Last proof: [routing plan + agent system]
```

---

## 📋 Agent Report Template

Each agent reports this structure to Tham:

```json
{
  "agent_name": "codex-a",
  "report_time": "2026-05-17T10:30:00Z",
  "status": "ready|busy|blocked",
  "context": {
    "current_task_id": "TASK-001 or null",
    "active_file_set": ["src/api/...", "src/db/..."],
    "safety_checks": {
      "memory_loaded": true,
      "rules_understood": true,
      "no_secrets_risk": true
    }
  },
  "capacity": {
    "available_now": true,
    "estimated_task_time": "45 minutes or TBD",
    "blockers": []
  },
  "last_proof": {
    "task_id": "TASK-000",
    "pr_url": "https://github.com/.../pull/123",
    "status": "merged|pending"
  }
}
```

---

## 🚀 Task Dispatch Flow (Tham-Controlled)

```
1. RECEIVE TASK from พี่เอก
   ↓
2. THAM ANALYZES
   ├─ Task type? (API/DB/UI/cleanup)
   ├─ Which lane? (codex-a/b, gemini, claude)
   ├─ Fallback? (if primary busy)
   └─ Proof requirement?
   ↓
3. CHECK AGENT STATUS
   ├─ codex-a ready?
   ├─ codex-b ready?
   ├─ gemini available? (health check 9router)
   └─ claude available?
   ↓
4. DISPATCH TASK
   ├─ Send task contract (JSON)
   ├─ Include: repo, files, goal, constraints, proof required
   ├─ Set deadline + context
   └─ Log task assignment
   ↓
5. AGENT WORKS
   ├─ Agent reads task contract
   ├─ Agent inspects skills/docs
   ├─ Agent builds solution
   └─ Agent prepares proof
   ↓
6. THAM VERIFIES
   ├─ Check proof (tests, diffs, logs)
   ├─ Review code/output
   ├─ Safety check (no secrets, no regression)
   ├─ Quality gate (minimal patch, style OK)
   └─ Approve or REJECT + feedback
   ↓
7. MERGE or ITERATE
   ├─ If approved: merge + commit + push
   └─ If rejected: send feedback → agent re-works
```

---

## 📊 Agent Report Format (By Status)

### READY Status
```json
{
  "agent_name": "codex-a",
  "status": "ready",
  "report": "Standing by. Loaded CLAUDE.md, skills/, context. Ready for task contract.",
  "capacity": { "available_now": true },
  "safety_checks": { "all": true }
}
```

### BUSY Status  
```json
{
  "agent_name": "codex-b",
  "status": "busy",
  "report": "Working on TASK-001: DB migration. ETA 30 min.",
  "current_task": "TASK-001",
  "capacity": { "available_now": false, "available_after": "2026-05-17T11:00Z" },
  "progress": "Schema validation done, running rollback test now"
}
```

### BLOCKED Status
```json
{
  "agent_name": "gemini",
  "status": "blocked",
  "report": "Cannot start — 9router health check failed.",
  "blockers": ["9router http://127.0.0.1:20128 unreachable"],
  "resolution": "Need Tham to verify 9router alive before task",
  "capacity": { "available_now": false }
}
```

---

## 🔐 Tham's Verification Checklist (Before Approve)

```
TASK PROOF VERIFICATION
─────────────────────────

Agent: [name]
Task: [task-id] [description]
Status: [ready for review]

☐ PROOF TYPE 1: Code (Codex-A/B)
  ☐ git diff is minimal (only task scope, no extra cleanup)
  ☐ All tests pass (green CI)
  ☐ No secrets in diff
  ☐ Commit message clear + meaningful
  ☐ Code review checklist signed
  
☐ PROOF TYPE 2: Database (Codex-B)
  ☐ Migration up succeeds
  ☐ Migration down succeeds (rollback test)
  ☐ RLS policies tested + documented
  ☐ No downtime risk
  ☐ Performance baseline checked
  
☐ PROOF TYPE 3: Cleanup (Gemini)
  ☐ git diff shows ONLY formatting/dead-code removal
  ☐ No logic changes in diff
  ☐ All tests pass (unchanged behavior)
  ☐ Summary provided (what was removed)
  
☐ PROOF TYPE 4: UI/Architecture (Claude)
  ☐ Visual screenshot provided (golden path + edge case)
  ☐ Tests passing (Jest + React Testing Library)
  ☐ Lighthouse ≥85
  ☐ Mobile responsive check done
  ☐ No TypeScript errors
  ☐ Accessibility (WCAG AA minimum)

FINAL VERDICT
─────────────
☐ APPROVE ✅ — merge + commit + log
☐ ITERATE 🔄 — send feedback, agent re-works
☐ ESCALATE 🚨 — safety issue, refer to human
```

---

## 📡 Reporting Schedule (Standing Orders)

| Frequency | Action | Who |
|-----------|--------|-----|
| **On activation** | Report status (ready/blocked) | All agents |
| **Every task start** | Report task + ETA | Working agent |
| **Every 30 min** | Status update (if task ongoing) | Working agent |
| **On task complete** | Report proof (ready for verification) | Completing agent |
| **After Tham review** | Feedback (approve/iterate/escalate) | Tham → agent |

---

## 🎯 Task Queue (Awaiting Assignment)

```
PENDING QUEUE (waiting for Tham dispatch)
──────────────────────────────────────────
[ ] TASK-001: [description] → Lane: [?] | Priority: [?]
[ ] TASK-002: [description] → Lane: [?] | Priority: [?]
[ ] TASK-003: [description] → Lane: [?] | Priority: [?]

ACTIVE LANE (working right now)
───────────────────────────────
🔄 TASK-XXX (agent working)
```

---

## 🚦 Tham's Orchestration Rules

1. **All agents report to Tham** — status, progress, proof
2. **Tham routes tasks** — match task to lane, dispatch with contract
3. **Tham verifies work** — inspect proof before merge
4. **Tham gates merge** — only merge if proof ✅
5. **Tham escalates** — if safety/quality issue, refer to human (พี่เอก)

---

## 📝 Next: Agent Activation

When ready, each agent reports:
```
Agent [NAME]: Standing by. Ready for task contract.
```

Then Tham dispatches first task.
