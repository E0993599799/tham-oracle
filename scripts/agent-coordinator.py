#!/usr/bin/env python3
"""
Phase 10A: Agent Coordinator
Read agent registry, probe port availability, query agent status, and output fleet status.
Integrates with circuit-breaker.py state for health assessment.
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


class MawSessionProber:
    """Query maw sessions via maw ls --json."""

    @staticmethod
    def get_sessions() -> Dict[str, bool]:
        """Return {agent_id: is_active}."""
        try:
            result = subprocess.run(["maw", "ls", "--json"], capture_output=True, text=True, timeout=5)
            if result.returncode != 0:
                return {}
            sessions = json.loads(result.stdout)
            return {s.get("name"): True for s in sessions if isinstance(s, dict) and s.get("name")}
        except Exception:
            return {}


class AgentCoordinator:
    """Query and coordinate agent fleet status."""

    def __init__(self):
        self.registry_file = REPO_ROOT / "configs/agent-registry.json"
        self.circuit_state_file = REPO_ROOT / "ψ/memory/resonance/circuit-breaker-state.json"
        self.output_dir = REPO_ROOT / "ψ/memory/resonance"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.registry = self._load_registry()
        self.circuit_states = self._load_circuit_states()
        self.maw_sessions = MawSessionProber.get_sessions()
        self.timestamp = datetime.now().isoformat()

    def _load_registry(self) -> Dict:
        """Load agent registry."""
        try:
            if self.registry_file.exists():
                with open(self.registry_file) as f:
                    return json.load(f)
        except Exception as e:
            print(f"Error loading agent registry: {e}")
            return {"agents": [], "lanes": []}
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

    def _probe_port(self, host: str, port: int, timeout: float = 2.0) -> bool:
        """Probe port availability via socket connection."""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result = sock.connect_ex((host, port)) == 0
            sock.close()
            return result
        except Exception:
            return False

    def _probe_agent(self, agent: Dict) -> Dict:
        """Probe a single agent and return status (Format B with soul/specialty/capabilities)."""
        agent_id = agent.get("id")
        port = agent.get("port")
        has_maw_session = agent_id in self.maw_sessions

        status_obj = {
            "name": agent_id,
            "soul": agent.get("soul", "No soul"),
            "role": agent.get("role", "unknown"),
            "specialty": agent.get("specialty", "General"),
            "capabilities": agent.get("capabilities", []),
            "port": port,
            "status": "unknown",
            "available": False,
            "maw_session_active": has_maw_session,
            "last_heartbeat": datetime.now().isoformat(),
            "task_count": 0,
        }

        # Probe port if specified
        port_reachable = False
        if port:
            port_reachable = self._probe_port("127.0.0.1", port, timeout=1.0)

        # Enhanced availability: port open OR maw session active
        if port_reachable:
            status_obj["status"] = "connected"
            status_obj["available"] = True
        elif has_maw_session:
            status_obj["status"] = "session-only"
            status_obj["available"] = True
        else:
            status_obj["status"] = "offline"
            status_obj["available"] = False

        return status_obj

    def query_fleet(self) -> Dict:
        """Query all agents and return unified Format B fleet status."""
        agents_status = []
        available_count = 0

        for agent in self.registry.get("agents", []):
            status = self._probe_agent(agent)
            agents_status.append(status)

            if status["available"]:
                available_count += 1

        total = len(agents_status)
        health_overall = "healthy" if available_count == total else "degraded" if available_count > 0 else "critical"

        # Load relay log from file if it exists
        relay_log = []
        relay_log_file = self.output_dir / "relay-log.jsonl"
        if relay_log_file.exists():
            lines = relay_log_file.read_text().strip().split("\n")
            for line in lines:
                if line:
                    try:
                        relay_log.append(json.loads(line))
                    except:
                        pass

        return {
            "timestamp": self.timestamp,
            "agents": agents_status,
            "relay_log": relay_log[-50:] if relay_log else [],  # Last 50 entries
            "message_queue": [],
            "health_overall": health_overall,
        }

    def save_fleet_status(self, fleet_status: Dict) -> Path:
        """Save fleet status to output file (both formats)."""
        date_str_compact = datetime.now().strftime("%Y%m%d")
        date_str_hyphen = datetime.now().strftime("%Y-%m-%d")

        files = [
            self.output_dir / f"fleet-status-{date_str_compact}.json",
            self.output_dir / f"fleet-status-{date_str_hyphen}.json",
        ]

        try:
            for output_file in files:
                with open(output_file, "w") as f:
                    json.dump(fleet_status, f, indent=2)
            return files[1]  # Return hyphen-date version
        except Exception as e:
            print(f"Error saving fleet status: {e}")
            return None

    def print_status(self, fleet_status: Dict) -> None:
        """Pretty-print fleet status (Format B)."""
        agents = fleet_status.get("agents", [])
        health = fleet_status.get("health_overall", "unknown")
        available = sum(1 for a in agents if a.get("available"))
        total = len(agents)

        emoji = {"healthy": "🟢", "degraded": "🟡", "critical": "🔴"}
        print("\n" + "=" * 70)
        print(f"FLEET STATUS  {emoji.get(health, '⚪')} {health.upper()}")
        print("=" * 70)
        print(f"Timestamp:    {fleet_status.get('timestamp')}")
        print(f"Total:        {total} agents, {available} available")
        print("\nAGENTS:")
        print("-" * 70)

        for agent in agents:
            name = agent.get("name", "?")
            role = agent.get("role", "?")
            status = agent.get("status", "unknown")
            available = agent.get("available", False)
            maw_active = agent.get("maw_session_active", False)

            emoji_status = "🟢" if available else "🔴"
            maw_indicator = " [maw]" if maw_active else ""

            print(f"  {emoji_status} {name:15} {role:20} {status:15}{maw_indicator}")

        relay_log = fleet_status.get("relay_log", [])
        if relay_log:
            print(f"\nRELAY LOG: {len(relay_log)} recent entries")

        print("=" * 70 + "\n")


def main():
    coordinator = AgentCoordinator()

    if "--test" in sys.argv:
        # Test mode
        print("Testing agent coordinator...")
        fleet_status = coordinator.query_fleet()
        coordinator.print_status(fleet_status)
        output_file = coordinator.save_fleet_status(fleet_status)
        if output_file:
            print(f"✓ Fleet status saved to {output_file}")
        sys.exit(0)

    # Default: query and save
    fleet_status = coordinator.query_fleet()
    coordinator.print_status(fleet_status)
    output_file = coordinator.save_fleet_status(fleet_status)

    if output_file:
        print(f"✓ Fleet status saved to {output_file.relative_to(REPO_ROOT)}")

    # Exit with status code based on health
    health = fleet_status.get("health_overall")
    if health == "healthy":
        sys.exit(0)
    elif health == "degraded":
        sys.exit(1)
    else:
        sys.exit(2)


if __name__ == "__main__":
    main()
