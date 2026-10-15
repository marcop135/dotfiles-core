---
title: "dotfiles-core: one shell setup for macOS, Windows, and WSL"
canonical: https://dotfiles.marcopontili.com/
description: Cross-platform dotfiles for zsh, bash, Git Bash, and PowerShell. One shared sh layer, one manifest, symlinks into your home folder.
dateModified: 2026-10-15
---

# dotfiles-core

**dotfiles-core** is the shared part of a cross-platform dotfiles setup for macOS, Windows, and WSL. Four shells read the same shared `sh` layer, one manifest decides what is linked where, and the repository stays the source of truth on every machine. Identity, employer, and machine-specific configuration stays local.

- Repository: [github.com/marcop135/dotfiles-core](https://github.com/marcop135/dotfiles-core)
- License: MIT

## One manifest, three home folders

`scripts/modules.conf` is the single manifest read by both installers and the check script. Files are linked, not copied.

| Platform | Shells | Links |
| --- | --- | --- |
| macOS | zsh | `~/.zshrc`, `~/.config/starship.toml`, `~/.gitconfig`, `~/.config/git/ignore`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json` |
| Windows | Git Bash, PowerShell | `~/.bashrc`, `~/.bash_profile`, `$PROFILE.CurrentUserAllHosts`, `~/.config/starship.toml`, `~/.gitconfig`, `~/.config/git/ignore`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json` |
| WSL | bash | `~/.bashrc`, `~/.config/starship.toml`, `~/.gitconfig`, `~/.config/git/ignore`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json` |

## Four shells, one shared layer

| Platform | Shell | Entry point |
| --- | --- | --- |
| macOS | zsh | `macos/zshrc` |
| Windows | Git Bash | `windows/bashrc` + `windows/bash_profile` |
| Windows | PowerShell | `windows/Microsoft.PowerShell_profile.ps1` |
| WSL | bash | `wsl/bashrc` |

The POSIX shells source `shared/shell/`. PowerShell has its own entry point because it cannot source POSIX shell configuration.

Shared functions: `mkcd`, `up`, `groot`, `path`, `port`, `serve`, `extract`, `ff`, `sizes`, `update_all`.

## Safe to run on a machine you care about

- Dry run by default. Only `--apply`, or `-Apply` in PowerShell, writes anything.
- Nothing is deleted. An existing file is renamed to `<target>.bak.<timestamp>` before a link replaces it.
- Private stays local. Every rc file sources an untracked `*.local` sibling last.
- `--unlink` removes only symlinks that point into the repository; `--restore` puts the backups back.

## Install

macOS, WSL, and Git Bash:

```sh
git clone https://github.com/marcop135/dotfiles-core.git ~/code/dotfiles-core
cd ~/code/dotfiles-core
./scripts/install.sh          # dry run: read the plan
./scripts/install.sh --apply  # then link it
```

Windows PowerShell:

```powershell
git clone https://github.com/marcop135/dotfiles-core.git ~/code/dotfiles-core
cd ~/code/dotfiles-core
.\scripts\install.ps1         # dry run: read the plan
.\scripts\install.ps1 -Apply  # then link it
```

Needs `git` and one supported shell. Starship is optional. Windows symlinks need Developer Mode or an elevated shell.

## Questions

### What does it need to run?

Git and one supported shell: zsh on macOS, Git Bash or PowerShell on Windows, bash on WSL. No runtime or package manager to install.

### What is not included?

Git identity, employer and client configuration, package lists, macOS system settings, and editor and terminal settings.

### How do I update it?

Run `git pull` and `./scripts/install.sh --apply` again. The installer is idempotent.

### How do I uninstall it?

Run `./scripts/install.sh --unlink --restore --apply`. It removes only the symlinks that point into the repository and puts the backups back.

### What does the Claude Code part do?

It links two user-level files, `CLAUDE.md` and `settings.json`. The settings turn off telemetry and the auto-updater, keep commands behind approval, and deny secret files, force-push, and pushes to `main`. The deny rules are a safety floor, not a sandbox.

## Links

- [README](https://github.com/marcop135/dotfiles-core#readme)
- [CHANGELOG](https://github.com/marcop135/dotfiles-core/blob/main/CHANGELOG.md)
- [Privacy](https://dotfiles.marcopontili.com/privacy.html)
- Author: [Marco Pontili](https://marcopontili.com)
