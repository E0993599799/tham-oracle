#!/usr/bin/env python3
"""
Phase 7G: Skill Gap Detector
Identify intents with low success rates and recommend executor upgrades
"""

import json
import sys
from pathlib import Path
from datetime import datetime, date, timedelta
from collections import defaultdict

REPO_ROOT = Path(__file__).parent.parent

# Success rate thresholds
MIN_ACCEPTABLE_SUCCESS = 0.80  # Below this = skill gap
TARGET_SUCCESS = 0.95  # Target after improvement


class SkillGapDetector:
    def __init__(self):
        self.proofs = []
        self.intent_metrics = {}
        self.gaps = []
        self.recommendations = []

    def load_historical_proofs(self, days=14):
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

    def identify_gaps(self):
        """Identify intents with success rate below threshold."""
        by_intent = defaultdict(lambda: {"success": 0, "total": 0, "failures": []})

        for proof in self.proofs:
            intent = proof.get("intent")
            status = proof.get("status")

            if intent:
                by_intent[intent]["total"] += 1
                if status in ["SUCCESS", "COMPLETED"]:
                    by_intent[intent]["success"] += 1
                else:
                    by_intent[intent]["failures"].append({
                        "lane": proof.get("routed_lane"),
                        "failure_type": proof.get("failure_type", "unknown"),
                        "timestamp": proof.get("timestamp")
                    })

        # Calculate metrics and find gaps
        for intent, data in by_intent.items():
            if data["total"] < 3:
                continue  # Need minimum evidence

            success_rate = data["success"] / data["total"]
            gap_severity = max(0, MIN_ACCEPTABLE_SUCCESS - success_rate)

            if gap_severity > 0:
                failure_types = defaultdict(int)
                lanes = defaultdict(int)

                for failure in data["failures"]:
                    failure_types[failure["failure_type"]] += 1
                    if failure["lane"]:
                        lanes[failure["lane"]] += 1

                gap = {
                    "intent": intent,
                    "current_success_rate": round(success_rate, 3),
                    "total_attempts": data["total"],
                    "failures": len(data["failures"]),
                    "gap_severity": round(gap_severity, 3),
                    "top_failure_types": dict(sorted(failure_types.items(), key=lambda x: x[1], reverse=True)[:3]),
                    "lanes_with_issues": dict(sorted(lanes.items(), key=lambda x: x[1], reverse=True)[:3])
                }

                self.gaps.append(gap)
                self.intent_metrics[intent] = gap

        return self.gaps

    def generate_recommendations(self):
        """Generate upgrade recommendations for each gap."""
        for gap in sorted(self.gaps, key=lambda x: x["gap_severity"], reverse=True):
            intent = gap["intent"]
            severity = gap["gap_severity"]
            top_failures = gap["top_failure_types"]

            recommendation = {
                "intent": intent,
                "priority": "critical" if severity > 0.2 else "high" if severity > 0.1 else "medium",
                "gap_size": gap_severity,
                "recommendation": self._get_recommendation(intent, top_failures),
                "estimated_impact": round((TARGET_SUCCESS - gap["current_success_rate"]) * 100, 1)
            }

            self.recommendations.append(recommendation)

        return self.recommendations

    def _get_recommendation(self, intent, top_failures):
        """Generate specific upgrade recommendation based on failure patterns."""
        if not top_failures:
            return f"Analyze {intent} execution path; no clear failure pattern"

        primary_failure = list(top_failures.keys())[0]

        recommendations_map = {
            "timeout": f"Increase timeout or implement streaming for {intent}",
            "rate_limit": f"Implement request batching or queue for {intent}",
            "permission_denied": f"Verify credentials and permissions for {intent}",
            "circuit_breaker_open": f"Add fallback lane or retry logic for {intent}",
            "invalid_input": f"Improve input validation and intent parsing for {intent}",
            "authentication_failure": f"Refresh auth tokens or rotate credentials for {intent}",
            "insufficient_memory": f"Optimize memory usage or split {intent} into smaller tasks",
            "network_error": f"Add retry logic with exponential backoff for {intent}",
            "unsupported_intent": f"Check if {intent} is properly routed to capable lanes",
            "other": f"Deep-dive analysis needed for {intent} failures"
        }

        return recommendations_map.get(primary_failure, f"Investigate {primary_failure} failures for {intent}")

    def save_gaps(self, output_dir=None):
        """Save skill gaps to JSON."""
        if output_dir is None:
            output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
            output_dir.mkdir(parents=True, exist_ok=True)

        today = date.today().isoformat()
        output_file = output_dir / f"skill-gaps-{today}.json"

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "total_gaps_detected": len(self.gaps),
            "by_priority": {
                "critical": len([r for r in self.recommendations if r["priority"] == "critical"]),
                "high": len([r for r in self.recommendations if r["priority"] == "high"]),
                "medium": len([r for r in self.recommendations if r["priority"] == "medium"])
            },
            "gaps": sorted(self.gaps, key=lambda x: x["gap_severity"], reverse=True),
            "recommendations": sorted(self.recommendations, key=lambda x: x["estimated_impact"], reverse=True)
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Saved skill gaps: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save gaps: {e}")
            return None

    def print_summary(self):
        """Print skill gap summary."""
        print("\n" + "=" * 70)
        print("SKILL GAP ANALYSIS")
        print("=" * 70)
        print(f"Intents with gaps: {len(self.gaps)}")
        print()

        critical = [r for r in self.recommendations if r["priority"] == "critical"]
        high = [r for r in self.recommendations if r["priority"] == "high"]
        medium = [r for r in self.recommendations if r["priority"] == "medium"]

        print(f"🔴 Critical gaps:    {len(critical)}")
        print(f"🟡 High gaps:        {len(high)}")
        print(f"🟢 Medium gaps:      {len(medium)}")

        if critical:
            print("\n🔴 CRITICAL UPGRADES NEEDED:")
            for rec in critical[:3]:
                print(f"   {rec['intent']:30} → {rec['recommendation']}")
                print(f"      Impact: +{rec['estimated_impact']:.1f}% success")

        print("=" * 70 + "\n")


def main():
    print(f"🔍 Skill Gap Detector: Analyzing intent performance gaps...")

    detector = SkillGapDetector()
    detector.load_historical_proofs(days=14)

    if not detector.proofs:
        print("ℹ️  No proofs to analyze")
        return

    detector.identify_gaps()
    detector.generate_recommendations()
    detector.print_summary()

    output_file = detector.save_gaps()
    if output_file:
        print(f"✓ Skill gap analysis complete: {len(detector.gaps)} gaps detected")


if __name__ == "__main__":
    main()
