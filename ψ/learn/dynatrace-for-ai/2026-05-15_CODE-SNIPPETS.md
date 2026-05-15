# dynatrace-for-ai — Code Snippets & Examples

**Date**: 2026-05-15

---

## DQL Essentials — Core Syntax

### Critical Pitfalls Table

| ❌ Wrong | ✅ Right | Why |
|---------|---------|-----|
| `filter field in ["a", "b"]` | `filter in(field, {"a", "b"})` | Array literals use `{}` not `[]` |
| `by: severity, status` | `by: {severity, status}` | Multi-field grouping requires `{}` |
| `contains(toLowercase(f), "err")` | `contains(f, "err", false)` | Use 3rd arg for case-insensitive |
| `arrayAvg(field[])` | `arrayAvg(field)` | Don't combine `[]` with aggregate |
| `filter loglevel == "ERROR"` | correct — `loglevel` not `log.level` | Field name is `loglevel` |
| `timeseries percentile(m, 90)` | `percentile(m, 90, rollup: avg)` | `rollup:` is REQUIRED |
| `event.status == "OPEN"` | `event.status == "ACTIVE"` | OPEN doesn't exist |

### Fetch Commands → Data Models

```dql
fetch spans                          // Distributed tracing
fetch logs                           // content = body, loglevel = severity
fetch events                         // DAVIS / infrastructure events
fetch bizevents                      // Business events
fetch user.sessions                  // RUM sessions
timeseries avg(dt.host.cpu.usage)   // Metrics — NOT 'fetch dt.metric'
smartscapeNodes "HOST"               // Topology — NOT 'fetch'
```

### Valid Timeseries Aggregations (only these 9)

```dql
sum, avg, min, max, count,
percentile(m, N, rollup: avg),
median(m, rollup: avg),
percentRank(m, value, rollup: avg),
countDistinct(m)
```

### Time Alignment (@-operator)

```dql
now()@h              // Align to current hour boundary
now()@d              // Midnight today
now()@w1             // Monday this week
now()-2h@h           // 2 hours ago, aligned to hour
```

### Entity Fields (Smartscape — NOT deprecated dt.entity.*)

| Entity | ID Field | smartscapeNodes Type |
|--------|----------|----------------------|
| Host | `dt.smartscape.host` | `"HOST"` |
| Service | `dt.smartscape.service` | `"SERVICE"` |
| Process | `dt.smartscape.process` | `"PROCESS"` |
| K8s Cluster | `dt.smartscape.k8s_cluster` | `"K8S_CLUSTER"` |

### makeTimeseries

```dql
fetch logs
| makeTimeseries {total = count(), errors = countIf(loglevel == "ERROR")},
    interval: 5m, by: {k8s.cluster.name}, from:now()-24h, to:now()
```

**Important**: Do NOT pipe `timeseries` → `makeTimeseries`. Fails with `INVALID_IMPLICIT_TIME_DEFAULT`.

---

## Problem Analysis — dt-obs-problems

### Standard Pattern (Always Start Here)

```dql
fetch dt.davis.problems, from:now()-2h
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| fields event.start, display_id, event.name, event.category
| sort event.start desc
| limit 20
```

### High-Impact Problems

```dql
fetch dt.davis.problems
| filter not(dt.davis.is_duplicate) and event.status == "ACTIVE"
| filter dt.davis.affected_users_count > 100
| sort dt.davis.affected_users_count desc
```

### Root Cause by Entity

```dql
fetch dt.davis.problems, from:now()-7d
| filter not(dt.davis.is_duplicate)
| filter isNotNull(root_cause_entity_id)
| summarize problem_count = count(), by: {root_cause_entity_name}
| sort problem_count desc
| limit 20
```

### Blast Radius Analysis

```dql
fetch dt.davis.problems, from:now()-7d
| filter not(dt.davis.is_duplicate)
| fieldsAdd affected_count = arraySize(smartscape.affected_entity.ids)
| summarize avg_affected = avg(affected_count), max_affected = max(affected_count),
    problem_count = count()
  by: {root_cause_entity_name}
| sort avg_affected desc
```

### Problem Categories
- **AVAILABILITY** — Service unavailable, synthetic test fails, DB connection lost
- **ERROR** — Increased error rates beyond baseline
- **SLOWDOWN** — Performance degradation
- **RESOURCE** — CPU/memory/disk saturation, OOM
- **CUSTOM** — Custom anomaly detections

---

## Kubernetes Monitoring — dt-obs-kubernetes

### Core Fields
```
k8s.cluster.name, k8s.namespace.name, k8s.pod.name,
k8s.node.name, k8s.workload.name, k8s.container.name, k8s.object
```

### Available Metrics
```
dt.kubernetes.container.{cpu_usage, cpu_throttled, limits_cpu, requests_cpu,
  memory_working_set, limits_memory, requests_memory, restarts, oom_kills}
dt.kubernetes.node.{pods_allocatable, cpu_allocatable, memory_allocatable}
dt.kubernetes.pods
```

