import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import os from 'os'

export const dynamic = 'force-dynamic'

// ── Security: NEVER return API keys ──────────────────────────────────────────
// All key fields are stripped before returning to client.

const PROVIDERS_CONFIG = path.join(os.homedir(), '.config/ai-providers/providers.json')
const ACTIVITY_LOG = '/tmp/tham-provider-activity.jsonl'
const ACTIVITY_MAX_EVENTS = 100

// ── Normalized models ─────────────────────────────────────────────────────────
interface ProviderConfig {
  name: string
  type: string
  model: string
  base_url: string
  quota_limit?: number
  priority?: number
  enabled?: boolean
  api_key?: string         // stripped from response
  api_key_env?: string     // stripped from response
  available_models?: string[]
}

export interface Provider {
  id: string
  providerName: string
  type: string
  model: string
  baseUrl: string
  priority: number
  enabled: boolean
  status: 'available' | 'degraded' | 'unavailable' | 'unknown'
  statusCode: number | null
  latencyMs: number | null
  lastCheckedAt: string
  availableModels?: string[]
}

export interface ProviderQuota {
  providerId: string
  providerName: string
  accountLabel: string
  modelOrLimitName: string
  windowType: 'session' | 'daily' | 'weekly' | 'monthly' | 'rpm' | 'tpm' | 'unknown'
  used: number | null
  limit: number | null
  remaining: number | null
  percentUsed: number | null
  percentRemaining: number | null
  resetAt: string | null
  resetInText: string
  status: 'available' | 'expiring' | 'warning' | 'exhausted' | 'unknown'
  quotaSource: 'api' | 'log' | 'config' | 'inferred' | 'unknown'
  lastCheckedAt: string
}

export interface ProviderActivity {
  id: string
  providerId: string
  providerName: string
  accountLabel: string
  eventType: 'connected' | 'disconnected' | 'request_ok' | 'auth_error' | 'rate_limited' | 'quota_exhausted' | 'timeout' | 'unavailable' | 'config_changed' | 'probe'
  statusCode: number | null
  message: string
  model: string
  endpoint: string
  latencyMs: number | null
  timestamp: string
  source: string
  severity: 'info' | 'warning' | 'error' | 'critical'
}

// ── Load config (safe — no keys returned) ────────────────────────────────────
function loadProviderConfig(): ProviderConfig[] {
  try {
    const raw = fs.readFileSync(PROVIDERS_CONFIG, 'utf8')
    const data = JSON.parse(raw)
    return data.providers || []
  } catch {
    return []
  }
}

// ── Activity log ──────────────────────────────────────────────────────────────
function appendActivity(event: ProviderActivity) {
  try {
    fs.appendFileSync(ACTIVITY_LOG, JSON.stringify(event) + '\n')
  } catch { /* non-fatal */ }
}

function readActivity(limit = 50): ProviderActivity[] {
  try {
    if (!fs.existsSync(ACTIVITY_LOG)) return []
    const lines = fs.readFileSync(ACTIVITY_LOG, 'utf8').split('\n').filter(Boolean)
    return lines
      .slice(-ACTIVITY_MAX_EVENTS)
      .map(l => { try { return JSON.parse(l) } catch { return null } })
      .filter(Boolean)
      .reverse()
      .slice(0, limit) as ProviderActivity[]
  } catch {
    return []
  }
}

