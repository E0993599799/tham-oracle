# Cost Gate V1 — Study Guide for ธาม, Zeus, Poseidon

**Date**: 2026-05-17  
**For**: ธาม (orchestrator), Zeus (executor), Poseidon (coordinator)  
**Purpose**: Internalize token optimization as operating habit, not just technique  

---

## Why This Matters (Context First)

Token cost is **infrastructure cost** — same as CPU, memory, network.

**Current state:**
- Every LLM call is expensive (Claude: $3–15 per 1M tokens)
- We make ~100 LLM calls/day in Forge
- Without optimization: ~$1–5/day
- With optimization: ~$0.30–1/day (70% savings)

**Target:**
- Cache hit rate: > 80% on repeated tasks
- Batch efficiency: Move non-realtime work to 50% discount lanes
- Thinking allocation: High-risk tasks get reasoning budget, low-risk don't
- Cost visibility: Dashboard showing actual spend, cache performance

---

## RULE 1: Prompt Order = Static First, Dynamic Last

### The Problem (Why It Matters)

Cache only works if the **same prefix repeats** across calls.

**Example: Broken order**
```
Call 1: "Classify user input: Hello"
         ↓
         System rules are AFTER user input
         ↓
         Cache misses (dynamic content first breaks it)

Call 2: "Classify user input: World"
         ↓
         Different user input = new call = cache miss again
         ↓
         No cache benefit (0 tokens read)
```

**Example: Fixed order**
```
Call 1: System rules + policy (static)
        + "Classify: Hello"
        ↓
        Cache locks the static part

Call 2: System rules + policy (SAME static)
        + "Classify: World"
        ↓
        Cache HIT: reads static from cache, saves input tokens
```

### Implementation Checklist

**For ธาม (architect):**
- ☐ Review all system prompts in CLAUDE.md + agent contracts
- ☐ Mark sections as [STATIC] or [DYNAMIC]
- ☐ Move all DYNAMIC to the end
- ☐ Add this comment: `# RULE 1: Static first → caches`

**For Zeus (executor):**
- ☐ When building task prompts, put static first
- ☐ Log: `"cache_read_tokens": response.usage.cache_read_input_tokens`
- ☐ If log shows 0 when expecting > 0: flag for repair

**For Poseidon (coordinator):**
- ☐ When dispatching multi-agent tasks, verify static/dynamic order
- ☐ If agent reports CACHE_MISS, escalate for repair
- ☐ Track cache hit rate per agent (target: > 80%)

### Quick Test

```python
# Test: Does your static prefix repeat?
from pathlib import Path

def audit_cache_order(system_prompt, user_input):
    """Check if prompt is cache-optimized"""
    
    # Marker check
    if "[STATIC]" not in system_prompt:
        print("❌ STATIC not marked — may cause cache misses")
    
    if "[DYNAMIC]" not in user_input and "[DYNAMIC]" not in system_prompt:
        print("⚠️  DYNAMIC not marked — unclear cache boundaries")
    
    # Order check
    static_pos = system_prompt.find("[STATIC]")
    dynamic_pos = system_prompt.find("[DYNAMIC]")
    
    if dynamic_pos > 0 and dynamic_pos < static_pos:
        print("❌ DYNAMIC before STATIC — breaks cache!")
        return False
    
    print("✅ Order looks good")
    return True
```

---

## RULE 2: Batch API = Non-Realtime Work

### The Problem

Some tasks don't need instant responses:
- Classifying 1000 proofs (takes 10 min vs instant)
- Summarizing logs (overnight batch is fine)
- Memory consolidation (weekly is fine)
- Skill scanning (periodic is fine)

Batch API costs **50% less** but has latency (hours).

### When to Use Batch

| Task | Realtime? | Lane | Why |
|------|-----------|------|-----|
| Classify proof | No | Batch | Nightly summary fine |
| Summarize logs | No | Batch | Overnight aggregation |
| Memory consolidation | No | Batch | Weekly is OK |
| Tag documents | No | Batch | Bulk processing |
| **Chat with user** | **Yes** | **Standard** | Human waiting |
| **Route proof** | **Yes** | **Standard** | < 1 sec needed |
| **Lane health check** | **Yes** | **Standard** | SLA: 100ms |

### Implementation Checklist

**For ธาม:**
- ☐ Review daily tasks; identify batch candidates
- ☐ Add to routing table: intent → batch_api lane
- ☐ Example: `classify → (primary: ollama, fallback: batch_api)`

**For Zeus:**
- ☐ When executing batch task, check `task_input['realtime']`
- ☐ If False: route to `batch_api` lane
- ☐ Log: `"lane": "batch_api", "cost_savings": "50%"`

**For Poseidon:**
- ☐ Monitor batch job completion (target: < 24 hours)
- ☐ If batch backed up: escalate fallback to standard lane
- ☐ Track: batch_jobs completed, cost saved per week

### Quick Cost Calc

