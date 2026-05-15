# Load Balance Architecture — Forge/Omega Multi-Agent System
**Date**: 2026-05-15 | **Status**: ACTIONABLE PLAN

---

## 1. Load Balancing Strategies

### Capability Matrix (route by task type, not round-robin)

| Task Type | Primary | Fallback 1 | Fallback 2 |
|---|---|---|---|
| Planning / Spec | Codex-A (Planner) | Claude Sonnet | Gemini |
| Code generation | Codex-B (Coder) | Claude Sonnet | — |
| Research / Synthesis | Gemini Brain | Claude Sonnet | — |
| PowerShell / SFSR | Claude Sonnet | Codex-B | — |
| Local/fast inference | OpenClaw (Ollama) | Hermes | — |
| Proof / Gate | Claude Sonnet (Omega role) | — | — |

Round-robin is wrong for agents with different capabilities. Use **capability-first routing**: match task tags → agent capability table → check health score → assign.

### Task Complexity Scoring

```typescript
// lib/task-scorer.ts
type Complexity = 'light' | 'medium' | 'heavy'

function scoreTask(task: QueueTask): Complexity {
  const heavyTags = ['scaffold', 'architect', 'refactor', 'migration']
  const lightTags  = ['probe', 'health', 'status', 'summarize']
  if (heavyTags.some(t => task.title.toLowerCase().includes(t))) return 'heavy'
  if (lightTags.some(t => task.title.toLowerCase().includes(t))) return 'light'
  return 'medium'
}
// Route: heavy → Claude/Codex-B, medium → Codex-A, light → OpenClaw
```

### Failure Fallback Chain

```
Codex-B (coder) → FAIL → Claude Sonnet → FAIL → Gemini → DEAD_LETTER
Codex-A (planner) → FAIL → Claude Sonnet → DEAD_LETTER
OpenClaw → FAIL → Hermes → FAIL → Claude Sonnet
```

Each fallback adds a `fallback_count` field to the task. If `fallback_count >= 3` → move to `failed` column, alert.

---

## 2. Queue Architecture

### Priority Levels

```typescript
// Add to ForgeQueue.tsx QueueTask interface
interface QueueTask {
  id: string
  title: string
  lane: string
  status: TaskStatus
  ts: string
  priority: 'urgent' | 'normal' | 'background'  // ADD
  agent?: string        // assigned agent id       // ADD
  complexity?: Complexity                           // ADD
  fallback_count?: number                           // ADD
  claimed_at?: string   // ISO — prevent double-assign // ADD
}
```

Sort order in each column: `urgent` → `normal` → `background`. Display urgent in amber.

### Agent Health Scoring

```typescript
// lib/agent-health.ts
interface AgentHealth {
  id: string       // 'codex-a' | 'codex-b' | 'claude' | 'gemini' | 'openclaw'
  score: number    // 0-100
  status: 'online' | 'standby' | 'offline'
  active_tasks: number
  last_ping: string
  rate_limit_until?: string  // ISO — skip if set and future
}

// Health score formula:
// base 100 - (active_tasks * 20) - (rate_limited ? 100 : 0)
// standby if score < 40, offline if score < 10
```

Update loop: `GET /api/agents/health` every 15s, written to `/tmp/forge-agent-health.json` (file-based, always available).

### Task Claiming (no double-assignment)

```typescript
// app/api/queue/claim/route.ts
// POST { task_id, agent_id }
// 1. Read task from queue file
// 2. If task.claimed_at exists → 409 Conflict
// 3. Set task.claimed_at = now, task.agent = agent_id, task.status = 'assigned'
// 4. Write back atomically (rename temp file)
// 5. Return 200 OK
```

File-based queue uses atomic rename (`writeFileSync` to `.tmp` then `renameSync`) — safe in single-process WSL.

### Backpressure Handling

When all agents are at `score < 40`:
- Stop accepting new `normal` + `background` tasks (return 503 with `retry_after: 30`)
- `urgent` tasks still enqueue but wait
- Dashboard shows "BACKPRESSURE" badge in LaneRouter header

