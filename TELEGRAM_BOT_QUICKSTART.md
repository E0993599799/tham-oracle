# Telegram Bot Quick Start (Phase 5)

## Setup

### 1. Get Telegram Bot Token
Contact `@BotFather` on Telegram:
```
/start
/newbot
Choose a name: "Omega OS Bot" (or any name)
Choose a username: "my_omega_os_bot" (must be unique)
Copy the token: 123456789:ABCDefGHIjklmNOPqrstUVWxyz
```

### 2. Get Your Telegram User ID
Send a message to your bot, then check:
```bash
# In webhook logs
logs/telegram-bot.log
# Look for: user_id = 123456789
```

Or use `@userinfobot` on Telegram.

### 3. Start Services

#### Option A: All Users (No Whitelist)
```bash
export TELEGRAM_BOT_TOKEN='your-token'
bash server/run-telegram-services.sh
```

#### Option B: Specific Users Only
```bash
export TELEGRAM_BOT_TOKEN='your-token'
export TELEGRAM_AUTHORIZED_USERS='123456789,987654321'
bash server/run-telegram-services.sh
```

### 4. Set Webhook URL (Production Only)
```bash
export TELEGRAM_BOT_TOKEN='your-token'
export TELEGRAM_WEBHOOK_URL='https://your-server.com/webhook'
python3 server/telegram-bot.py
```

---

## Commands

### Bot Commands
```
/start          Bot introduction + command list
/status         Lane health (all 6 lanes with %)
/proofs         Last 5 proofs executed
/stats          Today's statistics
/dashboard      Full dashboard summary
/subscribe      Enable proof notifications
/unsubscribe    Disable notifications
/submit         Submit remote task
/tasks          List your submitted tasks
```

### Examples

#### /status
```
🟢 Lane Status

🟢 codex_gpt55            5 tasks,  100.0% success
🟡 claude                 3 tasks,   66.7% success
🟢 gemini                 4 tasks,  100.0% success
🔴 ollama                 2 tasks,    0.0% success
⚪ hermes                  0 tasks idle
🟡 powershell_sfsr        1 tasks,   50.0% success
```

#### /stats
```
📊 Daily Stats

Total: 15 tasks
✓ Success: 13 (86.7%)
⊘ Blocked: 1
✗ Error: 1
⏱ Timeout: 0
⌛ Avg Duration: 2.45s
```

#### /dashboard
```
📊 *Omega OS Dashboard*

*Overall Stats*
  Total: 15
  Success: 13 (86.7%)
  Avg Duration: 2.45s

*Lane Status*
🟢 codex_gpt55           5 (100%)
🟡 claude               3 (66%)
...
```

#### /submit write_code "Create function"
```
✓ Task submitted: telegram-writ-a1b2c3
Intent: write_code
Risk: medium

Task is in queue. Use /status to check progress.
```

#### /subscribe
```
✓ Subscribed to proof notifications
```

Then whenever a new proof is generated, you receive:
```
✓ telegram-writ-a1b2c3 → codex_gpt55 (SUCCESS, 3.2s)
```

---

## Files & Logs

### Service Files
```
server/telegram-bot.py              Main webhook + commands
server/proof-notifier.py            Proof monitor (background)
server/telegram-remote-executor.py  /submit handler
server/telegram-dashboard-bridge.py  Dashboard summaries
server/run-telegram-services.sh     Orchestrator
```

### Logs
```
logs/telegram-bot.log        Bot requests & responses
logs/proof-notifier.log      Proof monitoring
```

### State
```
ψ/state/telegram_subscribers.json    Subscribed user IDs
ψ/inbox/telegram/*.json              Submitted task contracts
```

---

## Architecture

### Message Flow
```
Telegram App
    ↓ (user types command)
Telegram API
    ↓ (webhook POST)
telegram-bot.py (port 8767)
    ├─ parse command
    ├─ handle_command()
    ├─ format response
    └─ send_message() → Telegram API
```

