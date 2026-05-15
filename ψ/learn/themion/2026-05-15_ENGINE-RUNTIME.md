# Themion Engine Runtime — Learning Note

**Date**: 2026-05-15  
**Source**: https://raw.githubusercontent.com/tasanakorn/themion/main/docs/engine-runtime.md

---

## What This Document Describes

Themion is a Rust-based harness/runtime system that manages multi-agent AI orchestration within a single process. The engine-runtime doc explains how user turns flow through the system: prompt assembly, tool execution, workflow state mutation, session persistence, and multi-agent coordination. It covers both TUI (terminal UI) and headless execution modes, with explicit runtime domain ownership (TUI, core, network, background) and per-agent state management.

---

## Core Architecture Concepts

**Agent Identity & Separation**: Each `Agent` (in `themion-core`) owns harness state—session ID, project directory, workflow state, messages, model integration. The CLI layer owns process-local descriptors (agent_id, label, roles) for how agents operate within one process.

**Runtime Domain Topology**: Four explicit Tokio runtime domains handle different concern classes:
- **TUI**: Event intake, frame scheduling, terminal input (one worker thread)
- **Core**: Startup, agent-turn execution, orchestration
- **Network**: Stylos (remote) messaging and queries
- **Background**: Chat embedding, semantic indexing (runs only when agents idle)

**Turn Flow**: User input → record turn → build prompt (system + guardrails + context + history) → model streams → execute tools → append results → model again → finalize. Each turn tracks app_version, profile, provider, model in `agent_turns.meta`.

---

## Key Technical Patterns

**Budget-Aware Prompt Replay**: Uses tokenizer-backed estimation (tiktoken-rs) for accurate budget tracking. Keeps T0 (current turn) as highest priority, never replays turns older than T-7, degrades older turns to pure messages when token budget tight, and stops when hitting 250K ceiling.

**Per-Agent Queued Input**: When a target agent is busy, new user prompts queue on that agent rather than blocking. Queued prompts append to messages only when agent actually processes them, via FIFO drain during turn continuation.

**Unified-Search Background Embedding**: New chat messages register as "pending" in `unified_search_documents` at append time, but chunk generation and embedding happen only during idle windows—preventing I/O from blocking transcript writes.

**Workflow State Mutation**: Narrow patch-style tools (`workflow_get_state`, `workflow_set`) let agents inspect/mutate workflow between model calls—supporting activation, phase change, result update, status transitions.

**Stylos Remote Bridge**: Incoming remote requests (messages, board notes) inject into the same local input path as human input, with CLI-local admission policy (not TUI-local). Snapshot-based decisions on agent availability prevent race conditions.

---

## Application to Forge/Omega Orchestration

**Process-Local Multi-Agent**: Themion's per-agent queue and role-scoped prompts directly mirror Omega's local team model—multiple agents (master, interactive, executors) operating in one process without distributed overhead.

**Workflow State Coupling**: Themion's narrow `workflow_set` patch approach prevents conflicting mutations—a valuable constraint for Omega's mission/phase state (avoid simultaneous state overwrites).

**Background Indexing on Idle Windows**: Semantic search embedding during idle mirroring Omega's low-priority background tasks—schedule expensive work only when foreground agents pause.

**Headless + Network Domains**: Themion's explicit `network` domain for Stylos (remote) operations maps to Omega's external inbox/board intake—separate from core turn execution loop.

**Token Budget Tracking**: Themion's tokenizer-backed replay policy (T-7 window, 250K ceiling) provides concrete pattern for Omega memory management and context window safety.

---

## Actionable Insights

1. **Separate runtime domains explicitly** in Omega—avoid mixing TUI/core/network concerns. Each domain should own its admission policy and queueing.

2. **Implement per-agent input queues** for Omega executors receiving multiple delegated tasks. Don't block main executor waiting for first task to finish.

3. **Use snapshot-based decisions for remote routing**. Stylos's `activity_status` snapshot approach prevents race conditions when routing board notes or messages to local agents.

4. **Defer expensive background work to idle windows**. Apply Themion's embedding-deferred pattern to Omega's learning, semantic indexing, and cleanup tasks.

5. **Bound shell and file tool contracts** (fs_patch with unified diffs, bounded output/timeout). Themion's explicit limits prevent resource abuse and improve debuggability.

6. **Preserve turn-level metadata** (model, provider, profile, timestamp). Themion's `agent_turns.meta` tracks runtime decisions per turn—valuable for audit and replay.

---

## Summary

Themion's runtime is a process-local multi-agent harness with explicit runtime domain ownership, snapshot-driven remote routing, and budget-aware prompt management. Its patterns for per-agent queueing, background idle-only work, narrow workflow mutation, and bounded tool contracts offer direct templates for Omega's orchestration layer.
