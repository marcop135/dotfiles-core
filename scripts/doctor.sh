#!/usr/bin/env bash
# The conditions that silently degrade a setup and produce symptoms that do not
# point at their cause. Read-only.
#
#   ./scripts/doctor.sh
#
# What is currently linked is `./scripts/install.sh --status`, not this.
set -uo pipefail

# Help is the header block itself; see install.sh for why it is read rather
# than hard coded.
case ${1-} in
  '') ;;
  -h | --help)
    awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *) echo "doctor.sh: unknown option: $1" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WARNINGS=0

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_OK=''; C_WARN=''; C_DIM=''; C_OFF=''
fi

section() { printf '\n%s\n%s\n' "$1" "$(printf '%.0s-' $(seq 1 ${#1}))"; }
row() { printf '  %-18s %s\n' "$1" "$2"; }
ok() { printf '  %s+%s %s\n' "$C_OK" "$C_OFF" "$1"; }
warn() { printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$1"; WARNINGS=$((WARNINGS + 1)); }
note() { printf '    %s%s%s\n' "$C_DIM" "$1" "$C_OFF"; }

case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  MINGW* | MSYS* | CYGWIN*) PLATFORM=gitbash ;;
  Linux) grep -qi microsoft /proc/version 2>/dev/null && PLATFORM=wsl || PLATFORM=linux ;;
  *) PLATFORM=unknown ;;
esac

section 'Environment'
row 'platform' "$PLATFORM"
row 'os' "$(uname -sr)"
row 'shell' "${SHELL:-unknown} (under ${BASH_VERSION:+bash $BASH_VERSION}${ZSH_VERSION:+zsh $ZSH_VERSION})"
row 'term' "${TERM:-unset}"
row 'repository' "$ROOT"

section 'Tools'
for tool in git node npm starship rg bat delta fzf; do
  if command -v "$tool" >/dev/null 2>&1; then
    row "$tool" "$("$tool" --version 2>&1 | head -1)"
  else
    row "$tool" "${C_DIM}not installed${C_OFF}"
  fi
done

section 'Checks'

# Its absence is why bat and delta pick a theme that fights the terminal.
case "${COLORFGBG-}" in
  '0;15') ok 'COLORFGBG = 0;15 (light)' ;;
  '15;0') ok 'COLORFGBG = 15;0 (dark)' ;;
  '') warn 'COLORFGBG is unset; bat, delta, and less will guess at the theme'
      note 'run theme_refresh, or source shared/shell/theme.sh' ;;
  *) warn "COLORFGBG has an unexpected value: ${COLORFGBG}" ;;
esac

# A duplicated PATH entry means an rc file is sourced twice, which also means
# functions are redefined and the shell is slower than it needs to be.
dupes=$(printf '%s\n' "$PATH" | tr ':' '\n' | sort | uniq -d | grep -c . || true)
if [[ ${dupes:-0} -gt 0 ]]; then
  warn "PATH contains $dupes duplicated entries"
  note 'usually an rc file sourced twice; run `path` to inspect'
else
  ok "PATH has $(printf '%s\n' "$PATH" | tr ':' '\n' | grep -c .) entries, no duplicates"
fi

# Anything over half a second is felt on every new tab, and the usual cause is
# an eagerly loaded version manager.
if start=$(date +%s%N 2>/dev/null) && [[ $start != *N* ]]; then
  "$SHELL" -i -c exit >/dev/null 2>&1
  ms=$((($(date +%s%N) - start) / 1000000))
  if [[ $ms -gt 500 ]]; then
    warn "interactive shell start: ${ms}ms"
    note 'lazily load nvm, pyenv, rbenv; see macos/zshrc for the pattern'
  else
    ok "interactive shell start: ${ms}ms"
  fi
fi

if command -v git >/dev/null 2>&1; then
  if [[ -n "$(git config --get user.email 2>/dev/null)" ]]; then
    ok "git identity: $(git config --get user.email)"
  else
    warn 'git user.email is not set; commits will be attributed to nobody'
    note 'git config --file ~/.gitconfig.local user.email "you@example.com"'
  fi

  # The wrong autocrlf turns a shell script into `bad interpreter: /bin/bash^M`.
  case "$(git config --get core.autocrlf 2>/dev/null || true)" in
    input) ok 'git core.autocrlf = input' ;;
    '') warn 'git core.autocrlf is unset; a CRLF checkout will break shell scripts' ;;
    *) warn "git core.autocrlf = $(git config --get core.autocrlf), expected input" ;;
  esac
fi

# The symptom of a CRLF checkout is an interpreter error naming the interpreter,
# so look for the cause directly.
if grep -lUq $'\r' "$ROOT"/scripts/*.sh 2>/dev/null; then
  warn 'a script in scripts/ has CRLF line endings'
  note 'the checkout ignored .gitattributes; re-clone with core.autocrlf = input'
fi

case "$PLATFORM" in
  gitbash)
    [[ "$(git config --get core.longpaths 2>/dev/null)" == true ]] ||
      warn 'git core.longpaths is not true; deep node_modules trees fail to check out'
    ;;
  wsl)
    [[ -d /run/systemd/system ]] || {
      warn 'systemd is not running; systemctl will not work'
      note 'set boot.systemd = true in /etc/wsl.conf, then `wsl.exe --shutdown`'
    }
    [[ $PWD == /mnt/* ]] && {
      warn "running from $PWD, a Windows drive mount"
      note 'I/O here is several times slower and file watching is unreliable'
    }
    # Windows interop puts .exe binaries on PATH, so `node` can resolve to a
    # Windows install and `python` to a Microsoft Store stub.
    for tool in node python python3; do
      case "$(command -v "$tool" 2>/dev/null)" in
        /mnt/*) warn "$tool resolves to a Windows binary: $(command -v "$tool")"
                note 'install it inside the distribution, or it will not see Linux paths' ;;
      esac
    done
    ;;
  macos)
    [[ ${BASH_VERSINFO[0]:-0} -eq 3 ]] &&
      note 'the bash on PATH is the system 3.2; bash 4 features will fail'
    ;;
esac

echo
if [[ $WARNINGS -eq 0 ]]; then
  printf '%sNo warnings.%s\n' "$C_OK" "$C_OFF"
else
  printf '%s%d warning%s.%s\n' "$C_WARN" "$WARNINGS" "$([[ $WARNINGS -eq 1 ]] || echo s)" "$C_OFF"
fi
exit 0
