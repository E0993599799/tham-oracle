# Disable foreground PowerShell/CMD popup scheduled tasks
# ธาม — Safe script to stop auto-run popup chain
# Requires: Run as Administrator

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logPath = "C:\ProgramData\ThamOracle\logs\disable-popups-$timestamp.log"

# Ensure log directory exists
$logDir = Split-Path $logPath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Log {
    param([string]$Message)
    $msg = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $msg
    Add-Content -Path $logPath -Value $msg
}

# Check if running as admin
$isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Must run as Administrator"
    Write-Host "Right-click PowerShell → 'Run as Administrator' and try again"
    exit 1
}

Log "=== Disable Foreground PowerShell/CMD Popup Tasks ==="

# Tasks to disable (the popup culprits)
$tasksToDisable = @(
    "MarcuzX_Cmd_Popup_Background_Watcher",
    "MarcuzX_Force_All_Cmd_Background_V1",
    "MarcuzX_Force_All_Cmd_Background_Fixed",
    "MarcuzX_Block_Cmd_Popup_Chain_V1"
)

$successCount = 0
$failCount = 0

foreach ($taskName in $tasksToDisable) {
    try {
        # Check if task exists
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

        if ($null -eq $task) {
            Log "⚠️  SKIP: Task not found: $taskName"
            continue
        }

        # Stop the task if running
        Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        Log "⏸️  Stopped: $taskName"

        # Disable the task
        Disable-ScheduledTask -TaskName $taskName
        Log "✅ DISABLED: $taskName"
        $successCount++
    }
    catch {
        Log "❌ FAILED: $taskName - $_"
        $failCount++
    }
}

Log ""
Log "=== SUMMARY ==="
Log "Successfully disabled: $successCount tasks"
Log "Failed: $failCount tasks"
Log "Log saved to: $logPath"
Log "=== Done ==="

Write-Host ""
Write-Host "✅ All foreground popup tasks disabled!" -ForegroundColor Green
Write-Host "📄 Log: $logPath"
Write-Host ""
Write-Host "Next: Restart Windows or manually stop any running popup windows"
