# Security

Only the latest release is supported. Installed files are symlinks into a
clone, so updating is `git pull` and a re-run of the installer, and there is no
older version left on a machine to patch separately.

Both installers and both bootstrap scripts take a dry run by default: nothing
changes until you pass `--apply`, and reading the plan first is what the default
is for. Nothing is ever deleted, only backed up.

The installers, the doctors, and the gate fetch nothing at all. The two
bootstrap scripts are the exception, and only under `--apply`: between them they
run the upstream installers for Homebrew, nvm, and Starship, and all three are
the vendors' own `curl | sh` one-liners. nvm is pinned to a release tag.
Homebrew and Starship publish no versioned installer to pin to, so those two
follow a moving target, which is the reason they are called out here rather than
buried in a comment. Install any of the three yourself and the step becomes a
no-op on the next run. Nothing else in this repository pipes a downloaded script
to a shell, and no instruction in it will ever ask you to.

For a credential, token, or personal detail found in the tree or the history,
use GitHub's private vulnerability reporting rather than opening an issue, so
the finding is not published before it is removed. Expect an acknowledgement
within seven days. This is a personal repository, so that is a habit rather
than a service level, and anything credential-shaped is treated as urgent
regardless.
