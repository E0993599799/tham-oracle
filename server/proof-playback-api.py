#!/usr/bin/env python3
"""
Proof Playback API Server

Serves historical proof data and statistics via REST API
Listens on http://localhost:8766 (configurable via API_PORT env var)

Endpoints:
  GET /api/proofs?date=YYYY-MM-DD[&lane=LANE_NAME]
  GET /api/stats?date=YYYY-MM-DD
  GET /health
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
from pathlib import Path
from datetime import datetime, timedelta
import os
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ProofAPIHandler(BaseHTTPRequestHandler):
    """HTTP request handler for proof API"""

    def do_GET(self):
        """Handle GET requests"""
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        try:
            if parsed.path == '/api/proofs':
                self._handle_proofs(params)
            elif parsed.path == '/api/stats':
                self._handle_stats(params)
            elif parsed.path == '/health':
                self._send_json({'status': 'running'})
            else:
                self._send_error(404, 'Not found')
        except Exception as e:
            logger.error(f'Error handling request {parsed.path}: {e}')
            self._send_error(500, str(e))

    def _handle_proofs(self, params):
        """Handle GET /api/proofs"""
        date_str = params.get('date', [None])[0]
        lane_filter = params.get('lane', [None])[0]
        hours = params.get('hours', [None])[0]

        try:
            proofs = self._load_proofs(date_str, lane_filter, hours)
            self._send_json(proofs)
        except FileNotFoundError:
            self._send_json([])
        except ValueError as e:
            self._send_error(400, str(e))

    def _handle_stats(self, params):
        """Handle GET /api/stats"""
        date_str = params.get('date', [None])[0]

        try:
            stats = self._compute_stats(date_str)
            self._send_json(stats)
        except FileNotFoundError:
            self._send_json({
                'date': date_str,
                'task_count': 0,
                'success_count': 0,
                'success_rate_pct': 0,
                'error_count': 0,
                'pending_count': 0,
                'average_duration_seconds': 0,
                'risk_distribution': {
                    'low': 0,
                    'medium': 0,
                    'high': 0
                },
                'lane_distribution': {}
            })
        except ValueError as e:
            self._send_error(400, str(e))

    def _load_proofs(self, date_str=None, lane_filter=None, hours=None):
        """Load proofs from disk"""
        repo_root = Path(__file__).parent.parent
        proofs = []

        # Determine date(s) to load
        if hours:
            try:
                hours_int = int(hours)
                end_date = datetime.now()
                start_date = end_date - timedelta(hours=hours_int)
                dates = [start_date + timedelta(days=i) for i in range(hours_int // 24 + 1)]
                dates = [d.strftime('%Y-%m-%d') for d in dates]
            except ValueError:
                raise ValueError('Invalid hours parameter')
        elif date_str:
            # Validate date format
            try:
                datetime.strptime(date_str, '%Y-%m-%d')
                dates = [date_str]
            except ValueError:
                raise ValueError('Invalid date format. Use YYYY-MM-DD')
        else:
            # Default to today
            dates = [datetime.now().strftime('%Y-%m-%d')]

        # Load proofs from each date directory
        for date in dates:
            proof_dir = repo_root / 'proofs' / date
            if not proof_dir.exists():
                continue

            for json_file in sorted(proof_dir.glob('*.json'), reverse=True):
                # Skip health check proofs
                if json_file.name.startswith('lane-health'):
                    continue

                try:
                    with open(json_file, 'r', encoding='utf-8') as f:
                        proof = json.load(f)

                        # Only include task proofs (have task_id)
                        if 'task_id' not in proof:
                            continue

                        # Apply lane filter if specified
                        if lane_filter and proof.get('routed_lane') != lane_filter:
                            continue

                        # Ensure required fields
                        proof.setdefault('routed_lane', 'unknown')
                        proof.setdefault('status', 'UNKNOWN')
                        proof.setdefault('risk_level', 'low')
                        proof.setdefault('duration', 0)

                        proofs.append(proof)

                except (json.JSONDecodeError, IOError) as e:
                    logger.error(f'Error reading proof {json_file.name}: {e}')

        return proofs

    def _compute_stats(self, date_str=None):
        """Compute statistics for a date"""
        if not date_str:
            date_str = datetime.now().strftime('%Y-%m-%d')

        # Validate date format
        try:
            datetime.strptime(date_str, '%Y-%m-%d')
        except ValueError:
            raise ValueError('Invalid date format. Use YYYY-MM-DD')

        proofs = self._load_proofs(date_str)

        if not proofs:
            return {
                'date': date_str,
                'task_count': 0,
                'success_count': 0,
                'success_rate_pct': 0,
                'error_count': 0,
                'pending_count': 0,
                'average_duration_seconds': 0,
                'risk_distribution': {
                    'low': 0,
                    'medium': 0,
                    'high': 0
                },
                'lane_distribution': {}
            }

        # Compute statistics
        success_count = sum(1 for p in proofs if p.get('status') == 'SUCCESS')
        error_count = sum(1 for p in proofs if p.get('status') == 'ERROR')
        pending_count = sum(1 for p in proofs if p.get('status') == 'PENDING')

        total_duration = sum(p.get('duration', 0) for p in proofs if p.get('duration', 0) > 0)
        completed_count = sum(1 for p in proofs if p.get('duration', 0) > 0)
        avg_duration = total_duration / completed_count if completed_count > 0 else 0

        # Risk distribution
        risk_dist = {
            'low': sum(1 for p in proofs if p.get('risk_level') == 'low'),
            'medium': sum(1 for p in proofs if p.get('risk_level') == 'medium'),
            'high': sum(1 for p in proofs if p.get('risk_level') == 'high')
        }

        # Lane distribution
        lane_dist = {}
        for proof in proofs:
            lane = proof.get('routed_lane', 'unknown')
            lane_dist[lane] = lane_dist.get(lane, 0) + 1

        return {
            'date': date_str,
            'task_count': len(proofs),
            'success_count': success_count,
            'success_rate_pct': round((success_count / len(proofs) * 100) if proofs else 0, 2),
            'error_count': error_count,
            'pending_count': pending_count,
            'average_duration_seconds': round(avg_duration, 2),
            'risk_distribution': risk_dist,
            'lane_distribution': lane_dist
        }

    def _send_json(self, data):
        """Send JSON response"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode('utf-8'))

    def _send_error(self, status_code, message):
        """Send error response"""
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps({
            'error': message,
            'status_code': status_code
        }).encode('utf-8'))

    def log_message(self, format, *args):
        """Log HTTP requests"""
        logger.info("%s - %s" % (self.client_address[0], format % args))


def main():
    """Main entry point"""
    port = int(os.getenv('API_PORT', 8766))
    server_address = ('localhost', port)
    httpd = HTTPServer(server_address, ProofAPIHandler)

    logger.info(f'Starting Proof API server on http://localhost:{port}')
    logger.info(f'Endpoints:')
    logger.info(f'  GET /api/proofs?date=YYYY-MM-DD')
    logger.info(f'  GET /api/proofs?date=YYYY-MM-DD&lane=LANE_NAME')
    logger.info(f'  GET /api/stats?date=YYYY-MM-DD')
    logger.info(f'  GET /health')

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info('Shutting down...')
        httpd.shutdown()


if __name__ == '__main__':
    main()
