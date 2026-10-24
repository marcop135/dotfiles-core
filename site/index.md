---
title: "dotfiles-core: one shell setup for macOS, Windows, and WSL"
canonical: https://dotfiles.marcopontili.com/
description: Cross-platform dotfiles for zsh, bash, Git Bash, and PowerShell. One shared sh layer, one manifest, symlinks into your home folder.
dateModified: 2026-10-24
---

# dotfiles-core

**dotfiles-core** is cross-platform dotfiles for macOS, Windows, and WSL. Four shells share one `sh` layer, and one manifest decides what gets linked where.

- Repository: [github.com/marcop135/dotfiles-core](https://github.com/marcop135/dotfiles-core)
- License: MIT

## One manifest, three home folders

Both installers read `scripts/modules.conf` and link, never copy. zsh and both bashes source `shared/shell/`; PowerShell has its own profile.

| Platform | Shells | Shell entry points | Links |
| --- | --- | --- | --- |
| macOS | zsh | `~/.zshrc` | 6 |
| Windows | Git Bash, PowerShell | `~/.bashrc`, `~/.bash_profile`, `$PROFILE` | 7 from Git Bash, 6 from PowerShell |
| WSL | bash | `~/.bashrc` | 6 |

Plus five on every platform: `~/.config/starship.toml`, `~/.gitconfig`, `~/.config/git/ignore`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`.

## Safe to run on a machine you care about

1. Dry run by default. Nothing is written without `--apply`, or `-Apply` in PowerShell.
2. Nothing is deleted. An existing file moves to `<target>.bak.<timestamp>` first.
3. Private stays local. No identity is tracked. Every rc file sources an untracked `*.local` file last.
4. Clean uninstall. `--unlink` removes only its own links; `--restore` brings the backups back.

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

Needs `git`. Starship is optional. Windows symlinks need Developer Mode or an elevated shell.

## FAQ

### Why symlinks instead of copies?

The repository stays the only copy: an edit to `~/.zshrc` shows in `git diff`, and `git pull` reaches every machine.

### Where do my own aliases go?

In `~/.shell.local`, or `profile.local.ps1` next to the PowerShell profile. Both load last, so they win.

### How do I update it?

`git pull`, then run the installer with `--apply` again. Links already in place are left alone.

### What does the Claude Code part do?

It links `CLAUDE.md` and `settings.json`: telemetry and auto-update off, commands behind approval, and secret files, `rm -rf`, force-push, and pushes to `main` denied. A safety floor, not a sandbox.

## Links

- [README](https://github.com/marcop135/dotfiles-core#readme)
- [CHANGELOG](https://github.com/marcop135/dotfiles-core/blob/main/CHANGELOG.md)
- [Privacy](https://dotfiles.marcopontili.com/privacy.html)
- Author: [Marco Pontili](https://marcopontili.com)
