# Routing Decision Table — Phase 1

**Purpose**: Map task types → executor lanes with fallbacks. Source of truth for Phase 2 router implementation.

**Updated**: 2026-05-17  
**Status**: APPROVED (locked by พี่เอก + ธาม)  
**Phase**: 1C (routing table spec)

---

## Decision Table

| Task Type | Intent Signal | Risk Level | → Primary Lane | Fallback | Notes |
|---|---|---|---|---|---|
| **coding / repo repair** | `write_code`, `fix_bug`, `patch`, `refactor_code` | any | `codex_gpt55` | `ollama` | Fast iteration, accepts Chinese prompt, good at bug fixes |
| **architecture / review** | `review`, `design`, `refactor`, `security_audit`, `performance` | any | `claude` (via 9router cc/claude-sonnet-4-6) | `codex_gpt55` | Deep reasoning, long-context, design decisions |
| **research / web** | `search`, `summarize`, `web_fetch`, `data_gathering` | any | `gemini` | `ollama` | Real-time web, summarization, fact-gathering |
| **classify / embed / cheap** | `tag`, `classify`, `embed_text`, `batch_tag` | low | `ollama` (local minimax/glm/qwen) | — | No fallback needed; if ollama down, skip task |
| **legacy / local / allowlist** | `tool_call` + allowlisted tool (SFSR, PowerShell, tmux) | not-high | `hermes` (via 9router ollama/minimax) | `powershell_sfsr` | Specialist for local execution; fallback to direct SFSR script |
| **unknown / unrouted** | (no match above) | medium | `codex_gpt55` | `ollama` | Default fallback for unclassified tasks |

---

## Intent Signal Glossary

### coding / repo repair
- `write_code` — new function, feature, or complete file
- `fix_bug` — debug and patch existing code
- `patch` — small targeted fix
- `refactor_code` — restructure without logic change

### architecture / review
- `review` — code review, PR feedback, design critique
- `design` — architecture decision, system design
- `refactor` — large-scale restructure
- `security_audit` — security/compliance review
- `performance` — optimization, profiling, tuning

### research / web
- `search` — web search, information lookup
- `summarize` — convert findings to summary
- `web_fetch` — fetch and extract from URL
- `data_gathering` — bulk data collection

### classify / embed / cheap
- `tag` — single-tag or batch classification
- `classify` — assign category/label
- `embed_text` — generate vector embedding
- `batch_tag` — classify multiple items

### legacy / local / allowlist
- `tool_call` — run external tool/command
- Allowed tools: SFSR (PowerShell repair), tmux, local shell, GitHub CLI

### unknown / unrouted
- No matching intent signal → apply default policy

---

## Risk Level Mapping

| Level | Condition | Hermes Allow? | Gate Timeout Trigger |
|---|---|---|---|
| **low** | Read-only, no side effects | Yes | 30s (OK) |
| **medium** | Modification, reversible | Yes | 20s (warn) |
| **high** | Destructive, irreversible | No | 10s (block) |
| **unknown** | Default when unclassified | Yes | 20s (medium rules) |

---

## Lane Availability

| Lane | Status | Endpoint | Routing |
|---|---|---|---|
| `codex_gpt55` | ✅ Active | 9router port 20128 | `openai.models.codex-text-002` |
| `claude` | ✅ Active | 9router port 20128 | `cc/claude-sonnet-4-6` |
| `gemini` | 🔧 Pending | — | TBD (may need API key) |
| `ollama` | ✅ Active | 9router port 20128 | `ollama/minimax-m2.5` (default), fallback `ollama/qwen3.5` |
| `hermes` | ✅ Active (legacy) | 9router port 20128 | `ollama/minimax-m2.5` |
| `powershell_sfsr` | ✅ Active (local only) | WSL/Windows direct | SFSR-24–28 scripts |

---

## Fallback Rules

**Primary → Fallback Transition Trigger:**
1. **Timeout**: Primary lane no response after gate timeout → try fallback
2. **Error**: Primary lane returns error code → try fallback
3. **Explicit**: Task explicitly requests fallback lane → use immediately
4. **Capacity**: Primary lane at max concurrency → try fallback
5. **Unavailable**: Primary lane health check fails → skip to fallback

**Fallback exhaustion:**
- If fallback also fails or unavailable → emit task result = `BLOCKED`
- Emit proof: timeout log + error + which lanes tried
- Return task to queue for manual retry or escalation

---

## Approval Stamps

| Stakeholder | Date | Approval |
|---|---|---|
| พี่เอก | 2026-05-17 | ✅ Locked (routing_decision_table + gate_timeout_policy) |
| ธาม | 2026-05-17 | ✅ Locked (hermes_trigger_conditions, done_when criteria) |

---

## Next Phase

**Phase 2**: Implement `executor-lane-router.py` / TypeScript router using this table as SOT.

**Tests**:
1. Route 10 sample tasks through each lane → verify correct lane
2. Simulate timeout on primary → verify fallback trigger
3. Classify unrouted task → verify default routing
4. Check Hermes trigger conditions → only when explicit/allowlist/low-medium risk
