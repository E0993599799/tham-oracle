# Cost Gate V1 — Token Optimization Rules for Forge/Omega

**Version**: 1.0  
**Locked**: 2026-05-17  
**Applies to**: All agents, all LLM calls, all batch operations  
**Owner**: ธาม (Tham Oracle)  

---

## Core Principle

**Token cost is a runtime policy, not an API feature.**

Every LLM call should optimize for:
1. **Cache hit rate** (static prefixes, stable keys)
2. **Batch efficiency** (non-realtime → batch lanes)
3. **Reasoning budget allocation** (risk tier-based)
4. **Cost visibility** (log cached_tokens on every call)

---

## RULE 1: Prompt Cache = Static First, Dynamic Last

### Pattern

```
GOOD (cache-optimized):
┌─────────────────────────────────────────┐
│ [STATIC] System prompt (locked)         │ ← cached
│ [STATIC] Policy rules (locked)          │ ← cached
│ [STATIC] Tools/schema definitions       │ ← cached
│ [STATIC] Agent contract + examples      │ ← cached
├─────────────────────────────────────────┤
│ [DYNAMIC] Timestamp (current run)       │ ← NOT cached
│ [DYNAMIC] UUID (request ID)             │ ← NOT cached
│ [DYNAMIC] User input (task details)     │ ← NOT cached
│ [DYNAMIC] Run metadata (lane, tier)     │ ← NOT cached
└─────────────────────────────────────────┘

BAD (cache-wasted):
┌─────────────────────────────────────────┐
│ [DYNAMIC] User input (varies every call)│ ← breaks cache
├─────────────────────────────────────────┤
│ [STATIC] System prompt (now useless)    │ ← cache miss
│ [STATIC] Policy rules                   │ ← cache miss
│ [STATIC] Tools/schema                   │ ← cache miss
└─────────────────────────────────────────┘
```

### Implementation

**Anthropic (explicit cache control):**
```python
# Prompt structure
SYSTEM_STATIC = """
You are an agent in Forge/Omega. 
[All rules, policies, tools locked here]
"""

USER_DYNAMIC = f"""
User request: {user_input}
Run ID: {uuid.uuid4()}
Timestamp: {datetime.now()}
"""

# Call with cache breakpoint after static section
message = client.messages.create(
    model="claude-opus",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": SYSTEM_STATIC,
            "cache_control": {"type": "ephemeral"}  # Request cache
        }
    ],
    messages=[
        {"role": "user", "content": USER_DYNAMIC}
    ]
)

# Log cache performance
print(f"Cache read: {message.usage.cache_read_input_tokens}")
print(f"Cache creation: {message.usage.cache_creation_input_tokens}")
```

**OpenAI (automatic cache on 1024+ token prefix):**
```python
# OpenAI auto-caches if:
# 1. Prefix length >= 1024 tokens
# 2. Identical prefix repeated across calls
# 3. Uses prompt_cache_key (optional)

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": SYSTEM_STATIC},  # Auto-cached if long enough
        {"role": "user", "content": USER_DYNAMIC}
    ],
    extra_body={
        "prompt_cache_key": f"forge-agent-{agent_name}"  # Optional routing
    }
)
```

**Google Gemini (explicit + implicit):**
```python
# Explicit cached content (Gemini 2.5+)
cached_content = {
    "system_instruction": SYSTEM_STATIC,
    "cached_token_count": 0  # filled after first call
}

response = client.generate_content(
    contents=USER_DYNAMIC,
    cached_content=cached_content,
    thinking={
        "type": "enabled",
        "budget_tokens": 5000  # By risk tier (see Rule 3)
    }
)
```

### Rule 1 Checklist

- ✅ All static content (system, policy, tools, schema) in FIRST section
- ✅ All dynamic content (user input, timestamp, UUID) in LAST section
- ✅ Call happens AFTER all static content is committed to cache
- ✅ Log `cache_read_input_tokens` and `cache_creation_input_tokens` every call
- ✅ If `cache_read_input_tokens == 0` for repeated calls → repair prompt order

---

## RULE 2: Batch API = Non-Realtime Work Only

### When to use Batch Lane

Use Batch API (OpenAI, Anthropic, Google) for:
- ✅ Task classification runs (bulk)
- ✅ Log summarization (overnight)
- ✅ Proof aggregation (daily)
- ✅ Memory consolidation (weekly)
- ✅ Agent skill scanning (periodic)
- ✅ Research batch (no human waiting)

### When NOT to use Batch Lane

Do NOT use Batch API for:
- ❌ Chat/control center (human waiting)
- ❌ Real-time routing decisions
- ❌ Lane health checks (< 1 sec SLA)
- ❌ Emergency escalations
- ❌ Interactive debugging

### Implementation

**Batch routing in Executor Lane Router:**

