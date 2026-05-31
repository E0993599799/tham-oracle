'use client'

import React, { useCallback, useEffect, useRef, useState } from 'react'

interface TmuxSession {
  name: string
  windows: number
  attached: boolean
}

interface OutputData {
  session: string
  output: string
  capturedAt: string
  error?: string
}

export function TerminalPanel(): React.JSX.Element {
  const [sessions,    setSessions]    = useState<TmuxSession[]>([])
  const [selected,    setSelected]    = useState<string>('')
  const [output,      setOutput]      = useState<string>('')
  const [input,       setInput]       = useState<string>('')
  const [sending,     setSending]     = useState(false)
  const [error,       setError]       = useState<string>('')
  const [connected,   setConnected]   = useState(false)
  const outputRef = useRef<HTMLPreElement>(null)
  const pollRef   = useRef<ReturnType<typeof setInterval> | null>(null)

  // Fetch session list
  const fetchSessions = useCallback(async () => {
    try {
      const res  = await fetch('/api/tmux')
      const data = (await res.json()) as { sessions?: TmuxSession[]; error?: string }
      if (data.sessions) {
        setSessions(data.sessions)
        if (!selected && data.sessions.length > 0) {
          setSelected(data.sessions[0].name)
        }
      }
      if (data.error) setError(data.error)
    } catch (e) {
      setError(String(e))
    }
  }, [selected])

  // Fetch pane output
  const fetchOutput = useCallback(async (session: string) => {
    if (!session) return
    try {
      const res  = await fetch(`/api/tmux/${encodeURIComponent(session)}/output`)
      const data = (await res.json()) as OutputData
      setOutput(data.output ?? '')
      setConnected(true)
      if (data.error) setError(data.error)
    } catch (e) {
      setConnected(false)
      setError(String(e))
    }
  }, [])

  // Initial load + session poll every 10s
  useEffect(() => {
    fetchSessions()
    const t = setInterval(fetchSessions, 10000)
    return () => clearInterval(t)
  }, [fetchSessions])

  // Output poll every 1s when session selected
  useEffect(() => {
    if (pollRef.current) clearInterval(pollRef.current)
    if (!selected) return
    fetchOutput(selected)
    pollRef.current = setInterval(() => fetchOutput(selected), 1000)
    return () => { if (pollRef.current) clearInterval(pollRef.current) }
  }, [selected, fetchOutput])

  // Auto-scroll output to bottom
  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight
    }
  }, [output])

  async function sendInput(): Promise<void> {
    if (!selected || !input.trim()) return
    setSending(true)
    try {
      const res  = await fetch(`/api/tmux/${encodeURIComponent(selected)}/input`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ keys: input }),
      })
      const data = (await res.json()) as { ok: boolean; error?: string }
      if (!data.ok) setError(data.error ?? 'Send failed')
      else setInput('')
    } catch (e) {
      setError(String(e))
    }
    setSending(false)
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>): void {
    if (e.key === 'Enter') void sendInput()
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {/* Session selector */}
      <div style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
        <label style={{ color: 'var(--text-muted)', fontSize: 11, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>
          Session
        </label>
        <select
          value={selected}
          onChange={e => setSelected(e.target.value)}
          style={{
            background:  '#0D1117',
            border:      '1px solid var(--border)',
            borderRadius: 6,
            color:       '#e8e8f0',
            fontFamily:  'monospace',
            fontSize:    12,
            padding:     '4px 8px',
            cursor:      'pointer',
          }}
        >
          {sessions.length === 0 && <option value="">no sessions</option>}
          {sessions.map(s => (
            <option key={s.name} value={s.name}>
              {s.name} ({s.windows}w{s.attached ? ' ●' : ''})
            </option>
          ))}
        </select>
        <span style={{
          width: 8, height: 8, borderRadius: '50%',
          background: connected ? 'var(--success)' : 'var(--danger)',
          display: 'inline-block',
        }} />
        <span style={{ color: 'var(--text-muted)', fontSize: 10 }}>
          {connected ? 'connected · poll 1s' : 'disconnected'}
        </span>
        {error && (
          <span style={{ color: 'var(--danger)', fontSize: 10, marginLeft: 8 }}>
            ⚠ {error.slice(0, 60)}
          </span>
        )}
      </div>

      {/* Output */}
      <pre
        ref={outputRef}
        style={{
          background:    '#0D1117',
          border:        '1px solid var(--border)',
          borderRadius:  8,
          color:         '#e8e8f0',
          fontFamily:    'monospace',
          fontSize:      12,
          lineHeight:    1.5,
          margin:        0,
          minHeight:     280,
          maxHeight:     460,
          overflowY:     'scroll',
          padding:       '10px 14px',
          whiteSpace:    'pre-wrap',
          wordBreak:     'break-all',
        }}
      >
        {output || (selected ? 'waiting for output…' : 'select a session above')}
      </pre>

      {/* Input */}
      <div style={{ display: 'flex', gap: 8 }}>
        <span style={{ color: 'var(--accent)', fontFamily: 'monospace', fontSize: 13, lineHeight: '30px', flexShrink: 0 }}>
          ›
        </span>
        <input
          type="text"
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          disabled={!selected || sending}
          placeholder={selected ? 'type command + Enter to send' : 'select session first'}
          style={{
            flex:        1,
            background:  '#0D1117',
            border:      '1px solid var(--border)',
            borderRadius: 6,
            color:       '#e8e8f0',
            fontFamily:  'monospace',
            fontSize:    12,
            padding:     '6px 10px',
            outline:     'none',
          }}
        />
        <button
          onClick={() => void sendInput()}
          disabled={!selected || !input.trim() || sending}
          style={{
            background:   sending ? 'rgba(34,211,238,0.15)' : 'rgba(34,211,238,0.1)',
            border:       '1px solid rgba(34,211,238,0.3)',
            borderRadius: 6,
            color:        'var(--accent)',
            cursor:       sending ? 'not-allowed' : 'pointer',
            fontFamily:   'inherit',
            fontSize:     12,
            fontWeight:   600,
            padding:      '6px 14px',
          }}
        >
          {sending ? '⟳' : 'Send'}
        </button>
      </div>
    </div>
  )
}
