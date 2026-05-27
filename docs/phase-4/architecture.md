# Phase 4 Architecture

## System Flow

1. **Proof Generation**: Worker agents (Codex/Gemini) write .json proof files to proofs/YYYY-MM-DD/.
\n2. **Detection**: proof-watcher.py (inside websocket-server.py) polls this directory every 1 second.
\n3. **Streaming**: websocket-server.py broadcasts new proof JSONs to all connected WebSocket clients.
\n4. **Visualization**: ealtime-dashboard.html receives the stream and updates the UI instantly.
\n5. **Historical Access**: proof-playback-api.py reads the same proofs/ directory to serve REST requests for historical data.
\n## Component Interaction
- **Frontend** $\leftrightarrow$ **WebSocket Server** (Real-time Updates)
- **Frontend** $\leftrightarrow$ **Playback API** (Historical Data/Stats)
- **WebSocket Server** $\leftrightarrow$ **Filesystem** (Proof Polling)
- **Playback API** $\leftrightarrow$ **Filesystem** (JSON Parsing)
\n## Data Model
- Proofs are stored as independent JSON files to ensure durability and auditability.
- The dashboard uses an in-memory queue for the most recent 1000 proofs.
