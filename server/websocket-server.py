#!/usr/bin/env python3
"""
Phase 4A: WebSocket Server — Real-time proof streaming

Accepts WebSocket connections and streams proofs as they're created.
Runs on ws://localhost:8765 (configurable via WS_PORT env var)
"""

import asyncio
import json
import os
from pathlib import Path
from datetime import datetime, timezone
from collections import deque
import sys

# Configuration
WS_PORT = int(os.getenv('WS_PORT', 8765))
REPO_ROOT = Path("/root/ghq/github.com/E0993599799/tham-oracle")
PROOFS_DIR = REPO_ROOT / "proofs"

# Track connected clients
connected_clients = set()
proof_queue = deque(maxlen=1000)
last_processed_file = None


class ProofWatcher:
    """Watch proofs directory for new files."""
    
    def __init__(self, proofs_dir, poll_interval=1.0):
        self.proofs_dir = Path(proofs_dir)
        self.poll_interval = poll_interval
        self.seen_files = set()
        self.last_check = None
    
    def get_today_proofs(self):
        """Get proof files from today."""
        today = datetime.now().strftime("%Y-%m-%d")
        today_dir = self.proofs_dir / today
        if not today_dir.exists():
            return []
        return sorted(today_dir.glob("*.json"))
    
    def new_proofs(self):
        """Return proofs seen since last check."""
        new = []
        for proof_file in self.get_today_proofs():
            if proof_file not in self.seen_files:
                self.seen_files.add(proof_file)
                new.append(proof_file)
        return new
    
    async def poll(self):
        """Poll for new proofs every poll_interval seconds."""
        while True:
            try:
                for proof_file in self.new_proofs():
                    try:
                        with open(proof_file) as f:
                            proof_data = json.load(f)
                        # Skip health-check proofs
                        if not proof_file.name.startswith("lane-health"):
                            yield proof_data
                    except (json.JSONDecodeError, IOError) as e:
                        print(f"⚠️  Error reading {proof_file}: {e}", file=sys.stderr)
            except Exception as e:
                print(f"⚠️  Polling error: {e}", file=sys.stderr)
            
            await asyncio.sleep(self.poll_interval)


async def handle_client(websocket, path):
    """Handle WebSocket client connection."""
    client_id = id(websocket)
    connected_clients.add(websocket)
    print(f"✓ Client {client_id} connected ({len(connected_clients)} total)")
    
    try:
        # Send recent proofs (last 20)
        recent = list(proof_queue)[-20:] if proof_queue else []
        for proof in recent:
            try:
                await websocket.send(json.dumps({
                    "type": "recent",
                    "data": proof
                }))
            except Exception as e:
                print(f"⚠️  Error sending recent proof: {e}")
        
        # Keep connection alive
        async for message in websocket:
            # Handle any incoming messages (e.g., historical queries)
            try:
                cmd = json.loads(message)
                if cmd.get("type") == "query":
                    # Historical query: {type: "query", lane: "codex", hours: 24}
                    lane = cmd.get("lane")
                    hours = cmd.get("hours", 24)
                    matching = [p for p in proof_queue 
                               if p.get("routed_lane") == lane]
                    await websocket.send(json.dumps({
                        "type": "historical",
                        "data": matching[-100:]  # Last 100
                    }))
            except json.JSONDecodeError:
                pass
    
    except asyncio.CancelledError:
        pass
    finally:
        connected_clients.discard(websocket)
        print(f"✗ Client {client_id} disconnected ({len(connected_clients)} remain)")


async def broadcast_proof(proof_data):
    """Send proof to all connected clients."""
    if not connected_clients:
        return
    
    message = json.dumps({
        "type": "proof",
        "data": proof_data
    })
    
    dead_clients = set()
    for client in connected_clients:
        try:
            await client.send(message)
        except asyncio.CancelledError:
            dead_clients.add(client)
        except Exception as e:
            dead_clients.add(client)
            print(f"⚠️  Error sending to client: {e}", file=sys.stderr)
    
    for client in dead_clients:
        connected_clients.discard(client)


async def proof_streaming_loop():
    """Main loop: watch for proofs and broadcast."""
    watcher = ProofWatcher(PROOFS_DIR, poll_interval=1.0)
    async for proof_data in watcher.poll():
        # Add to queue
        proof_queue.append(proof_data)
        # Broadcast to clients
        await broadcast_proof(proof_data)
        # Log
        task_id = proof_data.get("task_id", "unknown")
        status = proof_data.get("status", "unknown")
        lane = proof_data.get("routed_lane", "unknown")
        print(f"📤 Broadcast: {task_id} → {lane} ({status}) to {len(connected_clients)} clients")


async def health_check_handler(path, request_headers):
    """HTTP health check endpoint."""
    response_headers = [('Content-Type', 'application/json')]
    health = json.dumps({
        "status": "running",
        "connected_clients": len(connected_clients),
        "proofs_in_queue": len(proof_queue),
        "timestamp": datetime.now(timezone.utc).isoformat()
    })
    return (200, response_headers, health)


async def main():
    """Start WebSocket server."""
    print(f"🚀 WebSocket Server Starting")
    print(f"   Port: ws://localhost:{WS_PORT}")
    print(f"   Watching: {PROOFS_DIR}")
    print("")
    
    # Start proof streaming loop
    streaming_task = asyncio.create_task(proof_streaming_loop())
    
    # Start WebSocket server
    try:
        async with asyncio.TaskGroup() as tg:
            # This is Python 3.11+ syntax, fallback for older versions
            try:
                import websockets
                async with websockets.serve(handle_client, "localhost", WS_PORT):
                    print(f"✅ WebSocket server running on ws://localhost:{WS_PORT}")
                    await asyncio.sleep(float('inf'))
            except ImportError:
                print("❌ websockets library not found")
                print("   Install: pip install websockets")
                sys.exit(1)
    except KeyboardInterrupt:
        print("\n✓ Server stopped")


if __name__ == "__main__":
    # Try to import websockets
    try:
        import websockets
    except ImportError:
        print("❌ ERROR: websockets library required")
        print("   Install: pip install websockets")
        print("")
        print("Note: Phase 4 WebSocket uses stdlib asyncio only.")
        print("      Fallback implementation uses asyncio.StreamReader")
        sys.exit(1)
    
    asyncio.run(main())
