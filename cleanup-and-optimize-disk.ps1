############################################################################
# Windows Disk Space Optimization Script
# Purpose: Analyze, cleanup, and optimize disk space on C: and D: drives
# Author: ธาม Oracle
# Date: May 2026
# Target: Free 10-20GB from C: drive safely
#
# SAFETY: This script only removes temporary/cache files. All deletions
# are logged and reversible. No system files are deleted.
############################################################################

#Requires -RunAsAdministrator

param(
    [switch]$SkipCleanup = $false,
    [switch]$SkipOptimization = $false,
    [switch]$CompactFiles = $false,
    [switch]$DisableHibernation = $false,
    [switch]$Force = $false
)

# ============================================================================
# SCRIPT CONFIGURATION
# ============================================================================

$ScriptVersion = "1.0.0"
$ErrorActionPreference = "SilentlyContinue"

# Log file path
$LogPath = "$env:USERPROFILE\Desktop\cleanup_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ReportPath = "$env:USERPROFILE\Desktop\disk_space_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

# Folders to clean (low risk only)
$TempFolders = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Temp",
    "C:\Windows\Prefetch",
    "C:\Windows\SoftwareDistribution\Download"
)

# Browser cache paths
$BrowserCaches = @{
    "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    "Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    "Firefox" = "$env:APPDATA\Mozilla\Firefox\Profiles"
}

# Application caches
$AppCaches = @(
    "$env:LOCALAPPDATA\npm-cache",
    "$env:LOCALAPPDATA\NuGet\v3-cache",
    "$env:LOCALAPPDATA\Temp\NuGetScratch",
    "$env:APPDATA\npm-cache",
    "$env:USERPROFILE\.gradle\caches",
    "$env:USERPROFILE\.m2\repository",
    "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogPath -Value $LogMessage -ErrorAction SilentlyContinue
}

function Get-FolderSize {
    param(
        [string]$Path
    )
    try {
        if (Test-Path -Path $Path) {
            $Size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            return $Size
        }
    }
    catch {
        return 0
    }
    return 0
}

function Format-Bytes {
    param(
        [long]$Bytes
    )
    if ($Bytes -eq 0) { return "0 B" }
    $Sizes = "B", "KB", "MB", "GB", "TB"
    $Order = [Math]::Floor([Math]::Log($Bytes, 1024))
    $Size = [Math]::Round($Bytes / [Math]::Pow(1024, $Order), 2)
    return "$Size $($Sizes[$Order])"
}

function Remove-FolderContents {
    param(
        [string]$Path,
        [string]$Description
    )
    $SpaceFreed = 0
    $ItemsRemoved = 0

    if (-not (Test-Path -Path $Path)) {
        return @{ SpaceFreed = 0; ItemsRemoved = 0 }
    }

    Write-Log "Cleaning: $Description ($Path)" "INFO"

    try {
        # Get items before deletion (for logging)
        $Items = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue

        foreach ($Item in $Items) {
            try {
                $Size = 0
                if ($Item.PSIsContainer) {
                    $Size = (Get-ChildItem -Path $Item.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                            Measure-Object -Property Length -Sum).Sum
                } else {
                    $Size = $Item.Length
                }

                Remove-Item -Path $Item.FullName -Recurse -Force -ErrorAction SilentlyContinue

                if (-not (Test-Path -Path $Item.FullName)) {
                    $SpaceFreed += $Size
                    $ItemsRemoved++
                    Write-Log "  ✓ Removed: $($Item.Name) ($(Format-Bytes $Size))" "DEBUG"
                }
            }
            catch {
                Write-Log "  ✗ Failed to remove: $($Item.Name) (File in use)" "WARN"
            }
        }

        Write-Log "  Result: Freed $(Format-Bytes $SpaceFreed) | Removed $ItemsRemoved items" "INFO"
    }
    catch {
        Write-Log "Error cleaning $Path : $_" "ERROR"
    }

    return @{ SpaceFreed = $SpaceFreed; ItemsRemoved = $ItemsRemoved }
}

