# PowerShell script to start/restart 9router service on Windows
# Usage: pwsh .\scripts\Start-9router.ps1
# Or: powershell -ExecutionPolicy Bypass -File "scripts\Start-9router.ps1"

param(
    [switch]$Status,
    [switch]$Stop,
    [switch]$Force
)

Write-Host "🔧 9router Service Manager (Windows)" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run PowerShell as Administrator and try again:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File 'scripts\Start-9router.ps1'" -ForegroundColor Yellow
    exit 1
}

$ServiceName = "9router"

# Check status
Write-Host "Checking $ServiceName service..."
try {
    $service = Get-Service -Name $ServiceName -ErrorAction Stop
    $currentStatus = $service.Status

    Write-Host "Service: $ServiceName"
    Write-Host "Status: $currentStatus" -ForegroundColor (if ($currentStatus -eq "Running") { "Green" } else { "Yellow" })
    Write-Host ""

    if ($Status) {
        Write-Host "Status check complete."
        exit 0
    }

    if ($Stop) {
        Write-Host "Stopping $ServiceName..."
        Stop-Service -Name $ServiceName -Force
        Write-Host "✓ Service stopped" -ForegroundColor Green
        exit 0
    }

    # Start or restart
    if ($currentStatus -eq "Running") {
        if ($Force) {
            Write-Host "Force restarting $ServiceName..."
            Restart-Service -Name $ServiceName -Force
            Write-Host "✓ Service restarted" -ForegroundColor Green
        } else {
            Write-Host "✓ $ServiceName is already running" -ForegroundColor Green
        }
    } else {
        Write-Host "Starting $ServiceName..."
        Start-Service -Name $ServiceName
        Write-Host "✓ Service started" -ForegroundColor Green
    }

    # Wait and verify
    Write-Host ""
    Write-Host "Waiting for service to stabilize..." -ForegroundColor Gray
    Start-Sleep -Seconds 2

    # Check API endpoint
    Write-Host "Checking API endpoint (http://localhost:20128/v1/models)..."
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:20128/v1/models" -TimeoutSec 2 -ErrorAction Stop
        Write-Host "✅ API is responding" -ForegroundColor Green
    } catch {
        Write-Host "⏳ API not responding yet (still initializing...)" -ForegroundColor Yellow
        Write-Host "   Try again in a few seconds"
    }

    Write-Host ""
    Write-Host "Dashboard: http://localhost:20128/dashboard" -ForegroundColor Cyan

} catch {
    Write-Host "❌ Error: Service '$ServiceName' not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure 9router is installed on this Windows machine." -ForegroundColor Yellow
    exit 1
}
