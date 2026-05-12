# oracle-v2 — ความทรงจำถาวรของธาม

oracle-v2 (arra-oracle) คือ MCP Server ที่ให้ Claude Code มี hybrid memory engine

## ติดตั้งแล้ว

```
~/.claude.json → project /root/repos/tham-oracle
mcpServers.oracle-v2 → bunx --bun arra-oracle@github:Soul-Brews-Studio/arra-oracle#main
```

## 22 MCP Tools

### Search & Learn
| Tool | ทำอะไร |
|------|--------|
| `oracle_search` | ค้นหา knowledge (hybrid: FTS5 + vector) |
| `oracle_learn` | เพิ่ม pattern/learning ใหม่ |
| `oracle_reflect` | Semantic reflection — ค้นลึก |
| `oracle_list` | ดู documents ทั้งหมด |
| `oracle_read` | อ่าน document ตาม ID |
| `oracle_concepts` | ดู concept tags |
| `oracle_stats` | สถิติ knowledge base |

### Communication
| Tool | ทำอะไร |
|------|--------|
| `oracle_thread` | สร้าง/ตอบ thread |
| `oracle_threads` | ดู threads ทั้งหมด |
| `oracle_thread_read` | อ่าน thread |
| `oracle_thread_update` | update thread |

### Session Management
| Tool | ทำอะไร |
|------|--------|
| `oracle_handoff` | สร้าง session handoff |
| `oracle_inbox` | ดู inbox |
| `oracle_supersede` | supersede document เก่า (ไม่ลบ!) |
| `oracle_verify` | verify document |

### Discovery
| Tool | ทำอะไร |
|------|--------|
| `oracle_trace` | เริ่ม trace session |
| `oracle_trace_list` | ดู traces |
| `oracle_trace_get` | อ่าน trace |
| `oracle_trace_link` | link trace กับ dig point |
| `oracle_trace_chain` | ดู chain ของ trace |

### Time
| Tool | ทำอะไร |
|------|--------|
| `oracle_schedule_add` | เพิ่มนัดหมาย |
| `oracle_schedule_list` | ดูตาราง |

## "Nothing is Deleted"

oracle-v2 ไม่ลบอะไร:
- document เก่า → `oracle_supersede` → mark superseded
- document ใหม่ point ไปที่เก่า → audit trail สมบูรณ์
- ทุก version ยังค้นหาได้

## วิธีใช้งาน

```
# ค้นหา
> ค้นหาใน oracle: "forge omega"

# บันทึก learning ใหม่
> จำไว้ว่า: Supabase เป็น preferred persistence สำหรับ Forge/Omega

# ค้นหาสิ่งที่เรียนรู้
> ค้นหาใน oracle: "persistence"
```

## HTTP Server (สำหรับ Oracle Studio)

```bash
# default port 47778
bash scripts/start-oracle-v2-http.sh
```
