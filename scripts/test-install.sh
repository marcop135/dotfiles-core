#!/usr/bin/env bash
# End-to-end test for scripts/install.sh against a throwaway home directory.
#
#   bash ./scripts/test-install.sh
#
# The installer is the only thing here that writes to $HOME, so it is the only
# thing here that can damage a machine, and a dry run proves nothing about the
# path that does the writing. This runs the real --apply against a temporary
# directory and asserts the result.
#
# What it covers, in order: links are created and point back into the
# repository, a second --apply changes nothing, an existing real file is backed
# up rather than destroyed, --unlink removes only what this repository owns,
# and --restore puts the user's original file back.
#
# Safe to run on a real machine: $HOME is overridden for every invocation and
# the temporary directory is removed on exit.
set -euo pipefail

# Help is the header block itself; see install.sh for why it is read rather
# than hard coded.
case ${1-} in
  '') ;;
  -h | --help)
    awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *) echo "test-install.sh: unknown option: $1" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$ROOT/scripts/install.sh"

# Git Bash needs this to create a real NTFS symlink rather than silently
# copying. The installer exports it for its own run; the assertions below use
# readlink outside that run, so the test needs it too.
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*) export MSYS=winsymlinks:nativestrict ;;
esac

SANDBOX="$(mktemp -d)"
trap 'rm -rf -- "$SANDBOX"' EXIT

# Preflight. Creating a symlink on Windows needs a privilege, and without it
# every assertion below fails for one reason that has nothing to do with this
# repository. Say so once and stop, rather than reporting fourteen failures.
if ! ln -s "$SANDBOX" "$SANDBOX/preflight" 2>/dev/null; then
  echo 'skipped: this shell cannot create symlinks.'
  echo 'On Windows, enable Developer Mode (Settings > System > For developers)'
  echo 'or run from an elevated shell.'
  exit 0
fi
rm -f -- "$SANDBOX/preflight"

PASS=0
FAIL=0

ok() { printf '  ok    %s\n' "$1"; PASS=$((PASS + 1)); }
no() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

check() {
  # check <description> <command...>
  local what="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$what"; else no "$what"; fi
}

run() { HOME="$SANDBOX" bash "$INSTALL" "$@"; }

# Targets for this platform, from the installer's own status output, so the
# test never has to duplicate the manifest. Column three is the target path;
# $SANDBOX comes from mktemp and contains no spaces.
targets() { run --status | tail -n +3 | awk 'NF { print $3 }'; }

# `targets | head -1` looks equivalent and is not. head exits after the first
# line, which closes the pipe, which kills the installer behind it with EPIPE,
# which `set -o pipefail` turns into a failure of the whole assertion. Whether
# that happens is a race between the writer finishing and the reader exiting:
# Linux wins it, macOS does not. Read the list in full, then take the first
# line of it. The same reasoning applies to every early-exiting reader below.
first_target() {
  local all
  all="$(targets)"
  printf '%s\n' "${all%%$'\n'*}"
}

echo "sandbox: $SANDBOX"
echo

echo '--apply creates the links'
run --apply >/dev/null
for t in $(targets); do
  if [[ -L $t ]]; then ok "symlink: ${t#"$SANDBOX"/}"; else no "symlink: ${t#"$SANDBOX"/}"; fi
  # The link must resolve back into the repository. A copy looks installed and
  # never picks up a change, which is the failure this asserts against.
  resolved="$(readlink "$t" 2>/dev/null || true)"
  case "$resolved" in
    "$ROOT"/*) ok "points into the repository: ${t#"$SANDBOX"/}" ;;
    *) no "points into the repository: ${t#"$SANDBOX"/} (got ${resolved:-nothing})" ;;
  esac
done

echo
echo 'every target reports linked'
# Read from a process substitution rather than a pipe: a pipe puts the loop in
# a subshell, where an assertion failure cannot reach the counters.
not_linked=0
while read -r _module state _target; do
  [[ $state == linked ]] || not_linked=$((not_linked + 1))
done < <(run --status | tail -n +3 | grep .)
if [[ $not_linked -eq 0 ]]; then ok 'all linked'; else no "$not_linked not linked"; fi

echo
echo 'a second --apply changes nothing'
second_apply="$(run --apply)"
if grep -q '^0 changed' <<<"$second_apply"; then ok 'idempotent'; else no 'idempotent'; fi

echo
echo 'an existing real file is backed up, not destroyed'
victim="$(first_target)"
rm -- "$victim"
printf 'original contents\n' > "$victim"
run --apply >/dev/null
check 'the target is a link again' test -L "$victim"
backup="$(ls -1d -- "$victim".bak.* 2>/dev/null | tail -1 || true)"
if [[ -n $backup ]] && grep -q 'original contents' "$backup"; then
  ok 'the original file survived in the backup'
else
  no 'the original file survived in the backup'
fi

echo
echo '--unlink removes only what this repository owns'
run --unlink --apply >/dev/null
still_linked=0
for t in $(HOME="$SANDBOX" bash "$INSTALL" --status | tail -n +3 | awk 'NF { print $3 }'); do
  [[ -L $t ]] && still_linked=$((still_linked + 1))
done
if [[ $still_linked -eq 0 ]]; then ok 'no links left'; else no "$still_linked links left"; fi
check 'the backup was left alone' test -e "$backup"

echo
echo '--unlink --restore puts the original back'
run --apply >/dev/null
run --unlink --restore --apply >/dev/null
if [[ -f $victim && ! -L $victim ]] && grep -q 'original contents' "$victim"; then
  ok 'original contents restored'
else
  no 'original contents restored'
fi

echo
echo 'a foreign symlink is never touched'
foreign="$(first_target)"
rm -f -- "$foreign"
ln -s /dev/null "$foreign"
run --unlink --apply >/dev/null
check 'still there' test -L "$foreign"

echo
if [[ $FAIL -eq 0 ]]; then
  echo "$PASS passed."
else
  echo "$FAIL failed, $PASS passed."
  exit 1
fi