// ── HTTP probe (lightweight — HEAD or GET /, no LLM call) ────────────────────
async function probeProvider(provider: ProviderConfig): Promise<{
  ok: boolean; code: number; latencyMs: number; detail: string
}> {
  const t0 = Date.now()
  const url = provider.base_url.replace(/\/$/, '') + '/'
  const key = provider.api_key || ''
  const headers: Record<string, string> = {}

  if (provider.type === 'anthropic' && key) {
    headers['x-api-key'] = key
    headers['anthropic-version'] = '2023-06-01'
  } else if ((provider.type === 'openai' || provider.type === 'gemini') && key) {
    headers['Authorization'] = `Bearer ${key}`
  }

  // http-api providers (oracle-v2) need manual start — use short timeout
  const timeoutMs = provider.type === 'http-api' ? 1200 : 3000

  try {
    const ctrl = new AbortController()
    const timer = setTimeout(() => ctrl.abort(), timeoutMs)
    // Use /v1/models for openai-compat and anthropic (avoids redirect timeouts on root /)
    const probeUrl = (provider.type === 'anthropic' || provider.type === 'openai-compat')
      ? `${provider.base_url.replace(/\/$/, '')}/v1/models`
      : url
    const res = await fetch(probeUrl, {
      method: 'GET',
      headers,
      signal: ctrl.signal,
      cache: 'no-store',
    })
    clearTimeout(timer)
    return { ok: res.ok || res.status < 500, code: res.status, latencyMs: Date.now() - t0, detail: `HTTP ${res.status}` }
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e)
    return { ok: false, code: 0, latencyMs: Date.now() - t0, detail: msg.includes('abort') ? 'timeout' : msg.slice(0, 80) }
  }
}

// ── Classify probe result → event type + severity ─────────────────────────────
function classifyEvent(code: number, ok: boolean): {
  eventType: ProviderActivity['eventType']
  severity: ProviderActivity['severity']
  providerStatus: Provider['status']
} {
  if (ok && code >= 200 && code < 300) return { eventType: 'request_ok', severity: 'info', providerStatus: 'available' }
  if (ok && code >= 300 && code < 400) return { eventType: 'request_ok', severity: 'info', providerStatus: 'available' }
  if (code === 401 || code === 403)    return { eventType: 'auth_error',   severity: 'critical', providerStatus: 'degraded' }
  if (code === 429)                    return { eventType: 'rate_limited', severity: 'warning',  providerStatus: 'degraded' }
  if (code === 0)                      return { eventType: 'timeout',      severity: 'error',    providerStatus: 'unavailable' }
  if (code >= 500)                     return { eventType: 'unavailable',  severity: 'error',    providerStatus: 'unavailable' }
  return { eventType: 'probe', severity: 'warning', providerStatus: 'unknown' }
}

