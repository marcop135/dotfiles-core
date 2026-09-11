# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [semver](https://semver.org/spec/v2.0.0.html), where major means a
change that needs action on a machine already using this.

## [1.1.0] - 2026-09-11

### Added

- `update_all` covers more of what a machine actually has installed. It already
  updated npm packages and one system package manager per platform; it now also
  updates pipx packages everywhere, Homebrew casks and Mac App Store apps on
  macOS, and Chocolatey packages under Git Bash. A manager that is not installed
  prints one line and is skipped, so the run still succeeds.
- Claude Code denies more without being asked: reading its own credentials file,
  opening raw sockets and SSH tunnels, reading a `.env` file through `head`,
  `tail`, or `less`, and pushing to `main`, `master`, or `develop`. The deny
  rules remain a safety floor rather than a sandbox.
- Claude Code auto mode is switched off, as bypass-permissions mode already was.

Nothing to do on a machine that already has this installed. Both files are
symlinked, so the next shell and the next Claude Code session pick the changes
up on their own.

## [1.0.0] - 2026-08-30

First public version.

[1.1.0]: https://github.com/marcop135/dotfiles-core/releases/tag/v1.1.0
[1.0.0]: https://github.com/marcop135/dotfiles-core/releases/tag/v1.0.0
