## What changed

<!-- One line on the change, then why it is needed. -->

Closes #

## Exercised on

<!-- Tick what you actually ran it on. CI covers the rest. -->

- [ ] macOS, zsh
- [ ] Windows, Git Bash
- [ ] Windows, PowerShell
- [ ] WSL, bash

## Gate

- [ ] `bash ./scripts/check.sh` exits 0
- [ ] `bash ./scripts/test-install.sh` exits 0
- [ ] `.\scripts\test-install.ps1` exits 0, for a change touching the PowerShell installer
- [ ] A new or moved link is in `scripts/modules.conf` and in the README manifest table
- [ ] No identity, token, employer name, or machine-specific path in a tracked file
- [ ] `CHANGELOG.md` updated under `[Unreleased]`, for a change worth recording

[Contributing guide](https://github.com/marcop135/dotfiles-core/blob/main/CONTRIBUTING.md)
