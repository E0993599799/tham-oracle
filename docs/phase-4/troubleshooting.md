# Phase 4 Troubleshooting

## Common Issues

| Issue | Cause | Resolution |
|---|---|---|
| Dashboard shows 'Disconnected' | WebSocket server not running or websockets package missing | Run ash server/run-realtime-services.sh and check logs/websocket-server.log |
| Proofs not updating | proof-watcher.py polling interval or filesystem permissions | Verify the proofs/ directory is writable and contains valid JSON files |
| API 404/500 | Incorrect date parameter or malformed JSON proof files | Ensure the date parameter is YYYY-MM-DD and verify JSON integrity |
| Slow Performance | Too many proofs in a single day directory | Use the lane filter in API requests to reduce payload size |

## Log Analysis
- **API Logs**: logs/api-server.log - Check for HTTP 500 errors or JSON parsing failures.
- **WebSocket Logs**: logs/websocket-server.log - Check for connection drops or broadcasting errors.
