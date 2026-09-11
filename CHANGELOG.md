# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [semver](https://semver.org/spec/v2.0.0.html), where major means a
change that needs action on a machine already using this.

## [1.1.0] - 2026-09-11

### Added

- `update_pipx`, `update_brew_cask`, `update_mas`, and `update_choco` in
  `shared/shell/update.sh`, each a no-op when its manager is absent, and all
  four wired into `update_all` for the platform they apply to.
- Claude Code deny rules for the credentials file, raw sockets and outbound
  tunnels, `.env` reads through `head`, `tail`, and `less`, and pushes to
  `main`, `master`, and `develop`.
- Claude Code auto mode is disabled alongside bypass-permissions mode.

Both files are already symlinked, so an existing machine picks this up on the
next shell and the next session with no re-install.

## [1.0.0] - 2026-08-30

First public version.

[1.1.0]: https://github.com/marcop135/dotfiles-core/releases/tag/v1.1.0
[1.0.0]: https://github.com/marcop135/dotfiles-core/releases/tag/v1.0.0
