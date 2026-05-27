## Phase 4: Real-time Proof Dashboard Overview

Phase 4 focuses on the observability of the agent fleet through a real-time dashboard. The primary goal is to transform static proof files into a live stream of agent activity, allowing the orchestrator (Tham) and humans to monitor progress, risks, and failures in real-time.

### Key Features
- **Live Streaming**: New proofs are pushed instantly via WebSockets.
- **Historical Playback**: Ability to reload and 'replay' proofs from previous dates.
- **Fleet Statistics**: Real-time aggregation of success rates and execution durations.
- **Proof Watcher**: Automatic directory monitoring for new JSON proof artifacts.
- **REST API**: Standardized endpoints for fetching proofs and statistics.

### System Components
- websocket-server.py: The heart of the real-time stream.
- proof-watcher.py: Monitors the proofs/ directory for new files.
- proof-playback-api.py: Provides REST endpoints for historical data.
- ealtime-dashboard.html: The frontend visualization layer.
- un-realtime-services.sh: Orchestration script to launch the backend stack.
