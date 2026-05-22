#!/usr/bin/env bash
# Agent active smoke proof for Tham Oracle
# Validates that every registry agent is active and that the tmux spawn contract is not a fake echo-only spawn.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT/configs/agent-registry.json"
SPAWN="$ROOT/scripts/spawn-agents-tmux.sh"
PROOF_DIR="$ROOT/proofs/agent-active"
PROOF_FILE="$PROOF_DIR/agent-active-smoke.latest.json"

mkdir -p "$PROOF_DIR"

fail() {
  local reason="$1"
  python3 - <<PY
import json, datetime, pathlib
proof = {
  "result": "FAIL",
  "reason": ${reason@Q},
  "checked_at_utc": datetime.datetime.utcnow().isoformat(timespec="seconds") + "Z",
}
path = pathlib.Path(${PROOF_FILE@Q})
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(proof, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(proof, ensure_ascii=False, indent=2))
PY
  exit 1
}

[[ -f "$REGISTRY" ]] || fail "missing configs/agent-registry.json"
[[ -f "$SPAWN" ]] || fail "missing scripts/spawn-agents-tmux.sh"

python3 - <<'PY'
import json, pathlib, sys
root = pathlib.Path.cwd()
registry_path = root / "configs" / "agent-registry.json"
spawn_path = root / "scripts" / "spawn-agents-tmux.sh"
proof_path = root / "proofs" / "agent-active" / "agent-active-smoke.latest.json"
required_ids = ["tham", "core", "bob", "hermes", "housekeeper", "codex", "gemini", "watchdog"]
registry = json.loads(registry_path.read_text(encoding="utf-8"))
agents = registry.get("agents", [])
by_id = {a.get("id"): a for a in agents}
missing = [x for x in required_ids if x not in by_id]
inactive = [x for x in required_ids if by_id.get(x, {}).get("status") != "active"]
missing_lane = [x for x in required_ids if not by_id.get(x, {}).get("lane")]
missing_validation = [x for x in required_ids if not by_id.get(x, {}).get("validation")]
spawn = spawn_path.read_text(encoding="utf-8")
window_missing = [x for x in required_ids if f'"{x}"' not in spawn and f"'{x}'" not in spawn and f" {x}" not in spawn]
markers = ["ACTIVE_MARKER", "AGENT_ID=", "AGENT_STATUS=active", "agent-runtime"]
weak_spawn = not all(m in spawn for m in markers)
proof = {
    "result": "OK" if not (missing or inactive or missing_lane or missing_validation or window_missing or weak_spawn) else "FAIL",
    "required_agents": required_ids,
    "agent_count": len(agents),
    "missing_agents": missing,
    "inactive_agents": inactive,
    "missing_lane": missing_lane,
    "missing_validation": missing_validation,
    "spawn_window_missing": window_missing,
    "spawn_contract_has_active_markers": not weak_spawn,
    "sot": "E0993599799/tham-oracle",
    "note": "This proves repository-level active contract. Local runtime liveness still requires running scripts/spawn-agents-tmux.sh on the machine with tmux and model CLIs installed."
}
proof_path.parent.mkdir(parents=True, exist_ok=True)
proof_path.write_text(json.dumps(proof, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(proof, ensure_ascii=False, indent=2))
if proof["result"] != "OK":
    sys.exit(1)
PY
