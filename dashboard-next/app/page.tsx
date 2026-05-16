'use client'

import { useEffect, useState, useCallback } from 'react'

// ── Types ──────────────────────────────────────────────────────────────────
interface Oracle {
  name: string
  path: string
  branch: string
  lastCommit: string
  days: number
  status: string
  hasAwaken: boolean
}
interface FleetData {
  oracles: Oracle[]
  summary: { total: number; active: number; stale: number; cold: number; abandoned: number; zygote: number }
  error?: string
}
interface Commit { hash: string; subject: string; author: string; ago: string }
interface GitData { commits: Commit[]; branch: string; dirtyFiles: number; error?: string }
interface MemFile { key: string; path: string; exists: boolean; hash: string; lastModified: string; sizeKB: number; snippet: string }
interface MemData { files: MemFile[]; constitutionRules: string[]; error?: string }
interface MetricRow { when: string; session: string; done: string; stuck: string; win: string; friction: string; error: string }
interface MetricsData { rows: MetricRow[]; retrosToday: number; learningsThisMonth: number; error?: string }
interface FileEntry { name: string; mtime: string; sizeKB: number }
interface InboxSection { count: number; files?: FileEntry[] | string[]; recent?: FileEntry[] | string[] }
interface InboxData {
  inbox: InboxSection
  outbox: InboxSection
  proofs: InboxSection
  active: InboxSection
}
interface ServiceResult {
  name: string
  label: string
  port: number | null
  category: string
  status: 'online' | 'offline' | 'degraded' | 'unknown'
  latencyMs: number | null
  checkedAt: string
  detail: string
  source: string
  fix: string
}
interface ServicesData {
  services: ServiceResult[]
  checked_at: string
  summary: { total: number; online: number; offline: number; unknown: number; attention: number }
}
interface ConstitutionRule {
  id: string
  title: string
  description: string
  index: number
}
interface ConstitutionData {
  rules: ConstitutionRule[]
  total: number
  error?: string
}

// === Health / Status Monitor types ===
interface HttpService { name: string; label: string; url: string; ok: boolean; latency: number; code: number; detail: string; fix: string; checked_at: string }
interface TmuxSession { name: string; detail: string; ok: boolean; fix: string }
interface RuntimeTool { name: string; detail: string; ok: boolean; fix: string }
interface WatchdogItem { name: string; pid?: string; ok: boolean; fix: string }
interface HealthData {
  checked_at: string
  summary: { total: number; healthy: number; unhealthy: number; git_dirty: number }
  http: HttpService[]
  tmux: TmuxSession[]
  fleet: { name: string; ok: boolean }[]
  watchdog: WatchdogItem[]
  runtimes: RuntimeTool[]
}

// === Task Board types ===
interface Task { id: string; name: string; column: string; mtime: string; sizeKB: number; type: string }
interface TasksData {
  columns: { inbox: Task[]; active: Task[]; outbox: Task[]; proofs: Task[]; archive: Task[] }
  total: number
}

// === Provider types ===
interface Provider {
  id: string; providerName: string; type: string; model: string; baseUrl: string
  priority: number; enabled: boolean
  status: 'available' | 'degraded' | 'unavailable' | 'unknown'
  statusCode: number | null; latencyMs: number | null; lastCheckedAt: string
  availableModels?: string[]
}
interface ProviderQuota {
  providerId: string; providerName: string; accountLabel: string; modelOrLimitName: string
  windowType: string; used: number | null; limit: number | null; remaining: number | null
  percentUsed: number | null; percentRemaining: number | null
  resetAt: string | null; resetInText: string
  status: 'available' | 'expiring' | 'warning' | 'exhausted' | 'unknown'
  quotaSource: string; lastCheckedAt: string
}
interface ProviderActivity {
  id: string; providerId: string; providerName: string; accountLabel: string
  eventType: string; statusCode: number | null; message: string; model: string
  endpoint: string; latencyMs: number | null; timestamp: string; source: string
  severity: 'info' | 'warning' | 'error' | 'critical'
}
interface ProvidersData {
  providers: Provider[]; quotas: ProviderQuota[]; activity: ProviderActivity[]
  summary: {
    providerTotal: number; providerAvailable: number; providerWarning: number
    providerExhausted: number; providerUnknown: number
    activityErrorsLastHour: number; lastCheckedAt: string
  }
}

type Section = 'fleet' | 'tasks' | 'health' | 'git' | 'memory' | 'queue' | 'services' | 'constitution' | 'metrics' | 'providers' | 'provider-activity'

const SECTION_LABELS: Record<Section, string> = {
  fleet:        'Oracle Fleet',
  tasks:        'Task Board',
  health:       'Status Monitor',
  git:          'Git Activity',
  memory:       'Memory Gate',
  queue:        'Queue / ψ Vault',
  services:          'Services Health',
  constitution:      'Constitution',
  metrics:           'Session Metrics',
  providers:         'Quota Tracker',
  'provider-activity': 'Provider Activity',
}

// ── Helpers ────────────────────────────────────────────────────────────────
function fmtTime(iso: string): string {
  if (!iso) return ''
  const d = new Date(iso)
  const now = Date.now()
  const diff = now - d.getTime()
  if (diff < 60000)  return 'just now'
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
  return d.toLocaleDateString('th-TH', { day:'2-digit', month:'short' }) + ' ' +
    d.toLocaleTimeString('th-TH', { hour:'2-digit', minute:'2-digit' })
}

function statusClass(days: number): string {
  if (days < 7)   return 'active'
  if (days < 30)  return 'stale'
  if (days < 90)  return 'cold'
  if (days < 999) return 'abandoned'
  return ''
}

