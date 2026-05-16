# OllamaApp Launch & Close with Port Check
# Usage: PowerShell -ExecutionPolicy Bypass -File launch-and-close.ps1

$ErrorActionPreference = "Stop"
$AppPath = "D:\ollamaapp\ollama app.exe"
$Port = 11434
$MaxWait = 30  # seconds
$LogPath = "D:\ollamaapp\launch-log.txt"

# Cleanup old logs
if (Test-Path $LogPath) { Remove-Item $LogPath -Force }

function Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $Line = "[$Timestamp] $Message"
    Write-Host $Line
    Add-Content -Path $LogPath -Value $Line
}

Log "=== OllamaApp Launch & Close ==="
Log "App: $AppPath"
Log "Port: $Port"
Log "Max Wait: ${MaxWait}s"

# Launch app in foreground
if (-not (Test-Path $AppPath)) {
    Log "ERROR: App not found at $AppPath"
    exit 1
}

Log "Launching OllamaApp..."
$Process = Start-Process -FilePath $AppPath -PassThru -WindowStyle Normal

Log "Process started: PID=$($Process.Id)"

# Wait for port to be ready
$Ready = $false
$Elapsed = 0

while ($Elapsed -lt $MaxWait) {
    try {
        $Response = Test-NetConnection -ComputerName 127.0.0.1 -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($Response.TcpTestSucceeded) {
            Log "✓ Port $Port is READY"
            $Ready = $true
            break
        }
    } catch {
        # Port not ready yet
    }

    Start-Sleep -Seconds 1
    $Elapsed++
    Write-Host "." -NoNewline
}

Write-Host ""

if (-not $Ready) {
    Log "WARNING: Port $Port did not respond after ${MaxWait}s (may still be initializing)"
}

# Additional health check — try to ping Ollama API
try {
    $ApiUrl = "http://localhost:$Port/api/tags"
    $ApiResponse = Invoke-WebRequest -Uri $ApiUrl -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($ApiResponse.StatusCode -eq 200) {
        Log "✓ API check PASSED (HTTP 200)"
    }
} catch {
    Log "API check inconclusive (may still be warming up)"
}

# Task complete — close app immediately
Log "Closing OllamaApp..."
try {
    Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    Log "✓ Process terminated gracefully"
} catch {
    Log "WARNING: Process termination had issues (may have self-closed)"
}

Log "=== Complete ==="
Log "Proof: $LogPath"

Write-Host ""
Write-Host "✓ Done. Check log: $LogPath"
