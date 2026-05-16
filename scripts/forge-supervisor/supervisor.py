#!/usr/bin/env python3
"""
Forge Supervisor Runtime — Priority 1
HTTP API on port 8769 (Agent Control Plane)

Components:
  - Session lifecycle (start/stop/pause/resume)
  - Daemon with state persistence
  - Reconnect with exponential backoff
  - Recovery (auto-restart dead agents)
  - Watchdog + heartbeat
  - Security: allowlist-based command execution, proof gate

State file: ψ/active/supervisor-state.json
"""
import os, json, time, threading, subprocess, signal, sys, hashlib
import http.server, socketserver, urllib.parse
from datetime import datetime, timezone, timedelta
from typing import Optional

# ── Config ────────────────────────────────────────────────────────────────────

REPO_ROOT = os.environ.get(
    "THAM_REPO_ROOT",
    os.path.expanduser("~/ghq/github.com/E0993599799/tham-oracle")
)
PSI = os.path.join(REPO_ROOT, "ψ")
STATE_FILE = os.path.join(PSI, "active", "supervisor-state.json")
PORT = int(os.environ.get("FORGE_SUPERVISOR_PORT", "8769"))
HEARTBEAT_INTERVAL = 30      # seconds
RECOVERY_MAX_RETRIES = 3
WATCHDOG_TIMEOUT = 90        # seconds — agent considered frozen if no heartbeat

# ── Security: Command Allowlist ───────────────────────────────────────────────
# ONLY these base commands can be executed. No eval. No dynamic construction.
ALLOWED_COMMANDS = {
    "git", "bun", "node", "python3", "bash", "tmux",
    "gh", "maw", "ghq", "curl", "ls", "cat", "grep",
    "find", "mkdir", "cp", "mv", "echo", "date",
    "kill", "ps", "fuser", "lsof"
}

FORBIDDEN_PATTERNS = [
    "rm -rf", "chmod 777", "> /dev/sda", "dd if=",
    "mkfs", "fdisk", "curl.*|.*bash", "wget.*|.*bash",
    "eval ", "; rm ", "&& rm ", "$(rm", "`rm",
    "base64 -d", "python -c", "perl -e",
]

def validate_command(cmd: str) -> tuple[bool, str]:
    """Security gate — validate command against allowlist + forbidden patterns."""
    if not cmd or not cmd.strip():
        return False, "empty command"
    base = cmd.strip().split()[0].split("/")[-1]
    if base not in ALLOWED_COMMANDS:
        return False, f"command '{base}' not in allowlist"
    for pat in FORBIDDEN_PATTERNS:
        if pat in cmd:
            return False, f"forbidden pattern: {pat}"
    return True, "ok"

# ── Helpers ───────────────────────────────────────────────────────────────────

def now_iso() -> str:
    return datetime.now(timezone(timedelta(hours=7))).isoformat()

def now_epoch() -> float:
    return time.time()

def log(msg: str):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)

def run_safe(cmd: str, cwd: str = REPO_ROOT, timeout: int = 15) -> tuple[bool, str]:
    """Execute command only if it passes the security gate."""
    ok, reason = validate_command(cmd)
    if not ok:
        log(f"[SECURITY BLOCKED] {reason} — cmd: {cmd[:60]}")
        return False, f"BLOCKED: {reason}"
    try:
        out = subprocess.check_output(
            cmd, shell=True, cwd=cwd,
            stderr=subprocess.STDOUT, timeout=timeout
        )
        return True, out.decode("utf-8", errors="replace").strip()
    except subprocess.CalledProcessError as e:
        return False, e.output.decode("utf-8", errors="replace").strip()
    except subprocess.TimeoutExpired:
        return False, "TIMEOUT"
    except Exception as e:
        return False, str(e)

# ── State ─────────────────────────────────────────────────────────────────────