function badgeFor(days: number): string {
  if (days < 7)   return 'badge-green'
  if (days < 30)  return 'badge-yellow'
  if (days < 90)  return 'badge-orange'
  if (days < 999) return 'badge-red'
  return 'badge-gray'
}

function ago(days: number): string {
  if (days === 9999) return 'never'
  if (days === 0) return 'today'
  if (days === 1) return '1d ago'
  return `${days}d ago`
}

// ── Stat Cards Row ─────────────────────────────────────────────────────────
function StatCardsRow({ fleet, services, git }: {
  fleet: FleetData | null
  services: ServicesData | null
  git: GitData | null
}) {
  const svcSummary = services?.summary
  const stats = [
    {
      label: 'Total Oracles',
      value: fleet?.summary.total ?? '—',
      sub: `${fleet?.summary.active ?? 0} active`,
      color: 'var(--accent)',
      icon: '◉',
    },
    {
      label: 'Fleet Health',
      value: fleet
        ? `${Math.round((fleet.summary.active / fleet.summary.total) * 100)}%`
        : '—',
      sub: `${fleet?.summary.stale ?? 0} stale · ${fleet?.summary.cold ?? 0} cold`,
      color: 'var(--success)',
      icon: '⚡',
    },
    {
      label: 'Services',
      value: svcSummary ? `${svcSummary.online}/${svcSummary.total}` : '—',
      sub: svcSummary?.attention
        ? `${svcSummary.attention} need attention`
        : 'all online',
      color: svcSummary?.attention ? 'var(--danger)' : 'var(--success)',
      icon: '◈',
    },
    {
      label: 'Last Commit',
      value: git?.commits[0]?.ago ?? '—',
      sub: git?.commits[0]?.subject?.slice(0, 30) ?? '',
      color: 'var(--info)',
      icon: '⎇',
    },
  ]

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(4, 1fr)',
      gap: 12,
      marginBottom: 20,
    }}>
      {stats.map((s, i) => (
        <div key={i} className="stat-card" style={{
          background: 'var(--bg-card)',
          border: '1px solid var(--border)',
          borderRadius: 12,
          padding: '16px 20px',
          position: 'relative',
          overflow: 'hidden',
          transition: 'border-color 0.2s, box-shadow 0.2s',
        }}>
          {/* Glow accent top border */}
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, height: 2,
            background: `linear-gradient(90deg, ${s.color}, transparent)`,
          }} />
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
            <span style={{ color: 'var(--text-muted)', fontSize: 11, fontWeight: 500, letterSpacing: '0.04em', textTransform: 'uppercase' }}>
              {s.label}
            </span>
            <span style={{ color: s.color, fontSize: 16 }}>{s.icon}</span>
          </div>
          <div style={{ fontSize: 28, fontWeight: 700, color: 'var(--text-primary)', lineHeight: 1.1 }}>
            {s.value}
          </div>
          <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 4 }}>
            {s.sub}
          </div>
        </div>
      ))}
    </div>
  )
}

// ── Sidebar ────────────────────────────────────────────────────────────────
const NAV_ITEMS: { id: Section; label: string; icon: string }[] = [
  { id: 'fleet',        label: 'Fleet',          icon: '◉' },
  { id: 'tasks',        label: 'Task Board',     icon: '🗂️' },
  { id: 'health',       label: 'Status Monitor', icon: '⚡' },
  { id: 'git',          label: 'Git',            icon: '⎇' },
  { id: 'memory',       label: 'Memory Gate',    icon: '🧠' },
  { id: 'queue',        label: 'Queue / ψ',      icon: '📥' },
  { id: 'services',          label: 'Services',         icon: '🔌' },
  { id: 'providers',         label: 'Quota Tracker',    icon: '🔋' },
  { id: 'provider-activity', label: 'Provider Activity',icon: '📡' },
  { id: 'constitution',      label: 'Constitution',     icon: '📜' },
  { id: 'metrics',           label: 'Metrics',          icon: '📊' },
]

function Sidebar({ active, onNav }: { active: Section; onNav: (s: Section) => void }) {
  return (
    <div className="sidebar">
      <div className="sidebar-logo">
        <span style={{ color: 'var(--accent)', fontSize: 16 }}>ธ</span>
        <span style={{ color: 'var(--text-primary)', fontSize: 13, fontWeight: 700 }}>ธาม</span>
      </div>
      <nav className="sidebar-nav">
        {NAV_ITEMS.map(item => (
          <button
            key={item.id}
            className={`sidebar-item${active === item.id ? ' sidebar-item-active' : ''}`}
            onClick={() => onNav(item.id)}
          >
            <span className="sidebar-icon">{item.icon}</span>
            <span className="sidebar-label">{item.label}</span>
          </button>
        ))}
      </nav>
      <div className="sidebar-footer">
        <span style={{ fontSize: 10 }}>v2 · port 3000</span>
      </div>
    </div>
  )
}

// ── Fleet Panel ────────────────────────────────────────────────────────────
function StatBar({ s }: { s: FleetData['summary'] }) {
  return (
    <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginBottom: 4 }}>
      {[
        { label: 'active',    val: s.active,    cls: 'badge-green' },
        { label: 'stale',     val: s.stale,     cls: 'badge-yellow' },
        { label: 'cold',      val: s.cold,      cls: 'badge-orange' },
        { label: 'abandoned', val: s.abandoned, cls: 'badge-red' },
        { label: 'zygote',    val: s.zygote,    cls: 'badge-gray' },
        { label: 'total',     val: s.total,     cls: 'badge-blue' },
      ].map(({ label, val, cls }) => (
        <span key={label} className={`badge ${cls}`}>
          {val} {label}
        </span>
      ))}
    </div>
  )
}

type FleetFilter = 'all' | 'active' | 'stale' | 'cold' | 'abandoned' | 'not-awakened'

