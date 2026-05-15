# Multi-Oracle Setup

ตั้งค่า Oracle หลายตัวในเครื่องเดียว ไม่ให้ port ชน

## Architecture

```
~/.oracle/
├── oracle.db           ← Tham (default) DB
├── oracle-dev.db       ← Dev Oracle DB
├── oracle-qa.db        ← QA Oracle DB
├── vault/              ← Shared knowledge vault
├── feed.log
└── pid/
```

## Port Map

| Oracle | Port | DB |
|--------|------|----|
| Tham (default) | 47778 | oracle.db |
| Dev | 47779 | oracle-dev.db |
| QA | 47780 | oracle-qa.db |
| Oracle Studio #1 | 3000 | → Tham |
| Oracle Studio #2 | 3001 | → Dev |

## เปิด Multi-Oracle (tmux fleet)

```bash
bash scripts/oracle-fleet.sh
tmux attach -t oracle-fleet
```

## MCP Config per Oracle Repo

**Tham Oracle (.mcp.json)**:
```json
{
  "mcpServers": {
    "oracle-v2": {
      "command": "bunx",
      "args": ["--bun", "arra-oracle@github:Soul-Brews-Studio/arra-oracle#main"],
      "env": { "ORACLE_PORT": "47778" }
    }
  }
}
```

**Dev Oracle (.mcp.json)**:
```json
{
  "mcpServers": {
    "oracle-v2": {
      "command": "bunx",
      "args": ["--bun", "arra-oracle@github:Soul-Brews-Studio/arra-oracle#main"],
      "env": { "ORACLE_PORT": "47779", "ORACLE_DB": "~/.oracle/oracle-dev.db" }
    }
  }
}
```

## สถานะตอนนี้

| Oracle | สถานะ |
|--------|--------|
| ธาม (port 47778) | ✅ active |
| Dev (port 47779) | 🔲 template/inactive |
| QA (port 47780) | 🔲 template/inactive |