### Proof Notification Flow
```
executor-lane-router.py (Phase 1)
    ↓ (creates proof)
proofs/YYYY-MM-DD/task-id.json
    ↓ (file created)
proof-notifier.py (polls every 1s)
    ├─ detects new file
    ├─ batches notification
    ├─ load subscribers from bot state
    └─ send_message() to each subscriber → Telegram API
```

### Remote Task Submission
```
User: /submit write_code "Create validator"
    ↓
telegram-bot.py (handle /submit)
    ↓
telegram-remote-executor.py
    ├─ validate intent (write_code)
    ├─ create contract JSON
    └─ save to ψ/inbox/telegram/
    ↓
executor-lane-router.py (route contract)
    ↓
proofs/YYYY-MM-DD/telegram-writ-*.json
```

---

## Troubleshooting

### "ERROR: TELEGRAM_BOT_TOKEN not set"
```bash
export TELEGRAM_BOT_TOKEN='your-token'
```

### "⚠️ Rate limit exceeded"
Your account sent >30 messages in 60 seconds. Wait a minute before retrying.

### "❌ Unauthorized"
Your Telegram user ID is not in TELEGRAM_AUTHORIZED_USERS whitelist.
Check:
```bash
echo $TELEGRAM_AUTHORIZED_USERS
```

### Bot not responding
Check webhook server:
```bash
curl -s http://localhost:8767/health || echo "Server down"
```

Check logs:
```bash
tail -f logs/telegram-bot.log
```

### Notifications not working
Check:
1. Did you `/subscribe`?
2. Phase 4 API running? `curl -s http://localhost:8766/health`
3. New proofs being created? `ls -lh proofs/$(date +%Y-%m-%d)/ | head -5`

---

## Integration with Phase 4

Phase 5 works alongside Phase 4 (WebSocket Dashboard):

```bash
# Terminal 1: Start Phase 4 services
bash server/run-realtime-services.sh

# Terminal 2: Start Phase 5 services
export TELEGRAM_BOT_TOKEN='your-token'
bash server/run-telegram-services.sh
```

Both access the same proofs directory and dashboards.

---

## For Developers

### Add New Command
Edit `server/telegram-bot.py`:
```python
elif command == "newcommand":
    return self.new_handler()
```

Add handler method:
```python
def new_handler(self) -> str:
    return "Response text"
```

### Add Intent Validation
Edit `server/telegram-remote-executor.py`:
```python
VALID_INTENTS = {
    "write_code", "fix_bug", ... "new_intent"
}
```

### Modify Dashboard Summary
Edit `server/telegram-dashboard-bridge.py`:
```python
def format_dashboard_summary(self, force_refresh=False) -> str:
    # Update formatting here
```

---

## Production Notes

### Webhook URL Setup
For production, register with Telegram:
```bash
curl -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/setWebhook \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"https://your-domain.com/webhook\"}"
```

### Systemd Service
```ini
[Unit]
Description=Omega OS Telegram Bot
After=network.target

[Service]
Type=simple
User=tham
WorkingDirectory=/root/ghq/github.com/E0993599799/tham-oracle
Environment="TELEGRAM_BOT_TOKEN=..."
ExecStart=/bin/bash server/run-telegram-services.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Start:
```bash
sudo systemctl enable omega-telegram-bot.service
sudo systemctl start omega-telegram-bot.service
sudo journalctl -u omega-telegram-bot.service -f
```

---

## Performance

- **Message Send**: ~500ms (Telegram API latency)
- **Command Response**: <100ms (local processing)
- **Proof Notification**: <5s (batched every 5 seconds)
- **Dashboard Cache**: 10 seconds

---

## Security

- ✅ No secrets in code (token from env var)
- ✅ User whitelist enforced
- ✅ Rate limiting (30 msg/min per user)
- ✅ All API calls use HTTPS (Telegram official API)
- ✅ Contracts validated before saving

---

## Support

For issues:
1. Check logs: `tail -f logs/telegram-bot.log`
2. Check prerequisites: `curl http://localhost:8766/health`
3. Check Telegram API: send test message to @userinfobot
4. Check whitelist: `echo $TELEGRAM_AUTHORIZED_USERS`

---

**Ready to go?** → Send `/start` to your bot!
