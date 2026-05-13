Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

trap {
  try { Write-Host "[FATAL] $($_ | Out-String)" } catch {}
  exit 1
}

function New-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

function Assert-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) { throw "Missing required command: $Name" }
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

# ---------- Config ----------
$ProjectId   = $env:GCP_PROJECT_ID;               if ([string]::IsNullOrWhiteSpace($ProjectId))   { $ProjectId   = "daily-report-c7e73" }
$Zone        = $env:GCP_ZONE;                      if ([string]::IsNullOrWhiteSpace($Zone))        { $Zone        = "asia-southeast1-a" }
$VmName      = $env:GCP_VM_NAME;                   if ([string]::IsNullOrWhiteSpace($VmName))      { $VmName      = "temphumtest" }
$HaUrl       = $env:HOME_ASSISTANT_URL;            if ([string]::IsNullOrWhiteSpace($HaUrl))       { $HaUrl       = "http://127.0.0.1:8123" }
$HaToken     = $env:KEY_HOME_ASSIASTANT_LONG_LIVE; if ([string]::IsNullOrWhiteSpace($HaToken))     { throw "Set KEY_HOME_ASSIASTANT_LONG_LIVE" }
$SupUrl      = $env:SUPABASE_PROJECT_URL;          if ([string]::IsNullOrWhiteSpace($SupUrl))      { $SupUrl      = "https://antlziuiiyauhsswopac.supabase.co" }
$SupKey      = $env:SUPABASE_SERVICE_ROLE_KEY;     if ([string]::IsNullOrWhiteSpace($SupKey))      { throw "Set SUPABASE_SERVICE_ROLE_KEY" }
$TimerOnCalendar = if ($env:COLLECTOR_SCHEDULE) { $env:COLLECTOR_SCHEDULE } else { "*:0/15" }  # every 15 min default

# ---------- Paths ----------
$RepoRoot  = Get-Location | Select-Object -ExpandProperty Path
$ToolsDir  = Join-Path $RepoRoot "tools"
$LogsDir   = Join-Path $ToolsDir "logs"
New-Dir $ToolsDir
New-Dir $LogsDir

$Ts      = (Get-Date).ToString("yyyyMMdd_HHmmss")
$LogPath = Join-Path $LogsDir "sfsr_ha_collector_$Ts.log"

Start-Transcript -Path $LogPath -Force | Out-Null

