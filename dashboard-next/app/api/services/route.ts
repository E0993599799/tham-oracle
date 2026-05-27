import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export const dynamic = 'force-dynamic'

// ── Normalized model (SOT) ────────────────────────────────────────────────────
export interface ServiceHealth {
  name: string
  label: string
  port: number | null
  category: 'api' | 'ui' | 'runtime' | 'router' | 'tool' | 'process'
  status: 'online' | 'offline' | 'degraded' | 'unknown'
  latencyMs: number | null
  checkedAt: string
  detail: string
  source: 'http-probe' | 'exec-probe' | 'registry-only'
  fix: string
}

// ── Canonical Service Registry ────────────────────────────────────────────────
// SOT: KPI and table both derive from this list. Add/remove services here only.
const REGISTRY: Omit<ServiceHealth, 'status' | 'latencyMs' | 'checkedAt' | 'detail' | 'source'>[] = [
  // HTTP / API
  { name: 'oracle-v2',         label: 'Oracle v2 API',       port: 47778, category: 'api',     fix: 'oracle-v2'        },
  { name: 'oracle-v2-swagger', label: 'Oracle v2 Swagger',   port: 47778, category: 'api',     fix: 'oracle-v2'        },
  { name: 'oracle-v2-omega',   label: 'Oracle v2 Omega',     port: 47779, category: 'api',     fix: 'oracle-v2'        },
  { name: 'forge-supervisor',  label: 'Forge Supervisor',    port: 8769,  category: 'runtime', fix: 'forge-supervisor' },
  { name: 'dashboard',         label: 'Tham Dashboard',      port: 3005,  category: 'ui',      fix: 'dashboard'        },
  { name: '9router',           label: '9router / OpenClaw',  port: 20128, category: 'router',  fix: ''                 },
  // Tools (exec-probed)
  { name: 'bun',               label: 'Bun Runtime',         port: null,  category: 'tool',    fix: ''                 },
  { name: 'node',              label: 'Node.js',             port: null,  category: 'tool',    fix: ''                 },
  { name: 'git',               label: 'Git',                 port: null,  category: 'tool',    fix: ''                 },
  { name: 'gh',                label: 'GitHub CLI',          port: null,  category: 'tool',    fix: ''                 },
  { name: 'maw',               label: 'MAW',                 port: null,  category: 'tool',    fix: 'maw-install'      },
  { name: 'tmux',              label: 'tmux',                port: null,  category: 'process', fix: 'tmux'             },
]

// ── URL map for HTTP-probed services ─────────────────────────────────────────
const HTTP_URLS: Record<string, string> = {
  'oracle-v2':         'http://localhost:47778/',
  'oracle-v2-swagger': 'http://localhost:47778/swagger',
  'oracle-v2-omega':   'http://localhost:47779/',
  'forge-supervisor':  'http://localhost:8769/',
  'dashboard':         'http://localhost:3005/api/git',
  '9router':           'http://localhost:20128/',
}

// ── Exec commands for tool-probed services ────────────────────────────────────
const EXEC_CMDS: Record<string, string> = {
  bun:  'bun --version',
  node: 'node --version',
  git:  'git --version',
  gh:   'gh --version',
  maw:  'maw --version 2>/dev/null || echo ""',
  tmux: 'tmux -V',
}

// ── Probes ────────────────────────────────────────────────────────────────────
async function probeHttp(url: string): Promise<{ ok: boolean; latencyMs: number; detail: string }> {
  const t0 = Date.now()
  try {
    const ctrl = new AbortController()
    const timer = setTimeout(() => ctrl.abort(), 2500)
    const res = await fetch(url, { signal: ctrl.signal, cache: 'no-store' })
    clearTimeout(timer)
    return {
      ok: res.ok || res.status < 500,
      latencyMs: Date.now() - t0,
      detail: `HTTP ${res.status}`,
    }
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    return {
      ok: false,
      latencyMs: Date.now() - t0,
      detail: msg.includes('abort') ? 'timeout' : msg.slice(0, 80),
    }
  }
}

function probeExec(cmd: string): { ok: boolean; detail: string } {
  try {
    const out = execSync(cmd, {
      encoding: 'utf8', timeout: 2000,
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim()
    return { ok: !!out, detail: out.split('\n')[0].slice(0, 60) }
  } catch {
    return { ok: false, detail: 'not found' }
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────
export async function GET() {
  const now = new Date().toISOString()

  // Probe all HTTP services concurrently
  const httpNames = REGISTRY.map(r => r.name).filter(n => HTTP_URLS[n])
  const httpResults: Record<string, { ok: boolean; latencyMs: number; detail: string }> =
    Object.fromEntries(
      await Promise.all(
        httpNames.map(name => probeHttp(HTTP_URLS[name]).then(r => [name, r]))
      )
    )

  // Build normalized service list from registry (preserves order, all 12 rows)
  const services: ServiceHealth[] = REGISTRY.map(r => {
    if (HTTP_URLS[r.name]) {
      const p = httpResults[r.name]
      return {
        ...r,
        status: p.ok ? 'online' : 'offline',
        latencyMs: p.latencyMs,
        checkedAt: now,
        detail: p.detail,
        source: 'http-probe',
      } satisfies ServiceHealth
    }
    if (EXEC_CMDS[r.name]) {
      const p = probeExec(EXEC_CMDS[r.name])
      return {
        ...r,
        status: (p.ok ? 'online' : 'offline') as ServiceHealth['status'],
        latencyMs: null,
        checkedAt: now,
        detail: p.detail,
        source: 'exec-probe',
      } satisfies ServiceHealth
    }
    return {
      ...r,
      status: 'unknown',
      latencyMs: null,
      checkedAt: now,
      detail: '—',
      source: 'registry-only',
    } satisfies ServiceHealth
  })

  const online    = services.filter(s => s.status === 'online').length
  const offline   = services.filter(s => s.status === 'offline').length
  const unknown   = services.filter(s => s.status === 'unknown').length
  const attention = services.filter(s => s.status !== 'online').length  // offline + degraded + unknown

  return NextResponse.json({
    services,
    checked_at: now,
    summary: { total: services.length, online, offline, unknown, attention },
  })
}
