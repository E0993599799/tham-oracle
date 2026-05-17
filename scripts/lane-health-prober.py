#!/usr/bin/env python3
"""
Phase 8E: Lane Health Prober
Probe each lane port and classify health: ok (<200ms) / warn (200-500ms) / down (>500ms or refused)
"""

import json
import time
import socket
from pathlib import Path
from datetime import datetime
from typing import Dict, Tuple

REPO_ROOT = Path(__file__).parent.parent

# Lane ports
LANE_PORTS = {
    "codex_gpt55": ("localhost", 20128),
    "claude": ("localhost", 20128),
    "gemini": ("localhost", 20128),
    "ollama": ("localhost", 11434),
    "hermes": ("localhost", 11434),
    "powershell_sfsr": None,  # local execution, no port
}

# Health thresholds (milliseconds)
THRESHOLD_OK = 200
THRESHOLD_WARN = 500


class LaneHealthProber:
    """Probe each lane for availability and latency."""

    def __init__(self):
        self.results = {}

    def probe_lane(self, lane: str) -> Dict:
        """Probe a single lane. Return {status, latency_ms, timestamp}."""
        if LANE_PORTS[lane] is None:
            # Local execution
            return {
                "lane": lane,
                "status": "ok",
                "latency_ms": 0,
                "timestamp": datetime.now().isoformat(),
            }

        host, port = LANE_PORTS[lane]
        start = time.time()

        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)  # 2 second timeout
            result = sock.connect_ex((host, port))
            latency_ms = (time.time() - start) * 1000
            sock.close()

            if result == 0:
                # Connected
                if latency_ms < THRESHOLD_OK:
                    status = "ok"
                elif latency_ms < THRESHOLD_WARN:
                    status = "warn"
                else:
                    status = "down"
            else:
                # Connection refused
                latency_ms = (time.time() - start) * 1000
                status = "down"

            return {
                "lane": lane,
                "status": status,
                "latency_ms": round(latency_ms, 1),
                "timestamp": datetime.now().isoformat(),
            }
        except Exception as e:
            return {
                "lane": lane,
                "status": "down",
                "latency_ms": 0,
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
            }

    def probe_all(self) -> Dict[str, Dict]:
        """Probe all lanes."""
        results = {}
        for lane in LANE_PORTS.keys():
            result = self.probe_lane(lane)
            results[lane] = result
            self.results[lane] = result
        return results

    def save_health_report(self) -> Path:
        """Save health report to resonance directory."""
        today = datetime.now().strftime("%Y-%m-%d")
        output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
        output_dir.mkdir(parents=True, exist_ok=True)
        output_file = output_dir / f"lane-health-{today}.json"

        # Summary
        ok_count = len([r for r in self.results.values() if r["status"] == "ok"])
        warn_count = len([r for r in self.results.values() if r["status"] == "warn"])
        down_count = len([r for r in self.results.values() if r["status"] == "down"])

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "summary": {
                "ok": ok_count,
                "warn": warn_count,
                "down": down_count,
                "total": len(self.results),
            },
            "lanes": list(self.results.values()),
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Health report saved: {output_file}")
            return output_file
        except Exception as e:
            print(f"✗ Failed to save report: {e}")
            return None

    def print_status(self) -> None:
        """Print health status."""
        print("\n" + "=" * 60)
        print("LANE HEALTH PROBE")
        print("=" * 60)
        for lane, result in self.results.items():
            emoji = {
                "ok": "🟢",
                "warn": "🟡",
                "down": "🔴",
            }
            status = result["status"].upper()
            latency = result.get("latency_ms", 0)
            print(f"{emoji.get(result['status'], '⚪')} {lane:20} {status:5} {latency:6.1f}ms")
        print("=" * 60 + "\n")


def main():
    prober = LaneHealthProber()
    prober.probe_all()
    prober.save_health_report()
    prober.print_status()


if __name__ == "__main__":
    main()
