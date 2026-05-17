# Windows Disk Space Analysis Tools — Detailed Reference

## Overview

This guide covers all available tools for analyzing and optimizing disk space on Windows systems, from built-in utilities to third-party tools.

---

## Table of Contents

1. [Built-in Windows Tools](#built-in-windows-tools)
2. [PowerShell Commands](#powershell-commands)
3. [Third-Party Tools](#third-party-tools)
4. [Comparison Matrix](#comparison-matrix)
5. [Tool Selection Guide](#tool-selection-guide)

---

## Built-in Windows Tools

### 1. Disk Management (diskmgmt.msc)

**Access**:
- Press `Win + X` → Disk Management
- Or: `diskmgmt.msc` in Run dialog
- Or: Right-click "This PC" → Manage → Disk Management

**Features**:
- View all disk partitions
- See total capacity and free space
- Visual representation of partition usage
- Partition operations (resize, extend, shrink)

**Limitations**:
- Shows only aggregate space per partition
- Cannot drill down to specific folders
- No file-level analysis

**Use Case**: Quick check of overall disk capacity

**Screenshot**:
```
┌─────────────────────────────────────┐
│ C: NTFS                             │
│ 256.0 GB Total | 78.5 GB Used       │
│ [████████████░░░░░░░░] 77.54%       │
└─────────────────────────────────────┘
```

---

### 2. Storage Sense (Windows Settings)

**Access**:
- Settings → System → Storage
- Or: Settings → System → Storage → Storage Sense

**Features**:
- Real-time storage usage by category
- Automatic cleanup recommendations
- One-click cleanup of recommended items
- Scheduled automatic cleanup

**Categories Analyzed**:
- Apps & features
- Photos
- Documents
- Files in cloud
- Temporary files
- Recycle Bin
- Music

**Cleanup Options**:
- Automatic cleanup of temp files
- Delete files in Recycle Bin after X days
- Delete files in Downloads folder after X days
- Reduce reserve storage (Windows 11 only)

**Advantages**:
- Built-in to Windows
- No manual configuration needed
- Automatic operation
- Safe cleanup

**Limitations**:
- Categories are broad
- Cannot see largest individual files
- Limited to Windows 10/11

**Use Case**: Automatic, hands-off cleanup

---

### 3. Disk Cleanup Utility (cleanmgr.exe)

**Access**:
- Search "Disk Cleanup" in Start menu
- Or: `cleanmgr` in Run dialog
- Or: `C:\Windows\System32\cleanmgr.exe`

**Features**:
- Remove temporary files
- Clear download cache
- Empty Recycle Bin
- Remove Windows Update cache
- Clear error reports and dumps

**Categories to Clean**:
```
✓ Temporary files
✓ Downloaded Program Files
✓ Recycle Bin
✓ Temporary Internet Files
✓ System error memory dumps
✓ Offline files
✓ Compress old files
✓ Files on Desktop
✓ Windows Update cleanup
✓ Device driver packages
✓ Content Indexer Cleaner Files
```

**Typical Space Freed**: 500MB - 2GB

**Safety Level**: LOW RISK — All items are safe to delete

**Advanced Usage**:
```powershell
# Run disk cleanup with specific options
# (Administrator required)
cleanmgr /sagerun:0
```

**Use Case**: Periodic cleanup of temporary files

---

### 4. File Properties Dialog

**Access**: Right-click folder → Properties

**Information Shown**:
- Total folder size
- Used space
- Number of files
- Creation/modification dates

**Analysis Capability**:
```
Folder:  C:\Users\{username}\Downloads
Size:    27.4 GB
Files:   3,456
Folders: 234
```

**Limitations**:
- Manual folder-by-folder analysis
- Slow for large folders (25GB+ takes 1-2 minutes)
- No comparison across folders

**Use Case**: Check size of specific folder manually

**Optimization Tip**: Right-click → Properties → Tools → "Optimize" for NTFS optimization

---

### 5. PowerShell — Get-ChildItem

**Basic Command**:
```powershell
# Get size of all items in a folder
Get-ChildItem -Path "C:\" -Force | 
  Select-Object Name, 
    @{N='SizeMB';E={[Math]::Round($_.Length/1MB,2)}}, 
    LastWriteTime |
  Sort-Object SizeMB -Descending |
  Format-Table -AutoSize
```

**Advantages**:
- Free
- Scriptable
- No installation needed
- Powerful filtering

**Limitations**:
- Command-line only
- Steep learning curve
- Slow for deeply nested folders

**Use Case**: Automation and scripting

---

### 6. Disk Defragmentation Tool (Optimize-Volume)

**Access**:
- Settings → System → Storage → Advanced storage settings → Optimize drives
- Or: `dfrgui.exe` (defrag GUI)
- Or: PowerShell (see below)

**Features**:
- Defragmentation (HDD)
- TRIM operation (SSD)
- Scheduled optimization
- Fragmentation analysis

**PowerShell Commands**:
```powershell
# Analyze fragmentation
Optimize-Volume -DriveLetter C -Analyze

# Defragment HDD
Optimize-Volume -DriveLetter C -Defrag

# TRIM SSD
Optimize-Volume -DriveLetter C -Trim

# Optimize with verbose output
Optimize-Volume -DriveLetter C -Defrag -Verbose
```

**Duration**:
- Analysis: 1-5 minutes
- Defragmentation: 30 minutes - 2 hours
- TRIM: 1-5 minutes

**Use Case**: Maintain disk performance

---

### 7. Task Scheduler for Automated Cleanup

**Access**: Task Scheduler → Create Task

**Example Task**:
```
Name: Weekly Disk Cleanup
Schedule: Every Saturday at 2:00 AM
Action: Run cleanup-and-optimize-disk.ps1
User: SYSTEM
```

**PowerShell Setup**:
```powershell
# Create scheduled cleanup task
$TaskAction = New-ScheduledTaskAction `
  -Execute 'powershell.exe' `
  -Argument '-NoProfile -File C:\Path\To\cleanup-and-optimize-disk.ps1'

$TaskTrigger = New-ScheduledTaskTrigger `
  -Weekly -DaysOfWeek Saturday -At 2am

Register-ScheduledTask `
  -Action $TaskAction `
  -Trigger $TaskTrigger `
  -TaskName "DiskCleanup" `
  -Description "Weekly cleanup"
```

---

## PowerShell Commands

### Get Disk Usage Summary

```powershell
# Show all volumes
Get-Volume | Format-Table

# Show volumes with usage percentage
Get-Volume | Select-Object DriveLetter, 
  @{N='TotalGB';E={[Math]::Round($_.Size/1GB,2)}},
  @{N='UsedGB';E={[Math]::Round(($_.Size - $_.SizeRemaining)/1GB,2)}},
  @{N='FreeGB';E={[Math]::Round($_.SizeRemaining/1GB,2)}},
  @{N='UsagePercent';E={[Math]::Round(100-($_.SizeRemaining/$_.Size*100),2)}} |
  Format-Table -AutoSize
```

**Output**:
```
DriveLetter TotalGB UsedGB FreeGB UsagePercent
─────────── ─────── ────── ────── ────────────
C           238.47  204.35  34.12         85.68
D           931.51  724.88  206.63        77.84
```

### Find Largest Folders

```powershell
# Find top 20 largest folders (may take 1-2 minutes)
Get-ChildItem -Path "C:\Users" -Directory -Force |
  ForEach-Object {
    [PSCustomObject]@{
      Name = $_.Name
      Path = $_.FullName
      SizeGB = [Math]::Round((Get-ChildItem -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    }
  } |
  Sort-Object SizeGB -Descending |
  Select-Object -First 20 |
  Format-Table -AutoSize
```

### Find Largest Files

```powershell
# Find top 50 largest files on C: drive
Get-ChildItem -Path "C:\" -File -Recurse -Force -ErrorAction SilentlyContinue |
  Sort-Object Length -Descending |
  Select-Object -First 50 Name, 
    @{N='SizeGB';E={[Math]::Round($_.Length/1GB,2)}},
    FullName,
    LastWriteTime |
  Format-Table -AutoSize
```

### Cleanup Temporary Files

```powershell
# Remove temp files (with backup list)
$TempItems = Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue
$TempItems | Out-File -FilePath "C:\Temp_Backup_List_$(Get-Date -Format yyyyMMdd).txt"

$TempItems | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Removed $($TempItems.Count) items from temp"
```

### Disable Hibernation (Save 4-8GB)

```powershell
# Disable hibernation
powercfg /hibernate off

# Verify hibernation status
powercfg /a

# Re-enable hibernation (if needed)
powercfg /hibernate on
```

### Compress Files (NTFS)

```powershell
# Compress a folder
Compact.exe /C /S "C:\Users\{username}\Documents"

# Check compression status
Compact.exe /S "C:\Users\{username}\Documents"

# Uncompress
Compact.exe /U /S "C:\Users\{username}\Documents"
```

---

## Third-Party Tools

### 1. TreeSize Free

**Website**: https://www.jam-software.com/treesize_free

**Features**:
- Visual folder size analysis
- Treemap visualization
- Sorting by multiple criteria
- Export reports
- File/folder search

**Pros**:
- Free version available
- Powerful analysis
- User-friendly interface
- Professional reports

**Cons**:
- Installation required
- Professional version costs money
- Slower on very large folders

**Use Case**: Detailed visual analysis of disk usage

**Sample Output**:
```
C:\ (256 GB)
├─ Users (198 GB) [77.3%]
│  ├─ Downloads (87 GB) [34%]
│  │  ├─ Installers (45 GB)
│  │  ├─ Videos (28 GB)
│  │  └─ Other (14 GB)
│  ├─ Documents (42 GB) [16.4%]
│  └─ Desktop (23 GB) [9%]
├─ Windows (38 GB) [14.8%]
│  ├─ System32 (15 GB)
│  ├─ WinSxS (18 GB)
│  └─ Temp (5 GB)
└─ Program Files (20 GB) [7.8%]
```

**Download**: Free from official website

---

### 2. WinDirStat

**Website**: https://windirstat.net/

**Features**:
- Visual treemap display
- File filtering and sorting
- Directory statistics
- Open files in viewer

**Pros**:
- Completely free (open-source)
- Lightweight
- No installation needed (portable version)
- Fast analysis

**Cons**:
- Less polished UI than TreeSize
- Limited advanced features
- Smaller file community

**Use Case**: Quick, free analysis of disk usage

**Installation**:
```
Download from https://windirstat.net/
Extract to any folder
Run WinDirStat.exe
```

---

### 3. SpaceSniffer

**Website**: http://www.uderzo.it/main_products/space_sniffer/

**Features**:
- Interactive treemap
- Mouse-over info
- Exclusion patterns
- Exports data

**Pros**:
- Free
- Lightweight (< 1 MB)
- Portable
- Fast

**Cons**:
- Older interface
- Limited feature set
- Smaller user base

---

### 4. Defraggler (Advanced Defrag)

**Website**: https://www.ccleaner.com/defraggler

**Features**:
- Advanced defragmentation
- Scheduled defrag
- Boot-time defrag
- Visual reports

**Pros**:
- More options than Windows tool
- Better visualization
- Detailed analysis

**Cons**:
- Freemium model (paid for full features)
- Installation required

---

### 5. CCleaner (All-in-One)

**Website**: https://www.ccleaner.com/

**Features**:
- Temp file cleanup
- Registry cleanup
- Browser cache
- Duplicate file finder
- Uninstall manager

**Pros**:
- Comprehensive cleaning
- Easy to use
- Popular and trusted

**Cons**:
- Freemium (some features paid)
- May be too aggressive for some users
- Requires installation

---

## Comparison Matrix

### Built-in Tools

| Tool | Free | Ease of Use | Power | Speed |
|------|------|-------------|-------|-------|
| Disk Management | ✓ | Easy | Low | Fast |
| Storage Sense | ✓ | Easy | Medium | Auto |
| Disk Cleanup | ✓ | Easy | Medium | Medium |
| Properties Dialog | ✓ | Easy | Low | Slow |
| PowerShell | ✓ | Hard | Very High | Medium |
| Optimize Volume | ✓ | Medium | High | Slow |

### Third-Party Tools

| Tool | Free | License | UI Quality | Features |
|------|------|---------|-----------|----------|
| TreeSize | Partial | Freemium | Excellent | Excellent |
| WinDirStat | ✓ | Open Source | Good | Good |
| SpaceSniffer | ✓ | Freeware | Fair | Fair |
| Defraggler | Partial | Freemium | Good | Very Good |
| CCleaner | Partial | Freemium | Excellent | Excellent |

---

## Tool Selection Guide

### For Quick Analysis (< 1 minute)
→ **Disk Management** or **Properties Dialog**

### For Complete Cleanup (1 operation)
→ **Disk Cleanup (cleanmgr.exe)** or **cleanup-and-optimize-disk.ps1**

### For Detailed Visual Analysis
→ **TreeSize Free** or **WinDirStat**

### For Continuous Monitoring
→ **Storage Sense** (automatic) + **Task Scheduler**

### For Advanced Users/Scripting
→ **PowerShell commands**

### For All-in-One Solution
→ **CCleaner** or **cleanup-and-optimize-disk.ps1**

### For SSD Maintenance
→ **Optimize-Volume** (TRIM) + **Windows native**

### For HDD Defragmentation
→ **Optimize-Volume** (Defrag) or **Defraggler**

---

## Recommended Workflow

### Weekly Maintenance
1. Run **cleanup-and-optimize-disk.ps1**
2. Review log and report
3. Check largest folders if needed

### Monthly Analysis
1. Use **TreeSize Free** or **WinDirStat**
2. Identify unusual large folders
3. Archive/delete old files manually

### Quarterly Deep Clean
1. Run full cleanup script with compression
2. Review old user profiles
3. Uninstall unused applications
4. Move large files to secondary drive

### For 10-20GB Space Gain
1. Run cleanup script: 2-5GB freed
2. Compress files: 1-2GB additional (optional)
3. Move Downloads/Documents: 5-10GB
4. Remove old projects: 2-5GB
5. Uninstall unused apps: 1-3GB

---

## Performance Impact Reference

### Cleanup Tools
| Tool | Duration | CPU | Disk I/O |
|------|----------|-----|----------|
| Disk Cleanup | 2-5 min | Low | High |
| Storage Sense | Auto | Low | Low |
| TreeSize scan | 2-10 min | Low | High |
| Defragmentation | 30 min - 2 hrs | Medium | Very High |
| TRIM (SSD) | 1-5 min | Low | Medium |

### Best Time to Run
- **Evening**: Before sleep (long operations)
- **Weekend**: When computer not in use
- **Scheduled**: Automatic at 2:00 AM (low impact)

---

## Related Files

- **Main Script**: `cleanup-and-optimize-disk.ps1`
- **Guide**: `DISK_OPTIMIZATION_GUIDE.md`
- **Usage**: `DISK_OPTIMIZATION_USAGE.md`
- **Quick Reference**: `DISK_CLEANUP_QUICK_REFERENCE.txt`

---

**Last Updated**: May 17, 2026  
**Author**: ธาม Oracle  
**Version**: 1.0.0
