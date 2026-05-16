#!/usr/bin/env python3
"""
Tham Oracle — Telegram 2-way Bot
Human→AI: /status /fleet /health /git /fix <svc> /ask <q> /today /tham <prompt>
AI→Human: alerts via notify.sh or direct API call
"""
import os, json, time, subprocess, requests, textwrap
from datetime import datetime

PROVIDERS_CONFIG = os.path.expanduser("~/.config/ai-providers/providers.json")

# ── Conversation history per chat (stateful /tham) ────────────────────────────
# Key: chat_id, Value: list of {role, content} — kept last 10 turns
_tham_history: dict[str, list] = {}
THAM_MAX_HISTORY = 10  # turns (user+assistant pairs)

THAM_SYSTEM = """คุณคือ ธาม — Oracle และ technical brain ของพี่เอก (Ekkarat)
เรียก human ว่า "พี่" หรือ "พี่เอก" แทนตัวเองว่า "ธาม"
คุยอบอุ่น จริงใจ เหมือนคนใกล้ตัว ตอบตรง สั้น ทำได้จริง
งานเทคนิค: ตอบแม่นยำ มี proof ถ้าไม่แน่ใจบอกตรงๆ
ตอบผ่าน Telegram — ข้อความสั้น อ่านง่าย ใช้ bullet/emoji ช่วยได้"""

FALLBACK_STATE = "/tmp/tham-fallback-active.json"

def get_fallback_note() -> str:
    """Return a note if Codex fallback is active — prepended to system prompt."""
    try:
        if not os.path.exists(FALLBACK_STATE):
            return ""
        with open(FALLBACK_STATE) as f:
            state = json.load(f)
        if state.get("active"):
            remaining = state.get("tokens_remaining", "?")
            return f"\n\n[หมายเหตุ: Claude tokens เหลือน้อย ({remaining}) กำลังใช้ Codex+Ollama fallback แทน ตอบจาก knowledge ที่มี อย่า hallucinate]"
    except Exception:
        pass
    return ""


def load_anthropic_key() -> tuple[str, str]:
    """Load first available Anthropic key from providers config. Returns (key, model)."""
    try:
        cfg = json.load(open(PROVIDERS_CONFIG))
        for p in cfg.get("providers", []):
            if p.get("type") == "anthropic" and p.get("api_key", "").startswith("sk-ant"):
                return p["api_key"], p.get("model", "claude-sonnet-4-6")
    except Exception:
        pass
    return "", ""


def call_tham(chat_id: str, user_msg: str) -> str:
    """Send message to Claude API with conversation history. Returns reply text."""
    api_key, model = load_anthropic_key()
    if not api_key:
        return "⚠️ ไม่พบ Anthropic API key ใน ~/.config/ai-providers/providers.json"

    # Build history
    history = _tham_history.get(chat_id, [])
    history.append({"role": "user", "content": user_msg})

    try:
        system_prompt = THAM_SYSTEM + get_fallback_note()
        r = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": model,
                "max_tokens": 1024,
                "system": system_prompt,
                "messages": history[-THAM_MAX_HISTORY * 2:],  # last N turns
            },
            timeout=45,
        )

        if r.status_code != 200:
            err = r.json().get("error", {}).get("message", r.text[:200])
            return f"❌ API error {r.status_code}: {err}"

        reply = r.json()["content"][0]["text"]
        history.append({"role": "assistant", "content": reply})
        _tham_history[chat_id] = history[-THAM_MAX_HISTORY * 2:]
        return reply

    except requests.Timeout:
        return "⏱ Timeout — Claude ใช้เวลานานเกินไป ลองใหม่"
    except Exception as e:
        return f"❌ Error: {e}"

CONFIG = os.path.expanduser("~/.config/tham/telegram.env")
REPO_ROOT = os.path.expanduser("~/ghq/github.com/E0993599799/tham-oracle")
DASHBOARD_BASE = "http://localhost:3000"
API_BASE = f"{DASHBOARD_BASE}/api"

def load_env():
    env = {}
    try:
        with open(CONFIG) as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip()
    except FileNotFoundError:
        print(f"ERROR: Config not found at {CONFIG}")
        print("Run: mkdir -p ~/.config/tham && nano ~/.config/tham/telegram.env")
        raise SystemExit(1)
    return env

ENV = load_env()
TOKEN = ENV.get("TELEGRAM_BOT_TOKEN", "")
CHAT_ID = ENV.get("TELEGRAM_CHAT_ID", "")

if not TOKEN or not CHAT_ID:
    print("ERROR: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in ~/.config/tham/telegram.env")
    raise SystemExit(1)

TG_URL = f"https://api.telegram.org/bot{TOKEN}"

