#!/usr/bin/env python3
"""
Phase 5C: Telegram Remote Executor — Accept remote task submission via Telegram

Handles /submit commands to create task contracts and route them through
the executor-lane-router for execution.

Command format: /submit <intent_signal> <context>
Example: /submit write_code "Create a Python function that validates emails"

Usage: Integrated with telegram-bot.py
"""

import json
import os
from pathlib import Path
from datetime import datetime, timezone
import logging
import hashlib

REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")

logger = logging.getLogger('telegram-remote-executor')


class RemoteExecutor:
    """Handle remote task submission via Telegram."""

    VALID_INTENTS = {
        "write_code", "fix_bug", "patch", "refactor_code",
        "review", "design", "refactor", "security_audit", "performance",
        "search", "summarize", "web_fetch", "data_gathering",
        "tag", "classify", "embed_text", "batch_tag", "tool_call"
    }

    RISK_OVERRIDES = {"low", "medium", "high", "critical"}

    def __init__(self):
        self.contracts_dir = REPO_ROOT / "ψ" / "inbox" / "telegram"
        self.contracts_dir.mkdir(parents=True, exist_ok=True)

    def parse_submit_command(self, args: str) -> dict:
        """Parse /submit command arguments."""
        parts = args.split(None, 1)
        if len(parts) < 2:
            return {"error": "Usage: /submit <intent> <context>"}

        intent = parts[0].lower()
        context = parts[1].strip('"\'')

        if intent not in self.VALID_INTENTS:
            return {"error": f"Invalid intent: {intent}. Valid: {', '.join(sorted(self.VALID_INTENTS))}"}

        return {
            "intent": intent,
            "context": context,
            "risk": "medium"  # default
        }

    def handle_submit(self, user_id: str, args: str) -> str:
        """Handle /submit command."""
        if not args.strip():
            return "❌ Usage: /submit <intent> <context>\nExample: /submit write_code \"Create a function that validates emails\""

        parsed = self.parse_submit_command(args)
        if "error" in parsed:
            return f"❌ {parsed['error']}"

        # Create task contract
        task_id = self._generate_task_id(user_id, parsed["intent"])
        contract = {
            "task_id": task_id,
            "intent": parsed["intent"],
            "prompt": parsed["context"],
            "risk_classification": parsed["risk"],
            "metadata": {
                "source": "telegram",
                "user_id": user_id,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
        }

        # Save contract
        contract_file = self.contracts_dir / f"{task_id}.json"
        try:
            with open(contract_file, 'w') as f:
                json.dump(contract, f, indent=2)
            logger.info(f"Created contract: {task_id}")
        except IOError as e:
            logger.error(f"Failed to save contract: {e}")
            return f"❌ Failed to create task: {e}"

        # Return acknowledgment
        return (
            f"✓ Task submitted: {task_id}\n"
            f"Intent: {parsed['intent']}\n"
            f"Risk: {parsed['risk']}\n"
            f"\nTask is in queue. Use /status to check progress."
        )

    def handle_list_tasks(self, user_id: str) -> str:
        """List user's submitted tasks."""
        tasks = []
        for contract_file in self.contracts_dir.glob("*.json"):
            try:
                with open(contract_file) as f:
                    contract = json.load(f)
                if contract.get("metadata", {}).get("user_id") == user_id:
                    task_id = contract.get("task_id")
                    intent = contract.get("intent")
                    tasks.append(f"• {task_id} ({intent})")
            except (json.JSONDecodeError, IOError):
                pass

        if not tasks:
            return "No tasks submitted yet."

        return "📋 Your Tasks:\n" + "\n".join(tasks)

    @staticmethod
    def _generate_task_id(user_id: str, intent: str) -> str:
        """Generate unique task ID."""
        now = datetime.now().isoformat()
        content = f"{user_id}:{intent}:{now}"
        hash_suffix = hashlib.md5(content.encode()).hexdigest()[:6]
        return f"telegram-{intent[:4]}-{hash_suffix}"


# Global instance
_executor = RemoteExecutor()


def handle_submit(user_id: str, args: str) -> str:
    """Handle /submit command - called from telegram-bot.py."""
    return _executor.handle_submit(user_id, args)


def handle_list_tasks(user_id: str) -> str:
    """Handle /tasks command - called from telegram-bot.py."""
    return _executor.handle_list_tasks(user_id)