---

## 3. Codex 2-Account Strategy

### Role Split

| Account | Role | Task Types | tmux pane |
|---|---|---|---|
| Codex-A | Planner | Spec, architecture, task decomposition, review | `codex-swarm` pane 0 |
| Codex-B | Coder | Implementation, scaffold, file writes, tests | `codex-swarm` pane 1 |

### Account Rotation to Avoid Rate Limits

```typescript
// lib/codex-router.ts
const CODEX_ACCOUNTS = [
  { id: 'codex-a', role: 'planner', token_env: 'CODEX_TOKEN_A', window_tokens: 0, window_start: 0 },
  { id: 'codex-b', role: 'coder',   token_env: 'CODEX_TOKEN_B', window_tokens: 0, window_start: 0 },
]
const TOKEN_WINDOW_MS = 60_000
const TOKEN_LIMIT     = 80_000  // conservative under 100k/min

function pickCodexAccount(role: 'planner' | 'coder', estimated_tokens: number) {
  const acc = CODEX_ACCOUNTS.find(a => a.role === role)!
  const now = Date.now()
  if (now - acc.window_start > TOKEN_WINDOW_MS) { acc.window_tokens = 0; acc.window_start = now }
  if (acc.window_tokens + estimated_tokens > TOKEN_LIMIT) return null  // rate limited
  acc.window_tokens += estimated_tokens
  return acc
}
```

### Planner → Coder Handoff Protocol

```
Codex-A produces: PLAN.md with sections:
  - GOAL / SCOPE / FILES_TO_CHANGE / STEPS[] / ACCEPTANCE_CRITERIA

Handoff trigger: task moves to status 'review' in queue
LaneRouter assigns to Codex-B with PLAN.md attached as context prefix

Codex-B outputs: PR diff + PROOF.md
Task moves to 'done' when PROOF.md exists and acceptance criteria checked
```

---

## 4. Implementation Plan

### ForgeQueue.tsx — Load-Aware Display

Add to each task card:
```tsx
// Priority badge: urgent=amber, normal=default, background=dim
<span className={priority === 'urgent' ? 'text-amber-400' : 'text-white/20'}>
  {priority === 'urgent' ? '🔥' : priority === 'background' ? '🌙' : ''}
</span>
// Agent badge when assigned
{task.agent && <span className="text-xs font-mono text-purple-300">{task.agent}</span>}
```

Add `assigned` column between `inbox` and `in-progress` (6-col grid).

### LaneRouter.tsx — Smart Routing Display

Replace static `LANE_STATUS` with live fetch:
```tsx
const [health, setHealth] = useState<Record<string, AgentHealth>>({})
useEffect(() => {
  const poll = () => fetch('/api/agents/health').then(r => r.json()).then(setHealth)
  poll(); const id = setInterval(poll, 15_000); return () => clearInterval(id)
}, [])
```

Add `active_tasks` count and `score` bar to each lane row.

### New API Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/agents/health` | GET | Return health scores for all agents |
| `/api/queue/claim` | POST | Atomic task claiming |
| `/api/queue/tasks` | GET/POST | Read/write task queue |
| `/api/queue/complete` | POST | Mark done with proof |

### Health Score Update Loop

Run as Next.js route handler with `export const revalidate = 15` — pings tmux pane via `tmux capture-pane` to detect agent liveness. Writes result to `/tmp/forge-agent-health.json`. LaneRouter reads from `/api/agents/health` which proxies the file.

---

## Next Actions

1. Add `AgentHealth` type + `/api/agents/health` route — 30 min
2. Update `QueueTask` interface + `ForgeQueue.tsx` with priority/agent columns — 20 min
3. Wire `LaneRouter.tsx` to live health poll — 15 min
4. Implement file-based queue with atomic claim — 1 hr
5. Add Codex 2-account token window tracker — 30 min
6. Define PLAN.md handoff schema and wire planner→coder — 45 min

**Total estimated**: ~3.5 hrs for full implementation
