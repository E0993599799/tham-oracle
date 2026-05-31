import { NextResponse } from 'next/server'
import { execSync } from 'child_process'

export const dynamic = 'force-dynamic'

interface RouteContext {
  params: Promise<{ session: string }>
}

export async function GET(_req: Request, ctx: RouteContext): Promise<NextResponse> {
  const { session } = await ctx.params
  if (!session || !/^[\w\-.:]+$/.test(session)) {
    return NextResponse.json({ error: 'Invalid session name' }, { status: 400 })
  }
  try {
    const output = execSync(
      `tmux capture-pane -t ${JSON.stringify(session)} -p -S -200 2>/dev/null`,
      { encoding: 'utf8', timeout: 3000 },
    )
    return NextResponse.json({ session, output, capturedAt: new Date().toISOString() })
  } catch (e) {
    return NextResponse.json({ session, output: '', error: String(e) }, { status: 500 })
  }
}
