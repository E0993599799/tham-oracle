# Phase 4 Deployment Guide

## Prerequisites
- Python 3.10+
- websockets library (optional for WebSocket support, dashboard will fallback to API polling)
\n## Quick Start
\n1. **Launch Services**:
   Run the orchestration script:
   \ash server/run-realtime-services.sh\`n\n2. **Access Dashboard**:
   Open dashboard/realtime-dashboard.html in any modern web browser.
\n## Component Details
- **API Server**: Runs on port 8766.
- **WebSocket Server**: Runs on port 8765.
- **Logs**: All service logs are captured in the logs/ directory.
\n## Troubleshooting
- **WebSocket Connection Failed**: Ensure pip install websockets is executed. The dashboard will automatically switch to API polling every 5 seconds if the WebSocket is unavailable.
- **No Proofs Visible**: Check that the proofs/ directory contains JSON files for the selected date.
- **CORS Issues**: The proof-playback-api.py includes a basic CORS header to allow requests from ile:// URIs.
