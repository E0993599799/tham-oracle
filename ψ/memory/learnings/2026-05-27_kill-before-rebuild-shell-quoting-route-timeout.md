---
pattern: Kill Next.js server before rebuilding .next/; quote paths with spaces in shell cmds; use Promise.race to hard-limit API route execution
date: 2026-05-27
source: rrr: tham-oracle
concepts: [nextjs, shell, typescript, production-server, debugging, path-spaces, timeout]
---

# Lessons: Server rebuild, shell quoting, route timeout hardening

## 1. Kill the server before rebuilding compiled output

**Rule**: Always `pkill -9 -f next-server` before `bun run build` / `next build`.

Rebuilding `next build` while `next start` is running rewrites `.next/server/` chunks mid-flight. The server process holds open file descriptors to these files. The result: the new server that reads the rebuilt `.next/` gets partially-overwritten route bundles → server accepts TCP connections but the HTTP handler never fires → curl times out with 0 bytes.

This is a silent corruption. No error log, no crash. The server says "Ready" and everything looks fine.

**Protocol**: kill → build → start. Non-negotiable.

---

## 2. Shell paths with spaces in TypeScript template literals must be double-quoted

When constructing shell command strings in TypeScript:

```typescript
// BAD — REPO_ROOT = "/mnt/d/01 Main Work/..." → shell splits at spaces
cmd: `bash ${REPO_ROOT}/scripts/start.sh`
// → bash /mnt/d/01 Main Work/... (4 args to bash)

// GOOD
const R = `"${REPO_ROOT}"`
cmd: `bash ${R}/scripts/start.sh`
// → bash "/mnt/d/01 Main Work/.../scripts/start.sh"
```

The symptom: "Error: Command failed" with no useful message. The fix: add double quotes around the variable expansion.

---

## 3. Promise.race is the correct hard-limit pattern for Next.js API routes

`AbortController` + `setTimeout` for individual `fetch()` calls is necessary but not sufficient. In Next.js production mode, if the underlying Node.js fetch doesn't honor the abort signal quickly (e.g., socket in TIME_WAIT, half-open connection), the route handler hangs indefinitely — the server never sends the HTTP response.

Hard-limit pattern:

```typescript
async function runWork() { ... }

export async function GET() {
  const timeout = new Promise<null>(r => setTimeout(() => r(null), 7000))
  const result  = await Promise.race([runWork(), timeout])
  if (result === null) return NextResponse.json({ error: 'timeout' })
  return NextResponse.json(result)
}
```

This guarantees the route always responds within 7s regardless of internal hang.

---

## 4. Background curl loops accumulate and flood new server instances

`until curl ... do sleep 2; done` commands started as background tasks continue running after the parent task context is gone. When a new server starts on the same port, these loops immediately create dozens of connections, exhausting the server's request queue or creating enough CLOSE_WAIT connections to saturate handlers.

**Practice**: before starting a fresh server, kill stale loops:
```bash
pkill -f "curl.*:3005" 2>/dev/null
```
