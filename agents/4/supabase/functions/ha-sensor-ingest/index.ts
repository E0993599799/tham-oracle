import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INGEST_SECRET = Deno.env.get("HA_INGEST_SECRET")!;

interface SensorReading {
  entity_id: string;
  state: string;
  last_updated: string;
  attributes?: Record<string, unknown>;
}

interface IngestPayload {
  readings: SensorReading[];
  source?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader || authHeader !== `Bearer ${INGEST_SECRET}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  let payload: IngestPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("Bad Request: invalid JSON", { status: 400 });
  }

  if (!Array.isArray(payload.readings) || payload.readings.length === 0) {
    return new Response("Bad Request: readings array required", { status: 400 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // resolve entity_id → device_id
  const entityIds = [...new Set(payload.readings.map((r) => r.entity_id))];
  const { data: devices, error: devErr } = await supabase
    .from("devices")
    .select("id, entity_id")
    .in("entity_id", entityIds);

  if (devErr) {
    console.error("devices lookup failed:", devErr.message);
    return new Response(
      JSON.stringify({ error: "devices lookup failed", detail: devErr.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const deviceMap = new Map<string, string>(
    (devices ?? []).map((d) => [d.entity_id, d.id]),
  );

  const rows = [];
  const skipped = [];

  for (const r of payload.readings) {
    const deviceId = deviceMap.get(r.entity_id);
    if (!deviceId) {
      skipped.push(r.entity_id);
      continue;
    }

    const numVal = parseFloat(r.state);
    if (isNaN(numVal)) {
      skipped.push(`${r.entity_id} (non-numeric: ${r.state})`);
      continue;
    }

    const metric = (r.attributes?.unit_of_measurement as string) ??
      (r.attributes?.device_class as string) ??
      "unknown";

    rows.push({
      timestamp: r.last_updated,
      device_id: deviceId,
      metric,
      value: numVal,
      attributes: r.attributes ?? null,
    });
  }

  if (rows.length === 0) {
    return new Response(
      JSON.stringify({ inserted: 0, skipped }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  }

  const { error: insertErr } = await supabase
    .from("sensor_readings")
    .insert(rows);

  if (insertErr) {
    console.error("insert failed:", insertErr.message);
    return new Response(
      JSON.stringify({ error: "insert failed", detail: insertErr.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({ inserted: rows.length, skipped }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
