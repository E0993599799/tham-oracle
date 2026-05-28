'use client'

import React, { memo, useEffect, useState, useCallback, useRef, useTransition } from 'react'
import { COMMAND_OPTIONS, type CommandId } from '@/lib/command-catalog'

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
interface MetricsData { rows: MetricRow[]; retrosToday: number; learningsThisMonth: number; brainLearnings: number; error?: string }
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
interface CommandRunResult {
  commandId: string
  executable: string
  args: string[]
  cwd: string
  stdout: string
  stderr: string
  exitCode: number | null
  signal: string | null
  durationMs: number
  checked_at: string
  ok: boolean
  error: string
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

type Section = 'fleet' | 'tasks' | 'health' | 'commands' | 'git' | 'memory' | 'queue' | 'services' | 'constitution' | 'metrics' | 'providers' | 'provider-activity' | 'erp'

const SECTION_LABELS: Record<Section, string> = {
  fleet:        'Oracle Fleet',
  tasks:        'Task Board',
  health:       'Status Monitor',
  commands:     'Command Runner',
  git:          'Git Activity',
  memory:       'Memory Gate',
  queue:        'Queue / ψ Vault',
  services:          'Services Health',
  constitution:      'Constitution',
  metrics:           'Session Metrics',
  providers:         'Quota Tracker',
  'provider-activity': 'Provider Activity',
  erp:               'Omega/Oracle Bridge',
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
const StatCardsRow = memo(function StatCardsRow({ fleet, services, git }: {
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
        ? (fleet.summary.total > 0
          ? `${Math.round((fleet.summary.active / fleet.summary.total) * 100)}%`
          : '—')
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
    <div className="stat-cards-row">
      {stats.map((s, i) => (
        <div key={i} className="stat-card">
          <div className="stat-card-accent" style={{ color: s.color }} />
          <div className="stat-card-header">
            <span className="stat-card-label">{s.label}</span>
            <span className="stat-card-icon" style={{ color: s.color }}>{s.icon}</span>
          </div>
          <div className="stat-card-value">{s.value}</div>
          <div className="stat-card-sub">{s.sub}</div>
        </div>
      ))}
    </div>
  )
})

// ── Sidebar ────────────────────────────────────────────────────────────────
const NAV_ITEMS: { id: Section; label: string; icon: string }[] = [
  { id: 'fleet',        label: 'Fleet',          icon: '◉' },
  { id: 'tasks',        label: 'Task Board',     icon: '🗂️' },
  { id: 'health',       label: 'Status Monitor', icon: '⚡' },
  { id: 'commands',     label: 'Command Runner', icon: '⌘' },
  { id: 'git',          label: 'Git',            icon: '⎇' },
  { id: 'memory',       label: 'Memory Gate',    icon: '🧠' },
  { id: 'queue',        label: 'Queue / ψ',      icon: '📥' },
  { id: 'services',    label: 'Services',       icon: '🔌' },
  { id: 'providers',   label: 'Quota Tracker',  icon: '🔋' },
  { id: 'provider-activity', label: 'Provider Activity', icon: '📈' },
  { id: 'constitution', label: 'Constitution',   icon: '📜' },
  { id: 'metrics',      label: 'Metrics',        icon: '📊' },
  { id: 'erp',          label: 'Bridge',         icon: '🧭' },
]

function Sidebar({ active, onNav }: { active: Section; onNav: (s: Section) => void }) {
  return (
    <div className="sidebar">
      <div className="sidebar-logo">
        <img src="/icon.svg" alt="" aria-hidden="true" width={22} height={22} style={{ display: 'block' }} />
        <span style={{ color: 'var(--text-primary)', fontSize: 14, fontWeight: 700 }}>ธาม</span>
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
        <span style={{ fontSize: 10 }}>v2 · port 3005</span>
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

const FleetPanel = memo(function FleetPanel({ data }: { data: FleetData | null }) {
  const [filter, setFilter] = useState<FleetFilter>('all')
  if (!data) return <div className="panel-content">loading fleet…</div>

  const oracles = data.oracles.filter(o => {
    if (filter === 'all')          return true
    if (filter === 'active')       return o.days < 7
    if (filter === 'stale')        return o.days >= 7 && o.days < 30
    if (filter === 'cold')         return o.days >= 30 && o.days < 90
    if (filter === 'abandoned')    return o.days >= 90 && o.days < 999
    if (filter === 'not-awakened') return !o.hasAwaken
    return true
  })

  const notAwakened = data.oracles.filter(o => !o.hasAwaken).length

  return (
    <div>
      <div className="panel-badge-row">
        <span className="badge badge-blue">◉ {data.summary.total} total</span>
        <span className="badge badge-green">⚡ {data.summary.active} active</span>
        <span className="badge badge-yellow">◔ {data.summary.stale} stale</span>
        {data.summary.cold > 0 && <span className="badge badge-orange">◕ {data.summary.cold} cold</span>}
        {data.summary.abandoned > 0 && <span className="badge badge-red">◑ {data.summary.abandoned} abandoned</span>}
        {notAwakened > 0 && <span className="badge badge-gray">✧ {notAwakened} not awakened</span>}
      </div>
      <StatBar s={data.summary} />
      <div className="panel-filter-row">
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
            <div className="oracle-card-header">
              <span className="oracle-card-title">
                {o.status} {o.name}
              </span>
              {o.hasAwaken && (
                <span className="oracle-card-badge">✦ awakened</span>
              )}
            </div>
            <div className="oracle-card-info">
              {o.branch && <span className="oracle-card-info-branch">{o.branch}</span>}
              {o.days === 0
                ? <span style={{ color: 'var(--success)' }}>today</span>
                : ago(o.days)
              }
            </div>
            <div className="oracle-card-path">{o.path}</div>
            <div className="oracle-card-commit">
              last commit {o.lastCommit ? fmtTime(o.lastCommit) : '—'}
            </div>
          </div>
        ))}
        {oracles.length === 0 && <div className="panel-empty">none</div>}
      </div>
    </div>
  )
})

// ── Git Panel ──────────────────────────────────────────────────────────────
const GitPanel = memo(function GitPanel({ data }: { data: GitData | null }) {
  if (!data) return <div className="panel-content">loading git…</div>
  return (
    <div>
      <div className="panel-badge-row">
        <span className="badge badge-blue">⎇ {data.branch || 'main'}</span>
        {data.dirtyFiles > 0 && (
          <span className="badge badge-yellow">~ {data.dirtyFiles} changed</span>
        )}
        {data.dirtyFiles === 0 && (
          <span className="badge badge-green">clean</span>
        )}
      </div>
      <div className="git-table-container">
        <table>
          <thead>
            <tr>
              <th>hash</th>
              <th>subject</th>
              <th>author</th>
              <th>ago</th>
            </tr>
          </thead>
          <tbody>
            {data.commits.map(c => (
              <tr key={c.hash}>
                <td><span className="hash">{c.hash}</span></td>
                <td className="git-table-cell-hash">{c.subject}</td>
                <td className="git-table-cell-author">{c.author}</td>
                <td className="git-table-cell-time">{c.ago}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
})

// ── Memory Panel ───────────────────────────────────────────────────────────
const MemoryPanel = memo(function MemoryPanel({ data }: { data: MemData | null }) {
  if (!data) return <div className="panel-content">loading memory…</div>

  const existing = data.files.filter(f => f.exists).length

  return (
    <div>
      <div className="panel-badge-row">
        <span className="badge badge-blue">🧠 {data.files.length} memory files</span>
        <span className="badge badge-green">✓ {existing} present</span>
        {data.files.length - existing > 0 && <span className="badge badge-red">✗ {data.files.length - existing} missing</span>}
        <span className="badge badge-purple">📜 {data.constitutionRules.length} constitution rules</span>
      </div>

      <div style={{ marginBottom: 12 }}>
        {data.files.map(f => (
          <div key={f.key} className="memory-file-item">
            <div className="memory-file-header">
              <span className="memory-file-key">{f.key}</span>
              <div className="memory-file-meta">
                {f.exists
                  ? <span className="badge badge-green">✓ exists</span>
                  : <span className="badge badge-red">✗ missing</span>
                }
                <span className="memory-file-meta-text">{f.sizeKB}KB</span>
                {f.lastModified && <span className="memory-file-meta-text">{fmtTime(f.lastModified)}</span>}
                {f.hash && f.hash !== 'untracked' && (
                  <span className="hash">{f.hash}</span>
                )}
              </div>
            </div>
            <div className="memory-file-path">{f.path}</div>
            {f.snippet && (
              <div className="memory-file-snippet">
                {f.snippet.slice(0, 100)}
              </div>
            )}
          </div>
        ))}
      </div>

      {data.constitutionRules.length > 0 && (
        <div>
          <div className="panel-section-header">
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
})

// ── Metrics Panel ──────────────────────────────────────────────────────────
const MetricsPanel = memo(function MetricsPanel({ data }: { data: MetricsData | null }) {
  if (!data) return <div className="panel-content">loading metrics…</div>

  return (
    <div>
      <div className="metrics-header">
        <span className="badge badge-blue">📝 {data.retrosToday} retros today</span>
        <span className="badge badge-purple">
          💡 {data.learningsThisMonth} learnings this month
        </span>
        <span className="badge badge-green">
          🧠 {data.brainLearnings} brain reflections
        </span>
      </div>
      {data.rows.length === 0 ? (
        <div className="metrics-empty">no session metrics yet</div>
      ) : (
        <div className="metrics-table-container">
          <table>
            <thead>
              <tr>
                <th>when</th>
                <th>session</th>
                <th>done</th>
                <th>stuck</th>
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
                  <td style={{ color: 'var(--text-secondary)', fontSize: 11 }}>{r.done.slice(0, 24)}</td>
                  <td style={{ color: 'var(--danger)', fontSize: 11 }}>{r.stuck.slice(0, 24)}</td>
                  <td style={{ color: 'var(--success)', fontSize: 11 }}>{r.win.slice(0, 40)}</td>
                  <td style={{ color: 'var(--warning)', fontSize: 11 }}>{r.friction.slice(0, 40)}</td>
                  <td style={{ color: 'var(--danger)', fontSize: 11 }}>{r.error.slice(0, 40)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
})

// ── Inbox Panel ────────────────────────────────────────────────────────────
const InboxPanel = memo(function InboxPanel({ data }: { data: InboxData | null }) {
  if (!data) return <div className="panel-content">loading queue…</div>

  const sections = [
    { label: 'inbox',  icon: '📥', val: data.inbox,  badge: 'badge-blue' },
    { label: 'outbox', icon: '📤', val: data.outbox, badge: 'badge-green' },
    { label: 'proofs', icon: '✅', val: data.proofs, badge: 'badge-blue' },
    { label: 'active', icon: '⚡', val: data.active, badge: 'badge-yellow' },
  ]

  return (
    <div className="inbox-grid">
      {sections.map(({ label, icon, val, badge }) => {
        const raw = (val.files ?? val.recent ?? []) as (FileEntry | string)[]
        return (
          <div key={label} className="inbox-section">
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8, alignItems: 'center' }}>
              <span style={{ color: 'var(--text-primary)', fontSize: 12 }}>{icon} {label}</span>
              <span className={`badge ${badge}`}>{val.count}</span>
            </div>
            {raw.length === 0 && (
              <div className="inbox-empty">empty</div>
            )}
            {raw.map((f, i) => {
              const name   = typeof f === 'string' ? f : f.name
              const mtime  = typeof f === 'string' ? '' : f.mtime
              const sizeKB = typeof f === 'string' ? 0  : f.sizeKB
              return (
                <div key={i} className="inbox-file-item" style={{ borderBottom: i < raw.length - 1 ? '1px solid var(--border-sub)' : 'none' }}>
                  <span className="inbox-file-name" style={{ color: 'var(--text-secondary)' }}>
                    {name.slice(0, 36)}{name.length > 36 ? '…' : ''}
                  </span>
                  <div className="inbox-file-meta">
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
})

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

const ServicesPanel = memo(function ServicesPanel({ data }: { data: ServicesData | null }) {
  if (!data) return <div className="panel-content">loading services…</div>
  const s = data.summary
  return (
    <div>
      <div className="services-header">
        <span className="badge badge-green">🟢 {s.online} online</span>
        {s.offline > 0 && <span className="badge badge-red">🔴 {s.offline} offline</span>}
        {s.unknown > 0 && <span className="badge badge-gray">⚪ {s.unknown} unknown</span>}
        {s.attention > 0 && <span className="badge badge-orange">⚠ {s.attention} attention</span>}
        <span className="services-probe-time">
          probed {data.checked_at ? fmtTime(data.checked_at) : '—'} · auto-refresh 15s
        </span>
      </div>
      <div className="services-table-container">
        <table>
          <thead>
            <tr>
              <th>service</th>
              <th>category</th>
              <th>port</th>
              <th>status</th>
              <th>latency</th>
              <th>source</th>
              <th>detail</th>
            </tr>
          </thead>
          <tbody>
            {data.services.map(svc => (
              <tr key={svc.name}>
                <td className="services-table-name">{svc.label}</td>
                <td><span className="badge badge-gray" style={{ fontSize: 10 }}>{svc.category}</span></td>
                <td><span className="hash">{svc.port ?? '—'}</span></td>
                <td><StatusBadge status={svc.status} /></td>
                <td className={svc.latencyMs != null && svc.latencyMs < 200 ? 'services-table-latency-fast' : 'services-table-latency-slow'}>
                  {svc.latencyMs != null ? `${svc.latencyMs}ms` : '—'}
                </td>
                <td className="services-table-source">{svc.source ?? '—'}</td>
                <td className="services-table-detail">{svc.detail ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
})

// ── Constitution Panel ─────────────────────────────────────────────────────
const ConstitutionPanel = memo(function ConstitutionPanel({ data }: { data: ConstitutionData | null }) {
  if (!data) return <div className="panel-content">loading constitution…</div>
  if (data.error) return <div style={{ color: 'var(--danger)' }}>Error: {data.error}</div>

  return (
    <div>
      <div className="constitution-header">
        <span className="badge badge-blue">📜 {data.total} rules</span>
        <span className="constitution-note">Immutable — cannot be overridden by prompts</span>
      </div>
      <div className="constitution-grid">
        {data.rules.map(rule => (
          <div key={rule.id} className="constitution-card">
            <div className="constitution-card-content">
              <span className="badge badge-blue constitution-card-id">{rule.id}</span>
              <div className="constitution-card-body">
                <div className="constitution-card-title">
                  {rule.title}
                </div>
                {rule.description && (
                  <div className="constitution-card-description">
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
})

// ── Status Monitor Panel ───────────────────────────────────────────────────
const StatusMonitorPanel = memo(function StatusMonitorPanel({ data }: { data: HealthData | null }) {
  const [fixing, setFixing] = useState<string | null>(null)
  const [fixResult, setFixResult] = useState<Record<string, string>>({})

  async function runFix(service: string) {
    if (!service) return
    setFixing(service)
    try {
      const res = await fetch('/api/fix', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        cache: 'no-store',
        body: JSON.stringify({ service }),
      })
      const json = await res.json()
      setFixResult(prev => ({ ...prev, [service]: json.agent_prompt || json.message || 'Fix attempted' }))
    } catch (e) {
      setFixResult(prev => ({ ...prev, [service]: String(e) }))
    }
    setTimeout(() => setFixing(null), 3000)
  }

  if (!data) return <div className="panel-content">loading health...</div>

  const { summary, http, tmux, runtimes, watchdog } = data
  const allHealthy = summary.unhealthy === 0

  const StatusRow = memo(function StatusRow({ name, detail, ok, fix, category }: { name: string; detail?: string; ok: boolean; fix?: string; category?: string }) {
    const isFixing = fixing === fix
    const result = fix ? fixResult[fix] : ''
    return (
      <div className="status-row" style={{ borderBottom: '1px solid var(--bg-surface)' }}>
        <div className="status-row-left">
          <span className="status-row-icon">{ok ? '🟢' : '🔴'}</span>
          <div className="status-row-info">
            <span className="status-row-name" style={{ color: ok ? 'var(--text-primary)' : 'var(--danger)' }}>
              {name}
            </span>
            {category && <span style={{ color: 'var(--text-muted)', fontSize: 10 }}>{category}</span>}
          </div>
          {detail && (
            <div className="status-row-detail">
              {detail}
            </div>
          )}
          {result && (
            <div style={{ color: 'var(--warning)', fontSize: 10, marginTop: 4, marginLeft: 21, background: 'rgba(245,158,11,0.08)', padding: '3px 6px', borderRadius: 4, wordBreak: 'break-all' }}>
              agent: {result.slice(0, 120)}
            </div>
          )}
        </div>
        <div className="status-row-fix">
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
  })

  return (
    <div>
      <div className="health-summary">
        <span className={`badge ${allHealthy ? 'badge-green' : 'badge-red'}`}>
          {allHealthy ? '✓ All healthy' : `${summary.unhealthy} issue${summary.unhealthy > 1 ? 's' : ''}`}
        </span>
        <span className="badge badge-blue">{summary.total} total</span>
        <span className="badge badge-green">{summary.healthy} healthy</span>
        {summary.unhealthy > 0 && <span className="badge badge-red">{summary.unhealthy} unhealthy</span>}
        {summary.git_dirty > 0 && <span className="badge badge-yellow">~ {summary.git_dirty} uncommitted</span>}
      </div>

      <div className="health-grid">
        <div className="health-section">
          <div className="health-section-header">HTTP Access Points</div>
          {http.map(s => (
            <StatusRow key={s.name} name={s.label || s.name}
              detail={s.ok ? `${s.code} · ${s.latency}ms · ${s.url}` : (s.detail || `${s.code} timeout`)}
              ok={s.ok} fix={s.fix} category="http" />
          ))}
        </div>

        <div className="health-section">
          <div className="health-section-header">Runtime Tools</div>
          {runtimes.map(r => (
            <StatusRow key={r.name} name={r.name} detail={r.detail} ok={r.ok} fix={r.fix} category="tool" />
          ))}

          <div className="health-section-header-alt">Watchdog</div>
          {watchdog.map((w, i) => (
            <StatusRow key={i} name={w.name} detail={w.pid ? `PID ${w.pid}` : ''} ok={w.ok} fix={w.fix} category="watchdog" />
          ))}

          <div className="health-section-header-alt">tmux Sessions</div>
          {tmux.map((t, i) => (
            <StatusRow key={i} name={t.name} detail={t.detail} ok={t.ok} fix={t.fix} category="tmux" />
          ))}
        </div>
      </div>

      <div className="health-footer">
        probed {new Date(data.checked_at).toLocaleTimeString('th-TH')} · ⚡ Fix triggers AI agent diagnostic
      </div>
    </div>
  )
})

function CommandRunnerPanel() {
  const [selectedCommandId, setSelectedCommandId] = useState<CommandId>(COMMAND_OPTIONS[0]?.id ?? 'git-status')
  const [runningCommandId, setRunningCommandId] = useState<CommandId | null>(null)
  const [result, setResult] = useState<CommandRunResult | null>(null)

  const selectedCommand = COMMAND_OPTIONS.find(option => option.id === selectedCommandId) ?? COMMAND_OPTIONS[0]

  async function runSelectedCommand(commandId: CommandId = selectedCommandId) {
    setRunningCommandId(commandId)
    try {
      const res = await fetch('/api/exec', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        cache: 'no-store',
        body: JSON.stringify({ commandId }),
      })
      const json = await res.json()
      setResult(json)
    } catch (e) {
      setResult({
        commandId,
        executable: '',
        args: [],
        cwd: '',
        stdout: '',
        stderr: String(e),
        exitCode: null,
        signal: null,
        durationMs: 0,
        checked_at: new Date().toISOString(),
        ok: false,
        error: String(e),
      })
    } finally {
      setRunningCommandId(null)
    }
  }

  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
        <span className="badge badge-blue">{COMMAND_OPTIONS.length} allowlisted commands</span>
        <span className="badge badge-green">safe exec-file runner</span>
        <span className="badge badge-yellow">no raw shell strings</span>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.5fr) minmax(280px, 1fr)', gap: 16 }}>
        <div style={{
          background: 'var(--bg-card)',
          border: '1px solid var(--border)',
          borderRadius: 12,
          padding: 16,
        }}>
          <div style={{ marginBottom: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10 }}>
            <div>
              <div style={{ color: 'var(--text-primary)', fontSize: 14, fontWeight: 700 }}>Run command</div>
              <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>{selectedCommand?.description}</div>
            </div>
            <button
              onClick={() => runSelectedCommand()}
              disabled={!!runningCommandId}
              style={{
                padding: '7px 12px',
                borderRadius: 8,
                border: '1px solid var(--accent)',
                background: runningCommandId ? 'rgba(99,102,241,0.18)' : 'transparent',
                color: runningCommandId ? 'var(--text-muted)' : 'var(--accent)',
                cursor: runningCommandId ? 'not-allowed' : 'pointer',
                fontSize: 12,
                fontFamily: 'inherit',
                fontWeight: 600,
              }}
            >
              {runningCommandId ? '⟳ running…' : '▶ Run'}
            </button>
          </div>

          <label style={{ display: 'block', marginBottom: 10 }}>
            <div style={{ color: 'var(--text-muted)', fontSize: 10, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
              Allowlisted command
            </div>
            <select
              value={selectedCommandId}
              onChange={e => setSelectedCommandId(e.target.value as CommandId)}
              style={{
                width: '100%',
                padding: '12px 14px',
                borderRadius: 10,
                border: '1px solid var(--border)',
                background: 'var(--bg-card)',
                color: 'var(--text-primary)',
                fontSize: 14,
              }}
            >
              {COMMAND_OPTIONS.map(option => (
                <option key={option.id} value={option.id}>
                  {option.label} — {option.description}
                </option>
              ))}
            </select>
          </label>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {COMMAND_OPTIONS.map(option => (
              <button
                key={option.id}
                onClick={() => setSelectedCommandId(option.id)}
                style={{
                  padding: '6px 10px',
                  borderRadius: 999,
                  border: option.id === selectedCommandId ? '1px solid var(--accent)' : '1px solid var(--border)',
                  background: option.id === selectedCommandId ? 'rgba(99,102,241,0.14)' : 'transparent',
                  color: option.id === selectedCommandId ? 'var(--accent)' : 'var(--text-secondary)',
                  cursor: 'pointer',
                  fontSize: 11,
                  fontWeight: 600,
                }}
              >
                {option.label}
              </button>
            ))}
          </div>

          <div style={{ marginTop: 12, color: 'var(--text-muted)', fontSize: 11, lineHeight: 1.5 }}>
            This runner only executes allowlisted commands defined server-side. It will not run arbitrary shell text.
          </div>
        </div>

        <div style={{
          background: 'var(--bg-card)',
          border: '1px solid var(--border)',
          borderRadius: 12,
          padding: 16,
        }}>
          <div style={{ color: 'var(--text-primary)', fontSize: 14, fontWeight: 700, marginBottom: 10 }}>Last result</div>
          {result ? (
            <div style={{ display: 'grid', gap: 10 }}>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                <span className={`badge ${result.ok ? 'badge-green' : 'badge-red'}`}>
                  {result.ok ? '✓ success' : `✕ exit ${result.exitCode ?? 'n/a'}`}
                </span>
                <span className="badge badge-blue">{result.commandId}</span>
                <span className="badge badge-yellow">{result.durationMs}ms</span>
              </div>
              <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>
                {result.executable} {result.args.join(' ')}
              </div>
              <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>
                cwd: {result.cwd || '—'}
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: 10, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.08em' }}>stdout</div>
                <pre style={{
                  margin: 0,
                  padding: 12,
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-sub)',
                  borderRadius: 8,
                  whiteSpace: 'pre-wrap',
                  wordBreak: 'break-word',
                  color: 'var(--text-primary)',
                  fontSize: 11,
                  lineHeight: 1.6,
                  minHeight: 72,
                }}>{result.stdout || '—'}</pre>
              </div>
              <div>
                <div style={{ color: 'var(--text-muted)', fontSize: 10, marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.08em' }}>stderr</div>
                <pre style={{
                  margin: 0,
                  padding: 12,
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-sub)',
                  borderRadius: 8,
                  whiteSpace: 'pre-wrap',
                  wordBreak: 'break-word',
                  color: 'var(--danger)',
                  fontSize: 11,
                  lineHeight: 1.6,
                  minHeight: 56,
                }}>{result.stderr || '—'}</pre>
              </div>
              {result.error && (
                <div style={{ color: 'var(--warning)', fontSize: 11 }}>
                  error: {result.error}
                </div>
              )}
              <div style={{ color: 'var(--text-muted)', fontSize: 10 }}>
                checked {new Date(result.checked_at).toLocaleTimeString('th-TH')}
              </div>
            </div>
          ) : (
            <div style={{ color: 'var(--text-muted)', fontSize: 11, lineHeight: 1.5 }}>
              Pick a command and click Run to execute it on the server.
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

const COLUMN_CONFIG = [

  { key: 'inbox',   label: 'Inbox',   color: 'var(--accent)',    icon: '📥' },
  { key: 'active',  label: 'Active',  color: 'var(--warning)',   icon: '⚡' },
  { key: 'outbox',  label: 'Outbox',  color: 'var(--success)',   icon: '📤' },
  { key: 'proofs',  label: 'Proofs',  color: 'var(--info)',      icon: '✅' },
  { key: 'archive', label: 'Archive', color: 'var(--text-muted)', icon: '📦' },
]

const TaskBoardPanel = memo(function TaskBoardPanel({ data }: { data: TasksData | null }) {
  if (!data) return <div className="panel-content">loading tasks…</div>
  return (
    <div>
      <div className="task-board-stats">
        <span className="badge badge-blue">{data.total} total tasks</span>
        <span className="badge badge-yellow">{data.columns.active.length} in progress</span>
        <span className="badge badge-green">{data.columns.proofs.length} proven</span>
      </div>
      <div className="task-board-grid">
        {COLUMN_CONFIG.map(col => {
          const tasks = (data.columns as Record<string, Task[]>)[col.key] ?? []
          return (
            <div key={col.key} className="task-column">
              <div className="task-column-header" style={{ borderBottom: `2px solid ${col.color}` }}>
                <span className="task-column-title" style={{ color: col.color }}>
                  {col.icon} {col.label}
                </span>
                <span className="task-column-count" style={{
                  background: `color-mix(in srgb, ${col.color} 13%, transparent)`,
                  color: col.color,
                }}>
                  {tasks.length}
                </span>
              </div>
              <div className="task-column-body">
                {tasks.slice(0, 8).map(t => (
                  <div key={t.id} className="task-card">
                    <div className="task-card-name">
                      {t.name.slice(0, 30)}{t.name.length > 30 ? '…' : ''}
                    </div>
                    <div className="task-card-meta">
                      <span>{t.type}</span>
                      <span>{fmtTime(t.mtime)}</span>
                    </div>
                  </div>
                ))}
                {tasks.length === 0 && (
                  <div className="task-column-empty">empty</div>
                )}
                {tasks.length > 8 && (
                  <div className="task-column-more">
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
})

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
            <th>account</th>
            <th>type</th>
            <th>model</th>
            <th>status</th>
            <th>latency</th>
            <th>quota limit</th>
            <th>reset</th>
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
                <td style={{ fontSize: 10, color: 'var(--text-secondary)' }}>{q?.accountLabel ?? '—'}</td>
                <td><span className="badge badge-gray" style={{ fontSize: 10 }}>{p.type}</span></td>
                <td style={{ fontSize: 11, color: 'var(--text-secondary)' }}>{p.model}</td>
                <td><ProviderStatusBadge status={p.status} /></td>
                <td style={{ color: 'var(--text-muted)', fontSize: 11 }}>
                  {p.latencyMs != null ? `${p.latencyMs}ms` : '—'}
                </td>
                <td style={{ fontSize: 11 }}>
                  {q?.limit != null ? q.limit.toLocaleString() : 'unknown'}
                </td>
                <td style={{ fontSize: 10, color: 'var(--text-secondary)' }}>{q?.resetInText ?? '—'}</td>
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
            <tr><td colSpan={10} style={{ color: 'var(--text-muted)', textAlign: 'center', padding: 16 }}>
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
            <th>account</th>
            <th>event</th>
            <th>code</th>
            <th>model</th>
            <th>endpoint</th>
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
              <td style={{ fontSize: 10, color: 'var(--text-secondary)' }}>{a.accountLabel || '—'}</td>
              <td style={{ fontSize: 11 }}>
                {eventIcons[a.eventType] ?? '•'} {a.eventType.replace(/_/g, ' ')}
              </td>
              <td>
                {a.statusCode
                  ? <span className="hash" style={a.statusCode >= 400 ? { color: 'var(--danger)' } : undefined}>{a.statusCode}</span>
                  : <span style={{ color: 'var(--text-muted)' }}>—</span>
                }
              </td>
              <td style={{ fontSize: 10, color: 'var(--text-secondary)' }}>{a.model?.split('/').pop() ?? '—'}</td>
              <td style={{ fontSize: 10, color: 'var(--text-secondary)', maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.endpoint || '—'}</td>
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
            <tr><td colSpan={10} style={{ color: 'var(--text-muted)', textAlign: 'center', padding: 16 }}>
              No activity events{sevFilter !== 'all' ? ` with severity: ${sevFilter}` : ''}
            </td></tr>
          )}
        </tbody>
      </table>
    </div>
  )
}

// ── Omega / Oracle Bridge Panel ────────────────────────────────────────────
interface ObsidianBridgeNote {
  key: string
  title: string
  path: string
  exists: boolean
  mtime: string
  sizeKB: number
  preview: string[]
}

interface ObsidianBridgeData {
  vaultPath: string
  wikiReady: boolean
  bridgeReady: boolean
  notes: ObsidianBridgeNote[]
  hotHighlights: string[]
  logHighlights: string[]
  error?: string
}

function ERPReferencePanel({ refreshTick }: { refreshTick: number }) {
  const [data, setData] = useState<ObsidianBridgeData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let alive = true
    setLoading(true)
    setError('')
    fetch('/api/obsidian', { cache: 'no-store' })
      .then(r => r.json())
      .then((json: ObsidianBridgeData) => {
        if (!alive) return
        if (json?.error) {
          setError(json.error)
        }
        setData(json)
      })
      .catch((e) => {
        if (alive) setError(String(e))
      })
      .finally(() => {
        if (alive) setLoading(false)
      })
    return () => { alive = false }
  }, [refreshTick])

  if (loading && !data) return <div style={{ color: 'var(--text-muted)' }}>loading Obsidian bridge…</div>

  const bridge = data ?? {
    vaultPath: '—',
    wikiReady: false,
    bridgeReady: false,
    notes: [],
    hotHighlights: [],
    logHighlights: [],
  }

  return (
    <div style={{ display: 'grid', gap: 16 }}>
      {error && (
        <div className="badge badge-red" style={{ borderRadius: 12, padding: '8px 12px', justifyContent: 'flex-start', whiteSpace: 'normal', lineHeight: 1.4 }}>
          ⚠ Obsidian bridge error: {error}
        </div>
      )}
      <div className="card" style={{ background: 'linear-gradient(180deg, rgba(15, 20, 28, 0.98), rgba(10, 14, 20, 0.98))', borderColor: 'rgba(60, 73, 95, 0.9)' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.2fr) minmax(260px, 0.8fr)', gap: 16, alignItems: 'start' }}>
          <div>
            <div className="card-header" style={{ marginBottom: 10 }}>
              <span className="dot" style={{ background: 'var(--accent2)' }} />
              Omega / Oracle Bridge — Obsidian wiki
            </div>
            <div style={{ fontSize: 28, fontWeight: 700, color: 'var(--text-primary)', lineHeight: 1.1 }}>Live bridge into the Obsidian vault</div>
            <div style={{ marginTop: 8, color: 'var(--text-secondary)', maxWidth: 820 }}>
              This panel reads the wiki home, index, hot cache, and log so Omega and Oracle can reason from the same durable notes.
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
              <span className="badge badge-blue">📁 {bridge.vaultPath}</span>
              <span className={bridge.wikiReady ? 'badge badge-green' : 'badge badge-red'}>
                {bridge.wikiReady ? '✓ wiki ready' : '✕ wiki missing'}
              </span>
              <span className={bridge.bridgeReady ? 'badge badge-green' : 'badge badge-yellow'}>
                {bridge.bridgeReady ? '✓ bridge ready' : '⚠ bridge warming'}
              </span>
            </div>
          </div>
          <div className="constitution-card" style={{ background: 'linear-gradient(180deg, rgba(17, 24, 35, 0.98), rgba(11, 16, 23, 0.98))' }}>
            <div style={{ color: 'var(--text-primary)', fontWeight: 700, marginBottom: 8 }}>Bridge checklist</div>
            <div style={{ display: 'grid', gap: 8, color: 'var(--text-secondary)', fontSize: 12 }}>
              <div>✓ Read `wiki/home.md` and `wiki/index.md` first</div>
              <div>✓ Keep `wiki/hot.md` short and current</div>
              <div>✓ Treat `wiki/log.md` as append-only</div>
              <div>✓ Use the same notes for Omega and Oracle reasoning</div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 12 }}>
        <div className="card" style={{ background: 'linear-gradient(180deg, rgba(15, 20, 28, 0.98), rgba(10, 14, 20, 0.98))' }}>
          <div className="card-header" style={{ marginBottom: 10 }}><span className="dot" style={{ background: 'var(--info)' }} />Wiki notes</div>
          <div style={{ display: 'grid', gap: 8 }}>
            {bridge.notes.map(note => (
              <div key={note.key} className="oracle-card" style={{ borderColor: note.exists ? 'rgba(53, 66, 90, 0.9)' : 'rgba(168, 85, 247, 0.45)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 10, alignItems: 'baseline' }}>
                  <div style={{ color: 'var(--text-primary)', fontWeight: 700 }}>{note.title}</div>
                  <span className={`badge ${note.exists ? 'badge-green' : 'badge-yellow'}`}>{note.exists ? 'present' : 'missing'}</span>
                </div>
                <div style={{ color: 'var(--text-muted)', fontSize: 10, marginTop: 4, wordBreak: 'break-all' }}>{note.path}</div>
                {note.exists && (
                  <div style={{ marginTop: 6, display: 'flex', gap: 8, flexWrap: 'wrap', color: 'var(--text-muted)', fontSize: 10 }}>
                    <span>{fmtTime(note.mtime)}</span>
                    <span>{note.sizeKB}KB</span>
                  </div>
                )}
                {note.preview.length > 0 && (
                  <div style={{ marginTop: 8, color: 'var(--text-secondary)', fontSize: 11, lineHeight: 1.5 }}>
                    {note.preview.slice(0, 3).map((line, idx) => <div key={idx}>• {line}</div>)}
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        <div style={{ display: 'grid', gap: 12 }}>
          <div className="card" style={{ background: 'linear-gradient(180deg, rgba(15, 20, 28, 0.98), rgba(10, 14, 20, 0.98))' }}>
            <div className="card-header" style={{ marginBottom: 10 }}><span className="dot" style={{ background: 'var(--success)' }} />Hot cache</div>
            <div style={{ display: 'grid', gap: 6, color: 'var(--text-secondary)', fontSize: 12, lineHeight: 1.55 }}>
              {bridge.hotHighlights.length === 0 ? (
                <div style={{ color: 'var(--text-muted)' }}>no highlights yet</div>
              ) : bridge.hotHighlights.map((line, idx) => <div key={idx}>• {line}</div>)}
            </div>
          </div>

          <div className="card" style={{ background: 'linear-gradient(180deg, rgba(15, 20, 28, 0.98), rgba(10, 14, 20, 0.98))' }}>
            <div className="card-header" style={{ marginBottom: 10 }}><span className="dot" style={{ background: 'var(--warning)' }} />Recent log</div>
            <div style={{ display: 'grid', gap: 6, color: 'var(--text-secondary)', fontSize: 12, lineHeight: 1.55 }}>
              {bridge.logHighlights.length === 0 ? (
                <div style={{ color: 'var(--text-muted)' }}>no log entries yet</div>
              ) : bridge.logHighlights.map((line, idx) => <div key={idx}>• {line}</div>)}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// ── TmuxChatPanel ──────────────────────────────────────────────────────────
interface TmuxPane {
  target: string
  session: string
  window: string
  paneIndex: string
  cmd: string
  title: string
  active: boolean
}
interface ChatMessage {
  id: number
  type: 'cmd' | 'out' | 'err' | 'sys'
  text: string
  target?: string
  ts: number
}

function TmuxChatPanel() {
  const [panes, setPanes]         = useState<TmuxPane[]>([])
  const [target, setTarget]       = useState('')
  const [selectedSession, setSelectedSession] = useState('all')
  const [outputMode, setOutputMode] = useState<'delta' | 'full'>('delta')
  const [messages, setMessages]   = useState<ChatMessage[]>([])
  const [input, setInput]         = useState('')
  const [sending, setSending]     = useState(false)
  const [liveCapture, setLiveCapture] = useState(false)
  const [liveOutput, setLiveOutput]   = useState('')
  const [lastCaptureAt, setLastCaptureAt] = useState('')
  const chatEndRef = useRef<HTMLDivElement>(null)
  const inputRef   = useRef<HTMLInputElement>(null)
  const msgId      = useRef(0)
  const liveInterval = useRef<ReturnType<typeof setInterval> | null>(null)

  useEffect(() => {
    try {
      const savedTarget = window.localStorage.getItem('tmux-chat-target')
      const savedSession = window.localStorage.getItem('tmux-chat-session')
      const savedMode = window.localStorage.getItem('tmux-chat-output-mode')
      if (savedTarget) setTarget(savedTarget)
      if (savedSession) setSelectedSession(savedSession)
      if (savedMode === 'delta' || savedMode === 'full') setOutputMode(savedMode)
    } catch { /* ignore */ }
  }, [])

  useEffect(() => {
    try { window.localStorage.setItem('tmux-chat-target', target) } catch { /* ignore */ }
  }, [target])

  useEffect(() => {
    try { window.localStorage.setItem('tmux-chat-session', selectedSession) } catch { /* ignore */ }
  }, [selectedSession])

  useEffect(() => {
    try { window.localStorage.setItem('tmux-chat-output-mode', outputMode) } catch { /* ignore */ }
  }, [outputMode])

  function addMsg(type: ChatMessage['type'], text: string, tgt?: string) {
    const msg: ChatMessage = { id: ++msgId.current, type, text, target: tgt, ts: Date.now() }
    setMessages(m => [...m, msg])
    return msg
  }

  async function loadPanes() {
    try {
      const r = await fetch('/api/tmux', { cache: 'no-store' })
      const d = await r.json()
      const list: TmuxPane[] = d.panes ?? []
      setPanes(list)
      if (selectedSession !== 'all' && list.every(p => p.session !== selectedSession)) {
        setSelectedSession('all')
      }
      if (list.length > 0) {
        const current = target ? list.find(p => p.target === target) : null
        const active = current ?? list.find(p => p.active) ?? list[0]
        if (!current) setTarget(active.target)
        if (selectedSession === 'all' || !list.some(p => p.session === selectedSession)) {
          setSelectedSession(active.session)
        }
      }
    } catch {
      addMsg('err', 'tmux not available or no sessions running')
    }
  }

  async function captureNow(tgt: string) {
    if (!tgt) return
    try {
      const r = await fetch(`/api/tmux?target=${encodeURIComponent(tgt)}&action=capture&lines=80`, { cache: 'no-store' })
      const d = await r.json()
      setLiveOutput(d.output ?? '')
      setLastCaptureAt(d.captured_at ?? '')
    } catch { /* ignore */ }
  }

  useEffect(() => { void loadPanes() }, [])

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  useEffect(() => {
    if (liveInterval.current) clearInterval(liveInterval.current)
    if (liveCapture && target) {
      void captureNow(target)
      liveInterval.current = setInterval(() => void captureNow(target), 1200)
    } else {
      setLiveOutput('')
    }
    return () => { if (liveInterval.current) clearInterval(liveInterval.current) }
  }, [liveCapture, target])

  useEffect(() => {
    if (target && !liveCapture) {
      void captureNow(target)
    }
  }, [target])

  async function sendCmd() {
    const cmd = input.trim()
    if (!cmd || !target || sending) return
    setInput('')
    setSending(true)
    addMsg('cmd', cmd, target)

    try {
      const r = await fetch('/api/tmux', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        cache: 'no-store',
        body: JSON.stringify({ target, cmd, delayMs: 700 }),
      })
      const d = await r.json()
      if (d.error) {
        addMsg('err', d.error, target)
      } else {
        const out = (outputMode === 'full' ? (d.full_output ?? d.output ?? '') : (d.delta ?? d.output ?? '')).trim()
        addMsg('out', out || '(no output)', target)
        if (liveCapture) setLiveOutput(d.full_output ?? d.output ?? '')
        if (d.sent_at) setLastCaptureAt(d.sent_at)
      }
    } catch (e) {
      addMsg('err', String(e), target)
    } finally {
      setSending(false)
      inputRef.current?.focus()
    }
  }

  const termBg   = '#0d1117'
  const termText = '#c9d1d9'
  const accentGreen = '#3fb950'
  const accentBlue  = '#58a6ff'
  const accentRed   = '#f85149'
  const accentYellow = '#d29922'
  const sessionNames = Array.from(new Set(panes.map(p => p.session))).sort()
  const visiblePanes = selectedSession === 'all' ? panes : panes.filter(p => p.session === selectedSession)
  const selectedPane = panes.find(p => p.target === target)
  const quickPanes = panes.filter(p => p.active || p.session === selectedPane?.session).slice(0, 6)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {/* Top bar */}
      <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
        <span className="badge badge-blue">{panes.length} panes</span>
        <span className="badge" style={{ background: liveCapture ? 'rgba(63,185,80,0.15)' : 'rgba(99,102,241,0.1)', color: liveCapture ? accentGreen : 'var(--text-muted)', border: `1px solid ${liveCapture ? accentGreen : 'var(--border)'}` }}>
          {liveCapture ? '⬤ live' : '○ live off'}
        </span>
        <span className="badge" style={{ background: outputMode === 'delta' ? 'rgba(63,185,80,0.1)' : 'rgba(88,166,255,0.1)', color: outputMode === 'delta' ? accentGreen : accentBlue, border: `1px solid ${outputMode === 'delta' ? accentGreen : accentBlue}44` }}>
          reply mode: {outputMode}
        </span>
        {selectedPane && (
          <span className="badge" style={{ background: 'rgba(88,166,255,0.1)', color: accentBlue, border: `1px solid ${accentBlue}44` }}>
            {selectedPane.session} / {selectedPane.window}.{selectedPane.paneIndex}
          </span>
        )}
        {lastCaptureAt && (
          <span className="badge" style={{ background: 'rgba(210,153,34,0.1)', color: accentYellow, border: `1px solid ${accentYellow}44` }}>
            captured {new Date(lastCaptureAt).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
          </span>
        )}
        <button
          onClick={() => void loadPanes()}
          style={{ padding: '4px 10px', borderRadius: 6, border: '1px solid var(--border)', background: 'transparent', color: 'var(--text-muted)', fontSize: 11, cursor: 'pointer', fontFamily: 'inherit' }}
        >⟳ refresh</button>
        <button
          onClick={() => setLiveCapture(l => !l)}
          style={{ padding: '4px 10px', borderRadius: 6, border: `1px solid ${liveCapture ? accentGreen : 'var(--border)'}`, background: liveCapture ? 'rgba(63,185,80,0.1)' : 'transparent', color: liveCapture ? accentGreen : 'var(--text-muted)', fontSize: 11, cursor: 'pointer', fontFamily: 'inherit' }}
        >{liveCapture ? '⬛ stop live' : '▶ live capture'}</button>
        <button
          onClick={() => setMessages([])}
          style={{ padding: '4px 10px', borderRadius: 6, border: '1px solid var(--border)', background: 'transparent', color: 'var(--text-muted)', fontSize: 11, cursor: 'pointer', fontFamily: 'inherit' }}
        >✕ clear chat</button>
        <button
          onClick={() => setOutputMode(m => m === 'delta' ? 'full' : 'delta')}
          style={{ padding: '4px 10px', borderRadius: 6, border: `1px solid ${outputMode === 'delta' ? accentGreen : accentBlue}`, background: 'transparent', color: outputMode === 'delta' ? accentGreen : accentBlue, fontSize: 11, cursor: 'pointer', fontFamily: 'inherit' }}
        >⇆ {outputMode === 'delta' ? 'switch to full reply' : 'switch to delta reply'}</button>
      </div>

      {quickPanes.length > 0 && (
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {quickPanes.map(p => (
            <button
              key={`quick-${p.target}`}
              onClick={() => {
                setTarget(p.target)
                setSelectedSession(p.session)
                void captureNow(p.target)
                inputRef.current?.focus()
              }}
              style={{
                padding: '4px 10px',
                borderRadius: 999,
                border: `1px solid ${p.target === target ? accentBlue : 'var(--border)'}`,
                background: p.target === target ? 'rgba(88,166,255,0.1)' : 'transparent',
                color: p.target === target ? accentBlue : 'var(--text-muted)',
                fontSize: 11,
                cursor: 'pointer',
                fontFamily: 'inherit',
              }}
            >
              {p.session}:{p.window}.{p.paneIndex}
            </button>
          ))}
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1fr) 220px', gap: 12, alignItems: 'start' }}>
        {/* Left: chat + live view */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>

          {/* Live pane view */}
          {liveCapture && (
            <div style={{ borderRadius: 10, overflow: 'hidden', border: `1px solid ${accentGreen}44` }}>
              <div style={{ background: '#161b22', padding: '6px 12px', fontSize: 10, color: accentGreen, display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ display: 'inline-block', width: 7, height: 7, borderRadius: '50%', background: accentGreen, boxShadow: `0 0 6px ${accentGreen}` }} />
                live — {target}
              </div>
              <pre style={{
                margin: 0,
                padding: 12,
                background: termBg,
                color: termText,
                fontSize: 11,
                lineHeight: 1.55,
                fontFamily: '"JetBrains Mono", "Fira Code", "Cascadia Code", Consolas, monospace',
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
                maxHeight: 320,
                overflowY: 'auto',
              }}>{liveOutput || 'waiting for output…'}</pre>
            </div>
          )}

          {/* Chat history */}
          <div style={{
            background: termBg,
            border: '1px solid var(--border)',
            borderRadius: 10,
            padding: 14,
            minHeight: 320,
            maxHeight: 420,
            overflowY: 'auto',
            fontFamily: '"JetBrains Mono", "Fira Code", Consolas, monospace',
            fontSize: 12,
            lineHeight: 1.6,
          }}>
            {messages.length === 0 ? (
              <div style={{ color: '#484f58', userSelect: 'none' }}>
                <div style={{ marginBottom: 8 }}>Select a pane on the right. The reply area shows only the new output delta instead of the full pane history.</div>
                <div>$ _</div>
              </div>
            ) : (
              messages.map(m => (
                <div key={m.id} style={{ marginBottom: 10 }}>
                  {m.type === 'cmd' && (
                    <div style={{ color: accentGreen, display: 'flex', gap: 8, alignItems: 'baseline' }}>
                      <span style={{ color: '#484f58', fontSize: 10, flexShrink: 0 }}>
                        [{new Date(m.ts).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}]
                      </span>
                      <span style={{ color: '#58a6ff', flexShrink: 0 }}>{m.target}</span>
                      <span style={{ color: accentGreen }}>$ {m.text}</span>
                    </div>
                  )}
                  {m.type === 'out' && (
                    <pre style={{
                      margin: '2px 0 0 0',
                      padding: '8px 10px',
                      background: '#161b22',
                      borderLeft: `2px solid #30363d`,
                      borderRadius: '0 6px 6px 0',
                      color: termText,
                      fontSize: 11,
                      lineHeight: 1.55,
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                      maxHeight: 300,
                      overflowY: 'auto',
                    }}>{m.text}</pre>
                  )}
                  {m.type === 'err' && (
                    <div style={{ color: accentRed, fontSize: 11, paddingLeft: 10 }}>⚠ {m.text}</div>
                  )}
                  {m.type === 'sys' && (
                    <div style={{ color: accentYellow, fontSize: 11, paddingLeft: 10 }}>ℹ {m.text}</div>
                  )}
                </div>
              ))
            )}
            <div ref={chatEndRef} />
          </div>

          {/* Input */}
          <div style={{
            display: 'flex',
            gap: 8,
            background: termBg,
            border: `1px solid ${sending ? accentGreen + '66' : 'var(--border)'}`,
            borderRadius: 10,
            padding: '8px 12px',
            alignItems: 'center',
            transition: 'border-color 0.15s',
          }}>
            <span style={{ color: accentGreen, fontSize: 13, fontFamily: 'monospace', flexShrink: 0 }}>
              {target ? `${target} $` : '$'}
            </span>
            <input
              ref={inputRef}
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); void sendCmd() } }}
              placeholder={target ? 'type command and press Enter…' : 'select a pane first'}
              disabled={!target || sending}
              style={{
                flex: 1,
                background: 'transparent',
                border: 'none',
                outline: 'none',
                color: termText,
                fontSize: 13,
                fontFamily: '"JetBrains Mono", "Fira Code", Consolas, monospace',
                lineHeight: 1.4,
              }}
            />
            <button
              onClick={() => void sendCmd()}
              disabled={!target || !input.trim() || sending}
              style={{
                padding: '4px 12px',
                borderRadius: 6,
                border: `1px solid ${target && input.trim() && !sending ? accentGreen : '#30363d'}`,
                background: target && input.trim() && !sending ? 'rgba(63,185,80,0.12)' : 'transparent',
                color: target && input.trim() && !sending ? accentGreen : '#484f58',
                fontSize: 12,
                cursor: target && input.trim() && !sending ? 'pointer' : 'not-allowed',
                fontFamily: 'monospace',
                transition: 'all 0.15s',
                flexShrink: 0,
              }}
            >{sending ? '⟳' : '↵ Send'}</button>
          </div>
        </div>

        {/* Right: pane list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div style={{ color: 'var(--text-muted)', fontSize: 10, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 4 }}>
            tmux panes
          </div>
          {sessionNames.length > 0 && (
            <select
              value={selectedSession}
              onChange={e => setSelectedSession(e.target.value)}
              style={{
                padding: '8px 10px',
                borderRadius: 8,
                border: '1px solid var(--border)',
                background: 'var(--bg-card)',
                color: 'var(--text-secondary)',
                fontSize: 11,
                fontFamily: '"JetBrains Mono", Consolas, monospace',
              }}
            >
              <option value="all">all sessions ({panes.length})</option>
              {sessionNames.map(name => {
                const count = panes.filter(p => p.session === name).length
                return <option key={name} value={name}>{name} ({count})</option>
              })}
            </select>
          )}
          {visiblePanes.length === 0 ? (
            <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>
              No tmux sessions.<br />Start one with: tmux new -s tham
            </div>
          ) : (
            visiblePanes.map(p => (
              <button
                key={p.target}
                onClick={() => {
                  setTarget(p.target)
                  void captureNow(p.target)
                  inputRef.current?.focus()
                }}
                style={{
                  padding: '8px 10px',
                  borderRadius: 8,
                  border: `1px solid ${p.target === target ? accentBlue : 'var(--border)'}`,
                  background: p.target === target ? 'rgba(88,166,255,0.1)' : 'var(--bg-card)',
                  color: p.target === target ? accentBlue : 'var(--text-secondary)',
                  textAlign: 'left',
                  cursor: 'pointer',
                  fontSize: 11,
                  lineHeight: 1.5,
                  fontFamily: '"JetBrains Mono", Consolas, monospace',
                  transition: 'all 0.12s',
                }}
              >
                <div style={{ fontWeight: 700, fontSize: 11, marginBottom: 2 }}>
                  {p.active && <span style={{ color: accentGreen, marginRight: 4 }}>⬤</span>}
                  {p.session}
                </div>
                <div style={{ color: 'var(--text-muted)', fontSize: 10 }}>
                  {p.window}.{p.paneIndex} — {p.cmd}
                </div>
                {p.title && <div style={{ color: 'var(--text-muted)', fontSize: 9, marginTop: 2, opacity: 0.7 }}>{p.title.slice(0, 28)}</div>}
              </button>
            ))
          )}
          {panes.length > 0 && (
            <button
              onClick={() => target && void captureNow(target).then(() => addMsg('sys', `captured pane: ${target}`))}
              disabled={!target}
              style={{
                marginTop: 6,
                padding: '6px 10px',
                borderRadius: 8,
                border: '1px solid var(--border)',
                background: 'transparent',
                color: 'var(--text-muted)',
                fontSize: 11,
                cursor: target ? 'pointer' : 'not-allowed',
                fontFamily: 'inherit',
              }}
            >📷 snapshot pane</button>
          )}
        </div>
      </div>
    </div>
  )
}

const MemoCommandRunnerPanel = memo(CommandRunnerPanel)
const MemoTmuxChatPanel = memo(TmuxChatPanel)
const MemoQuotaTrackerPanel = memo(QuotaTrackerPanel)
const MemoProviderActivityPanel = memo(ProviderActivityPanel)

// ── Command Control Section (tab wrapper) ──────────────────────────────────
function CommandControlSection() {
  const [tab, setTab] = useState<'runner' | 'tmux'>('runner')
  const tabStyle = (active: boolean): React.CSSProperties => ({
    padding: '6px 16px',
    borderRadius: '8px 8px 0 0',
    border: `1px solid ${active ? 'var(--border)' : 'transparent'}`,
    borderBottom: active ? '1px solid var(--bg-card)' : '1px solid var(--border)',
    background: active ? 'var(--bg-card)' : 'transparent',
    color: active ? 'var(--text-primary)' : 'var(--text-muted)',
    cursor: 'pointer',
    fontSize: 12,
    fontWeight: active ? 700 : 400,
    fontFamily: 'inherit',
    marginBottom: -1,
    transition: 'all 0.12s',
  })
  return (
    <div className="card" style={{ paddingTop: 0 }}>
      <div style={{ display: 'flex', gap: 0, borderBottom: '1px solid var(--border)', marginBottom: 16, paddingTop: 16 }}>
        <button style={tabStyle(tab === 'runner')} onClick={() => setTab('runner')}>⌘ Command Runner</button>
        <button style={tabStyle(tab === 'tmux')}   onClick={() => setTab('tmux')}>⬛ tmux Terminal</button>
      </div>
      {tab === 'runner' && <MemoCommandRunnerPanel />}
      {tab === 'tmux'   && <MemoTmuxChatPanel />}
    </div>
  )
}

// ── Main Page ──────────────────────────────────────────────────────────────
export default function Dashboard() {
  const [activeSection, setActiveSection] = useState<Section>('fleet')
  const [isPending, startTransition] = useTransition()
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
  const [erpRefreshTick, setErpRefreshTick] = useState(0)
  const refreshSeqRef = useRef(0)
  const loadedSectionsRef = useRef<Record<Section, boolean>>({
    commands: false,
    fleet: false,
    tasks: false,
    health: false,
    git: false,
    memory: false,
    queue: false,
    services: false,
    constitution: false,
    metrics: false,
    providers: false,
    'provider-activity': false,
    erp: false,
  })

  const refreshCore = useCallback(async () => {
    const refreshSeq = ++refreshSeqRef.current
    setRefreshing(true)

    const [fleetData, gitData, servicesData, providersData] = await Promise.all([
      fetch('/api/fleet', { cache: 'no-store' }).then(r => r.json()).catch(() => null),
      fetch('/api/git', { cache: 'no-store' }).then(r => r.json()).catch(() => null),
      fetch('/api/services', { cache: 'no-store' }).then(r => r.json()).catch(() => null),
      fetch('/api/forge-omega/providers/status', { cache: 'no-store' }).then(r => r.json()).catch(() => null),
    ])

    if (refreshSeq !== refreshSeqRef.current) return

    startTransition(() => {
      if (fleetData) setFleet(fleetData)
      if (gitData) setGit(gitData)
      if (servicesData) setServices(servicesData)
      if (providersData) setProviders(providersData)
    })

    loadedSectionsRef.current.fleet = true
    loadedSectionsRef.current.git = true
    loadedSectionsRef.current.services = true
    loadedSectionsRef.current.providers = true
    loadedSectionsRef.current['provider-activity'] = true
    setLastRefresh(new Date().toLocaleTimeString('th-TH'))
    setRefreshing(false)
  }, [startTransition])

  const loadSectionData = useCallback(async (section: Section, force = false) => {
    if (!force && loadedSectionsRef.current[section]) return

    const markLoaded = (...sections: Section[]) => {
      sections.forEach(s => { loadedSectionsRef.current[s] = true })
    }

    switch (section) {
      case 'fleet':
        loadedSectionsRef.current.fleet = true
        return
      case 'git': {
        const data = await fetch('/api/git', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setGit(data))
        markLoaded('git')
        return
      }
      case 'memory': {
        const data = await fetch('/api/memory', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setMem(data))
        markLoaded('memory')
        return
      }
      case 'metrics': {
        const data = await fetch('/api/metrics', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setMetrics(data))
        markLoaded('metrics')
        return
      }
      case 'queue': {
        const data = await fetch('/api/inbox', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setInbox(data))
        markLoaded('queue')
        return
      }
      case 'health': {
        const data = await fetch('/api/health', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setHealth(data))
        markLoaded('health')
        return
      }
      case 'tasks': {
        const data = await fetch('/api/tasks', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setTasks(data))
        markLoaded('tasks')
        return
      }
      case 'constitution': {
        const data = await fetch('/api/constitution', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setConstitution(data))
        markLoaded('constitution')
        return
      }
      case 'services': {
        const data = await fetch('/api/services', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setServices(data))
        markLoaded('services')
        return
      }
      case 'providers':
      case 'provider-activity': {
        const data = await fetch('/api/forge-omega/providers/status', { cache: 'no-store' }).then(r => r.json()).catch(() => null)
        if (data) startTransition(() => setProviders(data))
        markLoaded('providers', 'provider-activity')
        return
      }
      case 'commands':
        loadedSectionsRef.current.commands = true
        return
      case 'erp':
        loadedSectionsRef.current.erp = true
        setErpRefreshTick(tick => tick + 1)
        return
    }
  }, [startTransition])

  const handleNav = useCallback((section: Section) => {
    startTransition(() => {
      setActiveSection(section)
    })
  }, [startTransition])

  useEffect(() => {
    void refreshCore()
    void loadSectionData(activeSection, true)
    const timer = setInterval(() => {
      void refreshCore()
      void loadSectionData(activeSection, true)
    }, 30000)
    return () => { clearInterval(timer) }
  }, [refreshCore, loadSectionData, activeSection])

  return (
    <div className="main-layout">
      {/* Sidebar */}
      <Sidebar active={activeSection} onNav={handleNav} />

      {/* Main content */}
      <div className="main-content">
        {/* Header */}
        <div className="top-header">
          <div className="top-header-content">
            <span className="top-header-title">ธาม Oracle</span>
            <span className="top-header-separator">—</span>
            <span className="top-header-subtitle">
              {SECTION_LABELS[activeSection]}
            </span>
          </div>
          <div className="top-header-controls">
            {fleet?.summary && (
              <div className="grid-flex-h">
                <span className="badge badge-green">{fleet.summary.active} active</span>
                <span className="badge badge-blue">{fleet.summary.total} oracles</span>
              </div>
            )}
            <button
              onClick={async () => { await refreshCore(); await loadSectionData(activeSection, true) }}
              className={`refresh-btn${refreshing ? ' refresh-btn-active' : ''}`}
            >
              {refreshing ? '⟳ refreshing…' : '⟳ refresh'}
            </button>
          </div>
        </div>

        {/* Body */}
        <div className="main-content-area">

          {/* Stat Cards — always visible */}
          <StatCardsRow fleet={fleet} services={services} git={git} />

          <div className={`section-panel${isPending ? ' is-pending' : ''}`} aria-busy={isPending}>
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

            {activeSection === 'commands' && (
              <CommandControlSection />
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
                  <span className="dot" style={{ background: 'var(--accent2)' }} />
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
                  <button onClick={async () => { await refreshCore(); await loadSectionData('providers', true) }} className="refresh-btn" style={{ marginLeft: 'auto' }}>↻ refresh</button>
                </div>
                <MemoQuotaTrackerPanel data={providers} />
              </div>
            )}

            {activeSection === 'provider-activity' && (
              <div className="card">
                <div className="card-header">
                  <span className="dot" style={{ background: 'var(--info)' }} />
                  Provider Activity
                  <button onClick={async () => { await refreshCore(); await loadSectionData('providers', true) }} className="refresh-btn" style={{ marginLeft: 'auto' }}>↻ refresh</button>
                </div>
                <MemoProviderActivityPanel data={providers} />
              </div>
            )}

            {activeSection === 'erp' && (
              <div className="card">
                <div className="card-header">
                  <span className="dot" style={{ background: 'var(--accent2)' }} />
                  ERP Reference Map
                </div>
                <ERPReferencePanel refreshTick={erpRefreshTick} />
              </div>
            )}
          </div>
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
          <span style={{ marginLeft: 'auto', color: 'var(--text-muted)' }}>port 3005</span>
        </div>
      </div>
    </div>
  )
}
