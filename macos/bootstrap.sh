#!/usr/bin/env bash
# Bring a fresh Mac to a usable development state.
#
#   ./macos/bootstrap.sh            # dry run: list what would be installed
#   ./macos/bootstrap.sh --apply
#
# The macOS counterpart of wsl/bootstrap.sh, and it stops in the same place:
# Command Line Tools, Homebrew, a short list of CLI tools, a Node version
# manager, and the prompt. Language runtimes, databases, and anything
# project-specific belong in the project, not in a machine bootstrap.
#
# No `defaults write`. Dock, Finder, trackpad, and screenshot settings are
# personal rather than portable, they are not shell configuration, and the
# README says this repository does not carry them.
#
# Safe to run more than once: `brew install` on an installed formula is a no-op,
# and every step checks before acting.
set -euo pipefail

# Help is the header block itself; see scripts/install.sh for why it is read
# rather than hard coded. An unknown argument is an error rather than a silent
# dry run, so a typo cannot look like a deliberate plan.
APPLY=false
case ${1-} in
  '') ;;
  --apply) APPLY=true ;;
  -h | --help)
    awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *) echo "bootstrap.sh: unknown option: $1" >&2; exit 2 ;;
esac

if [[ $(uname -s) != Darwin ]]; then
  echo 'bootstrap.sh: this only runs on macOS.' >&2
  echo 'The WSL and Ubuntu equivalent is ./wsl/bootstrap.sh.' >&2
  exit 1
fi

section() { printf '\n== %s ==\n' "$1"; }

$APPLY || echo 'Dry run. Nothing will change. Re-run with --apply.'

# ---------- Command Line Tools ----------
# git, clang, make, and the system headers. Homebrew needs them, and so does
# every native npm module. `xcode-select --install` opens a GUI dialog and
# returns immediately, so this reports rather than waits: a background download
# that the script pretends to have finished is worse than an instruction.
section 'Command Line Tools'
if xcode-select -p >/dev/null 2>&1; then
  echo "  installed at $(xcode-select -p)"
else
  echo '  NOT installed. Run `xcode-select --install`, accept the dialog, wait for'
  echo '  it to finish, then re-run this script. Everything below needs it.'
  # A dry run still prints the rest of the plan; an --apply run has nothing to
  # build on and stops here. Written as an `if` rather than `$APPLY && exit 1`,
  # which under `set -e` would end the dry run too.
  if $APPLY; then exit 1; fi
fi

# ---------- Homebrew ----------
# The one thing here fetched over the network and piped to a shell, and the
# vendor's own documented one-liner. It is not pinned because Homebrew does not
# publish a versioned installer to pin to. See SECURITY.md; to avoid it, install
# Homebrew yourself and re-run, and this step becomes a no-op.
#
# Apple silicon installs under /opt/homebrew, Intel under /usr/local. Probing
# both is what macos/zshrc does, for the same reason.
section 'Homebrew'
BREW=''
for _prefix in /opt/homebrew /usr/local; do
  if [[ -x $_prefix/bin/brew ]]; then
    BREW="$_prefix/bin/brew"
    break
  fi
done

if [[ -n $BREW ]]; then
  echo "  already installed at $BREW"
elif $APPLY; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for _prefix in /opt/homebrew /usr/local; do
    if [[ -x $_prefix/bin/brew ]]; then
      BREW="$_prefix/bin/brew"
      break
    fi
  done
  [[ -n $BREW ]] || { echo 'bootstrap.sh: Homebrew install did not produce a brew binary.' >&2; exit 1; }
else
  echo '  would install Homebrew from https://brew.sh'
fi

# Put brew on PATH for the rest of this run. A new shell gets it from
# macos/zshrc, but this script cannot wait for one.
if [[ -n $BREW ]]; then
  eval "$("$BREW" shellenv)"
fi

# ---------- Formulae ----------
# One list, one brew call. The Debian side of this needs a rename workaround for
# `fd` and `bat`; Homebrew ships both under their real names, so there is no
# equivalent section below.
FORMULAE=(
  git         # newer than the one in Command Line Tools
  wget
  jq
  ripgrep     # rg
  fd
  bat
  tree
  htop
  pipx        # pulls a Homebrew python3 with it
  starship    # the prompt; see shared/starship.toml
)

section 'formulae'
if $APPLY; then
  brew update
  brew install "${FORMULAE[@]}"
else
  printf '  would install: %s\n' "${FORMULAE[*]}"
fi

# ---------- Node ----------
# nvm from the pinned upstream installer rather than `brew install nvm`: the
# formula puts nvm.sh in the Cellar, and macos/zshrc loads it lazily from
# $NVM_DIR, which is ~/.nvm. Same version as wsl/bootstrap.sh, so both machines
# get the same layout.
section 'nvm and Node LTS'
if [[ -d ${NVM_DIR:-$HOME/.nvm} ]]; then
  echo '  nvm already installed, skipping.'
elif $APPLY; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
else
  echo '  would install nvm and the current Node LTS'
fi

# ---------- Checks ----------
section 'environment checks'

# A brew under /usr/local on an arm64 Mac means the shell is running through
# Rosetta, and every formula it installs is an x86 build. It works, it is slow,
# and the cause is invisible from the symptom.
if [[ $(uname -m) == arm64 && ${BREW:-} == /usr/local/* ]]; then
  echo '  architecture: arm64 Mac using the Intel Homebrew under /usr/local.'
  echo '                This terminal is probably running under Rosetta. Turn off'
  echo '                "Open using Rosetta" in the terminal app Get Info panel.'
else
  echo "  architecture: $(uname -m)"
fi

# The repository installs ~/.zshrc. zsh has been the macOS default since
# Catalina, but a machine restored from an older backup can still be on bash.
case "${SHELL##*/}" in
  zsh) echo '  login shell: zsh' ;;
  *)
    echo "  login shell: $SHELL, not zsh."
    echo '               ~/.zshrc will not be read. Run `chsh -s /bin/zsh`.'
    ;;
esac

# Rosetta itself, for the arm64 machines that still need an x86 binary.
if [[ $(uname -m) == arm64 ]]; then
  if /usr/bin/pgrep oahd >/dev/null 2>&1; then
    echo '  rosetta: installed'
  else
    echo '  rosetta: not installed. Only needed for x86-only binaries:'
    echo '           softwareupdate --install-rosetta --agree-to-license'
  fi
fi

echo
if $APPLY; then
  echo 'Done. Open a new shell, then run ./scripts/install.sh --apply to link configs.'
else
  echo 'Dry run complete. Re-run with --apply.'
fi