// ── Quota derivation ──────────────────────────────────────────────────────────
function deriveQuota(provider: ProviderConfig, probeCode: number, now: string): ProviderQuota {
  const limit = provider.quota_limit || null
  // We can't know "used" without calling usage API — mark as inferred
  const used = null
  const remaining = null
  const percentUsed = null
  const percentRemaining = null

  let quotaStatus: ProviderQuota['status'] = 'unknown'
  let quotaSource: ProviderQuota['quotaSource'] = 'config'

  if (probeCode === 429) {
    quotaStatus = 'exhausted'
    quotaSource = 'inferred'
  } else if (probeCode === 401 || probeCode === 403) {
    quotaStatus = 'unknown'  // auth error — quota state unknown
    quotaSource = 'unknown'
  } else if (limit !== null) {
    quotaStatus = 'available'
    quotaSource = 'config'
  }

  return {
    providerId: provider.name,
    providerName: provider.name,
    accountLabel: provider.name,
    modelOrLimitName: provider.model,
    windowType: 'unknown',
    used,
    limit,
    remaining,
    percentUsed,
    percentRemaining,
    resetAt: null,
    resetInText: 'unknown',
    status: quotaStatus,
    quotaSource,
    lastCheckedAt: now,
  }
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function runProbes() {
  const now = new Date().toISOString()
  const configs = loadProviderConfig()

  // Probe all providers concurrently (skip disabled unless they have a key)
  const probeJobs = configs.map(async (cfg, i) => {
    // Only probe if enabled or has a key (skip empty-key disabled providers to avoid noise)
    const hasKey = !!(cfg.api_key || process.env[cfg.api_key_env || ''])
    const shouldProbe = cfg.enabled !== false || hasKey

    if (!shouldProbe) {
      return { cfg, probe: { ok: false, code: 0, latencyMs: 0, detail: 'disabled / no key' }, shouldProbe: false }
    }

    const probe = await probeProvider(cfg)
    return { cfg, probe, shouldProbe: true }
  })
  const results = await Promise.all(probeJobs)

  const providers: Provider[] = []
  const quotas: ProviderQuota[] = []
  const newActivity: ProviderActivity[] = []

  for (const { cfg, probe, shouldProbe } of results) {
    const { eventType, severity, providerStatus } = classifyEvent(probe.code, probe.ok)

    const provider: Provider = {
      id: cfg.name,
      providerName: cfg.name,
      type: cfg.type,
      model: cfg.model,
      baseUrl: cfg.base_url,  // URL is not sensitive
      priority: cfg.priority ?? 99,
      enabled: cfg.enabled !== false,
      status: shouldProbe ? providerStatus : (cfg.enabled === false ? 'unavailable' : 'unknown'),
      statusCode: shouldProbe ? probe.code : null,
      latencyMs: shouldProbe ? probe.latencyMs : null,
      lastCheckedAt: now,
      availableModels: cfg.available_models,
    }
    providers.push(provider)

    const quota = deriveQuota(cfg, probe.code, now)
    quotas.push(quota)

    if (shouldProbe) {
      const event: ProviderActivity = {
        id: `${cfg.name}-${Date.now()}`,
        providerId: cfg.name,
        providerName: cfg.name,
        accountLabel: cfg.name,
        eventType,
        statusCode: probe.code,
        message: probe.detail,
        model: cfg.model,
        endpoint: cfg.base_url,  // URL only, no key
        latencyMs: probe.latencyMs,
        timestamp: now,
        source: 'dashboard-probe',
        severity,
      }
      newActivity.push(event)
      appendActivity(event)
    }
  }

  // Sort providers: available first, then by priority
  providers.sort((a, b) => {
    const order = { available: 0, degraded: 1, unknown: 2, unavailable: 3 }
    return (order[a.status] - order[b.status]) || (a.priority - b.priority)
  })

  // Sort quotas: exhausted first, then expiring, warning, available, unknown
  quotas.sort((a, b) => {
    const order = { exhausted: 0, expiring: 1, warning: 2, available: 3, unknown: 4 }
    return order[a.status] - order[b.status]
  })

  // Read recent activity from log (includes this probe + historical)
  const activity = readActivity(50)

  const providerAvailable = providers.filter(p => p.status === 'available').length
  const providerWarning   = providers.filter(p => p.status === 'degraded').length
  const providerExhausted = quotas.filter(q => q.status === 'exhausted').length
  const providerUnknown   = providers.filter(p => p.status === 'unknown').length
  const activityErrors    = activity.filter(
    a => a.severity === 'error' || a.severity === 'critical'
  ).filter(a => {
    const diff = Date.now() - new Date(a.timestamp).getTime()
    return diff < 3600000  // last hour
  }).length

  return {
    providers,
    quotas,
    activity,
    summary: {
      providerTotal:       providers.length,
      providerAvailable:   providerAvailable,
      providerWarning:     providerWarning,
      providerExhausted:   providerExhausted,
      providerUnknown:     providerUnknown,
      activityErrorsLastHour: activityErrors,
      lastCheckedAt: now,
    },
  }
}

export async function GET() {
  const ROUTE_TIMEOUT_MS = 7000
  const timeoutResult = new Promise<null>((resolve) =>
    setTimeout(() => resolve(null), ROUTE_TIMEOUT_MS)
  )
  const data = await Promise.race([runProbes(), timeoutResult])
  if (data === null) {
    return NextResponse.json({
      providers: [], quotas: [], activity: [],
      summary: { providerTotal: 0, providerAvailable: 0, providerWarning: 0,
                 providerExhausted: 0, providerUnknown: 0, activityErrorsLastHour: 0,
                 lastCheckedAt: new Date().toISOString(), error: 'probe timeout' },
    })
  }
  return NextResponse.json(data)
}
