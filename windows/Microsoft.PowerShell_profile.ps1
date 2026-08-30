# PowerShell profile.
#
# Installed as $PROFILE.CurrentUserAllHosts, which is
# ~\Documents\PowerShell\profile.ps1 for PowerShell 7 and
# ~\Documents\WindowsPowerShell\profile.ps1 for Windows PowerShell 5.1.
#
# `$PROFILE` alone refers to CurrentUserCurrentHost, which is per-application:
# a profile installed there loads in the console but not in the VS Code
# integrated terminal. CurrentUserAllHosts loads in both.
#
# This is the native Windows shell configuration. Git Bash on the same machine
# uses windows/bashrc. They are separate on purpose: PowerShell is an object
# pipeline, not a text one, and translating the shared sh layer into it would
# produce something worse than either.

# ---------- Theme ----------
# Mirror shared/shell/theme.sh: derive COLORFGBG from the Windows app theme so
# tools that read it (bat, delta, less, several CLIs) match the terminal.
# AppsUseLightTheme: 0 = dark, 1 = light.
$appsUseLight = (Get-ItemProperty `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
        -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme

$env:COLORFGBG = if ($appsUseLight -eq 1) { '0;15' } else { '15;0' }

# Re-read it without restarting the shell, for when you toggle the OS theme
# mid-session.
function Update-Theme {
    $light = (Get-ItemProperty `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' `
            -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
    $env:COLORFGBG = if ($light -eq 1) { '0;15' } else { '15;0' }
    Write-Host "COLORFGBG = $env:COLORFGBG"
}

# ---------- Encoding ----------
# PowerShell 5.1 defaults to the system code page, so redirecting output that
# contains anything outside ASCII produces mojibake. Setting this makes 5.1
# behave like 7, and is a no-op in 7.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---------- Readline ----------
# PSReadLine ships with PowerShell 7 and with 5.1 on current Windows.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    # Up-arrow searches history for what you have already typed rather than
    # walking every command. This is the single biggest interactive improvement
    # available in PowerShell.
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Inline suggestion from history as you type, accepted with Right arrow.
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView

    # Show possible completions as a list on the first Tab rather than cycling
    # through them one at a time.
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Do not record a command containing something that looks like a secret.
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        return $line -notmatch '(?i)(password|secret|token|apikey|api_key|-AsPlainText)'
    }
}

# ---------- Prompt ----------
# Skip when TERM is dumb: several editor terminals and agent CLIs set it, and a
# prompt writing escape codes into a dumb terminal errors on every redraw.
if ((Get-Command starship -ErrorAction SilentlyContinue) -and $env:TERM -ne 'dumb') {
    $env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
    Invoke-Expression (& starship init powershell)
}

# ---------- Aliases ----------
# Set-Alias cannot take arguments, so anything with a flag has to be a function.
# The name shadows the built-in alias where one exists, which is intended.

Set-Alias -Name which -Value Get-Command
Set-Alias -Name g -Value git

function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force @args }

function gs { git status -s @args }
function gd { git diff @args }
function gl { git log --oneline --graph --decorate -20 @args }

# Repository root, matching the `groot` function in the sh layer.
function groot {
    $top = git rev-parse --show-toplevel 2>$null
    if (-not $top) { Write-Error 'not inside a git repository'; return }
    Set-Location $top
}

# PATH, one entry per line.
function Show-Path { $env:PATH -split ';' }
Set-Alias -Name path -Value Show-Path

# Which process is holding a port.
function Get-Port {
    param([Parameter(Mandatory)][int]$Port)
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, State, OwningProcess,
            @{ Name = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } }
}
Set-Alias -Name port -Value Get-Port

# Create a directory and enter it.
function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

# Reload the profile in place.
function reload { . $PROFILE.CurrentUserAllHosts }

# ---------- WSL bridge ----------
# Run a command on the Linux side. See windows/bashrc for the same idea in
# Git Bash and for the caveat about $HOME differing between the two.
#   --exec  so wsl passes positional arguments through
#   bash -ic  so ~/.bashrc runs and version-managed binaries are on PATH
function Invoke-Wsl {
    param([Parameter(Mandatory)][string]$Command, [Parameter(ValueFromRemainingArguments)]$Rest)
    wsl.exe --exec bash -ic "exec $Command `"`$@`"" _ @Rest
}
Set-Alias -Name wslrun -Value Invoke-Wsl

# ---------- Update ----------
# The PowerShell counterpart of update_all in shared/shell/update.sh: run each
# updater, record the outcome, report at the end rather than stopping at the
# first failure.
function Update-Everything {
    $steps = [ordered]@{
        'winget' = { winget upgrade --all --accept-source-agreements --accept-package-agreements --include-unknown }
        'npm'    = { if (Get-Command npm -ErrorAction SilentlyContinue) { npm update -g } else { Write-Host 'npm not installed, skipping.' } }
        'wsl'    = { if (Get-Command wsl.exe -ErrorAction SilentlyContinue) { wsl.exe --exec bash -lc 'sudo apt-get update && sudo apt-get upgrade -y' } else { Write-Host 'wsl not installed, skipping.' } }
    }

    $results = @()
    $i = 0
    foreach ($name in $steps.Keys) {
        $i++
        Write-Host ''
        Write-Host "========== [$i] $name =========="
        try {
            & $steps[$name]
            $ok = ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE)
        } catch {
            Write-Host $_.Exception.Message
            $ok = $false
        }
        $results += [pscustomobject]@{ Step = $name; Status = if ($ok) { 'ok' } else { 'failed' } }
    }

    Write-Host ''
    Write-Host "=== update-everything ==="
    $results | ForEach-Object { Write-Host ("  [{0,-6}] {1}" -f $_.Status, $_.Step) }
}

# ---------- Local overrides ----------
# Machine-specific configuration, not tracked. Same convention as
# ~/.shell.local on the sh side.
$localProfile = Join-Path (Split-Path $PROFILE.CurrentUserAllHosts) 'profile.local.ps1'
if (Test-Path $localProfile) { . $localProfile }
