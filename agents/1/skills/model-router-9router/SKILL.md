# Skill: Model Router / 9router

## Purpose
Use local OpenAI-compatible routing through 9router/OpenClaw.

## Baseline
Base URL: http://127.0.0.1:20128/v1

## Rules
- Do not switch to 20129 unless explicitly requested.
- Check auth/header issues.
- Sanitize non-ASCII API key contamination.
- Prefer local routing when OpenRouter fails.

