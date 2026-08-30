# shellcheck shell=sh
# Environment: locale, editor, pager, history, PATH.

# ---------- Locale ----------
# Set explicitly rather than inherited. An unset or C locale silently breaks
# UTF-8 output in git log, less, and anything drawing box characters, and the
# failure looks like a font problem rather than a locale problem.
: "${LANG:=en_US.UTF-8}"
export LANG

# ---------- Editor ----------
# Resolved at startup instead of hardcoded, so the same file works on a machine
# without VS Code installed. `code --wait` blocks until the tab is closed, which
# is what git needs for commit messages and interactive rebases.
if [ -z "${EDITOR-}" ]; then
  if command -v code >/dev/null 2>&1; then
    EDITOR='code --wait'
  elif command -v nano >/dev/null 2>&1; then
    EDITOR=nano
  else
    EDITOR=vi
  fi
fi
export EDITOR
export VISUAL="$EDITOR"

# ---------- Pager ----------
# -F quits if the output fits on one screen, -R passes colour through, -X stops
# less from clearing the screen on exit so short output stays visible in the
# scrollback. Without -F, `git branch` in a small repo opens a full-screen pager
# for three lines.
export PAGER=less
export LESS='-FRX'

# ---------- History ----------
# Large history is cheap and searchable history is the point. Deduplication and
# the ignore-leading-space rule are shell-specific and live in the platform rc
# files, because the option names differ between bash and zsh.
export HISTSIZE=1000000
export HISTFILESIZE=1000000
# Timestamps make `history` output useful months later. zsh writes them by
# default with EXTENDED_HISTORY; bash needs this variable.
export HISTTIMEFORMAT='%F %T '

# Drop the commands that are pure noise, so history stays worth searching.
# This is housekeeping, not a secrecy control. To keep a command with a token
# in it out of the file, type it with a leading space: `HISTCONTROL=ignoreboth`
# in windows/bashrc and wsl/bashrc, `setopt HIST_IGNORE_SPACE` in macos/zshrc.
#
# HISTIGNORE is bash-only, and a colon-separated list. zsh ignores it and uses
# HISTORY_IGNORE, which takes a pattern instead; macos/zshrc sets that one.
if [ -n "${BASH_VERSION-}" ]; then
  export HISTIGNORE='ls:cd:cd -:pwd:exit:clear:history'
fi

# ---------- PATH ----------
# Prepend a directory only if it exists and is not already present. Repeatedly
# sourcing an rc file (which every `exec $SHELL` and every nested shell does)
# otherwise grows PATH without bound until command lookup gets measurably slow.
path_prepend() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) [ -d "$1" ] && PATH="$1:$PATH" ;;
  esac
  export PATH
}

path_append() {
  case ":${PATH}:" in
    *":$1:"*) ;;
    *) [ -d "$1" ] && PATH="$PATH:$1" ;;
  esac
  export PATH
}

# The conventional location for user-installed binaries on every platform,
# including Git Bash and WSL.
path_prepend "$HOME/.local/bin"

# ---------- Tool defaults ----------
# Keep generated caches and state out of $HOME where the tool supports it.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Telemetry off, and Homebrew's hint output with it. DO_NOT_TRACK is the
# cross-tool convention; the rest are tool-specific.
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
export NEXT_TELEMETRY_DISABLED=1
export DO_NOT_TRACK=1
