/**
 * Omega maw Plugin — Fleet orchestration, message relay, provider tracking
 * Integrates Omega Phase 10 with maw-js concepts (federation, transport, hooks, triggers)
 */

import type { InvokeContext, InvokeResult } from "@maw-js/sdk/plugin";
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";
import { execFile } from "child_process";

export const command = {
  name: "omega",
  description: "Omega fleet orchestration — fleet, relay, wake, alert, providers",
};

const REPO_ROOT = path.join(process.cwd(), "..");
const RESONANCE_DIR = path.join(REPO_ROOT, "ψ/memory/resonance");
const INBOX_ROOT = path.join(REPO_ROOT, "ψ/inbox");

export default async function handler(ctx: InvokeContext): Promise<InvokeResult> {
  const logs: string[] = [];
  const origLog = console.log;
  console.log = (...a: any[]) => {
    if (ctx.writer) ctx.writer(...a);
    else logs.push(a.map(String).join(" "));
  };

  try {
    if (ctx.source === "cli") {
      const args = ctx.args as string[];
      const sub = args[0] || "fleet";

      if (sub === "fleet") {
        await cmdFleet();
      } else if (sub === "relay") {
        await cmdRelay();
      } else if (sub === "wake") {
        const agent = args[1];
        if (!agent) throw new Error("Usage: maw omega wake <agent-id>");
        await cmdWake(agent);
      } else if (sub === "alert") {
        await cmdAlert();
      } else if (sub === "providers") {
        await cmdProviders();
      } else {
        throw new Error(`Unknown subcommand: ${sub}`);
      }
    }

    return { ok: true, output: logs.join("\n") || "✓ omega command executed" };
  } catch (e: any) {
    return { ok: false, error: e.message, output: logs.join("\n") || undefined };
  } finally {
    console.log = origLog;
  }
}

// Hook: fire on SessionStart, SessionEnd, MessageSend
export async function onEvent(event: any) {
  const logs: string[] = [];
  try {
    if (event.type === "SessionStart") {
      logs.push(`[omega] SessionStart: ${event.agent}`);
      // Write to session-events.jsonl
      const eventFile = path.join(RESONANCE_DIR, "session-events.jsonl");
      const entry = JSON.stringify({ type: "start", agent: event.agent, timestamp: new Date().toISOString() });
      fs.appendFileSync(eventFile, entry + "\n");
    } else if (event.type === "SessionEnd") {
      logs.push(`[omega] SessionEnd: ${event.agent}`);
      const eventFile = path.join(RESONANCE_DIR, "session-events.jsonl");
      const entry = JSON.stringify({ type: "end", agent: event.agent, timestamp: new Date().toISOString() });
      fs.appendFileSync(eventFile, entry + "\n");
    } else if (event.type === "MessageSend") {
      logs.push(`[omega] MessageSend: ${event.from} → ${event.to}`);
      // cc bob if cross-agent (rule 2 of oracle-communication-law)
      if (event.from !== event.to && event.from !== "bob") {
        const bobPath = path.join(INBOX_ROOT, "bob", `${Date.now()}_from-${event.from}.json`);
        fs.mkdirSync(path.dirname(bobPath), { recursive: true });
        fs.writeFileSync(bobPath, JSON.stringify({ ...event, cc: true, timestamp: new Date().toISOString() }, null, 2));
        logs.push(`[omega] cc bob on cross-agent message`);
      }
    }
  } catch (e: any) {
    logs.push(`[omega] Hook error: ${e.message}`);
  }
  return logs;
}

// Cron hook: fire every minute (* * * * *)
export async function onTick() {
  const logs: string[] = [];
  try {
    logs.push("[omega] onTick: probe + relay cycle");
    await cmdFleet();
    await cmdRelay();
  } catch (e: any) {
    logs.push(`[omega] Tick error: ${e.message}`);
  }
  return logs;
}