### Cluster Health

```dql
// List clusters
smartscapeNodes K8S_CLUSTER
| fields k8s.cluster.name, k8s.cluster.version, k8s.cluster.distribution

// Node near pod capacity
timeseries {current_pods = avg(dt.kubernetes.pods),
            max_pods = avg(dt.kubernetes.node.pods_allocatable)}
  by: {k8s.node.name, k8s.cluster.name}
| fieldsAdd pod_capacity_pct = (arrayAvg(current_pods) / arrayAvg(max_pods)) * 100
| filter pod_capacity_pct > 80

// Non-Running pods
smartscapeNodes K8S_POD | parse k8s.object, "JSON:config"
| fieldsAdd phase = config[status][phase]
| filter phase != "Running"
```

### Pod Troubleshooting

```dql
// OOMKills
timeseries oom_kills = sum(dt.kubernetes.container.oom_kills)
  by: {k8s.pod.name, k8s.namespace.name, k8s.cluster.name}
| filter arraySum(oom_kills) > 0
| sort arraySum(oom_kills) desc

// Excessive restarts
timeseries restarts = sum(dt.kubernetes.container.restarts)
  by: {k8s.pod.name, k8s.namespace.name}
| filter arraySum(restarts) > 5

// K8s operational events
fetch events
| filter event.kind == "K8S_EVENT"
| filter in(event.reason, {"OOMKilling", "BackOff", "Evicted", "FailedScheduling"})
| sort timestamp desc
```

### Security Checks

```dql
// Privileged containers
smartscapeNodes K8S_POD | parse k8s.object, "JSON:config"
| expand container = config[spec][containers]
| fieldsAdd privileged = container[securityContext][privileged]
| filter privileged == true

// Root containers (UID 0)
smartscapeNodes K8S_POD | parse k8s.object, "JSON:config"
| expand container = config[spec][containers]
| fieldsAdd run_as_user = container[securityContext][runAsUser]
| filter (isNull(run_as_user) or run_as_user == 0)
```

### Entity Disambiguation
- **`K8S_POD`** — K8s-native with `k8s.object` JSON, scheduling info, conditions
- **`CONTAINER`** — Host-level container inventory
- Smartscape edge: `CONTAINER --(is_part_of)--> K8S_POD`

---

## Prompts — Structured Workflows

### dt-performance-regression.prompt.md (most detailed)
7-step deployment-aware regression detection:
- **Time windows**: Before = `[deploy_time-35m, deploy_time-5m]`, After = `[deploy_time+5m, deploy_time+35m]`
- **Thresholds**: P95 > 20% increase OR > 2s absolute; Error rate > 1pp; Throughput -20%
- **Actions**: Bottleneck span identification → code correlation → rollback vs hotfix recommendation

### dt-incident-response.prompt.md
1. Fetch all active Davis Problems
2. Explain root cause + user impact per problem
3. Correlate affected traces
4. Prioritize by business severity
5. Generate shareable incident report

### dt-investigate-error.prompt.md
Davis Problems → top 3 errors per problem → logs → traces → code mapping → remediation

### dt-troubleshoot-problem.prompt.md
Problem-first approach (no broad log searches) → 7-step error classification → trace reconstruction

### dt-health-check.prompt.md
Response time + errors + throughput → active problems → recent deployments → top 5 slow endpoints → security vulnerabilities

### dt-daily-standup.prompt.md
Today vs yesterday comparison → health status classification → action item inference → concise bullets

---

## Plugin Descriptor

```json
{
  "name": "dynatrace",
  "version": "0.2.0",
  "description": "Dynatrace observability skills. DQL query patterns, application and infrastructure monitoring, log analysis, problem investigation, and incident response workflows. Use with dtctl or the Dynatrace MCP server for live platform access."
}
```

---

## Test Scripts

### test-skill-quality.sh (per-skill validation)
1. Required frontmatter: `name`, `description`, `license`
2. Name matches directory name
3. Name format: kebab-case, max 64 chars
4. Description ≤ 250 chars (warning)
5. Description ≤ 1024 chars (hard error)
6. No trailing whitespace

### test-structure.sh (cross-repo consistency)
1. Every skill dir has `SKILL.md`
2. Every skill symlinked in `plugins/dynatrace/skills/`
3. `marketplace.json` valid + references dynatrace plugin
4. Plugin source uses `./` prefix

---

## Notebook Deployment Script

```bash
# deploy_notebook.sh usage
bash scripts/deploy_notebook.sh [--dry-run] <notebook.json>
```

Flow:
1. Validates notebook JSON
2. Calls `notebook-validator.js` via `dtctl exec function`
3. Supports `--dry-run` for preview
4. Auto-deletes source file after successful deploy
5. Prompts `dtctl get` to re-download if edits needed

Notebook JSON structure:
```json
{
  "sections": [
    { "type": "markdown", "content": "..." },
    { "type": "dql", "query": "...", "autoSelectVisualization": true }
  ]
}
```
