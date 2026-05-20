---
delegation_id: HERMES-CODEX-20260520-WSL-MIGRATION
timestamp: 2026-05-20T14:00:00Z
delegated_by: Tham Oracle
delegated_to: Hermes + Codex Agent
priority: HIGH
risk_level: MEDIUM (destructive operation, reversible with backup)
status: active
---

# Mission: WSL Disk Migration C: → D: (Solve Low Disk Space)

## Problem Statement
- **Current State**: WSL running on C: drive, disk space critically low
- **Goal**: Migrate WSL volume from C: to D: drive to free up C: space
- **Constraint**: Zero downtime for current projects, reversible if needed
- **Success Criteria**: WSL fully operational on D:, C: disk space recovered, all data intact

## Execution Plan

### Phase 1: Assess Current State (READ-ONLY)
```powershell
# Check current WSL installation location
wsl --list --verbose
# Output format: NAME | STATE | VERSION | DEFAULT | PATH

# Get C: drive usage
Get-Volume -DriveLetter C | Select-Object SizeRemaining, Size
# Calculate: (SizeRemaining / Size) * 100 = % free

# Get D: drive available space
Get-Volume -DriveLetter D | Select-Object SizeRemaining, Size

# Estimate WSL volume size
wsl -e du -sh /

# Check WSL default distribution
(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss").DefaultDistribution
```

**Output required**: Current disk usage %, WSL volume size, D: available space

### Phase 2: Backup WSL State (SAFE CHECKPOINT)
```powershell
# Stop all WSL distributions
wsl --shutdown

# Export current WSL state to backup file
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "D:\wsl-backup-$timestamp.tar.gz"

# List all WSL distributions
$distros = wsl --list --quiet

# Export each distro
foreach ($distro in $distros) {
    wsl --export $distro "D:\wsl-backup-$distro-$timestamp.tar"
    Write-Host "✓ Backed up: $distro"
}

# Verify backup size
Get-Item "D:\wsl-backup-*.tar" | Select-Object Name, Length
```

**Proof required**: Backup files created, sizes logged, WSL shut down cleanly

### Phase 3: Unregister WSL from C: & Register on D:
```powershell
# DANGER: This step unregisters WSL from C:
# Once unregistered, WSL will not start until re-registered

# List WSL distributions and their paths
$distros = wsl --list --quiet
foreach ($distro in $distros) {
    $path = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss\$distro").BasePath
    Write-Host "$distro -> $path"
}

# Unregister from registry (removes C: entry)
# NOTE: Does NOT delete files, only removes registry binding
foreach ($distro in $distros) {
    wsl --unregister $distro
    Write-Host "Unregistered: $distro from C:"
}

# Physically move WSL directory from C:\Users\...\AppData\Local\Packages\* to D:\wsl\
# If using WSL2:
# New location: D:\wsl\{DistroName}

Move-Item -Path "C:\Users\$env:USERNAME\AppData\Local\Packages\CanonicalGroupLimited*" `
          -Destination "D:\wsl\" -Force

# Re-import distributions on D:
$distros = @("Ubuntu", "Debian")  # Adjust to your distros
foreach ($distro in $distros) {
    wsl --import $distro "D:\wsl\$distro" "D:\wsl-backup-$distro-$timestamp.tar"
    Write-Host "✓ Registered: $distro on D:"
}
```

**Proof required**: Old registry entries gone, new entries on D:, physical move complete

### Phase 4: Verify WSL on D: & Integrity Check
```powershell
# Start WSL and verify it works
wsl --list --verbose
# Should show: NAME | STATE | VERSION | DEFAULT | D:\wsl\... (not C:\)

# Boot test
wsl -e sh -c "echo 'WSL running on D:' && df -h / | head -2"

# Check home directory still accessible
wsl -e pwd
wsl -e ls -la ~

# Run integrity check on all known git repos
wsl -e bash -c "
  find ~/ghq -name .git -type d | while read gitdir; do
    cd \$(dirname \$gitdir)
    git status > /dev/null 2>&1 && echo '✓ OK: '$PWD || echo '✗ FAIL: '$PWD
  done
"

# Verify tmux sessions survive (if any running)
wsl -e tmux list-sessions

# Check disk space on D: after migration
wsl -e df -h / | grep -E '^/dev|Mounted on'
```

**Proof required**: WSL boots cleanly, git repos healthy, disk space verified

### Phase 5: Cleanup & C: Disk Recovery
```powershell
# ONLY if Phase 4 passes completely

# Remove old WSL packages from C: (safe to delete)
Remove-Item -Path "C:\Users\$env:USERNAME\AppData\Local\Packages\CanonicalGroupLimited*" -Recurse -Force

# Remove backup files from C: (if any created there)
Remove-Item -Path "C:\wsl-backup-*.tar" -Force

# Check C: disk space recovered
Get-Volume -DriveLetter C | Select-Object SizeRemaining, Size
# Compare with Phase 1 baseline

# Optional: Delete backup files from D: (keep for 48 hours, then delete)
# Backup files can be deleted safely once D: system verified stable
```

**Proof required**: C: disk space before/after comparison, old files removed, recovery confirmed

## Rollback Plan (If Anything Fails)

If migration fails at ANY phase:

```powershell
# STOP: Do NOT continue without contacting พี่เอก

# Restore from backup (Phase 2 exports)
wsl --shutdown

# Unregister failed distros
wsl --unregister Ubuntu
wsl --unregister Debian

# Re-import from backup on C: (original location)
wsl --import Ubuntu "C:\wsl\Ubuntu" "D:\wsl-backup-Ubuntu-*.tar"

# Boot and verify
wsl --list --verbose
```

## Risk Assessment

| Risk | Mitigation | Severity |
|------|-----------|----------|
| Data loss during move | Full backup in Phase 2 | LOW (backed up) |
| WSL won't boot on D: | Import from backup | LOW (reversible) |
| Registry corruption | Unregister then re-import | LOW (clean registry) |
| Long migration time | Plan for 30+ min downtime | MEDIUM (acceptable) |
| Symlinks/mounts break | Test in Phase 4 | MEDIUM (verify) |

## Success Criteria (MUST ALL PASS)

✓ Phase 1: Baseline captured (disk usage %, WSL size, D: space)
✓ Phase 2: Full backup created + WSL shut down
✓ Phase 3: WSL unregistered from C:, re-registered on D:
✓ Phase 4: WSL boots, git repos healthy, integrity verified
✓ Phase 5: C: space recovered, old files cleaned up
✓ Proof: Before/after disk usage, boot logs, git status

## Proof Artifacts Required

Create file: `/proofs/WSL_MIGRATION_REPORT_20260520.md` with:
- Phase 1 baseline (C: %, D: available, WSL size)
- Phase 2 backup file names + sizes
- Phase 3 registry changes (before/after)
- Phase 4 boot test output + git integrity check
- Phase 5 C: disk recovery (%, space freed)
- Full timeline + any errors encountered

## Escalation Path

**If at any point**:
- WSL fails to boot on D:
- Git repos show corruption
- Disk space not recovered as expected
- Rollback needed

**STOP and escalate to พี่เอก with**:
- Exact error message
- Phase where it failed
- Backup file location
- Request: manual intervention vs. rollback authorization

---

**Next**: Hermes+Codex execute phases 1-5 sequentially. Wait for each phase proof before proceeding.
Report status to Tham after each phase completes.
