import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

export async function GET() {
  const apiKey = process.env.ANTHROPIC_API_KEY
  const online = Boolean(apiKey)

  return NextResponse.json({
    schema: 'omega.tham.heartbeat.v1',
    online,
    agent_name: 'tham-oracle',
    agent_status: online ? 'active' : 'degraded',
    last_seen: new Date().toISOString(),
    bridge: {
      type: 'direct',
      online,
      reason: online ? null : 'ANTHROPIC_API_KEY not set',
    },
    wake_available: online,
    checked_at: Math.floor(Date.now() / 1000),
  })
}
