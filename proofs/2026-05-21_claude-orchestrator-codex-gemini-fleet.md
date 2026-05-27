# Proof — Claude Orchestrator + Codex/Gemini Worker Fleet

Timestamp: 2026-05-21T20:06:46+07:00

## Intent

Configure `E0993599799/tham-oracle` so:

- Claude/Tham is the orchestrator.
- Spawned non-orchestrator agents use Codex or Gemini only.
- Previously established agent names are reused.
- Soul-Brews multi-agent patterns inform the config without cloning secrets or introducing new executors.

## Memory / Existing Names Reused

Reused active names:

- `tham`
- `core`
- `codex`
- `gemini`
- `bob`
- `housekeeper`
- `watchdog`

Legacy/manual-only:

- `hermes` — not spawned by default.

## Soul-Brews Repos Read

- `Soul-Brews-Studio/maw-js`: multi-agent terminal/tmux control with wake/hey/peek semantics.
- `Soul-Brews-Studio/multi-agent-workflow-kit`: `.agents/agents.yaml`, worktree mapping, tmux visibility.
- `Soul-Brews-Studio/oracle-framework`: external brain, memory/proof-first, no auto-actions.
- `Soul-Brews-Studio/arra-safety-hooks`: safety by enforceable hooks/config, especially no force push/destructive commands.
- `Soul-Brews-Studio/arra-oracle-skills-cli`: skills can target Claude Code, Codex, and Gemini CLI explicitly.

## Files Changed

- `.gitignore`
- `.claude/settings.json`
- `AGENTS.md`
- `.agents/agents.yaml`
- `configs/maw.config.json`
- `configs/agent-registry.json`
- `configs/pane-registry.json`
- `scripts/spawn-agents-tmux.sh`
- `proofs/2026-05-21_claude-orchestrator-codex-gemini-fleet.md`

## Validation Commands

```bash
python3 -m json.tool .claude/settings.json >/dev/null
python3 -m json.tool configs/maw.config.json >/dev/null
python3 -m json.tool configs/agent-registry.json >/dev/null
python3 -m json.tool configs/pane-registry.json >/dev/null
bash -n scripts/spawn-agents-tmux.sh
```

## Validation Result

Status: PASS

Observed output:

```text
VALIDATION_OK
```

Secret scan: PASS. Search hits were documentation words only (`secret`, `risk-gate`, `task-gate`); no literal credentials or API keys were added.

## Safety Notes

- No secrets added.
- No commit or push performed.
- Existing dirty files outside this task were not intentionally touched:
  - `configs/lane-cards/hermes-optional.json`
  - `skills/hermes-legacy-adapter/SKILL.md`
  - `docs/integrations/`
  - `skills/maw-rs-orchestration.skill.md`
- `scripts/spawn-agents-tmux.sh` defaults to label-only mode and requires explicit env flags to launch CLIs.

## Rollback

Use `git diff` to review, then selectively restore these files if needed. Do not use destructive reset/clean while unrelated user changes exist.
