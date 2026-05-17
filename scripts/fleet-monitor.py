#!/usr/bin/env python3
"""
Phase 10C: Fleet Monitor
Poll every 60s (configurable), probe ports, integrate circuit-breaker state,
classify alerts (LOW/MEDIUM/HIGH/CRITICAL), and route to appropriate channels.
"""

import json
import socket
import time
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import sys

REPO_ROOT = Path(__file__).parent.parent


class FleetMonitor:
    """Monitor fleet health and route alerts."""

    PROBE_PORTS = {
        "codex_inference": 20128,
        "tham_orchestrator": 47778,
        "core_bridge": 47779,
        "ollama": 11434,
    }

    ALERT_LEVELS = {
        "LOW": 0,
        "MEDIUM": 1,
        "HIGH": 2,
        "CRITICAL": 3,
    }

    def __init__(self):
        self.memory_root = REPO_ROOT / "ψ/memory/resonance"
        self.memory_root.mkdir(parents=True, exist_ok=True)

        self.inbox_root = REPO_ROOT / "ψ/inbox"
        self.inbox_root.mkdir(parents=True, exist_ok=True)

        self.registry_file = REPO_ROOT / "configs/agent-registry.json"
        self.circuit_state_file = self.memory_root / "circuit-breaker-state.json"
        self.monitor_log_file = self.memory_root / "fleet-monitor.jsonl"

        self.registry = self._load_registry()
        self.circuit_states = self._load_circuit_states()

        # Config
        self.poll_interval = 60  # seconds
        self.latency_threshold_low = 500  # ms
        self.latency_threshold_high = 2000  # ms

    def _load_registry(self) -> Dict:
        """Load agent registry."""
        try:
            if self.registry_file.exists():
                with open(self.registry_file) as f:
                    return json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load registry: {e}")
        return {"agents": [], "lanes": []}

    def _load_circuit_states(self) -> Dict:
        """Load circuit breaker states."""
        try:
            if self.circuit_state_file.exists():
                with open(self.circuit_state_file) as f:
                    return json.load(f)
        except:
            pass
        return {}

    def _probe_port(self, host: str, port: int, timeout: float = 2.0) -> tuple[bool, float]:
        """Probe port and return (reachable, latency_ms)."""
        start = time.time()
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port)) == 0
            sock.close()
            latency_ms = (time.time() - start) * 1000
            return result, latency_ms
        except Exception:
            latency_ms = (time.time() - start) * 1000
            return False, latency_ms

    def _classify_alert(
        self, port_name: str, reachable: bool, latency_ms: float, circuit_state: str
    ) -> Optional[Dict]:
        """Classify alert based on health status. Return alert dict or None if healthy."""
        if reachable and circuit_state != "OPEN":
            # Healthy
            if latency_ms > self.latency_threshold_high:
                return {
                    "level": "LOW",
                    "port": port_name,
                    "issue": f"High latency ({latency_ms:.0f}ms > {self.latency_threshold_low}ms)",
                }
            return None

        # Not reachable
        if not reachable and circuit_state == "OPEN":
            return {
                "level": "MEDIUM",
                "port": port_name,
                "issue": f"Port unreachable + circuit OPEN",
            }
        elif not reachable:
            return {
                "level": "MEDIUM",
                "port": port_name,
                "issue": f"Port unreachable ({latency_ms:.0f}ms timeout)",
            }

        return None

    def _count_down_lanes(self) -> tuple[int, int]:
        """Count how many lanes are down (circuit OPEN or port unreachable)."""
        down_lanes = 0
        total_lanes = 0

        for lane_id, state_entry in self.circuit_states.items():
            total_lanes += 1
            if state_entry.get("state") == "OPEN":
                down_lanes += 1

        return down_lanes, total_lanes

    def probe_fleet(self) -> Dict:
        """Probe all ports and return health snapshot."""
        timestamp = datetime.now().isoformat()
        alerts = []
        probe_results = {}

        for port_name, port_num in self.PROBE_PORTS.items():
            reachable, latency_ms = self._probe_port("127.0.0.1", port_num)
            circuit_state = self.circuit_states.get(port_name, {}).get("state", "UNKNOWN")

            probe_results[port_name] = {
                "reachable": reachable,
                "latency_ms": latency_ms,
                "circuit_state": circuit_state,
            }

            # Classify alert
            alert = self._classify_alert(port_name, reachable, latency_ms, circuit_state)
            if alert:
                alerts.append(alert)

        # Count down lanes
        down_lanes, total_lanes = self._count_down_lanes()

        # Determine overall alert level
        overall_level = "OK"
        if len(alerts) > 0:
            levels = [a["level"] for a in alerts]
            if "CRITICAL" in levels:
                overall_level = "CRITICAL"
            elif "HIGH" in levels:
                overall_level = "HIGH"
            elif "MEDIUM" in levels:
                overall_level = "MEDIUM"
            elif "LOW" in levels:
                overall_level = "LOW"

        # Escalate based on down lanes
        if down_lanes >= 2:
            overall_level = "HIGH"
        elif down_lanes == total_lanes:
            overall_level = "CRITICAL"

        return {
            "timestamp": timestamp,
            "overall_level": overall_level,
            "probes": probe_results,
            "alerts": alerts,
            "lane_status": {
                "down_lanes": down_lanes,
                "total_lanes": total_lanes,
            },
        }

    def _log_monitoring_event(self, snapshot: Dict) -> None:
        """Log monitoring event to fleet-monitor.jsonl."""
        try:
            with open(self.monitor_log_file, "a") as f:
                f.write(json.dumps(snapshot) + "\n")
        except Exception as e:
            print(f"Warning: Failed to log monitoring event: {e}")

    def _write_alert_to_inbox(self, alert_level: str, alert_text: str) -> bool:
        """Write alert to tham's inbox."""
        try:
            inbox_dir = self.inbox_root / "tham"
            inbox_dir.mkdir(parents=True, exist_ok=True)

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            alert_file = inbox_dir / f"{timestamp}_fleet-alert-{alert_level}.txt"

            with open(alert_file, "w") as f:
                f.write(f"[{alert_level}] {datetime.now().isoformat()}\n")
                f.write(alert_text)

            return True
        except Exception as e:
            print(f"Warning: Failed to write alert to inbox: {e}")
            return False

    def _send_telegram_alert(self, alert_level: str, alert_text: str) -> bool:
        """Send Telegram alert if configured."""
        try:
            config_file = REPO_ROOT / "configs/telegram-config.json"
            if not config_file.exists():
                return False

            with open(config_file) as f:
                config = json.load(f)

            if not config.get("enabled"):
                return False

            # Try to use existing telegram script
            telegram_script = REPO_ROOT / "scripts/telegram-send.sh"
            if telegram_script.exists():
                result = subprocess.run(
                    ["bash", str(telegram_script), f"[{alert_level}] {alert_text}"],
                    capture_output=True,
                    timeout=5,
                )
                return result.returncode == 0

        except Exception as e:
            print(f"Warning: Failed to send Telegram alert: {e}")

        return False

    def handle_alerts(self, snapshot: Dict) -> None:
        """Handle alerts based on level and route appropriately."""
        alerts = snapshot.get("alerts", [])
        overall_level = snapshot.get("overall_level")

        if overall_level == "OK":
            return

        # Build alert message
        alert_lines = [f"Fleet Monitor Alert: {overall_level}"]
        alert_lines.append(f"Timestamp: {snapshot.get('timestamp')}")
        alert_lines.append(f"Lanes down: {snapshot['lane_status']['down_lanes']}/{snapshot['lane_status']['total_lanes']}")
        alert_lines.append("")
        alert_lines.append("Issues:")
        for alert in alerts:
            alert_lines.append(f"  - {alert['port']}: {alert['issue']} [{alert['level']}]")

        alert_text = "\n".join(alert_lines)

        # Route based on level
        if overall_level == "LOW":
            # Just log
            print(f"LOW: {alerts[0]['issue'] if alerts else 'unknown'}")

        elif overall_level == "MEDIUM":
            # Write to tham's inbox
            self._write_alert_to_inbox("MEDIUM", alert_text)
            print(f"MEDIUM: Alert written to ψ/inbox/tham/")

        elif overall_level == "HIGH":
            # Write to inbox + try Telegram
            self._write_alert_to_inbox("HIGH", alert_text)
            self._send_telegram_alert("HIGH", alert_text)
            print(f"HIGH: Alert to inbox + Telegram")

        elif overall_level == "CRITICAL":
            # Write to inbox + Telegram + log prominently
            self._write_alert_to_inbox("CRITICAL", alert_text)
            self._send_telegram_alert("CRITICAL", alert_text)
            print(f"CRITICAL: {alert_text}")

    def save_snapshot(self, snapshot: Dict) -> Path:
        """Save snapshot to fleet-monitor-{date}.json."""
        date_str = datetime.now().strftime("%Y%m%d")
        output_file = self.memory_root / f"fleet-monitor-{date_str}.json"

        try:
            with open(output_file, "w") as f:
                json.dump(snapshot, f, indent=2)
            return output_file
        except Exception as e:
            print(f"Error saving snapshot: {e}")
            return None

    def print_snapshot(self, snapshot: Dict) -> None:
        """Pretty-print snapshot."""
        level = snapshot.get("overall_level", "UNKNOWN")
        emoji = {"OK": "🟢", "LOW": "🟡", "MEDIUM": "🟠", "HIGH": "🔴", "CRITICAL": "🔴🔴"}

        print("\n" + "=" * 70)
        print(f"FLEET MONITOR  {emoji.get(level, '⚪')} {level}")
        print("=" * 70)
        print(f"Timestamp:     {snapshot.get('timestamp')}")
        lanes = snapshot["lane_status"]
        print(f"Lanes:         {lanes['down_lanes']}/{lanes['total_lanes']} down")

        print("\nProbes:")
        for port_name, result in snapshot.get("probes", {}).items():
            reachable = result["reachable"]
            latency = result["latency_ms"]
            circuit = result["circuit_state"]
            emoji_status = "✓" if reachable else "✗"
            print(f"  {emoji_status} {port_name:20} {latency:7.0f}ms [circuit: {circuit}]")

        if snapshot.get("alerts"):
            print("\nAlerts:")
            for alert in snapshot["alerts"]:
                print(f"  [{alert['level']:8}] {alert['port']:20} {alert['issue']}")

        print("=" * 70 + "\n")


