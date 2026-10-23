# Changelog

- **Format:** Based on [Keep a Changelog](https://keepachangelog.com).
- **Voice:** Use the imperative, like a commit message. Write add, fix, increase, force, not added, fixed, increased, forced.
- **Length:** Keep each bullet on one line, max 120 characters (link URLs do not count toward the cap, only the visible text does).
- **Links:** Add inline markdown links for related PRs, docs, and external references when they help the reader.

## [1.5.2] - 2026-10-23

### Changed

- Move the README author line above the license, matching the site footer.
- Link the project site from the README author line.

### Fixed

- Make `install.sh --only` and `--skip` exit with a usage message when the module list is missing.
- Make `up` reject a non-numeric level count instead of printing a test error and staying put.
- Restore the 1.0.0 to 1.2.0 changelog bullets that the one-line-per-bullet conversion cut short.

## [1.5.1] - 2026-10-17

### Changed

- Fold the README's Claude Code settings list into a collapsible block.
- Merge the README install steps into one POSIX and one PowerShell block, as on the site.
- Reduce the README contributing section to the gate commands and a table of the project documents.
- Add the PowerShell update and uninstall commands to the README.
- List the missing aliases and `scripts/check-site.sh` in the README.

### Removed

- Remove the CI, release, and license badges from the README.

## [1.5.0] - 2026-10-17

### Added

- Add site FAQ entries on local aliases, link status, and why the files are symlinked.
- Animate the site FAQ answers as they open and close, except under reduced motion.

### Changed

- Start the site's terminal and manifest animations only once the figure is fully on screen.
- Match the site footer to the other project sites, with a two-column link grid on phones.
- Replace the broken connector lines in the phone layout of the site manifest diagram with one drop into the cards.
- Rename the site FAQ to "Questions answered", aligned with the README.
- Trim the site copy.

### Removed

- Remove the shared-function list from the site, which the README carries in full.

## [1.4.2] - 2026-10-16

### Fixed

- Report site analytics to its own self-hosted Matomo property instead of the shared one.

## [1.4.1] - 2026-10-16

### Changed

- Shorten the brand image tagline to "One shell for macOS, Win, and WSL" in the README, social, and Open Graph images.

## [1.4.0] - 2026-10-16

### Added

- Add the [dotfiles.marcopontili.com](https://dotfiles.marcopontili.com) site under `site/`, with a privacy page and cookieless Matomo ([#18](https://github.com/marcop135/dotfiles-core/pull/18)).
- Add `site/.htaccess` with security headers, a CSP limited to self and self-hosted Matomo, caching, and error pages.
- Add `deploy.yml` to mirror `site/` to Netsons over SFTP or FTPS on push to `main`, then purge the Cloudflare cache.
- Add `scripts/check-site.sh` for page structure and internal links, run by CI and before every deploy ([#18](https://github.com/marcop135/dotfiles-core/pull/18)).

## [1.3.0] - 2026-10-15

### Added

- Override Git for Windows `bell-style visible` so Tab completion no longer flashes Windows Terminal ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).
- Widen the Claude Code deny floor for secret env files, keys, force-push, `master`, and `gh api` ref writes ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).

### Changed

- Document the private-to-core promotion bar under Constraints in [`AGENTS.md`](https://github.com/marcop135/dotfiles-core/blob/develop/AGENTS.md) ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).
- Refresh the README, social, and Open Graph images under [`.github/brand/`](https://github.com/marcop135/dotfiles-core/tree/develop/.github/brand).

## [1.2.1] - 2026-10-05

### Changed

- Standardize the changelog on Keep a Changelog sections with a Format/Voice/Length/Links preamble and inline links.

## [1.2.0] - 2026-10-01

### Added

- Add [`CONTRIBUTING.md`](https://github.com/marcop135/dotfiles-core/blob/develop/CONTRIBUTING.md), [`SUPPORT.md`](https://github.com/marcop135/dotfiles-core/blob/develop/SUPPORT.md), and a Contributor Covenant `CODE_OF_CONDUCT.md`.
- Add bug and change-request issue forms that ask for the platform and shell.
- Add an issue chooser that turns blank issues off and routes questions to Discussions.
- Add a pull request template that asks where the change was exercised.
- Add README, Open Graph, and social preview images in [`.github/brand/`](https://github.com/marcop135/dotfiles-core/tree/develop/.github/brand), rendered from SVG sources.

### Changed

- Name the supported version and the reply window in [`SECURITY.md`](https://github.com/marcop135/dotfiles-core/blob/develop/SECURITY.md).
- Tighten the Claude Code instructions on written-file density, server URLs, rebuilds, worktrees, and where a task ends.
- Link Starship once in the README, where it is first named.
- Replace the old `.github/` social preview SVG and PNG with [`.github/brand/readme.png`](https://github.com/marcop135/dotfiles-core/blob/develop/.github/brand/readme.png).

## [1.1.0] - 2026-09-11

### Added

- Extend `update_all` to pipx, Homebrew casks, Mac App Store apps, and Chocolatey, skipping any manager not installed.
- Deny Claude Code its credentials file, raw sockets, SSH tunnels, `.env` pagers, and pushes to `main` and `develop`.
- Block switching a Claude Code session into auto mode, as bypass-permissions mode already was.

## [1.0.0] - 2026-08-30

### Added

- Publish the first public version.
