# Themion Rust Codebase — Deep Dive
## 2026-05-15

---

## 1. Core Data Structures

### Workflow State (workflow.rs)
```rust
pub struct WorkflowState {
    pub workflow_name: String,      // "NORMAL" | "LITE"
    pub phase_name: String,         // "IDLE", "EXECUTE", "CLARIFY", "VALIDATE"
    pub status: WorkflowStatus,     // Running, WaitingUser, Completed, Failed
    pub phase_result: PhaseResult,  // Pending, Passed, Failed, UserFeedbackRequired
    pub agent_name: String,
    pub retry_state: PhaseRetryState,
}

pub enum WorkflowStatus { Running, WaitingUser, Completed, Failed, Interrupted }
pub enum PhaseResult { Pending, Passed, Failed, UserFeedbackRequired }
```

### Agent Message Protocol (client.rs)
```rust
pub struct Message {
    pub role: String,               // "system", "user", "assistant", "tool"
    pub content: Option<String>,
    pub tool_calls: Option<Vec<ToolCall>>,
    pub tool_call_id: Option<String>,
}

pub struct ToolCall {
    pub id: String,
    pub function: FunctionCall,
}
```

### Session & Turn Tracking (db.rs)
```rust
pub struct TurnRecord {
    pub turn_id: i64,
    pub session_id: String,
    pub turn_seq: u32,
    pub meta_json: Option<String>,  // Compact {app_version, profile, provider, model}
    pub meta: Option<TurnMeta>,
}
```

### Board Notes (db.rs)
```rust
pub struct BoardNote {
    pub note_id: String,
    pub note_kind: String,          // "work_request"
    pub body: String,
    pub column_name: String,        // "todo", "in_progress", "blocked", "done"
    pub to_instance: String,
    pub to_agent_id: String,
    pub injection_state: String,    // "pending" | "injected"
    pub blocked_until_ms: Option<i64>,
}
```

---

## 2. Runtime Loop & Event Flow (agent.rs)

### Harness Loop Pattern
```
For each turn:
1. record turn boundary → open DB turn row
2. push user message → persist to agent_messages
3. build context (tokenizer-aware windowing, T-7 max age, 170K target)
4. stream chat_completion via ChatBackend
5. accumulate assistant response → emit AgentEvent::AssistantChunk
6. push assistant message → persist
7. if tool_calls exist:
   - emit ToolStart with raw + display-enriched args
   - call_tool(name, args, ToolCtx)
   - push tool result → persist
   - repeat from step 3
8. finalize turn with token stats → emit TurnDone
```

### Token Estimation
- Primary: `tiktoken_rs` with exact model mapping (o200k_base, cl100k_base, etc.)
- Fallback: Short trusted tokenizer mapping for aliases
- Degrade: Rough `chars / 4` estimator
- Budget: 170K target, 250K spike ceiling, never replay T-7+

### Context Assembly Order
```
[system_prompt]
[predefined coding guardrails]
[predefined Codex CLI web-search instruction]
[injected AGENTS.md]
[workflow context + phase instructions]
[recall hint if history omitted]
[budget-aware message replay]
```

---

## 3. Agent Communication & Coordination (tools.rs)

### Tool Execution Context
```rust
pub struct ToolCtx {
    pub db: Arc<DbHandle>,
    pub session_id: String,
    pub project_dir: PathBuf,
    pub workflow_state: WorkflowState,
    pub system_inspection: SystemInspection,
}
```

### Tool Categories
- **File I/O**: `fs_read_file`, `fs_write_file`, `fs_patch`, `fs_list_directory`
- **Shell**: `shell_run_command` (respects Unix `-lc` shell behavior)
- **History**: `history_recall` with `RecallDirection` (forward/backward)
- **Search**: `unified_search` (memory + chat + tools)
- **Memory**: `memory_node_*`, `memory_edge_*`, hashtag operations
- **Board**: `board_note_*` CRUD + injection + result update
- **Workflow**: `workflow_get_state`, `workflow_set` (phase/status/result mutations)
- **Agents**: `local_agent_create`, `local_agent_delete` (CLI-routed)

### Tool Result Schema
```rust
fn board_note_ack(note: &BoardNote, operation: &str) -> Value {
    json!({
        "ok": true,
        "entity": "board_note",
        "operation": operation,
        "note_id": note.note_id,
        "changed": {...}
    })
}
```

---

## 4. Task Queue & Board System (db.rs)

### SQLite Schema
```sql
CREATE TABLE agent_sessions (
    session_id TEXT PRIMARY KEY,
    project_dir TEXT,
    current_workflow, current_phase, workflow_status,
    current_phase_result, current_agent,
    workflow_last_updated_turn_seq
);

CREATE TABLE board_notes (
    note_id TEXT PRIMARY KEY,
    to_instance TEXT, to_agent_id TEXT,
    column_name TEXT,      -- "todo", "in_progress", "blocked", "done"
    injection_state TEXT,  -- "pending" | "injected"
    blocked_until_ms INTEGER,
    body TEXT, result_text TEXT
);

CREATE VIRTUAL TABLE agent_messages_fts USING fts5(content);
```

