#!/usr/bin/env python3
"""
Phase 4B: Proof Watcher — Monitor proofs directory for new files

Watches proofs/YYYY-MM-DD/ directory and emits events for new proofs.
Used by WebSocket server and API server for real-time updates.
"""

import json
import os
from pathlib import Path
from datetime import datetime
from collections import deque, defaultdict
from typing import List, Dict, Any

REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"


class ProofWatcher:
    """Monitor proofs directory and manage proof queue."""
    
    def __init__(self, max_queue_size=1000):
        self.max_queue_size = max_queue_size
        self.proof_queue = deque(maxlen=max_queue_size)
        self.seen_files = set()
        self.lane_stats = defaultdict(lambda: {"count": 0, "successful": 0})
        self.hourly_counts = defaultdict(int)
    
    def load_all_proofs(self, date_str: str = None):
        """Load all proofs for a date (today if not specified)."""
        if not date_str:
            date_str = datetime.now().strftime("%Y-%m-%d")
        
        proofs = []
        date_dir = PROOFS_DIR / date_str
        if not date_dir.exists():
            return proofs
        
        for proof_file in sorted(date_dir.glob("*.json")):
            if proof_file.name.startswith("lane-health"):
                continue  # Skip health-check files
            
            try:
                with open(proof_file) as f:
                    proof = json.load(f)
                proofs.append(proof)
                self.proof_queue.append(proof)
                self._update_stats(proof)
            except (json.JSONDecodeError, IOError) as e:
                print(f"⚠️  Error loading {proof_file}: {e}")
        
        return proofs
    
    def _update_stats(self, proof: Dict[str, Any]):
        """Update lane statistics from proof."""
        lane = proof.get("routed_lane", "unknown")
        self.lane_stats[lane]["count"] += 1
        if proof.get("status") == "SUCCESS":
            self.lane_stats[lane]["successful"] += 1
        
        # Track hourly counts
        try:
            ts = datetime.fromisoformat(proof.get("execution_timestamp", "").replace("Z", "+00:00"))
            hour_key = ts.strftime("%Y-%m-%d %H:00")
            self.hourly_counts[hour_key] += 1
        except (ValueError, AttributeError):
            pass
    
    def get_recent_proofs(self, lane: str = None, count: int = 20) -> List[Dict]:
        """Get recent proofs, optionally filtered by lane."""
        if lane:
            filtered = [p for p in self.proof_queue if p.get("routed_lane") == lane]
        else:
            filtered = list(self.proof_queue)
        
        return filtered[-count:] if filtered else []
    
    def get_proof_stats(self, hours: int = 24) -> Dict[str, Any]:
        """Get statistics for proofs in last N hours."""
        cutoff_time = datetime.now().replace(minute=0, second=0, microsecond=0)
        stats = {
            "total_proofs": 0,
            "successful": 0,
            "blocked": 0,
            "error": 0,
            "timeout": 0,
            "avg_duration": 0.0,
            "by_lane": {},
            "by_risk": defaultdict(int)
        }
        
        total_duration = 0
        count = 0
        
        for proof in self.proof_queue:
            stats["total_proofs"] += 1
            
            status = proof.get("status", "unknown")
            if status == "SUCCESS":
                stats["successful"] += 1
            elif status == "BLOCKED":
                stats["blocked"] += 1
            elif status == "ERROR":
                stats["error"] += 1
            elif status == "TIMEOUT":
                stats["timeout"] += 1
            
            # Duration
            duration = proof.get("execution_duration_seconds", 0)
            total_duration += duration
            count += 1
            
            # By lane
            lane = proof.get("routed_lane", "unknown")
            if lane not in stats["by_lane"]:
                stats["by_lane"][lane] = {"count": 0, "successful": 0}
            stats["by_lane"][lane]["count"] += 1
            if status == "SUCCESS":
                stats["by_lane"][lane]["successful"] += 1
            
            # By risk
            risk = proof.get("risk_level", "unknown")
            stats["by_risk"][risk] += 1
        
        if count > 0:
            stats["avg_duration"] = round(total_duration / count, 2)
        
        stats["by_risk"] = dict(stats["by_risk"])
        return stats
    
    def detect_anomalies(self) -> List[Dict[str, Any]]:
        """Detect anomalies in recent proofs."""
        anomalies = []
        
        recent = list(self.proof_queue)[-100:] if self.proof_queue else []
        
        if not recent:
            return anomalies
        
        # Check for timeout chains
        timeout_count = sum(1 for p in recent if p.get("status") == "TIMEOUT")
        if timeout_count > len(recent) * 0.2:  # > 20% timeouts
            anomalies.append({
                "type": "high_timeout_rate",
                "severity": "high",
                "message": f"Timeout rate: {timeout_count}/{len(recent)} in last 100 proofs"
            })
        
        # Check for all errors
        error_count = sum(1 for p in recent if p.get("status") == "ERROR")
        if error_count > len(recent) * 0.3:  # > 30% errors
            anomalies.append({
                "type": "high_error_rate",
                "severity": "high",
                "message": f"Error rate: {error_count}/{len(recent)} in last 100 proofs"
            })
        
        # Check for blocked tasks
        blocked = [p for p in recent if p.get("status") == "BLOCKED"]
        if blocked:
            anomalies.append({
                "type": "blocked_tasks",
                "severity": "medium",
                "message": f"Found {len(blocked)} blocked tasks",
                "lanes": list(set(p.get("routed_lane") for p in blocked))
            })
        
        return anomalies


def main():
    """Test the watcher."""
    print("🔍 Proof Watcher Test")
    print("")
    
    watcher = ProofWatcher()
    proofs = watcher.load_all_proofs()
    
    print(f"  Loaded {len(proofs)} proofs")
    print(f"  Queue size: {len(watcher.proof_queue)}")
    print("")
    
    # Show stats
    stats = watcher.get_proof_stats()
    print(f"  Total proofs: {stats['total_proofs']}")
    print(f"  Successful: {stats['successful']}")
    print(f"  Blocked: {stats['blocked']}")
    print(f"  Error: {stats['error']}")
    print(f"  Timeout: {stats['timeout']}")
    print(f"  Avg duration: {stats['avg_duration']}s")
    print("")
    
    # Show by lane
    print("  By lane:")
    for lane, counts in stats['by_lane'].items():
        pct = round((counts['successful'] / counts['count'] * 100), 1) if counts['count'] > 0 else 0
        print(f"    {lane:20} {counts['count']:3} tasks, {pct:5.1f}% success")
    print("")
    
    # Show anomalies
    anomalies = watcher.detect_anomalies()
    if anomalies:
        print(f"  ⚠️  Anomalies detected: {len(anomalies)}")
        for anom in anomalies:
            print(f"    {anom['type']}: {anom['message']}")
    else:
        print("  ✓ No anomalies detected")


if __name__ == "__main__":
    main()
