#!/usr/bin/env python3
"""
Phase 7H: Learning Engine
Orchestrate full learning pipeline: failures → rules → validation → promotion
"""

import json
import sys
import subprocess
from pathlib import Path
from datetime import datetime, date
from collections import defaultdict

REPO_ROOT = Path(__file__).parent.parent


class LearningEngine:
    def __init__(self):
        self.log_file = None
        self.timestamp = datetime.now().isoformat()
        self.date = date.today().isoformat()
        self.summary = {
            "timestamp": self.timestamp,
            "date": self.date,
            "failures_found": 0,
            "rules_generated": 0,
            "rules_validated": 0,
            "rules_promoted": 0,
            "promotion_success_rate": 0.0,
            "promotions": []
        }

    def run_stage(self, stage_name, script, args=None):
        """Run a learning pipeline stage."""
        print(f"\n📍 Running {stage_name}...")

        cmd = [sys.executable, str(script)]
        if args:
            cmd.extend(args)

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            if result.returncode == 0:
                print(f"  ✓ {stage_name} completed")
                return True, result.stdout
            else:
                print(f"  ✗ {stage_name} failed")
                print(f"  Error: {result.stderr}")
                return False, result.stderr
        except subprocess.TimeoutExpired:
            print(f"  ✗ {stage_name} timed out")
            return False, "Timeout"
        except Exception as e:
            print(f"  ✗ {stage_name} error: {e}")
            return False, str(e)

    def run_pipeline(self):
        """Execute full learning pipeline."""
        resonance_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
        resonance_dir.mkdir(parents=True, exist_ok=True)

        print("\n" + "=" * 70)
        print("OMEGA OS LEARNING ENGINE")
        print("=" * 70)
        print(f"Date: {self.date}")
        print(f"Time: {datetime.now().strftime('%H:%M:%S')}")

        # Stage 7A: Classify Failures
        print("\n[1/4] Failure Classification (7A)")
        success, output = self.run_stage(
            "Failure Classifier",
            REPO_ROOT / "scripts" / "failure-classifier.py",
            [self.date]
        )

        if not success:
            print("⚠️  Learning pipeline stopped: failure classification failed")
            return False

        # Load failure log to get count
        failure_log = resonance_dir / f"failure-log-{self.date}.json"
        if failure_log.exists():
            with open(failure_log) as f:
                data = json.load(f)
                self.summary["failures_found"] = data.get("total_failures", 0)

        # Stage 7B: Generate Rules
        print("\n[2/4] Rule Generation (7B)")
        success, output = self.run_stage(
            "Rule Generator",
            REPO_ROOT / "scripts" / "rule-generator.py",
            [str(failure_log)]
        )

        if not success:
            print("⚠️  Warning: rule generation failed, continuing...")

        # Load candidate rules
        candidate_rules = resonance_dir / f"candidate-rules-{self.date}.json"
        if candidate_rules.exists():
            with open(candidate_rules) as f:
                data = json.load(f)
                self.summary["rules_generated"] = data.get("total_candidates", 0)

        # Stage 7C: Validate Rules
        print("\n[3/4] Rule Validation (7C)")
        success, output = self.run_stage(
            "Rule Validator",
            REPO_ROOT / "scripts" / "rule-validator.py",
            [str(candidate_rules)]
        )

        if not success:
            print("⚠️  Warning: validation failed, continuing...")

        # Load validation report
        validation_report = resonance_dir / f"validation-report-{self.date}.json"
        if validation_report.exists():
            with open(validation_report) as f:
                data = json.load(f)
                self.summary["rules_validated"] = data.get("ready_to_promote", 0)
                self.summary["promotion_success_rate"] = data.get("promotion_rate_pct", 0)

        # Stage 7D: Promote Rules (stub for now)
        print("\n[4/4] Rule Promotion (7D)")
        print("  ℹ️  Rule promotion requires human approval")
        print(f"  📊 {self.summary['rules_validated']} rules ready for promotion")

        return True

    def save_learning_summary(self):
        """Save learning engine summary."""
        resonance_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
        output_file = resonance_dir / f"learning-summary-{self.date}.json"

        try:
            with open(output_file, "w") as f:
                json.dump(self.summary, f, indent=2)
            print(f"\n✓ Learning summary: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save summary: {e}")
            return None

    def print_final_report(self):
        """Print final learning report."""
        print("\n" + "=" * 70)
        print("LEARNING ENGINE REPORT")
        print("=" * 70)
        print(f"Date: {self.date}")
        print()
        print(f"Failures Found:        {self.summary['failures_found']}")
        print(f"Rules Generated:       {self.summary['rules_generated']}")
        print(f"Rules Validated:       {self.summary['rules_validated']}")
        print(f"Rules Promoted:        {self.summary['rules_promoted']}")
        print(f"Success Rate:          {self.summary['promotion_success_rate']:.1f}%")
        print("=" * 70 + "\n")


def main():
    engine = LearningEngine()

    success = engine.run_pipeline()

    engine.save_learning_summary()
    engine.print_final_report()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
