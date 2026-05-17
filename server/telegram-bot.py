#!/usr/bin/env python3
"""
Phase 5A: Telegram Bot — Remote proof streaming and operations

Telegram bot that provides:
- Real-time proof notifications
- Lane health status
- Dashboard summaries
- Remote task submission

Usage: python3 server/telegram-bot.py
Requires: TELEGRAM_BOT_TOKEN, TELEGRAM_AUTHORIZED_USERS (env vars)
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict
import logging
import http.server
import socketserver
import urllib.request
import urllib.parse

# Import remote executor and dashboard bridge
try:
    from telegram_remote_executor import handle_submit, handle_list_tasks
except ImportError:
    def handle_submit(*args, **kwargs):
        return "⚠️ Remote executor not available"
    def handle_list_tasks(*args, **kwargs):
        return "⚠️ Remote executor not available"

try:
    from telegram_dashboard_bridge import get_dashboard_summary
except ImportError:
    def get_dashboard_summary(*args, **kwargs):
        return "⚠️ Dashboard bridge not available"

REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"
API_URL = "http://localhost:8766"
TELEGRAM_API_URL = "https://api.telegram.org/bot"

# Configuration
BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
WEBHOOK_URL = os.getenv('TELEGRAM_WEBHOOK_URL', 'http://localhost:8767')
AUTHORIZED_USERS = set(u.strip() for u in os.getenv('TELEGRAM_AUTHORIZED_USERS', '').split(',') if u.strip())

# Logging
os.makedirs("logs", exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/telegram-bot.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('telegram-bot')


class TelegramBot:
    """Telegram bot for Omega OS remote operations."""

    def __init__(self, bot_token):
        self.bot_token = bot_token
        self.subscribed_users = set()
        self.rate_limit = defaultdict(int)
        self.subscribed_file = REPO_ROOT / "ψ" / "state" / "telegram_subscribers.json"
        self.load_subscribers()

    def send_message(self, chat_id: str, text: str) -> bool:
        """Send message via Telegram API."""
        try:
            url = f"{TELEGRAM_API_URL}{self.bot_token}/sendMessage"
            data = urllib.parse.urlencode({
                'chat_id': chat_id,
                'text': text,
                'parse_mode': 'Markdown'
            }).encode('utf-8')

            req = urllib.request.Request(url, data=data)
            with urllib.request.urlopen(req, timeout=5) as response:
                result = json.loads(response.read().decode())
                if result.get('ok'):
                    return True
                logger.error(f"Telegram API error: {result.get('description')}")
                return False
        except Exception as e:
            logger.error(f"Failed to send message to {chat_id}: {e}")
            return False

    def load_subscribers(self):
        """Load subscribed users from file."""
        if self.subscribed_file.exists():
            try:
                with open(self.subscribed_file) as f:
                    self.subscribed_users = set(json.load(f))
            except (json.JSONDecodeError, IOError):
                pass

    def save_subscribers(self):
        """Save subscribed users to file."""
        self.subscribed_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.subscribed_file, 'w') as f:
            json.dump(list(self.subscribed_users), f)
    
    def format_status(self) -> str:
        """Format lane health status for Telegram."""
        # In production, this would call the API
        # For now, simulate from latest proofs
        
        text = "🟢 Lane Status\n\n"
        
        # Load today's proofs
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = PROOFS_DIR / today
        
        lane_stats = defaultdict(lambda: {"count": 0, "successful": 0})
        
        if today_dir.exists():
            for proof_file in today_dir.glob("*.json"):
                if proof_file.name.startswith("lane-health"):
                    continue
                try:
                    with open(proof_file) as f:
                        proof = json.load(f)
                    lane = proof.get("routed_lane", "unknown")
                    lane_stats[lane]["count"] += 1
                    if proof.get("status") == "SUCCESS":
                        lane_stats[lane]["successful"] += 1
                except (json.JSONDecodeError, IOError):
                    pass
        
        lanes = ["codex_gpt55", "claude", "gemini", "ollama", "hermes", "powershell_sfsr"]
        for lane in lanes:
            count = lane_stats[lane]["count"]
            successful = lane_stats[lane]["successful"]
            pct = (successful / count * 100) if count > 0 else 0
            
            status_emoji = "🟢" if pct >= 80 else "🟡" if pct >= 50 else "🔴"
            text += f"{status_emoji} {lane:20} {count:3} tasks, {pct:5.1f}% success\n"
        
        return text
    
    def format_proofs(self) -> str:
        """Format last 5 proofs for Telegram."""
        text = "📋 Recent Proofs\n\n"
        
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = PROOFS_DIR / today
        
        proofs = []
        if today_dir.exists():
            for proof_file in sorted(today_dir.glob("*.json"), reverse=True):
                if proof_file.name.startswith("lane-health"):
                    continue
                try:
                    with open(proof_file) as f:
                        proofs.append(json.load(f))
                except (json.JSONDecodeError, IOError):
                    pass
        
        for proof in proofs[:5]:
            task_id = proof.get("task_id", "unknown")[:20]
            lane = proof.get("routed_lane", "?")[:12]
            status = proof.get("status", "?")
            duration = proof.get("execution_duration_seconds", 0)
            
            emoji = "✓" if status == "SUCCESS" else "✗"
            text += f"{emoji} {task_id:20} → {lane:12} ({duration:.2f}s)\n"
        
        if not proofs:
            text += "(No proofs yet today)\n"
        
        return text
    
    def format_stats(self) -> str:
        """Format daily statistics for Telegram."""
        text = "📊 Daily Stats\n\n"
        
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = PROOFS_DIR / today
        
        if not today_dir.exists():
            text += "(No data yet)\n"
            return text
        
        proofs = []
        for proof_file in today_dir.glob("*.json"):
            if proof_file.name.startswith("lane-health"):
                continue
            try:
                with open(proof_file) as f:
                    proofs.append(json.load(f))
            except (json.JSONDecodeError, IOError):
                pass
        
        if not proofs:
            text += "(No proofs yet)\n"
            return text
        
        successful = sum(1 for p in proofs if p.get("status") == "SUCCESS")
        blocked = sum(1 for p in proofs if p.get("status") == "BLOCKED")
        error = sum(1 for p in proofs if p.get("status") == "ERROR")
        timeout = sum(1 for p in proofs if p.get("status") == "TIMEOUT")
        avg_duration = sum(p.get("execution_duration_seconds", 0) for p in proofs) / len(proofs)
        
        text += f"Total: {len(proofs)} tasks\n"
        text += f"✓ Success: {successful} ({successful/len(proofs)*100:.1f}%)\n"
        text += f"⊘ Blocked: {blocked}\n"
        text += f"✗ Error: {error}\n"
        text += f"⏱ Timeout: {timeout}\n"
        text += f"⌛ Avg Duration: {avg_duration:.2f}s\n"
        
        return text
    
    def handle_command(self, user_id: str, command: str, args: str = "") -> str:
        """Handle Telegram commands."""
        # Check authorization
        if user_id not in AUTHORIZED_USERS and AUTHORIZED_USERS:
            return "❌ Unauthorized. You are not in the whitelist."

        # Rate limiting: max 30 messages/minute per user
        self.rate_limit[user_id] += 1
        if self.rate_limit[user_id] > 30:
            return "⚠️  Rate limit exceeded (30/min). Please try again later."

        if command == "start":
            return (
                "🤖 Omega OS Remote Bot\n\n"
                "Commands:\n"
                "/status — Lane health\n"
                "/proofs — Last 5 proofs\n"
                "/stats — Daily summary\n"
                "/subscribe — Real-time notifications\n"
                "/unsubscribe — Disable notifications\n"
                "/dashboard — Dashboard link\n"
                "/submit <intent> <context> — Submit remote task\n"
                "/tasks — List your submitted tasks\n"
            )

        elif command == "status":
            return self.format_status()

        elif command == "proofs":
            return self.format_proofs()

        elif command == "stats":
            return self.format_stats()

        elif command == "subscribe":
            self.subscribed_users.add(user_id)
            self.save_subscribers()
            return "✓ Subscribed to proof notifications"

        elif command == "unsubscribe":
            self.subscribed_users.discard(user_id)
            self.save_subscribers()
            return "✓ Unsubscribed from proof notifications"

        elif command == "dashboard":
            summary = get_dashboard_summary()
            dashboard_path = REPO_ROOT / "dashboard" / "realtime-dashboard.html"
            return summary + f"\n\n[Open Dashboard]({dashboard_path.as_uri()})"

        elif command == "submit":
            return handle_submit(user_id, args)

        elif command == "tasks":
            return handle_list_tasks(user_id)

        else:
            return f"❌ Unknown command: /{command}"

    def broadcast_proof(self, proof: dict):
        """Send proof notification to all subscribed users."""
        task_id = proof.get("task_id", "unknown")
        lane = proof.get("routed_lane", "?")
        status = proof.get("status", "?")
        duration = proof.get("execution_duration_seconds", 0)

        emoji = "✓" if status == "SUCCESS" else "✗"
        text = f"{emoji} Task {task_id}\n→ {lane} ({status}, {duration:.1f}s)"

        for user_id in self.subscribed_users:
            self.send_message(user_id, text)


class WebhookHandler(http.server.BaseHTTPRequestHandler):
    """HTTP webhook handler for Telegram updates."""

    def do_POST(self):
        """Handle incoming Telegram update."""
        if self.path == "/webhook":
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                update = json.loads(body.decode())
                self.server.bot.handle_update(update)
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"ok": True}).encode())
            except Exception as e:
                logger.error(f"Error processing update: {e}")
                self.send_response(500)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


# Store bot instance globally for webhook handler
_bot_instance = None


def create_webhook_server(bot, port=8767):
    """Create HTTP webhook server."""
    handler = WebhookHandler
    handler_with_bot = type('BotWebhookHandler', (WebhookHandler,), {})

    server = socketserver.TCPServer(("localhost", port), handler_with_bot)
    server.bot = bot
    return server


def main():
    """Main bot entrypoint."""
    logger.info("🤖 Telegram Bot Initialization")

    # Check token
    if not BOT_TOKEN:
        logger.error("ERROR: TELEGRAM_BOT_TOKEN not set")
        logger.error("   Set: export TELEGRAM_BOT_TOKEN='your-token'")
        sys.exit(1)

    logger.info(f"✓ Bot token configured (first 10 chars: {BOT_TOKEN[:10]}...)")
    logger.info(f"✓ Webhook URL: {WEBHOOK_URL}")
    logger.info(f"✓ Authorized users: {AUTHORIZED_USERS if AUTHORIZED_USERS else 'All'}")

    # Initialize bot
    global _bot_instance
    bot = TelegramBot(BOT_TOKEN)
    _bot_instance = bot

    # Add handle_update to bot
    def handle_update(self, update):
        """Process incoming Telegram update."""
        try:
            if 'message' in update:
                msg = update['message']
                chat_id = str(msg.get('chat', {}).get('id', ''))
                user_id = str(msg.get('from', {}).get('id', ''))
                text = msg.get('text', '')

                if text.startswith('/'):
                    parts = text.split(None, 1)
                    command = parts[0][1:]
                    args = parts[1] if len(parts) > 1 else ''
                    response = self.handle_command(user_id, command, args)
                    self.send_message(chat_id, response)
        except Exception as e:
            logger.error(f"Error handling update: {e}")

    # Bind method to bot instance
    import types
    bot.handle_update = types.MethodType(handle_update, bot)

    # Start webhook server
    port = 8767
    server = create_webhook_server(bot, port)
    logger.info(f"✓ Starting webhook server on port {port}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