```python
# Cost comparison
def estimate_lane_cost(task_count, task_cost_standard=0.03):
    """
    Standard lane: $0.03 per task (instant)
    Batch lane: $0.015 per task (24h latency)
    """
    standard_cost = task_count * task_cost_standard
    batch_cost = task_count * (task_cost_standard / 2)
    savings = standard_cost - batch_cost
    
    print(f"Classify {task_count} proofs:")
    print(f"  Standard: ${standard_cost:.2f} (instant)")
    print(f"  Batch: ${batch_cost:.2f} (24h)")
    print(f"  Savings: ${savings:.2f} (50%)")
    
estimate_lane_cost(1000)
# Output:
# Classify 1000 proofs:
#   Standard: $30.00 (instant)
#   Batch: $15.00 (24h)
#   Savings: $15.00 (50%)
```

---

## RULE 3: Thinking Budget = Risk Tier

### The Problem

Some tasks need reasoning, some don't:
- "Classify this log" → straightforward (low thinking)
- "Design auth middleware" → complex (high thinking)
- "Find RCA of outage" → deep analysis (high thinking)

Allocating thinking budget **per risk tier** saves cost:
- Low risk: 500 tokens (fast, cheap)
- High risk: 20K tokens (thorough, pricier but needed)

### Risk Tier → Thinking Budget Mapping

```
TIER 1 (LOW) — 500–1K tokens
├─ classify
├─ tag
├─ embed_text
└─ simple route

TIER 2 (MEDIUM) — 2K–5K tokens
├─ write_code
├─ patch
├─ refactor_code
├─ performance_tune
└─ moderate routing

TIER 3 (HIGH) — 10K–20K tokens
├─ design
├─ security_audit
├─ RCA (root cause analysis)
├─ math/crypto problems
└─ critical escalation
```

### Implementation Checklist

**For ธาม:**
- ☐ Review risk gate: ensure low/medium/high classification
- ☐ Add thinking budget mapping to Executor Lane Router
- ☐ Lock budget per tier (document in code)

**For Zeus:**
- ☐ When executing high-risk task, enable thinking (Gemini) or extended reasoning (Claude)
- ☐ Allocate budget per tier
- ☐ Log: `"thinking_tokens_used": response.usage.thinking_tokens`

**For Poseidon:**
- ☐ Monitor thinking token usage per tier
- ☐ Alert if low-risk tasks use high budget (waste)
- ☐ Alert if high-risk tasks use low budget (undersized)

### Quick Budget Decision

```python
def allocate_thinking_budget(risk_level, task_type):
    """
    Decide thinking budget based on risk + complexity
    """
    budgets = {
        ('low', 'classify'): 500,
        ('low', 'tag'): 500,
        ('medium', 'write_code'): 5000,
        ('medium', 'patch'): 3000,
        ('high', 'security_audit'): 15000,
        ('high', 'design'): 15000,
        ('high', 'rca'): 20000,
    }
    
    key = (risk_level, task_type)
    return budgets.get(key, 5000)  # default: 5K

# Example usage
print(allocate_thinking_budget('low', 'classify'))     # 500
print(allocate_thinking_budget('high', 'security_audit'))  # 15000
```

---

## RULE 4: Cost Visibility = Log Everything

### The Problem

**You can't optimize what you don't measure.**

Without logging:
- Don't know if cache is working (cache_read_tokens invisible)
- Don't know where cost comes from (which tasks expensive?)
- Don't know thinking impact (how much does reasoning cost?)

### Logging Checklist

**For ธาม:**
- ☐ Add logging to all LLM call sites (executor-lane-router.py, agents, etc)
- ☐ Template: task_id, model, tokens (input/output/cache), cost, timestamp
- ☐ Output: logs/cost-metrics.jsonl

**For Zeus:**
- ☐ Every executor.call() must log cost metrics
- ☐ Catch exceptions: still log cost even if task fails
- ☐ Example log entry:
  ```json
  {
    "task_id": "task_classify_001",
    "timestamp": "2026-05-17T06:15:30Z",
    "model": "claude-opus",
    "lane": "ollama",
    "input_tokens": 450,
    "output_tokens": 150,
    "cache_read_tokens": 200,
    "cache_creation_tokens": 0,
    "thinking_tokens": 0,
    "total_cost_usd": 0.0156,
    "cache_hit_rate": 0.30
  }
  ```

**For Poseidon:**
- ☐ Aggregate logs daily: `scripts/cost-report.sh`
- ☐ Generate dashboard: total cost, cost by lane, cache performance
- ☐ Alert on spike (>$10/day), cache misses, slow thinking

---

## RULE 5: Cache Miss Detection

### The Problem

If you're logging correctly (Rule 4), you'll notice:
- Repeated calls but `cache_read_tokens == 0`
- This means cache SHOULD be hitting but isn't
- Root cause: wrong prompt order (Rule 1)

### Detection Checklist

