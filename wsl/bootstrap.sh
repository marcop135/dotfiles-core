#!/usr/bin/env bash
# Bring a fresh WSL Ubuntu or Debian install to a usable development state.
#
#   ./wsl/bootstrap.sh            # dry run: list what would be installed
#   ./wsl/bootstrap.sh --apply
#
# It installs build essentials, a few CLI tools, and a Node version manager,
# then stops. Language runtimes, databases, and anything project-specific
# belong in the project, not in a machine bootstrap.
#
# Safe to run more than once: apt-get install on an installed package is a
# no-op, and every step checks before acting.
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

if ! grep -qi microsoft /proc/version 2>/dev/null; then
  echo 'bootstrap.sh: this does not look like WSL.' >&2
  echo 'It will mostly work on plain Ubuntu, but the interop checks will not.' >&2
  echo 'Re-run with FORCE=1 to continue anyway.' >&2
  [[ ${FORCE-} == 1 ]] || exit 1
fi

run() {
  if $APPLY; then
    "$@"
  else
    printf '  would run: %s\n' "$*"
  fi
}

section() { printf '\n== %s ==\n' "$1"; }

$APPLY || echo 'Dry run. Nothing will change. Re-run with --apply.'

# ---------- Packages ----------
# One list, one apt-get call. Splitting it into several is slower and makes a
# partial failure harder to reason about.
PACKAGES=(
  build-essential   # gcc, make, headers. Needed by half of npm and all of pip.
  ca-certificates
  curl
  wget
  git
  unzip
  jq
  ripgrep           # rg
  fd-find           # binary is `fdfind` on Debian; see the alias note below
  bat               # binary is `batcat` on Debian; same
  tree
  htop
  python3-venv      # Ubuntu splits venv out of python3. pip fails without it.
  python3-pip
  pipx
)

section 'apt packages'
if $APPLY; then
  sudo apt-get update
  sudo apt-get install -y "${PACKAGES[@]}"
else
  printf '  would install: %s\n' "${PACKAGES[*]}"
fi

# ---------- Debian binary name workaround ----------
# Debian and Ubuntu ship `fd` as `fdfind` and `bat` as `batcat`, because both
# names collided with existing packages. Symlink them into ~/.local/bin, which
# shared/shell/env.sh already puts on PATH.
section 'binary name symlinks'
run mkdir -p "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1; then
  run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
if command -v batcat >/dev/null 2>&1; then
  run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# ---------- Node ----------
# nvm rather than the apt package: the Ubuntu Node is old, and per-project
# version switching is the normal case.
section 'nvm and Node LTS'
if [[ -d "${NVM_DIR:-$HOME/.nvm}" ]]; then
  echo '  nvm already installed, skipping.'
elif $APPLY; then
  # Pinning the installer version rather than following master: a `curl | bash`
  # against a moving target is worth avoiding where the cost is one string.
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
else
  echo '  would install nvm and the current Node LTS'
fi

# ---------- Prompt ----------
section 'starship'
if command -v starship >/dev/null 2>&1; then
  echo '  starship already installed, skipping.'
else
  run sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
fi

# ---------- Checks ----------
section 'environment checks'

# systemd is not enabled by default on older WSL installs, and its absence is
# only noticed later when `systemctl` fails on a service you just installed.
if [[ -d /run/systemd/system ]]; then
  echo '  systemd: running'
else
  echo '  systemd: NOT running. Set boot.systemd = true in /etc/wsl.conf,'
  echo '           then run `wsl.exe --shutdown` from Windows.'
fi

# Working under /mnt is the most common self-inflicted WSL performance problem.
if [[ $PWD == /mnt/* ]]; then
  echo "  location: running from $PWD, which is a Windows drive mount."
  echo '            Clone to ~/ instead; file I/O there is several times faster.'
else
  echo '  location: on the Linux filesystem'
fi

if command -v wslpath >/dev/null 2>&1; then
  echo '  interop: available'
else
  echo '  interop: unavailable. Check [interop] enabled = true in /etc/wsl.conf.'
fi

echo
if $APPLY; then
  echo 'Done. Open a new shell, then run ./scripts/install.sh --apply to link configs.'
else
  echo 'Dry run complete. Re-run with --apply.'
fi