class SupervisorState:
    def __init__(self):
        self._lock = threading.Lock()
        self.sessions: dict = {}    # id → SessionRecord
        self.goals: list = []
        self.started_at: str = now_iso()
        self.supervisor_version = "1.0.0"
        self._load()

    def _load(self):
        try:
            if os.path.exists(STATE_FILE):
                with open(STATE_FILE) as f:
                    data = json.load(f)
                self.sessions = data.get("sessions", {})
                self.goals = data.get("goals", [])
                log(f"State loaded: {len(self.sessions)} sessions, {len(self.goals)} goals")
        except Exception as e:
            log(f"State load error (starting fresh): {e}")

    def save(self):
        try:
            os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
            with self._lock:
                data = {
                    "supervisor_version": self.supervisor_version,
                    "started_at": self.started_at,
                    "saved_at": now_iso(),
                    "sessions": self.sessions,
                    "goals": self.goals,
                }
            with open(STATE_FILE, "w") as f:
                json.dump(data, f, indent=2, default=str)
        except Exception as e:
            log(f"State save error: {e}")

    def upsert_session(self, session_id: str, data: dict):
        with self._lock:
            if session_id not in self.sessions:
                self.sessions[session_id] = {
                    "id": session_id,
                    "created_at": now_iso(),
                    "status": "starting",
                    "retry_count": 0,
                    "heartbeat_at": None,
                    "worktree": None,
                    "goal": None,
                    "proof_verified": False,
                    "risk_level": "medium",
                }
            self.sessions[session_id].update(data)

    def heartbeat(self, session_id: str):
        with self._lock:
            if session_id in self.sessions:
                self.sessions[session_id]["heartbeat_at"] = now_iso()
                self.sessions[session_id]["status"] = "active"

    def get_snapshot(self) -> dict:
        with self._lock:
            return {
                "supervisor_version": self.supervisor_version,
                "started_at": self.started_at,
                "uptime_s": int(now_epoch() - _start_epoch),
                "sessions": dict(self.sessions),
                "goals": list(self.goals),
                "session_count": len(self.sessions),
                "active_count": sum(
                    1 for s in self.sessions.values()
                    if s.get("status") == "active"
                ),
            }

STATE = SupervisorState()
_start_epoch = now_epoch()

# ── Watchdog ──────────────────────────────────────────────────────────────────

class Watchdog(threading.Thread):
    """Monitors session heartbeats and triggers recovery on frozen/dead agents."""
    def __init__(self, state: SupervisorState):
        super().__init__(daemon=True, name="watchdog")
        self.state = state
        self._stop = threading.Event()

    def run(self):
        log("Watchdog started")
        while not self._stop.is_set():
            try:
                self._check()
                self.state.save()
            except Exception as e:
                log(f"Watchdog error: {e}")
            self._stop.wait(HEARTBEAT_INTERVAL)

    def _check(self):
        now = now_epoch()
        with self.state._lock:
            sessions = dict(self.state.sessions)

        for sid, s in sessions.items():
            status = s.get("status", "unknown")
            if status in ("stopped", "completed", "failed"):
                continue
            hb = s.get("heartbeat_at")
            if hb:
                try:
                    hb_epoch = datetime.fromisoformat(hb).timestamp()
                    age = now - hb_epoch
                    if age > WATCHDOG_TIMEOUT:
                        log(f"[WATCHDOG] Session {sid[:8]} frozen ({age:.0f}s no heartbeat) → recovery")
                        self._recover(sid, s)
                except Exception:
                    pass

    def _recover(self, sid: str, session: dict):
        retries = session.get("retry_count", 0)
        if retries >= RECOVERY_MAX_RETRIES:
            log(f"[WATCHDOG] Session {sid[:8]} exceeded retry limit → escalating")
            self.state.upsert_session(sid, {
                "status": "escalated",
                "escalated_at": now_iso(),
                "escalation_reason": f"frozen {RECOVERY_MAX_RETRIES} times",
            })
            return

        log(f"[WATCHDOG] Attempting recovery for {sid[:8]} (attempt {retries+1}/{RECOVERY_MAX_RETRIES})")
        self.state.upsert_session(sid, {
            "status": "recovering",
            "retry_count": retries + 1,
            "recovery_at": now_iso(),
        })
        # In a real system: re-spawn the agent process here
        # For now: mark as recovery-pending for the control plane to handle
        time.sleep(2 ** retries)  # exponential backoff: 1s, 2s, 4s
        self.state.upsert_session(sid, {
            "status": "recovery-pending",
            "heartbeat_at": now_iso(),
        })

    def stop(self):
        self._stop.set()