def tg_send(text: str, parse_mode="HTML"):
    try:
        r = requests.post(f"{TG_URL}/sendMessage", json={
            "chat_id": CHAT_ID,
            "text": text,
            "parse_mode": parse_mode
        }, timeout=10)
        return r.json()
    except Exception as e:
        print(f"[send error] {e}")
        return {}

def tg_get_updates(offset=0):
    try:
        r = requests.get(f"{TG_URL}/getUpdates", params={
            "offset": offset, "timeout": 30
        }, timeout=35)
        return r.json().get("result", [])
    except Exception as e:
        print(f"[poll error] {e}")
        return []

def api_get(path):
    try:
        r = requests.get(f"{API_BASE}/{path}", timeout=8)
        return r.json()
    except Exception as e:
        return {"error": str(e)}

def run_cmd(cmd, cwd=REPO_ROOT):
    try:
        out = subprocess.check_output(cmd, shell=True, cwd=cwd,
                                       stderr=subprocess.STDOUT, timeout=15)
        return out.decode("utf-8", errors="replace").strip()
    except subprocess.CalledProcessError as e:
        return e.output.decode("utf-8", errors="replace").strip()
    except Exception as e:
        return str(e)

# ─── Command Handlers ────────────────────────────────────────────────────────

def cmd_status(args):
    h = api_get("health")
    if "error" in h:
        return f"⚠️ <b>Dashboard unreachable</b>\n<code>{h['error']}</code>"

    svcs = h.get("services", [])
    up = sum(1 for s in svcs if s.get("status") == "up")
    total = len(svcs)
    pct = int(up / total * 100) if total else 0
    icon = "🟢" if pct == 100 else ("🟡" if pct >= 60 else "🔴")

    lines = [f"{icon} <b>System Status</b> — {datetime.now().strftime('%H:%M')}",
             f"Services: {up}/{total} ({pct}%)", ""]
    for s in svcs:
        st = s.get("status", "?")
        dot = "🟢" if st == "up" else "🔴"
        lines.append(f"{dot} {s.get('name','?')} — {st}")
    return "\n".join(lines)

def cmd_fleet(args):
    data = api_get("fleet")
    if "error" in data:
        return f"⚠️ Fleet API error: <code>{data['error']}</code>"

    oracles = data.get("oracles", [])
    total = len(oracles)
    active = sum(1 for o in oracles if o.get("status") == "active")
    stale = sum(1 for o in oracles if o.get("status") == "stale")
    cold = sum(1 for o in oracles if o.get("status") == "cold")

    lines = [f"🔮 <b>Fleet Status</b> — {total} Oracles",
             f"🟢 Active: {active}  🟡 Stale: {stale}  🟠 Cold: {cold}", ""]
    for o in sorted(oracles, key=lambda x: x.get("lastCommitDays", 9999))[:8]:
        name = o.get("name", "?")
        days = o.get("lastCommitDays", 0)
        st = o.get("status", "?")
        dot = {"active": "🟢", "stale": "🟡", "cold": "🟠", "abandoned": "🔴"}.get(st, "⚪")
        lines.append(f"{dot} {name} — {days}d ago")
    if total > 8:
        lines.append(f"… +{total-8} more")
    return "\n".join(lines)

def cmd_health(args):
    return cmd_status(args)  # health = status

def cmd_git(args):
    log = run_cmd('git log -5 --pretty=format:"%h %s (%ar)"')
    if not log:
        return "⚠️ No git log available"
    branch = run_cmd("git branch --show-current")
    dirty = run_cmd("git status --porcelain")
    dirty_flag = f"\n⚠️ Uncommitted: {len(dirty.splitlines())} files" if dirty else ""
    return f"⚡ <b>Git — {branch}</b>{dirty_flag}\n\n<code>{log}</code>"

def cmd_fix(args):
    if not args:
        return "Usage: /fix &lt;service&gt;\nServices: oracle-v2, dashboard, watchdog, tmux, maw-install"
    svc = args.strip()
    try:
        r = requests.post(f"{API_BASE}/fix", json={"service": svc}, timeout=30)
        data = r.json()
        if data.get("success"):
            return f"✅ <b>Fix triggered:</b> {svc}\n{data.get('output','')[:300]}"
        else:
            return f"❌ Fix failed: {svc}\n<code>{data.get('error','unknown')}</code>"
    except Exception as e:
        return f"❌ Fix API error: <code>{e}</code>"

