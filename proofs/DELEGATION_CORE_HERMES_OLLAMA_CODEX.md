---
delegation_id: CORE-20260520-HERMES-OLLAMA-CODEX
timestamp: 2026-05-20T13:00:00Z
delegated_by: Tham Oracle
delegated_to: Core Agent (Windows/WSL Ollama lane)
status: active
revision: 3
---

# Mission: Hermes Spawn → Ollama Codex (Local Model)

## Problem Statement
- Hermes adapter must spawn and delegate to Codex model
- **Provider: Ollama** (local LLM runtime, no API budget needed)
- **Model: Codex** (pulled from Ollama registry)
- Windows/WSL environment

## Execution Contract

### Phase 1: Check Ollama Service
```bash
# Is Ollama running?
curl http://localhost:11434/api/tags 2>&1

# If running, list models
curl http://localhost:11434/api/tags | jq '.models[].name'

# If not running, start Ollama
# On Windows: ollama serve
# On WSL: ollama serve &
# Or check if service exists
ollama --version
which ollama
```

### Phase 2: Pull Codex Model (if not exists)
```bash
# Check if codex already pulled
curl http://localhost:11434/api/tags | grep -i codex

# If not, pull it
ollama pull codex

# Wait for download (~2-5 min depending on model size)
# Verify pulled
curl http://localhost:11434/api/tags | jq '.models[] | select(.name | contains("codex"))'
```

### Phase 3: Configure Hermes for Ollama
```bash
# Set Ollama as Hermes provider
export HERMES_PROVIDER="ollama"
export HERMES_API_URL="http://localhost:11434"
export HERMES_MODEL="codex"

# Or update .hermes config file
cat ~/.hermes/.env
# Should have:
# OLLAMA_API_URL=http://localhost:11434
# OLLAMA_MODEL=codex
```

### Phase 4: Spawn Hermes & Test
```bash
# Spawn Hermes tmux session (if not already running)
bash scripts/spawn-agents-tmux.sh

# Or activate existing Hermes pane
tmux send-keys -t tham-oracle-stack:5 "C-c"
tmux send-keys -t tham-oracle-stack:5 "source ~/.hermes/.env && hermes chat" C-m

# Test Hermes → Ollama call
hermes chat -q "What is 2+2?" -m codex

# Or manual curl test
curl http://localhost:11434/api/generate \
  -d '{
    "model": "codex",
    "prompt": "What is 2+2?",
    "stream": false
  }'
```

## Success Criteria
✅ Ollama service running (port 11434)
✅ Codex model pulled locally
✅ Hermes configured for Ollama endpoint
✅ Hermes → Codex call succeeds (test response)
✅ No API keys needed, no internet required

## Proof Required
- Ollama service status + model list
- Hermes environment config
- Test call output (Hermes → Codex response)
- Process list showing Ollama active
- No errors in execution

---

**Next**: Core execute all 4 phases, verify Hermes ↔ Ollama Codex working.