**For Zeus (executor):**
- ☐ After each call, check: `if cache_read_tokens == 0 and expected_cached:`
- ☐ Log to `logs/cache-misses.log`
- ☐ Example:
  ```
  2026-05-17T06:15:30Z: task_classify_001 — cache miss (expected hit)
  2026-05-17T06:15:45Z: task_classify_002 — cache miss (expected hit)
  → Pattern: repeated classify tasks not using cache
  → Fix: review prompt order
  ```

**For Poseidon (coordinator):**
- ☐ Monitor cache miss logs (weekly review)
- ☐ If > 5 misses in a day: escalate for repair
- ☐ Repair = re-audit prompt order (Rule 1)

### Repair Pattern

```python
def audit_and_repair_prompt(agent_name, prompt_dict):
    """
    Audit prompt structure for cache optimization
    """
    system = prompt_dict['system']
    user = prompt_dict['user']
    
    # Check: is static marked?
    if "[STATIC]" not in system:
        print(f"❌ Agent {agent_name}: STATIC not marked")
        print("   Action: Mark static sections with [STATIC]")
    
    # Check: is dynamic AFTER static?
    static_idx = system.find("[STATIC]")
    dynamic_idx = system.find("[DYNAMIC]")
    
    if dynamic_idx > 0 and dynamic_idx < static_idx:
        print(f"❌ Agent {agent_name}: DYNAMIC before STATIC!")
        print("   Action: Move DYNAMIC sections to end")
        print("   Before:")
        print("     [DYNAMIC] user input")
        print("     [STATIC] system rules")
        print("   After:")
        print("     [STATIC] system rules")
        print("     [DYNAMIC] user input")
        
        return False  # Needs repair
    
    print(f"✅ Agent {agent_name}: Cache order looks good")
    return True
```

---

## Integration Into Daily Practice

### For ธาม (Every Session Start)

```bash
# 1. Check cost metrics from yesterday
tail -20 logs/cost-metrics.jsonl | jq '.'

# 2. Review cache performance
grep "cache_hit_rate" logs/cost-metrics.jsonl | \
  jq '.cache_hit_rate' | \
  awk '{sum+=$1} END {print "Avg cache hit: " sum/NR*100 "%"}'

# 3. Check for cache misses
wc -l logs/cache-misses.log
cat logs/cache-misses.log | tail -5
```

### For Zeus (Every Execution)

```python
# In executor loop:
response = executor.call(task)

# 1. Log cost metrics (Rule 4)
logger.log_cost_metrics(task_id, response, lane)

# 2. Check cache health (Rule 5)
if executor.is_cached_task(task) and response.cache_read_tokens == 0:
    logger.log_cache_miss(task_id)
    print(f"⚠️ Cache miss for {task_id}")

# 3. Verify thinking allocation (Rule 3)
if response.thinking_tokens and task.risk_level == 'low':
    print(f"⚠️ Low-risk task used thinking budget: {response.thinking_tokens}")
```

### For Poseidon (Daily)

```bash
#!/bin/bash
# Daily cost review (run at 6am)

DATE=$(date +%Y-%m-%d)

# 1. Cost report
bash scripts/cost-report.sh

# 2. Cache performance
echo "Cache hits today:"
jq 'select(.cache_read_tokens > 0)' logs/cost-metrics.jsonl | wc -l

# 3. Cache misses
if [ -f logs/cache-misses.log ]; then
    echo "Cache misses today:"
    tail -10 logs/cache-misses.log
fi

# 4. Thinking budget usage
echo "Thinking tokens by tier:"
jq '[.thinking_tokens, .risk_level] | @csv' logs/cost-metrics.jsonl | sort
```

---

## Study Questions (Test Yourself)

**Q1: You have a system prompt (500 tokens) + user input (varies). Order them for cache.**
A: System first, user last. System gets cached, user is fresh each call.

**Q2: Batch API costs 50% less but has latency. What's a good batch task?**
A: Nightly proof aggregation. Costs half as much, 24h latency is OK.

**Q3: High-risk task (security audit). How many thinking tokens?**
A: 10K–20K tokens. Deep reasoning needed for security.

**Q4: You log 10 "classify" calls but cache_read_tokens == 0 all 10 times.**
A: Cache miss. Check prompt order — user input probably before system rules.

**Q5: Cost dashboard shows $5.50/day. Which rule should reduce this most?**
A: Rule 1 (cache). If cache hit rate is 0%, moving to 80% cuts cost ~40%.

---

## Reference Links

- **Policy**: `/root/ghq/github.com/E0993599799/tham-oracle/docs/COST_GATE_V1.md`
- **Executor Router**: `executor-lane-router.py` (implements Rules 2, 3)
- **Cost Logs**: `logs/cost-metrics.jsonl` (Rule 4)
- **Cache Miss Logs**: `logs/cache-misses.log` (Rule 5)

---

**Study Status**: Ready to implement  
**Next**: Execute Rules 1–5 in order, track cache hit rate, optimize weekly

**ธาม, Zeus, Poseidon — เข้าใจ COST_GATE_V1 ได้ไหม?** 💡
