# Safe disk cleanup for C:\ drive
# ธาม — Find + preview large files before deleting
# Requires: Run as Administrator

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logPath = "C:\ProgramData\ThamOracle\logs\cleanup-$timestamp.log"

if (-not (Test-Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}

function Log {
    param([string]$Message)
    $msg = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $msg
    Add-Content -Path $logPath -Value $msg
}

$isAdmin = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Must run as Administrator"
    exit 1
}

Log "=== C:\ Disk Cleanup Scanner ==="

# Safe targets to clean (low risk)
$cleanupTargets = @(
    @{
        Path = "C:\Windows\Temp"
        Name = "Windows Temp"
        Risk = "✅ SAFE"
    },
    @{
        Path = "C:\Windows\Prefetch"
        Name = "Windows Prefetch"
        Risk = "✅ SAFE"
    },
    @{
        Path = "C:\ProgramData\Temp"
        Name = "ProgramData Temp"
        Risk = "✅ SAFE"
    },
    @{
        Path = "$env:LOCALAPPDATA\Temp"
        Name = "User Temp"
        Risk = "✅ SAFE"
    },
    @{
        Path = "C:\ProgramData\Package Cache"
        Name = "Windows Install Cache"
        Risk = "✅ SAFE"
    },
    @{
        Path = "$env:LOCALAPPDATA\npm-cache"
        Name = "NPM Cache"
        Risk = "✅ SAFE"
    },
    @{
        Path = "$env:USERPROFILE\.bun\install\cache"
        Name = "Bun Cache"
        Risk = "✅ SAFE"
    },
    @{
        Path = "$env:LOCALAPPDATA\Ollama"
        Name = "Ollama Cache (older models)"
        Risk = "⚠️  CHECK FIRST"
    }
)

Write-Host ""
Write-Host "=== DISK USAGE ANALYSIS ===" -ForegroundColor Cyan
Write-Host ""

$totalSize = 0
$items = @()

foreach ($target in $cleanupTargets) {
    $path = $target.Path

    if (Test-Path $path) {
        try {
            $size = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum

            if ($null -eq $size) { $size = 0 }

            $sizeGB = [math]::Round($size / 1GB, 2)
            $sizeMB = [math]::Round($size / 1MB, 2)

            if ($size -gt 0) {
                $items += @{
                    Name = $target.Name
                    Path = $path
                    Size = $size
                    SizeDisplay = if ($sizeGB -ge 1) { "$sizeGB GB" } else { "$sizeMB MB" }
                    Risk = $target.Risk
                }
                $totalSize += $size
            }
        }
        catch {
            Log "⚠️  Could not scan: $path"
        }
    }
}

# Sort by size (largest first)
$items = $items | Sort-Object -Property Size -Descending

foreach ($item in $items) {
    Write-Host "$($item.Risk) | $($item.SizeDisplay.PadRight(10)) | $($item.Name)" -ForegroundColor Yellow
    Write-Host "    Path: $($item.Path)" -ForegroundColor Gray
}

Write-Host ""
$totalGB = [math]::Round($totalSize / 1GB, 2)
Write-Host "TOTAL AVAILABLE: $totalGB GB" -ForegroundColor Green
Write-Host ""

# Ask user
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "[1] Show detailed breakdown"
Write-Host "[2] Delete ALL safe targets (auto-confirm)"
Write-Host "[3] Cancel"
Write-Host ""

$choice = Read-Host "Choose [1-3]"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=== DETAILED BREAKDOWN ===" -ForegroundColor Cyan
        foreach ($item in $items) {
            Write-Host ""
            Write-Host "📁 $($item.Name) | $($item.SizeDisplay)" -ForegroundColor Yellow
            Write-Host "   Risk: $($item.Risk)"
            Write-Host "   Path: $($item.Path)"

            # Show sample files
            $files = Get-ChildItem -Path $item.Path -Force -ErrorAction SilentlyContinue |
                     Sort-Object -Property Length -Descending | Select-Object -First 5

            if ($files) {
                Write-Host "   Top 5 files:"
                foreach ($file in $files) {
                    $fileSize = [math]::Round($file.Length / 1MB, 2)
                    Write-Host "     - $($file.Name) ($fileSize MB)"
                }
            }
        }
        Write-Host ""
        $confirm = Read-Host "Proceed with cleanup? (yes/no)"
        if ($confirm -eq "yes") {
            goto DELETE
        }
        exit 0
    }

    "2" {
        goto DELETE
    }

    "3" {
        Write-Host "Cancelled."
        exit 0
    }
}

:DELETE
Write-Host ""
Write-Host "⚠️  FINAL CONFIRMATION" -ForegroundColor Red
Write-Host "Will delete $totalGB GB from:"
foreach ($item in $items) {
    Write-Host "  • $($item.Name)"
}
Write-Host ""
$final = Read-Host "Type 'DELETE' to confirm"

if ($final -ne "DELETE") {
    Write-Host "❌ Cancelled."
    exit 0
}

Write-Host ""
Log "=== Starting deletion ==="

$deletedSize = 0
foreach ($item in $items) {
    try {
        Write-Host "🗑️  Deleting: $($item.Name)..." -ForegroundColor Yellow
        Log "Deleting: $($item.Path)"

        Get-ChildItem -Path $item.Path -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

        Log "✅ DELETED: $($item.Name)"
        $deletedSize += $item.Size
    }
    catch {
        Log "❌ Failed to delete: $($item.Name) - $_"
        Write-Host "⚠️  Could not delete: $($item.Name)" -ForegroundColor Red
    }
}

$deletedGB = [math]::Round($deletedSize / 1GB, 2)
Write-Host ""
Write-Host "✅ Cleanup complete!" -ForegroundColor Green
Write-Host "Freed: $deletedGB GB"
Write-Host "Log: $logPath"
Log "=== Cleanup complete - freed $deletedGB GB ==="
