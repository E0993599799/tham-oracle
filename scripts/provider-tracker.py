#!/usr/bin/env python3
"""
Provider Tracker — Monitor API providers and per-agent quotas
Tracks: Claude API, OpenAI, 9router, Ollama, Oracle-v2
Outputs: ψ/memory/resonance/provider-status-{date}.json
"""

import json
import socket
import subprocess
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
import requests

REPO_ROOT = Path(__file__).parent.parent

PROVIDERS = [
    {"id": "claude", "name": "Claude API (Anthropic)", "url": "https://api.anthropic.com", "port": None, "env_key": "ANTHROPIC_API_KEY"},
    {"id": "openai", "name": "OpenAI API", "url": "https://api.openai.com", "port": None, "env_key": "OPENAI_API_KEY"},
    {"id": "9router", "name": "9router / OpenClaw", "url": "http://localhost:20128", "port": 20128, "env_key": None},
    {"id": "ollama", "name": "Ollama", "url": "http://localhost:11434", "port": 11434, "env_key": None},
    {"id": "oracle-v2", "name": "Oracle-v2 MCP", "url": "http://localhost:47778", "port": 47778, "env_key": None},
]

AGENT_QUOTAS = {
    "tham": {
        "provider": "claude",
        "model": "claude-haiku-4-5-20251001",
        "token_limit": 200000,
        "tier": "standard",
    },
    "core": {
        "provider": "oracle-v2",
        "model": "oracle-v2-mcp",
        "token_limit": 500000,
        "tier": "standard",
    },
    "codex": {
        "provider": "9router",
        "model": "cx/gpt-5.5",
        "token_limit": 128000,
        "tier": "standard",
    },
    "gemini": {
        "provider": "9router",
        "model": "gemini/gemini-2.5-flash",
        "token_limit": 1000000,
        "tier": "standard",
    },
    "bob": {
        "provider": "oracle-v2",
        "model": "oracle-coordination",
        "token_limit": 100000,
        "tier": "standard",
    },
    "watchdog": {
        "provider": "oracle-v2",
        "model": "oracle-monitoring",
        "token_limit": 50000,
        "tier": "standard",
    },
    "hermes": {
        "provider": "9router",
        "model": "hermes/hermes-3",
        "token_limit": 64000,
        "tier": "specialist",
    },
    "housekeeper": {
        "provider": "oracle-v2",
        "model": "oracle-maintenance",
        "token_limit": 50000,
        "tier": "standard",
    },
}


class ProviderTracker:
    """Track API provider health and per-agent quotas."""

    def __init__(self):
        self.output_dir = REPO_ROOT / "ψ/memory/resonance"
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.timestamp = datetime.now().isoformat()

    def probe_provider(self, provider: Dict) -> Dict:
        """Probe a single provider for health/connectivity."""
        provider_id = provider["id"]
        port = provider.get("port")
        url = provider.get("url")
        env_key = provider.get("env_key")

        result = {
            "id": provider_id,
            "name": provider["name"],
            "status": "unknown",
            "latency_ms": None,
            "has_key": None,
        }

        # Check if API key exists
        if env_key:
            result["has_key"] = bool(os.environ.get(env_key))

        # For local services: probe TCP port
        if port:
            result["status"], result["latency_ms"] = self._probe_port("127.0.0.1", port)
        # For remote HTTPS APIs: check response (basic connectivity)
        elif url and url.startswith("https://"):
            result["status"], result["latency_ms"] = self._probe_https(url)

        return result

    def _probe_port(self, host: str, port: int, timeout: float = 1.0) -> Tuple[str, Optional[int]]:
        """Probe TCP port via socket, return (status, latency_ms)."""
        try:
            import time

            start = time.time()
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port)) == 0
            sock.close()
            latency = int((time.time() - start) * 1000)

            if result:
                return "connected", latency
            else:
                return "down", None
        except Exception:
            return "down", None

    def _probe_https(self, url: str, timeout: float = 2.0) -> Tuple[str, Optional[int]]:
        """Probe HTTPS endpoint via HEAD request, return (status, latency_ms)."""
        try:
            import time

            start = time.time()
            response = requests.head(url, timeout=timeout, allow_redirects=True)
            latency = int((time.time() - start) * 1000)

            if response.status_code < 400:
                return "connected", latency
            else:
                return "down", None
        except Exception:
            return "down", None

    def get_agent_quotas(self) -> List[Dict]:
        """Build per-agent quota list."""
        quotas = []

        for agent_id, quota_info in AGENT_QUOTAS.items():
            quotas.append(
                {
                    "agent": agent_id,
                    "provider": quota_info["provider"],
                    "model": quota_info["model"],
                    "requests_today": 0,  # Would need to read from logs
                    "token_limit": quota_info["token_limit"],
                    "tier": quota_info["tier"],
                }
            )

        return quotas

    def track_providers(self) -> Dict:
        """Probe all providers and return status."""
        providers_status = []

        for provider in PROVIDERS:
            status = self.probe_provider(provider)
            providers_status.append(status)

        return {
            "timestamp": self.timestamp,
            "providers": providers_status,
            "agent_quotas": self.get_agent_quotas(),
        }

    def save_status(self, status: Dict) -> Path:
        """Save provider status to output file."""
        date_str = datetime.now().strftime("%Y-%m-%d")
        output_file = self.output_dir / f"provider-status-{date_str}.json"

        try:
            with open(output_file, "w") as f:
                json.dump(status, f, indent=2)
            return output_file
        except Exception as e:
            print(f"Error saving provider status: {e}")
            return None

    def print_status(self, status: Dict) -> None:
        """Pretty-print provider status."""
        print("\n" + "=" * 70)
        print("PROVIDER STATUS")
        print("=" * 70)

        providers = status.get("providers", [])
        for p in providers:
            status_emoji = "🟢" if p["status"] == "connected" else "🔴" if p["status"] == "down" else "⚪"
            key_indicator = "🔑" if p["has_key"] else "❌" if p["has_key"] is False else "—"
            latency_str = f"{p['latency_ms']}ms" if p["latency_ms"] else "—"

            print(f"  {status_emoji} {p['id']:12} {p['name']:35} {latency_str:8} {key_indicator}")

        print("\nAGENT QUOTAS:")
        print("-" * 70)
        quotas = status.get("agent_quotas", [])
        for q in quotas:
            usage_pct = (q.get("requests_today", 0) / max(q.get("token_limit", 1), 1)) * 100
            print(
                f"  {q['agent']:15} {q['provider']:12} {q['model']:30} {q['token_limit']:8} tokens ({usage_pct:.1f}% used)"
            )

        print("=" * 70 + "\n")


def main():
    tracker = ProviderTracker()

    status = tracker.track_providers()
    tracker.print_status(status)

    output_file = tracker.save_status(status)
    if output_file:
        print(f"✓ Provider status saved to {output_file.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
