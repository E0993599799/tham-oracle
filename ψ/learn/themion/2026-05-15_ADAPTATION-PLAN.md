# Themion Adaptation Plan for Forge/Omega

## What Themion Does

Themion is a Rust-based terminal AI agent runtime that bundles a complete local execution engine—prompt assembly, tool calling, history management, and workflow orchestration—into a single process with TUI/headless/browser interfaces. It combines multi-backend support (Codex, OpenRouter, local llama.cpp), persistent SQLite history with semantic search, a project-scoped knowledge graph (Project Memory), local multi-agent coordination via board notes and queued prompts, and optional mesh visibility through Stylos (for discovery and peer messaging without moving execution out-of-process). The core philosophy: keep the agent runtime local, keep business logic in runtime not transport, and separate provider integration from CLI/UI concerns.

Themion is tightly designed for terminal-first workflows with streaming token output, keyboard shortcuts (`!command`), persistent session profiles, and direct shell integration. Its architecture treats TUI as a strict I/O surface, runtime/workflow state as non-TUI-owned, and tools as first-class contract-driven callables that shape how the agent interacts with the workspace.

## 5 Key Patterns Worth Adapting to Forge/Omega

### 1. Strict Separation: Provider Abstraction via `ChatBackend` Trait

**Themion pattern**: All model calls route through a single `ChatBackend` trait with async streaming:
```rust
#[async_trait]
pub trait ChatBackend {
    async fn chat_completion_stream(
        &self, model: &str, messages: Vec<Message>, tools: Option<Vec<ToolSchema>>,
        on_chunk: impl Fn(String), on_status: impl Fn(Status)
    ) -> Result<(ResponseMessage, Usage)>;
}
```

**TypeScript equivalent for Forge/Omega**:
```typescript
interface ChatBackend {
  chatCompletionStream(
    model: string, messages: Message[], tools: ToolSchema[] | null,
    onChunk: (text: string) => Promise<void>,
    onStatus: (status: Status) => Promise<void>
  ): Promise<{ message: ResponseMessage; usage: Usage }>;
}

class AnthropicBackend implements ChatBackend { ... }
class OpenAIBackend implements ChatBackend { ... }
class OllamaBackend implements ChatBackend { ... }
```

**Forge/Omega impact**: Replace hardcoded Anthropic SDK calls in `ForgeQueue` or `LaneRouter` with a pluggable backend. This lets you swap models/providers at runtime without touching orchestration logic.

---

### 2. Windowed Budget-Aware Context Replay (Not Fixed-Turn Windows)

**Themion pattern**: Prompt assembly uses token estimation (tiktoken or fallback) to build context dynamically:
- Always include the current turn (T0) first
- Never replay turns older than T-7
- Degrade T-1 through T-5 into pure-message replay if T0 alone exceeds 170K tokens
- Omit prior turns if T0 alone exceeds 250K spike ceiling
- Fallback: `chars / 4` estimator when no tokenizer is available

**TypeScript equivalent**:
```typescript
interface PromptContext {
  currentTurn: Message[];
  replayTurns: Message[][];  // T-1 to T-7, filtered by budget
  estimationMode: "tiktoken" | "fallback" | "rough";
  totalEstimatedTokens: number;
}

function buildContextWithBudget(
  allTurns: Message[][], model: string, maxTokens: number
): PromptContext {
  const currentTokens = estimateTokens(allTurns[0], model);
  if (currentTokens > 250000) return { currentTurn: allTurns[0], replayTurns: [], ... };
  
  const toReplay = [];
  for (let i = 1; i <= 7 && i < allTurns.length; i++) {
    const est = estimateTokens(allTurns[i], model);
    if (currentTokens + est > maxTokens) break;
    toReplay.push(allTurns[i]);
  }
  return { currentTurn: allTurns[0], replayTurns: toReplay, ... };
}
```

**Forge/Omega impact**: Replace `ForgeQueue`'s naive last-N-turns slice with budget-aware replay. This saves token cost, preserves critical recent context, and makes LLM calls more predictable.

---

### 3. Tool Definition as First-Class Contracts (Not Ad Hoc)

**Themion pattern**: Tools are defined once as JSON schemas (OpenAI format) and reused everywhere:
```rust
fn tool_definitions() -> Vec<ToolSchema> {
    json!([
        { "name": "fs_read_file", "parameters": { "type": "object", "properties": { "path": { "type": "string" } } } },
        { "name": "shell_run_command", "parameters": { ... } },
        // ... more tools
    ])
}

async fn call_tool(name: &str, args: serde_json::Value, ctx: &ToolCtx) -> String {
    match name {
        "fs_read_file" => { ... },
        "shell_run_command" => { ... },
        // ... dispatch
    }
}
```

**TypeScript equivalent**:
```typescript
const TOOL_DEFINITIONS = [
  {
    name: "readFile",
    description: "Read file contents",
    inputSchema: { type: "object", properties: { path: { type: "string" } } }
  },
  {
    name: "runCommand",
    description: "Execute shell command",
    inputSchema: { type: "object", properties: { command: { type: "string" } } }
  }
];

type ToolCallHandler = (name: string, args: Record<string, any>) => Promise<string>;

const toolHandlers: Record<string, ToolCallHandler> = {
  readFile: async (args) => { ... },
  runCommand: async (args) => { ... }
};
```

**Forge/Omega impact**: Standardize how `Executor`, `LaneRouter`, and agents define tools. This makes tool metadata queryable, prevents duplicate definitions, and enables agent discovery of what they can call.

