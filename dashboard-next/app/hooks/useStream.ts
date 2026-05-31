'use client'

import { useEffect, useRef, useState } from 'react'

interface FleetPayload {
  raw: string
  updatedAt: string
}

interface TasksPayload {
  files: { name: string; mtime: string }[]
  count: number
  updatedAt: string
}

interface HealthService {
  name: string
  port: number
  url: string
  ok: boolean
  code: number
}

interface HealthPayload {
  services: HealthService[]
  checkedAt: string
}

export interface StreamState {
  fleet:     FleetPayload | null
  tasks:     TasksPayload | null
  health:    HealthPayload | null
  connected: boolean
}

const INITIAL_DELAY = 500
const MAX_DELAY     = 30000

export function useStream(url: string): StreamState {
  const [state, setState] = useState<StreamState>({
    fleet: null, tasks: null, health: null, connected: false,
  })
  const esRef    = useRef<EventSource | null>(null)
  const delayRef = useRef(INITIAL_DELAY)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const aliveRef = useRef(true)

  useEffect(() => {
    aliveRef.current = true

    function connect(): void {
      if (!aliveRef.current) return

      const es = new EventSource(url)
      esRef.current = es

      es.onopen = () => {
        delayRef.current = INITIAL_DELAY
        setState(prev => ({ ...prev, connected: true }))
      }

      es.onmessage = (e: MessageEvent) => {
        try {
          const event = JSON.parse(e.data) as { type: string; payload: unknown }
          if (event.type === 'fleet') {
            setState(prev => ({ ...prev, fleet: event.payload as FleetPayload }))
          } else if (event.type === 'tasks') {
            setState(prev => ({ ...prev, tasks: event.payload as TasksPayload }))
          } else if (event.type === 'health') {
            setState(prev => ({ ...prev, health: event.payload as HealthPayload }))
          }
        } catch { /* malformed event — ignore */ }
      }

      es.onerror = () => {
        es.close()
        setState(prev => ({ ...prev, connected: false }))
        if (!aliveRef.current) return
        // Exponential backoff
        timerRef.current = setTimeout(() => {
          delayRef.current = Math.min(delayRef.current * 2, MAX_DELAY)
          connect()
        }, delayRef.current)
      }
    }

    connect()

    return () => {
      aliveRef.current = false
      if (timerRef.current) clearTimeout(timerRef.current)
      esRef.current?.close()
    }
  }, [url])

  return state
}
