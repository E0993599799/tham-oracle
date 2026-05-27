#!/usr/bin/env python3
"""
Phase 4D: Proof Playback API — REST API for historical proofs

Provides HTTP endpoints for fetching historical proofs.
Runs on http://localhost:8766 (configurable via API_PORT env var)
"""

import json
import os
from pathlib import Path
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import sys

API_PORT = int(os.getenv('API_PORT', 8766))
REPO_ROOT = Path(__file__).parent.parent.absolute()
PROOFS_DIR = REPO_ROOT / "proofs"


class ProofAPIHandler(BaseHTTPRequestHandler):
    """HTTP request handler for proof API."""

    def do_GET(self):
        """Handle GET requests."""
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        query_params = parse_qs(parsed_url.query)

        try:
            if path == '/health':
                self._send_json({
                    "status": "running",
                    "timestamp": datetime.now().isoformat(),
                    "server": "proof-playback-api"
                })

            elif path == '/api/proofs':
                # GET /api/proofs?date=YYYY-MM-DD&lane=codex_gpt55&hours=24
                date_str = query_params.get('date', [datetime.now().strftime("%Y-%m-%d")])[0]
                lane_filter = query_params.get('lane', [None])[0]
                hours_filter = int(query_params.get('hours', [24])[0])

                proofs = self._get_proofs(date_str, lane_filter, hours_filter)
                self._send_json({"proofs": proofs, "count": len(proofs)})

            elif path == '/api/stats':
                # GET /api/stats?date=YYYY-MM-DD
                date_str = query_params.get('date', [datetime.now().strftime("%Y-%m-%d")])[0]
                stats = self._get_stats(date_str)
                self._send_json(stats)

            elif path == '/api/dashboard':
                # GET /api/dashboard?date=YYYY-MM-DD&lane=codex_gpt55
                date_str = query_params.get('date', [datetime.now().strftime("%Y-%m-%d")])[0]
                lane_filter = query_params.get('lane', [None])[0]
                recent_count = int(query_params.get('recent', [20])[0])
                dashboard = self._get_dashboard(date_str=date_str, lane_filter=lane_filter, recent_count=recent_count)
                self._send_json(dashboard)

            else:
                self._send_json({"error": "Not found"}, status=404)

        except Exception as e:
            self._send_json({"error": str(e)}, status=500)

    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def _send_json(self, payload: dict, status: int = 200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.end_headers()
        self.wfile.write(json.dumps(payload).encode())

    def _get_proofs(self, date_str: str, lane_filter: str = None, hours_filter: int = 24) -> list:
        """Load proofs for a date, optionally filtered."""
        date_dir = PROOFS_DIR / date_str
        if not date_dir.exists():
            return []

        proofs = []
        for proof_file in sorted(date_dir.glob("*.json")):
            if proof_file.name.startswith("lane-health"):
                continue

            try:
                with open(proof_file) as f:
                    proof = json.load(f)

                # Filter by lane if specified
                if lane_filter and proof.get("routed_lane") != lane_filter:
                    continue

                proofs.append(proof)
            except (json.JSONDecodeError, IOError):
                pass

        return proofs[-100:] if proofs else []  # Last 100

    def _get_stats(self, date_str: str) -> dict:
        """Get statistics for a date."""
        proofs = self._get_proofs(date_str)

        if not proofs:
            return {
                "date": date_str,
                "total": 0,
                "successful": 0,
                "blocked": 0,
                "error": 0,
                "timeout": 0,
                "by_lane": {},
                "by_risk": {}
            }

        stats = {
            "date": date_str,
            "total": len(proofs),
            "successful": sum(1 for p in proofs if p.get("status") == "SUCCESS"),
            "blocked": sum(1 for p in proofs if p.get("status") == "BLOCKED"),
            "error": sum(1 for p in proofs if p.get("status") == "ERROR"),
            "timeout": sum(1 for p in proofs if p.get("status") == "TIMEOUT"),
            "by_lane": {},
            "by_risk": {}
        }

        # By lane
        for proof in proofs:
            lane = proof.get("routed_lane", "unknown")
            if lane not in stats["by_lane"]:
                stats["by_lane"][lane] = {"count": 0, "successful": 0}
            stats["by_lane"][lane]["count"] += 1
            if proof.get("status") == "SUCCESS":
                stats["by_lane"][lane]["successful"] += 1

        # By risk
        for proof in proofs:
            risk = proof.get("risk_level", "unknown")
            stats["by_risk"][risk] = stats["by_risk"].get(risk, 0) + 1

        return stats

    def _get_dashboard(self, date_str: str, lane_filter: str = None, recent_count: int = 20) -> dict:
        """Build a compact dashboard payload for the live monitor UI."""
        proofs = self._get_proofs(date_str, lane_filter=lane_filter)
        total = len(proofs)
        successful = sum(1 for p in proofs if p.get("status") == "SUCCESS")
        blocked = sum(1 for p in proofs if p.get("status") == "BLOCKED")
        error = sum(1 for p in proofs if p.get("status") == "ERROR")
        timeout = sum(1 for p in proofs if p.get("status") == "TIMEOUT")

        avg_duration = 0.0
        if total:
            avg_duration = sum(float(p.get("execution_duration_seconds", 0) or 0) for p in proofs) / total

        by_lane = {}
        by_risk = {}
        for proof in proofs:
            lane = proof.get("routed_lane", "unknown")
            by_lane.setdefault(lane, {"count": 0, "successful": 0})
            by_lane[lane]["count"] += 1
            if proof.get("status") == "SUCCESS":
                by_lane[lane]["successful"] += 1

            risk = proof.get("risk_level", "unknown")
            by_risk[risk] = by_risk.get(risk, 0) + 1

        lane_status = {}
        for lane, info in by_lane.items():
            count = info["count"]
            success_rate = (info["successful"] / count) if count else 0.0
            if count == 0:
                emoji, status = "⚪", "idle"
            elif success_rate >= 0.8:
                emoji, status = "🟢", "healthy"
            elif success_rate >= 0.5:
                emoji, status = "🟡", "degraded"
            else:
                emoji, status = "🔴", "down"
            lane_status[lane] = {
                "emoji": emoji,
                "status": status,
                "count": count,
                "successful": info["successful"],
                "success_rate": round(success_rate, 3),
            }

        recent = proofs[-recent_count:] if recent_count else proofs[-20:]
        return {
            "generated_at": datetime.now().isoformat(),
            "date": date_str,
            "lane_filter": lane_filter,
            "total_proofs": total,
            "successful": successful,
            "blocked": blocked,
            "error": error,
            "timeout": timeout,
            "success_rate": (successful / total) if total else 0.0,
            "avg_duration": round(avg_duration, 2),
            "by_lane": by_lane,
            "by_risk": by_risk,
            "lane_status": lane_status,
            "recent_proofs": recent,
            "anomalies": [],
        }

    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


def main():
    """Start API server."""
    server = HTTPServer(('localhost', API_PORT), ProofAPIHandler)
    print(f"🚀 Proof Playback API Starting")
    print(f"   URL: http://localhost:{API_PORT}")
    print(f"   Endpoints:")
    print(f"     GET /api/proofs?date=YYYY-MM-DD")
    print(f"     GET /api/proofs?date=YYYY-MM-DD&lane=codex_gpt55")
    print(f"     GET /api/stats?date=YYYY-MM-DD")
    print(f"     GET /api/dashboard?date=YYYY-MM-DD")
    print(f"     GET /health")
    print(f"   Serving proofs from: {PROOFS_DIR}")
    print("")
    print(f"✅ API server running on http://localhost:{API_PORT}")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n✓ API server stopped")


if __name__ == "__main__":
    main()
