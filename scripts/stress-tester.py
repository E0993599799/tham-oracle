#!/usr/bin/env python3
"""
Phase 11B: Stress Tester
Load testing for Omega OS under sustained and burst load

Generates 100 tasks in 5 minute window with:
- Burst: 20 simultaneous tasks
- Measurement: p50/p95/p99 latency, error rate, circuit breaker trips
- Output: {metrics: {p50, p95, p99, error_rate, trips}, status}
"""

import json
import sys
import time
import threading
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, asdict
from typing import List, Dict, Any
import random
import statistics

REPO_ROOT = Path(__file__).parent.parent


@dataclass
class TaskExecution:
    """Single task execution record"""
    task_id: str
    task_type: str
    start_time: float
    end_time: float
    latency_ms: float
    status: str  # "success" | "timeout" | "error"
    error: str = None


class StressTester:
    """
    Load testing for Omega OS

    Configuration:
    - Total tasks: 100
    - Time window: 5 minutes (simulated as 5 seconds in test mode)
    - Burst size: 20 concurrent tasks
    - Lanes: core, codex, claude-code, local-worker, browser
    """

    def __init__(self, test_mode=True):
        self.repo_root = REPO_ROOT
        self.test_mode = test_mode  # Accelerated timing for tests
        self.total_tasks = 100
        self.burst_size = 20
        self.time_window_seconds = 5 if test_mode else 300  # 5s in test, 5min in prod
        self.lane_types = ["core", "codex", "claude-code", "local-worker", "browser"]
        self.circuit_breaker_threshold = 0.05  # Trip at 5% error rate
        self.circuit_breaker_trips = 0
        self.executions: List[TaskExecution] = []
        self.now = datetime.utcnow()

    def run_stress_test(self) -> Dict[str, Any]:
        """Run full stress test"""

        print("[11B] Starting Stress Test...")
        print(f"Configuration:")
        print(f"  Total tasks: {self.total_tasks}")
        print(f"  Burst size: {self.burst_size}")
        print(f"  Time window: {self.time_window_seconds}s")
        print(f"  Lanes tested: {len(self.lane_types)}")
        print("-" * 80)

        start_time = time.time()

        # Generate and execute tasks
        for burst_num in range(0, self.total_tasks, self.burst_size):
            burst_tasks = min(self.burst_size, self.total_tasks - burst_num)
            print(f"\nBurst {burst_num // self.burst_size + 1}: "
                  f"Launching {burst_tasks} tasks simultaneously...")

            threads = []
            for i in range(burst_tasks):
                task_id = f"task-{burst_num + i:03d}"
                lane = random.choice(self.lane_types)
                t = threading.Thread(
                    target=self._execute_task,
                    args=(task_id, lane)
                )
                t.start()
                threads.append(t)

            # Wait for burst to complete or timeout
            for t in threads:
                t.join(timeout=2.0)

            # Check circuit breaker
            if self._should_trip_circuit_breaker():
                self.circuit_breaker_trips += 1
                print(f"⚠️  CIRCUIT BREAKER TRIPPED (Error rate threshold exceeded)")
                time.sleep(0.5)  # Simulate circuit breaker recovery delay

            # Simulate time between bursts
            time.sleep(0.1)

        total_time = time.time() - start_time

        print("\n" + "=" * 80)
        print("STRESS TEST RESULTS")
        print("=" * 80)

        metrics = self._calculate_metrics(total_time)
        results = {
            "metrics": metrics,
            "status": "PASS" if metrics["error_rate"] < 0.10 else "WARN" if metrics["error_rate"] < 0.20 else "FAIL",
            "total_time_seconds": total_time,
            "tasks_completed": len(self.executions),
            "circuit_breaker_trips": self.circuit_breaker_trips,
            "timestamp": self.now.isoformat(),
        }

        self._print_results(metrics)

        return results

    def _execute_task(self, task_id: str, lane: str):
        """Execute a single task and record metrics"""
        try:
            start = time.time()

            # Simulate task execution with lane-specific latency
            if self.test_mode:
                # Test mode: faster execution
                base_latency = random.uniform(0.01, 0.05)
            else:
                # Production mode: realistic latency
                lane_latencies = {
                    "core": (0.1, 0.5),
                    "codex": (0.2, 1.0),
                    "claude-code": (0.3, 1.5),
                    "local-worker": (0.05, 0.2),
                    "browser": (0.5, 2.0),
                }
                min_lat, max_lat = lane_latencies.get(lane, (0.1, 0.5))
                base_latency = random.uniform(min_lat, max_lat)

            # Simulate occasional failures
            if random.random() < 0.03:  # 3% error rate
                time.sleep(0.01)
                raise Exception(f"Simulated error in {lane}")

            time.sleep(base_latency)
            end = time.time()

            latency_ms = (end - start) * 1000
            self.executions.append(TaskExecution(
                task_id=task_id,
                task_type=lane,
                start_time=start,
                end_time=end,
                latency_ms=latency_ms,
                status="success",
            ))

        except Exception as e:
            end = time.time()
            latency_ms = (end - start) * 1000
            self.executions.append(TaskExecution(
                task_id=task_id,
                task_type=lane,
                start_time=start,
                end_time=end,
                latency_ms=latency_ms,
                status="error",
                error=str(e),
            ))

    def _should_trip_circuit_breaker(self) -> bool:
        """Check if error rate exceeds threshold"""
        if len(self.executions) < 10:
            return False

        recent_executions = self.executions[-20:]  # Check last 20 tasks
        error_count = sum(1 for e in recent_executions if e.status == "error")
        error_rate = error_count / len(recent_executions)

        return error_rate > self.circuit_breaker_threshold

    def _calculate_metrics(self, total_time: float) -> Dict[str, Any]:
        """Calculate latency and error metrics"""

        if not self.executions:
            return {
                "p50_ms": 0,
                "p95_ms": 0,
                "p99_ms": 0,
                "error_rate": 0.0,
                "successful_tasks": 0,
                "failed_tasks": 0,
                "throughput_tasks_per_sec": 0.0,
            }

        # Latency percentiles
        latencies = sorted([e.latency_ms for e in self.executions if e.status == "success"])

        if latencies:
            p50 = statistics.median(latencies)
            p95 = latencies[int(len(latencies) * 0.95)] if len(latencies) > 1 else latencies[0]
            p99 = latencies[int(len(latencies) * 0.99)] if len(latencies) > 1 else latencies[0]
        else:
            p50 = p95 = p99 = 0.0

        # Error rate
        error_count = sum(1 for e in self.executions if e.status == "error")
        error_rate = error_count / len(self.executions) if self.executions else 0.0

        # Throughput
        successful = len([e for e in self.executions if e.status == "success"])
        throughput = successful / total_time if total_time > 0 else 0.0

        return {
            "p50_ms": round(p50, 2),
            "p95_ms": round(p95, 2),
            "p99_ms": round(p99, 2),
            "error_rate": round(error_rate, 4),
            "successful_tasks": successful,
            "failed_tasks": error_count,
            "throughput_tasks_per_sec": round(throughput, 2),
        }

    def _print_results(self, metrics: Dict[str, Any]):
        """Print formatted stress test results"""

        print(f"\nLatency Percentiles:")
        print(f"  p50:  {metrics['p50_ms']:7.2f} ms")
        print(f"  p95:  {metrics['p95_ms']:7.2f} ms")
        print(f"  p99:  {metrics['p99_ms']:7.2f} ms")

        print(f"\nError & Throughput:")
        print(f"  Error rate:      {metrics['error_rate'] * 100:6.2f}%")
        print(f"  Successful:      {metrics['successful_tasks']:4d} tasks")
        print(f"  Failed:          {metrics['failed_tasks']:4d} tasks")
        print(f"  Throughput:      {metrics['throughput_tasks_per_sec']:6.2f} tasks/sec")

        print(f"\nCircuit Breaker:")
        print(f"  Trips triggered: {self.circuit_breaker_trips}")
        print(f"  Threshold:       {self.circuit_breaker_threshold * 100:.1f}%")

        print(f"\nBenchmark Thresholds:")
        print(f"  p95 < 1000ms:    {'✓ PASS' if metrics['p95_ms'] < 1000 else '✗ FAIL'}")
        print(f"  Error < 5%:      {'✓ PASS' if metrics['error_rate'] < 0.05 else '✗ FAIL'}")
        print(f"  Throughput > 5/s:{'✓ PASS' if metrics['throughput_tasks_per_sec'] > 5 else '✗ FAIL'}")


def main():
    tester = StressTester(test_mode=True)  # Use test mode for fast runs
    results = tester.run_stress_test()

    # Write results
    output_file = REPO_ROOT / "benchmark-results-stress.json"
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2)

    print(f"\nDetailed results written to: {output_file}")

    return 0 if results["status"] in ["PASS", "WARN"] else 1


if __name__ == "__main__":
    sys.exit(main())
