#!/usr/bin/env python3
"""
WebSocket Server for Real-time Proof Streaming

Listens on ws://localhost:8765 (configurable via WS_PORT env var)
Streams proof events as they appear in proofs/YYYY-MM-DD/
Broadcasts to all connected clients in real-time
"""

import asyncio
import websockets
import json
from pathlib import Path
from datetime import datetime
from collections import deque
import signal
import os


class ProofServer:
    def __init__(self, port=None):
        self.port = port or int(os.getenv("WS_PORT", 8765))
        self.clients = set()
        self.proof_queue = deque(maxlen=1000)  # Keep last 1000 proofs
        self.running = True
        self.repo_root = Path(__file__).parent.parent
        self.last_checked = {}

    async def handle_client(self, websocket):
        """Accept client connection, stream proofs"""
        self.clients.add(websocket)
        client_addr = websocket.remote_address if websocket.remote_address else ("unknown", "unknown")
        print(f"✓ Client connected: {client_addr[0]}:{client_addr[1]}")

        try:
            # Send recent proofs on connect
            if self.proof_queue:
                for proof in self.proof_queue:
                    await websocket.send(json.dumps(proof))
                print(f"  Sent {len(self.proof_queue)} recent proofs to {client_addr[0]}:{client_addr[1]}")

            # Keep connection alive
            await websocket.wait_closed()
        except websockets.exceptions.ConnectionClosed:
            pass
        except Exception as e:
            print(f"✗ Error handling client {client_addr}: {e}")
        finally:
            self.clients.discard(websocket)
            print(f"✗ Client disconnected: {client_addr[0]}:{client_addr[1]}")

    async def proof_poller(self):
        """Watch proofs/ directory, emit new proofs every 1 second"""
        while self.running:
            try:
                # Construct today's proof directory
                today_str = datetime.now().strftime("%Y-%m-%d")
                proof_dir = self.repo_root / "proofs" / today_str

                if proof_dir.exists():
                    for json_file in proof_dir.glob("*.json"):
                        # Skip health-check proofs
                        if json_file.name.startswith("lane-health"):
                            continue

                        stat = json_file.stat()
                        file_key = str(json_file)

                        # Check if file is new or modified
                        if file_key not in self.last_checked or stat.st_mtime > self.last_checked[file_key]:
                            try:
                                with open(json_file, 'r', encoding='utf-8') as f:
                                    proof = json.load(f)

                                    # Only emit task proofs (have task_id)
                                    if "task_id" in proof:
                                        # Format proof message for streaming
                                        message = {
                                            "type": "proof",
                                            "task_id": proof.get("task_id"),
                                            "routed_lane": proof.get("routed_lane"),
                                            "status": proof.get("status", "UNKNOWN"),
                                            "timestamp": proof.get("execution_timestamp", datetime.now().isoformat()),
                                            "duration": proof.get("execution_duration_seconds", 0),
                                            "source_file": json_file.name
                                        }

                                        self.proof_queue.append(message)
                                        await self.broadcast_proof(message)
                                        self.last_checked[file_key] = stat.st_mtime

                            except (json.JSONDecodeError, IOError) as e:
                                print(f"✗ Error reading proof {json_file.name}: {e}")

            except Exception as e:
                print(f"✗ Poller error: {e}")

            await asyncio.sleep(1)

    async def broadcast_proof(self, proof):
        """Send proof to all connected clients"""
        if not self.clients:
            return

        # Broadcast to all clients
        if self.clients:
            message = json.dumps(proof)
            results = await asyncio.gather(
                *[client.send(message) for client in self.clients],
                return_exceptions=True
            )

            # Count successes
            successes = sum(1 for r in results if r is None)
            if successes > 0:
                print(f"  Broadcasted proof {proof['task_id']} to {successes} client(s)")

    def shutdown(self, sig, frame):
        """Handle graceful shutdown"""
        print("\n⊗ Shutdown signal received")
        self.running = False

    async def run(self):
        """Start WebSocket server"""
        print(f"Starting WebSocket server on ws://localhost:{self.port}")

        # Register shutdown handlers
        signal.signal(signal.SIGTERM, self.shutdown)
        signal.signal(signal.SIGINT, self.shutdown)

        # Create proof poller task
        poller_task = asyncio.create_task(self.proof_poller())

        try:
            # Start WebSocket server
            async with websockets.serve(
                self.handle_client,
                "localhost",
                self.port,
                ping_interval=20,
                ping_timeout=10
            ):
                print(f"✅ WebSocket server running on port {self.port}")
                print(f"   Connect with: wscat -c ws://localhost:{self.port}")

                # Wait until shutdown
                while self.running:
                    await asyncio.sleep(0.1)

        except Exception as e:
            print(f"✗ Server error: {e}")
        finally:
            poller_task.cancel()
            print("⊗ WebSocket server shut down")


async def main():
    """Main entry point"""
    server = ProofServer()
    await server.run()


if __name__ == "__main__":
    asyncio.run(main())