// Command: maw omega fleet — probe agents, get maw sessions, merge results
async function cmdFleet() {
  console.log("🔍 Probing agent fleet...");

  const registryPath = path.join(REPO_ROOT, "configs/agent-registry.json");
  const registry = JSON.parse(fs.readFileSync(registryPath, "utf8"));

  const mawSessions: Record<string, boolean> = {};
  try {
    const result = execSync("maw ls --json 2>/dev/null", { encoding: "utf8" });
    const sessions = JSON.parse(result);
    sessions.forEach((s: any) => {
      if (s.name) mawSessions[s.name] = true;
    });
    console.log(`✓ Found ${Object.keys(mawSessions).length} maw sessions`);
  } catch (e) {
    console.log("⚠ maw ls failed, continuing with port probes only");
  }

  // Probe ports for each agent
  const agents = registry.agents || [];
  const fleetStatus = {
    timestamp: new Date().toISOString(),
    agents: agents.map((agent: any) => {
      const hasSession = !!mawSessions[agent.id];
      const port = agent.port;
      let portReachable = false;

      if (port) {
        try {
          execSync(`timeout 1 bash -c "</dev/tcp/127.0.0.1/${port}" 2>/dev/null`, { stdio: "ignore" });
          portReachable = true;
        } catch (e) {
          portReachable = false;
        }
      }

      let availability = "unavailable";
      if (portReachable || hasSession) availability = "available";
      else if (hasSession) availability = "degraded";

      return {
        name: agent.id,
        soul: agent.soul || "No soul",
        role: agent.role || "unknown",
        specialty: agent.specialty || "General",
        capabilities: agent.capabilities || [],
        port: port || null,
        status: portReachable ? "connected" : hasSession ? "session-only" : "offline",
        available: availability !== "unavailable",
        maw_session_active: hasSession,
        last_heartbeat: new Date().toISOString(),
        task_count: 0,
      };
    }),
    relay_log: loadRelayLog(),
    message_queue: [],
    health_overall: "healthy",
  };

  // Write unified Format B
  const dateStr = new Date().toISOString().split("T")[0];
  const outputFile = path.join(RESONANCE_DIR, `fleet-status-${dateStr}.json`);
  fs.mkdirSync(path.dirname(outputFile), { recursive: true });
  fs.writeFileSync(outputFile, JSON.stringify(fleetStatus, null, 2));
  console.log(`✓ Fleet status saved: ${outputFile}`);
}

// Command: maw omega relay — scan inboxes, route messages, cc bob
async function cmdRelay() {
  console.log("📬 Routing inbox messages...");

  const relayLog: any[] = [];
  const processedHashes = loadProcessedHashes();

  // Scan all agent inboxes
  if (!fs.existsSync(INBOX_ROOT)) {
    console.log("⚠ No inbox root found");
    return;
  }

  const agents = fs.readdirSync(INBOX_ROOT).filter((d) => {
    const p = path.join(INBOX_ROOT, d);
    return fs.statSync(p).isDirectory();
  });

  for (const agent of agents) {
    const agentInbox = path.join(INBOX_ROOT, agent);
    const files = fs.readdirSync(agentInbox);

    for (const file of files) {
      if (file.startsWith(".")) continue;

      const filePath = path.join(agentInbox, file);
      const hash = `${agent}:${file}`;

      if (processedHashes[hash]) continue; // Already routed
      processedHashes[hash] = true;

      try {
        let msg: any = { timestamp: new Date().toISOString() };
        const content = fs.readFileSync(filePath, "utf8");

        if (file.endsWith(".json")) {
          msg = { ...JSON.parse(content), routing: { from: agent, timestamp: new Date().toISOString() } };
        } else {
          msg = { type: "text", content, routing: { from: agent, timestamp: new Date().toISOString() } };
        }

        const toAgent = msg.to_agent || msg.routing?.to || "tham";
        const targetInbox = path.join(INBOX_ROOT, toAgent);

        fs.mkdirSync(targetInbox, { recursive: true });
        const targetFile = path.join(targetInbox, `${Date.now()}_from-${agent}.json`);
        fs.writeFileSync(targetFile, JSON.stringify(msg, null, 2));

        relayLog.push({
          timestamp: new Date().toISOString(),
          source_agent: agent,
          target_agent: toAgent,
          message_id: file,
          status: "routed",
          notes: "",
        });

        // CC bob if cross-agent
        if (agent !== toAgent && toAgent !== "bob") {
          const bobInbox = path.join(INBOX_ROOT, "bob");
          fs.mkdirSync(bobInbox, { recursive: true });
          const bobFile = path.join(bobInbox, `${Date.now()}_cc-${agent}.json`);
          fs.writeFileSync(bobFile, JSON.stringify({ ...msg, cc: true }, null, 2));

          relayLog.push({
            timestamp: new Date().toISOString(),
            source_agent: agent,
            target_agent: "bob",
            message_id: file,
            status: "cc",
            notes: "cross-agent cc",
          });
        }

        console.log(`✓ Routed ${file} → ${toAgent}`);
      } catch (e: any) {
        relayLog.push({
          timestamp: new Date().toISOString(),
          source_agent: agent,
          target_agent: "unknown",
          message_id: file,
          status: "failed",
          notes: e.message,
        });
      }
    }
  }

  // Save relay log
  if (relayLog.length > 0) {
    const logFile = path.join(RESONANCE_DIR, "relay-log.jsonl");
    relayLog.forEach((entry) => {
      fs.appendFileSync(logFile, JSON.stringify(entry) + "\n");
    });

    // Update fleet-status relay_log array
    const dateStr = new Date().toISOString().split("T")[0];
    const fleetFile = path.join(RESONANCE_DIR, `fleet-status-${dateStr}.json`);
    if (fs.existsSync(fleetFile)) {
      const fleet = JSON.parse(fs.readFileSync(fleetFile, "utf8"));
      fleet.relay_log = (fleet.relay_log || []).concat(relayLog);
      fs.writeFileSync(fleetFile, JSON.stringify(fleet, null, 2));
    }

    console.log(`✓ Relayed ${relayLog.length} messages`);
  }

  // Save processed hashes
  saveProcessedHashes(processedHashes);
}

