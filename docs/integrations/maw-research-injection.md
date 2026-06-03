# MAW Research Injection for Tham Oracle

- injected_at: 20260521_184223
- source_kind: maw-rs
- source_path: /route/mission-control/backup/temp-time-load-doc/repos/maw-rs
- target: /home/user/ghq/github.com/E0993599799/tham-oracle

## Purpose
Integrate MAW operating knowledge into Tham-oracle as an orchestration memory/skill layer, not as a blind code overwrite.

## Observed MAW Pattern
- MAW is treated as a multi-agent workflow/oracle orchestration CLI.
- Core commands/patterns to preserve for Tham-oracle: wake agent, send/hey, peek screen, fleet/session detection, tmux-backed orchestration.
- Tham remains the brain/orchestrator; MAW is a local/WSL agent control substrate.

## Injection Contract
- Do not send raw human natural language directly to worker agents.
- Route through: Intent Decode -> Memory Gate -> Risk Gate -> Contract -> Executor Lane -> Proof -> Writeback.
- Prefer WSL paths:
  - mission-control: /route/mission-control
  - Tham-oracle: /home/user/ghq/github.com/E0993599799/tham-oracle
- Preserve proof logs under mission-control/tools/logs.

## Files Inspected
- .claude/INCUBATED_BY
- .git/HEAD
- .git/config
- .git/description
- .git/index
- .git/packed-refs
- .git/shallow
- .gitignore
- Cargo.lock
- Cargo.toml
- README.md

## README Excerpt
# maw-rs

[![CI](https://github.com/Soul-Brews-Studio/maw-rs/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Soul-Brews-Studio/maw-rs/actions/workflows/ci.yml)
![version](https://img.shields.io/badge/version-v0.1.0--alpha.1-blue)
![coverage](https://img.shields.io/badge/coverage-99.79%25-brightgreen)

Rust port of the maw-js portable core.

`maw-rs` is intentionally starting with deterministic, side-effect-free crates.
Each crate copies the same JSON fixture contract from `maw-js/test/spec/` and
must pass those fixtures in Rust before runtime IO, transports, or CLI commands
move over.

## Phase 1 status

Cargo workspace scaffolded and pushed to `main`.

| Crate | maw-js source | Portable fixture |
| --- | --- | --- |
| `maw-matcher` | `src/core/matcher/resolve-target.ts`, `normalize-target.ts` | `matcher-resolve-target.fixtures.json`, `normalize-target.fixtures.json` |
| `maw-calver` | `scripts/calver.ts` | `calver.fixtures.json` |
| `maw-policy` | `src/plugin/default-active.ts`, `src/plugin/tier.ts`, `src/plugin/manifest-constants.ts` | `plugin-policy.fixtures.json` |
| `maw-worktree` | `src/core/fleet/worktree-window-match.ts` | `worktree-window-match.fixtures.json` |
| `maw-transport` | `src/core/transport/transport.ts` | `transport-router.fixtures.json` |
| `maw-routing` | `src/core/routing.ts` | `routing.fixtures.json` |
| `maw-identity` | `src/core/fleet/session-name.ts`, `src/core/fleet/node-identity.ts`, `src/core/fleet/validate.ts` | `canonical-session-name.fixtures.json`, `canonical-node-identity.fixtures.json`, `test/validate-oracle-name.test.ts` |
| `maw-bring` | `src/commands/shared/bring-flags.ts` | `bring-to-flag.fixtures.json`, `bring-to-target.fixtures.json`, `bring-self-guard.fixtures.json` |
| `maw-split` | `src/vendor/mpr-plugins/split/impl.ts`, `src/commands/plugins/tmux/safety.ts` | `split-policy.fixtures.json` |
| `maw-peer` | `src/commands/shared/peer-sources.ts` | `peer-source-resolver.fixtures.json` |
| `maw-tmux` | `src/core/transport/tmux-class.ts`, `src/commands/shared/discover-live-state.ts` | tmux parser unit tests, `discover-tmux-live-state.fixtures.json` |
| `maw-hub` | `src/transports/hub-config.ts` | `test/isolated/hub-config.test.ts`, hub config loader coverage |
| `maw-feed` | `src/lib/feed.ts` | `test/isolated/feed-lib-coverage.test.ts` |
| `maw-auth` | `src/lib/federation-auth.ts` | federation auth pure helper and O6 decision tests |
| `maw-xdg` | `src/core/xdg.ts`, `src/core/paths.ts`, `src/cli/instance-preset.ts` | `test/core-xdg.test.ts`, `test/paths.test.ts`, `test/00-resolve-home.test.ts` |
| `maw-bind` | `src/core/bind-host.ts` | `test/bind-heuristic.test.ts` |
| `maw-fuzzy` | `src/core/util/fuzzy.ts` | `test/fuzzy-match.test.ts` |
| `maw-plugin-scaffold` | `src/commands/shared/plugin-create-scaffold.ts` | `test/plugin-create.test.ts` (pure validation/manifest cases) |
| `maw-plugin-manifest` | `src/plugin/manifest-validate.ts` | `test/plugin-manifest-validate-edges.test.ts` (cli/api validators) |

Current local gates:

```bash
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
```

## Phase 2 plan

1. Add side-effecting transport implementations behind the `maw-transport` policy:
   - tmux via the `tmux` CLI
   - HTTP federation via injectable IO first; runtime HTTP client wiring later
   - Zenoh via the Rust stylos/themion ecosystem
2. Add runtime adapters for fleet/worktree/session discovery around the pure crates.
3. Keep maw-js and maw-rs running side-by-side until command parity is proven.

## Phase 3 plan

1. Add a `maw-rs` CLI with `clap`.
2. Port high-value fast-path commands first: `ls`, `hey`, `peek`, and target resolution helpers.
3. Validate each command against maw-js fixtures or captured golden outputs before replacing any default `maw` entrypoint.

## Package/Cargo Excerpt
[workspace]
members = ["crates/maw-matcher", "crates/maw-calver", "crates/maw-policy", "crates/maw-worktree", "crates/maw-transport", "crates/maw-routing", "crates/maw-tmux", "crates/maw-identity", "crates/maw-bring", "crates/maw-split", "crates/maw-peer", "crates/maw-hub", "crates/maw-feed", "crates/maw-auth", "crates/maw-xdg", "crates/maw-bind", "crates/maw-fuzzy", "crates/maw-plugin-scaffold", "crates/maw-plugin-manifest", "crates/maw-cli", "crates/maw-auto-wake"]
resolver = "2"

[workspace.package]
edition = "2021"
license = "BUSL-1.1"
repository = "https://github.com/Soul-Brews-Studio/maw-rs"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
pedantic = { level = "warn", priority = -1 }
