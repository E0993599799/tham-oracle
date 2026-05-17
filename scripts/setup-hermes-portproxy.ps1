# Setup Hermes portproxy — WSL ↔ Windows routing for 9router
# Run this in Windows PowerShell (Admin)
# Purpose: Allow WSL to access Windows 9router on localhost:20128

Write-Host "🔧 Hermes Portproxy Setup — WSL ↔ Windows" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match "S-1-5-32-544")
if (-not $isAdmin) {
    Write-Host "❌ ABORT: Must run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell → Run as administrator → paste script again" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Get WSL IP
Write-Host "📡 Finding WSL IPv4 address..." -ForegroundColor Blue
$wslIp = (wsl hostname -I).Trim() -split '\s+' | Select-Object -First 1

if (-not $wslIp) {
    Write-Host "❌ Failed to detect WSL IP" -ForegroundColor Red
    Write-Host "   Check: wsl --list --verbose (is WSL2 running?)" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ WSL IP: $wslIp" -ForegroundColor Green
Write-Host ""

# Port config
$windowsPort = 20128
$wslPort = 20128

Write-Host "📍 Portproxy Config:" -ForegroundColor Blue
Write-Host "   Windows port: $windowsPort → WSL $wslIp`:$wslPort"
Write-Host ""

# Delete existing rule (if any)
Write-Host "🔄 Clearing old rules..." -ForegroundColor Blue
netsh interface portproxy delete v4tov4 listenport=$windowsPort listenaddress=127.0.0.1 2>$null | Out-Null
netsh interface portproxy delete v4tov4 listenport=$windowsPort listenaddress=0.0.0.0 2>$null | Out-Null

# Add new portproxy rule
Write-Host "⚙️  Adding new portproxy rule..." -ForegroundColor Blue
netsh interface portproxy add v4tov4 listenport=$windowsPort listenaddress=127.0.0.1 connectport=$wslPort connectaddress=$wslIp

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Portproxy rule added" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to add portproxy rule (exit code: $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🧪 Testing..." -ForegroundColor Blue

# List all portproxy rules
Write-Host "📋 Current portproxy rules:" -ForegroundColor Cyan
netsh interface portproxy show all

Write-Host ""
Write-Host "✅ Hermes portproxy READY!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. In WSL: nc -zv 127.0.0.1 20128" -ForegroundColor Yellow
Write-Host "2. If ✅: Hermes can reach 9router" -ForegroundColor Yellow
Write-Host "3. Check: curl http://127.0.0.1:20128/status" -ForegroundColor Yellow
Write-Host ""
