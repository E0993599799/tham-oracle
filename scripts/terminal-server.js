#!/usr/bin/env node
// terminal-server.js — Live tmux pane viewer for oracle-fleet
// No external dependencies — Node.js built-ins only
// Usage: node scripts/terminal-server.js [port] [session]

'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync, execFileSync } = require('child_process');

const PORT    = parseInt(process.argv[2] || process.env.TERM_PORT || '3002', 10);
const SESSION = process.argv[3] || process.env.THAM_ORACLE_SESSION || process.env.TMUX_SESSION || 'tham-oracle-stack';
const DASH_DIR = path.join(__dirname, '..', 'dashboard');
const REPO_ROOT = path.join(__dirname, '..');
const BRAIN_INDEXER = path.join(__dirname, 'second_brain_indexer.py');
const TMUX_TIMEOUT_MS = 1000;
const PANE_ID_RE = /^%\d+$/;

// Agent metadata
const AGENT_META = {
  brain:  [{ name: 'tham',        color: '#3b82f6', role: 'Brain / Orchestrator' },
           { name: 'bob',         color: '#f59e0b', role: 'Inter-Oracle Coordinator' }],
  exec:   [{ name: 'core',        color: '#10b981', role: 'Bridge / Gate (Omega)' },
           { name: 'hermes',      color: '#8b5cf6', role: 'Specialist / Legacy (9router)' }],
  ops:    [{ name: 'housekeeper', color: '#ef4444', role: 'Maintenance' },
           { name: 'dashboard',   color: '#6366f1', role: 'Fleet Dashboard' }],
  design: [{ name: 'uxui',        color: '#06b6d4', role: 'UX/UI Design (Gemini)' },
           { name: 'bugfix',      color: '#f97316', role: 'BugFix (Codex-Style)' }],
};

