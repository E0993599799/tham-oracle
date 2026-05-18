# Team Task Cards — Multi-Team Coordination

**Coordinator**: ธาม  
**Sprint**: Sprint 1 (Foundation Build)  
**Duration**: 2026-05-18 to 2026-05-25  
**Status**: 🚀 DISPATCHED

---

## Task 1: Codex — Dashboard MVP

**Status**: ✅ DETAILED PLAN READY  
**File**: `CODEX-DASHBOARD-TASK-DETAIL.md`  
**Deadline**: 2026-05-20 EOD  
**Deliverables**:
- StatusBadge component (reusable)
- FleetHealthSummary enhanced (visual bar + live indicator)
- useFleetStatus hook (real-time polling)
- OracleFleet.tsx updated (8 agent cards)

**Acceptance**: 0 TypeScript errors, npm build passing, 2 screenshots, git commits

**Next**: Day 3 starts second-wave components (Kanban, timeline, artifacts)

---

## Task 2: Planner — Phase 2 Runbook

**Assigned to**: Planner Oracle  
**Deadline**: 2026-05-24 EOD (draft by 2026-05-22)  
**Deliverables**:

### Phase 2 Runbook (Markdown Document)

**Contents**:
1. **Executive Summary** (1 page)
   - What is Phase 2?
   - Why after Phase 1?
   - Success criteria

2. **Single-Runtime Convergence Strategy** (2-3 pages)
   - Current: Multiple runtimes (Forge V2, Aegis, legacy gateway)
   - Target: Single canonical runtime
   - Path: Steps to consolidate without breaking Phase 1
   - Timeline: How many sessions?

3. **Vocabulary Mapping** (2 pages)
   - Legacy terms → canonical terms (examples)
   - Session → Run
   - Task → Task (unchanged)
   - Agent state → Agent status
   - Which code paths need updating

4. **Parallel/Async Execution Model** (3 pages)
   - Current: Sequential execution possible
   - Target: Parallel agent execution (multiple agents same run)
   - How: Dependency graph model
   - Example: 5 agents in parallel, wait for 3, cascade to others

5. **Graph Editing UI Sketch** (1 page + diagram)
   - User story: "Operator modifies agent graph at runtime"
   - Mockup: Left sidebar (agents), center (graph canvas), right (properties)
   - Actions: Add node, delete node, connect edges, update properties
   - Safety: Confirmation dialogs for destructive ops

6. **Sub-Agent Communication Protocol Spec** (2 pages)
   - Message format (JSON)
   - Request/response contract
   - Error codes + handling
   - Timeout behavior
   - Retry strategy

7. **Go/No-Go Criteria** (1 page)
   - Must-haves before Phase 2 start
   - Would-be-nice-but-not-blocking
   - Risk tolerance (what can we ship with?)
   - Approval gates (who signs off?)

### Phase 2 Implementation Checklist
- [ ] Runbook draft (50% by 2026-05-22)
- [ ] Full runbook (100% by 2026-05-24)
- [ ] Gemini review (UX/design perspective)
- [ ] ธาม review + approval
- [ ] Ready for team adoption

**Proof**: 
- Runbook markdown file + commit
- Review comments addressed
- Approval signature from ธาม

---

## Task 3: Historian — System Documentation Refresh

**Assigned to**: Historian Oracle  
**Deadline**: 2026-05-25 EOD (50% by 2026-05-22)  
**Deliverables**:

### 1. ARCHITECTURE.md — Complete Rewrite
- Current state (not idealized)
- All major components (who does what)
- Data flow diagrams
- Deployment diagram
- Technology stack with versions
- Known limitations/TODOs

**Sections**:
- System overview (500 words)
- Component architecture (with diagrams)
- Agent graph structure (with diagram)
- Orchestration flow (Aegis + Forge V2)
- Data persistence (SQLite schema)
- API landscape (endpoints + auth)
- Deployment architecture (local + cloud)
- Security model

### 2. Operator's Manual
- "How do I use Mission Control?" (for ops/users)
- Screenshots + step-by-step
- Common workflows (deploy, monitor, debug)
- Troubleshooting (first aid)
- Keyboard shortcuts / power-user tips

**Sections**:
- Getting started (5 min)
- Dashboard walkthrough (with screenshots)
- How to: Deploy task, view results, debug failure, check system health
- FAQ
- Contact for help

### 3. Developer Guide
- "How do I extend the system?" (for engineers)
- Architecture review (point to ARCHITECTURE.md)
- How to add new agent to graph
- How to extend Forge V2 with new stage
- How to add API endpoint
- Testing patterns
- Code style guide (links to existing configs)

**Sections**:
- System architecture (brief review)
- Development environment setup
- Adding new agent (step-by-step)
- Extending orchestrator (new stage type)
- Testing & validation
- Code quality (linting, type checking)
- PR review checklist

### 4. Troubleshooting Runbook
- Common errors + solutions
- Health check procedures
- Log analysis guide
- Performance profiling
- Recovery procedures

**Sections**:
- Dashboard won't load → check 9router, check Next.js dev server
- Agent not responding → check heartbeat, check logs, restart
- Task stuck in queue → check dependencies, check permissions
- Performance slow → check database, check network latency
- (More as discovered)

### 5. API Reference
- Auto-generated from code? Or manual?
- All HTTP endpoints (GET, POST, etc.)
- Request/response schemas
- Error codes + meanings
- Example curl commands

### 6. Training Guide (New Team Members)
- Onboarding checklist (30 min)
- Terminology glossary
- "5-minute overview" video script
- Lab: Deploy your first task (hands-on)
- Next steps: Deeper learning path