```python
def route_task(self, task_input):
    intent = task_input['intent']
    risk_level = self._risk_gate(intent)
    
    # Routing decision
    if intent in ['classify', 'summarize', 'batch_tag']:
        if not self._is_realtime_required():
            primary_lane = 'batch_api'  # Batch API lane
            # Cost savings: 50% discount on batch jobs
        else:
            primary_lane = self._select_lane(intent, risk_level)
    else:
        primary_lane = self._select_lane(intent, risk_level)
    
    return self._execute_on_lane(task_input, primary_lane)
```

### Rule 2 Checklist

- ✅ Batch jobs explicitly marked in task_input (`realtime: false`)
- ✅ Batch jobs routed to `batch_api` lane
- ✅ Fallback: if batch pending, use standard lane
- ✅ Log `batch_job_id` for cost tracking
- ✅ Monitor: batch completion latency (hours vs minutes)

---

## RULE 3: Thinking Budget = Risk Tier-Based Allocation

### Budget by Risk Tier

| Tier | Category | Examples | Thinking Budget | Why |
|------|----------|----------|-----------------|-----|
| **Low** | Simple routing | classify, tag, embed | 500–1K tokens | Straightforward classification |
| **Medium** | Code generation | write_code, patch, refactor | 2K–5K tokens | Logic verification needed |
| **High** | Architecture/Security/Math | design, security_audit, RCA, math | 10K–20K tokens | Deep reasoning required |

### Implementation

**Gemini 2.5+ with thinkingBudget:**

```python
def route_task_with_thinking(self, task_input):
    intent = task_input['intent']
    risk_level = self._risk_gate(intent)
    
    # Allocate thinking budget by risk tier
    thinking_budget_map = {
        'low': 1000,
        'medium': 5000,
        'high': 20000
    }
    budget = thinking_budget_map.get(risk_level, 5000)
    
    response = client.generate_content(
        prompt=task_input['prompt'],
        thinking={
            "type": "enabled",
            "budget_tokens": budget
        }
    )
    
    return response
```

**Claude (think_budget via extended thinking):**

```python
# Coming in Claude 5.x; current workaround:
# Use explicit reasoning prompt + length control

if risk_level == 'high':
    prompt = f"""
    REASON DEEPLY about this task:
    - What is the root problem?
    - What assumptions are you making?
    - What edge cases could break your solution?
    
    Then solve: {task_input['prompt']}
    """
    response = client.messages.create(
        model="claude-opus",
        max_tokens=8000,  # Extended length for high-risk reasoning
        messages=[{"role": "user", "content": prompt}]
    )
```

### Rule 3 Checklist

- ✅ Risk tier assigned by `_risk_gate()` (low/medium/high)
- ✅ Thinking budget allocated per tier
- ✅ High-risk tasks (security, RCA, math) get 10K+ tokens
- ✅ Log `thinking_tokens_used` for cost analysis
- ✅ Periodically review: thinking_tokens vs actual complexity

---

## RULE 4: Cost Visibility = Log Every Call

### Logging Template

```python
def log_cost_metrics(self, task_id, response, lane_name):
    """Log cost metrics for every LLM call"""
    
    log_entry = {
        "task_id": task_id,
        "timestamp": datetime.utcnow().isoformat(),
        "lane": lane_name,
        "model": response.model,
        "input_tokens": response.usage.prompt_tokens,
        "output_tokens": response.usage.completion_tokens,
        "cache_read_tokens": response.usage.cache_read_input_tokens or 0,
        "cache_creation_tokens": response.usage.cache_creation_input_tokens or 0,
        "thinking_tokens": response.usage.thinking_tokens or 0,
        "total_cost_usd": self._compute_cost(response),
        "cache_hit_rate": self._compute_hit_rate(response)
    }
    
    # Write to logs/cost-metrics.jsonl
    with open("logs/cost-metrics.jsonl", "a") as f:
        f.write(json.dumps(log_entry) + "\n")
    
    return log_entry

def _compute_cost(self, response):
    """Compute USD cost (example rates, adjust per provider)"""
    # Claude: $3/1M input, $15/1M output, $0.30/1M cached
    # GPT-4: $0.03/1K input, $0.06/1K output, $0.015/1K cached
    # Gemini: $0.075/1M input, $0.30/1M output, $0.0075/1M cached
    
    cache_savings = (response.usage.cache_read_input_tokens or 0) * 0.30 / 1000000
    input_cost = (response.usage.prompt_tokens) * 3 / 1000000
    output_cost = (response.usage.completion_tokens) * 15 / 1000000
    
    return input_cost + output_cost - cache_savings
```

### Cost Dashboard

Create daily cost report:

