#!/usr/bin/env python3
"""
Phase 3C: Proof Aggregator
Aggregate daily proof records into analytics summaries
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Dict, Tuple
from statistics import mean, StatisticsError

def load_proof_records(date_str: str) -> List[Dict]:
    """
    Load all proof records from proofs/YYYY-MM-DD/*.json

    Args:
        date_str: Date string in format YYYY-MM-DD

    Returns:
        List of proof record dictionaries (only task proofs with task_id field)
    """
    repo_root = Path(__file__).parent.parent
    proof_dir = repo_root / "proofs" / date_str

    if not proof_dir.exists():
        print(f"❌ Proof directory not found: {proof_dir}")
        return []

    records = []
    for json_file in sorted(proof_dir.glob("*.json")):
        try:
            with open(json_file, 'r') as f:
                record = json.load(f)
                # Only include records with task_id (actual proof records, not health probes)
                if "task_id" in record:
                    records.append(record)
        except json.JSONDecodeError as e:
            print(f"⚠️ Failed to parse {json_file.name}: {e}")
        except Exception as e:
            print(f"⚠️ Error reading {json_file.name}: {e}")

    return records


def aggregate_stats(records: List[Dict]) -> Dict:
    """
    Compute aggregated statistics from proof records

    Returns:
        Dictionary with aggregated stats
    """
    if not records:
        return {
            "total_tasks": 0,
            "success": 0,
            "success_rate_pct": 0.0,
            "blocked": 0,
            "timeout": 0,
            "error": 0,
            "avg_duration_seconds": 0.0,
            "risk_distribution": {"low": 0, "medium": 0, "high": 0},
            "lane_distribution": {},
            "anomalies_detected": 0
        }

    # Count by status
    statuses = {}
    for record in records:
        status = record.get("status", "UNKNOWN")
        statuses[status] = statuses.get(status, 0) + 1

    total = len(records)
    success_count = statuses.get("SUCCESS", 0)
    blocked_count = statuses.get("BLOCKED", 0)
    timeout_count = statuses.get("TIMEOUT", 0)
    error_count = statuses.get("ERROR", 0)

    success_rate = (success_count / total * 100) if total > 0 else 0.0

    # Average duration (only for completed tasks)
    durations = [
        r.get("execution_duration_seconds", 0)
        for r in records
        if r.get("execution_duration_seconds", 0) > 0
    ]
    avg_duration = mean(durations) if durations else 0.0

    # Risk distribution
    risk_dist = {"low": 0, "medium": 0, "high": 0}
    for record in records:
        risk = record.get("risk_level", "medium").lower()
        if risk in risk_dist:
            risk_dist[risk] += 1

    # Lane distribution
    lane_dist = {}
    for record in records:
        lane = record.get("routed_lane", "unknown")
        lane_dist[lane] = lane_dist.get(lane, 0) + 1

    return {
        "total_tasks": total,
        "success": success_count,
        "success_rate_pct": round(success_rate, 2),
        "blocked": blocked_count,
        "timeout": timeout_count,
        "error": error_count,
        "avg_duration_seconds": round(avg_duration, 2),
        "risk_distribution": risk_dist,
        "lane_distribution": lane_dist,
        "anomalies_detected": 0  # Will be updated after detect_anomalies()
    }


def classify_by_intent(records: List[Dict]) -> Dict[str, List[Dict]]:
    """
    Group records by intent signal (derived from task_id or proof_summary)

    Returns:
        Dictionary mapping intent → list of records
    """
    intents = {}
    intent_keywords = {
        "write_code": ["write", "code", "implementation", "coding"],
        "review": ["review", "audit", "security"],
        "search": ["search", "find", "query"],
        "classify": ["classify", "categorize", "parse"],
        "fix_bug": ["fix", "bug", "error", "debug"],
        "design": ["design", "architecture", "schema"],
        "refactor": ["refactor", "optimize", "performance"],
        "patch": ["patch", "update", "upgrade"],
    }

    for record in records:
        task_id = record.get("task_id", "").lower()
        proof_summary = record.get("proof_summary", "").lower()
        combined = f"{task_id} {proof_summary}"

        detected_intent = "unknown"
        for intent, keywords in intent_keywords.items():
            if any(kw in combined for kw in keywords):
                detected_intent = intent
                break

        if detected_intent not in intents:
            intents[detected_intent] = []
        intents[detected_intent].append(record)

    return intents


def classify_by_lane(records: List[Dict]) -> Dict[str, List[Dict]]:
    """
    Group records by routed lane

    Returns:
        Dictionary mapping lane → list of records
    """
    lanes = {}
    for record in records:
        lane = record.get("routed_lane", "unknown")
        if lane not in lanes:
            lanes[lane] = []
        lanes[lane].append(record)

    return lanes


def detect_anomalies(records: List[Dict]) -> List[Dict]:
    """
    Detect anomalies in proof records:
    - Consecutive timeouts (same lane)
    - High-risk tasks that got blocked
    - Unusually slow routes (> 3x avg duration)
    - Fallback chain usage (primary failed)

    Returns:
        List of anomaly records
    """
    anomalies = []

    if not records:
        return anomalies

    # Compute average duration (for slow route detection)
    durations = [
        r.get("execution_duration_seconds", 0)
        for r in records
        if r.get("execution_duration_seconds", 0) > 0
    ]
    avg_duration = mean(durations) if durations else 0.0

    # Group by lane to detect consecutive timeouts
    lanes = classify_by_lane(records)
    for lane, lane_records in lanes.items():
        timeout_count = sum(1 for r in lane_records if r.get("status") == "TIMEOUT")
        if timeout_count >= 2:
            anomalies.append({
                "type": "consecutive_timeouts",
                "lane": lane,
                "count": timeout_count,
                "recommendation": f"Check {lane} availability; consider load balancing or timeout increase"
            })

    # Detect high-risk tasks that were blocked
    for record in records:
        if record.get("status") == "BLOCKED" and record.get("risk_level") == "high":
            anomalies.append({
                "type": "high_risk_blocked",
                "task_id": record.get("task_id"),
                "risk_level": record.get("risk_level"),
                "recommendation": "Requires explicit human approval before retry"
            })

    # Detect slow routes
    for record in records:
        duration = record.get("execution_duration_seconds", 0)
        if duration > 0 and avg_duration > 0:
            slowdown_factor = duration / avg_duration
            if slowdown_factor > 3:
                anomalies.append({
                    "type": "slow_route",
                    "task_id": record.get("task_id"),
                    "duration_seconds": round(duration, 2),
                    "avg_duration_seconds": round(avg_duration, 2),
                    "slowdown_factor": round(slowdown_factor, 2),
                    "recommendation": "Investigate lane health or task complexity"
                })

    # Detect fallback usage (primary failed, fallback attempted)
    for record in records:
        primary = record.get("routed_lane")
        fallback = record.get("fallback_lane")
        proof = record.get("proof_summary", "")

        if fallback and primary and "failed" in proof.lower():
            anomalies.append({
                "type": "fallback_used",
                "task_id": record.get("task_id"),
                "primary_lane": primary,
                "fallback_lane": fallback,
                "status": record.get("status"),
                "recommendation": f"Primary {primary} failed; fallback {fallback} attempted. Monitor primary lane health."
            })

    return anomalies


def compute_lane_stats(records: List[Dict], lanes: Dict[str, List[Dict]]) -> Dict[str, Dict]:
    """
    Compute per-lane statistics

    Returns:
        Dictionary mapping lane → stats dict
    """
    lane_stats = {}

    for lane, lane_records in lanes.items():
        if not lane_records:
            continue

        total = len(lane_records)
        success = sum(1 for r in lane_records if r.get("status") == "SUCCESS")
        success_rate = (success / total * 100) if total > 0 else 0.0

        durations = [
            r.get("execution_duration_seconds", 0)
            for r in lane_records
            if r.get("execution_duration_seconds", 0) > 0
        ]
        avg_duration = mean(durations) if durations else 0.0

        lane_stats[lane] = {
            "tasks": total,
            "success": success,
            "success_rate_pct": round(success_rate, 2),
            "avg_duration_seconds": round(avg_duration, 2)
        }

    return lane_stats


def compute_intent_stats(intents: Dict[str, List[Dict]]) -> Dict[str, Dict]:
    """
    Compute per-intent statistics

    Returns:
        Dictionary mapping intent → stats dict
    """
    intent_stats = {}

    for intent, intent_records in intents.items():
        if not intent_records:
            continue

        total = len(intent_records)
        success = sum(1 for r in intent_records if r.get("status") == "SUCCESS")
        success_rate = (success / total * 100) if total > 0 else 0.0

        # Primary lane for this intent
        primary_lanes = {}
        for record in intent_records:
            lane = record.get("routed_lane", "unknown")
            primary_lanes[lane] = primary_lanes.get(lane, 0) + 1

        primary_lane = max(primary_lanes.items(), key=lambda x: x[1])[0] if primary_lanes else "unknown"

        intent_stats[intent] = {
            "tasks": total,
            "success": success,
            "success_rate_pct": round(success_rate, 2),
            "primary_lane": primary_lane
        }

    return intent_stats


def render_markdown_summary(
    date_str: str,
    stats: Dict,
    lane_stats: Dict[str, Dict],
    intent_stats: Dict[str, Dict],
    anomalies: List[Dict],
    records: List[Dict]
) -> str:
    """
    Render Markdown summary using template format

    Returns:
        Markdown string
    """
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    # Build lane table
    lane_rows = []
    for lane, lane_stat in sorted(lane_stats.items()):
        lane_rows.append(
            f"| {lane} | {lane_stat['tasks']} | {lane_stat['success_rate_pct']}% | {lane_stat['avg_duration_seconds']}s |"
        )
    lane_table = "\n".join(lane_rows) if lane_rows else "| (no lanes routed) | — | — | — |"

    # Build intent table
    intent_rows = []
    for intent, intent_stat in sorted(intent_stats.items()):
        intent_rows.append(
            f"| {intent} | {intent_stat['tasks']} | {intent_stat['success_rate_pct']}% | {intent_stat['primary_lane']} |"
        )
    intent_table = "\n".join(intent_rows) if intent_rows else "| (no intents classified) | — | — | — |"

    # Build anomalies section
    anomalies_section = ""
    if anomalies:
        anomalies_section = "\n## Anomalies Detected\n\n"
        for anom in anomalies:
            anomalies_section += f"- **{anom['type']}**: {anom.get('task_id', anom.get('lane', 'N/A'))}\n"
            anomalies_section += f"  - Recommendation: {anom.get('recommendation', 'N/A')}\n"
    else:
        anomalies_section = "\n## Anomalies Detected\n\nNo anomalies detected.\n"

    # Build success/error task lists
    success_tasks = [r for r in records if r.get("status") == "SUCCESS"]
    error_tasks = [r for r in records if r.get("status") == "ERROR"]
    blocked_tasks = [r for r in records if r.get("status") == "BLOCKED"]
    timeout_tasks = [r for r in records if r.get("status") == "TIMEOUT"]

    success_rows = []
    for r in success_tasks[:10]:  # Limit to first 10
        success_rows.append(
            f"| {r.get('task_id', '?')} | {r.get('routed_lane', '?')} | {r.get('execution_duration_seconds', 0)}s |"
        )
    success_table = "\n".join(success_rows) if success_rows else "| (no successful tasks) | | |"

    total_tasks = stats.get('total_tasks', 0)
    success = stats.get('success', 0)
    blocked = stats.get('blocked', 0)
    timeout = stats.get('timeout', 0)
    error = stats.get('error', 0)
    success_rate = stats.get('success_rate_pct', 0)
    avg_duration = stats.get('avg_duration_seconds', 0)
    
    markdown = f"""---
date: {date_str}
type: router-proof
phase: 3C-aggregation
source: proofs/{date_str}/
aggregated: true
---

# Router Proof Summary — {date_str}

## Quick Stats

| Metric | Value |
|---|---|
| **Tasks Routed** | {total_tasks} |
| **SUCCESS** | {success} |
| **BLOCKED** | {blocked} |
| **TIMEOUT** | {timeout} |
| **ERROR** | {error} |
| **Success Rate** | {success_rate}% |
| **Avg Duration** | {avg_duration}s |

## Success Rate by Lane

| Lane | Tasks | Success Rate | Avg Duration |
|---|---|---|---|
{lane_table}

## Success Rate by Intent

| Intent | Tasks | Success Rate | Primary Lane |
|---|---|---|---|
{intent_table}

## Risk Distribution

| Risk Level | Count | % |
|---|---|---|
| Low | {stats['risk_distribution']['low']} | {round(stats['risk_distribution']['low'] / stats['total_tasks'] * 100, 1) if stats['total_tasks'] > 0 else 0}% |
| Medium | {stats['risk_distribution']['medium']} | {round(stats['risk_distribution']['medium'] / stats['total_tasks'] * 100, 1) if stats['total_tasks'] > 0 else 0}% |
| High | {stats['risk_distribution']['high']} | {round(stats['risk_distribution']['high'] / stats['total_tasks'] * 100, 1) if stats['total_tasks'] > 0 else 0}% |

## Successful Tasks

| Task ID | Lane | Duration |
|---|---|---|
{success_table}

**Summary**: {stats['success']} tasks completed successfully. Avg gate time: {stats['avg_duration_seconds']}s.

## Error Tasks

**Count**: {len(error_tasks)}

{f'**Errors**:' if error_tasks else '**No errors recorded.**'}
{chr(10).join([f"- {r.get('task_id', '?')}: {r.get('proof_summary', 'No summary')[:100]}" for r in error_tasks[:5]])}

## Blocked Tasks

**Count**: {stats['blocked']}

{f'**Blocked**:' if blocked_tasks else '**No blocked tasks.**'}
{chr(10).join([f"- {r.get('task_id', '?')}: {r.get('proof_summary', 'No summary')[:100]}" for r in blocked_tasks[:5]])}

## Timeout Tasks

**Count**: {stats['timeout']}

{f'**Timeouts**:' if timeout_tasks else '**No timeout tasks.**'}
{chr(10).join([f"- {r.get('task_id', '?')}: {r.get('proof_summary', 'No summary')[:100]}" for r in timeout_tasks[:5]])}
{anomalies_section}

## Recommendations

1. Monitor lane health for any degraded services
2. Escalate blocked high-risk tasks for human review
3. Review slow routes to optimize execution
4. Track fallback usage to identify primary lane issues

---

**Generated**: {now}
**Aggregated from**: `proofs/{date_str}/`
**Source**: Phase 3C Proof Aggregator
"""

    return markdown


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 proof-aggregator.py YYYY-MM-DD")
        sys.exit(1)

    date_str = sys.argv[1]
    repo_root = Path(__file__).parent.parent

    # Load proof records
    print(f"📖 Loading proof records from proofs/{date_str}...")
    records = load_proof_records(date_str)

    if not records:
        print(f"❌ No proof records found for {date_str}")
        sys.exit(1)

    print(f"✅ Loaded {len(records)} proof records")

    # Aggregate statistics
    print("📊 Aggregating statistics...")
    stats = aggregate_stats(records)

    # Classify by lane and intent
    lanes = classify_by_lane(records)
    intents = classify_by_intent(records)

    # Detect anomalies
    print("🔍 Detecting anomalies...")
    anomalies = detect_anomalies(records)
    stats["anomalies_detected"] = len(anomalies)

    # Compute lane and intent stats
    lane_stats = compute_lane_stats(records, lanes)
    intent_stats = compute_intent_stats(intents)

    # Write JSON stats file
    stats_file = repo_root / "ψ/memory/resonance" / f"router-stats-{date_str}.json"
    stats_file.parent.mkdir(parents=True, exist_ok=True)

    print(f"📝 Writing stats to {stats_file.name}...")
    with open(stats_file, 'w') as f:
        json.dump(stats, f, indent=2)

    # Write JSON insights file
    insights_file = repo_root / "ψ/memory/resonance" / f"router-insights-{date_str}.json"
    insights = {
        "date": date_str,
        "anomalies_detected": len(anomalies),
        "anomalies": anomalies,
        "recommendations": [
            "Monitor lane health for degraded services",
            "Escalate blocked high-risk tasks for human review",
            "Review slow routes to optimize execution",
            "Track fallback usage to identify primary lane issues"
        ]
    }

    print(f"📝 Writing insights to {insights_file.name}...")
    with open(insights_file, 'w') as f:
        json.dump(insights, f, indent=2)

    # Render and write Markdown summary
    markdown = render_markdown_summary(date_str, stats, lane_stats, intent_stats, anomalies, records)
    summary_file = repo_root / "ψ/memory/resonance" / f"router-summary-{date_str}.md"

    print(f"📝 Writing summary to {summary_file.name}...")
    with open(summary_file, 'w') as f:
        f.write(markdown)

    # Print summary
    print("\n✅ Aggregation complete!")
    print(f"   Stats: {stats_file}")
    print(f"   Insights: {insights_file}")
    print(f"   Summary: {summary_file}")
    print(f"\n📊 Results:")
    print(f"   Total Tasks: {stats['total_tasks']}")
    print(f"   Success: {stats['success']} ({stats['success_rate_pct']}%)")
    print(f"   Blocked: {stats['blocked']}")
    print(f"   Timeout: {stats['timeout']}")
    print(f"   Error: {stats['error']}")
    print(f"   Anomalies: {len(anomalies)}")


if __name__ == "__main__":
    main()
