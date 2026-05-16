# Catch ephemeral PowerShell windows — runs 1 minute, logs source + count
$startTime = Get-Date
$duration = 60  # seconds
$log = @()
$tracked = @{}

Write-Host "🔍 Monitoring for PowerShell popups (60 sec)..." -ForegroundColor Cyan

while ((Get-Date) - $startTime -lt (New-TimeSpan -Seconds $duration)) {
    Get-Process powershell -ErrorAction SilentlyContinue | ForEach-Object {
        $pid = $_.Id
        $cmdline = (Get-WmiObject Win32_Process -Filter "ProcessId=$pid" -ErrorAction SilentlyContinue).CommandLine

        if ($cmdline -and -not $tracked[$pid]) {
            # Extract parent process
            $parentId = (Get-WmiObject Win32_Process -Filter "ProcessId=$pid" -ErrorAction SilentlyContinue).ParentProcessId
            $parentProc = Get-Process -Id $parentId -ErrorAction SilentlyContinue
            $source = $parentProc.ProcessName ?? "unknown"

            $tracked[$pid] = @{
                StartTime = Get-Date
                CommandLine = $cmdline
                Source = $source
            }

            Write-Host "  ✓ PID $pid spawned from [$source]" -ForegroundColor Green
        }
    }

    # Check for dead processes (popups that closed)
    $deadPids = $tracked.Keys | Where-Object { -not (Get-Process -Id $_ -ErrorAction SilentlyContinue) }
    $deadPids | ForEach-Object {
        $info = $tracked[$_]
        $duration = (Get-Date) - $info.StartTime
        $log += [PSCustomObject]@{
            PID = $_
            Source = $info.Source
            Duration = "{0:F1}s" -f $duration.TotalSeconds
            CommandLine = $info.CommandLine
        }

        Write-Host "  ✗ PID $_ closed after {0:F1}s from [$($info.Source)]" -ForegroundColor Yellow
        $tracked.Remove($_)
    }

    Start-Sleep -Milliseconds 500
}

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "   Total ephemeral popups: $($log.Count)" -ForegroundColor Magenta
if ($log.Count -gt 0) {
    Write-Host "`n   By source:" -ForegroundColor Cyan
    $log | Group-Object Source | ForEach-Object {
        Write-Host "      $($_.Name): $($_.Count) popups" -ForegroundColor Green
    }

    Write-Host "`n   Details:" -ForegroundColor Cyan
    $log | Select-Object PID, Source, Duration | Format-Table -AutoSize
}

# Save log
$logPath = "C:\Users\User\Desktop\powershell-popups-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$log | Export-Csv $logPath -NoTypeInformation
Write-Host "`n   Log saved: $logPath" -ForegroundColor Gray