### Board Note Lifecycle
- Created in `todo` column with `injection_state="pending"`
- Injected into agent's context when ready
- Transitions via `workflow_set` calls (column moves)
- Result persisted on completion
- FTS5 indexing for semantic search

---

## 5. Concurrency Model (architecture.md)

### Tokio Runtime Domains
| Domain | Workers | Purpose |
|--------|---------|---------|
| `tui` | 1 | TUI event intake, tick scheduling, frame refresh |
| `core` | multi | Agent turns, harness orchestration, startup |
| `network` | multi | Stylos publisher, query handlers, broker |
| `background` | multi | Pending embedding, semantic reindex, maintenance |

### Channel Patterns
- `mpsc::unbounded` for command submission (hub → agents)
- `tokio::sync::watch` for runtime-owned snapshot broadcast
- `broadcast` for lossy event notifications
- Per-agent queued prompts (FIFO drain on idle)

### Per-Agent Busy Tracking
```rust
// Agent execution is per-agent, not global lock
if agent.is_idle() {
    start_turn(agent)
} else {
    queue_prompt_on_agent(agent, prompt)
}
```

---

## 6. Web Runtime (themion-web/src/)

### Agent Runtime Service
```rust
pub struct AgentRuntimeService {
    request_tx: mpsc::UnboundedSender<AgentRuntimeRequest>,
}

enum AgentRuntimeRequest {
    Snapshot { response_tx: oneshot::Sender<AgentRosterSnapshot> },
    SubmitPrompt { agent_id, prompt, response_tx },
    Subscribe { agent_id, response_tx: Receiver<AgentRuntimeEvent> },
    CreateAgent { label, roles, response_tx },
    DeleteAgent { agent_id, response_tx },
}

pub enum AgentRuntimeEvent {
    Snapshot(AgentSnapshot),
    RosterUpdated(AgentRosterSnapshot),
    Busy { agent_id, busy: bool },
    TranscriptDelta(TranscriptDelta),
    Completed { agent_id },
    Failed { agent_id, message },
}
```

### WebSocket Integration
- Per-agent subscription channels
- Event-driven transcript delta streaming
- Roster mutations broadcast to all subscribers
- Reconnect-safe snapshot-on-subscribe pattern

---

## 7. Key Patterns & Guarantees

### Ownership Boundaries
```
TUI / HEADLESS (render only)
    ↓
HUB / APP_STATE (runtime decisions, scheduling)
    ↓
AGENT CORE + STYLOS (execution engines)
```
- TUI does not own roster, workflow truth, watchdog policy
- Hub/AppState owns admission, scheduling, board coordination
- Core owns harness loop, prompt assembly, tool dispatch

### Budget-Aware Context
- Full in-memory history in `Vec<Message>` never trimmed
- Replay uses tokenizer-backed estimation
- Omit turns T-8 and older
- Degrade T-1..T-5 to assistant-only when T0 > 170K
- Stop adding turns if ceiling 250K exceeded

### Workflow State Machine
```
NORMAL:  IDLE ←→ EXECUTE
LITE:    CLARIFY → EXECUTE → VALIDATE (with backtrack)
         Max retries: current=3, previous=3
```

### Prompt Injection Order
System → Guardrails → Codex-Search → AGENTS.md → Workflow → Recall → History

---

## 8. File Organization

| Path | Purpose |
|------|---------|
| `crates/themion-core/src/agent.rs` | Harness loop, context assembly, streaming |
| `crates/themion-core/src/client.rs` | ChatBackend trait, streaming protocol |
| `crates/themion-core/src/client_codex.rs` | Codex Responses API integration |
| `crates/themion-core/src/tools.rs` | Tool definitions, execution, result formatting |
| `crates/themion-core/src/db.rs` | SQLite schema, session/turn/message CRUD, FTS5 |
| `crates/themion-core/src/workflow.rs` | State machine, phase transitions, retry logic |
| `crates/themion-cli/src/app_state.rs` | Bootstrap, shared runtime ownership |
| `crates/themion-cli/src/tui.rs` | Ratatui rendering, event routing only |
| `crates/themion-web/src/agent_runtime.rs` | Web API surface, multiplexing |
| `docs/architecture.md` | System design, ownership, thread model |
| `docs/engine-runtime.md` | Harness loop, token budgeting, workflow semantics |
| `AGENTS.md` | Repo rules, tool design, validation checklist |

---

## Summary

Themion is a **local-first async agent runtime** with:
- **Async-task based concurrency** (mpsc + watch channels) across 4 Tokio domains
- **Stateful conversation** with **budget-aware context replay** (170K target, 250K spike)
- **OpenAI-compatible tool calling** with **structured result formatting**
- **SQLite-persisted history** with FTS5 full-text and semantic indexing
- **Multi-agent coordination** via board notes + workflow state + per-agent queuing
- **Ownership-first architecture** separating TUI (render), Hub (schedule), Core (execute)
- **Provider abstraction** through ChatBackend trait + Codex-specific Responses API handler
- **Strict separation** of kernel logic (core) from CLI concerns (file I/O, TUI, auth)

Max ~500 words covered: data structures, harness loop, communication, task queue, concurrency, web service, patterns, file map.