function FleetPanel({ data }: { data: FleetData | null }) {
  const [filter, setFilter] = useState<FleetFilter>('all')
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading fleet…</div>

  const oracles = data.oracles.filter(o => {
    if (filter === 'all')          return true
    if (filter === 'active')       return o.days < 7
    if (filter === 'stale')        return o.days >= 7 && o.days < 30
    if (filter === 'cold')         return o.days >= 30 && o.days < 90
    if (filter === 'abandoned')    return o.days >= 90 && o.days < 999
    if (filter === 'not-awakened') return !o.hasAwaken
    return true
  })

  return (
    <div>
      <StatBar s={data.summary} />
      <div style={{ display: 'flex', gap: 8, margin: '12px 0 10px', flexWrap: 'wrap' }}>
        {(['all','active','stale','cold','abandoned','not-awakened'] as FleetFilter[]).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`filter-btn${filter === f ? ' filter-btn-active' : ''}`}
          >
            {f}
          </button>
        ))}
      </div>
      <div className="oracle-grid">
        {oracles.map(o => (
          <div key={o.name} className={`oracle-card ${statusClass(o.days)}`}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
              <span style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-primary)' }}>
                {o.status} {o.name}
              </span>
              {o.hasAwaken && (
                <span style={{ fontSize: 10, color: '#a855f7', background: 'rgba(76,29,149,0.13)', borderRadius: 4, padding: '1px 5px', border: '1px solid rgba(124,58,237,0.2)' }}>
                  ✦ awakened
                </span>
              )}
            </div>
            <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>
              {o.branch && <span style={{ color: 'var(--success)', marginRight: 6 }}>{o.branch}</span>}
              {o.days === 0
                ? <span style={{ color: 'var(--success)' }}>today</span>
                : ago(o.days)
              }
            </div>
          </div>
        ))}
        {oracles.length === 0 && <div style={{ color: 'var(--text-muted)', padding: 8 }}>none</div>}
      </div>
    </div>
  )
}

