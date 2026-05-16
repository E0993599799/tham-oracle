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

// ── Helpers ────────────────────────────────────────────────────────────────
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

function daysLabel(days: number): string {
  if (days === 9999) return '—'
  if (days === 0) return 'today'
  return `${days}d`
}

function ago(days: number): string {
  if (days === 9999) return 'never'
  if (days === 0) return 'today'
  if (days === 1) return '1d ago'
  return `${days}d ago`
}

// ── Panels ─────────────────────────────────────────────────────────────────
function StatBar({ s }: { s: FleetData['summary'] }) {
  return (
    <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginBottom: 4 }}>
      {[
        { label: 'active', val: s.active, cls: 'badge-green' },
        { label: 'stale',  val: s.stale,  cls: 'badge-yellow' },
        { label: 'cold',   val: s.cold,   cls: 'badge-orange' },
        { label: 'abandoned', val: s.abandoned, cls: 'badge-red' },
        { label: 'zygote', val: s.zygote, cls: 'badge-gray' },
        { label: 'total',  val: s.total,  cls: 'badge-blue' },
      ].map(({ label, val, cls }) => (
        <span key={label} className={`badge ${cls}`}>
          {val} {label}
        </span>
      ))}
    </div>
  )
}

function FleetPanel({ data }: { data: FleetData | null }) {
  const [filter, setFilter] = useState<string>('all')
  if (!data) return <div style={{ color: '#8491b0' }}>loading fleet…</div>

  const oracles = data.oracles.filter(o => {
    if (filter === 'all') return true
    if (filter === 'active') return o.days < 7
    if (filter === 'stale')  return o.days >= 7 && o.days < 30
    if (filter === 'cold')   return o.days >= 30 && o.days < 90
    if (filter === 'abandoned') return o.days >= 90 && o.days < 999
    return true
  })

  return (
    <div>
      <StatBar s={data.summary} />
      <div style={{ display: 'flex', gap: 8, margin: '12px 0 10px', flexWrap: 'wrap' }}>
        {['all','active','stale','cold','abandoned'].map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            style={{
              padding: '3px 12px',
              borderRadius: 999,
              border: '1px solid',
              borderColor: filter === f ? '#3b7cf4' : '#1e2d4a',
              background: filter === f ? '#1e3a8a33' : 'transparent',
              color: filter === f ? '#93c5fd' : '#8491b0',
              cursor: 'pointer',
              fontSize: 11,
              fontFamily: 'inherit',
            }}
          >
            {f}
          </button>
        ))}
      </div>
      <div className="oracle-grid">
        {oracles.map(o => (
          <div key={o.name} className={`oracle-card ${statusClass(o.days)}`}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
              <span style={{ fontSize: 12, fontWeight: 600, color: '#c7d8ff' }}>
                {o.status} {o.name}
              </span>
              {o.hasAwaken && <span style={{ fontSize: 10, color: '#a855f7' }}>✦</span>}
            </div>
            <div style={{ color: '#8491b0', fontSize: 11 }}>
              {o.branch && <span style={{ color: '#4ade80', marginRight: 6 }}>{o.branch}</span>}
              {ago(o.days)}
            </div>
          </div>
        ))}
        {oracles.length === 0 && <div style={{ color: '#8491b0', padding: 8 }}>none</div>}
      </div>
    </div>
  )
}

