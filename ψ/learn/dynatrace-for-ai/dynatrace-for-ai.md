# dynatrace-for-ai Learning Index

## Latest Exploration
**Date**: 2026-05-15

**Files**:
- [[2026-05-15_ARCHITECTURE|Architecture]] — Directory structure, skill system, plugin design, CI tests
- [[2026-05-15_CODE-SNIPPETS|Code Snippets]] — DQL syntax, problem queries, K8s patterns, prompt workflows
- [[2026-05-15_QUICK-REFERENCE|Quick Reference]] — Cheatsheet: skills list, prompts, install steps, DQL gotchas

## What It Is

Portable Agent Skills + Prompts that teach AI agents (Claude Code, Copilot, Cursor, 30+) how to use Dynatrace. Knowledge-only — pairs with **dtctl** or **Dynatrace MCP Server** for live queries.

## Timeline

### 2026-05-15 (First exploration)
- Initial discovery
- Core: progressive disclosure skill system (catalog → instructions → references)
- 15 skills across DQL, observability (9 domains), platform, migration
- 6 structured prompts for incident/health/regression workflows
- Plugin = symlinked skills + marketplace.json + plugin.json
- DQL is NOT SQL — array literals `{}`, `smartscapeNodes` for topology, `timeseries` for metrics
