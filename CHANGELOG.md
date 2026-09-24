# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [semver](https://semver.org/spec/v2.0.0.html), where major means a
change that needs action on a machine already using this.

## [Unreleased]

### Added

- `CONTRIBUTING.md`, `SUPPORT.md`, and a Contributor Covenant
  `CODE_OF_CONDUCT.md`.
- Issue forms for a bug and a change request, both asking which platform and
  shell, a chooser that turns blank issues off and routes questions to
  Discussions, and a pull request template that asks where the change was
  exercised.
- `SECURITY.md` now names the supported version and the reply window.

### Changed

- The Claude Code instructions hold a written file to the same density as a
  reply: a README, changelog, release note, or PR body grows by replacing
  rather than appending.
- They also ask for the local server URL in the final message, a rebuild before
  a change is called visible, a worktree rather than a second repository, and
  the integration branch as the place a task ends.
- The README links Starship once, where it is first named.

The instructions file is symlinked, so an installed machine needs no action.

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