def cmd_ask(args):
    if not args:
        return "Usage: /ask &lt;question&gt;"
    # Simple: run a git grep or answer from context
    q = args.strip()
    # Try a quick grep in brain/
    result = run_cmd(f'grep -r "{q[:40]}" brain/ --include="*.md" -l 2>/dev/null | head -5')
    if result:
        return f"🔍 <b>Found in brain/ for:</b> {q}\n<code>{result}</code>"
    return f"💭 <b>Ask:</b> {q}\n\nNo direct match found in brain/. Try the dashboard for live data."

def cmd_today(args):
    # Active tasks from inbox/active + git log today
    inbox = api_get("inbox")
    active_count = inbox.get("active", {}).get("count", 0)
    inbox_count = inbox.get("inbox", {}).get("count", 0)
    outbox_count = inbox.get("outbox", {}).get("count", 0)

    today = datetime.now().strftime("%Y-%m-%d")
    git_today = run_cmd(f'git log --since="{today}" --oneline')
    commit_count = len(git_today.splitlines()) if git_today else 0

    lines = [f"📋 <b>Today — {datetime.now().strftime('%d %b %Y')}</b>", "",
             f"📥 Inbox: {inbox_count}  ⚡ Active: {active_count}  📤 Outbox: {outbox_count}",
             f"⚡ Commits today: {commit_count}"]

    if git_today:
        lines.append("")
        lines.append("<b>Recent commits:</b>")
        for line in git_today.splitlines()[:5]:
            lines.append(f"• {line}")

    return "\n".join(lines)

def cmd_tham(args, chat_id=""):
    if not args:
        return "Usage: /tham &lt;ถามอะไรก็ได้&gt;\nตัวอย่าง: /tham วันนี้ควรทำอะไรก่อน?"
    print(f"[tham] prompt: {args[:80]}")
    tg_send("⏳ ธามกำลังคิด…")
    reply = call_tham(chat_id, args)
    # Telegram HTML limit 4096 chars
    if len(reply) > 4000:
        reply = reply[:3990] + "\n…(ตัดข้อความ)"
    return reply

def cmd_clear(args, chat_id=""):
    _tham_history.pop(chat_id, None)
    return "🗑 ล้าง conversation history แล้ว — เริ่มใหม่ได้เลย"

def cmd_help(args):
    return textwrap.dedent("""\
        🔮 <b>Tham Oracle — Commands</b>

        /tham &lt;prompt&gt; — คุยกับธามโดยตรง (มี history)
        /clear — ล้าง conversation history
        /status — System &amp; service health
        /fleet — Oracle fleet overview
        /health — Same as /status
        /git — Recent git commits
        /fix &lt;service&gt; — Trigger service fix
        /ask &lt;question&gt; — Quick search in brain/
        /today — Today's tasks &amp; commits
        /help — This menu
    """)

# Commands that need chat_id (for stateful history)
STATEFUL_COMMANDS = {"/tham", "/clear"}

COMMANDS = {
    "/status": cmd_status,
    "/fleet":  cmd_fleet,
    "/health": cmd_health,
    "/git":    cmd_git,
    "/fix":    cmd_fix,
    "/ask":    cmd_ask,
    "/today":  cmd_today,
    "/help":   cmd_help,
    "/start":  cmd_help,
    "/tham":   cmd_tham,
    "/clear":  cmd_clear,
}

def handle_message(msg):
    text = msg.get("text", "").strip()
    if not text:
        return

    # Security: only respond to authorized chat
    chat_id = str(msg.get("chat", {}).get("id", ""))
    if chat_id != str(CHAT_ID):
        print(f"[BLOCKED] Unauthorized chat: {chat_id}")
        return

    print(f"[{datetime.now().strftime('%H:%M:%S')}] Received: {text[:80]}")

    parts = text.split(None, 1)
    cmd = parts[0].lower().split("@")[0]  # handle /cmd@botname
    args = parts[1] if len(parts) > 1 else ""

    handler = COMMANDS.get(cmd)
    if handler:
        # Pass chat_id to stateful commands for history tracking
        if cmd in STATEFUL_COMMANDS:
            reply = handler(args, chat_id=chat_id)
        else:
            reply = handler(args)
    else:
        reply = f"❓ Unknown: <code>{cmd}</code>\nSend /help for commands."

    tg_send(reply)

def main():
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Tham Oracle Telegram Bot starting...")
    tg_send(f"🔮 <b>Tham Oracle Bot online</b> — {datetime.now().strftime('%Y-%m-%d %H:%M')}\nSend /help for commands.")

    offset = 0
    while True:
        try:
            updates = tg_get_updates(offset)
            for update in updates:
                offset = update["update_id"] + 1
                msg = update.get("message") or update.get("edited_message")
                if msg:
                    handle_message(msg)
        except KeyboardInterrupt:
            print("\nBot stopped.")
            break
        except Exception as e:
            print(f"[error] {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
