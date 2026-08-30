<#
.SYNOPSIS
    End-to-end test for scripts/install.ps1 against a throwaway home directory.

.DESCRIPTION
    The PowerShell counterpart of scripts/test-install.sh, and the same
    argument: the installer is the only thing here that writes outside the
    repository, and a dry run proves nothing about the path that does the
    writing.

    Only the `prompt` module is exercised. The `shell` entry installs to
    $PROFILE.CurrentUserAllHosts, which is fixed by the host process and does
    not follow a scratch home, so applying it would touch the real profile.

    Safe to run on a real machine: $env:USERPROFILE is redirected for the whole
    run and the temporary directory is removed at the end.

.EXAMPLE
    pwsh -File .\scripts\test-install.ps1
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $PSScriptRoot 'install.ps1'

$script:Pass = 0
$script:Fail = 0

function Assert-That {
    param([string]$What, [bool]$Condition)

    if ($Condition) {
        Write-Host "  ok    $What"
        $script:Pass++
    }
    else {
        Write-Host "  FAIL  $What"
        $script:Fail++
    }
}

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
$realProfile = $env:USERPROFILE
$env:USERPROFILE = $sandbox

try {
    Write-Host "sandbox: $sandbox"
    Write-Host ''

    $target = Join-Path $sandbox '.config\starship.toml'

    Write-Host '-Apply creates the link'
    & $Installer -Apply -Only prompt 6> $null
    Assert-That 'the target exists' (Test-Path -LiteralPath $target)

    $item = Get-Item -LiteralPath $target -Force
    Assert-That 'it is a symlink' ($item.LinkType -eq 'SymbolicLink')

    # It must resolve back into the repository. A copy looks installed and never
    # picks up a change, which is the failure this asserts against.
    $linkTarget = if ($item.Target -is [array]) { $item.Target[0] } else { $item.Target }
    Assert-That 'it points into the repository' ($linkTarget -like "$Root*")

    Write-Host ''
    Write-Host '-Status reports it linked'
    # 6>&1 folds the information stream into the pipeline. install.ps1 reports
    # with Write-Host, which does not otherwise reach a variable.
    $status = & $Installer -Status -Only prompt 6>&1
    Assert-That 'state is linked' (($status -join "`n") -match '\blinked\b')

    Write-Host ''
    Write-Host 'a second -Apply changes nothing'
    $second = & $Installer -Apply -Only prompt 6>&1
    Assert-That 'idempotent' (($second -join "`n") -match '(?m)^0 changed')

    Write-Host ''
    Write-Host 'an existing real file is backed up, not destroyed'
    Remove-Item -LiteralPath $target -Force
    'original contents' | Set-Content -LiteralPath $target
    & $Installer -Apply -Only prompt 6> $null
    Assert-That 'the target is a link again' ((Get-Item -LiteralPath $target -Force).LinkType -eq 'SymbolicLink')

    $backup = Get-ChildItem -LiteralPath (Split-Path -Parent $target) -Filter 'starship.toml.bak.*' -Force |
        Sort-Object Name | Select-Object -Last 1
    Assert-That 'a backup was written' ($null -ne $backup)
    if ($backup) {
        Assert-That 'the original file survived in it' ((Get-Content -LiteralPath $backup.FullName -Raw).Trim() -eq 'original contents')
    }

    Write-Host ''
    Write-Host '-Unlink removes the link and leaves the backup'
    & $Installer -Unlink -Apply -Only prompt 6> $null
    Assert-That 'the link is gone' (-not (Test-Path -LiteralPath $target))
    Assert-That 'the backup was left alone' (Test-Path -LiteralPath $backup.FullName)

    Write-Host ''
    Write-Host '-Unlink -Restore puts the original back'
    & $Installer -Apply -Only prompt 6> $null
    & $Installer -Unlink -Restore -Apply -Only prompt 6> $null
    $restored = Test-Path -LiteralPath $target
    Assert-That 'the target is back' $restored
    if ($restored) {
        $item = Get-Item -LiteralPath $target -Force
        Assert-That 'it is a real file, not a link' ($item.LinkType -ne 'SymbolicLink')
        Assert-That 'with the original contents' ((Get-Content -LiteralPath $target -Raw).Trim() -eq 'original contents')
    }

    Write-Host ''
    Write-Host 'a foreign symlink is never touched'
    Remove-Item -LiteralPath $target -Force
    # Windows PowerShell refuses to create a symlink to a path that does not
    # exist, so the decoy target has to be a real file.
    $elsewhere = Join-Path $sandbox 'somewhere-else'
    'not ours' | Set-Content -LiteralPath $elsewhere
    New-Item -ItemType SymbolicLink -Path $target -Target $elsewhere -Force | Out-Null
    & $Installer -Unlink -Apply -Only prompt 6> $null
    Assert-That 'still there' (Test-Path -LiteralPath $target)
}
finally {
    $env:USERPROFILE = $realProfile
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($script:Fail -eq 0) {
    Write-Host "$script:Pass passed."
    exit 0
}
Write-Host "$script:Fail failed, $script:Pass passed."
exit 1
