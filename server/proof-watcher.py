#!/usr/bin/env python3
"""
Proof Watcher - Monitor proof directory, maintain cache, query interface

Standalone service that can be imported by other modules.
Watches proofs/YYYY-MM-DD/ directory for new proof files.
Maintains in-memory cache of last 1000 proofs.
Provides query methods: recent proofs, stats by timerange.
"""

import json
from pathlib import Path
from datetime import datetime, timedelta
from collections import deque, defaultdict
import time
from typing import List, Dict, Optional


class ProofWatcher:
    def __init__(self, repo_root: Optional[Path] = None, max_cache=1000):
        """
        Initialize proof watcher.

        Args:
            repo_root: Root of tham-oracle repo. Defaults to parent of this file.
            max_cache: Maximum proofs to keep in memory (default 1000)
        """
        self.repo_root = repo_root or Path(__file__).parent.parent
        self.proofs = deque(maxlen=max_cache)
        self.by_lane = defaultdict(list)
        self.by_intent = defaultdict(list)
        self.by_status = defaultdict(list)
        self.last_checked = {}
        self.max_cache = max_cache

    def load_daily_proofs(self, date_str: str = None) -> int:
        """
        Load all proofs from proofs/YYYY-MM-DD/

        Args:
            date_str: Date string (YYYY-MM-DD). Defaults to today.

        Returns:
            Number of proofs loaded
        """
        if date_str is None:
            date_str = datetime.now().strftime("%Y-%m-%d")

        proof_dir = self.repo_root / "proofs" / date_str

        if not proof_dir.exists():
            return 0

        count = 0
        for json_file in sorted(proof_dir.glob("*.json")):
            # Skip health-check proofs
            if json_file.name.startswith("lane-health"):
                continue

            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    proof = json.load(f)

                    # Only load task proofs (have task_id)
                    if "task_id" in proof:
                        self._index_proof(proof)
                        self.proofs.append(proof)
                        count += 1

            except (json.JSONDecodeError, IOError) as e:
                print(f"✗ Error loading {json_file.name}: {e}")

        return count

    def _index_proof(self, proof: Dict):
        """Index proof by lane, intent, and status"""
        if "routed_lane" in proof:
            self.by_lane[proof["routed_lane"]].append(proof)

        if "intent" in proof:
            self.by_intent[proof["intent"]].append(proof)

        if "status" in proof:
            self.by_status[proof["status"]].append(proof)

    def get_recent_proofs(self, lane: Optional[str] = None, count: int = 20) -> List[Dict]:
        """
        Return last N proofs (optionally filtered by lane).

        Args:
            lane: Optional lane name to filter
            count: Number of proofs to return

        Returns:
            List of proof dicts (most recent last)
        """
        if lane and lane in self.by_lane:
            proofs = self.by_lane[lane]
        else:
            proofs = list(self.proofs)

        return proofs[-count:] if proofs else []

    def get_stats(self, hours: int = 1) -> Dict:
        """
        Return stats for last N hours.

        Args:
            hours: Number of hours to look back

        Returns:
            Dict with status counts, success rate, avg duration, by lane
        """
        from datetime import timezone

        # Use timezone-aware UTC for comparison
        cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours)
        cutoff_iso = cutoff_time.isoformat()

        stats = {
            "timerange_hours": hours,
            "start_time": cutoff_iso,
            "total_proofs": 0,
            "by_status": defaultdict(int),
            "by_lane": defaultdict(lambda: {"count": 0, "avg_duration": 0}),
            "success_count": 0,
            "failure_count": 0,
            "avg_duration_seconds": 0,
        }

        total_duration = 0
        lane_durations = defaultdict(list)

        for proof in self.proofs:
            # Parse timestamp
            timestamp_str = proof.get("execution_timestamp", "")
            if not timestamp_str:
                continue

            try:
                ts = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
            except (ValueError, AttributeError):
                continue

            if ts < cutoff_time:
                continue

            stats["total_proofs"] += 1

            # Count by status
            status = proof.get("status", "UNKNOWN")
            stats["by_status"][status] += 1

            if status == "SUCCESS":
                stats["success_count"] += 1
            elif status in ("FAILED", "ERROR"):
                stats["failure_count"] += 1

            # Accumulate duration
            duration = proof.get("execution_duration_seconds", 0)
            total_duration += duration

            # By lane
            lane = proof.get("routed_lane", "unknown")
            lane_durations[lane].append(duration)

        # Calculate averages
        if stats["total_proofs"] > 0:
            stats["avg_duration_seconds"] = total_duration / stats["total_proofs"]
            stats["success_rate"] = stats["success_count"] / stats["total_proofs"]
        else:
            stats["success_rate"] = 0.0

        # Per-lane stats
        for lane, durations in lane_durations.items():
            stats["by_lane"][lane] = {
                "count": len(durations),
                "avg_duration": sum(durations) / len(durations) if durations else 0,
            }

        return dict(stats)

    def poll_directory(self, date_str: str = None) -> int:
        """
        Poll proofs directory for new files (non-blocking).

        Args:
            date_str: Date string (YYYY-MM-DD). Defaults to today.

        Returns:
            Number of new proofs found
        """
        if date_str is None:
            date_str = datetime.now().strftime("%Y-%m-%d")

        proof_dir = self.repo_root / "proofs" / date_str

        if not proof_dir.exists():
            return 0

        count = 0
        for json_file in proof_dir.glob("*.json"):
            # Skip health-check proofs
            if json_file.name.startswith("lane-health"):
                continue

            stat = json_file.stat()
            file_key = str(json_file)

            # Check if file is new or modified
            if file_key not in self.last_checked or stat.st_mtime > self.last_checked[file_key]:
                try:
                    with open(json_file, 'r', encoding='utf-8') as f:
                        proof = json.load(f)

                        # Only load task proofs
                        if "task_id" in proof:
                            self._index_proof(proof)
                            self.proofs.append(proof)
                            self.last_checked[file_key] = stat.st_mtime
                            count += 1

                except (json.JSONDecodeError, IOError) as e:
                    print(f"✗ Error polling {json_file.name}: {e}")

        return count

    def clear_cache(self):
        """Clear all cached proofs"""
        self.proofs.clear()
        self.by_lane.clear()
        self.by_intent.clear()
        self.by_status.clear()
        self.last_checked.clear()

    def get_lane_stats(self, lane: str) -> Dict:
        """
        Get stats for a specific lane.

        Args:
            lane: Lane name

        Returns:
            Dict with counts and stats for that lane
        """
        if lane not in self.by_lane:
            return {"lane": lane, "count": 0, "proofs": []}

        proofs = self.by_lane[lane]
        statuses = defaultdict(int)
        total_duration = 0

        for proof in proofs:
            status = proof.get("status", "UNKNOWN")
            statuses[status] += 1
            total_duration += proof.get("execution_duration_seconds", 0)

        return {
            "lane": lane,
            "count": len(proofs),
            "status_breakdown": dict(statuses),
            "avg_duration_seconds": total_duration / len(proofs) if proofs else 0,
            "recent_proofs": list(proofs)[-5:],
        }


def demo_watcher():
    """Demo: Load and display stats"""
    print("Proof Watcher Demo")
    print("=" * 60)

    watcher = ProofWatcher()

    # Load today's proofs
    count = watcher.load_daily_proofs()
    print(f"\nLoaded {count} proofs from today")

    # Show recent proofs
    recent = watcher.get_recent_proofs(count=5)
    if recent:
        print(f"\nRecent 5 proofs:")
        for proof in recent:
            print(f"  {proof['task_id']}: {proof['status']} ({proof['routed_lane']})")

    # Show stats
    stats = watcher.get_stats(hours=24)
    print(f"\nStats (last 24 hours):")
    print(f"  Total proofs: {stats['total_proofs']}")
    print(f"  Success rate: {stats['success_rate']:.1%}")
    print(f"  Avg duration: {stats['avg_duration_seconds']:.2f}s")
    print(f"  By status: {dict(stats['by_status'])}")
    print(f"  By lane: {dict(stats['by_lane'])}")


if __name__ == "__main__":
    demo_watcher()
