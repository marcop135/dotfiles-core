# Changelog

- **Format:** Based on [Keep a Changelog](https://keepachangelog.com).
- **Voice:** Use the imperative, like a commit message. Write add, fix, increase, force, not added, fixed, increased, forced.
- **Length:** Keep each bullet on one line, max 120 characters (link URLs do not count toward the cap, only the visible text does).
- **Links:** Add inline markdown links for related PRs, docs, and external references when they help the reader.

## [Unreleased]

### Added

- Install lazygit and lazydocker from the macOS bootstrap ([#46](https://github.com/marcop135/dotfiles-core/pull/46), [#45](https://github.com/marcop135/dotfiles-core/issues/45)).
- Install lazygit from the WSL bootstrap where apt ships it, Ubuntu 26.04 and later ([#46](https://github.com/marcop135/dotfiles-core/pull/46), [#45](https://github.com/marcop135/dotfiles-core/issues/45)).

## [1.8.0] - 2026-11-05

### Changed

- Move site analytics to a cookieless Matomo Tag Manager container, adding time on page and errors ([#43](https://github.com/marcop135/dotfiles-core/pull/43), [#42](https://github.com/marcop135/dotfiles-core/issues/42)).
- List anonymous interaction events in the site's privacy page ([#43](https://github.com/marcop135/dotfiles-core/pull/43)).

## [1.7.0] - 2026-11-03

### Added

- Select installed Node versions from the nearest `.nvmrc` on macOS and WSL ([#40](https://github.com/marcop135/dotfiles-core/pull/40), [#39](https://github.com/marcop135/dotfiles-core/issues/39)).

## [1.6.0] - 2026-10-24

### Added

- Clear stale npm staging directories before Git Bash `update_npm` to prevent `EINVALIDPACKAGENAME` ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Add site animations and a closing call to action ([#32](https://github.com/marcop135/dotfiles-core/pull/32)).

### Changed

- Cut the site copy: drop the shells section, the section ledes, and two FAQ entries, and shorten the rest ([#32](https://github.com/marcop135/dotfiles-core/pull/32)).
- Rebuild the site manifest diagram for phones: a left spine, shared links listed once, and a fitting excerpt ([#32](https://github.com/marcop135/dotfiles-core/pull/32)).

### Fixed

- Fix the bootstrap nvm installers appending to the linked `~/.zshrc` or `~/.bashrc` inside the repository ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Fix the PowerShell profile erroring on Windows PowerShell 5.1, whose PSReadLine lacks the prediction options ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Fix `Update-Everything` marking a step failed on the previous step's exit code ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Fix the zsh completion cache never being used, because `(#q)` needs `EXTENDED_GLOB` ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Fix `ff` hanging on macOS without ripgrep, where grep reads stdin when given no path ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Fix `doctor.sh` aborting when `SHELL` is unset ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).
- Fix the WSL `open` breaking on a URL with a single quote, and running with no argument ([#32](https://github.com/marcop135/dotfiles-core/pull/32), [#37](https://github.com/marcop135/dotfiles-core/issues/37)).

## [1.5.2] - 2026-10-23

### Changed

- Update the README ([#30](https://github.com/marcop135/dotfiles-core/pull/30)).

### Fixed

- Fix `install.sh --only` and `--skip` exiting silently without a module list ([#30](https://github.com/marcop135/dotfiles-core/pull/30), [#36](https://github.com/marcop135/dotfiles-core/issues/36)).
- Fix `up` accepting a non-numeric level count ([#30](https://github.com/marcop135/dotfiles-core/pull/30), [#36](https://github.com/marcop135/dotfiles-core/issues/36)).

## [1.5.1] - 2026-10-17

### Changed

- Fold the README's Claude Code settings list into a collapsible block ([#28](https://github.com/marcop135/dotfiles-core/pull/28)).
- Merge the README install steps into one POSIX and one PowerShell block, as on the site ([#28](https://github.com/marcop135/dotfiles-core/pull/28)).
- Reduce the README contributing section to the gate commands and a table of the project documents ([#28](https://github.com/marcop135/dotfiles-core/pull/28)).
- Add the PowerShell update and uninstall commands to the README ([#28](https://github.com/marcop135/dotfiles-core/pull/28)).
- List the missing aliases and `scripts/check-site.sh` in the README ([#28](https://github.com/marcop135/dotfiles-core/pull/28)).

### Removed

- Remove the CI, release, and license badges from the README ([#28](https://github.com/marcop135/dotfiles-core/pull/28)).

## [1.5.0] - 2026-10-17

### Added

- Add site FAQ entries on local aliases, link status, and why the files are symlinked ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).
- Animate the site FAQ answers as they open and close, except under reduced motion ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).

### Changed

- Start the site's terminal and manifest animations only once the figure is fully on screen ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).
- Match the site footer to the other project sites, with a two-column link grid on phones ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).
- Replace the broken connector lines in the phone layout of the site manifest diagram with one drop into the cards ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).
- Rename the site FAQ to "Questions answered", aligned with the README ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).
- Trim the site copy ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).

### Removed

- Remove the shared-function list from the site, which the README carries in full ([#25](https://github.com/marcop135/dotfiles-core/pull/25)).

## [1.4.2] - 2026-10-16

### Fixed

- Report site analytics to its own self-hosted Matomo property instead of the shared one ([#23](https://github.com/marcop135/dotfiles-core/pull/23), [#38](https://github.com/marcop135/dotfiles-core/issues/38)).

## [1.4.1] - 2026-10-16

### Changed

- Shorten the brand image tagline to "One shell for macOS, Win, and WSL" across README, social and Open Graph ([#21](https://github.com/marcop135/dotfiles-core/pull/21)).

## [1.4.0] - 2026-10-16

### Added

- Add the [dotfiles.marcopontili.com](https://dotfiles.marcopontili.com) site under `site/`, with a privacy page and cookieless Matomo ([#18](https://github.com/marcop135/dotfiles-core/pull/18)) ([#38](https://github.com/marcop135/dotfiles-core/issues/38)).
- Add `site/.htaccess` with headers, a self/Matomo-only CSP, caching and error pages ([#18](https://github.com/marcop135/dotfiles-core/pull/18), [#38](https://github.com/marcop135/dotfiles-core/issues/38)).
- Add `deploy.yml` to mirror `site/` over SFTP or FTPS on `main` pushes, then purge Cloudflare ([#18](https://github.com/marcop135/dotfiles-core/pull/18), [#38](https://github.com/marcop135/dotfiles-core/issues/38)).
- Add `scripts/check-site.sh` for page structure and internal links, run by CI and before every deploy ([#18](https://github.com/marcop135/dotfiles-core/pull/18)) ([#38](https://github.com/marcop135/dotfiles-core/issues/38)).

## [1.3.0] - 2026-10-15

### Added

- Override Git for Windows `bell-style visible` so Tab completion no longer flashes Windows Terminal ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).
- Widen the Claude Code deny floor for secret env files, keys, force-push, `master`, and `gh api` ref writes ([#15](https://github.com/marcop135/dotfiles-core/pull/15)) ([#35](https://github.com/marcop135/dotfiles-core/issues/35)).

### Changed

- Document the private-to-core promotion bar under Constraints in [`AGENTS.md`](https://github.com/marcop135/dotfiles-core/blob/develop/AGENTS.md) ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).
- Refresh the README, social, and Open Graph images under [`.github/brand/`](https://github.com/marcop135/dotfiles-core/tree/develop/.github/brand) ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).

## [1.2.1] - 2026-10-05

### Changed

- Use Keep a Changelog sections, Format/Voice/Length/Links preamble and inline links ([#7](https://github.com/marcop135/dotfiles-core/pull/7), [#10](https://github.com/marcop135/dotfiles-core/pull/10)).

## [1.2.0] - 2026-10-01

### Added

- Add [`CONTRIBUTING.md`](https://github.com/marcop135/dotfiles-core/blob/develop/CONTRIBUTING.md), [`SUPPORT.md`](https://github.com/marcop135/dotfiles-core/blob/develop/SUPPORT.md), and a Contributor Covenant `CODE_OF_CONDUCT.md` ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).
- Add bug and change-request issue forms that ask for the platform and shell ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).
- Add an issue chooser that turns blank issues off and routes questions to Discussions ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).
- Add a pull request template that asks where the change was exercised ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).
- Add README, Open Graph, and social preview images in [`.github/brand/`](https://github.com/marcop135/dotfiles-core/tree/develop/.github/brand), rendered from SVG sources ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).

### Changed

- Name the supported version and the reply window in [`SECURITY.md`](https://github.com/marcop135/dotfiles-core/blob/develop/SECURITY.md) ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).
- Tighten the Claude Code instructions on file density, server URLs, rebuilds, worktrees and task endings ([#4](https://github.com/marcop135/dotfiles-core/pull/4)).
- Link Starship once in the README, where it is first named ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).
- Replace the old `.github/` social preview SVG and PNG with [`.github/brand/readme.png`](https://github.com/marcop135/dotfiles-core/blob/develop/.github/brand/readme.png) ([#5](https://github.com/marcop135/dotfiles-core/pull/5)).

## [1.1.0] - 2026-09-11

### Added

- Extend `update_all` to pipx, Homebrew casks, Mac App Store apps, and Chocolatey, skipping absent managers ([#1](https://github.com/marcop135/dotfiles-core/pull/1), [#34](https://github.com/marcop135/dotfiles-core/issues/34)).
- Deny Claude Code credentials, raw sockets, SSH tunnels, `.env` pagers and pushes to `main` and `develop` ([#1](https://github.com/marcop135/dotfiles-core/pull/1), [#35](https://github.com/marcop135/dotfiles-core/issues/35)).
- Block switching a Claude Code session into auto mode, as bypass-permissions mode already was ([#1](https://github.com/marcop135/dotfiles-core/pull/1), [#35](https://github.com/marcop135/dotfiles-core/issues/35)).

## [1.0.0] - 2026-08-30

### Added

- Publish the first public version.