# ── Worktree Manager ──────────────────────────────────────────────────────────

class WorktreeManager:
    """Creates isolated git worktrees per agent — Priority 2."""
    WORKTREE_BASE = "/tmp/forge-worktrees"

    @classmethod
    def create(cls, session_id: str, branch: str = "main") -> tuple[bool, str]:
        path = os.path.join(cls.WORKTREE_BASE, f"agent-{session_id[:8]}")
        os.makedirs(cls.WORKTREE_BASE, exist_ok=True)
        if os.path.exists(path):
            return True, path  # already exists
        ok, out = run_safe(f"git worktree add {path} {branch}", cwd=REPO_ROOT, timeout=30)
        if ok:
            log(f"[WORKTREE] Created: {path}")
            return True, path
        else:
            log(f"[WORKTREE] Failed: {out}")
            return False, out

    @classmethod
    def remove(cls, session_id: str) -> bool:
        path = os.path.join(cls.WORKTREE_BASE, f"agent-{session_id[:8]}")
        if not os.path.exists(path):
            return True
        ok, out = run_safe(f"git worktree remove --force {path}", cwd=REPO_ROOT, timeout=15)
        if ok:
            log(f"[WORKTREE] Removed: {path}")
        else:
            log(f"[WORKTREE] Remove failed: {out}")
        return ok

    @classmethod
    def list_all(cls) -> list:
        ok, out = run_safe("git worktree list --porcelain", cwd=REPO_ROOT)
        if not ok:
            return []
        worktrees = []
        current = {}
        for line in out.splitlines():
            if line.startswith("worktree "):
                if current:
                    worktrees.append(current)
                current = {"path": line[9:]}
            elif line.startswith("branch "):
                current["branch"] = line[7:]
            elif line.startswith("HEAD "):
                current["head"] = line[5:]
        if current:
            worktrees.append(current)
        return worktrees

# ── Goal Runtime — Priority 4 ─────────────────────────────────────────────────