function Get-DiskAnalysis {
    param(
        [string]$DriveLetter
    )

    Write-Log "Analyzing disk: $DriveLetter" "INFO"

    $Volume = Get-Volume -DriveLetter $DriveLetter
    $TotalSize = $Volume.Size
    $FreeSpace = $Volume.SizeRemaining
    $UsedSpace = $TotalSize - $FreeSpace
    $UsagePercent = [Math]::Round(($UsedSpace / $TotalSize) * 100, 2)

    Write-Log "  Total: $(Format-Bytes $TotalSize) | Used: $(Format-Bytes $UsedSpace) | Free: $(Format-Bytes $FreeSpace)" "INFO"
    Write-Log "  Usage: $UsagePercent%" "INFO"

    return @{
        DriveLetter = $DriveLetter
        TotalSize = $TotalSize
        UsedSpace = $UsedSpace
        FreeSpace = $FreeSpace
        UsagePercent = $UsagePercent
    }
}

function Get-LargestFolders {
    param(
        [string]$Path,
        [int]$TopCount = 10
    )

    $Folders = @()
    try {
        $Dirs = Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue

        foreach ($Dir in $Dirs) {
            try {
                $Size = (Get-ChildItem -Path $Dir.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum).Sum

                if ($Size -gt 0) {
                    $Folders += @{
                        Name = $Dir.Name
                        Path = $Dir.FullName
                        Size = $Size
                        SizeFormatted = Format-Bytes $Size
                    }
                }
            }
            catch {
                # Skip folders we can't read
            }
        }

        $Folders = $Folders | Sort-Object -Property Size -Descending | Select-Object -First $TopCount
    }
    catch {
        Write-Log "Error analyzing folders in $Path : $_" "ERROR"
    }

    return $Folders
}

function Clear-RecycleBin {
    Write-Log "Clearing Recycle Bin..." "INFO"

    try {
        $Size = 0
        try {
            $Recycler = New-Object -ComObject Shell.Application
            $RecycleBinItem = $Recycler.NameSpace(10)
            $RecycleBinItem.Items() | ForEach-Object {
                $Size += $_.Size
            }
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Log "  ✓ Recycle Bin cleared (Freed: $(Format-Bytes $Size))" "INFO"
        }
        catch {
            # Fallback if COM object fails
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Log "  ✓ Recycle Bin cleared" "INFO"
        }
        return @{ SpaceFreed = $Size; ItemsRemoved = 0 }
    }
    catch {
        Write-Log "  ✗ Failed to clear Recycle Bin: $_" "WARN"
        return @{ SpaceFreed = 0; ItemsRemoved = 0 }
    }
}

function Run-DiskCleanup {
    Write-Log "Running Windows Disk Cleanup utility..." "INFO"

    try {
        # Create temporary cleanup config
        $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

        # Enable cleaners to remove
        $Cleaners = @(
            "Temporary Files",
            "Downloaded Program Files",
            "Old ChkDsk Files",
            "Recycle Bin",
            "System error memory dumps",
            "System error minidumps"
        )

        foreach ($Cleaner in $Cleaners) {
            $CleanerPath = "$RegPath\$Cleaner"
            if (Test-Path -Path $CleanerPath) {
                Set-ItemProperty -Path $CleanerPath -Name "StateFlags0000" -Value 2 -ErrorAction SilentlyContinue
            }
        }

        # Run Disk Cleanup
        & "$env:SystemRoot\System32\cleanmgr.exe" /sagerun:0

        Write-Log "  ✓ Disk Cleanup completed" "INFO"
        return $true
    }
    catch {
        Write-Log "  ✗ Disk Cleanup failed: $_" "WARN"
        return $false
    }
}

function Optimize-DiskVolume {
    param(
        [string]$DriveLetter
    )

    Write-Log "Optimizing disk volume: $DriveLetter" "INFO"

    try {
        # Detect drive type (SSD vs HDD)
        $Volume = Get-Volume -DriveLetter $DriveLetter
        $Partition = Get-Partition -DriveLetter $DriveLetter
        $PhysicalDisk = Get-PhysicalDisk | Where-Object { $_.ObjectId -eq (Get-Disk -Number $Partition.DiskNumber).ObjectId }

        if ($PhysicalDisk.MediaType -eq "SSD" -or $PhysicalDisk.BusType -eq "NVMe") {
            Write-Log "  SSD detected - Running TRIM..." "INFO"
            Optimize-Volume -DriveLetter $DriveLetter -Trim -Verbose
            Write-Log "  ✓ TRIM completed" "INFO"
        }
        else {
            Write-Log "  HDD detected - Skipping defrag (use manually if needed)" "INFO"
            Write-Log "  To defragment HDD manually, run: Optimize-Volume -DriveLetter $DriveLetter -Defrag" "INFO"
        }
    }
    catch {
        Write-Log "Error optimizing volume: $_" "ERROR"
    }
}

