#!/usr/bin/env python3
"""
Phase 7B: Rule Generator
Convert failure patterns into preventive rules
"""

import json
import sys
from pathlib import Path
from datetime import datetime, date
from collections import defaultdict

REPO_ROOT = Path(__file__).parent.parent


class RuleGenerator:
    def __init__(self, failure_log_file=None):
        self.failure_log = None
        self.failures = []
        self.candidates = []
        self.pattern_threshold = 3  # Minimum failures to generate rule

        if failure_log_file:
            self.load_failure_log(failure_log_file)

    def load_failure_log(self, file_path):
        """Load failure log from JSON."""
        try:
            with open(file_path) as f:
                self.failure_log = json.load(f)
                self.failures = self.failure_log.get("failures", [])
            print(f"✓ Loaded {len(self.failures)} failures")
        except (json.JSONDecodeError, IOError) as e:
            print(f"✗ Failed to load failure log: {e}")

    def find_patterns(self):
        """Detect failure patterns."""
        patterns = defaultdict(list)

        # Group by (failure_type, lane)
        for failure in self.failures:
            key = (failure["failure_type"], failure["lane"])
            patterns[key].append(failure)

        return patterns

    def generate_rule(self, failure_type, lane, failures):
        """Generate rule from pattern."""
        if len(failures) < self.pattern_threshold:
            return None

        confidence = min(1.0, 0.5 + (len(failures) * 0.1))  # Confidence increases with evidence

        # Determine rule type
        if failure_type == "circuit_breaker_open":
            rule_type = "lane_blocklist"
            action = f"Block {lane} temporarily, use fallback"
        elif failure_type == "timeout":
            rule_type = "timeout_increase"
            action = f"Increase timeout for {lane}"
        elif failure_type == "rate_limit":
            rule_type = "rate_limit_reduction"
            action = f"Reduce task submission rate"
        else:
            rule_type = "lane_blocklist"
            action = f"Block {lane} for problematic intent signals"

        # Get affected intents
        affected_intents = set()
        for failure in failures:
            if failure.get("intent"):
                affected_intents.add(failure["intent"])

        rule = {
            "rule_id": f"rule-{failure_type}-{lane}",
            "rule_type": rule_type,
            "condition": f"{failure_type} on {lane}",
            "action": action,
            "failure_type": failure_type,
            "lane": lane,
            "affected_intents": list(affected_intents),
            "confidence": confidence,
            "evidence_count": len(failures),
            "created_timestamp": datetime.now().isoformat(),
            "implementation": self.get_implementation_code(rule_type, failure_type, lane)
        }

        return rule

    def get_implementation_code(self, rule_type, failure_type, lane):
        """Generate implementation snippet."""
        if rule_type == "lane_blocklist":
            return {
                "target": "executor-lane-router.py",
                "section": "LANE_BLOCKLIST",
                "code": f"LANE_BLOCKLIST['{lane}'] = True  # {failure_type}"
            }
        elif rule_type == "timeout_increase":
            return {
                "target": "executor-lane-router.py",
                "section": "TIMEOUT_CONFIG",
                "code": f"TIMEOUT_CONFIG['{lane}'] = 30  # Increased from 10s"
            }
        elif rule_type == "rate_limit_reduction":
            return {
                "target": "executor-lane-router.py",
                "section": "RATE_LIMITS",
                "code": f"RATE_LIMITS['global'] = 20  # Reduced from 30"
            }
        return {}

    def generate_rules(self):
        """Generate all candidate rules."""
        patterns = self.find_patterns()

        for (failure_type, lane), failures in patterns.items():
            rule = self.generate_rule(failure_type, lane, failures)
            if rule:
                self.candidates.append(rule)
                print(f"  Generated: {rule['rule_id']} (confidence: {rule['confidence']:.2f})")

        print(f"✓ Generated {len(self.candidates)} candidate rules")
        return self.candidates

    def save_candidates(self, output_dir=None):
        """Save candidate rules to JSON."""
        if output_dir is None:
            output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
            output_dir.mkdir(parents=True, exist_ok=True)

        today = date.today().isoformat()
        output_file = output_dir / f"candidate-rules-{today}.json"

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "total_candidates": len(self.candidates),
            "by_type": self.get_rule_type_distribution(),
            "candidates": self.candidates
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Saved candidate rules: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save candidate rules: {e}")
            return None

    def get_rule_type_distribution(self):
        """Get breakdown by rule type."""
        dist = defaultdict(int)
        for rule in self.candidates:
            dist[rule["rule_type"]] += 1
        return dict(dist)

    def print_summary(self):
        """Print rule generation summary."""
        print("\n" + "=" * 60)
        print("RULE GENERATION SUMMARY")
        print("=" * 60)
        print(f"Candidate rules: {len(self.candidates)}")
        print()

        if self.candidates:
            print("By Type:")
            for rtype, count in self.get_rule_type_distribution().items():
                print(f"  {rtype:30} {count:3}")

            print("\nTop Rules by Confidence:")
            for rule in sorted(self.candidates, key=lambda r: r["confidence"], reverse=True)[:5]:
                print(f"  {rule['rule_id']:40} confidence={rule['confidence']:.2f} evidence={rule['evidence_count']}")

        print("=" * 60 + "\n")


def main():
    if len(sys.argv) > 1:
        failure_log_file = sys.argv[1]
    else:
        # Default to today's failure log
        today = date.today().isoformat()
        failure_log_file = REPO_ROOT / "ψ" / "memory" / "resonance" / f"failure-log-{today}.json"

    print(f"📋 Generating rules from {failure_log_file}...")

    generator = RuleGenerator(str(failure_log_file))

    if not generator.failures:
        print("ℹ️  No failures to process")
        return

    print(f"📊 Finding patterns in {len(generator.failures)} failures...")
    rules = generator.generate_rules()
    generator.print_summary()

    output_file = generator.save_candidates()
    if output_file:
        print(f"✓ Rule generation complete: {len(rules)} rules generated")


if __name__ == "__main__":
    main()
