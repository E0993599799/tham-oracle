#!/usr/bin/env python3
"""
Phase 8D: Circuit Breaker
Manage per-lane circuit breaker state: CLOSED → OPEN (3 failures) → HALF_OPEN (60s) → CLOSED
"""

import json
import time
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Optional

REPO_ROOT = Path(__file__).parent.parent


class CircuitBreaker:
    """Circuit breaker state machine for each lane."""

    FAILURE_THRESHOLD = 3
    COOLDOWN_SECONDS = 60

    def __init__(self):
        self.state_file = REPO_ROOT / "ψ/memory/resonance" / "circuit-breaker-state.json"
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.states = self._load_states()

    def _load_states(self) -> Dict[str, Dict]:
        """Load circuit breaker states from file."""
        try:
            if self.state_file.exists():
                with open(self.state_file) as f:
                    return json.load(f)
        except:
            pass
        return {}

    def _save_states(self) -> None:
        """Save states to file."""
        try:
            with open(self.state_file, "w") as f:
                json.dump(self.states, f, indent=2)
        except Exception as e:
            print(f"Failed to save circuit breaker state: {e}")

    def _ensure_lane(self, lane: str) -> None:
        """Ensure lane entry exists."""
        if lane not in self.states:
            self.states[lane] = {
                "state": "CLOSED",
                "failure_count": 0,
                "last_failure_time": None,
                "opened_at": None,
            }

    def record_failure(self, lane: str) -> str:
        """Record a failure and return new state (CLOSED, OPEN, HALF_OPEN)."""
        self._ensure_lane(lane)
        state_entry = self.states[lane]
        state_entry["failure_count"] += 1
        state_entry["last_failure_time"] = datetime.now().isoformat()

        if state_entry["state"] == "CLOSED" and state_entry["failure_count"] >= self.FAILURE_THRESHOLD:
            state_entry["state"] = "OPEN"
            state_entry["opened_at"] = datetime.now().isoformat()
            print(f"🔴 {lane}: Circuit breaker OPENED (3 failures)")

        self._save_states()
        return state_entry["state"]

    def record_success(self, lane: str) -> str:
        """Record a success. If HALF_OPEN, transition to CLOSED."""
        self._ensure_lane(lane)
        state_entry = self.states[lane]

        if state_entry["state"] == "HALF_OPEN":
            state_entry["state"] = "CLOSED"
            state_entry["failure_count"] = 0
            print(f"🟢 {lane}: Circuit breaker CLOSED (1 success after HALF_OPEN)")

        self._save_states()
        return state_entry["state"]

    def get_state(self, lane: str) -> str:
        """Get current state. Transition OPEN → HALF_OPEN if cooldown elapsed."""
        self._ensure_lane(lane)
        state_entry = self.states[lane]

        if state_entry["state"] == "OPEN":
            opened_at = datetime.fromisoformat(state_entry["opened_at"])
            elapsed = (datetime.now() - opened_at).total_seconds()

            if elapsed >= self.COOLDOWN_SECONDS:
                state_entry["state"] = "HALF_OPEN"
                state_entry["failure_count"] = 0
                print(f"🟡 {lane}: Circuit breaker HALF_OPEN (cooldown expired)")
                self._save_states()

        return state_entry["state"]

    def is_available(self, lane: str) -> bool:
        """Check if lane is available (not OPEN)."""
        state = self.get_state(lane)
        return state != "OPEN"

    def print_status(self) -> None:
        """Print circuit breaker status for all lanes."""
        print("\n" + "=" * 60)
        print("CIRCUIT BREAKER STATUS")
        print("=" * 60)
        for lane, entry in self.states.items():
            state = self.get_state(lane)
            failures = entry["failure_count"]
            emoji = {"CLOSED": "🟢", "HALF_OPEN": "🟡", "OPEN": "🔴"}
            print(f"{emoji.get(state, '⚪')} {lane:20} {state:10} (failures: {failures})")
        print("=" * 60 + "\n")


def main():
    breaker = CircuitBreaker()

    # Test mode
    import sys
    if "--test" in sys.argv:
        # Simulate failures
        for i in range(5):
            state = breaker.record_failure("codex_gpt55")
            print(f"Failure {i+1}: {state}")

        # Check state
        state = breaker.get_state("codex_gpt55")
        print(f"Current state: {state}")

        # Simulate success
        state = breaker.record_success("codex_gpt55")
        print(f"After success: {state}")

        breaker.print_status()
        print("✓ Circuit breaker test complete")


if __name__ == "__main__":
    main()