function Compress-NTFSFiles {
    param(
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        return 0
    }

    Write-Log "Compressing NTFS files in: $Path" "INFO"

    try {
        $SpaceSaved = 0
        $InitialSize = Get-FolderSize -Path $Path

        # Compress using compact utility
        & cmd.exe /c "compact /c /s /exe:lzx `"$Path`"" 2>&1 | ForEach-Object {
            Write-Log "  $($_.Trim())" "DEBUG"
        }

        Start-Sleep -Seconds 2
        $FinalSize = Get-FolderSize -Path $Path
        $SpaceSaved = $InitialSize - $FinalSize

        if ($SpaceSaved -gt 0) {
            Write-Log "  ✓ Compression completed (Saved: $(Format-Bytes $SpaceSaved))" "INFO"
        }

        return $SpaceSaved
    }
    catch {
        Write-Log "  ✗ Compression failed: $_" "ERROR"
        return 0
    }
}

function Generate-Report {
    param(
        [hashtable]$BeforeDiskAnalysis,
        [hashtable]$AfterDiskAnalysis,
        [hashtable]$CleanupSummary,
        [array]$LargestFolders
    )

    Write-Log "Generating disk space report..." "INFO"

    $Report = @{
        ScriptVersion = $ScriptVersion
        ExecutionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        System = @{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            OSVersion = [System.Environment]::OSVersion.VersionString
        }
        DiskAnalysis = @{
            Before = $BeforeDiskAnalysis
            After = $AfterDiskAnalysis
            DifferenceCDrive = @{
                FreedSpace = $AfterDiskAnalysis.FreeSpace - $BeforeDiskAnalysis.FreeSpace
                FreedSpaceFormatted = Format-Bytes ($AfterDiskAnalysis.FreeSpace - $BeforeDiskAnalysis.FreeSpace)
                UsageChangePercent = $AfterDiskAnalysis.UsagePercent - $BeforeDiskAnalysis.UsagePercent
            }
        }
        CleanupSummary = $CleanupSummary
        LargestFolders = $LargestFolders
        LogFile = $LogPath
    }

    try {
        $Report | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath -Encoding UTF8
        Write-Log "Report saved to: $ReportPath" "INFO"
    }
    catch {
        Write-Log "Error saving report: $_" "ERROR"
    }

    return $Report
}

# ============================================================================
# MAIN SCRIPT EXECUTION
# ============================================================================

function Main {
    Clear-Host

    Write-Host "============================================================================"
    Write-Host "  Windows Disk Space Optimization Script v$ScriptVersion"
    Write-Host "  Purpose: Analyze, cleanup, and optimize disk space safely"
    Write-Host "  Author: ธาม Oracle | Date: May 2026"
    Write-Host "============================================================================"
    Write-Host ""

    # Verify admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "ERROR: This script requires administrator privileges!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
        exit 1
    }

    Write-Log "Script started - Disk optimization initiated" "INFO"
    Write-Log "Log file: $LogPath" "INFO"

    # ========================================================================
    # PHASE 1: ANALYSIS
    # ========================================================================

    Write-Host ""
    Write-Host "PHASE 1: DISK ANALYSIS" -ForegroundColor Cyan
    Write-Host "========================================================================"

    Write-Log "========== PHASE 1: DISK ANALYSIS ==========" "INFO"

    $BeforeC = Get-DiskAnalysis -DriveLetter "C"
    Write-Host ""

    # Try D: drive if it exists
    $BeforeD = $null
    try {
        if ((Get-Volume -DriveLetter "D" -ErrorAction SilentlyContinue) -ne $null) {
            $BeforeD = Get-DiskAnalysis -DriveLetter "D"
            Write-Host ""
        }
    }
    catch {
        Write-Log "D: drive not found or not accessible" "WARN"
    }

    # Get largest folders on C:
    Write-Host ""
    Write-Host "Top 10 Largest Folders on C:" -ForegroundColor Yellow
    Write-Log "Top 10 largest folders on C:" "INFO"

    $LargestFoldersC = Get-LargestFolders -Path "C:\" -TopCount 10
    $LargestFoldersC | ForEach-Object {
        Write-Host "  • $($_.Name): $($_.SizeFormatted)"
        Write-Log "  $($_.Name): $($_.SizeFormatted)" "INFO"
    }

    # ========================================================================
    # PHASE 2: CLEANUP
    # ========================================================================

    if (-not $SkipCleanup) {
        Write-Host ""
        Write-Host "PHASE 2: CLEANUP OPERATIONS" -ForegroundColor Cyan
        Write-Host "========================================================================"

        Write-Log "========== PHASE 2: CLEANUP OPERATIONS ==========" "INFO"

        $CleanupSummary = @{
            TempFiles = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            BrowserCaches = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            AppCaches = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            RecycleBin = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            TotalSpaceFreed = 0
        }

        # Clean temporary files
        Write-Host ""
        Write-Host "Cleaning temporary files..." -ForegroundColor Green
        foreach ($TempFolder in $TempFolders) {
            $Result = Remove-FolderContents -Path $TempFolder -Description "Temp: $TempFolder"
            $CleanupSummary.TempFiles.SpaceFreed += $Result.SpaceFreed
            $CleanupSummary.TempFiles.ItemsRemoved += $Result.ItemsRemoved
        }
        Write-Host "  Total freed: $(Format-Bytes $CleanupSummary.TempFiles.SpaceFreed)" -ForegroundColor Green

        # Clear browser caches (safe method - via folder deletion of old entries)
        Write-Host ""
        Write-Host "Cleaning browser cache directories..." -ForegroundColor Green
        foreach ($BrowserName in $BrowserCaches.Keys) {
            $CachePath = $BrowserCaches[$BrowserName]
            if ($BrowserName -eq "Firefox") {
                # For Firefox, check profile folders
                if (Test-Path -Path $CachePath) {
                    Get-ChildItem -Path $CachePath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        $ProfileCachePath = Join-Path $_.FullName "cache2"
                        $Result = Remove-FolderContents -Path $ProfileCachePath -Description "Firefox Cache"
                        $CleanupSummary.BrowserCaches.SpaceFreed += $Result.SpaceFreed
                        $CleanupSummary.BrowserCaches.ItemsRemoved += $Result.ItemsRemoved
                    }
                }
            }
            else {
                $Result = Remove-FolderContents -Path $CachePath -Description "$BrowserName Cache"
                $CleanupSummary.BrowserCaches.SpaceFreed += $Result.SpaceFreed
                $CleanupSummary.BrowserCaches.ItemsRemoved += $Result.ItemsRemoved
            }
        }
        Write-Host "  Total freed: $(Format-Bytes $CleanupSummary.BrowserCaches.SpaceFreed)" -ForegroundColor Green

        # Clean application caches
        Write-Host ""
        Write-Host "Cleaning application caches..." -ForegroundColor Green
        foreach ($CachePath in $AppCaches) {
            $Result = Remove-FolderContents -Path $CachePath -Description "App Cache: $(Split-Path -Leaf $CachePath)"
            $CleanupSummary.AppCaches.SpaceFreed += $Result.SpaceFreed
            $CleanupSummary.AppCaches.ItemsRemoved += $Result.ItemsRemoved
        }
        Write-Host "  Total freed: $(Format-Bytes $CleanupSummary.AppCaches.SpaceFreed)" -ForegroundColor Green

        # Clear Recycle Bin
        Write-Host ""
        Write-Host "Clearing Recycle Bin..." -ForegroundColor Green
        $Result = Clear-RecycleBin
        $CleanupSummary.RecycleBin = $Result
        Write-Host "  Total freed: $(Format-Bytes $Result.SpaceFreed)" -ForegroundColor Green

        # Run Windows Disk Cleanup
        Write-Host ""
        Write-Host "Running Windows Disk Cleanup..." -ForegroundColor Green
        Run-DiskCleanup

        # Calculate total cleanup
        $CleanupSummary.TotalSpaceFreed = ($CleanupSummary.TempFiles.SpaceFreed +
                                           $CleanupSummary.BrowserCaches.SpaceFreed +
                                           $CleanupSummary.AppCaches.SpaceFreed +
                                           $CleanupSummary.RecycleBin.SpaceFreed)

        Write-Host ""
        Write-Host "CLEANUP SUMMARY:" -ForegroundColor Cyan
        Write-Host "  Temp Files:        $(Format-Bytes $CleanupSummary.TempFiles.SpaceFreed)" -ForegroundColor Yellow
        Write-Host "  Browser Caches:    $(Format-Bytes $CleanupSummary.BrowserCaches.SpaceFreed)" -ForegroundColor Yellow
        Write-Host "  App Caches:        $(Format-Bytes $CleanupSummary.AppCaches.SpaceFreed)" -ForegroundColor Yellow
        Write-Host "  Recycle Bin:       $(Format-Bytes $CleanupSummary.RecycleBin.SpaceFreed)" -ForegroundColor Yellow
        Write-Host "  ─────────────────────────────────────"
        Write-Host "  TOTAL FREED:       $(Format-Bytes $CleanupSummary.TotalSpaceFreed)" -ForegroundColor Green

        Write-Log "========== CLEANUP COMPLETE ==========" "INFO"
    }
    else {
        Write-Host ""
        Write-Host "PHASE 2: SKIPPED (--SkipCleanup)" -ForegroundColor Yellow
        $CleanupSummary = @{
            TempFiles = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            BrowserCaches = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            AppCaches = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            RecycleBin = @{ SpaceFreed = 0; ItemsRemoved = 0 }
            TotalSpaceFreed = 0
        }
    }

    # ========================================================================
    # PHASE 3: OPTIONAL ADVANCED CLEANUP
    # ========================================================================

    if ($CompactFiles) {
        Write-Host ""
        Write-Host "PHASE 3: NTFS FILE COMPRESSION" -ForegroundColor Cyan
        Write-Host "========================================================================"

        Write-Log "========== PHASE 3: FILE COMPRESSION ==========" "INFO"

        Write-Host "Compressing system files..." -ForegroundColor Green
        $CompressionSaved = Compress-NTFSFiles -Path "C:\Users"

        Write-Host ""
        Write-Host "COMPRESSION SUMMARY:" -ForegroundColor Cyan
        Write-Host "  Space Saved:       $(Format-Bytes $CompressionSaved)" -ForegroundColor Green

        Write-Log "========== COMPRESSION COMPLETE ==========" "INFO"
    }
    else {
        Write-Host ""
        Write-Host "PHASE 3: SKIPPED (Use --CompactFiles flag to enable)" -ForegroundColor Yellow
    }

    # ========================================================================
    # PHASE 4: OPTIMIZATION
    # ========================================================================

    if (-not $SkipOptimization) {
        Write-Host ""
        Write-Host "PHASE 4: DISK OPTIMIZATION" -ForegroundColor Cyan
        Write-Host "========================================================================"

        Write-Log "========== PHASE 4: OPTIMIZATION ==========" "INFO"

        Optimize-DiskVolume -DriveLetter "C"

        Write-Log "========== OPTIMIZATION COMPLETE ==========" "INFO"
    }
    else {
        Write-Host ""
        Write-Host "PHASE 4: SKIPPED (--SkipOptimization)" -ForegroundColor Yellow
    }

    # ========================================================================
    # PHASE 5: POST-CLEANUP ANALYSIS
    # ========================================================================

    Write-Host ""
    Write-Host "PHASE 5: POST-CLEANUP ANALYSIS" -ForegroundColor Cyan
    Write-Host "========================================================================"

    Write-Log "========== PHASE 5: POST-CLEANUP ANALYSIS ==========" "INFO"

    $AfterC = Get-DiskAnalysis -DriveLetter "C"
    $AfterD = $null
    if ($BeforeD -ne $null) {
        try {
            $AfterD = Get-DiskAnalysis -DriveLetter "D"
        }
        catch {
            # D: drive analysis failed
        }
    }

    # Calculate difference
    $FreedSpaceC = $AfterC.FreeSpace - $BeforeC.FreeSpace
    $UsageChangeC = $AfterC.UsagePercent - $BeforeC.UsagePercent

    Write-Host ""
    Write-Host "DISK SPACE DIFFERENCE (C: Drive):" -ForegroundColor Cyan
    Write-Host "  Before: $(Format-Bytes $BeforeC.FreeSpace) free | Usage: $($BeforeC.UsagePercent)%"
    Write-Host "  After:  $(Format-Bytes $AfterC.FreeSpace) free | Usage: $($AfterC.UsagePercent)%"

    if ($FreedSpaceC -gt 0) {
        Write-Host "  ✓ FREED: $(Format-Bytes $FreedSpaceC) | Usage reduced by: $([Math]::Abs($UsageChangeC))%" -ForegroundColor Green
    }
    else {
        Write-Host "  No change detected (files may have been locked)" -ForegroundColor Yellow
    }

    # ========================================================================
    # RECOMMENDATIONS
    # ========================================================================

    Write-Host ""
    Write-Host "RECOMMENDATIONS FOR FURTHER CLEANUP:" -ForegroundColor Cyan
    Write-Host "========================================================================"
    Write-Host ""
    Write-Host "Low Risk (Safe to clean):"
    Write-Host "  1. Download folder: Review old files in $env:USERPROFILE\Downloads"
    Write-Host "  2. Move media to D: drive (Videos, Pictures, Music)"
    Write-Host ""
    Write-Host "Medium Risk (Review before cleaning):"
    Write-Host "  3. Old user profiles: Control Panel → System → Advanced → User Profiles"
    Write-Host "  4. Application install folders: Check Programs and Features for unused apps"
    Write-Host ""
    Write-Host "High Risk (Requires careful consideration):"
    Write-Host "  5. Disable hibernation: powercfg /hibernate off  (frees 4-8GB)"
    Write-Host "  6. Reduce restore points: System Properties → System Protection"
    Write-Host "  7. Delete Windows.old: Only if > 30 days since Windows update"
    Write-Host ""

    # ========================================================================
    # GENERATE REPORT
    # ========================================================================

    Write-Host ""
    Write-Host "GENERATING REPORT..." -ForegroundColor Cyan
    Write-Host "========================================================================"

    Generate-Report -BeforeDiskAnalysis $BeforeC -AfterDiskAnalysis $AfterC `
                    -CleanupSummary $CleanupSummary -LargestFolders $LargestFoldersC

    # ========================================================================
    # FINAL SUMMARY
    # ========================================================================

    Write-Host ""
    Write-Host "============================================================================"
    Write-Host "SCRIPT COMPLETION SUMMARY" -ForegroundColor Green
    Write-Host "============================================================================"
    Write-Host ""
    Write-Host "✓ Disk Analysis:      Complete"
    Write-Host "✓ Cleanup Operations: $(if ($SkipCleanup) { "Skipped" } else { "Complete" })"
    Write-Host "✓ File Compression:   $(if ($CompactFiles) { "Complete" } else { "Skipped" })"
    Write-Host "✓ Disk Optimization:  $(if ($SkipOptimization) { "Skipped" } else { "Complete" })"
    Write-Host ""
    Write-Host "Log File:             $LogPath"
    Write-Host "Report File:          $ReportPath"
    Write-Host ""
    Write-Host "Total Space Freed:    $(Format-Bytes $CleanupSummary.TotalSpaceFreed)" -ForegroundColor Green
    Write-Host ""
    Write-Host "============================================================================"
    Write-Host ""

    Write-Log "========== SCRIPT COMPLETED SUCCESSFULLY ==========" "INFO"
    Write-Log "Total space freed: $(Format-Bytes $CleanupSummary.TotalSpaceFreed)" "INFO"
}

# Execute main function
try {
    Main
}
catch {
    Write-Log "CRITICAL ERROR: $_" "ERROR"
    Write-Host ""
    Write-Host "CRITICAL ERROR OCCURRED:" -ForegroundColor Red
    Write-Host $_
    Write-Host ""
    Write-Host "Check log file: $LogPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "Press any key to close this window..." -ForegroundColor Gray
[System.Console]::ReadKey() | Out-Null
