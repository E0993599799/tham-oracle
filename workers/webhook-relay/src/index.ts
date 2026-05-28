/**
 * Tham Oracle — Cloudflare Webhook Relay Worker
 *
 * Routes inbound webhooks from GitHub / Telegram / LINE / generic sources
 * → normalises payload → POST /api/feed/ on the local oracle-v2 instance
 *   reachable via ORACLE_URL (a cloudflared quick-tunnel URL).
 *
 * Deploy:
 *   npx wrangler deploy
 * Set env vars:
 *   npx wrangler secret put ORACLE_SECRET   # shared HMAC secret with oracle-v2
 *   npx wrangler secret put ORACLE_URL      # e.g. https://xxxx.trycloudflare.com
 *   npx wrangler secret put GITHUB_SECRET   # GitHub webhook secret (optional)
 *   npx wrangler secret put TELEGRAM_TOKEN  # Telegram bot token (optional)
 *
 * Routes:
 *   POST /webhook/github    → GitHub push / PR / issue events
 *   POST /webhook/telegram  → Telegram bot update
 *   POST /webhook/line      → LINE Messaging API event
 *   POST /webhook/<any>     → generic passthrough
 *   GET  /health            → liveness probe
 */

export interface Env {
  ORACLE_URL: string;      // https://xxxx.trycloudflare.com  (no trailing slash)
  ORACLE_SECRET: string;   // HMAC-SHA256 key sent as X-Oracle-Hmac header
  GITHUB_SECRET?: string;
  TELEGRAM_TOKEN?: string;
}

// ── helpers ─────────────────────────────────────────────────────────────────

async function hmacHex(secret: string, body: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function verifyGitHubSignature(secret: string, body: string, header: string | null): Promise<boolean> {
  if (!header || !header.startsWith("sha256=")) return false;
  const expected = "sha256=" + (await hmacHex(secret, body));
  // constant-time compare
  if (expected.length !== header.length) return false;
  const a = new TextEncoder().encode(expected);
  const b = new TextEncoder().encode(header);
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ── feed POST helper ─────────────────────────────────────────────────────────

async function forwardToOracle(
  env: Env,
  source: string,
  event: string,
  payload: unknown,
  raw: string,
): Promise<Response> {
  const feedEntry = {
    source,
    event,
    payload,
    raw,
    ts: new Date().toISOString(),
  };

  const body = JSON.stringify(feedEntry);
  const hmac = await hmacHex(env.ORACLE_SECRET, body);

  const resp = await fetch(`${env.ORACLE_URL}/api/feed/`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Oracle-Source": source,
      "X-Oracle-Event": event,
      "X-Oracle-Hmac": hmac,
    },
    body,
  });

  if (!resp.ok) {
    const text = await resp.text();
    console.error(`oracle feed POST failed ${resp.status}: ${text}`);
    return jsonResponse({ error: "oracle unavailable", status: resp.status }, 502);
  }

  return jsonResponse({ ok: true, forwarded: source, event });
}

// ── route handlers ───────────────────────────────────────────────────────────

async function handleGitHub(req: Request, env: Env): Promise<Response> {
  const raw = await req.text();

  if (env.GITHUB_SECRET) {
    const sig = req.headers.get("X-Hub-Signature-256");
    if (!(await verifyGitHubSignature(env.GITHUB_SECRET, raw, sig))) {
      return jsonResponse({ error: "invalid signature" }, 401);
    }
  }

  const event = req.headers.get("X-GitHub-Event") ?? "push";
  let payload: unknown;
  try { payload = JSON.parse(raw); } catch { payload = {}; }

  return forwardToOracle(env, "github", event, payload, raw);
}

async function handleTelegram(req: Request, env: Env): Promise<Response> {
  // Telegram sends updates as POST JSON; no HMAC, but the path itself can
  // embed the bot token as a secret: /webhook/telegram/<TOKEN>
  const raw = await req.text();
  let payload: unknown;
  try { payload = JSON.parse(raw); } catch { payload = {}; }

  const update = payload as Record<string, unknown>;
  const event = update.message
    ? "message"
    : update.callback_query
    ? "callback_query"
    : update.inline_query
    ? "inline_query"
    : "update";

  return forwardToOracle(env, "telegram", event, payload, raw);
}

async function handleLine(req: Request, env: Env): Promise<Response> {
  const raw = await req.text();
  let payload: unknown;
  try { payload = JSON.parse(raw); } catch { payload = {}; }

  const events = (payload as Record<string, unknown>).events;
  const firstEvent = Array.isArray(events) && events[0]
    ? (events[0] as Record<string, unknown>).type ?? "unknown"
    : "unknown";

  return forwardToOracle(env, "line", String(firstEvent), payload, raw);
}

async function handleGeneric(req: Request, env: Env, source: string): Promise<Response> {
  const raw = await req.text();
  let payload: unknown;
  try { payload = JSON.parse(raw); } catch { payload = { body: raw }; }

  return forwardToOracle(env, source, "webhook", payload, raw);
}

// ── main fetch ───────────────────────────────────────────────────────────────

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const path = url.pathname;

    if (path === "/health" && req.method === "GET") {
      return jsonResponse({ ok: true, relay: "tham-oracle-webhook-relay" });
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "method not allowed" }, 405);
    }

    if (!env.ORACLE_URL) {
      return jsonResponse({ error: "ORACLE_URL not configured" }, 503);
    }

    // /webhook/<source>
    const match = path.match(/^\/webhook\/([a-zA-Z0-9_-]+)/);
    if (!match) {
      return jsonResponse({ error: "unknown route" }, 404);
    }

    const source = match[1].toLowerCase();

    switch (source) {
      case "github":    return handleGitHub(req, env);
      case "telegram":  return handleTelegram(req, env);
      case "line":      return handleLine(req, env);
      default:          return handleGeneric(req, env, source);
    }
  },
};
