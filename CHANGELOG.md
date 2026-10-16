# Changelog

- **Format:** Based on [Keep a Changelog](https://keepachangelog.com).
- **Voice:** Use the imperative, like a commit message. Write add, fix, increase, force, not added, fixed, increased, forced.
- **Length:** Keep each bullet on one line, max 120 characters (link URLs do not count toward the cap, only the visible text does).
- **Links:** Add inline markdown links for related PRs, docs, and external references when they help the reader.

## [Unreleased]

### Added

- Add the static site for [dotfiles.marcopontili.com](https://dotfiles.marcopontili.com) under `site/`, with privacy page and cookieless Matomo.
- Add `site/.htaccess` with security headers, a CSP limited to self and `mt.marcopontili.com`, caching, and error pages.
- Add `deploy.yml` to mirror `site/` to Netsons over SFTP or FTPS on push to `main`, then purge the Cloudflare host cache.
- Add `scripts/check-site.sh` for page structure and internal links, run by CI and before every deploy.

## [1.3.0] - 2026-10-15

### Added

- Override Git for Windows `bell-style visible` so Tab completion no longer flashes Windows Terminal ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).
- Widen the Claude Code deny floor for secret env files, keys, force-push, `master`, and `gh api` ref writes ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).

### Changed

- Document the private-to-core promotion bar under Constraints in [`AGENTS.md`](https://github.com/marcop135/dotfiles-core/blob/develop/AGENTS.md) ([#15](https://github.com/marcop135/dotfiles-core/pull/15)).
- Refresh README, social, and Open Graph brand images under [`.github/brand/`](https://github.com/marcop135/dotfiles-core/tree/develop/.github/brand).

## [1.2.1] - 2026-10-05

### Changed

- Standardize the changelog on Keep a Changelog sections with Format/Voice/Length/Links preamble and inline links.

## [1.2.0] - 2026-10-01

### Added

- [`CONTRIBUTING.md`](https://github.com/marcop135/dotfiles-core/blob/develop/CONTRIBUTING.md), [`SUPPORT.md`](https://github.com/marcop135/dotfiles-core/blob/develop/SUPPORT.md), and a Contributor Covenant
- Issue forms for a bug and a change request, both asking which platform and
- [`SECURITY.md`](https://github.com/marcop135/dotfiles-core/blob/develop/SECURITY.md) now names the supported version and the reply window.
- README, Open Graph, and GitHub social preview images in [`.github/brand/`](https://github.com/marcop135/dotfiles-core/blob/develop/.github/brand/),

### Changed

- The Claude Code instructions hold a written file to the same density as a
- They also ask for the local server URL in the final message, a rebuild before
- The README links Starship once, where it is first named.
- The README image is [`.github/brand/readme.png`](https://github.com/marcop135/dotfiles-core/blob/develop/.github/brand/readme.png); the old social preview SVG

## [1.1.0] - 2026-09-11

### Added

- `update_all` also updates pipx packages, Homebrew casks, Mac App Store apps,
- Claude Code denies its own credentials file, raw sockets and SSH tunnels,
- A session can no longer be switched into Claude Code's auto mode, which stops

## [1.0.0] - 2026-08-30
