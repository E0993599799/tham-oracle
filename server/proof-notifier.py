#!/usr/bin/env python3
"""
Phase 5B: Proof Notifier — Monitor proofs and send Telegram notifications

Watches proofs/YYYY-MM-DD/ directory for new proof files and sends
notifications to subscribed Telegram users.

Usage: python3 server/proof-notifier.py
"""

import json
import os
import sys
import time
import logging
from pathlib import Path
from datetime import datetime
from collections import deque
import urllib.request
import urllib.parse

REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"
TELEGRAM_API_URL = "https://api.telegram.org/bot"
BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')

# Logging
os.makedirs("logs", exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/proof-notifier.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('proof-notifier')


class ProofNotifier:
    """Monitor proofs directory and send Telegram notifications."""

    def __init__(self, bot_token):
        self.bot_token = bot_token
        self.seen_proofs = set()
        self.batch_queue = deque()
        self.batch_timeout = 5
        self.last_batch_time = time.time()
        self.subscribers = []
        self.load_subscribers()

    def load_subscribers(self):
        """Load subscribed users from telegram-bot state."""
        subscribers_file = REPO_ROOT / "ψ" / "state" / "telegram_subscribers.json"
        if subscribers_file.exists():
            try:
                with open(subscribers_file) as f:
                    self.subscribers = json.load(f)
                logger.info(f"Loaded {len(self.subscribers)} subscribers")
            except (json.JSONDecodeError, IOError) as e:
                logger.error(f"Failed to load subscribers: {e}")

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
                return result.get('ok', False)
        except Exception as e:
            logger.error(f"Failed to send message to {chat_id}: {e}")
            return False

    def format_proof_notification(self, proof: dict) -> str:
        """Format proof as notification message."""
        task_id = proof.get("task_id", "unknown")
        lane = proof.get("routed_lane", "?")
        status = proof.get("status", "?")
        duration = proof.get("execution_duration_seconds", 0)

        emoji = "✓" if status == "SUCCESS" else "✗" if status == "ERROR" else "⏸"
        return f"{emoji} {task_id} → {lane} ({status}, {duration:.1f}s)"

    def broadcast_notification(self, text: str):
        """Send notification to all subscribed users."""
        for user_id in self.subscribers:
            self.send_message(user_id, text)

    def check_new_proofs(self):
        """Poll proofs directory for new files."""
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = PROOFS_DIR / today

        if not today_dir.exists():
            return

        for proof_file in today_dir.glob("*.json"):
            # Skip health-check files
            if proof_file.name.startswith("lane-health"):
                continue

            # Skip already-seen proofs
            if proof_file.name in self.seen_proofs:
                continue

            try:
                with open(proof_file) as f:
                    proof = json.load(f)

                # Validate proof structure
                if not proof.get("task_id"):
                    continue

                self.seen_proofs.add(proof_file.name)
                self.batch_queue.append(proof)
                logger.info(f"Detected new proof: {proof_file.name}")

            except (json.JSONDecodeError, IOError) as e:
                logger.error(f"Failed to read {proof_file.name}: {e}")

    def flush_batch(self):
        """Send batched notifications."""
        if not self.batch_queue:
            return

        notifications = []
        while self.batch_queue:
            proof = self.batch_queue.popleft()
            notifications.append(self.format_proof_notification(proof))

        text = "📬 New Proofs:\n" + "\n".join(notifications)
        self.broadcast_notification(text)
        logger.info(f"Sent batch of {len(notifications)} notifications")

    def run(self):
        """Main monitoring loop."""
        logger.info("Proof notifier starting")

        try:
            while True:
                self.check_new_proofs()

                # Batch notifications every 5 seconds
                now = time.time()
                if now - self.last_batch_time >= self.batch_timeout:
                    if self.batch_queue:
                        self.flush_batch()
                    self.last_batch_time = now

                time.sleep(1)

        except KeyboardInterrupt:
            logger.info("Shutting down")
            if self.batch_queue:
                self.flush_batch()


def main():
    """Main entrypoint."""
    if not BOT_TOKEN:
        logger.error("ERROR: TELEGRAM_BOT_TOKEN not set")
        sys.exit(1)

    logger.info(f"✓ Bot token configured (first 10 chars: {BOT_TOKEN[:10]}...)")

    notifier = ProofNotifier(BOT_TOKEN)
    notifier.run()


if __name__ == "__main__":
    main()
