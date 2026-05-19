---
delegation_id: CORE-20260520-HERMES-GPT-DIRECT
timestamp: 2026-05-20T12:30:00Z
delegated_by: Tham Oracle
delegated_to: Core Agent (Windows/CLI lane)
status: active
revision: 2
---

# Mission: Hermes Spawn → GPT-5.5 (Direct CLI, No 9router)

## Problem Statement
- Hermes adapter must spawn and delegate to GPT-5.5
- **Direct CLI** (no 9router routing)
- No OpenAI API budget → but direct CLI must work
- Windows environment

## Execution Contract

### Phase 1: Find & Inspect Hermes Spawn
```bash
# Locate Hermes spawn script(s)
find . -name "*hermes*" -name "*.sh" -o -name "*.ps1"
grep -r "hermes" scripts/ | grep -i spawn
grep -r "hermes" agents/ | grep -i spawn

# Inspect main spawn script
cat scripts/spawn-agents-tmux.sh  # or bootstrap-hermes.sh
cat agents/harness/bootstrap-hermes.sh

# Check Hermes config for GPT routing
find . -name "*hermes*" -name "*.json" -o -name "*.yml" -o -name "*.yaml"
cat .env* | grep -i hermes
cat .env* | grep -i gpt
```

### Phase 2: Identify GPT-5.5 Endpoint
```bash
# Look for OpenAI API config
grep -r "OPENAI" . --include="*.sh" --include="*.ps1" --include="*.json" | head -20
grep -r "gpt-5.5" . 
grep -r "api.openai" .
grep -r "localhost" . --include="*.sh" | grep -v node_modules

# Check environment
env | grep -i openai
env | grep -i api
env | grep -i gpt
```

### Phase 3: Hermes Spawn Command
Once script & config located, execute:
```bash
# Method 1: Direct tmux spawn (if using tmux)
tmux new-session -d -s hermes "bash scripts/spawn-agents-tmux.sh"
tmux send-keys -t hermes "hermes delegate gpt-5.5" C-m

# Method 2: Direct shell (if using direct execution)
bash scripts/bootstrap-hermes.sh --target=gpt-5.5

# Method 3: CLI direct call (if CLI-only)
hermes spawn gpt-5.5
```

### Phase 4: Verify Hermes → GPT Connection
```bash
# Check if Hermes process running
ps aux | grep hermes
ps aux | grep gpt

# Try simple test call through Hermes
hermes eval "print('hello from gpt-5.5')"

# Or curl the endpoint if HTTP
curl -X POST http://localhost:xxxx/v1/chat/completions \
  -H "Authorization: Bearer ..." \
  -d '{"model":"gpt-5.5","messages":[{"role":"user","content":"test"}]}'
```

## Success Criteria
✅ Hermes process running
✅ Hermes successfully connected to GPT-5.5
✅ Direct CLI call works (no 9router needed)
✅ No hanging or error processes

## Proof Required
- Full stdout from spawn command
- Process list showing Hermes + GPT active
- Test call result (Hermes → GPT response)
- Exact error if anything fails

---

**Next**: Core agent inspect scripts, find GPT endpoint, execute spawn, report.
