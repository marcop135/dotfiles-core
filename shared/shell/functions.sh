# shellcheck shell=sh
# Small functions that solve recurring annoyances.
#
# These are functions rather than aliases because they take arguments, and they
# live here rather than in a platform file because every one of them works
# identically on macOS, Git Bash, and WSL.

# Create a directory and enter it. The two-step version is one of the most
# frequently retyped command pairs there is.
mkcd() {
  [ -n "${1-}" ] || { echo "usage: mkcd <dir>" >&2; return 2; }
  mkdir -p -- "$1" && cd -- "$1" || return 1
}

# Go up N directories. `up 3` instead of `cd ../../..`.
up() {
  _up_count=${1:-1}
  _up_path=''
  while [ "$_up_count" -gt 0 ]; do
    _up_path="../$_up_path"
    _up_count=$((_up_count - 1))
  done
  unset _up_count
  # shellcheck disable=SC2164
  cd "${_up_path:-.}" || { unset _up_path; return 1; }
  unset _up_path
}

# Jump to the root of the current git repository. Useful from any depth, and it
# fails loudly outside a repo rather than silently landing in $HOME.
groot() {
  _groot_top=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "groot: not inside a git repository" >&2
    return 1
  }
  cd "$_groot_top" || { unset _groot_top; return 1; }
  unset _groot_top
}

# Print PATH one entry per line. Debugging a PATH problem by reading a single
# 900-character colon-separated line is needlessly hard.
path() {
  printf '%s\n' "$PATH" | tr ':' '\n'
}

# Serve the current directory over HTTP. Faster than reaching for a dev server
# when all you need is to check a built `dist/` or share a file on the LAN.
serve() {
  _serve_port=${1:-8000}
  if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server "$_serve_port"
  elif command -v python >/dev/null 2>&1; then
    python -m http.server "$_serve_port"
  elif command -v npx >/dev/null 2>&1; then
    npx --yes serve --listen "$_serve_port"
  else
    echo "serve: needs python3 or npx" >&2
    unset _serve_port
    return 1
  fi
  unset _serve_port
}

# Extract any common archive without remembering which flag combination each
# tool wants. `tar xjf` versus `tar xzf` versus `unzip` is pure trivia.
extract() {
  [ -f "${1-}" ] || { echo "usage: extract <archive>" >&2; return 2; }
  case "$1" in
    *.tar.bz2 | *.tbz2) tar xjf "$1" ;;
    *.tar.gz | *.tgz) tar xzf "$1" ;;
    *.tar.xz) tar xJf "$1" ;;
    *.tar) tar xf "$1" ;;
    *.zip) unzip "$1" ;;
    *.gz) gunzip "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.7z) 7z x "$1" ;;
    *) echo "extract: unsupported archive: $1" >&2; return 1 ;;
  esac
}

# Which process is holding a port. The command differs on every platform, and
# looking it up is a guaranteed context switch in the middle of debugging.
port() {
  [ -n "${1-}" ] || { echo "usage: port <number>" >&2; return 2; }
  case "$(uname -s 2>/dev/null)" in
    Darwin)
      lsof -nP -iTCP:"$1" -sTCP:LISTEN
      ;;
    MINGW* | MSYS* | CYGWIN*)
      # Git Bash: netstat.exe is the only one that sees Windows sockets.
      netstat.exe -ano | grep -E "LISTENING" | grep ":$1 "
      ;;
    *)
      if command -v ss >/dev/null 2>&1; then
        ss -lptn "sport = :$1"
      else
        lsof -nP -iTCP:"$1" -sTCP:LISTEN
      fi
      ;;
  esac
}

# Recursive grep that skips the directories you never want to search. Falls
# back to grep so it works on a machine without ripgrep.
ff() {
  [ -n "${1-}" ] || { echo "usage: ff <pattern> [path]" >&2; return 2; }
  if command -v rg >/dev/null 2>&1; then
    rg --hidden --glob '!.git' "$@"
  else
    grep -rIn --exclude-dir=.git --exclude-dir=node_modules "$@"
  fi
}

# Print the size of each entry in a directory, largest last. Answers "what is
# eating my disk" without remembering the du flags.
sizes() {
  du -sh -- "${1:-.}"/* 2>/dev/null | sort -h
}
