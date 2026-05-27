#!/bin/bash
# Tham Oracle — statusLine: show session duration + token usage
PROJECT_DIR="/home/user/.claude/projects/-mnt-d-01-Main-Work-Boots-Agentic-AI-mission-control-tham-oracle"
LATEST=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | head -1)
[ -z "$LATEST" ] && echo "ธาม | no session" && exit 0

python3 - "$LATEST" <<'EOF'
import json, sys
from datetime import datetime, timezone

lines = open(sys.argv[1]).readlines()
total_input = total_output = total_cache_read = total_cache_write = 0
first_ts = last_ts = None

for l in lines:
    try:
        d = json.loads(l)
        ts = d.get('timestamp', '')
        if ts:
            if not first_ts: first_ts = ts
            last_ts = ts
        u = d.get('usage') or d.get('message', {}).get('usage', {}) or {}
        total_input    += u.get('input_tokens', 0)
        total_output   += u.get('output_tokens', 0)
        total_cache_read  += u.get('cache_read_input_tokens', 0)
        total_cache_write += u.get('cache_creation_input_tokens', 0)
    except:
        pass

dur = '?'
if first_ts:
    try:
        start = datetime.fromisoformat(first_ts.replace('Z', '+00:00'))
        mins  = int((datetime.now(timezone.utc) - start).total_seconds() / 60)
        dur   = f'{mins}m' if mins < 60 else f'{mins//60}h{mins%60:02d}m'
    except:
        pass

out_k   = total_output // 1000
cache_m = total_cache_read / 1_000_000

print(f'⏱{dur} · out:{out_k}k · cache:{cache_m:.1f}M | ธาม')
EOF
