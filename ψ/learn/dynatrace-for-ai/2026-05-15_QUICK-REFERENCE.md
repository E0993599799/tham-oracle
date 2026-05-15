# dynatrace-for-ai — Quick Reference

**Date**: 2026-05-15

---

## What It Is

Dynatrace for AI is a collection of portable **Agent Skills** and **Prompts** that teach AI coding agents (Claude Code, Copilot, Cursor, and 30+ others) how to work with Dynatrace's observability platform. Skills provide DQL patterns and domain knowledge. Pair with **dtctl** (CLI) or **Dynatrace MCP Server** for live query execution.

---

## Skills (15 total)

| Skill | Domain | One-liner |
|-------|--------|-----------|
| `dt-dql-essentials` | Query | Core DQL syntax, operators, pitfalls, time alignment |
| `dt-obs-services` | Observability | RED metrics, runtime telemetry per language |
| `dt-obs-frontends` | Observability | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-obs-tracing` | Observability | Distributed traces, spans, service dependencies |
| `dt-obs-hosts` | Observability | Host CPU, memory, disk, network, processes |
| `dt-obs-kubernetes` | Observability | K8s clusters, pods, nodes, OOMKills, security |
| `dt-obs-aws` | Observability | EC2, RDS, Lambda, ECS/EKS, VPC |
| `dt-obs-azure` | Observability | Azure resource monitoring |
| `dt-obs-gcp` | Observability | GCP resource monitoring |
| `dt-obs-logs` | Observability | Log queries, filtering, pattern matching |
| `dt-obs-problems` | Observability | DAVIS problems, root cause, blast radius |
| `dt-obs-predictive-analytics` | Observability | Forecasting, anomaly detection |
| `dt-app-dashboards` | Platform | Dashboard JSON, tiles, layouts, DQL integration |
| `dt-app-notebooks` | Platform | Notebook sections, analytics workflow |
| `dt-migration` | Migration | Classic entity DQL → Smartscape modernization |

---

## Prompts (6 total)

| Prompt | Use Case |
|--------|---------|
| `dt-daily-standup` | Today vs yesterday service health, action items |
| `dt-health-check` | Full service health: perf + errors + problems + deployments |
| `dt-incident-response` | Active incident triage, root cause, shareable report |
| `dt-investigate-error` | Problems → logs → traces → code mapping |
| `dt-performance-regression` | Pre/post deployment comparison with thresholds |
| `dt-troubleshoot-problem` | Structured problem investigation (7-step) |

---

## How to Install

```bash
# Claude Code
claude plugin marketplace add dynatrace/dynatrace-for-ai

# Universal (30+ agents)
npx skills add dynatrace/dynatrace-for-ai

# Manual
# Copy skill dirs into .claude/skills/ or .cursor/skills/ etc.
```

---

## Key Concepts

### DQL — Dynatrace Query Language
- Pipeline-based, not SQL. Chain commands with `|`
- Core commands: `fetch`, `timeseries`, `smartscapeNodes`, `filter`, `summarize`, `makeTimeseries`
- Always start with `dt-dql-essentials` skill

### Skills vs Prompts vs Plugins
- **Skills** = domain knowledge, loaded progressively (catalog 100 tokens → instructions ≤5K → references on-demand)
- **Prompts** = reusable task templates (structured workflows for common operations)
- **Plugins** = Claude Code integration packaging (marketplace.json + plugin.json + symlinked skills)

### Smartscape (NOT dt.entity.*)
- Dynatrace's dynamic topology engine
- Query with `smartscapeNodes "HOST"|"SERVICE"|"K8S_POD"|...`
- Use `dt.smartscape.*` fields — `dt.entity.*` is deprecated

### Dynatrace Notebooks
- JSON with `sections[]` (markdown + DQL blocks)
- Set `autoSelectVisualization: true` for auto chart selection
- Deploy via `bash scripts/deploy_notebook.sh notebook.json`

### Progressive Disclosure
- All 15 skills can be installed with zero token penalty at startup
- Agent selects relevant skill → full SKILL.md loads (~5K tokens)
- Reference files load only when agent needs deep topic detail

---

## Integration Points

| Tool | Role |
|------|------|
| **dtctl** | Recommended CLI: `brew install dynatrace-oss/tap/dtctl` → `dtctl auth login` → `npx skills add dynatrace-oss/dtctl` |
| **Dynatrace MCP Server** | API access for MCP-compatible agents (see docs.dynatrace.com) |
| **Claude Code marketplace** | `claude plugin marketplace add dynatrace/dynatrace-for-ai` |

---

## Top 5 Use Cases

1. **Service Health Check** — `dt-health-check` prompt → response time + errors + problems + deployments
2. **Incident Response** — `dt-incident-response` → Davis Problems → logs → traces → shareable report
3. **Performance Regression** — `dt-performance-regression` → symmetric windows around deployment → P95/error/throughput diff
4. **K8s Troubleshooting** — `dt-obs-kubernetes` + `dt-obs-logs` → pod failures, OOMKills, resource contention
5. **Error Investigation** — `dt-investigate-error` → Problems entry → log patterns → trace inspection

---

## Requirements

- Active Dynatrace tenant + API token with scopes: `document:read/write`, `audit:read`
- 35-day raw data retention (default)
- dtctl or Dynatrace MCP Server for live query execution

## DQL Gotchas (Fast Lookup)

```
Array literals:  {"a", "b"}  not  ["a", "b"]
Multi-field by:  by: {f1, f2}  not  by: f1, f2
Metrics:         timeseries avg(...)  not  fetch dt.metric
Topology:        smartscapeNodes "HOST"  not  fetch
Percentile:      percentile(m, 90, rollup: avg)  — rollup REQUIRED
Status values:   event.status == "ACTIVE"  not  "OPEN"
Entity fields:   dt.smartscape.host  not  dt.entity.host
Log body:        content  (not message or body)
Log severity:    loglevel  (not log.level)
```
