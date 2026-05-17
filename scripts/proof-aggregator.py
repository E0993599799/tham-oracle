#!/usr/bin/env python3
"""
Phase 3C: Proof Aggregator — Daily summary generation

Reads all proofs from a date, generates:
1. router-stats-YYYY-MM-DD.json — structured stats
2. router-summary-YYYY-MM-DD.md — Obsidian-format summary  
3. router-insights-YYYY-MM-DD.json — actionable insights
"""

import json
import sys
from datetime import datetime
from pathlib import Path
from collections import defaultdict

REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"
OUTPUT_DIR = REPO_ROOT / "ψ" / "memory" / "resonance"

def load_proof_records(date_str):
    """Load all proof JSON files for a given date."""
    date_dir = PROOFS_DIR / date_str
    if not date_dir.exists():
        return []
    
    records = []
    for proof_file in date_dir.glob("*.json"):
        try:
            with open(proof_file) as f:
                records.append(json.load(f))
        except (json.JSONDecodeError, IOError):
            pass
    return records

def aggregate_stats(records):
    """Compute daily statistics from proof records."""
    if not records:
        return {
            "task_count": 0,
            "success_rate_pct": 0.0,
            "avg_duration_seconds": 0.0,
            "total_duration_seconds": 0.0,
            "risk_distribution": {},
            "status_distribution": {}
        }
    
    successful = sum(1 for r in records if r.get("status") == "SUCCESS")
    total_duration = sum(r.get("execution_duration_seconds", 0) for r in records)
    
    risk_dist = defaultdict(int)
    status_dist = defaultdict(int)
    
    for r in records:
        risk_dist[r.get("risk_level", "unknown")] += 1
        status_dist[r.get("status", "unknown")] += 1
    
    return {
        "task_count": len(records),
        "success_rate_pct": round((successful / len(records) * 100), 1) if records else 0.0,
        "avg_duration_seconds": round(total_duration / len(records), 2) if records else 0.0,
        "total_duration_seconds": round(total_duration, 2),
        "risk_distribution": dict(risk_dist),
        "status_distribution": dict(status_dist)
    }

def classify_by_intent(records):
    """Group records by intent signal."""
    by_intent = defaultdict(lambda: {"count": 0, "successful": 0, "avg_duration": 0.0})
    total_by_intent = defaultdict(float)
    
    for r in records:
        intent = r.get("context", {}).get("intent_signal", "unknown") if isinstance(r.get("context"), dict) else "unknown"
        by_intent[intent]["count"] += 1
        if r.get("status") == "SUCCESS":
            by_intent[intent]["successful"] += 1
        total_by_intent[intent] += r.get("execution_duration_seconds", 0)
    
    for intent in by_intent:
        count = by_intent[intent]["count"]
        by_intent[intent]["avg_duration"] = round(total_by_intent[intent] / count, 2) if count > 0 else 0.0
        by_intent[intent]["success_pct"] = round((by_intent[intent]["successful"] / count * 100), 1) if count > 0 else 0.0
    
    return dict(by_intent)

def classify_by_lane(records):
    """Group records by routed lane."""
    by_lane = defaultdict(lambda: {"count": 0, "successful": 0, "avg_duration": 0.0})
    total_by_lane = defaultdict(float)
    
    for r in records:
        lane = r.get("routed_lane", "unknown")
        by_lane[lane]["count"] += 1
        if r.get("status") == "SUCCESS":
            by_lane[lane]["successful"] += 1
        total_by_lane[lane] += r.get("execution_duration_seconds", 0)
    
    for lane in by_lane:
        count = by_lane[lane]["count"]
        by_lane[lane]["avg_duration"] = round(total_by_lane[lane] / count, 2) if count > 0 else 0.0
        by_lane[lane]["success_pct"] = round((by_lane[lane]["successful"] / count * 100), 1) if count > 0 else 0.0
    
    return dict(by_lane)

def detect_anomalies(records):
    """Find anomalies in proof records."""
    anomalies = []
    
    # Check for timeout chains
    timeout_count = sum(1 for r in records if r.get("status") == "TIMEOUT")
    if timeout_count > len(records) * 0.1:  # > 10% timeouts
        anomalies.append({
            "type": "high_timeout_rate",
            "severity": "high",
            "message": f"Timeout rate: {timeout_count}/{len(records)} tasks",
            "action": "Check lane health and timeouts"
        })
    
    # Check for blocked tasks
    blocked_count = sum(1 for r in records if r.get("status") == "BLOCKED")
    if blocked_count > 0:
        anomalies.append({
            "type": "blocked_tasks",
            "severity": "medium",
            "message": f"Blocked tasks: {blocked_count}",
            "action": "Review risk gates and fallback lanes"
        })
    
    # Check for high-risk tasks
    high_risk = [r for r in records if r.get("risk_level") == "high"]
    if high_risk:
        anomalies.append({
            "type": "high_risk_tasks",
            "severity": "medium",
            "message": f"High-risk tasks: {len(high_risk)}",
            "action": "Review high-risk routing decisions"
        })
    
    # Check for slow lanes
    by_lane = classify_by_lane(records)
    for lane, stats in by_lane.items():
        if stats["avg_duration"] > 10.0:  # > 10 seconds
            anomalies.append({
                "type": "slow_lane",
                "severity": "low",
                "lane": lane,
                "avg_duration_seconds": stats["avg_duration"],
                "action": "Consider fallback or route optimization"
            })
    
    return anomalies