function getPanes() {
  try {
    const raw = execSync(
      `tmux list-panes -s -t "${SESSION}" -F "#{pane_id}|#{window_index}|#{window_name}|#{pane_index}|#{pane_width}|#{pane_height}|#{pane_current_command}"`,
      { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'], timeout: TMUX_TIMEOUT_MS }
    ).trim();
    if (!raw) return [];

    return raw.split('\n').map(line => {
      const [id, winIdx, window, paneIdx, width, height, cmd] = line.split('|');
      const pi = parseInt(paneIdx, 10);
      const meta = (AGENT_META[window] || [])[pi] || { name: `${window}.${pi}`, color: '#6b7280', role: '' };
      return {
        id,
        window,
        window_index: parseInt(winIdx, 10),
        pane_index: pi,
        width:  parseInt(width, 10),
        height: parseInt(height, 10),
        cmd,
        ...meta,
      };
    }).sort((a, b) => a.window_index - b.window_index || a.pane_index - b.pane_index);
  } catch {
    return [];
  }
}

function capturePane(paneId, lines = 60) {
  try {
    return execSync(
      `tmux capture-pane -t "${paneId}" -p -e -S -${lines} 2>/dev/null`,
      { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'], maxBuffer: 1024 * 512, timeout: TMUX_TIMEOUT_MS }
    );
  } catch {
    return '';
  }
}

const BRAIN_INDEX = path.join(DASH_DIR, 'brain-index.json');

function buildBrainIndex() {
  execFileSync(
    'python3',
    [BRAIN_INDEXER, '--root', REPO_ROOT, '--output', BRAIN_INDEX],
    { stdio: ['ignore', 'pipe', 'pipe'], encoding: 'utf8' }
  );
  return fs.readFileSync(BRAIN_INDEX, 'utf8');
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js':   'text/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.ico':  'image/x-icon',
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // ── /api/panes ─────────────────────────────────────────────────────
  if (url.pathname === '/api/panes') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify(getPanes()));
    return;
  }

  // ── /api/stream?id=<pane_id> — SSE live stream ─────────────────────
  if (url.pathname === '/api/stream') {
    const paneId = url.searchParams.get('id');
    if (!paneId) { res.writeHead(400); res.end('missing id'); return; }
    if (!PANE_ID_RE.test(paneId)) { res.writeHead(400); res.end('invalid id'); return; }

    res.writeHead(200, {
      'Content-Type':  'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection':    'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });

    // Send pane list alongside so client can refresh
    let prev = null;
    const send = () => {
      const content = capturePane(paneId);
      if (content !== prev) {
        prev = content;
        res.write(`data: ${JSON.stringify(content)}\n\n`);
      }
    };

    // Heartbeat every 15s so proxy doesn't kill idle SSE
    const beat = () => res.write(': heartbeat\n\n');

    send();
    const dataTimer = setInterval(send, 500);
    const hbTimer   = setInterval(beat, 15000);
    req.on('close', () => { clearInterval(dataTimer); clearInterval(hbTimer); });
    return;
  }

  // ── /api/send  POST { id, keys, enter? } ──────────────────────────
  if (url.pathname === '/api/send' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; if (body.length > 4096) req.destroy(); });
    req.on('end', () => {
      try {
        const { id, keys, enter = true } = JSON.parse(body);
        // Validate pane id: must be %N
        if (!/^%\d+$/.test(id)) throw new Error('invalid pane id');
        if (typeof keys !== 'string' || keys.length > 2048) throw new Error('invalid keys');
        const args = enter
          ? ['send-keys', '-t', id, keys, 'Enter']
          : ['send-keys', '-t', id, keys];
        execFileSync('tmux', args, { stdio: 'ignore' });
        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        res.end(JSON.stringify({ ok: true }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
        res.end(JSON.stringify({ ok: false, error: e.message }));
      }
    });
    return;
  }

  // ── /api/brain ─────────────────────────────────────────────────────
  if (url.pathname === '/api/brain') {
    try {
      const shouldRefresh = url.searchParams.get('refresh') === '1';
      const body = shouldRefresh || !fs.existsSync(BRAIN_INDEX)
        ? buildBrainIndex()
        : fs.readFileSync(BRAIN_INDEX, 'utf8');
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
        'Access-Control-Allow-Origin': '*',
      });
      res.end(body);
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
      res.end(JSON.stringify({ ok: false, error: 'brain index not available', path: BRAIN_INDEX, detail: e.message }));
    }
    return;
  }

  // ── Static files + friendly aliases ───────────────────────────────
  const aliases = {
    '/': '/terminals.html',
    '/dashboard': '/terminals.html',
    '/terminals': '/terminals.html',
    '/second-brain': '/second-brain.html',
    '/brain': '/second-brain.html',
    '/realtime-dashboard': '/realtime-dashboard.html',
    '/realtime': '/realtime-dashboard.html',
  };

  const rel = aliases[url.pathname] || url.pathname;
  const full = path.join(DASH_DIR, rel);

  // Prevent path traversal
  if (!full.startsWith(DASH_DIR)) { res.writeHead(403); res.end('Forbidden'); return; }

  try {
    const content = fs.readFileSync(full);
    res.writeHead(200, { 'Content-Type': MIME[path.extname(full)] || 'text/plain' });
    res.end(content);
  } catch {
    res.writeHead(404, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
    res.end(JSON.stringify({ error: 'Not found', path: url.pathname, hint: 'Try /terminals.html, /second-brain.html, or /realtime-dashboard.html' }));
  }
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use — stop the existing terminal server or choose another port.`);
  } else {
    console.error(err);
  }
  process.exit(1);
});

server.listen(PORT, () => {
  console.log(`\x1b[1;36m┌─────────────────────────────────────────┐\x1b[0m`);
  console.log(`\x1b[1;36m│  Omega OS Terminal Dashboard             │\x1b[0m`);
  console.log(`\x1b[1;36m│  http://localhost:${PORT}                    │\x1b[0m`);
  console.log(`\x1b[1;36m│  Session: ${SESSION.padEnd(30)}│\x1b[0m`);
  console.log(`\x1b[1;36m└─────────────────────────────────────────┘\x1b[0m`);
  const panes = getPanes();
  if (panes.length === 0) {
    console.log('\x1b[33m  ⚠ tmux session not running — start it first\x1b[0m');
  } else {
    console.log(`\x1b[32m  ✓ ${panes.length} panes detected:\x1b[0m`);
    panes.forEach(p => console.log(`    ${p.id.padEnd(6)} [${p.window}] ${p.name}`));
  }
});
