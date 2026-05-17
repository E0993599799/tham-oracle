#!/usr/bin/env python3
"""
Phase 7F: Performance Tracker
Calculate 7-day trends, SLA metrics, lane throughput, and success rates
"""

import json
import sys
from pathlib import Path
from datetime import datetime, date, timedelta
from collections import defaultdict
import statistics

REPO_ROOT = Path(__file__).parent.parent


class PerformanceTracker:
    def __init__(self):
        self.proofs = []
        self.metrics = {}
        self.lane_metrics = {}
        self.intent_metrics = {}

    def load_historical_proofs(self, days=7):
        """Load proofs from last N days."""
        proofs = []
        for i in range(days):
            check_date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
            date_dir = REPO_ROOT / "proofs" / check_date

            if date_dir.exists():
                for proof_file in date_dir.glob("*.json"):
                    if proof_file.name.startswith("lane-health"):
                        continue

                    try:
                        with open(proof_file) as f:
                            proofs.append(json.load(f))
                    except (json.JSONDecodeError, IOError):
                        pass

        print(f"✓ Loaded {len(proofs)} proofs from {days} days")
        self.proofs = proofs
        return proofs

    def calculate_lane_metrics(self):
        """Calculate per-lane metrics."""
        by_lane = defaultdict(lambda: {"success": 0, "total": 0, "response_times": []})

        for proof in self.proofs:
            lane = proof.get("routed_lane")
            status = proof.get("status")

            if lane:
                by_lane[lane]["total"] += 1
                if status in ["SUCCESS", "COMPLETED"]:
                    by_lane[lane]["success"] += 1

                # Track response time if available
                if "execution_time_ms" in proof:
                    by_lane[lane]["response_times"].append(proof["execution_time_ms"])

        # Calculate metrics per lane
        for lane, data in by_lane.items():
            success_rate = (data["success"] / data["total"]) if data["total"] > 0 else 0.0
            avg_response_time = (
                statistics.mean(data["response_times"])
                if data["response_times"]
                else 0
            )
            p95_response_time = (
                sorted(data["response_times"])[int(len(data["response_times"]) * 0.95)]
                if len(data["response_times"]) >= 20
                else avg_response_time
            )

            self.lane_metrics[lane] = {
                "lane": lane,
                "total_executions": data["total"],
                "successful_executions": data["success"],
                "success_rate": round(success_rate, 3),
                "failure_rate": round(1.0 - success_rate, 3),
                "avg_response_time_ms": round(avg_response_time, 1),
                "p95_response_time_ms": round(p95_response_time, 1),
                "throughput_per_day": round(data["total"] / 7, 1),
                "sla_status": "🟢 OK" if success_rate >= 0.95 else "🟡 WARN" if success_rate >= 0.85 else "🔴 CRITICAL"
            }

        return self.lane_metrics

    def calculate_intent_metrics(self):
        """Calculate per-intent metrics."""
        by_intent = defaultdict(lambda: {"success": 0, "total": 0})

        for proof in self.proofs:
            intent = proof.get("intent")
            status = proof.get("status")

            if intent:
                by_intent[intent]["total"] += 1
                if status in ["SUCCESS", "COMPLETED"]:
                    by_intent[intent]["success"] += 1

        for intent, data in by_intent.items():
            success_rate = (data["success"] / data["total"]) if data["total"] > 0 else 0.0

            self.intent_metrics[intent] = {
                "intent": intent,
                "total_executions": data["total"],
                "successful_executions": data["success"],
                "success_rate": round(success_rate, 3),
                "failure_rate": round(1.0 - success_rate, 3)
            }

        return self.intent_metrics

    def calculate_overall_metrics(self):
        """Calculate overall system metrics."""
        total = len(self.proofs)
        successful = len([p for p in self.proofs if p.get("status") in ["SUCCESS", "COMPLETED"]])
        success_rate = (successful / total) if total > 0 else 0.0

        response_times = [
            p.get("execution_time_ms")
            for p in self.proofs
            if "execution_time_ms" in p
        ]

        avg_response = statistics.mean(response_times) if response_times else 0
        p95_response = (
            sorted(response_times)[int(len(response_times) * 0.95)]
            if len(response_times) >= 20
            else avg_response
        )

        # Failure distribution
        failures_by_type = defaultdict(int)
        for proof in self.proofs:
            if proof.get("status") not in ["SUCCESS", "COMPLETED"]:
                failure_type = proof.get("failure_type", "unknown")
                failures_by_type[failure_type] += 1

        self.metrics = {
            "timestamp": datetime.now().isoformat(),
            "date": date.today().isoformat(),
            "window_days": 7,
            "total_executions": total,
            "successful_executions": successful,
            "overall_success_rate": round(success_rate, 3),
            "overall_failure_rate": round(1.0 - success_rate, 3),
            "avg_response_time_ms": round(avg_response, 1),
            "p95_response_time_ms": round(p95_response, 1),
            "daily_throughput": round(total / 7, 1),
            "failure_distribution": dict(failures_by_type)
        }

        return self.metrics

    def save_metrics(self, output_dir=None):
        """Save performance metrics to JSON."""
        if output_dir is None:
            output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
            output_dir.mkdir(parents=True, exist_ok=True)

        today = date.today().isoformat()
        output_file = output_dir / f"performance-metrics-{today}.json"

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "overall_metrics": self.metrics,
            "lane_metrics": list(self.lane_metrics.values()),
            "intent_metrics": list(self.intent_metrics.values())
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Saved performance metrics: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save metrics: {e}")
            return None

    def print_summary(self):
        """Print performance tracking summary."""
        print("\n" + "=" * 70)
        print("PERFORMANCE SUMMARY (7-DAY WINDOW)")
        print("=" * 70)

        m = self.metrics
        print(f"Total Executions:     {m['total_executions']}")
        print(f"Success Rate:         {m['overall_success_rate']:.1%}")
        print(f"Avg Response Time:    {m['avg_response_time_ms']:.0f}ms")
        print(f"P95 Response Time:    {m['p95_response_time_ms']:.0f}ms")
        print(f"Daily Throughput:     {m['daily_throughput']:.1f}")

        print("\n📊 Top Lanes:")
        sorted_lanes = sorted(self.lane_metrics.values(), key=lambda x: x["success_rate"], reverse=True)
        for lane_metric in sorted_lanes[:5]:
            print(f"  {lane_metric['sla_status']} {lane_metric['lane']:20} success={lane_metric['success_rate']:.1%} throughput={lane_metric['throughput_per_day']:.1f}/day")

        print("\n🎯 Top Intents:")
        sorted_intents = sorted(self.intent_metrics.values(), key=lambda x: x["total_executions"], reverse=True)
        for intent_metric in sorted_intents[:5]:
            print(f"   {intent_metric['intent']:30} success={intent_metric['success_rate']:.1%} count={intent_metric['total_executions']}")

        print("=" * 70 + "\n")


def main():
    print(f"📈 Performance Tracker: Analyzing 7-day metrics...")

    tracker = PerformanceTracker()
    tracker.load_historical_proofs(days=7)

    if not tracker.proofs:
        print("ℹ️  No proofs to analyze")
        return

    tracker.calculate_overall_metrics()
    tracker.calculate_lane_metrics()
    tracker.calculate_intent_metrics()
    tracker.print_summary()

    output_file = tracker.save_metrics()
    if output_file:
        print(f"✓ Performance tracking complete")


if __name__ == "__main__":
    main()
