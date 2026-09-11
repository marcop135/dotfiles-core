# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [semver](https://semver.org/spec/v2.0.0.html), where major means a
change that needs action on a machine already using this.

## [1.1.0] - 2026-09-11

### Added

- `update_all` also updates pipx packages, Homebrew casks, Mac App Store apps,
  and Chocolatey packages. A manager that is not installed is skipped.
- Claude Code denies its own credentials file, raw sockets and SSH tunnels,
  `.env` reads through `head`, `tail`, and `less`, and pushes to `main` and
  `develop`.
- A session can no longer be switched into Claude Code's auto mode, which stops
  asking before it acts. Bypass-permissions mode was already blocked this way.

Both files are symlinked, so an installed machine needs no action.

## [1.0.0] - 2026-08-30

First public version.

[1.1.0]: https://github.com/marcop135/dotfiles-core/releases/tag/v1.1.0
[1.0.0]: https://github.com/marcop135/dotfiles-core/releases/tag/v1.0.0
