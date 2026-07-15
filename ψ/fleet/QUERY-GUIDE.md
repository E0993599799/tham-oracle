# Fleet Status Query Guide

> **Goal**: Fast, human-friendly queries on the broadcast log. Use `jq` for parsing, grep for scanning.

**Log Location**: `ψ/fleet/BROADCAST-LOG.ndjson` (one JSON event per line)

---

## Quick Queries

### 1. What did Oracle X do today?

```bash
ORACLE="Luxi"
TODAY="2026-07-16"

jq "select(.oracle == \"$ORACLE\") | select(.timestamp | startswith(\"$TODAY\"))" ψ/fleet/BROADCAST-LOG.ndjson
```

**Output**:
```json
{"timestamp":"2026-07-16T08:12:00Z","oracle":"Luxi","event_type":"oracle:session_start","project":"luxi-oracle","message":"UI theme refactor","severity":"info","tags":["frontend"],"details":{}}
{"timestamp":"2026-07-16T11:45:23Z","oracle":"Luxi","event_type":"commit:pushed","project":"luxi-oracle","message":"3 commits: theme inheritance fix","severity":"info","tags":[],"details":{}}
{"timestamp":"2026-07-16T12:00:00Z","oracle":"Luxi","event_type":"oracle:session_end","project":"luxi-oracle","message":"Session complete: 3h 48m","severity":"info","tags":[],"details":{}}
```

---

### 2. Which projects deployed this week?

```bash
WEEK_START="2026-07-14"

jq "select(.event_type == \"project:deployed\") | select(.timestamp | startswith(\"2026-07-1\"))" ψ/fleet/BROADCAST-LOG.ndjson | \
  jq -s 'group_by(.project) | map({project: .[0].project, count: length, last: .[-1].timestamp})'
```

**Output**:
```json
[
  {"project": "captain-maid", "count": 2, "last": "2026-07-16T06:30:00Z"},
  {"project": "orry-website", "count": 1, "last": "2026-07-15T14:22:00Z"}
]
```

---

### 3. Any active blockers?

```bash
jq 'select(.severity == "critical" or .severity == "error")' ψ/fleet/BROADCAST-LOG.ndjson | \
  jq -r '"\(.timestamp | .[0:16]): [\(.oracle)] \(.message)"'
```

**Output**:
```
2026-07-16 14:45: [Agis] Blocker: Database access pending — 12h SLA
2026-07-15 09:20: [Tham] Error: Package manager conflict in build
```

---

### 4. Token budget alerts (tier changes)

```bash
jq 'select(.event_type == "oracle:token_tier_change")' ψ/fleet/BROADCAST-LOG.ndjson | \
  jq -r '"\(.timestamp | .[0:16]): [\(.oracle)] \(.details.previous_tier) → \(.details.current_tier)"'
```

**Output**:
```
2026-07-16 15:00: [Zeus] green → yellow
2026-07-16 18:30: [Luxi] yellow → green
```

---

### 5. Fleet summary (all events this week)

```bash
echo "=== Fleet Status Summary (2026-07-14 to 2026-07-16) ==="
echo ""
echo "🟢 Active Oracles:"
jq 'select(.event_type == "oracle:session_start") | select(.timestamp | startswith("2026-07-1"))' ψ/fleet/BROADCAST-LOG.ndjson | \
  jq -r '.oracle' | sort | uniq -c | column -t

echo ""
echo "📦 Deployments:"
jq 'select(.event_type == "project:deployed") | select(.timestamp | startswith("2026-07-1"))' ψ/fleet/BROADCAST-LOG.ndjson | \
  jq -r '"\(.project): \(.timestamp | .[0:10])"' | sort | uniq

echo ""
echo "🔴 Critical Issues:"
jq 'select(.severity == "critical") | select(.timestamp | startswith("2026-07-1"))' ψ/fleet/BROADCAST-LOG.ndjson | \
  jq -r '"\(.oracle): \(.message)"' || echo "None"
```

---

## Advanced: Aliases for Shell

Add to `~/.bashrc` or CLAUDE.md:

```bash
# Fleet queries
fleet-today() {
  ORACLE="${1:-*}"
  jq "select(.oracle | startswith(\"$ORACLE\")) | select(.timestamp | startswith(\"$(date +%Y-%m-%d)\"))" ψ/fleet/BROADCAST-LOG.ndjson
}

fleet-blockers() {
  jq 'select(.severity == "critical" or .severity == "error")' ψ/fleet/BROADCAST-LOG.ndjson | jq -r '"\(.timestamp | .[0:16]): [\(.oracle)] \(.message)"'
}

fleet-deployed() {
  jq 'select(.event_type == "project:deployed")' ψ/fleet/BROADCAST-LOG.ndjson | jq -r '"\(.project): \(.timestamp | .[0:10])"' | sort | uniq
}

# Usage:
# fleet-today Luxi              → all Luxi events today
# fleet-blockers                → all blockers (any age)
# fleet-deployed                → all deployments (any age)
```

---

## Validation

Check log integrity before querying:

```bash
# Validate all JSON objects
jq -e . ψ/fleet/BROADCAST-LOG.ndjson > /dev/null && echo "✓ Valid" || echo "✗ Corrupt"

# Count events by type
jq -r '.event_type' ψ/fleet/BROADCAST-LOG.ndjson | sort | uniq -c

# Newest event timestamp
jq -r '.timestamp' ψ/fleet/BROADCAST-LOG.ndjson | sort | tail -1
```

---

## Troubleshooting

**"jq: command not found"** → Install jq: `apt install jq` (Linux), `brew install jq` (Mac)

**"BROADCAST-LOG.ndjson: No such file"** → File hasn't been created yet. Run first session and emit an event.

**"parse error: Invalid numeric literal"** → Malformed JSON in one line. Check with:
```bash
grep -vE '^{.*}$' ψ/fleet/BROADCAST-LOG.ndjson  # Shows invalid lines
```

---

**Last Updated**: 2026-07-16  
**Schema**: See `ψ/fleet/schema.json`
