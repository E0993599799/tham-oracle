#!/usr/bin/env python3
"""
Phase 7A: Failure Classifier
Analyze task failures and classify root causes
"""

import json
import sys
from pathlib import Path
from datetime import datetime, date
from collections import defaultdict

REPO_ROOT = Path(__file__).parent.parent
PROOFS_DIR = REPO_ROOT / "proofs"

FAILURE_TYPES = {
    "network_error",
    "timeout",
    "invalid_input",
    "permission_denied",
    "rate_limit",
    "circuit_breaker_open",
    "unsupported_intent",
    "insufficient_memory",
    "authentication_failure",
    "other"
}

FAILURE_SIGNALS = {
    "network_error": ["connection refused", "timeout", "EOF", "closed"],
    "timeout": ["execution timed out", "deadline exceeded", "timeout"],
    "rate_limit": ["rate limit", "too many requests", "429"],
    "permission_denied": ["permission denied", "unauthorized", "forbidden", "403"],
    "circuit_breaker_open": ["circuit breaker open", "breaker open"],
    "invalid_input": ["invalid request", "bad request", "malformed", "400"],
    "authentication_failure": ["authentication failed", "invalid token", "401"],
    "insufficient_memory": ["out of memory", "memory limit", "insufficient"],
}


class FailureClassifier:
    def __init__(self):
        self.failures = []
        self.classification_accuracy = 0.0

    def load_daily_proofs(self, target_date=None):
        """Load all proofs for a specific date."""
        if target_date is None:
            target_date = date.today().isoformat()

        date_dir = PROOFS_DIR / target_date
        if not date_dir.exists():
            return []

        proofs = []
        for proof_file in date_dir.glob("*.json"):
            if proof_file.name.startswith("lane-health"):
                continue

            try:
                with open(proof_file) as f:
                    proof = json.load(f)
                    # Only include failures
                    if proof.get("status") in ["ERROR", "BLOCKED", "TIMEOUT"]:
                        proofs.append(proof)
            except (json.JSONDecodeError, IOError):
                pass

        return proofs

    def classify_failure(self, proof):
        """Classify failure type with confidence."""
        summary = proof.get("proof_summary", "").lower()
        lane_response = proof.get("lane_response", {})
        status = proof.get("status", "").upper()

        # Status-based classification
        if status == "TIMEOUT":
            return "timeout", 0.95

        # Summary-based classification
        for failure_type, signals in FAILURE_SIGNALS.items():
            for signal in signals:
                if signal.lower() in summary:
                    confidence = 0.90 if signal in summary else 0.70
                    return failure_type, confidence

        # Default classification
        return "other", 0.5

    def process_failures(self, proofs):
        """Classify all failures."""
        classified = []

        for proof in proofs:
            failure_type, confidence = self.classify_failure(proof)

            classified_failure = {
                "failure_id": f"fail-{proof.get('task_id', 'unknown')[:20]}",
                "task_id": proof.get("task_id"),
                "lane": proof.get("routed_lane"),
                "intent": proof.get("intent_signal", "unknown"),
                "risk_level": proof.get("risk_level"),
                "failure_type": failure_type,
                "confidence": confidence,
                "status": proof.get("status"),
                "execution_timestamp": proof.get("execution_timestamp"),
                "response_time_ms": proof.get("lane_response", {}).get("response_time_ms"),
                "context": {
                    "summary": proof.get("proof_summary", "")[:100],
                    "gates_passed": proof.get("gates_passed", [])
                }
            }

            classified.append(classified_failure)

        self.failures = classified
        return classified

    def save_failure_log(self, output_dir=None):
        """Save classified failures to JSON."""
        if output_dir is None:
            output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
            output_dir.mkdir(parents=True, exist_ok=True)

        today = date.today().isoformat()
        output_file = output_dir / f"failure-log-{today}.json"

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "total_failures": len(self.failures),
            "by_type": self.get_failure_distribution(),
            "by_lane": self.get_lane_distribution(),
            "by_intent": self.get_intent_distribution(),
            "failures": self.failures
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Saved failure log: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save failure log: {e}")
            return None

    def get_failure_distribution(self):
        """Get breakdown by failure type."""
        dist = defaultdict(int)
        for failure in self.failures:
            dist[failure["failure_type"]] += 1
        return dict(dist)

    def get_lane_distribution(self):
        """Get breakdown by lane."""
        dist = defaultdict(int)
        for failure in self.failures:
            dist[failure["lane"]] += 1
        return dict(dist)

    def get_intent_distribution(self):
        """Get breakdown by intent signal."""
        dist = defaultdict(int)
        for failure in self.failures:
            dist[failure["intent"]] += 1
        return dict(dist)

    def print_summary(self):
        """Print classification summary."""
        print("\n" + "=" * 60)
        print("FAILURE CLASSIFICATION SUMMARY")
        print("=" * 60)
        print(f"Total failures: {len(self.failures)}")
        print()

        print("By Type:")
        for ftype, count in self.get_failure_distribution().items():
            pct = (count / len(self.failures)) * 100 if self.failures else 0
            print(f"  {ftype:30} {count:3} ({pct:5.1f}%)")

        print("\nBy Lane:")
        for lane, count in self.get_lane_distribution().items():
            pct = (count / len(self.failures)) * 100 if self.failures else 0
            print(f"  {lane:30} {count:3} ({pct:5.1f}%)")

        print("\nBy Intent:")
        for intent, count in self.get_intent_distribution().items():
            pct = (count / len(self.failures)) * 100 if self.failures else 0
            print(f"  {intent:30} {count:3} ({pct:5.1f}%)")

        print("=" * 60 + "\n")


def main():
    if len(sys.argv) > 1:
        target_date = sys.argv[1]
    else:
        target_date = date.today().isoformat()

    print(f"🔍 Analyzing failures for {target_date}...")

    classifier = FailureClassifier()
    proofs = classifier.load_daily_proofs(target_date)

    if not proofs:
        print(f"ℹ️  No failures found for {target_date}")
        return

    print(f"Found {len(proofs)} failures")
    classified = classifier.process_failures(proofs)
    classifier.print_summary()

    output_file = classifier.save_failure_log()
    if output_file:
        print(f"✓ Classification complete: {len(classified)} failures classified")


if __name__ == "__main__":
    main()