def render_markdown_summary(date_str, stats, by_intent, by_lane, anomalies):
    """Render Obsidian-format markdown summary."""
    lines = [
        f"# Router Daily Summary — {date_str}",
        f"Generated: {datetime.now().isoformat()}",
        "",
        "## Overview",
        f"- **Tasks**: {stats['task_count']}",
        f"- **Success Rate**: {stats['success_rate_pct']}%",
        f"- **Avg Duration**: {stats['avg_duration_seconds']}s",
        f"- **Total Duration**: {stats['total_duration_seconds']}s",
        "",
        "## Risk Distribution",
    ]
    
    for risk, count in sorted(stats['risk_distribution'].items()):
        pct = round((count / stats['task_count'] * 100), 1) if stats['task_count'] > 0 else 0
        lines.append(f"- {risk}: {count} ({pct}%)")
    
    lines.extend([
        "",
        "## Status Distribution",
    ])
    
    for status, count in sorted(stats['status_distribution'].items()):
        pct = round((count / stats['task_count'] * 100), 1) if stats['task_count'] > 0 else 0
        lines.append(f"- {status}: {count} ({pct}%)")
    
    lines.extend([
        "",
        "## Performance by Lane",
        "",
        "| Lane | Tasks | Success | Avg Duration (s) |",
        "|------|-------|---------|------------------|",
    ])
    
    for lane, stats_lane in sorted(by_lane.items()):
        lines.append(f"| {lane} | {stats_lane['count']} | {stats_lane['success_pct']}% | {stats_lane['avg_duration']} |")
    
    if anomalies:
        lines.extend([
            "",
            "## Anomalies & Alerts",
            "",
        ])
        for anom in anomalies:
            lines.append(f"### {anom['type'].title()}")
            lines.append(f"**Severity**: {anom['severity'].upper()}")
            lines.append(f"**Message**: {anom['message']}")
            if 'lane' in anom:
                lines.append(f"**Lane**: {anom['lane']}")
            lines.append(f"**Action**: {anom['action']}")
            lines.append("")
    
    lines.extend([
        "## Proof Files",
        f"Location: `proofs/{date_str}/`",
        "",
        "---",
        "Generated by Phase 3 Proof Aggregator"
    ])
    
    return "\n".join(lines)

def main():
    """Main aggregation pipeline."""
    if len(sys.argv) < 2:
        print("Usage: python3 proof-aggregator.py YYYY-MM-DD")
        sys.exit(1)
    
    date_str = sys.argv[1]
    
    print(f"📊 Aggregating proofs for {date_str}")
    
    # Load proof records
    records = load_proof_records(date_str)
    print(f"  Found {len(records)} proof files")
    
    if not records:
        print("  No proofs found for this date")
        return
    
    # Aggregate
    stats = aggregate_stats(records)
    by_intent = classify_by_intent(records)
    by_lane = classify_by_lane(records)
    anomalies = detect_anomalies(records)
    
    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Write 3 output files
    # 1. Stats JSON
    stats_file = OUTPUT_DIR / f"router-stats-{date_str}.json"
    with open(stats_file, 'w') as f:
        json.dump({
            "date": date_str,
            "generated": datetime.now().isoformat(),
            "stats": stats,
            "by_intent": by_intent,
            "by_lane": by_lane,
        }, f, indent=2)
    print(f"  ✓ Stats: {stats_file}")
    
    # 2. Markdown summary
    summary_md = render_markdown_summary(date_str, stats, by_intent, by_lane, anomalies)
    summary_file = OUTPUT_DIR / f"router-summary-{date_str}.md"
    with open(summary_file, 'w') as f:
        f.write(summary_md)
    print(f"  ✓ Summary: {summary_file}")
    
    # 3. Insights JSON
    insights_file = OUTPUT_DIR / f"router-insights-{date_str}.json"
    with open(insights_file, 'w') as f:
        json.dump({
            "date": date_str,
            "generated": datetime.now().isoformat(),
            "anomalies": anomalies,
            "recommendations": [
                {"type": "slow_lanes", "action": "Consider optimizing or adding fallbacks for slow lanes"},
                {"type": "timeout_chains", "action": "Check lane health and increase timeouts if needed"},
                {"type": "blocked_tasks", "action": "Review risk gates and fallback coverage"},
            ]
        }, f, indent=2)
    print(f"  ✓ Insights: {insights_file}")
    
    print("")
    print(f"✅ Aggregation complete: {stats['task_count']} tasks, {stats['success_rate_pct']}% success")

if __name__ == "__main__":
    main()
