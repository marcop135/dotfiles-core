<#
.SYNOPSIS
    Symlink configuration from this repository into your Windows profile.

.DESCRIPTION
    The PowerShell counterpart of scripts/install.sh, and a real equivalent
    rather than a wrapper: it reads the same scripts/modules.conf manifest and
    installs the entries whose platform list includes `windows`.

    Dry run is the default. Nothing is deleted; an existing file at a target
    path is renamed to <target>.bak.<timestamp> before the link is created.
    -Unlink is the other half of that promise: it removes only symlinks that
    point into this repository, and never a real file.

.PARAMETER Apply
    Actually create the links. Without it, the plan is printed and nothing
    changes.

.PARAMETER Only
    Comma separated module names to install, e.g. -Only shell

.PARAMETER Skip
    Comma separated module names to leave alone.

.PARAMETER List
    Print the available modules and exit.

.PARAMETER Status
    Print what is currently linked and exit.

.PARAMETER Unlink
    Remove the links this repository owns. Honours -Only and -Skip, and is a
    dry run unless -Apply is given.

.PARAMETER Restore
    With -Unlink, move the newest <target>.bak.* back into place after
    unlinking. Without it, the backup path is printed and left alone.

.EXAMPLE
    .\scripts\install.ps1
    .\scripts\install.ps1 -Apply
    .\scripts\install.ps1 -Apply -Only shell
    .\scripts\install.ps1 -Unlink
    .\scripts\install.ps1 -Unlink -Restore -Apply

.NOTES
    Creating a symbolic link on Windows requires a privilege. Enable Developer
    Mode (Settings > System > For developers), or run this from an elevated
    shell. The script detects the failure and says so.
#>

[CmdletBinding()]
param(
    [switch]$Apply,
    [string[]]$Only,
    [string[]]$Skip,
    [switch]$List,
    [switch]$Status,
    [switch]$Unlink,
    [switch]$Restore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Restore -and -not $Unlink) {
    # Write-Host rather than Write-Error: $ErrorActionPreference is Stop, and a
    # thrown error would replace the exit code with its own.
    Write-Host 'install.ps1: -Restore only means something with -Unlink'
    exit 2
}

$Root = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $PSScriptRoot 'modules.conf'
$Platform = 'windows'

if (-not (Test-Path $Manifest)) {
    Write-Error "manifest not found: $Manifest"
    exit 1
}

# ---------- Target expansion ----------
function Expand-Target {
    param([Parameter(Mandatory)][string]$Target)

    $expanded = $Target
    $expanded = $expanded.Replace('{{PSPROFILE}}', $PROFILE.CurrentUserAllHosts)
    if ($expanded.StartsWith('~')) {
        # $env:USERPROFILE rather than $HOME. They are the same directory on
        # Windows, but $HOME is a read-only automatic variable, so a caller
        # cannot point this script at a scratch home. CI does exactly that to
        # test -Apply without writing to the runner's real profile.
        $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
        $expanded = Join-Path $homeDir $expanded.Substring(1).TrimStart('/', '\')
    }
    # Normalise to backslashes so the output does not mix separators.
    $expanded -replace '/', '\'
}

# ---------- Manifest ----------
function Get-ManifestEntry {
    Get-Content $Manifest | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }

        $parts = $line -split '\|'
        if ($parts.Count -lt 4) { return }

        [pscustomobject]@{
            Module    = $parts[0].Trim()
            Source    = $parts[1].Trim()
            Target    = $parts[2].Trim()
            Platforms = ($parts[3].Trim() -split ',' | ForEach-Object { $_.Trim() })
        }
    }
}

