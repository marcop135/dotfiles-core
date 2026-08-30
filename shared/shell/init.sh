# shellcheck shell=sh
# Entry point for the shared shell layer.
#
# Every platform rc file (macos/zshrc, windows/bashrc, wsl/bashrc) sources this
# one file. Adding a shared module means adding it to the list below, not
# editing three rc files and forgetting one.
#
# Everything here must run under both bash and zsh, so it is written in POSIX
# sh: no arrays, no [[ ]], no local-with-assignment tricks. Shell-specific
# behaviour belongs in the platform rc file.

# Resolve this file's directory without relying on $0, which differs between
# bash (`$BASH_SOURCE`) and zsh (`${(%):-%x}`) when a file is sourced.
if [ -n "${BASH_VERSION-}" ]; then
  # shellcheck disable=SC3028,SC3054
  DOTFILES_SHELL_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
elif [ -n "${ZSH_VERSION-}" ]; then
  # ${(%):-%x} is zsh's "path of the file being sourced". shellcheck has no zsh
  # dialect, so it reads the parenthesis as a malformed sh expansion. The branch
  # only runs under zsh, where it is valid.
  # shellcheck disable=SC2296
  DOTFILES_SHELL_DIR=$(CDPATH= cd -- "$(dirname -- "${(%):-%x}")" && pwd)
else
  DOTFILES_SHELL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fi

# Repository root, exported so scripts and functions can find sibling files
# regardless of where the rc file was symlinked from.
DOTFILES_ROOT=$(CDPATH= cd -- "$DOTFILES_SHELL_DIR/../.." && pwd)
export DOTFILES_ROOT

# Order matters: env before everything (it sets PATH and locale), theme before
# any tool that reads COLORFGBG, aliases last so they can shadow functions.
for _dotfiles_module in env.sh theme.sh functions.sh update.sh aliases.sh; do
  if [ -r "$DOTFILES_SHELL_DIR/$_dotfiles_module" ]; then
    # shellcheck source=/dev/null
    . "$DOTFILES_SHELL_DIR/$_dotfiles_module"
  fi
done
unset _dotfiles_module

# Machine-local overrides, always last so they win.
#
# This is the single most important convention in this repository: anything
# private, machine-specific, or employer-specific goes in an untracked file
# outside the repo. The repo never has to know it exists, and no tracked file
# has to be redacted before it is published. See shared/shell/local.sh.example.
if [ -r "$HOME/.shell.local" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.shell.local"
fi
