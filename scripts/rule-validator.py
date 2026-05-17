#!/usr/bin/env python3
"""
Phase 7C: Rule Validator
Validate proposed rules against historical data
"""

import json
import sys
from pathlib import Path
from datetime import datetime, date
from collections import defaultdict

REPO_ROOT = Path(__file__).parent.parent

# Promotion thresholds
MIN_PRECISION = 0.95  # 95% of the time rule prevents failure without false positives
MIN_CONFIDENCE = 0.85
MIN_EVIDENCE = 5


class RuleValidator:
    def __init__(self):
        self.candidates = []
        self.proofs = []
        self.validations = []

    def load_candidate_rules(self, rules_file):
        """Load candidate rules."""
        try:
            with open(rules_file) as f:
                data = json.load(f)
                self.candidates = data.get("candidates", [])
            print(f"✓ Loaded {len(self.candidates)} candidate rules")
        except (json.JSONDecodeError, IOError) as e:
            print(f"✗ Failed to load rules: {e}")

    def load_historical_proofs(self, days=7):
        """Load historical proofs for validation."""
        from pathlib import Path
        from datetime import datetime, timedelta

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

        print(f"✓ Loaded {len(proofs)} historical proofs")
        self.proofs = proofs
        return proofs

    def validate_rule(self, rule):
        """Validate a single rule against historical data."""
        # Find relevant proofs
        lane = rule.get("lane")
        failure_type = rule.get("failure_type")

        relevant_proofs = [
            p for p in self.proofs
            if p.get("routed_lane") == lane and p.get("status") in ["ERROR", "BLOCKED", "TIMEOUT"]
        ]

        if len(relevant_proofs) < MIN_EVIDENCE:
            return {
                "rule_id": rule["rule_id"],
                "ready_to_promote": False,
                "reason": f"Insufficient evidence (only {len(relevant_proofs)} failures)",
                "precision": 0.0,
                "recall": 0.0,
                "false_positive_rate": 0.0
            }

        # Calculate metrics
        failures_prevented = 0
        false_positives = 0
        total_checked = 0

        for proof in relevant_proofs:
            total_checked += 1

            # Did rule prevent this failure?
            proof_failure_type = self._classify_failure(proof)
            if proof_failure_type == failure_type:
                failures_prevented += 1

        # Precision: % of times rule applies correctly
        precision = failures_prevented / total_checked if total_checked > 0 else 0.0

        # Recall: % of all failures of this type this rule catches
        all_failures_of_type = len([
            p for p in self.proofs
            if self._classify_failure(p) == failure_type and p.get("routed_lane") == lane
        ])
        recall = failures_prevented / all_failures_of_type if all_failures_of_type > 0 else 0.0

        false_positive_rate = false_positives / total_checked if total_checked > 0 else 0.0

        ready = (precision >= MIN_PRECISION and
                rule["confidence"] >= MIN_CONFIDENCE and
                len(relevant_proofs) >= MIN_EVIDENCE)

        return {
            "rule_id": rule["rule_id"],
            "precision": precision,
            "recall": recall,
            "false_positive_rate": false_positive_rate,
            "evidence_count": len(relevant_proofs),
            "ready_to_promote": ready,
            "reason": self._get_validation_reason(precision, rule["confidence"], len(relevant_proofs))
        }

    def _classify_failure(self, proof):
        """Quick failure classification (mirrors 7A)."""
        status = proof.get("status", "").upper()
        summary = proof.get("proof_summary", "").lower()

        if status == "TIMEOUT":
            return "timeout"
        if "rate limit" in summary or "429" in summary:
            return "rate_limit"
        if "circuit breaker" in summary:
            return "circuit_breaker_open"
        if "permission" in summary:
            return "permission_denied"

        return "other"

    def _get_validation_reason(self, precision, confidence, evidence):
        """Generate validation reason."""
        if precision < MIN_PRECISION:
            return f"Precision too low ({precision:.2f} < {MIN_PRECISION})"
        if confidence < MIN_CONFIDENCE:
            return f"Confidence too low ({confidence:.2f} < {MIN_CONFIDENCE})"
        if evidence < MIN_EVIDENCE:
            return f"Insufficient evidence ({evidence} < {MIN_EVIDENCE})"
        return "Ready for promotion ✓"

    def validate_all(self):
        """Validate all candidate rules."""
        for rule in self.candidates:
            validation = self.validate_rule(rule)
            self.validations.append(validation)
            status = "✓" if validation["ready_to_promote"] else "✗"
            print(f"  {status} {rule['rule_id']:40} precision={validation['precision']:.2f}")

        return self.validations

    def save_validation_report(self, output_dir=None):
        """Save validation report."""
        if output_dir is None:
            output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
            output_dir.mkdir(parents=True, exist_ok=True)

        today = date.today().isoformat()
        output_file = output_dir / f"validation-report-{today}.json"

        ready_count = sum(1 for v in self.validations if v["ready_to_promote"])

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "total_validated": len(self.validations),
            "ready_to_promote": ready_count,
            "promotion_rate_pct": (ready_count / len(self.validations) * 100) if self.validations else 0,
            "validations": self.validations
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Saved validation report: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save report: {e}")
            return None

    def print_summary(self):
        """Print validation summary."""
        print("\n" + "=" * 60)
        print("VALIDATION SUMMARY")
        print("=" * 60)
        print(f"Total rules: {len(self.validations)}")

        ready = [v for v in self.validations if v["ready_to_promote"]]
        print(f"Ready for promotion: {len(ready)}")

        if ready:
            print("\nRules Ready for Promotion:")
            for v in ready:
                print(f"  ✓ {v['rule_id']}")

        print("=" * 60 + "\n")


def main():
    if len(sys.argv) > 1:
        rules_file = sys.argv[1]
    else:
        today = date.today().isoformat()
        rules_file = REPO_ROOT / "ψ" / "memory" / "resonance" / f"candidate-rules-{today}.json"

    print(f"✓ Validating rules from {rules_file}...")

    validator = RuleValidator()
    validator.load_candidate_rules(str(rules_file))

    if not validator.candidates:
        print("ℹ️  No candidates to validate")
        return

    print(f"📊 Loading historical proofs for validation...")
    validator.load_historical_proofs(days=7)

    print(f"🔍 Validating {len(validator.candidates)} rules...")
    validator.validate_all()
    validator.print_summary()

    output_file = validator.save_validation_report()
    if output_file:
        print(f"✓ Validation complete")


if __name__ == "__main__":
    main()
