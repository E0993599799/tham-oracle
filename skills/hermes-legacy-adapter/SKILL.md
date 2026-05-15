# Skill: Hermes Legacy Adapter

## Purpose
Route specialist/legacy tasks through Hermes (minimax-m2.5 via 9router/OpenClaw) when explicitly assigned by Executor Lane Router. Never as default.

## Rules
- **NEVER default route to Hermes** — only when Tham Executor Lane Router explicitly assigns
- Always send structured JSON task contract — no raw natural language
- Hermes routes through 9router (OpenClaw) at `http://127.0.0.1:20128/v1` — NOT direct Ollama
- Model: `ollama/minimax-m2.5`
- Verify 9router is alive before invoking: `curl http://127.0.0.1:20128/v1/models`
- Watch for shim recursion — Hermes must not call itself
- Watch for missing model — confirm minimax-m2.5 is loaded in Ollama

## When to Use
- Legacy API compatibility requiring non-Claude model
- Specialist tasks where minimax-m2.5 has demonstrated advantage
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
- base_url: `http://127.0.0.1:20128/v1`
- api_key_env: `OPENCLAW_API_KEY`
- model: `ollama/minimax-m2.5`
- Lane card: `configs/lane-cards/hermes-optional.json`
