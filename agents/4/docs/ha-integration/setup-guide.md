# HA Sensor Collector — Supabase Edge Function Setup

## Architecture

```
Home Assistant (GCE VM)
  └─ Automation (every 15 min)
       └─ REST POST → Supabase Edge Function
                          └─ INSERT → sensor_readings table
```

HA initiates outbound. No gcloud, no firewall changes needed.

## Step 1 — Deploy Edge Function

```bash
# from tham-oracle repo root
supabase functions deploy ha-sensor-ingest --project-ref <project-ref>
```

## Step 2 — Set Edge Function Secrets

Generate a random secret (keep this — goes in both Supabase and HA):
```bash
openssl rand -hex 32
```

Set it in Supabase:
```bash
supabase secrets set HA_INGEST_SECRET=<your-secret> --project-ref <project-ref>
```

## Step 3 — Configure HA

### secrets.yaml (HA config)
```yaml
ha_ingest_secret: "<your-secret>"
```

### configuration.yaml (add rest_command block)
```yaml
rest_command:
  supabase_ingest:
    url: "https://<project-ref>.supabase.co/functions/v1/ha-sensor-ingest"
    method: POST
    headers:
      Authorization: "Bearer {{ ingest_secret }}"
      Content-Type: "application/json"
    payload: "{{ payload }}"
    timeout: 30
```

### automations.yaml
Copy the content from `ha-automation-config.yaml` and adjust entity_ids to match your actual HA sensor entity IDs.

Then reload HA config or restart.

## Step 4 — Verify devices table has matching entity_ids

The Edge Function looks up `entity_id` in the `devices` table.
Devices seeded:
- `sensor.temperature_indoor`
- `sensor.humidity_indoor`
- `sensor.temperature_outdoor`

Adjust these to match your actual HA entity IDs.

```sql
-- check seeded devices
select entity_id, name, location from public.devices;
```

## Step 5 — Test manually

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/ha-sensor-ingest \
  -H "Authorization: Bearer <your-secret>" \
  -H "Content-Type: application/json" \
  -d '{
    "source": "manual_test",
    "readings": [{
      "entity_id": "sensor.temperature_indoor",
      "state": "25.5",
      "last_updated": "2026-05-13T10:00:00+07:00",
      "attributes": {"unit_of_measurement": "°C", "device_class": "temperature"}
    }]
  }'
```

Expected: `{"inserted":1,"skipped":[]}`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `{"error":"devices lookup failed"}` | Check project-ref and service_role key |
| `{"inserted":0,"skipped":["sensor.xxx"]}` | entity_id in devices table doesn't match HA entity_id |
| HA automation fails silently | Check HA logs: Settings > System > Logs, filter by `rest_command` |
| 401 Unauthorized | HA_INGEST_SECRET mismatch between Supabase secret and HA secrets.yaml |
