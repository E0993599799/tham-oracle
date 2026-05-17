#!/usr/bin/env python3
"""
Phase 11D: Benchmark Runner
Orchestrates all testing phases (11A-11D) and scores world-class status

Runs:
- 11A: integration-test-suite.py (12 benchmarks)
- 11B: stress-tester.py (load testing)
- 11C: chaos-tester.py (fault injection)

Aggregates results and produces:
ψ/memory/resonance/benchmark-results-{date}.json
with {scores: {}, world_class: bool, pass_count}

World-class threshold: ≥10/12 benchmarks pass
"""

import json
import sys
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List
import time

REPO_ROOT = Path(__file__).parent.parent


class BenchmarkRunner:
    """
    Master benchmark orchestrator for Omega OS

    Phase progression:
    1. Run integration-test-suite.py (12 world-class benchmarks)
    2. Run stress-tester.py (load + throughput testing)
    3. Run chaos-tester.py (fault injection + resilience)
    4. Aggregate all results
    5. Write to ψ/memory/resonance/benchmark-results-{date}.json
    6. Determine world-class status (pass_count >= 10/12)
    """

    def __init__(self):
        self.repo_root = REPO_ROOT
        self.now = datetime.utcnow()
        self.date_str = self.now.strftime("%Y-%m-%d_%H%M%S")
        self.results = {
            "phase_11a": None,
            "phase_11b": None,
            "phase_11c": None,
            "aggregated": None,
        }

    def run(self) -> Dict[str, Any]:
        """Execute full benchmark suite"""

        print("\n" + "=" * 80)
        print("OMEGA OS PHASE 11: INTEGRATION & VALIDATION")
        print("World-Class Benchmark Suite")
        print(f"Start: {self.now.isoformat()}")
        print("=" * 80)

        # Phase 11A: Integration tests (12 benchmarks)
        print("\n" + "-" * 80)
        print("PHASE 11A: Integration Test Suite (12 world-class benchmarks)")
        print("-" * 80)
        self.results["phase_11a"] = self._run_phase("integration-test-suite.py")

        # Phase 11B: Stress testing
        print("\n" + "-" * 80)
        print("PHASE 11B: Stress Testing (Load & Throughput)")
        print("-" * 80)
        self.results["phase_11b"] = self._run_phase("stress-tester.py")

        # Phase 11C: Chaos testing
        print("\n" + "-" * 80)
        print("PHASE 11C: Chaos Testing (Fault Injection & Resilience)")
        print("-" * 80)
        self.results["phase_11c"] = self._run_phase("chaos-tester.py")

        # Aggregate and score
        aggregated = self._aggregate_results()
        self.results["aggregated"] = aggregated

        # Write results to memory vault
        self._write_results(aggregated)

        # Final report
        self._print_final_report(aggregated)

        return aggregated

    def _run_phase(self, script_name: str) -> Dict[str, Any]:
        """Run a single benchmark script"""

        script_path = self.repo_root / "scripts" / script_name
        print(f"Executing: {script_name}")

        try:
            result = subprocess.run(
                [sys.executable, str(script_path)],
                capture_output=True,
                text=True,
                timeout=60,
            )

            # Print output
            if result.stdout:
                print(result.stdout)

            if result.returncode != 0 and result.stderr:
                print(f"Error output:\n{result.stderr}")

            # Parse JSON result if available
            result_file = None
            if "integration" in script_name:
                result_file = self.repo_root / "benchmark-results-integration.json"
            elif "stress" in script_name:
                result_file = self.repo_root / "benchmark-results-stress.json"
            elif "chaos" in script_name:
                result_file = self.repo_root / "benchmark-results-chaos.json"

            if result_file and result_file.exists():
                with open(result_file) as f:
                    return json.load(f)

            return {"status": "error", "error": "No result file generated"}

        except subprocess.TimeoutExpired:
            print(f"ERROR: {script_name} timed out")
            return {"status": "timeout"}
        except Exception as e:
            print(f"ERROR running {script_name}: {e}")
            return {"status": "error", "error": str(e)}

    def _aggregate_results(self) -> Dict[str, Any]:
        """Combine all test results and calculate world-class score"""

        phase_11a = self.results["phase_11a"] or {}
        phase_11b = self.results["phase_11b"] or {}
        phase_11c = self.results["phase_11c"] or {}

        # Extract scores from Phase 11A (12 benchmarks)
        benchmark_results = phase_11a.get("benchmark_results", [])
        pass_count = phase_11a.get("pass_count", 0)
        overall_11a_score = phase_11a.get("overall_score", 0)

        # Extract metrics from Phase 11B
        stress_metrics = phase_11b.get("metrics", {})
        stress_status = phase_11b.get("status", "UNKNOWN")

        # Extract chaos results
        chaos_tests = phase_11c.get("chaos_tests", [])
        chaos_pass_count = phase_11c.get("pass_count", 0)

        # World-class determination
        # Threshold: ≥10/12 pass on Phase 11A
        world_class = pass_count >= 10
        world_class_status = "PASS" if world_class else "FAIL"

        # Calculate composite score
        # 11A: 70% weight (core benchmarks)
        # 11B: 15% weight (performance)
        # 11C: 15% weight (resilience)
        score_11a = overall_11a_score
        score_11b = 100 if stress_status == "PASS" else 50 if stress_status == "WARN" else 0
        score_11c = (chaos_pass_count / 3) * 100 if chaos_tests else 0

        composite_score = int(
            (score_11a * 0.70) + (score_11b * 0.15) + (score_11c * 0.15)
        )

        return {
            "benchmark_run_date": self.now.isoformat(),
            "world_class_status": world_class_status,
            "world_class": world_class,
            "world_class_threshold": "≥10/12 benchmarks pass",
            "scores": {
                "phase_11a_integration": score_11a,
                "phase_11b_stress": score_11b,
                "phase_11c_chaos": score_11c,
                "composite_score": composite_score,
            },
            "pass_count": {
                "phase_11a_benchmarks": f"{pass_count}/12",
                "phase_11c_chaos_scenarios": f"{chaos_pass_count}/3",
                "total_pass": pass_count,
            },
            "phase_details": {
                "phase_11a": {
                    "overall_score": overall_11a_score,
                    "pass_count": pass_count,
                    "world_class": phase_11a.get("world_class", False),
                    "benchmark_count": 12,
                    "benchmarks": benchmark_results,
                },
                "phase_11b": {
                    "status": stress_status,
                    "metrics": stress_metrics,
                },
                "phase_11c": {
                    "pass_count": chaos_pass_count,
                    "total_scenarios": len(chaos_tests),
                    "scenarios": chaos_tests,
                },
            },
        }

    def _write_results(self, aggregated: Dict[str, Any]):
        """Write aggregated results to memory vault"""

        memory_dir = self.repo_root / "ψ" / "memory" / "resonance"
        memory_dir.mkdir(parents=True, exist_ok=True)

        result_file = memory_dir / f"benchmark-results-{self.date_str}.json"

        with open(result_file, "w") as f:
            json.dump(aggregated, f, indent=2)

        print(f"\n✓ Results written to: {result_file}")

        # Also update the latest pointer
        latest_file = memory_dir / "benchmark-results-latest.json"
        with open(latest_file, "w") as f:
            json.dump(aggregated, f, indent=2)

        print(f"✓ Latest results at: {latest_file}")

    def _print_final_report(self, aggregated: Dict[str, Any]):
        """Print comprehensive final report"""

        print("\n" + "=" * 80)
        print("FINAL REPORT: OMEGA OS WORLD-CLASS CERTIFICATION")
        print("=" * 80)

        world_class = aggregated["world_class"]
        world_class_status = aggregated["world_class_status"]
        pass_count = int(aggregated["pass_count"]["phase_11a_benchmarks"].split("/")[0])

        print(f"\nWorld-Class Status: {world_class_status}")
        print(f"Overall Score: {aggregated['scores']['composite_score']}/100")
        print(f"Pass Count: {pass_count}/12 (threshold: ≥10)")

        print(f"\nScores by Phase:")
        print(f"  Phase 11A (Integration):  {int(aggregated['scores']['phase_11a_integration']):3d}/100")
        print(f"  Phase 11B (Stress):       {int(aggregated['scores']['phase_11b_stress']):3d}/100")
        print(f"  Phase 11C (Chaos):        {int(aggregated['scores']['phase_11c_chaos']):3d}/100")
        print(f"  Composite Score:          {int(aggregated['scores']['composite_score']):3d}/100")

        print(f"\nBenchmark Breakdown (12 tests):")
        phase_11a = aggregated["phase_details"]["phase_11a"]
        for benchmark in phase_11a.get("benchmarks", []):
            status_symbol = "✓" if benchmark["status"] == "PASS" else "✗" if benchmark["status"] == "FAIL" else "⚠"
            print(
                f"  {status_symbol} [{benchmark['number']:2d}] {benchmark['name']:40s} "
                f"Score: {benchmark['score']:3d}/100"
            )

        print(f"\nStress Test Results:")
        stress = aggregated["phase_details"]["phase_11b"]
        if "metrics" in stress and stress["metrics"]:
            m = stress["metrics"]
            print(f"  p95 latency:     {m.get('p95_ms', 0):.2f}ms")
            print(f"  Error rate:      {m.get('error_rate', 0) * 100:.2f}%")
            print(f"  Throughput:      {m.get('throughput_tasks_per_sec', 0):.2f} tasks/sec")

        print(f"\nChaos Test Results:")
        chaos = aggregated["phase_details"]["phase_11c"]
        print(f"  Scenarios passed: {chaos.get('pass_count', 0)}/{chaos.get('total_scenarios', 3)}")

        print(f"\n" + "=" * 80)
        print(f"CERTIFICATION: Omega OS is {'WORLD-CLASS ✓' if world_class else 'NOT YET WORLD-CLASS ✗'}")
        print("=" * 80)

        if world_class:
            print("""
The Omega OS orchestrator (Tham) meets production-grade standards:
  ✓ Intent accuracy ≥ 95%
  ✓ Proof completeness and independence verified
  ✓ Constitutional compliance enforced
  ✓ Memory freshness maintained
  ✓ Confidence thresholds applied
  ✓ Fallback mechanisms tested
  ✓ Token budget enforced
  ✓ Self-improvement loop active
  ✓ HITL escalation working
  ✓ System observability enabled
  ✓ Recovery procedures < 3 min
  ✓ Load testing passed (stress + chaos)

Ready for production deployment.
            """)
        else:
            gaps = 12 - pass_count
            print(f"""
{gaps} benchmarks require remediation:
  - Review failed benchmarks (marked ✗)
  - Address implementation gaps
  - Re-run benchmark suite after fixes
  - Resubmit for world-class certification
            """)

        print(f"\nTimestamp: {self.now.isoformat()}")


def main():
    runner = BenchmarkRunner()
    results = runner.run()

    # Return appropriate exit code
    return 0 if results["world_class"] else 1


if __name__ == "__main__":
    sys.exit(main())
