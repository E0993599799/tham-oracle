# Phase 4 API Reference

## 1. Proof Playback API (REST)

**Base URL**: http://localhost:8766

### Endpoints

#### GET /api/proofs
- **Description**: Retrieves a list of proofs for a specific date.
- **Parameters**:
  - date (Required): Format YYYY-MM-DD.
  - lane (Optional): Filter proofs by routed lane (e.g., codex_gpt55).
- **Response**: JSON array of proof objects.

#### GET /api/stats
- **Description**: Retrieves aggregated statistics for a specific date.
- **Parameters**:
  - date (Required): Format YYYY-MM-DD.
- **Response**: JSON object containing total, success, blocked, error, timeout counts and lane/risk breakdowns.

#### GET /health
- **Description**: API health check.
- **Response**: {'status': 'ok'}

## 2. WebSocket Stream

**URL**: ws://localhost:8765

### Message Types

#### Outgoing (Server to Client)
- type: 'proof': A new proof has been generated. Data contains the full proof JSON.
- type: 'recent': Initial burst of the last 20 proofs upon connection.
- type: 'historical': Response to a historical query.

#### Incoming (Client to Server)
- type: 'query': Request for historical proofs.
- **Payload**: { "type": "query", "lane": "codex", "hours": 24 }
