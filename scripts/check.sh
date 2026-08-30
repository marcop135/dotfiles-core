#!/usr/bin/env bash
# Every gate this repository has, in one script.
#
#   bash ./scripts/check.sh
#
#   1. modules.conf parses, and names files that exist
#   2. every relative link in the markdown resolves
#   3. every repository path named in the markdown exists
#   4. every runnable script is named by the markdown
#   5. shellcheck at severity error
#   6. a parse pass over every shell file
#
# Written for bash 3.2, the version macOS ships: no associative arrays, no
# mapfile. That is the same constraint shared/shell/ lives under.
#
# macos/zshrc is checked by neither shellcheck nor `bash -n`: shellcheck has no
# zsh dialect, and the file uses zsh glob qualifiers, which are a syntax error
# to bash. `zsh -n` covers it below, wherever zsh is present.
set -uo pipefail

# Help is the header block itself; see install.sh for why it is read rather
# than hard coded. Before the cd, because BASH_SOURCE is relative to the caller.
case ${1-} in
  '') ;;
  -h | --help)
    awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
    exit 0
    ;;
  *) echo "check.sh: unknown option: $1" >&2; exit 2 ;;
esac

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

status=0
fail() { echo "FAIL: $*"; status=1; }

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

# ---------- 1. modules.conf ----------
# `module | source | target | platforms`. The header of the file itself says why
# it is flat text rather than JSON.
KNOWN_PLATFORMS=' macos gitbash wsl windows '
KNOWN_TOKENS=' {{PSPROFILE}} '

entries=0
modules=''
module_count=0
pairs=''
lineno=0

while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno + 1))
  case $(trim "$line") in '' | '#'*) continue ;; esac

  IFS='|' read -r f1 f2 f3 f4 f5 <<<"$line"
  if [ -n "${f5-}" ] || [ -z "${f4-}" ]; then
    fail "modules.conf:$lineno: expected 4 pipe-separated fields"
    continue
  fi

  module=$(trim "$f1")
  src=$(trim "$f2")
  target=$(trim "$f3")
  platforms=$(trim "$f4")

  [ -e "$src" ] || fail "modules.conf:$lineno: source does not exist: $src"

  case $target in
    *'{{'*)
      token=${target#*\{\{}
      token=${token%%\}\}*}
      case $KNOWN_TOKENS in
        *" {{$token}} "*) ;;
        *) fail "modules.conf:$lineno: unknown target token: {{$token}}" ;;
      esac
      ;;
  esac

  old_ifs=$IFS
  IFS=','
  for p in $platforms; do
    p=$(trim "$p")
    case $KNOWN_PLATFORMS in
      *" $p "*) ;;
      *) fail "modules.conf:$lineno: unknown platform: $p" ;;
    esac
    pairs="$pairs$p	$target
"
  done
  IFS=$old_ifs

  case " $modules " in
    *" $module "*) ;;
    *)
      modules="${modules:+$modules, }$module"
      module_count=$((module_count + 1))
      ;;
  esac
  entries=$((entries + 1))
done <scripts/modules.conf

# Two links may not claim the same target on the same platform: the second would
# silently win, and which one that is depends on the order of the file.
dups=$(printf '%s' "$pairs" | grep -v '^$' | sort | uniq -d)
[ -z "$dups" ] || while IFS= read -r d; do
  fail "modules.conf: two links claim the same target on one platform: $d"
done <<<"$dups"

# ---------- 2. markdown links ----------
# Inline `[text](path)` and reference `[label]: path`. Absolute URLs, mailto,
# and bare anchors are somebody else's problem; the rest has to resolve on disk.
md_files=$(find . -name '*.md' -not -path './.git/*' | sort)

