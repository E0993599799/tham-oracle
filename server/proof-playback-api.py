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
REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"


class ProofAPIHandler(BaseHTTPRequestHandler):
    """HTTP request handler for proof API."""
    
    def do_GET(self):
        """Handle GET requests."""
        parsed_url = urlparse(self.path)
        path = parsed_url.path
        query_params = parse_qs(parsed_url.query)
        
        # CORS headers
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.end_headers()
        
        try:
            if path == '/health':
                response = {
                    "status": "running",
                    "timestamp": datetime.now().isoformat(),
                    "server": "proof-playback-api"
                }
                self.wfile.write(json.dumps(response).encode())
            
            elif path == '/api/proofs':
                # GET /api/proofs?date=YYYY-MM-DD&lane=codex_gpt55&hours=24
                date_str = query_params.get('date', [datetime.now().strftime("%Y-%m-%d")])[0]
                lane_filter = query_params.get('lane', [None])[0]
                hours_filter = int(query_params.get('hours', [24])[0])
                
                proofs = self._get_proofs(date_str, lane_filter, hours_filter)
                self.wfile.write(json.dumps({"proofs": proofs, "count": len(proofs)}).encode())
            
            elif path == '/api/stats':
                # GET /api/stats?date=YYYY-MM-DD
                date_str = query_params.get('date', [datetime.now().strftime("%Y-%m-%d")])[0]
                stats = self._get_stats(date_str)
                self.wfile.write(json.dumps(stats).encode())
            
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(json.dumps({"error": "Not found"}).encode())
        
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())
    
    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
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