// Command: maw omega wake <agent> — call maw wake
async function cmdWake(agent: string) {
  console.log(`⏰ Waking ${agent}...`);
  try {
    execSync(`maw wake ${agent}`, { stdio: "inherit" });
    console.log(`✓ ${agent} woken`);
  } catch (e: any) {
    console.log(`⚠ maw wake failed: ${e.message}`);
  }
}

// Command: maw omega alert — dedup and summarize tham inbox alerts
async function cmdAlert() {
  console.log("🚨 Alert summary...");
  const thamInbox = path.join(INBOX_ROOT, "tham");
  if (!fs.existsSync(thamInbox)) {
    console.log("No tham inbox");
    return;
  }

  const alerts = fs.readdirSync(thamInbox).filter((f) => f.includes("fleet-alert"));
  const levels: Record<string, number> = {};

  alerts.forEach((f) => {
    const level = f.match(/fleet-alert-(\w+)/)?.[1] || "UNKNOWN";
    levels[level] = (levels[level] || 0) + 1;
  });

  console.log(`Alert summary: ${JSON.stringify(levels)}`);
}

// Command: maw omega providers — show provider status
async function cmdProviders() {
  console.log("📊 Provider status...");
  const dateStr = new Date().toISOString().split("T")[0];
  const providerFile = path.join(RESONANCE_DIR, `provider-status-${dateStr}.json`);

  if (fs.existsSync(providerFile)) {
    const status = JSON.parse(fs.readFileSync(providerFile, "utf8"));
    console.log(JSON.stringify(status, null, 2));
  } else {
    console.log("⚠ Provider status not yet generated");
  }
}

// Helpers

function loadRelayLog(): any[] {
  const logFile = path.join(RESONANCE_DIR, "relay-log.jsonl");
  if (!fs.existsSync(logFile)) return [];

  const lines = fs.readFileSync(logFile, "utf8").split("\n").filter((l) => l.trim());
  return lines.map((l) => {
    try {
      return JSON.parse(l);
    } catch (e) {
      return { error: e };
    }
  });
}

function loadProcessedHashes(): Record<string, boolean> {
  const hashFile = path.join(RESONANCE_DIR, "relay-processed.json");
  if (!fs.existsSync(hashFile)) return {};
  return JSON.parse(fs.readFileSync(hashFile, "utf8"));
}

function saveProcessedHashes(hashes: Record<string, boolean>) {
  const hashFile = path.join(RESONANCE_DIR, "relay-processed.json");
  fs.mkdirSync(path.dirname(hashFile), { recursive: true });
  fs.writeFileSync(hashFile, JSON.stringify(hashes, null, 2));
}
