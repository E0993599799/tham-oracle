#!/usr/bin/env python3
"""
Phase 10A: Agent Coordinator
Read agent registry, probe port availability, query agent status, and output fleet status.
Integrates with circuit-breaker.py state for health assessment.
"""

import json
import socket
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
import sys

REPO_ROOT = Path(__file__).parent.parent


class AgentCoordinator:
    """Query and coordinate agent fleet status."""

    def __init__(self):
        self.registry_file = REPO_ROOT / "configs/agent-registry.json"
        self.circuit_state_file = REPO_ROOT / "ψ/memory/resonance/circuit-breaker-state.json"
        self.output_dir = REPO_ROOT / "ψ/memory/resonance"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.registry = self._load_registry()
        self.circuit_states = self._load_circuit_states()
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
        """Probe a single agent and return status."""
        agent_id = agent.get("id")
        port = agent.get("port")
        status_obj = {
            "id": agent_id,
            "role": agent.get("role"),
            "port": port,
            "availability": "unknown",
            "port_reachable": None,
            "circuit_state": self.circuit_states.get(agent_id, {}).get("state", "UNKNOWN"),
            "last_probed": datetime.now().isoformat(),
        }

        # Probe port if specified
        if port:
            reachable = self._probe_port("127.0.0.1", port, timeout=1.0)
            status_obj["port_reachable"] = reachable
            status_obj["availability"] = "available" if reachable else "unavailable"
        else:
            # Port-less agents (bob, housekeeper, watchdog) check circuit state
            circuit_state = self.circuit_states.get(agent_id, {}).get("state", "UNKNOWN")
            if circuit_state == "OPEN":
                status_obj["availability"] = "unavailable"
            elif circuit_state == "HALF_OPEN":
                status_obj["availability"] = "degraded"
            else:
                status_obj["availability"] = "available"

        return status_obj

    def query_fleet(self) -> Dict:
        """Query all agents and return fleet status."""
        agents_status = []
        available_count = 0
        degraded_count = 0
        unavailable_count = 0

        for agent in self.registry.get("agents", []):
            status = self._probe_agent(agent)
            agents_status.append(status)

            if status["availability"] == "available":
                available_count += 1
            elif status["availability"] == "degraded":
                degraded_count += 1
            else:
                unavailable_count += 1

        total = len(agents_status)
        health_overall = "healthy"
        if unavailable_count > 0:
            health_overall = "degraded" if total - unavailable_count > 0 else "critical"
        elif degraded_count > 0:
            health_overall = "degraded"

        return {
            "timestamp": self.timestamp,
            "health_overall": health_overall,
            "summary": {
                "total_agents": total,
                "available": available_count,
                "degraded": degraded_count,
                "unavailable": unavailable_count,
            },
            "agents": agents_status,
        }

    def save_fleet_status(self, fleet_status: Dict) -> Path:
        """Save fleet status to output file."""
        date_str = datetime.now().strftime("%Y%m%d")
        output_file = self.output_dir / f"fleet-status-{date_str}.json"

        try:
            with open(output_file, "w") as f:
                json.dump(fleet_status, f, indent=2)
            return output_file
        except Exception as e:
            print(f"Error saving fleet status: {e}")
            return None

    def print_status(self, fleet_status: Dict) -> None:
        """Pretty-print fleet status."""
        summary = fleet_status.get("summary", {})
        health = fleet_status.get("health_overall", "unknown")

        emoji = {"healthy": "🟢", "degraded": "🟡", "critical": "🔴"}
        print("\n" + "=" * 70)
        print(f"FLEET STATUS  {emoji.get(health, '⚪')} {health.upper()}")
        print("=" * 70)
        print(f"Timestamp:    {fleet_status.get('timestamp')}")
        print(f"Total:        {summary.get('total_agents')} agents")
        print(f"  Available:  {summary.get('available')}")
        print(f"  Degraded:   {summary.get('degraded')}")
        print(f"  Unavailable: {summary.get('unavailable')}")
        print("\nDETAILS:")
        print("-" * 70)

        for agent in fleet_status.get("agents", []):
            agent_id = agent["id"]
            role = agent["role"]
            avail = agent["availability"]
            circuit = agent["circuit_state"]
            port = agent["port"]

            emoji_avail = {
                "available": "🟢",
                "degraded": "🟡",
                "unavailable": "🔴",
                "unknown": "⚪",
            }

            port_str = f":{port}" if port else "(no port)"
            print(
                f"  {emoji_avail.get(avail, '⚪')} {agent_id:15} {role:20} {avail:12} [circuit: {circuit}] {port_str}"
            )

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
