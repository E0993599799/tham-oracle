# Skill: OpenClaw / Ollama Router

## Purpose
Manage local model routing and inference providers.

## Baseline
- 9router/OpenClaw: http://127.0.0.1:20128/v1
- Ollama: http://127.0.0.1:11434

## Rules
- Probe ports before claiming online.
- Record model/base/provider.
- Avoid long-hang model calls.