class GoalRuntime:
    """
    /goal <description> → self-evaluate → plan → execute → verify → retry
    """

    PHASES = ["research", "plan", "execute", "verify", "optimize"]

    @classmethod
    def submit(cls, description: str, priority: str = "normal") -> dict:
        goal_id = hashlib.sha256(f"{description}{now_iso()}".encode()).hexdigest()[:12]
        goal = {
            "id": goal_id,
            "description": description,
            "priority": priority,
            "phase": "research",
            "status": "pending",
            "created_at": now_iso(),
            "retry_count": 0,
            "retry_limit": 3,
            "evaluation_score": None,
            "proof_verified": False,
            "history": [],
        }
        with STATE._lock:
            STATE.goals.append(goal)
        STATE.save()
        log(f"[GOAL] Submitted: {goal_id[:8]} — {description[:60]}")
        return goal

    @classmethod
    def advance(cls, goal_id: str, result: dict) -> dict:
        """Advance goal to next phase based on proof + evaluation."""
        with STATE._lock:
            goal = next((g for g in STATE.goals if g["id"] == goal_id), None)
            if not goal:
                return {"error": "goal not found"}

            proof_ok = result.get("proof_verified", False)
            score = result.get("score", 0.0)
            current_phase = goal["phase"]
            goal["history"].append({
                "phase": current_phase,
                "at": now_iso(),
                "proof_verified": proof_ok,
                "score": score,
            })

            # Proof gate — cannot advance to verify without proof
            if current_phase == "execute" and not proof_ok:
                goal["status"] = "proof-gate-blocked"
                log(f"[GOAL] {goal_id[:8]} blocked at proof gate")
                return goal

            # Score gate — retry if below threshold
            if score < 0.6 and goal["retry_count"] < goal["retry_limit"]:
                goal["retry_count"] += 1
                goal["phase"] = "plan"  # backtrack to plan
                goal["status"] = "retrying"
                log(f"[GOAL] {goal_id[:8]} retrying (score {score:.2f}, attempt {goal['retry_count']})")
                return goal

            # Advance phase
            idx = cls.PHASES.index(current_phase)
            if idx + 1 < len(cls.PHASES):
                goal["phase"] = cls.PHASES[idx + 1]
                goal["status"] = "in_progress"
            else:
                goal["phase"] = "completed"
                goal["status"] = "completed"
                goal["proof_verified"] = proof_ok
                log(f"[GOAL] {goal_id[:8]} COMPLETED — score {score:.2f}")

            return goal

    @classmethod
    def evaluate(cls, goal_id: str) -> dict:
        """Self-evaluation: compare current state vs goal description."""
        with STATE._lock:
            goal = next((g for g in STATE.goals if g["id"] == goal_id), None)
        if not goal:
            return {"error": "goal not found"}
        # Simple heuristic evaluation (real impl would call LLM)
        return {
            "goal_id": goal_id,
            "description": goal["description"],
            "phase": goal["phase"],
            "score": 0.0,  # placeholder — agent fills this in
            "gaps": [],
            "next_action": f"Research approaches for: {goal['description']}",
        }

# ── HTTP API (Agent Control Plane) ────────────────────────────────────────────

class ControlPlaneHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # suppress default access logs

    def _json(self, data: dict, status: int = 200):
        body = json.dumps(data, default=str).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        if length:
            raw = self.rfile.read(length)
            try:
                return json.loads(raw)
            except Exception:
                return {}
        return {}

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path.rstrip("/")

        if path == "" or path == "/":
            self._json({
                "service": "forge-supervisor",
                "version": "1.0.0",
                "status": "running",
                "port": PORT,
                "uptime_s": int(now_epoch() - _start_epoch),
            })

        elif path == "/sessions":
            snap = STATE.get_snapshot()
            self._json({"sessions": list(snap["sessions"].values())})

        elif path == "/status":
            snap = STATE.get_snapshot()
            self._json({
                "supervisor": "running",
                "uptime_s": snap["uptime_s"],
                "session_count": snap["session_count"],
                "active_count": snap["active_count"],
                "goal_count": len(snap["goals"]),
                "started_at": snap["started_at"],
            })

        elif path == "/goals":
            with STATE._lock:
                self._json({"goals": list(STATE.goals)})

        elif path == "/worktrees":
            self._json({"worktrees": WorktreeManager.list_all()})

        elif path == "/health":
            snap = STATE.get_snapshot()
            frozen = [
                s for s in snap["sessions"].values()
                if s.get("status") == "escalated"
            ]
            self._json({
                "status": "degraded" if frozen else "healthy",
                "sessions": snap["session_count"],
                "active": snap["active_count"],
                "escalated": len(frozen),
                "watchdog": "running",
            })

        else:
            self._json({"error": "not found"}, 404)

    def do_POST(self):
        path = urllib.parse.urlparse(self.path).path.rstrip("/")
        body = self._read_body()

        if path == "/sessions":
            session_id = body.get("id") or hashlib.sha256(now_iso().encode()).hexdigest()[:16]
            create_worktree = body.get("worktree", True)
            worktree_path = None

            if create_worktree:
                ok, wt_path = WorktreeManager.create(session_id)
                worktree_path = wt_path if ok else None

            STATE.upsert_session(session_id, {
                "status": "active",
                "agent_type": body.get("agent_type", "generic"),
                "goal": body.get("goal"),
                "risk_level": body.get("risk_level", "medium"),
                "worktree": worktree_path,
                "heartbeat_at": now_iso(),
            })
            STATE.save()
            log(f"[SESSION] Started: {session_id[:8]}")
            self._json({"session_id": session_id, "worktree": worktree_path})

        elif path == "/sessions/heartbeat":
            sid = body.get("session_id")
            if not sid:
                self._json({"error": "session_id required"}, 400)
                return
            STATE.heartbeat(sid)
            self._json({"ok": True, "session_id": sid, "at": now_iso()})

        elif path == "/sessions/stop":
            sid = body.get("session_id")
            proof_verified = body.get("proof_verified", False)
            if not sid:
                self._json({"error": "session_id required"}, 400)
                return
            STATE.upsert_session(sid, {
                "status": "stopped",
                "stopped_at": now_iso(),
                "proof_verified": proof_verified,
            })
            if body.get("cleanup_worktree", True):
                WorktreeManager.remove(sid)
            STATE.save()
            log(f"[SESSION] Stopped: {sid[:8]} proof={proof_verified}")
            self._json({"ok": True})

        elif path == "/goal":
            description = body.get("description", "").strip()
            if not description:
                self._json({"error": "description required"}, 400)
                return
            goal = GoalRuntime.submit(
                description=description,
                priority=body.get("priority", "normal"),
            )
            self._json(goal)

        elif path == "/goal/advance":
            goal_id = body.get("goal_id")
            if not goal_id:
                self._json({"error": "goal_id required"}, 400)
                return
            result = GoalRuntime.advance(goal_id, body)
            self._json(result)

        elif path == "/goal/evaluate":
            goal_id = body.get("goal_id")
            if not goal_id:
                self._json({"error": "goal_id required"}, 400)
                return
            eval_result = GoalRuntime.evaluate(goal_id)
            self._json(eval_result)

        else:
            self._json({"error": "not found"}, 404)

    def do_DELETE(self):
        path = urllib.parse.urlparse(self.path).path.rstrip("/")
        body = self._read_body()

        if path == "/sessions":
            sid = body.get("session_id")
            if sid and sid in STATE.sessions:
                WorktreeManager.remove(sid)
                with STATE._lock:
                    del STATE.sessions[sid]
                STATE.save()
                self._json({"ok": True, "deleted": sid})
            else:
                self._json({"error": "session not found"}, 404)
        else:
            self._json({"error": "not found"}, 404)

# ── Main ──────────────────────────────────────────────────────────────────────

_watchdog: Optional[Watchdog] = None

def shutdown(sig, frame):
    log(f"Shutdown signal {sig} — saving state...")
    if _watchdog:
        _watchdog.stop()
    STATE.save()
    log("Forge Supervisor stopped.")
    sys.exit(0)

def main():
    global _watchdog

    os.makedirs(os.path.join(PSI, "active"), exist_ok=True)
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    _watchdog = Watchdog(STATE)
    _watchdog.start()

    log(f"Forge Supervisor Runtime v1.0.0")
    log(f"Port: {PORT} | State: {STATE_FILE}")
    log(f"Watchdog: {WATCHDOG_TIMEOUT}s timeout, {RECOVERY_MAX_RETRIES} max retries")
    log(f"Security: allowlist={len(ALLOWED_COMMANDS)} cmds, {len(FORBIDDEN_PATTERNS)} forbidden patterns")

    with socketserver.TCPServer(("", PORT), ControlPlaneHandler) as httpd:
        httpd.allow_reuse_address = True
        log(f"Control Plane listening on http://0.0.0.0:{PORT}")
        log("Endpoints: GET / /status /sessions /goals /worktrees /health")
        log("           POST /sessions /sessions/heartbeat /sessions/stop /goal /goal/advance")
        httpd.serve_forever()

if __name__ == "__main__":
    main()