def main():
    monitor = FleetMonitor()

    if "--test" in sys.argv:
        # Single probe
        print("Testing fleet monitor...")
        snapshot = monitor.probe_fleet()
        monitor.print_snapshot(snapshot)
        monitor.handle_alerts(snapshot)
        monitor._log_monitoring_event(snapshot)
        output_file = monitor.save_snapshot(snapshot)
        if output_file:
            print(f"✓ Snapshot saved to {output_file.relative_to(REPO_ROOT)}")
        sys.exit(0)

    if "--daemon" in sys.argv:
        # Continuous monitoring
        print(f"Fleet Monitor daemon starting (poll interval: {monitor.poll_interval}s)")
        try:
            while True:
                snapshot = monitor.probe_fleet()
                monitor.handle_alerts(snapshot)
                monitor._log_monitoring_event(snapshot)
                if snapshot.get("overall_level") != "OK":
                    monitor.print_snapshot(snapshot)
                time.sleep(monitor.poll_interval)
        except KeyboardInterrupt:
            print("\nFleet Monitor stopped.")
            sys.exit(0)

    # Default: single probe
    snapshot = monitor.probe_fleet()
    monitor.print_snapshot(snapshot)
    monitor.handle_alerts(snapshot)
    monitor._log_monitoring_event(snapshot)


if __name__ == "__main__":
    main()
