# Omega Self-Evolution Folder Structure

> Phase 0/1 only • NOT RUN-PROVEN

```text
mission-control/
├── docs/
│   └── omega-self-evolution/
│       ├── README.md
│       ├── update-blueprint.phase0-1.md
│       ├── architecture.phase0-1.md
│       ├── folder-structure.md
│       ├── source-audit.md
│       └── automation-contracts.phase0-1.md
├── schemas/
│   └── omega-self-evolution/
│       ├── README.md
│       ├── task_trace.schema.json
│       ├── proof_artifact.schema.json
│       ├── failure_event.schema.json
│       ├── agent_scorecard.schema.json
│       ├── skill_candidate.schema.json
│       ├── skill_release.schema.json
│       ├── prompt_patch.schema.json
│       ├── memory_delta.schema.json
│       ├── automation_run.schema.json
│       └── weekly_capability_bet.schema.json
├── prompts/
│   └── omega-self-evolution/
│       └── README.md
├── skills/
│   └── omega-self-evolution/
│       └── README.md
├── data/
│   └── omega-self-evolution/
│       └── README.md
├── dashboards/
│   └── omega-self-evolution/
│       └── README.md
└── tools/
    ├── omega-self-evolution/
    │   └── README.md
    └── logs/
        └── omega-self-evolution/
            └── README.md
```

## Folder intent
- `docs/`: architecture, contracts, and human-readable blueprint
- `schemas/`: machine-readable contracts for traces, proofs, failures, scorecards
- `prompts/`: agent prompt templates for later phases
- `skills/`: promoted reusable procedures for later phases
- `data/`: seeded example data and fixture payloads
- `dashboards/`: dashboard design assets and future UI specs
- `tools/`: future runtime scripts and helpers
- `tools/logs/`: runtime logs and summaries when Phase 2+ exists

## Rule
Phase 0/1 must not create runtime behavior yet.
This tree is the contract, not the implementation.