// ── Git Panel ──────────────────────────────────────────────────────────────
function GitPanel({ data }: { data: GitData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading git…</div>
  return (
    <div>
      <div style={{ marginBottom: 10, display: 'flex', gap: 10, alignItems: 'center' }}>
        <span className="badge badge-blue">⎇ {data.branch || 'main'}</span>
        {data.dirtyFiles > 0 && (
          <span className="badge badge-yellow">~ {data.dirtyFiles} changed</span>
        )}
        {data.dirtyFiles === 0 && (
          <span className="badge badge-green">clean</span>
        )}
      </div>
      <table>
        <thead>
          <tr>
            <th>hash</th>
            <th>subject</th>
            <th>ago</th>
          </tr>
        </thead>
        <tbody>
          {data.commits.map(c => (
            <tr key={c.hash}>
              <td><span className="hash">{c.hash}</span></td>
              <td style={{ maxWidth: 380, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {c.subject}
              </td>
              <td style={{ color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>{c.ago}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// ── Memory Panel ───────────────────────────────────────────────────────────
function MemoryPanel({ data }: { data: MemData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading memory…</div>

  return (
    <div>
      <div style={{ marginBottom: 12 }}>
        {data.files.map(f => (
          <div key={f.key} style={{
            background: 'var(--bg-surface)',
            border: '1px solid var(--border)',
            borderRadius: 6,
            padding: '8px 12px',
            marginBottom: 6,
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 3 }}>
              <span style={{ color: '#93c5fd', fontSize: 12, fontWeight: 600 }}>{f.key}</span>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                {f.exists
                  ? <span className="badge badge-green">✓ exists</span>
                  : <span className="badge badge-red">✗ missing</span>
                }
                <span style={{ color: 'var(--text-muted)', fontSize: 10 }}>{f.sizeKB}KB</span>
                {f.hash && f.hash !== 'untracked' && (
                  <span className="hash">{f.hash}</span>
                )}
              </div>
            </div>
            <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>{f.path}</div>
            {f.snippet && (
              <div style={{ color: 'var(--text-muted)', fontSize: 10, marginTop: 3, fontStyle: 'italic' }}>
                {f.snippet.slice(0, 100)}
              </div>
            )}
          </div>
        ))}
      </div>

      {data.constitutionRules.length > 0 && (
        <div>
          <div style={{ fontSize: 10, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
            Constitution ({data.constitutionRules.length} rules)
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {data.constitutionRules.map((r, i) => (
              <span key={i} className="badge badge-blue" style={{ fontSize: 10 }}>
                {r.split(':')[0]}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// ── Metrics Panel ──────────────────────────────────────────────────────────
function MetricsPanel({ data }: { data: MetricsData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading metrics…</div>

  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 12 }}>
        <span className="badge badge-blue">📝 {data.retrosToday} retros today</span>
        <span className="badge badge-purple">
          💡 {data.learningsThisMonth} learnings this month
        </span>
      </div>
      {data.rows.length === 0 ? (
        <div style={{ color: 'var(--text-muted)' }}>no session metrics yet</div>
      ) : (
        <table>
          <thead>
            <tr>
              <th>when</th>
              <th>session</th>
              <th>win</th>
              <th>friction</th>
              <th>error</th>
            </tr>
          </thead>
          <tbody>
            {data.rows.map((r, i) => (
              <tr key={i}>
                <td style={{ color: 'var(--text-muted)', fontSize: 10 }}>{r.when}</td>
                <td><span className="hash">{r.session.slice(0, 8)}</span></td>
                <td style={{ color: 'var(--success)', fontSize: 11 }}>{r.win.slice(0, 40)}</td>
                <td style={{ color: 'var(--warning)', fontSize: 11 }}>{r.friction.slice(0, 40)}</td>
                <td style={{ color: 'var(--danger)', fontSize: 11 }}>{r.error.slice(0, 40)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}

// ── Inbox Panel ────────────────────────────────────────────────────────────
function InboxPanel({ data }: { data: InboxData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading queue…</div>

  const sections = [
    { label: 'inbox',  icon: '📥', val: data.inbox,  badge: 'badge-blue' },
    { label: 'outbox', icon: '📤', val: data.outbox, badge: 'badge-green' },
    { label: 'proofs', icon: '✅', val: data.proofs, badge: 'badge-blue' },
    { label: 'active', icon: '⚡', val: data.active, badge: 'badge-yellow' },
  ]

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
      {sections.map(({ label, icon, val, badge }) => {
        const raw = (val.files ?? val.recent ?? []) as (FileEntry | string)[]
        return (
          <div key={label} style={{
            background: 'var(--bg-surface)',
            border: '1px solid var(--border)',
            borderRadius: 8,
            padding: '10px 12px',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <span style={{ color: 'var(--text-primary)', fontSize: 12 }}>{icon} {label}</span>
              <span className={`badge ${badge}`}>{val.count}</span>
            </div>
            {raw.length === 0 && (
              <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>empty</div>
            )}
            {raw.map((f, i) => {
              const name   = typeof f === 'string' ? f : f.name
              const mtime  = typeof f === 'string' ? '' : f.mtime
              const sizeKB = typeof f === 'string' ? 0  : f.sizeKB
              return (
                <div key={i} style={{
                  borderBottom: i < raw.length - 1 ? '1px solid var(--border-sub)' : 'none',
                  padding: '5px 0',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  gap: 8,
                }}>
                  <span style={{ color: 'var(--text-secondary)', fontSize: 11, wordBreak: 'break-all', flex: 1 }}>
                    {name.slice(0, 36)}{name.length > 36 ? '…' : ''}
                  </span>
                  <div style={{ textAlign: 'right', flexShrink: 0 }}>
                    {mtime && (
                      <div style={{ color: 'var(--success)', fontSize: 10 }}>{fmtTime(mtime)}</div>
                    )}
                    {sizeKB > 0 && (
                      <div style={{ color: 'var(--text-muted)', fontSize: 10 }}>{sizeKB}KB</div>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        )
      })}
    </div>
  )
}

// ── Services Panel ─────────────────────────────────────────────────────────
function StatusBadge({ status }: { status: string }) {
  const map: Record<string, { cls: string; icon: string; label: string }> = {
    online:   { cls: 'badge-green',  icon: '🟢', label: 'online'   },
    offline:  { cls: 'badge-red',    icon: '🔴', label: 'offline'  },
    degraded: { cls: 'badge-orange', icon: '🟠', label: 'degraded' },
    unknown:  { cls: 'badge-gray',   icon: '⚪', label: 'unknown'  },
  }
  const b = map[status] ?? map.unknown
  return <span className={`badge ${b.cls}`}>{b.icon} {b.label}</span>
}

function ServicesPanel({ data }: { data: ServicesData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading services…</div>
  const s = data.summary
  return (
    <div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 12, alignItems: 'center', flexWrap: 'wrap' }}>
        <span className="badge badge-green">🟢 {s.online} online</span>
        {s.offline > 0 && <span className="badge badge-red">🔴 {s.offline} offline</span>}
        {s.unknown > 0 && <span className="badge badge-gray">⚪ {s.unknown} unknown</span>}
        <span style={{ color: 'var(--text-muted)', fontSize: 10, marginLeft: 'auto' }}>
          probed {data.checked_at ? fmtTime(data.checked_at) : '—'} · auto-refresh 15s
        </span>
      </div>
      <table>
        <thead>
          <tr>
            <th>service</th>
            <th>category</th>
            <th>port</th>
            <th>status</th>
            <th>latency</th>
            <th>detail</th>
          </tr>
        </thead>
        <tbody>
          {data.services.map(svc => (
            <tr key={svc.name}>
              <td style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{svc.label}</td>
              <td><span className="badge badge-gray" style={{ fontSize: 10 }}>{svc.category}</span></td>
              <td><span className="hash">{svc.port ?? '—'}</span></td>
              <td><StatusBadge status={svc.status} /></td>
              <td style={{ color: svc.latencyMs != null && svc.latencyMs < 200 ? 'var(--success)' : 'var(--text-muted)' }}>
                {svc.latencyMs != null ? `${svc.latencyMs}ms` : '—'}
              </td>
              <td style={{ color: 'var(--text-muted)', fontSize: 11 }}>{svc.detail ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// ── Constitution Panel ─────────────────────────────────────────────────────
function ConstitutionPanel({ data }: { data: ConstitutionData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading constitution…</div>
  if (data.error) return <div style={{ color: 'var(--danger)' }}>Error: {data.error}</div>

  return (
    <div>
      <div style={{ marginBottom: 12, display: 'flex', gap: 10, alignItems: 'center' }}>
        <span className="badge badge-blue">📜 {data.total} rules</span>
        <span style={{ color: 'var(--text-muted)', fontSize: 11 }}>Immutable — cannot be overridden by prompts</span>
      </div>
      <div className="constitution-grid">
        {data.rules.map(rule => (
          <div key={rule.id} className="constitution-card">
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
              <span className="badge badge-blue constitution-id">{rule.id}</span>
              <div style={{ flex: 1 }}>
                <div style={{ color: 'var(--text-primary)', fontSize: 12, fontWeight: 600, marginBottom: 4 }}>
                  {rule.title}
                </div>
                {rule.description && (
                  <div style={{ color: 'var(--text-secondary)', fontSize: 11, lineHeight: 1.5 }}>
                    {rule.description}
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── Status Monitor Panel ───────────────────────────────────────────────────
function StatusMonitorPanel({ data }: { data: HealthData | null }) {
  const [fixing, setFixing] = useState<string | null>(null)
  const [fixResult, setFixResult] = useState<Record<string, string>>({})

  async function runFix(service: string) {
    if (!service) return
    setFixing(service)
    try {
      const res = await fetch('/api/fix', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ service }),
      })
      const json = await res.json()
      setFixResult(prev => ({ ...prev, [service]: json.agent_prompt || json.message || 'Fix attempted' }))
    } catch (e) {
      setFixResult(prev => ({ ...prev, [service]: String(e) }))
    }
    setTimeout(() => setFixing(null), 3000)
  }

  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading health...</div>

  const { summary, http, tmux, runtimes, watchdog } = data
  const allHealthy = summary.unhealthy === 0

  function StatusRow({ name, detail, ok, fix, category }: { name: string; detail?: string; ok: boolean; fix?: string; category?: string }) {
    const isFixing = fixing === fix
    const result = fix ? fixResult[fix] : ''
    return (
      <div style={{
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
        padding: '7px 0', borderBottom: '1px solid var(--bg-surface)', gap: 8,
      }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 13 }}>{ok ? '🟢' : '🔴'}</span>
            <span style={{ color: ok ? 'var(--text-primary)' : 'var(--danger)', fontSize: 12, fontWeight: 600 }}>{name}</span>
            {category && <span style={{ color: 'var(--text-muted)', fontSize: 10 }}>{category}</span>}
          </div>
          {detail && (
            <div style={{ color: 'var(--text-muted)', fontSize: 10, marginTop: 2, marginLeft: 21, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 320 }}>
              {detail}
            </div>
          )}
          {result && (
            <div style={{ color: 'var(--warning)', fontSize: 10, marginTop: 4, marginLeft: 21, background: 'rgba(245,158,11,0.08)', padding: '3px 6px', borderRadius: 4, wordBreak: 'break-all' }}>
              agent: {result.slice(0, 120)}
            </div>
          )}
        </div>
        <div style={{ flexShrink: 0, display: 'flex', alignItems: 'center', gap: 8 }}>
          {!ok && fix && (
            <button
              onClick={() => runFix(fix)}
              disabled={isFixing}
              style={{
                padding: '3px 10px', borderRadius: 6, border: '1px solid var(--danger)',
                background: isFixing ? 'rgba(239,68,68,0.2)' : 'transparent',
                color: isFixing ? '#fca5a5' : 'var(--danger)',
                cursor: isFixing ? 'not-allowed' : 'pointer',
                fontSize: 10, fontFamily: 'inherit', fontWeight: 600,
              }}
            >
              {isFixing ? '⟳ fixing…' : '⚡ Fix'}
            </button>
          )}
        </div>
      </div>
    )
  }

  return (
    <div>
      {/* Summary bar */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
        <span className={`badge ${allHealthy ? 'badge-green' : 'badge-red'}`}>
          {allHealthy ? '✓ All healthy' : `${summary.unhealthy} issue${summary.unhealthy > 1 ? 's' : ''}`}
        </span>
        <span className="badge badge-green">{summary.healthy} healthy</span>
        {summary.unhealthy > 0 && <span className="badge badge-red">{summary.unhealthy} unhealthy</span>}
        {summary.git_dirty > 0 && <span className="badge badge-yellow">~ {summary.git_dirty} uncommitted</span>}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        {/* HTTP Services */}
        <div>
          <div style={{ color: 'var(--text-muted)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
            HTTP Access Points
          </div>
          {http.map(s => (
            <StatusRow key={s.name} name={s.label || s.name}
              detail={s.ok ? `${s.code} · ${s.latency}ms · ${s.url}` : (s.detail || `${s.code} timeout`)}
              ok={s.ok} fix={s.fix} category="http" />
          ))}
        </div>

        {/* Runtimes + Watchdog + tmux */}
        <div>
          <div style={{ color: 'var(--text-muted)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
            Runtime Tools
          </div>
          {runtimes.map(r => (
            <StatusRow key={r.name} name={r.name} detail={r.detail} ok={r.ok} fix={r.fix} category="tool" />
          ))}

          <div style={{ color: 'var(--text-muted)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.08em', margin: '12px 0 8px' }}>
            Watchdog
          </div>
          {watchdog.map((w, i) => (
            <StatusRow key={i} name={w.name} detail={w.pid ? `PID ${w.pid}` : ''} ok={w.ok} fix={w.fix} category="watchdog" />
          ))}

          <div style={{ color: 'var(--text-muted)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.08em', margin: '12px 0 8px' }}>
            tmux Sessions
          </div>
          {tmux.map((t, i) => (
            <StatusRow key={i} name={t.name} detail={t.detail} ok={t.ok} fix={t.fix} category="tmux" />
          ))}
        </div>
      </div>

      <div style={{ marginTop: 8, color: 'var(--text-muted)', fontSize: 10 }}>
        probed {new Date(data.checked_at).toLocaleTimeString('th-TH')} · ⚡ Fix triggers AI agent diagnostic
      </div>
    </div>
  )
}

// ── Task Board Panel ───────────────────────────────────────────────────────
const COLUMN_CONFIG = [
  { key: 'inbox',   label: 'Inbox',   color: 'var(--accent)',    icon: '📥' },
  { key: 'active',  label: 'Active',  color: 'var(--warning)',   icon: '⚡' },
  { key: 'outbox',  label: 'Outbox',  color: 'var(--success)',   icon: '📤' },
  { key: 'proofs',  label: 'Proofs',  color: 'var(--info)',      icon: '✅' },
  { key: 'archive', label: 'Archive', color: 'var(--text-muted)', icon: '📦' },
]

function TaskBoardPanel({ data }: { data: TasksData | null }) {
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading tasks…</div>
  return (
    <div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <span className="badge badge-blue">{data.total} total tasks</span>
        <span className="badge badge-yellow">{data.columns.active.length} in progress</span>
        <span className="badge badge-green">{data.columns.proofs.length} proven</span>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 10 }}>
        {COLUMN_CONFIG.map(col => {
          const tasks = (data.columns as Record<string, Task[]>)[col.key] ?? []
          return (
            <div key={col.key} style={{
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 10,
              overflow: 'hidden',
            }}>
              {/* Column header */}
              <div style={{
                padding: '10px 12px',
                borderBottom: `2px solid ${col.color}`,
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              }}>
                <span style={{ fontSize: 11, fontWeight: 600, color: col.color }}>
                  {col.icon} {col.label}
                </span>
                <span style={{
                  background: `color-mix(in srgb, ${col.color} 13%, transparent)`,
                  color: col.color,
                  borderRadius: 999, padding: '1px 7px', fontSize: 10, fontWeight: 700,
                }}>
                  {tasks.length}
                </span>
              </div>
              {/* Task cards */}
              <div style={{ padding: 8, display: 'flex', flexDirection: 'column', gap: 6, minHeight: 60 }}>
                {tasks.slice(0, 8).map(t => (
                  <div key={t.id} style={{
                    background: 'var(--bg-surface)',
                    border: '1px solid var(--border-sub)',
                    borderRadius: 7,
                    padding: '7px 10px',
                  }}>
                    <div style={{ color: 'var(--text-primary)', fontSize: 11, fontWeight: 500, marginBottom: 3, wordBreak: 'break-word' }}>
                      {t.name.slice(0, 30)}{t.name.length > 30 ? '…' : ''}
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text-muted)', fontSize: 10 }}>
                      <span>{t.type}</span>
                      <span>{fmtTime(t.mtime)}</span>
                    </div>
                  </div>
                ))}
                {tasks.length === 0 && (
                  <div style={{ color: 'var(--text-muted)', fontSize: 10, padding: '8px 2px' }}>empty</div>
                )}
                {tasks.length > 8 && (
                  <div style={{ color: 'var(--text-muted)', fontSize: 10, textAlign: 'center', padding: '4px 0' }}>
                    +{tasks.length - 8} more
                  </div>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

// ── Quota Tracker Panel ────────────────────────────────────────────────────
function ProviderStatusBadge({ status }: { status: string }) {
  const map: Record<string, { cls: string; icon: string }> = {
    available:   { cls: 'badge-green',  icon: '🟢' },
    degraded:    { cls: 'badge-orange', icon: '🟠' },
    unavailable: { cls: 'badge-red',    icon: '🔴' },
    exhausted:   { cls: 'badge-red',    icon: '🔴' },
    expiring:    { cls: 'badge-orange', icon: '🟠' },
    warning:     { cls: 'badge-yellow', icon: '🟡' },
    unknown:     { cls: 'badge-gray',   icon: '⚪' },
  }
  const b = map[status] ?? map.unknown
  return <span className={`badge ${b.cls}`}>{b.icon} {status}</span>
}

function SeverityBadge({ severity }: { severity: string }) {
  const map: Record<string, { cls: string; icon: string }> = {
    info:     { cls: 'badge-blue',   icon: 'ℹ' },
    warning:  { cls: 'badge-yellow', icon: '⚠' },
    error:    { cls: 'badge-orange', icon: '✖' },
    critical: { cls: 'badge-red',    icon: '🚨' },
  }
  const b = map[severity] ?? map.info
  return <span className={`badge ${b.cls}`}>{b.icon} {severity}</span>
}

function QuotaTrackerPanel({ data }: { data: ProvidersData | null }) {
  const [filter, setFilter] = useState<string>('all')
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading quota tracker…</div>
  const { providers, quotas, summary } = data

  const providerFilters = ['all', 'available', 'degraded', 'unavailable', 'unknown']
  const visibleProviders = filter === 'all'
    ? providers
    : providers.filter(p => p.status === filter)

  return (
    <div>
      {/* KPI row */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 14, flexWrap: 'wrap', alignItems: 'center' }}>
        <span className="badge badge-blue">🔋 {summary.providerTotal} providers</span>
        <span className="badge badge-green">🟢 {summary.providerAvailable} available</span>
        {summary.providerWarning > 0 && <span className="badge badge-orange">🟠 {summary.providerWarning} degraded</span>}
        {summary.providerExhausted > 0 && <span className="badge badge-red">🔴 {summary.providerExhausted} exhausted</span>}
        {summary.providerUnknown > 0 && <span className="badge badge-gray">⚪ {summary.providerUnknown} unknown</span>}
        <span style={{ color: 'var(--text-muted)', fontSize: 10, marginLeft: 'auto' }}>
          checked {fmtTime(summary.lastCheckedAt)} · 30s refresh
        </span>
      </div>

      {/* Filter */}
      <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
        {providerFilters.map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`filter-btn${filter === f ? ' filter-btn-active' : ''}`}>
            {f}
          </button>
        ))}
      </div>

      {/* Provider table */}
      <table>
        <thead>
          <tr>
            <th>provider</th>
            <th>type</th>
            <th>model</th>
            <th>status</th>
            <th>latency</th>
            <th>quota limit</th>
            <th>quota status</th>
            <th>source</th>
          </tr>
        </thead>
        <tbody>
          {visibleProviders.map(p => {
            const q = quotas.find(q => q.providerId === p.id)
            return (
              <tr key={p.id}>
                <td style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{p.providerName}</td>
                <td><span className="badge badge-gray" style={{ fontSize: 10 }}>{p.type}</span></td>
                <td style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{p.model}</td>
                <td><ProviderStatusBadge status={p.status} /></td>
                <td style={{ color: 'var(--text-muted)', fontSize: 11 }}>
                  {p.latencyMs != null ? `${p.latencyMs}ms` : '—'}
                </td>
                <td style={{ fontSize: 11 }}>
                  {q?.limit != null ? q.limit.toLocaleString() : 'unknown'}
                </td>
                <td>
                  {q ? <ProviderStatusBadge status={q.status} /> : <span className="badge badge-gray">⚪ unknown</span>}
                </td>
                <td style={{ fontSize: 10, color: 'var(--text-muted)' }}>
                  {q?.quotaSource ?? '—'}
                </td>
              </tr>
            )
          })}
          {visibleProviders.length === 0 && (
            <tr><td colSpan={8} style={{ color: 'var(--text-muted)', textAlign: 'center', padding: 16 }}>
              No providers match filter: {filter}
            </td></tr>
          )}
        </tbody>
      </table>
    </div>
  )
}

// ── Provider Activity Panel ────────────────────────────────────────────────
function ProviderActivityPanel({ data }: { data: ProvidersData | null }) {
  const [sevFilter, setSevFilter] = useState<string>('all')
  if (!data) return <div style={{ color: 'var(--text-muted)' }}>loading provider activity…</div>
  const { activity, summary } = data

  const eventIcons: Record<string, string> = {
    connected:       '🟢',
    disconnected:    '🔴',
    request_ok:      '✅',
    auth_error:      '🔑',
    rate_limited:    '⏱',
    quota_exhausted: '🈳',
    timeout:         '⏸',
    unavailable:     '🔴',
    config_changed:  '⚙',
    probe:           '🔍',
  }

  const sevFilters = ['all', 'critical', 'error', 'warning', 'info']
  const visible = sevFilter === 'all'
    ? activity
    : activity.filter(a => a.severity === sevFilter)

  return (
    <div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 12, alignItems: 'center', flexWrap: 'wrap' }}>
        {summary.activityErrorsLastHour > 0
          ? <span className="badge badge-red">🚨 {summary.activityErrorsLastHour} errors (last hour)</span>
          : <span className="badge badge-green">✓ no errors last hour</span>
        }
        <span style={{ color: 'var(--text-muted)', fontSize: 10, marginLeft: 'auto' }}>
          {activity.length} events · auto-refresh 30s
        </span>
      </div>
      <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
        {sevFilters.map(f => (
          <button key={f} onClick={() => setSevFilter(f)}
            className={`filter-btn${sevFilter === f ? ' filter-btn-active' : ''}`}>
            {f}
          </button>
        ))}
      </div>
      <table>
        <thead>
          <tr>
            <th>time</th>
            <th>provider</th>
            <th>event</th>
            <th>code</th>
            <th>model</th>
            <th>latency</th>
            <th>message</th>
            <th>severity</th>
          </tr>
        </thead>
        <tbody>
          {visible.map(a => (
            <tr key={a.id}>
              <td style={{ fontSize: 10, color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>{fmtTime(a.timestamp)}</td>
              <td style={{ fontWeight: 600, fontSize: 11 }}>{a.providerName}</td>
              <td style={{ fontSize: 11 }}>
                {eventIcons[a.eventType] ?? '•'} {a.eventType.replace(/_/g, ' ')}
              </td>
              <td>
                {a.statusCode
                  ? <span className={`hash ${a.statusCode >= 400 ? 'style={{color:"var(--danger)"}}' : ''}`}>{a.statusCode}</span>
                  : <span style={{ color: 'var(--text-muted)' }}>—</span>
                }
              </td>
              <td style={{ fontSize: 10, color: 'var(--text-secondary)' }}>{a.model?.split('/').pop() ?? '—'}</td>
              <td style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                {a.latencyMs != null ? `${a.latencyMs}ms` : '—'}
              </td>
              <td style={{ fontSize: 11, color: 'var(--text-secondary)', maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {a.message}
              </td>
              <td><SeverityBadge severity={a.severity} /></td>
            </tr>
          ))}
          {visible.length === 0 && (
            <tr><td colSpan={8} style={{ color: 'var(--text-muted)', textAlign: 'center', padding: 16 }}>
              No activity events{sevFilter !== 'all' ? ` with severity: ${sevFilter}` : ''}
            </td></tr>
          )}
        </tbody>
      </table>
    </div>
  )
}

// ── Main Page ──────────────────────────────────────────────────────────────
export default function Dashboard() {
  const [activeSection, setActiveSection] = useState<Section>('fleet')
  const [fleet,         setFleet]         = useState<FleetData | null>(null)
  const [git,           setGit]           = useState<GitData | null>(null)
  const [mem,           setMem]           = useState<MemData | null>(null)
  const [metrics,       setMetrics]       = useState<MetricsData | null>(null)
  const [inbox,         setInbox]         = useState<InboxData | null>(null)
  const [services,      setServices]      = useState<ServicesData | null>(null)
  const [constitution,  setConstitution]  = useState<ConstitutionData | null>(null)
  const [health,        setHealth]        = useState<HealthData | null>(null)
  const [tasks,         setTasks]         = useState<TasksData | null>(null)
  const [providers,     setProviders]     = useState<ProvidersData | null>(null)
  const [lastRefresh,   setLastRefresh]   = useState<string>('')
  const [refreshing,    setRefreshing]    = useState(false)

  const refresh = useCallback(async () => {
    setRefreshing(true)
    await Promise.all([
      fetch('/api/fleet').then(r => r.json()).then(setFleet).catch(() => {}),
      fetch('/api/git').then(r => r.json()).then(setGit).catch(() => {}),
      fetch('/api/memory').then(r => r.json()).then(setMem).catch(() => {}),
      fetch('/api/metrics').then(r => r.json()).then(setMetrics).catch(() => {}),
      fetch('/api/inbox').then(r => r.json()).then(setInbox).catch(() => {}),
      fetch('/api/constitution').then(r => r.json()).then(setConstitution).catch(() => {}),
      fetch('/api/health').then(r => r.json()).then(setHealth).catch(() => {}),
      fetch('/api/tasks').then(r => r.json()).then(setTasks).catch(() => {}),
    ])
    setLastRefresh(new Date().toLocaleTimeString('th-TH'))
    setRefreshing(false)
  }, [])

  const refreshProviders = useCallback(async () => {
    fetch('/api/forge-omega/providers/status').then(r => r.json()).then(setProviders).catch(() => {})
  }, [])

  const refreshServices = useCallback(async () => {
    fetch('/api/services').then(r => r.json()).then(setServices).catch(() => {})
}, [])

  useEffect(() => {
    refresh()
    refreshServices()
    refreshProviders()
    const timer = setInterval(refresh, 30000)
    const svcTimer = setInterval(refreshServices, 15000)
    const provTimer = setInterval(refreshProviders, 30000)
    return () => { clearInterval(timer); clearInterval(svcTimer); clearInterval(provTimer) }
  }, [refresh, refreshServices, refreshProviders])

  return (
    <div style={{ minHeight: '100vh' }}>
      {/* Sidebar */}
      <Sidebar active={activeSection} onNav={setActiveSection} />

      {/* Main content */}
      <div className="main-content">
        {/* Header */}
        <div className="top-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--text-primary)' }}>ธาม Oracle</span>
            <span style={{ color: 'var(--border)' }}>—</span>
            <span style={{ color: '#93c5fd', fontSize: 13, fontWeight: 600 }}>
              {SECTION_LABELS[activeSection]}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            {fleet?.summary && (
              <div style={{ display: 'flex', gap: 8 }}>
                <span className="badge badge-green">{fleet.summary.active} active</span>
                <span className="badge badge-blue">{fleet.summary.total} oracles</span>
              </div>
            )}
            <button
              onClick={() => { refresh(); refreshServices() }}
              className={`refresh-btn${refreshing ? ' refresh-btn-active' : ''}`}
            >
              {refreshing ? '⟳ refreshing…' : '⟳ refresh'}
            </button>
          </div>
        </div>

        {/* Body */}
        <div style={{ padding: '16px 20px 64px' }}>

          {/* Stat Cards — always visible */}
          <StatCardsRow fleet={fleet} services={services} git={git} />

          {activeSection === 'fleet' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--success)' }} />
                Oracle Fleet
              </div>
              <FleetPanel data={fleet} />
            </div>
          )}

          {activeSection === 'tasks' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--warning)' }} />
                Task Board (ψ Vault)
              </div>
              <TaskBoardPanel data={tasks} />
            </div>
          )}

          {activeSection === 'health' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--success)' }} />
                Status Monitor — Health Probe + Fix
              </div>
              <StatusMonitorPanel data={health} />
            </div>
          )}

          {activeSection === 'git' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--accent)' }} />
                Git Activity — tham-oracle
              </div>
              <GitPanel data={git} />
            </div>
          )}

          {activeSection === 'memory' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: '#a855f7' }} />
                Memory Gate
              </div>
              <MemoryPanel data={mem} />
            </div>
          )}

          {activeSection === 'queue' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--warning)' }} />
                Queue / ψ Vault
              </div>
              <InboxPanel data={inbox} />
            </div>
          )}

          {activeSection === 'services' && (
            <div className="card">
              <div className="card-header">
                <span className="dot service-online-dot" style={{ background: 'var(--success)' }} />
                Services Health
              </div>
              <ServicesPanel data={services} />
            </div>
          )}

          {activeSection === 'constitution' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--accent)' }} />
                Constitution — Immutable Core Rules
              </div>
              <ConstitutionPanel data={constitution} />
            </div>
          )}

          {activeSection === 'metrics' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--info)' }} />
                Session Metrics
              </div>
              <MetricsPanel data={metrics} />
            </div>
          )}

          {activeSection === 'providers' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--accent2)' }} />
                🔋 Quota Tracker
                <button onClick={refreshProviders} className="refresh-btn" style={{ marginLeft: 'auto' }}>↻ refresh</button>
              </div>
              <QuotaTrackerPanel data={providers} />
            </div>
          )}

          {activeSection === 'provider-activity' && (
            <div className="card">
              <div className="card-header">
                <span className="dot" style={{ background: 'var(--info)' }} />
                📡 API Provider Connection Activity
                <button onClick={refreshProviders} className="refresh-btn" style={{ marginLeft: 'auto' }}>↻ refresh</button>
              </div>
              <ProviderActivityPanel data={providers} />
            </div>
          )}

        </div>

        {/* Status bar */}
        <div className="statusbar">
          <span className={refreshing ? 'pulse' : ''} style={{ color: 'var(--success)' }}>●</span>
          <span>ธาม Oracle</span>
          <span style={{ color: 'var(--border)' }}>|</span>
          <span>auto-refresh 30s · services 15s</span>
          <span style={{ color: 'var(--border)' }}>|</span>
          <span>last: {lastRefresh || '—'}</span>
          {git?.branch && (
            <>
              <span style={{ color: 'var(--border)' }}>|</span>
              <span>⎇ {git.branch}</span>
            </>
          )}
          {services?.summary && (
            <>
              <span style={{ color: 'var(--border)' }}>|</span>
              <span style={{ color: services.summary.attention === 0 ? 'var(--success)' : 'var(--danger)' }}>
                {services.summary.online}/{services.summary.total} services
              </span>
            </>
          )}
          <span style={{ marginLeft: 'auto', color: 'var(--text-muted)' }}>port 3000</span>
        </div>
      </div>
    </div>
  )
}
