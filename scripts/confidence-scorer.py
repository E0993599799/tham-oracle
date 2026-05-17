#!/usr/bin/env python3
"""
Phase 7E: Confidence Scorer
Analyze task success patterns and assign confidence scores per intent+lane
"""

import json
import sys
from pathlib import Path
from datetime import datetime, date, timedelta
from collections import defaultdict
import statistics

REPO_ROOT = Path(__file__).parent.parent


class ConfidenceScorer:
    def __init__(self):
        self.proofs = []
        self.scores = []
        self.min_evidence = 3
        self.variance_threshold = 0.3
        self.confidence_window_days = 14

    def load_historical_proofs(self, days=14):
        """Load successful proofs from last N days."""
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
                            proof = json.load(f)
                            # Only include successful proofs
                            if proof.get("status") in ["SUCCESS", "COMPLETED"]:
                                proofs.append(proof)
                    except (json.JSONDecodeError, IOError):
                        pass

        print(f"✓ Loaded {len(proofs)} successful proofs from {days} days")
        self.proofs = proofs
        return proofs

    def calculate_variance(self, daily_rates):
        """Calculate variance of daily success rates."""
        if len(daily_rates) < 2:
            return 0.0
        try:
            return statistics.variance(daily_rates)
        except:
            return 0.0

    def calculate_confidence_for_pair(self, intent, lane):
        """Calculate confidence score for (intent, lane) pair."""
        # Find all proofs matching this intent+lane
        matching = [
            p for p in self.proofs
            if p.get("intent") == intent and p.get("routed_lane") == lane
        ]

        if len(matching) < self.min_evidence:
            return None

        # Count successful vs total
        successful = len([p for p in matching if p.get("status") in ["SUCCESS", "COMPLETED"]])
        total = len(matching)
        base_confidence = successful / total if total > 0 else 0.0

        # Calculate daily success rates for variance
        daily_rates = defaultdict(lambda: {"success": 0, "total": 0})
        for proof in matching:
            proof_date = proof.get("timestamp", "").split("T")[0]
            daily_rates[proof_date]["total"] += 1
            if proof.get("status") in ["SUCCESS", "COMPLETED"]:
                daily_rates[proof_date]["success"] += 1

        daily_success_rates = [
            (d["success"] / d["total"]) if d["total"] > 0 else 0.0
            for d in daily_rates.values()
        ]

        variance = self.calculate_variance(daily_success_rates) if daily_success_rates else 0.0

        # Apply variance discount
        confidence = base_confidence
        if variance > self.variance_threshold:
            confidence *= (1.0 - (variance - self.variance_threshold))

        # Apply recency boost if last 3 all succeeded
        recent_3 = sorted(matching, key=lambda p: p.get("timestamp", ""), reverse=True)[:3]
        if len(recent_3) == 3 and all(p.get("status") in ["SUCCESS", "COMPLETED"] for p in recent_3):
            confidence = min(1.0, confidence + 0.05)

        # Clamp to [0, 1]
        confidence = max(0.0, min(1.0, confidence))

        # Determine tier
        if confidence >= 0.85:
            tier = "high"
        elif confidence >= 0.65:
            tier = "medium"
        else:
            tier = "low"

        false_negative_rate = (total - successful) / total if total > 0 else 0.0

        return {
            "intent": intent,
            "lane": lane,
            "confidence": round(confidence, 3),
            "successful_executions": successful,
            "total_executions": total,
            "false_negative_rate": round(false_negative_rate, 3),
            "variance": round(variance, 3),
            "evidence_count": total,
            "confidence_tier": tier,
            "last_updated": datetime.now().isoformat()
        }

    def score_all(self):
        """Score all (intent, lane) pairs."""
        # Find unique pairs
        pairs = set()
        for proof in self.proofs:
            intent = proof.get("intent")
            lane = proof.get("routed_lane")
            if intent and lane:
                pairs.add((intent, lane))

        print(f"🔍 Scoring {len(pairs)} intent+lane pairs...")

        for intent, lane in sorted(pairs):
            score = self.calculate_confidence_for_pair(intent, lane)
            if score:
                self.scores.append(score)
                tier_emoji = {"high": "🟢", "medium": "🟡", "low": "🔴"}
                emoji = tier_emoji.get(score["confidence_tier"], "⚪")
                print(f"  {emoji} {intent:30} → {lane:20} confidence={score['confidence']:.2f}")

        return self.scores

    def save_scores(self, output_dir=None):
        """Save confidence scores to JSON."""
        if output_dir is None:
            output_dir = REPO_ROOT / "ψ" / "memory" / "resonance"
            output_dir.mkdir(parents=True, exist_ok=True)

        today = date.today().isoformat()
        output_file = output_dir / f"confidence-scores-{today}.json"

        # Summary stats
        by_tier = defaultdict(int)
        for score in self.scores:
            by_tier[score["confidence_tier"]] += 1

        output = {
            "timestamp": datetime.now().isoformat(),
            "date": today,
            "total_scored": len(self.scores),
            "by_tier": dict(by_tier),
            "scores": sorted(self.scores, key=lambda s: s["confidence"], reverse=True)
        }

        try:
            with open(output_file, "w") as f:
                json.dump(output, f, indent=2)
            print(f"✓ Saved confidence scores: {output_file}")
            return output_file
        except IOError as e:
            print(f"✗ Failed to save scores: {e}")
            return None

    def print_summary(self):
        """Print confidence scoring summary."""
        print("\n" + "=" * 70)
        print("CONFIDENCE SCORING SUMMARY")
        print("=" * 70)
        print(f"Total pairs scored: {len(self.scores)}")
        print()

        high_conf = [s for s in self.scores if s["confidence_tier"] == "high"]
        medium_conf = [s for s in self.scores if s["confidence_tier"] == "medium"]
        low_conf = [s for s in self.scores if s["confidence_tier"] == "low"]

        print(f"High confidence (>= 0.85):   {len(high_conf):3}")
        print(f"Medium confidence (0.65-0.84): {len(medium_conf):3}")
        print(f"Low confidence (< 0.65):     {len(low_conf):3}")

        if high_conf:
            print("\n🟢 Top High-Confidence Pairs:")
            for score in high_conf[:5]:
                print(f"   {score['intent']:30} → {score['lane']:20} {score['confidence']:.2f}")

        print("=" * 70 + "\n")


def main():
    print(f"📊 Confidence Scorer: Analyzing intent+lane success rates...")

    scorer = ConfidenceScorer()
    scorer.load_historical_proofs(days=14)

    if not scorer.proofs:
        print("ℹ️  No proofs to analyze")
        return

    scorer.score_all()
    scorer.print_summary()

    output_file = scorer.save_scores()
    if output_file:
        print(f"✓ Confidence scoring complete: {len(scorer.scores)} pairs scored")


if __name__ == "__main__":
    main()