### Documentation Checklist
- [ ] ARCHITECTURE.md audit (identify stale sections) — by 2026-05-22
- [ ] ARCHITECTURE.md rewrite (100%) — by 2026-05-24
- [ ] Operator's manual skeleton (25%) — by 2026-05-22
- [ ] All docs (80%) — by 2026-05-25
- [ ] Review + final polish — by 2026-05-25 EOD

**Proof**:
- Git commits for each doc
- Review checklist (no stale info)
- Proof that examples work (screenshots)

---

## Task 4: Aegis — Protocol & Integration

**Assigned to**: Aegis Coordinator  
**Deadline**: 2026-05-25 EOD (spec by 2026-05-23)  
**Deliverables**:

### 1. Agent Communication Protocol Spec

**Document**:
- Protocol version: 1.0
- Overview (use cases, scope)
- Message format (JSON)
- Request/response contract (with examples)
- Error codes (400, 500, 503, etc.)
- Timeout behavior
- Retry strategy (exponential backoff)
- Health check / heartbeat format
- Security (auth, encryption if needed)

**Example Messages**:
```json
{
  "request": {
    "id": "uuid",
    "agent": "codex",
    "action": "execute_task",
    "payload": { ... },
    "timestamp": "2026-05-18T12:34:56Z"
  },
  "response": {
    "id": "uuid-same",
    "status": "success|error|timeout",
    "result": { ... },
    "error": { "code": 500, "message": "..." },
    "timestamp": "2026-05-18T12:34:57Z"
  }
}
```

### 2. Reference Implementations
- Implement protocol in 3+ agents (Codex, Router, Executor)
- Create example client + server
- Create integration tests

### 3. Integration Test Suite
- Agent can send + receive messages
- Error handling works (retry, timeout)
- Health checks pass
- Load test (100 concurrent messages)

### 4. Integration Catalog
- What's already integrated? (list)
- What's planned? (roadmap)
- Third-party integrations (APIs, webhooks)
- Compatibility matrix (which agents work with which services)

### Protocol Checklist
- [ ] Protocol spec outline — by 2026-05-21
- [ ] Full spec draft — by 2026-05-22
- [ ] Example implementations — by 2026-05-23
- [ ] Integration tests — by 2026-05-24
- [ ] All tests passing — by 2026-05-25 EOD

**Proof**:
- Protocol spec document (GitHub or .md)
- Example code + tests
- Test results (all passing)
- Integration catalog

---

## Daily Standup Format

**Every day at 16:00 UTC+7**, each team updates:

```markdown
## [TEAM] Status Update — 2026-05-18

### ✅ Completed Today
- Item 1 (commit hash)
- Item 2 (commit hash)

### 🔄 In Progress
- Item 1 (% complete, ETA)
- Item 2 (% complete, ETA)

### ❌ Blockers
- Blocker 1 (severity: LOW/MEDIUM/HIGH, assigned to: ธาม)
- Blocker 2 (severity: LOW/MEDIUM/HIGH, assigned to: ธาม)

### 📊 Metrics
- Lines of code added: XX
- TypeScript errors: 0
- Tests passing: XX/XX
- Confidence: 80% (or whatever %)

### 🎯 Tomorrow's Plan
- Task 1 (estimated XYZ hours)
- Task 2 (estimated XYZ hours)
```

---

## Weekly Review Format

**Every Monday at 10:00 UTC+7**, full proof submission:

```markdown
## [TEAM] Weekly Proof — Week of 2026-05-18

### Completed This Week
- [Deliverable 1] — commit hash, proof link
- [Deliverable 2] — commit hash, proof link
- [Deliverable 3] — commit hash, proof link

### Proof Artifacts
- [Code diff] (link)
- [Tests] (results)
- [Screenshots] (if applicable)
- [Documentation] (link)
- [Performance metrics] (if applicable)

### Risks Carried Over
- Risk 1 (status: RESOLVED / ONGOING, action: ???)

### Next Week Priorities
1. Task 1 (deliverable, deadline)
2. Task 2 (deliverable, deadline)
3. Task 3 (deliverable, deadline)
```

---

## Escalation Path

**If blocker happens**:
1. Team lead identifies blocker (LOW/MEDIUM/HIGH severity)
2. Same-day notification to ธาม (via Slack/Teams or thread)
3. ธาม responds within 4 hours
4. ธาม either:
   - Unblocks (removes dependency)
   - Revises scope (what can ship without this?)
   - Escalates to พี่เอก (if policy/resource decision)

**Example**:
- Codex: "TypeScript dep conflict, can't build"
- ธาม: "Check package-lock.json, rm node_modules && npm install fresh"
- If that fails: ธาม escalates to พี่เอก

---

## Success Criteria (Full Sprint)

By 2026-05-25 EOD:

| Team | Deliverable | Status |
|------|-------------|--------|
| Codex | Dashboard MVP (fleet health + agents) | ✅ Ready by 2026-05-20 |
| Planner | Phase 2 runbook (complete + approved) | ✅ Ready by 2026-05-24 |
| Historian | System docs (80%+ complete) | ✅ Ready by 2026-05-25 |
| Aegis | Protocol spec + tests | ✅ Ready by 2026-05-25 |

**Overall Sprint Success**: 4/4 teams at acceptable quality (ธาม approval) OR escalated with clear status.

---

**Coordinator**: ธาม  
**Authority**: Full decision-making for scope, timeline, quality  
**Reporting**: Daily standups + weekly proofs  
**Status**: 🟢 ACTIVE

**Teams**: Check your detailed task cards in proofs/2026-05-18/ and GET STARTED! 🚀