function GitPanel({ data }: { data: GitData | null }) {
  if (!data) return <div style={{ color: '#8491b0' }}>loading git…</div>
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
              <td style={{ maxWidth: 280, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {c.subject}
              </td>
              <td style={{ color: '#8491b0', whiteSpace: 'nowrap' }}>{c.ago}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function MemoryPanel({ data }: { data: MemData | null }) {
  if (!data) return <div style={{ color: '#8491b0' }}>loading memory…</div>

  return (
    <div>
      <div style={{ marginBottom: 12 }}>
        {data.files.map(f => (
          <div key={f.key} style={{
            background: '#0d1829',
            border: '1px solid #1e2d4a',
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
                <span style={{ color: '#8491b0', fontSize: 10 }}>{f.sizeKB}KB</span>
                {f.hash && f.hash !== 'untracked' && (
                  <span className="hash">{f.hash}</span>
                )}
              </div>
            </div>
            <div style={{ color: '#8491b0', fontSize: 11 }}>{f.path}</div>
            {f.snippet && (
              <div style={{ color: '#6b7fa8', fontSize: 10, marginTop: 3, fontStyle: 'italic' }}>
                {f.snippet.slice(0, 100)}
              </div>
            )}
          </div>
        ))}
      </div>

      {data.constitutionRules.length > 0 && (
        <div>
          <div style={{ fontSize: 10, color: '#8491b0', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 8 }}>
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

function MetricsPanel({ data }: { data: MetricsData | null }) {
  if (!data) return <div style={{ color: '#8491b0' }}>loading metrics…</div>

  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 12 }}>
        <span className="badge badge-blue">📝 {data.retrosToday} retros today</span>
        <span className="badge badge-purple" style={{ background: '#4c1d9533', color: '#c084fc', borderColor: '#7c3aed33' }}>
          💡 {data.learningsThisMonth} learnings this month
        </span>
      </div>
      {data.rows.length === 0 ? (
        <div style={{ color: '#8491b0' }}>no session metrics yet</div>
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
                <td style={{ color: '#8491b0', fontSize: 10 }}>{r.when}</td>
                <td><span className="hash">{r.session.slice(0, 8)}</span></td>
                <td style={{ color: '#4ade80', fontSize: 11 }}>{r.win.slice(0, 40)}</td>
                <td style={{ color: '#f59e0b', fontSize: 11 }}>{r.friction.slice(0, 40)}</td>
                <td style={{ color: '#f87171', fontSize: 11 }}>{r.error.slice(0, 40)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}

function InboxPanel({ data }: { data: InboxData | null }) {
  if (!data) return <div style={{ color: '#8491b0' }}>loading queue…</div>

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
            background: '#0d1829',
            border: '1px solid #1e2d4a',
            borderRadius: 8,
            padding: '10px 12px',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <span style={{ color: '#c7d8ff', fontSize: 12 }}>{icon} {label}</span>
              <span className={`badge ${badge}`}>{val.count}</span>
            </div>
            {raw.length === 0 && (
              <div style={{ color: '#4a5878', fontSize: 11 }}>empty</div>
            )}
            {raw.map((f, i) => {
              const name   = typeof f === 'string' ? f : f.name
              const mtime  = typeof f === 'string' ? '' : f.mtime
              const sizeKB = typeof f === 'string' ? 0  : f.sizeKB
              return (
                <div key={i} style={{
                  borderBottom: i < raw.length - 1 ? '1px solid #111d30' : 'none',
                  padding: '5px 0',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  gap: 8,
                }}>
                  <span style={{ color: '#93a8d8', fontSize: 11, wordBreak: 'break-all', flex: 1 }}>
                    {name.slice(0, 36)}{name.length > 36 ? '…' : ''}
                  </span>
                  <div style={{ textAlign: 'right', flexShrink: 0 }}>
                    {mtime && (
                      <div style={{ color: '#4ade80', fontSize: 10 }}>{fmtTime(mtime)}</div>
                    )}
                    {sizeKB > 0 && (
                      <div style={{ color: '#4a5878', fontSize: 10 }}>{sizeKB}KB</div>
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

// ── Main Page ──────────────────────────────────────────────────────────────
export default function Dashboard() {
  const [fleet,   setFleet]   = useState<FleetData | null>(null)
  const [git,     setGit]     = useState<GitData | null>(null)
  const [mem,     setMem]     = useState<MemData | null>(null)
  const [metrics, setMetrics] = useState<MetricsData | null>(null)
  const [inbox,   setInbox]   = useState<InboxData | null>(null)
  const [lastRefresh, setLastRefresh] = useState<string>('')
  const [refreshing, setRefreshing]   = useState(false)

  const refresh = useCallback(async () => {
    setRefreshing(true)
    await Promise.all([
      fetch('/api/fleet').then(r => r.json()).then(setFleet).catch(() => {}),
      fetch('/api/git').then(r => r.json()).then(setGit).catch(() => {}),
      fetch('/api/memory').then(r => r.json()).then(setMem).catch(() => {}),
      fetch('/api/metrics').then(r => r.json()).then(setMetrics).catch(() => {}),
      fetch('/api/inbox').then(r => r.json()).then(setInbox).catch(() => {}),
    ])
    setLastRefresh(new Date().toLocaleTimeString('th-TH'))
    setRefreshing(false)
  }, [])

  useEffect(() => {
    refresh()
    const timer = setInterval(refresh, 30000)
    return () => clearInterval(timer)
  }, [refresh])

  return (
    <div style={{ minHeight: '100vh', padding: '0 0 48px' }}>
      {/* Header */}
      <div style={{
        background: '#0a1220',
        borderBottom: '1px solid #1e2d4a',
        padding: '12px 20px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        position: 'sticky',
        top: 0,
        zIndex: 50,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 16, fontWeight: 700, color: '#e2e8f7' }}>ธาม Oracle</span>
          <span style={{ color: '#8491b0', fontSize: 12 }}>—</span>
          <span style={{ color: '#8491b0', fontSize: 12 }}>Fleet & Memory Dashboard</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {fleet?.summary && (
            <div style={{ display: 'flex', gap: 8 }}>
              <span className="badge badge-green">{fleet.summary.active} active</span>
              <span className="badge badge-blue">{fleet.summary.total} total</span>
            </div>
          )}
          <button
            onClick={refresh}
            style={{
              background: refreshing ? '#1e3a8a33' : '#131f35',
              border: '1px solid #1e2d4a',
              borderRadius: 6,
              padding: '4px 12px',
              color: refreshing ? '#93c5fd' : '#8491b0',
              cursor: 'pointer',
              fontSize: 11,
              fontFamily: 'inherit',
            }}
          >
            {refreshing ? '⟳ refreshing…' : '⟳ refresh'}
          </button>
        </div>
      </div>

      {/* Body */}
      <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 16 }}>

        {/* Row 1: Fleet (full width) */}
        <div className="card">
          <div className="card-header">
            <span className="dot" style={{ background: '#22c55e' }} />
            Oracle Fleet
          </div>
          <FleetPanel data={fleet} />
        </div>

        {/* Row 2: Git + Inbox side by side */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div className="card">
            <div className="card-header">
              <span className="dot" style={{ background: '#3b7cf4' }} />
              Git Activity — tham-oracle
            </div>
            <GitPanel data={git} />
          </div>
          <div className="card">
            <div className="card-header">
              <span className="dot" style={{ background: '#f59e0b' }} />
              Queue / ψ Vault
            </div>
            <InboxPanel data={inbox} />
          </div>
        </div>

        {/* Row 3: Memory Gate + Session Metrics */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div className="card">
            <div className="card-header">
              <span className="dot" style={{ background: '#a855f7' }} />
              Memory Gate
            </div>
            <MemoryPanel data={mem} />
          </div>
          <div className="card">
            <div className="card-header">
              <span className="dot" style={{ background: '#06b6d4' }} />
              Session Metrics
            </div>
            <MetricsPanel data={metrics} />
          </div>
        </div>

      </div>

      {/* Status bar */}
      <div className="statusbar">
        <span className={refreshing ? 'pulse' : ''} style={{ color: '#22c55e' }}>●</span>
        <span>ธาม Oracle Dashboard</span>
        <span style={{ color: '#1e2d4a' }}>|</span>
        <span>auto-refresh 30s</span>
        <span style={{ color: '#1e2d4a' }}>|</span>
        <span>last: {lastRefresh || '—'}</span>
        {git?.branch && (
          <>
            <span style={{ color: '#1e2d4a' }}>|</span>
            <span>⎇ {git.branch}</span>
          </>
        )}
        {fleet?.summary && (
          <>
            <span style={{ color: '#1e2d4a' }}>|</span>
            <span>{fleet.summary.total} oracles</span>
          </>
        )}
        <span style={{ marginLeft: 'auto', color: '#1e2d4a' }}>port 3000</span>
      </div>
    </div>
  )
}