---

### 4. Stateful Local Workflow + Board Notes for Durable Delegation

**Themion pattern**: Agents track work in three durability tiers:
- **Self-notes**: Short volatile memos for the current agent
- **Board notes**: Four-column durable notes (`todo`, `in_progress`, `blocked`, `done`) for delegated/scheduled work
- **Workflow state**: Explicit phase/status machine for long-running tasks

```rust
pub struct WorkflowState {
    pub status: String,  // "idle", "active", "paused"
    pub phase: String,   // task-specific: "setup", "build", "test", etc.
    pub phase_result: Option<String>,
}

async fn workflow_set(state: WorkflowState) -> Result<()> { ... }

async fn board_append(column: BoardColumn, note: String) -> Result<()> { ... }
```

**TypeScript equivalent**:
```typescript
interface WorkflowState {
  status: "idle" | "active" | "paused" | "complete" | "error";
  phase?: string;  // e.g., "compile", "test", "deploy"
  phaseResult?: string;
}

interface BoardNote {
  id: string;
  column: "todo" | "in_progress" | "blocked" | "done";
  text: string;
  createdAt: Date;
  agentId?: string;
}

async function workflowSet(state: Partial<WorkflowState>): Promise<void> { ... }
async function boardAppend(column: BoardNote["column"], text: string): Promise<BoardNote> { ... }
```

**Forge/Omega impact**: Replace ad hoc task tracking in `ForgeQueue` with explicit board+workflow. This makes long-running tasks auditable, enables agent handoff with clear outcomes, and helps detect stalled work.

---

### 5. Multi-Agent Coordination Without Scheduler Out-of-Process

**Themion pattern**: Local agents within one process coordinate via:
- Queued incoming prompts (FIFO per agent when busy)
- Board notes + "done mentions" for completion signals
- Direct `local_agent_create` / `local_agent_delete` tool calls (CLI-owned roster)
- No distributed scheduler; agent decides when to drain its prompt queue

```rust
async fn local_agent_create(label: &str, roles: Vec<String>) -> Result<AgentHandle> { ... }
async fn local_agent_delete(agent_id: &str) -> Result<()> { ... }

async fn incoming_prompt(target_agent_id: &str, prompt: String) -> Result<()> {
    // Agent's local queue; drained on next continuation
}
```

**TypeScript equivalent**:
```typescript
async function createLocalAgent(options: {
  label: string;
  roles: string[];  // e.g., ["executor", "reviewer", "watchdog"]
}): Promise<AgentHandle> { ... }

async function deleteLocalAgent(agentId: string): Promise<void> { ... }

async function queuePrompt(targetAgentId: string, prompt: string): Promise<void> {
  // Stores in process-local queue; target agent drains on next turn
}

interface AgentHandle {
  agentId: string;
  label: string;
  roles: string[];
}
```

**Forge/Omega impact**: Extend `Executor` and `LaneRouter` to support co-resident agents with stable identities. Replace message passing between separate processes with in-process queues when agents share lifecycle. This enables tighter coordination, simpler debugging, and clearer outcome tracking.

---

## Concrete Forge/Omega Component Modifications

| Component | Themion Pattern | Forge/Omega Change |
|---|---|---|
| **ForgeQueue** | Agent loop with FIFO history + streaming | Add `ChatBackend` trait interface; swap hard-coded Anthropic SDK |
| **LaneRouter** | Budget-aware context replay | Replace last-N-turns with tokenizer-backed windowed context |
| **Tool system** | Centralized `tool_definitions()` + dispatch | Merge scattered tool definitions into `TOOL_REGISTRY` with OpenAI schema format |
| **Task tracking** | Workflow state machine + board notes | Add `WorkflowBoard` and `WorkflowState` to `ExecutorContext` |
| **Multi-agent** | Local roster + FIFO prompt queue per agent | Extend `ExecutorHandle` to support role-based agents; add process-local queue |

---

## Copy & Adapt Checklist

### Literally Port (Minimal Changes)
- [ ] JSON schema format for tools (already OpenAI-compatible, just extract and reuse)
- [ ] Board note four-column model (`todo`, `in_progress`, `blocked`, `done`)
- [ ] Workflow state patch syntax (activation, phase change, terminal status)
- [ ] Predefined guardrail set for answer shaping (see `predefined_guardrails.rs`)

### Re-Implement (Language + Architecture)
- [ ] `ChatBackend` trait → TypeScript interface + factory pattern
- [ ] Token estimation path → use `js-tiktoken` or OpenAI token counter
- [ ] SQLite history + semantic search → check if Forge/Omega already has DB; adapt or keep separate
- [ ] TUI event-driven render → already websocket-driven in Forge/Omega; align snapshot model
- [ ] Stylos mesh → evaluate; may already have LLM-router equivalents

### Study for Pattern
- [ ] "Budget-aware replay never older than T-7" → inform `LaneRouter` context assembly
- [ ] "Separate system prompt + guardrails + contextual AGENTS.md" → clarify Forge/Omega prompt layering
- [ ] "TUI is strict I/O, runtime is non-TUI-owned" → validate Forge/Omega executor/dashboard separation
- [ ] "Role-context injection" → check if executor already receives role/capability hints

---

**Max token cost**: Adapt budget-aware context, tool definitions, and board notes. Leave Stylos mesh and semantic search as deferred (already have router).
