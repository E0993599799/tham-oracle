# MISSION: Codex CLI Fallback + Token-Limit Trigger Awake

**Date**: 2026-05-16 19:30 +0700  
**From**: ธาม (tham-oracle)  
**To**: Omega (Core agent)  
**Priority**: HIGH  
**Lane**: Windows PowerShell / WSL hybrid  

---

## Context — Research Findings

ธามได้ research มาแล้ว สรุปสำหรับ Omega:

| ข้อมูล | ผล |
|--------|-----|
| Codex CLI repo | https://github.com/openai/codex (Apache 2.0, public) |
| เวอร์ชันล่าสุด | v0.131.0-alpha.22 (15 พ.ค. 2026) |
| Wire API | Responses API เท่านั้น (ไม่ใช่ Chat Completions แล้วตั้งแต่ ม.ค. 2026) |
| Ollama routing | ต้องผ่าน `mimo2codex` proxy (แปลง Responses ↔ Chat Completions) |
| โมเดลที่ใช้ได้ | `qwen2.5-coder:7b` (มีอยู่แล้ว), `qwen3.5:latest` |
| Ollama base URL | `http://172.21.112.1:11434` (มีใน providers.json) |
| Token detection | header `anthropic-ratelimit-tokens-remaining` จาก Claude API |

**สรุป: ทำได้** — ผ่าน mimo2codex proxy + config.toml + trigger script

---

## TASK CONTRACT

### Task 1: Install mimo2codex proxy

**Target**: Windows (PowerShell) หรือ WSL  
**Action**: Clone + setup mimo2codex

```powershell
# Windows PowerShell
git clone https://github.com/7as0nch/mimo2codex
cd mimo2codex
pip install -r requirements.txt
# หรือถ้าเป็น Go/Rust binary ให้ build ตามที่ repo บอก
```

proxy ต้อง listen บน port เช่น `18080` แปลง Codex Responses API → Ollama Chat Completions

**Proof required**:
- `curl http://localhost:18080/health` → 200
- log แสดง proxy กำลัง run

---

### Task 2: Configure Codex CLI → Ollama

**Target**: `~/.codex/config.toml` (Windows: `%USERPROFILE%\.codex\config.toml`)

```toml
[model_providers.ollama_via_mimo]
name = "Ollama via mimo2codex"
base_url = "http://localhost:18080/v1"

[profiles.ollama_fallback]
model = "qwen2.5-coder:7b"
model_provider = "ollama_via_mimo"
```

**Install Codex CLI** (ถ้ายังไม่มี):
```powershell
npm install -g @openai/codex
# Verify:
codex --version
```

**Proof required**:
- `codex --profile ollama_fallback --help` → ไม่ error
- `codex --profile ollama_fallback "ทดสอบ ping"` → ได้ response จาก qwen2.5-coder

---

### Task 3: Token Watch + Trigger Awake Script

**สร้างไฟล์**: `scripts/token-watch/token-watcher.py`

Logic:
1. Monitor Claude API responses สำหรับ header `anthropic-ratelimit-tokens-remaining`
2. เมื่อ tokens remaining < THRESHOLD (default: 10,000) → trigger fallback
3. Fallback action:
   - ส่ง Telegram alert: `⚠️ Claude token ใกล้หมด — switching to Codex/Ollama fallback`
   - Write flag file: `/tmp/tham-fallback-active.json`
   - อัพเดท `~/.config/ai-providers/providers.json` → set `active: "ollama_codex"`
   - Start mimo2codex proxy ถ้ายังไม่ run

**สร้างไฟล์**: `scripts/token-watch/trigger-awake.sh`

```bash
#!/usr/bin/env bash
# Called when token limit approaching
THRESHOLD=${THAM_TOKEN_THRESHOLD:-10000}
NOTIFY_SCRIPT="scripts/telegram/notify.sh"

# Check current token remaining via Anthropic API
REMAINING=$(curl -s -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  "https://api.anthropic.com/v1/models" -I 2>/dev/null \
  | grep -i "anthropic-ratelimit-tokens-remaining" \
  | awk '{print $2}' | tr -d '[:space:]')

echo "Tokens remaining: $REMAINING"

if [ -n "$REMAINING" ] && [ "$REMAINING" -lt "$THRESHOLD" ] 2>/dev/null; then
  echo "⚠️ Token limit approaching ($REMAINING remaining) — activating fallback"
  
  # Write fallback state
  echo "{\"active\": true, \"reason\": \"token_limit\", \"remaining\": $REMAINING, \"at\": \"$(date -Iseconds)\"}" \
    > /tmp/tham-fallback-active.json
  
  # Telegram alert
  if [ -f "$NOTIFY_SCRIPT" ]; then
    bash "$NOTIFY_SCRIPT" custom "⚠️ <b>Token Limit Warning</b>
Claude tokens remaining: <code>$REMAINING</code>
Switching to Codex + Ollama fallback automatically.
Run /status to check provider health."
  fi
  
  # Start mimo2codex if not running
  if ! curl -sf http://localhost:18080/health >/dev/null 2>&1; then
    echo "Starting mimo2codex proxy..."
    # Omega: insert start command here based on actual install path
    # Example: cd ~/mimo2codex && python proxy.py --port 18080 &
  fi
else
  echo "✅ Tokens OK: $REMAINING"
  # Clear fallback flag if was active
  rm -f /tmp/tham-fallback-active.json
fi
```

**Cron / auto-trigger**: เพิ่มใน `scripts/telegram/setup-cron.sh`:
```bash
# Check token limit every 10 min
*/10 * * * * bash /root/ghq/github.com/E0993599799/tham-oracle/scripts/token-watch/trigger-awake.sh >> /tmp/tham-token-watch.log 2>&1
```

---

### Task 4: Dashboard Integration

**อัพเดท** `/api/forge-omega/providers/status/route.ts`:
- เพิ่ม fallback state จาก `/tmp/tham-fallback-active.json`
- แสดงใน Provider Activity: `event_type: config_changed`, message: `fallback activated`

**อัพเดท** Telegram bot `/tham` command:
- ถ้า `/tmp/tham-fallback-active.json` exists → prepend note ใน system prompt ว่าใช้ Ollama fallback

---

## Proof Required (ก่อน mark DONE)

- [ ] `mimo2codex` proxy running → `curl http://localhost:18080/health` = 200
- [ ] `codex --profile ollama_fallback "hello"` → response จาก qwen2.5-coder (ไม่ error)
- [ ] `trigger-awake.sh` run ได้ ไม่ crash
- [ ] Telegram alert ถูกส่งเมื่อ simulate token limit
- [ ] `/tmp/tham-fallback-active.json` เขียนได้ถูกต้อง
- [ ] Dashboard แสดง fallback status

---

## Notes for Omega

- Ollama base URL: `http://172.21.112.1:11434` (Windows host IP จาก WSL)
- mimo2codex repo: https://github.com/7as0nch/mimo2codex
- Codex context requirement: 64K min → set `num_ctx=65536` สำหรับ qwen2.5-coder:7b
- ถ้า mimo2codex ยาก → ลอง `qwen2.5-coder:7b` ผ่าน LiteLLM proxy แทน (LiteLLM รองรับ Responses API emulation)
- Codex CLI alpha: breaking changes บ่อย → pin version ที่ใช้ได้

---

## Writeback Target

เมื่อเสร็จ → write proof ไปที่:
- `brain/proofs/2026-05-16_codex-fallback.md`
- `ψ/outbox/codex-fallback-done.md`

**ACK**: Write `ψ/active/codex-fallback-mission-ack.md` เมื่อรับ mission
