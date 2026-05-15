# dynatrace-for-ai — Architecture

**Date**: 2026-05-15

## Overview

Dynatrace for AI is a curated collection of **15 portable knowledge packages ("skills")** following the [Agent Skills](https://agentskills.io) open specification. These skills teach AI coding agents (Claude Code, GitHub Copilot, Cursor, Cline, and 30+ others) how to work with Dynatrace's observability platform.

The skills are **knowledge-only** — they contain DQL patterns, best practices, and semantic guidance, not executable code. They pair with **dtctl** (CLI) or the **Dynatrace MCP Server** for live query execution.

---

## Directory Structure

```
dynatrace-for-ai/
├── .claude-plugin/
│   └── marketplace.json          # Top-level plugin entry point
├── plugins/dynatrace/
│   ├── .claude-plugin/
│   │   └── plugin.json           # v0.2.0 descriptor
│   └── skills/                   # Symlinks → all 15 skills
├── skills/                       # 15 domain skill directories
│   ├── dt-dql-essentials/        # Core DQL syntax + pitfalls
│   ├── dt-obs-*/                 # 9 observability skills
│   ├── dt-app-*/                 # 2 platform app skills
│   └── dt-migration/             # Classic → Smartscape migration
├── prompts/                      # 6 reusable workflow templates
├── tests/
│   ├── run-all.sh
│   ├── test-structure.sh         # Plugin/symlink consistency
│   └── test-skill-quality.sh    # Frontmatter + naming validation
├── README.md
├── CONTRIBUTING.md
├── llms.txt                      # LLM-friendly context summary
└── LICENSE                       # Apache-2.0
```

---

## Skills Inventory (15 total)

### DQL & Query Language
| Skill | Purpose |
|-------|---------|
| `dt-dql-essentials` | Core syntax, field namespaces, operators, time alignment, smartscape topology, common pitfalls |

### Observability (9 skills)
| Skill | Purpose |
|-------|---------|
| `dt-obs-services` | RED metrics, runtime telemetry (Java/JVM, Node.js, .NET, Python, Go) |
| `dt-obs-frontends` | RUM, Web Vitals, user sessions, mobile crashes |
| `dt-obs-tracing` | Distributed traces, spans, service dependencies |
| `dt-obs-hosts` | Host/process CPU, memory, disk, network |
| `dt-obs-kubernetes` | K8s clusters, pods, nodes, workloads |
| `dt-obs-aws` | EC2, RDS, Lambda, ECS/EKS, VPC |
| `dt-obs-azure` | Azure resources |
| `dt-obs-gcp` | GCP resources |
| `dt-obs-logs` | Log queries, filtering, pattern matching, error rates |
| `dt-obs-problems` | DAVIS AI problems, root cause, blast radius |
| `dt-obs-predictive-analytics` | Forecasting, anomaly detection |

### Platform (2 skills)
| Skill | Purpose |
|-------|---------|
| `dt-app-dashboards` | Dashboard JSON, tiles, layouts, DQL integration |
| `dt-app-notebooks` | Notebook JSON sections, analytics workflows |

### Migration (1 skill)
| Skill | Purpose |
|-------|---------|
| `dt-migration` | Classic entity-based DQL → Smartscape modernization |

---

## How Skills Work — Progressive Disclosure

Each skill is a directory with exactly 2 components:

```
skills/dt-obs-problems/
├── SKILL.md          # YAML frontmatter + instructions (~5000 tokens)
└── references/       # Deep-dive topic files (loaded on demand)
    ├── problem-trending.md
    ├── problem-correlation.md
    ├── impact-analysis.md
    └── problem-merging.md
```

### 3-Phase Loading
| Phase | Tokens | What loads |
|-------|--------|-----------|
| Catalog | ~100 | name + description only (on agent startup) |
| Instructions | ≤5000 | Full SKILL.md (when agent selects skill) |
| Resources | 2000–10K | Reference files (on demand, per topic) |

This design lets agents install all 15 skills with **zero startup penalty** — loading only what's relevant to the current task.

### SKILL.md Frontmatter
```yaml
---
name: dt-obs-problems
description: DAVIS problem analysis including root cause identification, impact assessment...
license: Apache-2.0
---
```

Constraints enforced by CI:
- `description` ≤ 250 chars (Claude Code truncation warning)
- `description` ≤ 1024 chars (Agent Skills hard limit)
- `name` = kebab-case, max 64 chars, must match directory name
- No trailing whitespace

---

## Plugin System Architecture

### marketplace.json (top-level entry)
```json
{
  "name": "dynatrace-for-ai",
  "owner": { "name": "Dynatrace" },
  "plugins": [{ "name": "dynatrace", "source": "./plugins/dynatrace" }]
}
```

### plugin.json (Claude Code descriptor)
```json
{
  "name": "dynatrace",
  "version": "0.2.0",
  "description": "Dynatrace observability skills. DQL query patterns, application and infrastructure monitoring..."
}
```

### Symlink Architecture
`plugins/dynatrace/skills/` contains **symlinks** to all skills in the root `skills/` directory.  
Single source of truth — adding a skill to `skills/` and symlinking it is the only step needed for distribution.

---

## Naming Convention

Pattern: `dt-<domain>[-<usecase>]` (kebab-case)

Defined domains: `obs`, `appsec`, `biz`, `setup`, `migration`, `dql`, `sdlc`, `platform`, `fleet`

---

## Installation Models

| Method | Command |
|--------|---------|
| Claude Code marketplace | `claude plugin marketplace add dynatrace/dynatrace-for-ai` |
| Skills.sh (universal) | `npx skills add dynatrace/dynatrace-for-ai` |
| Manual | Copy skill dirs into `.claude/skills/`, `.cursor/skills/`, etc. |

---

## Quality Assurance (CI Tests)

### test-structure.sh
- Every skill dir has SKILL.md
- All skills symlinked in `plugins/dynatrace/skills/`
- `marketplace.json` valid and references dynatrace plugin
- Plugin source uses `./` prefix

### test-skill-quality.sh
- Frontmatter has `name`, `description`, `license`
- Name matches directory + valid kebab-case (≤64 chars)
- Description ≤250 chars (warning) / ≤1024 chars (error)
- No trailing whitespace

---

## Key Design Decisions

1. **Knowledge-only model** — No SDK/CLI in the repo; pairs with dtctl or MCP Server for execution
2. **Progressive disclosure** — Token-efficient; load only what the task needs
3. **Symlink mirror** — Single source of truth, automatic plugin sync
4. **Frontmatter validation** — Description limits enforce Claude Code UI clarity
5. **Reference modularization** — Deep docs in `references/`; core concepts in SKILL.md body
6. **Dynatrace-controlled maintenance** — Built internally, published via CI/CD; community contributes via GitHub Issues (do not edit `skills/` directly)
