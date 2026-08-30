<#
.SYNOPSIS
    Conditions that quietly degrade a Windows setup. Read-only.

.DESCRIPTION
    The PowerShell counterpart of scripts/doctor.sh. It reports only what does
    not announce itself: a symlink privilege that is off, a path length limit
    that is on, an execution policy that stops the profile from loading at all.
    What is currently linked is `.\scripts\install.ps1 -Status`, not this.

.EXAMPLE
    .\scripts\doctor.ps1
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$Root = Split-Path -Parent $PSScriptRoot
$script:Warnings = 0

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host $Title
    Write-Host ('-' * $Title.Length)
}

function Write-Row {
    param([string]$Label, [string]$Value)
    Write-Host ('  {0,-18} {1}' -f $Label, $Value)
}

function Write-Ok {
    param([string]$Message)
    Write-Host '  + ' -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host '  ! ' -ForegroundColor Yellow -NoNewline
    Write-Host $Message
    $script:Warnings++
}

function Write-Note {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor DarkGray
}

# Get-ItemProperty -Name on a missing value writes a PropertyNotFoundException
# rather than returning $null, and under StrictMode the following access throws
# too. Wrapping it is the only reliable way to ask "is this set".
function Get-RegistryValue {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { $key = Get-ItemProperty -Path $Path -ErrorAction Stop } catch { return $null }
    if ($null -eq $key) { return $null }
    if ($key.PSObject.Properties.Name -contains $Name) { return $key.$Name }
    return $null
}

Write-Section 'Environment'
Write-Row 'platform' 'windows (PowerShell)'
Write-Row 'os' ([System.Environment]::OSVersion.VersionString)
Write-Row 'powershell' "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
Write-Row 'repository' $Root
Write-Row 'profile' $PROFILE.CurrentUserAllHosts

Write-Section 'Tools'
foreach ($tool in @('git', 'node', 'npm', 'starship', 'rg', 'bat', 'delta', 'wsl')) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) {
        # wsl.exe writes UTF-16LE, which PowerShell decodes as ANSI and renders
        # as "W S L   v e r s i o n". Stripping NUL bytes fixes that one without
        # special-casing it, and is a no-op for every other tool here.
        $version = try { (& $tool --version 2>&1 | Select-Object -First 1) -replace "`0", '' }
        catch { 'installed' }
        Write-Row $tool $version
    }
    else { Write-Row $tool 'not installed' }
}

Write-Section 'Checks'

# Two settings are needed for long paths, and having only one is the common
# case: git accepts the path and the filesystem rejects it, or the reverse.
if ((git config --get core.longpaths 2>$null) -eq 'true') { Write-Ok 'git core.longpaths = true' }
else { Write-Warn 'git core.longpaths is not true; deep node_modules trees fail to check out' }

if ((Get-RegistryValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled') -eq 1) {
    Write-Ok 'Windows LongPathsEnabled = 1'
}
else {
    Write-Warn 'Windows long path support is off'
    Write-Note 'elevated: Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem LongPathsEnabled 1'
}

# Without Developer Mode, creating a symlink needs elevation, and the
# installer's failure message is the first sign anything is wrong.
$devMode = Get-RegistryValue `
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
    'AllowDevelopmentWithoutDevLicense'
if ($devMode -eq 1) { Write-Ok 'Developer Mode is on (symlinks work without elevation)' }
else {
    Write-Warn 'Developer Mode is off; creating a symlink needs an elevated shell'
    Write-Note 'Settings > System > For developers > Developer Mode'
}

# Restricted blocks the profile itself, which presents as "my profile does not
# load" with no other clue. Check the effective policy, not the CurrentUser
# scope: Undefined there is normal and falls through to LocalMachine.
$policy = Get-ExecutionPolicy
if ($policy -in @('RemoteSigned', 'Unrestricted', 'Bypass', 'AllSigned')) {
    Write-Ok "execution policy (effective): $policy"
}
else {
    Write-Warn "execution policy is $policy; the profile will not load"
    Write-Note 'Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
}

# Its absence is why bat and delta pick a theme that fights the terminal.
switch ($env:COLORFGBG) {
    '0;15' { Write-Ok 'COLORFGBG = 0;15 (light)' }
    '15;0' { Write-Ok 'COLORFGBG = 15;0 (dark)' }
    $null {
        Write-Warn 'COLORFGBG is unset; bat, delta, and less will guess at the theme'
        Write-Note 'the PowerShell profile sets it; run Update-Theme to re-read it'
    }
    default { Write-Warn "COLORFGBG has an unexpected value: $env:COLORFGBG" }
}

# A duplicated PATH entry usually means a profile is sourced twice.
$pathEntries = $env:PATH -split ';' | Where-Object { $_ }
$dupes = ($pathEntries | Group-Object | Where-Object Count -GT 1).Count
if ($dupes -gt 0) {
    Write-Warn "PATH contains $dupes duplicated entries"
    Write-Note 'run `path` to inspect'
}
else { Write-Ok "PATH has $($pathEntries.Count) entries, no duplicates" }

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitEmail = git config --get user.email 2>$null
    if ($gitEmail) { Write-Ok "git identity: $gitEmail" }
    else {
        Write-Warn 'git user.email is not set; commits will be attributed to nobody'
        Write-Note 'git config --file ~/.gitconfig.local user.email "you@example.com"'
    }

    # core.autocrlf decides whether a script committed from Windows runs
    # anywhere else: `true` rewrites LF to CRLF and breaks what bash sources.
    $autocrlf = git config --get core.autocrlf 2>$null
    if ($autocrlf -eq 'input') { Write-Ok 'git core.autocrlf = input' }
    elseif (-not $autocrlf) { Write-Warn 'git core.autocrlf is unset; a CRLF checkout breaks shell scripts' }
    else { Write-Warn "git core.autocrlf = $autocrlf, expected input" }
}

Write-Host ''
if ($script:Warnings -eq 0) { Write-Host 'No warnings.' -ForegroundColor Green }
else { Write-Host "$($script:Warnings) warning$(if ($script:Warnings -ne 1) { 's' })." -ForegroundColor Yellow }
