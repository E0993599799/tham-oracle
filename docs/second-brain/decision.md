# Second Brain Decision

## Goal
Build a low-token, practical second brain for this repo that helps humans and agents understand the codebase quickly.

## Options studied

### 1) Understand-Anything style graph system
- Tree-sitter/static analysis scans files, functions, classes, imports.
- LLM adds semantic labels, tours, impact analysis, and role-aware views.
- Strong for large repositories and onboarding.

Cost profile:
- Implementation effort: high
- Runtime cost: medium to high
- Token use: medium unless aggressively cached
- Maintenance: higher, because the semantic layer can drift

### 2) HTML second brain
- Static HTML UI over a precomputed index.
- Search, backlinks, guided tour, and node detail panes.
- Can be opened instantly, shared, and versioned with git.

Cost profile:
- Implementation effort: low to medium
- Runtime cost: very low
- Token use: low
- Maintenance: low

## Selected implementation
Use a hybrid approach:
- Python indexer builds a compact code graph and metadata JSON.
- HTML renders the second brain and lets the user inspect/search it.
- LLM is optional and only used offline or during index enrichment, not in the hot path.

Why this wins:
- Lowest cost per useful insight.
- Works offline and in local repo context.
- Easy to extend later into a richer Understand-Anything experience.
- Good fit for this repo’s existing dashboard-first workflow.

## Practical decision
Implement the hybrid index + HTML brain first.
If semantic tours or business-logic mapping are needed later, add them as enrichment layers on top of the same index rather than replacing the UI.