try {
  Assert-Command "gcloud"

  Write-Host "[INFO] Project : $ProjectId"
  Write-Host "[INFO] Zone    : $Zone"
  Write-Host "[INFO] VM      : $VmName"
  Write-Host "[INFO] HA URL  : $HaUrl"
  Write-Host "[INFO] Sup URL : $SupUrl"
  Write-Host "[INFO] Timer   : $TimerOnCalendar"

  & gcloud config set project $ProjectId | Out-Host

  # ---- Write ha_data_collector.py locally ----
  $ScriptLocal = Join-Path $ToolsDir "ha_data_collector.py"
  $PythonScript = @'
import os, sys, json
from datetime import datetime
from dotenv import load_dotenv
import requests
from supabase import create_client, Client
from dateutil import tz

ENTITY_MAP = {
    "sensor.t_h_sensor_chanwaangyaa_nmaaengin": {
        "temperature": "sensor.t_h_sensor_chanwaangyaa_nmaaengin_temperature",
        "humidity":    "sensor.t_h_sensor_chanwaangyaa_nmaaengin_humidity",
    },
    "sensor.t_h_sensor_phuuenthiismaar_ngyaa": {
        "temperature": "sensor.t_h_sensor_phuuenthiismaar_ngyaa_temperature",
        "humidity":    "sensor.t_h_sensor_phuuenthiismaar_ngyaa_humidity",
    },
    "sensor.t_h_sensor_tuueyn_probe": {
        "temperature": "sensor.t_h_sensor_tuueyn_probe_temperature",
        "humidity":    "sensor.t_h_sensor_tuueyn_probe_humidity",
    },
}

def get_ha_state(base_url, token, entity_id):
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    try:
        r = requests.get(f"{base_url}/api/states/{entity_id}", headers=headers, timeout=10)
        r.raise_for_status()
        return r.json()
    except requests.exceptions.RequestException as e:
        print(f"  - ERROR fetching {entity_id}: {e}")
        return None

def main():
    print("--- HA Data Collector ---")
    dotenv_path = os.path.join(os.path.dirname(__file__), '..', '.env.local')
    if not os.path.exists(dotenv_path):
        print("FATAL: .env.local not found"); sys.exit(1)
    load_dotenv(dotenv_path=dotenv_path)

    sup_url  = os.environ.get("SUPABASE_PROJECT_URL")
    sup_key  = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    ha_url   = os.environ.get("HOME_ASSISTANT_URL")
    ha_token = os.environ.get("KEY_HOME_ASSIASTANT_LONG_LIVE")

    if not all([sup_url, sup_key, ha_url, ha_token]):
        print("FATAL: missing env vars"); sys.exit(1)

    supabase: Client = create_client(sup_url, sup_key)
    res = supabase.table("devices").select("id, entity_id").execute()
    if not res.data:
        print("FATAL: no devices in Supabase"); sys.exit(1)
    device_map = {d['entity_id']: d['id'] for d in res.data}
    print(f"  devices: {len(device_map)} found")

    ts = datetime.now(tz.gettz(os.environ.get("TZ", "Asia/Bangkok"))).isoformat()
    records = []

    for base_entity, metrics in ENTITY_MAP.items():
        device_uuid = device_map.get(base_entity)
        if not device_uuid:
            print(f"  WARN: {base_entity} not in DB, skipping"); continue
        for metric_name, full_entity_id in metrics.items():
            state = get_ha_state(ha_url, ha_token, full_entity_id)
            if state:
                try:
                    value = float(state.get('state', 0.0))
                    records.append({
                        "timestamp": ts, "device_id": device_uuid,
                        "metric": metric_name, "value": value,
                        "attributes": json.dumps(state.get('attributes', {})),
                    })
                    print(f"    {base_entity} {metric_name}: {value}")
                except (ValueError, TypeError):
                    print(f"    WARN: non-numeric state for {full_entity_id}")

    if records:
        supabase.table("sensor_readings").insert(records).execute()
        print(f"  inserted {len(records)} records")
    else:
        print("  no records to insert")
    return 0

if __name__ == "__main__":
    sys.exit(main())
'@
  Write-Utf8NoBom $ScriptLocal $PythonScript
  Write-Host "[INFO] Written: $ScriptLocal"

  # ---- Write .env.local locally (DO NOT COMMIT) ----
  $EnvLocal = Join-Path $ToolsDir ".env.local"
  $EnvContent = @"
SUPABASE_PROJECT_URL=$SupUrl
SUPABASE_SERVICE_ROLE_KEY=$SupKey
HOME_ASSISTANT_URL=$HaUrl
KEY_HOME_ASSIASTANT_LONG_LIVE=$HaToken
TZ=Asia/Bangkok
"@
  Write-Utf8NoBom $EnvLocal $EnvContent
  Write-Host "[INFO] Written: $EnvLocal (secrets — do not commit)"

  # ---- SCP files to VM ----
  Write-Host "[INFO] Uploading files to VM..."
  & gcloud compute scp $ScriptLocal "${VmName}:~/ha_collector/ha_data_collector.py" --zone $Zone --project $ProjectId | Out-Host
  & gcloud compute scp $EnvLocal    "${VmName}:~/.env.local"                         --zone $Zone --project $ProjectId | Out-Host

  # ---- Remote setup: venv + deps + systemd ----
  $RemoteSetup = @"
#!/usr/bin/env bash
set -euo pipefail
LOG=/tmp/ha_collector_setup.log
exec > >(tee -a "\$LOG") 2>&1
echo "[INFO] \$(date -Is) Remote setup start"

mkdir -p ~/ha_collector

# Python venv
if [ ! -d ~/ha_collector/venv ]; then
  python3 -m venv ~/ha_collector/venv
fi
~/ha_collector/venv/bin/pip install -q --upgrade pip
~/ha_collector/venv/bin/pip install -q supabase python-dotenv requests python-dateutil

# systemd service
UNIT=/etc/systemd/system/ha-collector.service
sudo tee "\$UNIT" > /dev/null <<'UNIT_EOF'
[Unit]
Description=Home Assistant Sensor Collector
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=%h/ha_collector
ExecStart=%h/ha_collector/venv/bin/python %h/ha_collector/ha_data_collector.py
StandardOutput=append:%h/ha_collector/collector.log
StandardError=append:%h/ha_collector/collector.log
UNIT_EOF

# systemd timer
TIMER=/etc/systemd/system/ha-collector.timer
sudo tee "\$TIMER" > /dev/null <<'TIMER_EOF'
[Unit]
Description=Run HA Sensor Collector every 15 min

[Timer]
OnCalendar=$TimerOnCalendar
Persistent=true
AccuracySec=5s

[Install]
WantedBy=timers.target
TIMER_EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ha-collector.timer

echo "[INFO] \$(date -Is) Setup done"
echo "[INFO] Timer status:"
sudo systemctl status ha-collector.timer --no-pager
"@

  $RemoteSetupLocal = Join-Path $ToolsDir "remote_ha_setup_$Ts.sh"
  Write-Utf8NoBom $RemoteSetupLocal $RemoteSetup

  & gcloud compute scp $RemoteSetupLocal "${VmName}:/tmp/ha_collector_remote_setup.sh" --zone $Zone --project $ProjectId | Out-Host
  & gcloud compute ssh $VmName --zone $Zone --project $ProjectId --command "bash /tmp/ha_collector_remote_setup.sh" | Out-Host

  # ---- Test run ----
  Write-Host "[INFO] Test run..."
  & gcloud compute ssh $VmName --zone $Zone --project $ProjectId --command "~/ha_collector/venv/bin/python ~/ha_collector/ha_data_collector.py" | Out-Host

  # ---- Verify: check sensor_readings ----
  Write-Host "[INFO] Verify: checking last 5 sensor_readings via SSH curl..."
  $VerifyCurl = "curl -s -X GET '${SupUrl}/rest/v1/sensor_readings?select=timestamp,metric,value&order=created_at.desc&limit=5' -H 'apikey: ${SupKey}' -H 'Authorization: Bearer ${SupKey}'"
  & gcloud compute ssh $VmName --zone $Zone --project $ProjectId --command $VerifyCurl | Out-Host

  Write-Host "[OK] Setup complete"
  Write-Host "[SUMMARY] Timer: ha-collector.timer (every 15 min)"
  Write-Host "[SUMMARY] Log:   ~/ha_collector/collector.log (on VM)"
  Write-Host "[SUMMARY] Local log: $LogPath"
  Write-Host "[REMINDER] Revoke and regenerate SUPABASE_ACCESS_TOKEN — it was exposed in chat"
}
catch {
  Write-Host "[FAIL] $($_.Exception.Message)"
  exit 1
}
finally {
  Stop-Transcript | Out-Null
}
