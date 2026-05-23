# Omega Tech Landscape — May 2026

> Research brief for the Omega self-hosted multi-oracle AI orchestration system.
> Stack: TypeScript · Node.js · Supabase · Claude Sonnet 4.x · Groq Llama · Gemini 2.x · Ollama (WSL2/Windows)
> Compiled: 2026-05-24 | Knowledge base: Aug 2025 + public roadmap projections

---

## Claude API Updates

**claude-sonnet-4-6** is a mid-cycle release between Sonnet 4.5 and any future Opus 5. Key capabilities relevant to Omega:

- **Extended Thinking** (`thinking` parameter, `budget_tokens` up to 32 k): enables multi-step internal reasoning before tool calls. Ideal for Omega's Planner and Reviewer agents where deliberation quality matters more than latency.
- **Tool use improvements**: parallel tool calls in a single turn (multiple `tool_use` blocks), `disable_parallel_tool_use` flag for strict sequencing. Significantly reduces round-trip count in multi-step agentic loops.
- **200 k context window** (Sonnet 4.x) — full thread history can be kept in-context for medium-length sessions without external retrieval.
- **Prompt caching** (`cache_control: ephemeral`): cache system prompts and large reference packs; cached tokens re-billed at ~10% of input price. Critical for Omega's ORCHESTRATOR_PROMPT.md which is injected every turn.
- **`claude-opus-4`**: available for tasks requiring highest reasoning (architecture design, complex debugging). Significantly more expensive — use selectively via Omega's task router.
- **Files API / vision**: pass PDFs, images, docs directly; avoids manual text extraction pipelines.
- **Streaming tool results**: stream partial tool output back to model mid-execution — useful for long-running Bash/code tools in agent loops.

**Action for Omega**: Enable prompt caching on all ORCHESTRATOR_PROMPT injections. Route planning/review tasks to extended thinking; route execution tasks to standard Sonnet 4.6.

---

## Groq Updates

Groq's LPU (Language Processing Unit) architecture remains the fastest publicly available inference as of mid-2026.

- **Llama 3.3 70B** (`llama-3.3-70b-versatile`): Groq's primary recommended model. Excellent instruction following, strong tool-call support, ~800–1200 tokens/second throughput. Best Omega router model.
- **Llama 3.1 8B** (`llama-3.1-8b-instant`): ultra-low latency (~2000 tok/s), near-zero cost. Ideal for classification, routing decisions, and lightweight subtasks.
- **Mixtral 8x7B**: still available; good for tasks needing broader knowledge mix.
- **Context**: Groq supports up to 128 k context on the 70B model (verify current limits via `GET /openai/v1/models`).
- **Pricing**: Groq remains significantly cheaper per token than Claude/Gemini Pro for equivalent throughput. Llama 3.3 70B at ~$0.59/M input tokens (vs Claude Sonnet at $3/M).
- **Rate limits**: free tier is restrictive; paid tier removes most bottlenecks. Omega should implement retry-with-backoff + model fallback chain.

**Action for Omega**: Use Groq Llama 3.3 70B as the primary fast-path router/executor. Fall back to Claude Sonnet only for tasks needing tool use chains or extended thinking.

---

## Gemini Updates

Google's Gemini 2.x family (released late 2024 through 2025) has matured significantly:

- **Gemini 2.5 Flash** (`gemini-2.5-flash-preview`): best Flash model. 1M token context, multimodal (text, image, audio, video, PDF). Very fast, very cheap (~$0.075/M input). Strong at summarization, extraction, and structured output. Recommended for Omega's Scout and Historian agents.
- **Gemini 2.5 Pro** (`gemini-2.5-pro-preview`): highest capability in the family. Deep reasoning, code generation, long document analysis. ~$1.25/M input. Use for Omega's Planner when Claude is unavailable.
- **Thinking mode** (2.5 Pro): similar to Claude extended thinking — activates for complex reasoning. Token budget configurable.
- **Native tool use / function calling**: Gemini 2.5 supports parallel function calling, response schema enforcement (JSON mode). Reliable for structured agent outputs.
- **Grounding with Google Search**: built-in search tool for Gemini API calls — useful for research-type agent tasks without a separate retrieval layer.
- **Free tier (AI Studio)**: generous free quota; Omega can route low-priority tasks to AI Studio keys to reduce spend.

**Action for Omega**: Assign Gemini 2.5 Flash to Scout (web research, summarization) and Historian (log analysis). Reserve Gemini 2.5 Pro as a Claude fallback for planning tasks.

---

## MCP Ecosystem Highlights

The Model Context Protocol (MCP) ecosystem has grown substantially. Most useful servers for an orchestration system:

| Server | Use case for Omega |
|---|---|
| `@modelcontextprotocol/server-filesystem` | Give agents read/write access to project files safely |
| `@modelcontextprotocol/server-github` | Issue tracking, PR creation, repo search from within agent loops |
| `@modelcontextprotocol/server-postgres` / `supabase-mcp` | Direct Supabase DB queries from agent context |
| `@modelcontextprotocol/server-brave-search` | Web search without browser automation |
| `mcp-server-fetch` | Fetch and parse any URL — replaces custom scrapers |
| `@modelcontextprotocol/server-memory` | Official MCP memory server (knowledge graph) — pairs with agent memory layer |
| `mcp-server-shell` | Controlled shell execution (replaces ad-hoc Bash tool calls) |
| `mcp-server-obsidian` | Read/write Obsidian vault — relevant given Omega uses an Obsidian vault |

