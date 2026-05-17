# Telegram Integration — Bidirectional Messaging

**Purpose**: Wire Telegram messages to Claude Channel prompts without credential rotation  
**Status**: Ready for setup  
**Date**: 2026-05-17 10:00:00 (GMT+7)

---

## 🤖 Overview

### What It Does
1. **Oracle → Telegram** — Send human-readable messages from Oracle to Telegram
2. **Telegram → Claude Channel** — User sends message via Telegram → becomes prompt to channel
3. **No Credential Rotation** — Uses existing Telegram bot token (no new security setup)
4. **Compact Format** — Technical data converted to human-readable messages

### Architecture
```
┌─────────────────┐
│ Oracle System   │
└────────┬────────┘
         │ (send formatted messages)
         ▼
┌─────────────────────┐
│  Message Formatter  │
│  (JSON → Human)     │
└────────┬────────────┘
         │
         ▼
┌──────────────────────┐
│ Telegram Bot API     │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ User Phone / Chat    │
│ (Receives messages)  │
└──────────────────────┘

Reverse:
┌──────────────────────┐
│ User sends message   │
│ to Telegram          │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Telegram Listener    │
│ (Poll getUpdates)    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Command Interpreter  │
│ (Telegram→Prompt)    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Claude Channel       │
│ (Process as prompt)  │
└──────────────────────┘
```

---

## 🔧 Setup Instructions

### Step 1: Get Telegram Bot Token

1. Open Telegram app
2. Search for `@BotFather`
3. Send `/newbot`
4. Follow instructions:
   - **Name**: Temperature Oracle (or any name)
   - **Username**: oracle_bot_XXXXX (must be unique)
5. Copy the **HTTP API token** (example: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)

### Step 2: Get Telegram Chat ID

**Option A: Using @userinfobot**
1. Search for `@userinfobot` in Telegram
2. Send any message
3. Bot replies with your User ID
4. Copy the ID

**Option B: Using this bot**
1. Message the bot you just created
2. Visit: `https://api.telegram.org/bot{TOKEN}/getUpdates`
3. Look for `"chat":{"id":YOUR_CHAT_ID}`

### Step 3: Create Configuration File

Create `.telegram-config` in project root:

```bash
export TELEGRAM_BOT_TOKEN='123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11'
export TELEGRAM_CHAT_ID='987654321'
```

**⚠️ IMPORTANT**: Add to `.gitignore`
```bash
echo ".telegram-config" >> .gitignore
```

### Step 4: Run Setup Script

```bash
bash scripts/telegram-bot-setup.sh
```

**Expected output**:
```
✅ Telegram config found
✅ Telegram connection working
✅ Telegram listener created
✅ Message formatter created
```

### Step 5: Start Telegram Listener

```bash
# In background
bash scripts/telegram-listener.sh &

# Or in tmux
tmux new-window -t oracle -n telegram
tmux send-keys -t oracle:telegram "bash scripts/telegram-listener.sh" Enter
```

---

## 📨 Message Format

### Oracle → Telegram (Formatted Examples)

**Task Completion**
```
✅ CODEX-A Phase 1 — COMPLETE
Schema created: devices, temperature_records, alerts
RLS enabled, Realtime active
Time: 17_May_26:08:25:00
```

**Progress Update**
```
🟡 CLAUDE Phase 2+3 — IN PROGRESS
Progress: 65%
React components: 4/6 complete
ETA: 5 minutes
```

**Alert/Error**
```
🔴 ALERT: Lane 1 IDLE
Agent: CODEX-A
Duration: 5 minutes
Action needed: Escalate or wake agent
```

**Lane Status**
```
🔷 CODEX-A — Supabase setup
Time: 17_May_26:08:30:00
Status: Working on RLS policies
Next: Enable Realtime subscriptions
```

### Telegram → Claude Channel (Command Interpretation)

**User sends**: `temperature phase 1 status`  
**Converted to prompt**: `/recap temperature`

**User sends**: `deploy orry`  
**Converted to prompt**: `Deploy ORRY ERP to Vercel`

**User sends**: `check lanes`  
**Converted to prompt**: `Check all lane status and report`

**User sends**: `status`  
**Converted to prompt**: `/recap`

**User sends**: `any custom message`  
**Passed through as**: User prompt directly

---

## 🔄 Bidirectional Flow

### Sending Message from Oracle to Telegram