function Get-SelectedEntry {
    Get-ManifestEntry | Where-Object {
        ($_.Platforms -contains $Platform) -and
        (-not $Only -or $Only -contains $_.Module) -and
        (-not $Skip -or $Skip -notcontains $_.Module)
    } | ForEach-Object {
        [pscustomobject]@{
            Module = $_.Module
            Source = Join-Path $Root ($_.Source -replace '/', '\')
            Rel    = $_.Source
            Target = Expand-Target $_.Target
        }
    }
}

function Get-LinkState {
    param([string]$Target, [string]$Want)

    if (-not (Test-Path -LiteralPath $Target)) { return 'missing' }

    $item = Get-Item -LiteralPath $Target -Force
    if ($item.LinkType -in @('SymbolicLink', 'Junction')) {
        # .Target is an array on some PowerShell versions and a string on
        # others. Normalise before comparing, or a correctly linked file
        # reports as wrong-link.
        $current = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
        if ($current -and ((Resolve-Path -LiteralPath $current -ErrorAction SilentlyContinue).Path -eq
                (Resolve-Path -LiteralPath $Want -ErrorAction SilentlyContinue).Path)) {
            return 'linked'
        }
        return 'wrong-link'
    }
    return 'file'
}

# ---------- Actions ----------
if ($List) {
    Write-Host "platform: $Platform"
    Write-Host 'modules:'
    Get-ManifestEntry | Select-Object -ExpandProperty Module -Unique | Sort-Object |
        ForEach-Object { Write-Host "  $_" }
    exit 0
}

if ($Status) {
    Write-Host "platform: $Platform`n"
    foreach ($e in Get-SelectedEntry) {
        $state = Get-LinkState -Target $e.Target -Want $e.Source
        Write-Host ('  {0,-8} {1,-10} {2}' -f $e.Module, $state, $e.Target)
    }
    exit 0
}

# Newest <target>.bak.* for a target, or $null. The timestamp format is
# yyyyMMddHHmmss, so the newest is also the last in a plain name sort.
function Get-NewestBackup {
    param([string]$Target)

    $dir = Split-Path -Parent $Target
    $leaf = Split-Path -Leaf $Target
    if (-not (Test-Path -LiteralPath $dir)) { return $null }

    Get-ChildItem -LiteralPath $dir -Filter "$leaf.bak.*" -Force -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1 -ExpandProperty FullName
}

# ---------- Unlink ----------
# The inverse of install, with the same dry-run default. A target is removed
# only when it is a symlink into this repository. A real file, or a symlink
# pointing somewhere else, belongs to someone else and is reported, not touched.
if ($Unlink) {
    Write-Host "platform: $Platform"
    Write-Host "repository: $Root"
    if (-not $Apply) {
        Write-Host ''
        Write-Host 'DRY RUN. Nothing will be changed. Re-run with -Apply.'
    }
    Write-Host ''

    $considered = 0
    $unlinked = 0
    $errors = 0

    foreach ($e in Get-SelectedEntry) {
        $considered++
        $state = Get-LinkState -Target $e.Target -Want $e.Source

        switch ($state) {
            'linked' {
                if ($Apply) {
                    try {
                        # -Force on a symlink to a file removes the link, not
                        # the target. Remove-Item on a directory symlink would
                        # prompt; none of the targets here are directories.
                        Remove-Item -LiteralPath $e.Target -Force
                        Write-Host ('  {0,-8} unlinked   {1}' -f $e.Module, $e.Target)
                        $unlinked++
                    }
                    catch {
                        Write-Host ('  {0,-8} ERROR      could not remove {1}' -f $e.Module, $e.Target)
                        $errors++
                        continue
                    }
                }
                else {
                    Write-Host ('  {0,-8} would unlink {1}' -f $e.Module, $e.Target)
                }

                $backup = Get-NewestBackup -Target $e.Target
                if ($backup) {
                    if ($Restore) {
                        if ($Apply) {
                            Move-Item -LiteralPath $backup -Destination $e.Target -Force
                            Write-Host ('  {0,-8} restored   {1}' -f $e.Module, $e.Target)
                        }
                        else {
                            Write-Host ('  {0,-8} would restore {1}' -f $e.Module, $backup)
                        }
                    }
                    else {
                        Write-Host ('  {0,-8} backup     {1}' -f $e.Module, $backup)
                    }
                }
            }
            'wrong-link' {
                Write-Host ('  {0,-8} skipped    {1} (symlink to somewhere else)' -f $e.Module, $e.Target)
            }
            'file' {
                Write-Host ('  {0,-8} skipped    {1} (a real file, not our link)' -f $e.Module, $e.Target)
            }
            'missing' {
                Write-Host ('  {0,-8} absent     {1}' -f $e.Module, $e.Target)
            }
        }
    }

    Write-Host ''
    if ($Apply) {
        Write-Host "$unlinked unlinked, $considered considered, $errors errors."
        if (-not $Restore) {
            Write-Host 'Backups were left in place. Re-run with -Restore to move the newest one back.'
        }
    }
    else {
        Write-Host "$considered considered, $errors errors. Re-run with -Apply."
    }

    exit ($(if ($errors -eq 0) { 0 } else { 1 }))
}

Write-Host "platform: $Platform"
Write-Host "repository: $Root"
if (-not $Apply) {
    Write-Host ''
    Write-Host 'DRY RUN. Nothing will be changed. Re-run with -Apply.'
}
Write-Host ''

$planned = 0
$changed = 0
$errors = 0

foreach ($e in Get-SelectedEntry) {
    if (-not (Test-Path -LiteralPath $e.Source)) {
        Write-Host ('  {0,-8} ERROR      missing source: {1}' -f $e.Module, $e.Rel)
        $errors++
        continue
    }

    $state = Get-LinkState -Target $e.Target -Want $e.Source
    $planned++

    if ($state -eq 'linked') {
        Write-Host ('  {0,-8} ok         {1}' -f $e.Module, $e.Target)
        continue
    }

    if ($state -in @('file', 'wrong-link')) {
        # Backing up ~/.gitconfig is correct and also moves the user's name and
        # email out of the way, and the next commit is authored by nobody. Say
        # so before it happens, in dry run too, with the commands that fix it.
        if ((Split-Path -Leaf $e.Target) -eq '.gitconfig' -and
            (Select-String -LiteralPath $e.Target -Pattern '^\[user\]' -Quiet -ErrorAction SilentlyContinue)) {
            $name = (git config user.name 2>$null)
            $email = (git config user.email 2>$null)
            if (-not $name) { $name = 'Your Name' }
            if (-not $email) { $email = 'you@example.com' }
            Write-Host ''
            Write-Host ('  {0,-8} NOTE       {1} has a [user] section.' -f $e.Module, $e.Target)
            Write-Host '           It will be backed up, not lost, but your identity has to move to'
            Write-Host '           ~/.gitconfig.local or your next commit is authored by nobody:'
            Write-Host ''
            Write-Host "             git config --file ~/.gitconfig.local user.name  ""$name"""
            Write-Host "             git config --file ~/.gitconfig.local user.email ""$email"""
            Write-Host ''
        }

        $backup = '{0}.bak.{1}' -f $e.Target, (Get-Date -Format 'yyyyMMddHHmmss')
        if ($Apply) {
            Move-Item -LiteralPath $e.Target -Destination $backup -Force
            Write-Host ('  {0,-8} backed up  {1}' -f $e.Module, $backup)
        }
        else {
            Write-Host ('  {0,-8} would back up {1}' -f $e.Module, $e.Target)
        }
    }

    if ($Apply) {
        $parent = Split-Path -Parent $e.Target
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        try {
            New-Item -ItemType SymbolicLink -Path $e.Target -Target $e.Source -Force | Out-Null
            Write-Host ('  {0,-8} linked     {1} -> {2}' -f $e.Module, $e.Target, $e.Rel)
            $changed++
        }
        catch {
            Write-Host ('  {0,-8} ERROR      could not link {1}' -f $e.Module, $e.Target)
            Write-Host '           Symbolic links need permission. Enable Developer Mode'
            Write-Host '           (Settings > System > For developers) or run elevated.'
            $errors++
        }
    }
    else {
        Write-Host ('  {0,-8} would link {1} -> {2}' -f $e.Module, $e.Target, $e.Rel)
    }
}

Write-Host ''
if ($Apply) {
    Write-Host "$changed changed, $planned considered, $errors errors."
    Write-Host ''
    Write-Host 'Next:'
    Write-Host '  Copy-Item shared\shell\local.sh.example $HOME\.shell.local'
    Write-Host '  # then put anything machine-specific in it'
    Write-Host '  . $PROFILE.CurrentUserAllHosts'
}
else {
    Write-Host "$planned links planned, $errors errors. Re-run with -Apply."
}

exit ($(if ($errors -eq 0) { 0 } else { 1 }))
