# Skill: Hermes Adapter (v2 — Gemini 3.1 Pro)

## Purpose
Route specialist review, multimodal, or long-context tasks through Hermes (gemini/gemini-3.1-pro-preview via 9router/OpenClaw) when explicitly assigned by Tham. Never as default and never as Codex middleware.

## Rules
- **NEVER default route to Hermes** — only when Tham Executor Lane Router explicitly assigns
- Always send structured JSON task contract — no raw natural language
- Hermes routes through 9router (OpenClaw) at `http://172.21.112.1:20128/v1`
- Model: `gemini/gemini-3.1-pro-preview`
- Verify 9router is alive before invoking: `curl http://172.21.112.1:20128/v1/models`
- Watch for shim recursion — Hermes must not call itself
- For coding tasks Tham routes DIRECT to Codex GPT-5.5 at `50-tham:codex-gpt55` — do not relay through Hermes.

## When to Use
- Specialist review, multimodal, or long-context tasks
- Tasks where Gemini 3.1 Pro has demonstrated advantage
- Tasks explicitly routed here by Executor Lane Router decision

## When NOT to Use
- Default fallback when Claude is slow — use fast lane (glm-4.7-flash) instead
- Tasks Claude Sonnet/Haiku can handle fine
- Shortcutting past main execution lanes
- Any task without explicit route decision from Tham

## Invocation Contract
```json
{
  "lane": "hermes-optional",
  "task": "describe the task",
  "reason_for_hermes": "why hermes and not another lane",
  "structured_input": {},
  "expected_output": "what proof looks like",
  "proof_required": true
}
```

## Health Check
```bash
# Verify 9router is up
curl http://127.0.0.1:20128/v1/models | jq '.data[].id'

# Confirm minimax is available
curl http://127.0.0.1:20128/v1/models | jq '.data[] | select(.id | contains("minimax"))'
```

## Provider Config
- base_url: `http://172.21.112.1:20128/v1`
- api_key_env: `OPENCLAW_API_KEY`
- model: `gemini/gemini-3.1-pro-preview`
- Lane card: `configs/lane-cards/hermes-optional.json`