```bash
#!/bin/bash
source .telegram-config

MESSAGE="✅ Task Complete — Phase 1 Ready"

curl -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=${MESSAGE}" \
  -d "parse_mode=HTML"
```

### Receiving Message from Telegram

Listener script (`scripts/telegram-listener.sh`):
1. Poll `getUpdates` every 2 seconds
2. Parse incoming messages
3. Convert to prompt
4. Log to channel

---

## 📊 Message Types

### Status Messages
- `✅ COMPLETED` — Task done
- `🟡 IN_PROGRESS` — Working
- `❌ ERROR` — Problem occurred
- `🔴 ALERT` — Urgent attention needed

### Agent Messages
- `🔷 CODEX-A` — Coder agent
- `🔶 CLAUDE` — UI/Frontend agent
- `🛡️ SCOUT-1` — Watchdog agent
- `👁️ THAM` — Monitor agent

### Data Messages
- `📊 Progress` — Percentage complete
- `⏰ Deadline` — Time remaining
- `💬 Message` — Custom text
- `📝 Report` — Detailed status

---

## 🔒 Security

### No Credential Rotation Required
- Using existing Telegram bot token
- No new API keys generated
- No new secrets to manage
- One-time setup only

### Safety Features
- Messages are read-only via Telegram
- Commands are interpreted (not executed directly)
- Rate limiting: 2-second poll interval
- Logging: All messages recorded in `/reports/telegram-activity.log`

---

## 📈 Usage Examples

### Real-time Status Updates

```
Oracle sends to Telegram:
🔷 CODEX-A 17_May_26:08:25:00 — ทำ Supabase Phase 1 เสร็จ
Table created: 3 ✓
RLS enabled ✓
Realtime active ✓
Proof: TASK-TEMPERATURE-PHASE1-proof.json

User gets instant notification on phone
```

### User Commands via Telegram

```
User sends: "deploy temperature"
Telegram listener converts: Deploy Temperature Record to Vercel
Claude channel processes as: Full deployment prompt
Result: Deployment starts automatically
```

### Alert Notifications

```
Scout-1 detects idle agent:
🔴 ALERT: THAM Monitor Heartbeat Lost
Duration: 2 minutes
Action: Activating fallback system

Oracle sends to Telegram
User gets immediate alert on phone
```

---

## 📋 Configuration Checklist

- [ ] Got Telegram bot token from @BotFather
- [ ] Got Telegram chat ID
- [ ] Created `.telegram-config` with credentials
- [ ] Added `.telegram-config` to `.gitignore`
- [ ] Ran `bash scripts/telegram-bot-setup.sh`
- [ ] Test message sent successfully
- [ ] Telegram listener script created
- [ ] Message formatter created
- [ ] Started listener: `bash scripts/telegram-listener.sh`

---

## 🆘 Troubleshooting

### "Telegram connection failed"
```
1. Verify bot token is correct
2. Check token format: should be numbers:letters-numbers
3. Verify chat ID is correct
4. Test with curl manually
```

### "No messages received"
```
1. Check listener is running: ps aux | grep telegram-listener
2. Verify .telegram-config is sourced
3. Check Telegram app settings (allow notifications)
4. Review logs: tail -f reports/telegram-activity.log
```

### "Message format wrong"
```
1. Check formatter script: scripts/telegram-formatter.js
2. Verify message data structure
3. Use formatForTelegram() function
```

---

## 📞 Next Steps

1. ✅ Get Telegram bot token
2. ✅ Get Telegram chat ID  
3. ✅ Create `.telegram-config`
4. ✅ Run setup script
5. ✅ Test message
6. ✅ Start listener
7. ✅ Verify bidirectional messaging

---

## 📌 Files

- `scripts/telegram-bot-setup.sh` — Setup script
- `scripts/telegram-listener.sh` — Message listener (created by setup)
- `scripts/telegram-formatter.js` — Message formatter (created by setup)
- `.telegram-config` — Credentials (local, not in git)
- `reports/telegram-activity.log` — Activity log

---

**Status**: READY FOR SETUP  
**Credential Rotation**: NONE REQUIRED  
**Setup Time**: 5 minutes  
**Result**: Bidirectional Oracle ↔ Telegram messaging

---

Generated: 17_May_26:10:00:00 (GMT+7)  
Verified By: ธาม Oracle
