# Skill: MAW Orchestration for Tham Oracle

Use this skill when พี่เอก asks Tham-oracle to control/wake/reuse/peek multi-agent sessions through MAW.

## Default Flow
1. Decode user intent.
2. Apply Memory Gate and Risk Gate.
3. Convert to an explicit task contract.
4. Use MAW only as executor/session substrate.
5. Capture proof and write back to mission-control/Obsidian when complete.

## WSL Defaults
- mission-control: /route/mission-control
- target oracle repo: /home/user/ghq/github.com/E0993599799/tham-oracle
- source researched: maw-rs at /route/mission-control/backup/temp-time-load-doc/repos/maw-rs

## Guardrails
- No blind overwrite of oracle code.
- No direct agent spawn without contract/proof.
- No foreground Windows CMD/PowerShell popup.
- If maw-rs is unavailable, use maw-js research only until maw-rs can be cloned.
