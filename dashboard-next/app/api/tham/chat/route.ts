import { NextRequest, NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

const SYSTEM_PROMPT = `คุณคือ ธาม (Tham) — Oracle/Observer/Governor สำหรับระบบ Forge/Omega ของพี่เอก

บทบาทของธาม:
- ที่ปรึกษาเชิงกลยุทธ์และ CTO ที่ไว้ใจได้
- ประสานงานและ delegate งานให้ agents (Core, Codex, Gemini, Hermes)
- ตรวจสอบ risk และ governance ก่อนตัดสินใจ
- ซื่อสัตย์ต่อสถานะงาน ไม่แสร้งทำเป็นสำเร็จถ้ายังไม่มี proof
- คุยอบอุ่น จริงใจ ตรงประเด็น

กฎสำคัญ:
- เรียก Human ว่า "พี่" หรือ "พี่เอก"
- แทนตัวเองว่า "ธาม"
- ไม่ execute โดยตรง — ให้คำแนะนำและ route งานให้ agent ที่เหมาะสม
- ถ้าเจอความเสี่ยงให้หยุดและเสนอทางที่ปลอดภัยกว่า
- ตอบสั้น กระชับ ทำได้จริง`

interface AnthropicMessage {
  role: 'user' | 'assistant'
  content: string
}

async function callClaude(messages: AnthropicMessage[], apiKey: string): Promise<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages,
    }),
    signal: AbortSignal.timeout(20000),
  })

  if (!res.ok) {
    const err = await res.text().catch(() => res.statusText)
    throw new Error(`Anthropic API error ${res.status}: ${err}`)
  }

  const data = await res.json()
  const content = data?.content?.[0]?.text
  if (!content) throw new Error('Empty response from Claude')
  return content
}

export async function POST(request: NextRequest) {
  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey) {
    return NextResponse.json(
      { error: 'ANTHROPIC_API_KEY not configured', message: null, forward: null },
      { status: 503 }
    )
  }

  let body: { message?: string; conversation_id?: string; source?: string } = {}
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Invalid JSON', message: null, forward: null }, { status: 400 })
  }

  const humanText = (body.message || '').trim()
  if (!humanText) {
    return NextResponse.json({ error: '"message" required', message: null, forward: null }, { status: 400 })
  }

  try {
    const reply = await callClaude([{ role: 'user', content: humanText }], apiKey)
    return NextResponse.json({ message: reply, forward: null }, { status: 200 })
  } catch (err) {
    return NextResponse.json(
      {
        error: err instanceof Error ? err.message : 'llm_error',
        message: null,
        forward: null,
      },
      { status: 502 }
    )
  }
}

export async function GET() {
  return NextResponse.json({ messages: [], count: 0, schema: 'omega.tham.chat.history.v1' })
}
