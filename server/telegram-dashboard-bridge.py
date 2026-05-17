#!/usr/bin/env python3
"""
Phase 5D: Telegram Dashboard Bridge — Provide dashboard summaries via Telegram

Delivers real-time dashboard summaries through Telegram with formatted text
and emoji indicators.

Usage: Integrated with telegram-bot.py as /dashboard command
"""

import json
from pathlib import Path
from datetime import datetime
from collections import defaultdict
import logging

REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"

logger = logging.getLogger('telegram-dashboard-bridge')


class DashboardBridge:
    """Provide dashboard summaries via Telegram."""

    def __init__(self, cache_seconds=10):
        self.cache_seconds = cache_seconds
        self.last_cache_time = 0
        self.cached_summary = None

    def format_dashboard_summary(self, force_refresh=False) -> str:
        """Format complete dashboard summary."""
        now = datetime.now().timestamp()

        # Use cache if available
        if not force_refresh and self.cached_summary and (now - self.last_cache_time) < self.cache_seconds:
            return self.cached_summary

        # Load today's proofs
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = PROOFS_DIR / today

        lane_stats = defaultdict(lambda: {"count": 0, "successful": 0, "failed": 0})
        all_proofs = []

        if today_dir.exists():
            for proof_file in today_dir.glob("*.json"):
                if proof_file.name.startswith("lane-health"):
                    continue
                try:
                    with open(proof_file) as f:
                        proof = json.load(f)
                    all_proofs.append(proof)
                    lane = proof.get("routed_lane", "unknown")
                    lane_stats[lane]["count"] += 1
                    if proof.get("status") == "SUCCESS":
                        lane_stats[lane]["successful"] += 1
                    else:
                        lane_stats[lane]["failed"] += 1
                except (json.JSONDecodeError, IOError):
                    pass

        # Build summary
        text = "📊 *Omega OS Dashboard*\n\n"

        # Overall stats
        total = len(all_proofs)
        if total > 0:
            successful = sum(1 for p in all_proofs if p.get("status") == "SUCCESS")
            avg_duration = sum(p.get("execution_duration_seconds", 0) for p in all_proofs) / total
            success_pct = (successful / total) * 100

            text += f"*Overall Stats*\n"
            text += f"  Total: {total}\n"
            text += f"  Success: {successful} ({success_pct:.1f}%)\n"
            text += f"  Avg Duration: {avg_duration:.2f}s\n\n"

            # Lane breakdown
            text += "*Lane Status*\n"
            lanes = ["codex_gpt55", "claude", "gemini", "ollama", "hermes", "powershell_sfsr"]
            for lane in lanes:
                stats = lane_stats[lane]
                count = stats["count"]
                if count == 0:
                    status_emoji = "⚪"
                    text += f"{status_emoji} {lane:20} idle\n"
                else:
                    pct = (stats["successful"] / count) * 100
                    if pct >= 80:
                        status_emoji = "🟢"
                    elif pct >= 50:
                        status_emoji = "🟡"
                    else:
                        status_emoji = "🔴"
                    text += f"{status_emoji} {lane:20} {count:2} ({pct:5.1f}%)\n"

            text += f"\n_Updated: {datetime.now().strftime('%H:%M:%S')}_"
        else:
            text += "No proofs recorded yet.\n"

        # Cache result
        self.cached_summary = text
        self.last_cache_time = now

        return text

    def format_quick_dashboard(self) -> str:
        """Format compact dashboard for inline display."""
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = PROOFS_DIR / today

        total = 0
        successful = 0

        if today_dir.exists():
            for proof_file in today_dir.glob("*.json"):
                if proof_file.name.startswith("lane-health"):
                    continue
                try:
                    with open(proof_file) as f:
                        proof = json.load(f)
                    total += 1
                    if proof.get("status") == "SUCCESS":
                        successful += 1
                except (json.JSONDecodeError, IOError):
                    pass

        if total == 0:
            return "📊 Dashboard: No data yet"

        pct = (successful / total) * 100
        emoji = "🟢" if pct >= 80 else "🟡" if pct >= 50 else "🔴"
        return f"📊 {emoji} {total} tasks, {pct:.0f}% success"


# Global instance
_bridge = DashboardBridge()


def get_dashboard_summary(force_refresh=False) -> str:
    """Get dashboard summary - called from telegram-bot.py."""
    return _bridge.format_dashboard_summary(force_refresh)


def get_quick_dashboard() -> str:
    """Get compact dashboard - for inline display."""
    return _bridge.format_quick_dashboard()
