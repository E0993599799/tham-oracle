---
delegation_id: CORE-20260520-HERMES-OLLAMA-CODEXAPP
timestamp: 2026-05-20T13:30:00Z
delegated_by: Tham Oracle
delegated_to: Core Agent (Windows/WSL Ollama+CodexApp lane)
status: active
revision: 4
---

# Mission: Hermes → Ollama → CodexApp Routing

## Problem Statement
- Hermes adapter must spawn and delegate to Codex model via CodexApp
- **Provider Chain: Hermes → Ollama → CodexApp**
- CodexApp is local application/service managing Codex model
- Windows/WSL environment

## Execution Contract

### Phase 1: Locate & Verify CodexApp
```bash
# Find CodexApp installation/service
find . -name "*codexapp*" -o -name "*codex-app*" -o -name "*CodexApp*" | head -20
grep -r "codex.app\|codexapp\|codex-app" . --include="*.sh" --include="*.json" --include="*.ps1" | head -20

# Check if CodexApp running as service/process
ps aux | grep -i codex
lsof -i :8000 2>/dev/null | head -5  # Common app port
lsof -i :5000 2>/dev/null | head -5
lsof -i :9000 2>/dev/null | head -5

# Check Windows services
Get-Service | grep -i codex  # If PowerShell available
```

### Phase 2: Get CodexApp Endpoint
```bash
# From CodexApp config/documentation
find . -name "*codex*config*" -o -name "*codexapp*.json" -o -name "*codexapp*.env"

# Check common locations
cat ~/.codexapp/config.json
cat ./codexapp/config.json
cat /opt/codexapp/config.json

# Look for API endpoint in code
grep -r "CODEXAPP.*URL\|CODEXAPP.*ENDPOINT\|CODEXAPP.*HOST\|CODEXAPP.*PORT" . --include="*.sh" --include="*.py" --include="*.json"

# Try common ports
curl http://localhost:8080/health
curl http://localhost:5000/health
curl http://localhost:3000/health
curl http://localhost:9000/api/health
```

### Phase 3: Configure Hermes for CodexApp via Ollama
```bash
# Set Ollama routing to CodexApp
export OLLAMA_CODEXAPP_URL="http://localhost:XXXX"  # Replace XXXX with CodexApp port
export HERMES_PROVIDER="ollama"
export HERMES_API_URL="http://localhost:11434"
export HERMES_MODEL="codex"
export HERMES_CODEX_BACKEND="codexapp"  # Tell Hermes Codex is via CodexApp

# Or update config files
cat > ~/.hermes/.env << 'EOF'
OLLAMA_API_URL=http://localhost:11434
OLLAMA_MODEL=codex
OLLAMA_CODEXAPP_BACKEND=true
CODEXAPP_URL=http://localhost:XXXX
EOF

# Source config
source ~/.hermes/.env
```

### Phase 4: Spawn & Test Hermes → CodexApp
```bash
# Spawn Hermes tmux session
bash scripts/spawn-agents-tmux.sh

# Test Hermes → Ollama → CodexApp chain
hermes chat -q "What is 2+2?" -m codex

# Manual test of CodexApp endpoint
curl -X POST http://localhost:XXXX/api/completions \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is 2+2?", "model": "codex"}'

# Verify routing chain
hermes status  # Should show: Hermes → Ollama → CodexApp
```

## Success Criteria
✅ CodexApp service found and running
✅ CodexApp endpoint responding (HTTP 200)
✅ Hermes configured for CodexApp routing via Ollama
✅ Test call succeeds (Hermes → Ollama → CodexApp → Codex response)
✅ Full chain verified: no API budget needed, local execution

## Proof Required
- CodexApp location & running status
- Endpoint URL + port
- Hermes environment config
- Test call output (full chain response)
- Process list showing all 3 components active
- Routing verification output

---

**Next**: Core locate CodexApp, identify endpoint, configure routing, test full chain.
