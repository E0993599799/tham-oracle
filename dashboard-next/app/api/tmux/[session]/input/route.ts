import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export const dynamic = 'force-dynamic'

interface RouteContext {
  params: Promise<{ session: string }>
}

interface InputBody {
  keys: string
}

export async function POST(req: Request, ctx: RouteContext): Promise<NextResponse> {
  const { session } = await ctx.params
  if (!session || !/^[\w\-.:]+$/.test(session)) {
    return NextResponse.json({ error: 'Invalid session name' }, { status: 400 })
  }
  try {
    const body = (await req.json()) as InputBody
    const keys = body.keys ?? ''
    if (typeof keys !== 'string' || keys.length > 500) {
      return NextResponse.json({ error: 'Invalid keys payload' }, { status: 400 })
    }
    // Escape the keys string for tmux send-keys — pass as literal string + Enter
    execSync(
      `tmux send-keys -t ${JSON.stringify(session)} ${JSON.stringify(keys)} Enter`,
      { encoding: 'utf8', timeout: 3000 },
    )
    return NextResponse.json({ ok: true, session, sentAt: new Date().toISOString() })
  } catch (e) {
    return NextResponse.json({ ok: false, error: String(e) }, { status: 500 })
  }
}
