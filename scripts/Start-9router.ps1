# PowerShell launcher for 9router on Windows
# Usage: pwsh .\scripts\Start-9router.ps1
# Or: powershell -ExecutionPolicy Bypass -File "scripts\Start-9router.ps1"

param(
    [switch]$Status,
    [switch]$Stop,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ServiceName = '9router'
$RouterPort = 20128
$RouterHost = '0.0.0.0'
$RouterArgs = @('--port', "$RouterPort", '--host', $RouterHost, '--no-browser', '--tray', '--skip-update')
$RouterShimCmd = Join-Path $env:LOCALAPPDATA 'Volta\bin\9router.cmd'
$RouterShim = Join-Path $env:LOCALAPPDATA 'Volta\bin\9router'

Write-Host "🔧 9router Launcher (Windows)" -ForegroundColor Cyan
Write-Host ""

function Test-RouterApi {
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:$RouterPort/v1/models" -TimeoutSec 2 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-RouterLauncher {
    if (Test-Path $RouterShimCmd) {
        return $RouterShimCmd
    }
    if (Test-Path $RouterShim) {
        return $RouterShim
    }
    return $null
}

function Start-RouterDirect {
    $launcher = Get-RouterLauncher
    if (-not $launcher) {
        throw "Could not find 9router launcher under $env:LOCALAPPDATA\Volta\bin"
    }

    $argumentString = ($RouterArgs -join ' ')
    Write-Host "Launching 9router directly..." -ForegroundColor Yellow
    Write-Host "  $launcher $argumentString" -ForegroundColor Gray

    # Use cmd.exe so both .cmd and shell shim variants work from Windows PowerShell.
    Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', ('"' + $launcher + '" ' + $argumentString)) -WindowStyle Hidden | Out-Null
}

# Check service if present
$service = $null
try {
    $service = Get-Service -Name $ServiceName -ErrorAction Stop
} catch {
    $service = $null
}

$apiReady = Test-RouterApi
if ($Status) {
    if ($service) {
        $serviceColor = if ($service.Status -eq 'Running') { 'Green' } else { 'Yellow' }
        Write-Host "Service: $ServiceName" -ForegroundColor Cyan
        Write-Host "Status: $($service.Status)" -ForegroundColor $serviceColor
    } else {
        Write-Host "Service: $ServiceName (not installed)" -ForegroundColor Yellow
    }
    $apiState = if ($apiReady) { 'online' } else { 'offline' }
    $apiColor = if ($apiReady) { 'Green' } else { 'Yellow' }
    Write-Host "API: $apiState" -ForegroundColor $apiColor
    exit 0
}

if ($Stop) {
    if ($service) {
        Write-Host "Stopping $ServiceName..." -ForegroundColor Yellow
        Stop-Service -Name $ServiceName -Force
        Write-Host "✓ Service stopped" -ForegroundColor Green
    } else {
        Write-Host "No Windows service found. If 9router was started directly, close the process from Task Manager." -ForegroundColor Yellow
    }
    exit 0
}

if ($apiReady) {
    Write-Host "✅ 9router API already responding" -ForegroundColor Green
    Write-Host "   http://127.0.0.1:$RouterPort/v1/models" -ForegroundColor Cyan
    exit 0
}

if ($service) {
    if ($service.Status -eq 'Running') {
        if ($Force) {
            Write-Host "Force restarting service $ServiceName..." -ForegroundColor Yellow
            Restart-Service -Name $ServiceName -Force
        } else {
            Write-Host "Service $ServiceName is running; waiting for API..." -ForegroundColor Green
        }
    } else {
        Write-Host "Starting service $ServiceName..." -ForegroundColor Yellow
        Start-Service -Name $ServiceName
    }
} else {
    Start-RouterDirect
}

Write-Host ""
Write-Host "Waiting for 9router API on http://127.0.0.1:$RouterPort/v1/models ..." -ForegroundColor Cyan

$ready = $false
for ($i = 1; $i -le 30; $i++) {
    if (Test-RouterApi) {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 1
}

if ($ready) {
    Write-Host "✅ 9router is ready" -ForegroundColor Green
    Write-Host "   http://127.0.0.1:$RouterPort/v1/models" -ForegroundColor Cyan
    exit 0
}

Write-Host "❌ 9router did not become ready within 30 seconds" -ForegroundColor Red
Write-Host ""
Write-Host "If you are on Windows, try launching manually in PowerShell:" -ForegroundColor Yellow
Write-Host "  & `"$RouterShimCmd`" --port $RouterPort --host $RouterHost --no-browser --tray --skip-update" -ForegroundColor Gray
exit 1