```bash
#!/bin/bash
# scripts/cost-report.sh

DATE=$(date +%Y-%m-%d)
COST_FILE="logs/cost-metrics.jsonl"

echo "=== Daily Cost Report: $DATE ==="
echo ""

# Total cost
jq -s 'map(.total_cost_usd) | add' "$COST_FILE" | \
  awk '{printf "Total Cost: $%.2f\n", $1}'

# By lane
echo ""
echo "By Lane:"
jq -r '.lane' "$COST_FILE" | sort | uniq -c | \
  while read count lane; do
    cost=$(jq -s "map(select(.lane==\"$lane\") | .total_cost_usd) | add" "$COST_FILE")
    printf "  %s: \$%.2f (%d calls)\n" "$lane" "$cost" "$count"
  done

# Cache hit rate
echo ""
echo "Cache Performance:"
jq -s 'map(select(.cache_read_tokens > 0)) | length' "$COST_FILE" | \
  awk '{printf "Cache hits: %d calls\n", $1}'

jq -s 'map(.cache_hit_rate) | add / length * 100' "$COST_FILE" | \
  awk '{printf "Average cache hit rate: %.1f%%\n", $1}'
```

### Rule 4 Checklist

- ✅ Every LLM call logs to `logs/cost-metrics.jsonl`
- ✅ Log includes: input_tokens, output_tokens, cache_read, cache_creation, thinking_tokens
- ✅ Daily cost report generated (nightly via cron)
- ✅ Cost dashboard available (optional: dashboard/cost-dashboard.html)
- ✅ Alert on: cost spike (>$10/day), cache miss chains, slow thinking

---

## RULE 5: Cache Miss Detection & Repair

### When Cache Hit = 0 (Unexpected)

```python
def check_cache_health(self, response, expected_cache_hit=True):
    """Verify cache is working as expected"""
    
    cache_read = response.usage.cache_read_input_tokens or 0
    
    if expected_cache_hit and cache_read == 0:
        # Cache miss on repeated call!
        print(f"⚠️ CACHE MISS: Expected cache but got 0 tokens")
        print(f"   Task: {response.task_id}")
        print(f"   Prompt length: {response.usage.prompt_tokens}")
        print(f"   Action: Review prompt order (dynamic content first?)")
        
        # Log for later analysis
        with open("logs/cache-misses.log", "a") as f:
            f.write(f"{datetime.now().isoformat()}: {response.task_id}\n")
```

### Repair Pattern

**Before (broken cache):**
```python
# User input changes first → breaks cache
USER_INPUT = f"Classify: {user_text}"  # ← Dynamic first!

SYSTEM_RULES = """
You are a classifier.
Rules:
1. ...
2. ...
"""

messages = [
    {"role": "user", "content": USER_INPUT},
    {"role": "system", "content": SYSTEM_RULES}
]
```

**After (fixed):**
```python
# Static rules first → cache stable
SYSTEM_RULES = """
You are a classifier.
Rules:
1. ...
2. ...
"""

USER_INPUT = f"Classify: {user_text}"  # ← Dynamic last!

messages = [
    {"role": "system", "content": SYSTEM_RULES},
    {"role": "user", "content": USER_INPUT}
]
```

### Rule 5 Checklist

- ✅ Log cache_read_tokens on every call
- ✅ Alert on cache_read == 0 when expected > 0
- ✅ Review & repair prompt order
- ✅ Re-test after repair (verify cache hit returns)
- ✅ Archive cache-miss logs (weekly analysis)

---

## Implementation Roadmap (Forge/Omega)

### Phase 1: Logging (Week 1)
- ✅ Add Rule 4 logging to all LLM calls
- ✅ Create cost-metrics.jsonl
- ✅ Build daily cost report script

### Phase 2: Prompt Optimization (Week 2)
- ✅ Audit all agent prompts (identify static vs dynamic)
- ✅ Reorganize by Rule 1 (static first, dynamic last)
- ✅ Test cache hit rate before/after

### Phase 3: Batch Routing (Week 3)
- ✅ Identify batch-suitable tasks (classify, tag, summarize)
- ✅ Route to batch_api lane
- ✅ Monitor batch latency + savings

### Phase 4: Thinking Budget (Week 4)
- ✅ Add risk tier classification (Rule 3)
- ✅ Allocate thinking budget by tier
- ✅ Track thinking_tokens cost

### Phase 5: Dashboard (Week 5)
- ✅ Create cost dashboard (daily/weekly/monthly views)
- ✅ Cache performance heatmap
- ✅ Risk tier distribution

---

## Enforcement

These rules are **locked as policy** for all Forge/Omega agents:
- ✅ ธาม (orchestrator)
- ✅ Zeus (executor)
- ✅ Poseidon (coordinator)
- ✅ Core (proof validator)
- ✅ All future agents

**Violation = task blocked** until corrected.

---

## References

- [OpenAI Prompt Caching](https://developers.openai.com/api/docs/guides/prompt-caching)
- [Anthropic Prompt Caching](https://platform.claude.com/docs/build-with-claude/prompt-caching)
- [Google Gemini Context Caching](https://ai.google.dev/gemini-api/docs/caching)
- [Google Gemini Thinking](https://ai.google.dev/gemini-api/docs/thinking)
- [OpenAI Batch API](https://platform.openai.com/docs/guides/batch)
- [Anthropic Batch Processing](https://platform.claude.com/docs/build-with-claude/batch-api)

---

**Locked by**: ธาม Oracle  
**Effective date**: 2026-05-17  
**Review cycle**: Monthly  
**Contact**: tham@oracle.local
