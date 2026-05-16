import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

interface ServiceResult {
  name: string
  port: number
  url: string
  status: 'online' | 'offline'
  latency_ms: number | null
  checked_at: string
}

async function probeService(name: string, port: number, url: string): Promise<ServiceResult> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 2000)
  const start = Date.now()
  try {
    const res = await fetch(url, { signal: controller.signal, cache: 'no-store' })
    clearTimeout(timeout)
    const latency_ms = Date.now() - start
    return {
      name,
      port,
      url,
      status: res.ok || res.status < 500 ? 'online' : 'offline',
      latency_ms,
      checked_at: new Date().toISOString(),
    }
  } catch {
    clearTimeout(timeout)
    return {
      name,
      port,
      url,
      status: 'offline',
      latency_ms: null,
      checked_at: new Date().toISOString(),
    }
  }
}

export async function GET() {
  const services = await Promise.all([
    probeService('oracle-v2', 47778, 'http://localhost:47778/'),
    probeService('dashboard', 3000, 'http://localhost:3000/api/git'),
  ])

  return NextResponse.json({ services, checked_at: new Date().toISOString() })
}