link_failures=$(
  printf '%s\n' "$md_files" | while IFS= read -r md; do
    [ -n "$md" ] || continue
    dir=$(dirname "$md")
    {
      grep -oE '\]\([^)]+\)' "$md" | sed -e 's/^](//' -e 's/)$//' -e 's/[[:space:]].*$//'
      grep -oE '^ {0,3}\[[^]]+\]:[[:space:]]*[^[:space:]]+' "$md" | sed 's/^.*\]:[[:space:]]*//'
    } | while IFS= read -r ref; do
      # Every pattern below opens with a redundant `(`. It is POSIX, and it is
      # load-bearing here: bash 3.2, which is what macOS ships and what this
      # script is written for, scans `$( ... )` for its closing paren with a
      # parser that does not understand case statements, so the `)` ending a
      # pattern terminates the substitution early. The result is a syntax error
      # at parse time, which takes the whole gate down, on macOS only. Balancing
      # the parens is what keeps the scan honest. Passes 2 and 3 are each one
      # large command substitution, so this applies to both.
      case $ref in
        ('' | '#'* | http://* | https://* | mailto:*) continue ;;
      esac
      ref=${ref%%#*}
      [ -n "$ref" ] || continue
      case $ref in
        (/*) resolved=".$ref" ;;
        (*) resolved="$dir/$ref" ;;
      esac
      [ -e "$resolved" ] || echo "$md: link does not resolve: $ref"
    done
  done
)
[ -z "$link_failures" ] || while IFS= read -r l; do fail "$l"; done <<<"$link_failures"

# ---------- 3. repository paths named in the markdown ----------
# The README restates modules.conf as a table, and both write paths as code
# spans rather than links, so pass 2 never sees them. Without this, renaming a
# source file updates the manifest, passes the gate, and leaves the README
# pointing at a file that is gone.
#
# Only spans that begin with a real top-level directory count. That skips the
# install targets, which are `~/...` and do not exist in the tree, and the
# PowerShell paths, whose backslashes make them unresolvable here anyway.
path_failures=$(
  printf '%s\n' "$md_files" | while IFS= read -r md; do
    [ -n "$md" ] || continue
    grep -oE '`(bash )?(\./)?(scripts|shared|macos|windows|wsl|\.github)/[^`]+`' "$md" |
      tr -d '`' | sed -e 's/^bash //' -e 's|^\./||' -e 's/[[:space:]].*$//' | sort -u |
      while IFS= read -r p; do
        # A glob or a <placeholder> is prose, not a path. Leading `(` for the
        # bash 3.2 reason given in pass 2.
        case $p in
          (*'*'* | *'<'* | *'{'*) continue ;;
        esac
        [ -e "$p" ] || echo "$md: no such path: $p"
      done
  done
)
[ -z "$path_failures" ] || while IFS= read -r l; do fail "$l"; done <<<"$path_failures"

# ---------- 4. runnable scripts the markdown never names ----------
# Pass 3 catches a document pointing at a file that has moved. This is the other
# direction, and the one that fails silently: a script that lives in the tree,
# runs in CI, and appears in no document. Nothing breaks, so nobody notices, and
# the README slowly stops describing the repository.
#
# Scoped to what a person is expected to run, plus the manifest. The
# shared/shell/ fragments are deliberately not in the list: the README documents
# that directory as a layer rather than file by file, and the rc files are
# covered by modules.conf and pass 1.
#
# Both slash directions are accepted, because the PowerShell scripts are written
# `.\scripts\install.ps1` in prose and would never match a forward slash.
RUNNABLE=(scripts/*.sh scripts/*.ps1 scripts/modules.conf macos/bootstrap.sh wsl/bootstrap.sh)

undocumented=$(
  for f in "${RUNNABLE[@]}"; do
    [ -e "$f" ] || continue
    backslashed=$(printf '%s' "$f" | tr '/' '\\')
    # shellcheck disable=SC2086
    grep -qF -e "$f" -e "$backslashed" $md_files 2>/dev/null ||
      echo "no markdown names $f"
  done
)
[ -z "$undocumented" ] || while IFS= read -r l; do fail "$l"; done <<<"$undocumented"

# ---------- 5 and 6. shellcheck, then parse ----------
# The rc files have no extension and no shebang, so shellcheck has to be told.
SH=(scripts/*.sh shared/shell/*.sh shared/shell/local.sh.example macos/bootstrap.sh wsl/bootstrap.sh)
BASH=(windows/bashrc windows/bash_profile wsl/bashrc)

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -S error "${SH[@]}" || status=1
  shellcheck -S error -s bash "${BASH[@]}" || status=1
elif [ -n "${CI-}" ]; then
  # Locally a missing shellcheck is a reason to skip. In CI it is a hole in the
  # gate, and a gate with a hole reports green for the wrong reason.
  fail 'shellcheck is not installed on this runner'
else
  echo 'skipped: shellcheck is not installed'
fi

for f in "${SH[@]}" "${BASH[@]}"; do
  bash -n "$f" || fail "parse: $f"
done

if command -v zsh >/dev/null 2>&1; then
  zsh -n macos/zshrc || fail 'parse: macos/zshrc'
fi

if [ $status -eq 0 ]; then
  echo "modules.conf: $entries links across $module_count modules ($modules), all valid."
  echo "markdown: $(printf '%s\n' "$md_files" | wc -l | tr -d ' ') files, every relative link and repository path resolves."
  echo "scripts: ${#RUNNABLE[@]} runnable, every one named by the markdown."
  echo "shell: ${#SH[@]} sh, ${#BASH[@]} bash, and zshrc where zsh exists."
fi
exit $status
