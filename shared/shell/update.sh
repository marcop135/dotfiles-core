# shellcheck shell=sh
# Update npm, pipx, and the platform's package managers in one command.
#
# Chaining them with `&&` means the first failure hides the rest. `run_step`
# records a failure and carries on; `run_step_summary` says which ones failed.
# That harness is the reusable part: it fits any sequence of independent,
# fallible steps.
#
# Each updater returns 0 when its manager is absent. "Not installed" is the
# normal state on two of the three platforms, not a failure.

# ---------- Step harness ----------
# Usage: run_step <label> <command> [args...]
# Results accumulate in _RUN_STEP_RESULTS, newline separated, because bash and
# zsh arrays are not portable between the two and this file is POSIX sh.
run_step() {
  _step_label=$1
  shift

  _RUN_STEP_COUNT=$((${_RUN_STEP_COUNT:-0} + 1))
  printf '\n========== [%s] %s ==========\n' "$_RUN_STEP_COUNT" "$_step_label"

  if "$@"; then
    _RUN_STEP_OK=$((${_RUN_STEP_OK:-0} + 1))
    _RUN_STEP_RESULTS="${_RUN_STEP_RESULTS-}[ ok ]   $_step_label
"
  else
    _RUN_STEP_FAIL=$((${_RUN_STEP_FAIL:-0} + 1))
    printf '(non-zero exit from: %s)\n' "$_step_label"
    _RUN_STEP_RESULTS="${_RUN_STEP_RESULTS-}[failed] $_step_label
"
  fi

  unset _step_label
}

run_step_reset() {
  _RUN_STEP_COUNT=0
  _RUN_STEP_OK=0
  _RUN_STEP_FAIL=0
  _RUN_STEP_RESULTS=''
}

# Non-zero if any step failed, so a whole run is usable in a script or a CI job.
run_step_summary() {
  printf '\n=== %s (%s ok, %s failed of %s) ===\n' \
    "${1:-summary}" "${_RUN_STEP_OK:-0}" "${_RUN_STEP_FAIL:-0}" "${_RUN_STEP_COUNT:-0}"
  printf '%s' "${_RUN_STEP_RESULTS-}" | sed 's/^/  /'
  [ "${_RUN_STEP_FAIL:-0}" -eq 0 ]
}

# ---------- Updaters ----------

update_npm() {
  command -v npm >/dev/null 2>&1 || { echo "npm not installed, skipping."; return 0; }
  npm update -g
}

update_pipx() {
  command -v pipx >/dev/null 2>&1 || { echo "pipx not installed, skipping."; return 0; }
  pipx upgrade-all
}

update_brew() {
  command -v brew >/dev/null 2>&1 || { echo "brew not installed, skipping."; return 0; }
  brew update && brew upgrade && brew cleanup
}

# Casks are GUI applications, and `brew upgrade` alone leaves them behind.
update_brew_cask() {
  command -v brew >/dev/null 2>&1 || { echo "brew not installed, skipping."; return 0; }
  brew upgrade --cask
}

# Mac App Store applications. mas is not installed by default: `brew install mas`.
update_mas() {
  command -v mas >/dev/null 2>&1 || { echo "mas not installed, skipping."; return 0; }
  mas upgrade
}

update_winget() {
  command -v winget >/dev/null 2>&1 || command -v winget.exe >/dev/null 2>&1 || {
    echo "winget not available, skipping."
    return 0
  }
  # MSYS2_ARG_CONV_EXCL stops Git Bash rewriting the `--`-prefixed arguments
  # into Windows paths on the way to a native executable.
  MSYS2_ARG_CONV_EXCL='*' winget.exe upgrade --all \
    --accept-source-agreements --accept-package-agreements --include-unknown
}

update_choco() {
  command -v choco.exe >/dev/null 2>&1 || command -v choco >/dev/null 2>&1 || {
    echo "choco not available, skipping."
    return 0
  }
  # Chocolatey writes under ProgramData, so this needs an elevated shell. From a
  # normal one the step fails, run_step records it, and the rest of the run
  # continues, which is the point of the harness.
  choco.exe upgrade all -y
}

update_apt() {
  command -v apt-get >/dev/null 2>&1 || { echo "apt not available, skipping."; return 0; }
  sudo apt-get update &&
    sudo apt-get upgrade -y &&
    sudo apt-get autoremove -y &&
    sudo apt-get autoclean
}

# ---------- Combined run ----------
# The language-level managers first because they are fast and fail cheaply; the
# OS-level ones last because they may prompt for a password or for elevation.
update_all() {
  run_step_reset
  run_step 'npm' update_npm
  run_step 'pipx' update_pipx

  case "$(uname -s 2>/dev/null)" in
    Darwin)
      run_step 'brew' update_brew
      run_step 'brew --cask' update_brew_cask
      run_step 'mas' update_mas
      ;;
    MINGW* | MSYS* | CYGWIN*)
      run_step 'winget' update_winget
      run_step 'choco' update_choco
      ;;
    *) run_step 'apt' update_apt ;;
  esac

  run_step_summary 'update-all'
}