**Priority for Omega**: `supabase-mcp` (direct DB introspection) + `server-memory` (persistent KV/graph memory) + `server-github` (task tracking). These three close the most gaps in the current architecture.

---

## Local LLM Fallback (Ollama)

Best models to run locally via Ollama in 2026 for a WSL2/Windows host:

- **Llama 3.2 3B** (`ollama pull llama3.2:3b`): 2 GB RAM, CPU-runnable. Best ultra-light fallback for routing and classification when API is down.
- **Llama 3.1 8B Q4** (`llama3.1:8b-instruct-q4_K_M`): 5 GB RAM. Good general-purpose local model. Solid tool-call support via Ollama's OpenAI-compatible endpoint.
- **Qwen2.5-Coder 7B** (`qwen2.5-coder:7b`): outstanding for code generation/review tasks. Recommended for Omega's Builder agent fallback.
- **Mistral 7B v0.3**: reliable instruction following, broad knowledge. Good all-rounder.
- **Phi-3.5 Mini** (`phi3.5:mini`): Microsoft's 3.8B model, extremely efficient, surprisingly capable on reasoning tasks.
- **Ollama serve** exposes `http://localhost:11434/v1` — fully OpenAI-compatible. Omega's `local-executor.js` can hit this endpoint with zero code change if base URL is parameterized.

**Action for Omega**: Set up a 3-tier fallback: `Groq (primary) → Claude Sonnet (premium) → Ollama Llama 3.1 8B (offline)`. Ensure `local-executor.js` reads `OLLAMA_BASE_URL` from env.

---

## Agent Memory Solutions

Production-ready options in 2026 for persistent agent memory:

1. **Mem0 (mem0.ai)** — OSS + hosted. Purpose-built for agent memory: stores facts, preferences, and user history with automatic deduplication. Python + Node SDKs. Self-hostable. Best fit for Omega's Historian agent.
2. **MCP `server-memory`** — official MCP knowledge-graph memory. Entities + relations + observations. Lightweight, file-backed, zero infrastructure. Good for Oracle-level persistent context.
3. **Supabase pgvector** — Omega already runs Supabase. Add a `memories` table with a `vector` column + `pgvector` extension. Semantic search via `<=>` operator. No new infrastructure needed — best ROI for Omega.
4. **Chroma** (self-hosted) — OSS vector DB. Docker image, REST API. Good if you need more query flexibility than pgvector.
5. **Zep** — temporal memory store with automatic summarization and forgetting curves. Well-suited for long-running agent sessions.

**Action for Omega**: Use `Supabase pgvector` for semantic memory (already have the infrastructure). Pair with `MCP server-memory` for fast entity/relation lookups. Skip managed services to stay self-hosted.

---

## Cost Optimization

Techniques validated for multi-agent systems:

1. **Prompt caching** (Claude): cache system prompts + large context. 90% discount on cached tokens. Most impactful single change for Omega.
2. **Model tiering**: route by task complexity. Cheap fast model (Groq 8B / Gemini Flash) for triage, summarization, extraction. Premium model (Claude Sonnet/Opus) only for final synthesis and planning.
3. **Token budgeting**: set `max_tokens` per agent role. Scout = 1 k, Planner = 4 k, Builder = 2 k. Prevents runaway completions.
4. **Batch API** (Claude + Gemini): non-time-sensitive tasks (nightly summaries, memory consolidation) can use batch endpoints at 50% discount.
5. **Context compression**: summarize completed sub-task results before injecting into next agent's context. Reduces downstream token counts by 40–60%.
6. **Local fallback routing**: route repetitive/low-stakes tasks (log parsing, template filling) to Ollama — $0 marginal cost.
7. **Structured output**: enforce JSON schema on all agent outputs. Eliminates re-try loops caused by malformed free-text responses.
8. **Streaming with early termination**: stream responses and terminate when structured output markers are detected. Avoids paying for verbose trailing text.

---

## Recommended Stack for Omega (May 2026)

| Layer | Recommended | Notes |
|---|---|---|
| Orchestrator / Planner | Claude Sonnet 4.6 + Extended Thinking | Caching on system prompt |
| Fast Router / Executor | Groq Llama 3.3 70B | Primary workhorse |
| Lightweight Classifier | Groq Llama 3.1 8B Instant | Routing, scoring, triage |
| Research / Scout | Gemini 2.5 Flash + Grounding | 1M context, built-in search |
| Code Tasks | Qwen2.5-Coder 7B via Ollama | Local, zero cost |
| Offline Fallback | Ollama Llama 3.1 8B Q4 | API-down resilience |
| Memory Layer | Supabase pgvector + MCP server-memory | Already self-hosted |
| Tool Surface | MCP: filesystem, github, supabase, fetch | Standardized tool interface |
| Cost Control | Prompt caching + model tiering + batch API | Target <$10/day for active orchestration |

---

*Note: WebSearch was unavailable during compilation. This brief is based on training knowledge (cutoff Aug 2025) plus public roadmap data. Verify model IDs and pricing at docs.anthropic.com, console.groq.com, and ai.google.dev before implementation.*
