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
    const errText = await res.text().catch(() => res.statusText)
    // Surface credit errors distinctly so the caller can fallback
    if (res.status === 400 && errText.includes('credit balance is too low')) {
      throw Object.assign(new Error('credit_low'), { code: 'credit_low' })
    }
    throw new Error(`Anthropic API error ${res.status}: ${errText}`)
  }

  const data = await res.json()
  const content = data?.content?.[0]?.text
  if (!content) throw new Error('Empty response from Claude')
  return content
}

async function callCodex(humanText: string, codexApiKey: string): Promise<string> {
  const model = process.env.CODEX_MODEL || 'gpt-4o'

  // sk-proj- keys use the standard OpenAI API; OAuth Hermes tokens use chatgpt.com/backend-api/codex
  const isOAuthToken = !codexApiKey.startsWith('sk-')
  const baseUrl = isOAuthToken
    ? (process.env.CODEX_BASE_URL || 'https://chatgpt.com/backend-api/codex').replace(/\/$/, '')
    : 'https://api.openai.com/v1'

  if (isOAuthToken) {
    // Hermes OAuth path — Responses API with SSE
    const accountId = process.env.CHATGPT_ACCOUNT_ID
    const res = await fetch(`${baseUrl}/responses`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${codexApiKey}`,
        'Content-Type': 'application/json',
        'User-Agent': 'codex_cli_rs/0.0.0 (Hermes Agent)',
        originator: 'codex_cli_rs',
        ...(accountId ? { 'ChatGPT-Account-ID': accountId } : {}),
      },
      body: JSON.stringify({
        model,
        instructions: SYSTEM_PROMPT,
        input: [{ role: 'user', content: humanText }],
        store: false,
        stream: true,
      }),
      signal: AbortSignal.timeout(30000),
    })

    if (!res.ok) {
      const errText = await res.text().catch(() => res.statusText)
      throw new Error(`Codex API error ${res.status}: ${errText}`)
    }

    const sseText = await res.text()
    let outputText = ''
    for (const line of sseText.split('\n')) {
      if (!line.startsWith('data: ')) continue
      const raw = line.slice(6).trim()
      if (raw === '[DONE]') break
      try {
        const evt = JSON.parse(raw)
        if (evt.type === 'response.output_text.delta') {
          outputText += evt.delta || ''
        } else if (evt.type === 'response.done' || evt.type === 'response.completed') {
          const finalText =
            evt.response?.output_text ||
            evt.response?.output?.find((o: { type: string }) => o.type === 'message')
              ?.content?.find((c: { type: string }) => c.type === 'output_text')?.text ||
            ''
          if (finalText) outputText = finalText
        }
      } catch { /* skip malformed SSE lines */ }
    }

    if (!outputText) throw new Error('Codex: no output_text extracted from SSE stream')
    return outputText.trim()
  }

  // Standard OpenAI API path (sk-proj- / sk- keys)
  const res = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${codexApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      max_tokens: 1024,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: humanText },
      ],
    }),
    signal: AbortSignal.timeout(30000),
  })

  if (!res.ok) {
    const errText = await res.text().catch(() => res.statusText)
    throw new Error(`OpenAI API error ${res.status}: ${errText}`)
  }

  const data = await res.json()
  const text = data?.choices?.[0]?.message?.content
  if (!text) throw new Error('OpenAI: empty response')
  return text.trim()
}

export async function POST(request: NextRequest) {
  const anthropicKey = process.env.ANTHROPIC_API_KEY
  const codexKey = process.env.CODEX_API_KEY

  if (!anthropicKey && !codexKey) {
    return NextResponse.json(
      { error: 'No LLM credentials configured (ANTHROPIC_API_KEY or CODEX_API_KEY)', message: null, forward: null },
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

  // Try Claude first; fallback to Codex on credit error
  if (anthropicKey) {
    try {
      const reply = await callClaude([{ role: 'user', content: humanText }], anthropicKey)
      return NextResponse.json({ message: reply, forward: null, provider: 'claude' }, { status: 200 })
    } catch (err) {
      const isCreditLow = err instanceof Error && (err as NodeJS.ErrnoException & { code?: string }).code === 'credit_low'
      if (!isCreditLow || !codexKey) {
        return NextResponse.json(
          { error: err instanceof Error ? err.message : 'llm_error', message: null, forward: null },
          { status: 502 }
        )
      }
      // Fall through to Codex
    }
  }

  // Codex / gpt-5.4 path
  try {
    const reply = await callCodex(humanText, codexKey!)
    return NextResponse.json({ message: reply, forward: null, provider: 'codex' }, { status: 200 })
  } catch (err) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : 'codex_error', message: null, forward: null },
      { status: 502 }
    )
  }
}

export async function GET() {
  return NextResponse.json({ messages: [], count: 0, schema: 'omega.tham.chat.history.v1' })
}
