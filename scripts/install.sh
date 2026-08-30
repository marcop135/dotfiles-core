#!/usr/bin/env bash
# Symlink configuration from this repository into your home directory.
#
#   ./scripts/install.sh                       dry run: print the plan, change nothing
#   ./scripts/install.sh --apply               link every module for this platform
#   ./scripts/install.sh --apply --only shell
#   ./scripts/install.sh --apply --skip prompt
#   ./scripts/install.sh --list                list modules and exit
#   ./scripts/install.sh --status              show what is currently linked
#   ./scripts/install.sh --unlink              dry run: what removing the links would do
#   ./scripts/install.sh --unlink --apply      remove the links this repository owns
#   ./scripts/install.sh --unlink --restore --apply
#                                              the same, then move the newest backup back
#
# Dry run is the default, so you can read the plan before anything touches your
# home directory.
#
# Nothing is deleted. An existing file at a target path is renamed to
# <target>.bak.<timestamp> before the link is created, so the operation is
# reversible. --unlink is the other half: it removes only symlinks that point
# into this repository, and never a real file.
#
# Handles macOS, Git Bash, and WSL. Native Windows PowerShell is
# scripts/install.ps1.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/scripts/modules.conf"

APPLY=false
ONLY=''
SKIP=''
RESTORE=false
ACTION=install

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --dry-run) APPLY=false; shift ;;
    --only) ONLY="${2-}"; shift 2 ;;
    --skip) SKIP="${2-}"; shift 2 ;;
    --list) ACTION=list; shift ;;
    --status) ACTION=status; shift ;;
    --unlink) ACTION=unlink; shift ;;
    --restore) RESTORE=true; shift ;;
    # Print the header block as help. Driven by "comment lines after the
    # shebang, up to the first line of code" rather than a hard-coded line
    # range, which drifts silently every time the header is edited.
    -h | --help)
      awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) echo "install.sh: unknown option: $1" >&2; exit 2 ;;
  esac
done

# ---------- Platform detection ----------
detect_platform() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    MINGW* | MSYS* | CYGWIN*) echo gitbash ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo wsl
      else
        # Plain Linux is not a first-class target here, but the WSL profile is
        # the closest match and works, minus the Windows interop helpers.
        echo wsl
      fi
      ;;
    *) echo unknown ;;
  esac
}

if $RESTORE && [[ $ACTION != unlink ]]; then
  echo 'install.sh: --restore only means something with --unlink' >&2
  exit 2
fi

PLATFORM="$(detect_platform)"
if [[ $PLATFORM == unknown ]]; then
  echo "install.sh: unsupported platform: $(uname -s)" >&2
  exit 1
fi

# Make `ln -s` create a real NTFS symlink under Git Bash instead of silently
# falling back to a copy. `nativestrict` means it fails loudly when it cannot,
# which is what you want: a copied file looks installed and never picks up a
# change to the repository.
#
# Creating a symlink on Windows needs a privilege. Enable Developer Mode, or
# run this once from an elevated shell.
if [[ $PLATFORM == gitbash ]]; then
  export MSYS=winsymlinks:nativestrict
fi

# ---------- Target expansion ----------
expand_target() {
  local t="$1"
  t="${t/#\~/$HOME}"
  printf '%s\n' "$t"
}

# ---------- Manifest ----------
in_list() {
  local needle="$1" haystack="$2"
  [[ ,${haystack}, == *,${needle},* ]]
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s\n' "$s"
}

# Emit "module<TAB>source<TAB>target" for every entry matching this platform
# and the --only/--skip filters.
selected_entries() {
  local line module source target platforms
  while IFS='|' read -r module source target platforms; do
    [[ -z ${module// /} ]] && continue
    [[ ${module# } == \#* ]] && continue

    module="$(trim "$module")"
    [[ -z $module || $module == \#* ]] && continue

    source="$(trim "$source")"
    target="$(trim "$target")"
    platforms="$(trim "$platforms")"

    in_list "$PLATFORM" "$platforms" || continue
    [[ -n $ONLY ]] && { in_list "$module" "$ONLY" || continue; }
    [[ -n $SKIP ]] && { in_list "$module" "$SKIP" && continue; }

    # {{PSPROFILE}} is a PowerShell concept; install.ps1 owns those entries.
    [[ $target == *'{{PSPROFILE}}'* ]] && continue

    printf '%s\t%s\t%s\n' "$module" "$source" "$(expand_target "$target")"
  done < "$MANIFEST"
}

all_modules() {
  local module rest
  while IFS='|' read -r module rest; do
    module="$(trim "$module")"
    [[ -z $module || $module == \#* ]] && continue
    printf '%s\n' "$module"
  done < "$MANIFEST" | sort -u
}

# ---------- Actions ----------
if [[ $ACTION == list ]]; then
  echo "platform: $PLATFORM"
  echo 'modules:'
  all_modules | sed 's/^/  /'
  exit 0
fi

link_state() {
  # Prints: linked | wrong-link | file | missing
  local target="$1" want="$2"
  if [[ -L $target ]]; then
    local current
    current="$(readlink "$target" 2>/dev/null || true)"
    if [[ $current == "$want" ]]; then echo linked; else echo wrong-link; fi
  elif [[ -e $target ]]; then
    echo file
  else
    echo missing
  fi
}

if [[ $ACTION == status ]]; then
  echo "platform: $PLATFORM"
  echo
  while IFS=$'\t' read -r module source target; do
    printf '  %-8s %-10s %s\n' "$module" "$(link_state "$target" "$ROOT/$source")" "$target"
  done < <(selected_entries)
  exit 0
fi

# Newest <target>.bak.* for a target, or the empty string. The timestamp format
# is %Y%m%d%H%M%S, so the newest is also the last in a plain string sort.
newest_backup() {
  local target="$1" candidate newest=''
  for candidate in "$target".bak.*; do
    [[ -e $candidate ]] || continue
    [[ -z $newest || $candidate > $newest ]] && newest="$candidate"
  done
  printf '%s\n' "$newest"
}

# ---------- Unlink ----------
# The inverse of install, with the same dry-run default. A target is removed
# only when it is a symlink into this repository. A real file, or a symlink
# pointing somewhere else, belongs to someone else and is reported, not touched.
if [[ $ACTION == unlink ]]; then
  echo "platform: $PLATFORM"
  echo "repository: $ROOT"
  if ! $APPLY; then
    echo
    echo 'DRY RUN. Nothing will be changed. Re-run with --apply.'
  fi
  echo

  considered=0
  unlinked=0
  errors=0

  while IFS=$'\t' read -r module source target; do
    src="$ROOT/$source"
    considered=$((considered + 1))
    state="$(link_state "$target" "$src")"

    case "$state" in
      linked)
        if $APPLY; then
          if rm -- "$target" 2>/dev/null; then
            printf '  %-8s unlinked   %s\n' "$module" "$target"
            unlinked=$((unlinked + 1))
          else
            printf '  %-8s ERROR      could not remove %s\n' "$module" "$target"
            errors=$((errors + 1))
            continue
          fi
        else
          printf '  %-8s would unlink %s\n' "$module" "$target"
        fi

        backup="$(newest_backup "$target")"
        if [[ -n $backup ]]; then
          if $RESTORE; then
            if $APPLY; then
              mv -- "$backup" "$target"
              printf '  %-8s restored   %s\n' "$module" "$target"
            else
              printf '  %-8s would restore %s\n' "$module" "$backup"
            fi
          else
            printf '  %-8s backup     %s\n' "$module" "$backup"
          fi
        fi
        ;;
      wrong-link)
        printf '  %-8s skipped    %s (symlink to somewhere else)\n' "$module" "$target"
        ;;
      file)
        printf '  %-8s skipped    %s (a real file, not our link)\n' "$module" "$target"
        ;;
      missing)
        printf '  %-8s absent     %s\n' "$module" "$target"
        ;;
    esac
  done < <(selected_entries)

  echo
  if $APPLY; then
    echo "$unlinked unlinked, $considered considered, $errors errors."
    $RESTORE || echo 'Backups were left in place. Re-run with --restore to move the newest one back.'
  else
    echo "$considered considered, $errors errors. Re-run with --apply."
  fi

  [[ $errors -eq 0 ]] && exit 0
  exit 1
fi

# ---------- Install ----------
echo "platform: $PLATFORM"
echo "repository: $ROOT"
$APPLY || echo
$APPLY || echo 'DRY RUN. Nothing will be changed. Re-run with --apply.'
echo

planned=0
changed=0
errors=0

while IFS=$'\t' read -r module source target; do
  src="$ROOT/$source"

  if [[ ! -e $src ]]; then
    printf '  %-8s ERROR      missing source: %s\n' "$module" "$source"
    errors=$((errors + 1))
    continue
  fi

  state="$(link_state "$target" "$src")"
  planned=$((planned + 1))

  case "$state" in
    linked)
      printf '  %-8s ok         %s\n' "$module" "$target"
      continue
      ;;
    file | wrong-link)
      # Backing up ~/.gitconfig is correct and also moves the user's name and
      # email out of the way, and the next commit is authored by nobody. Say so
      # before it happens, in dry run too, with the commands that fix it.
      if [[ $(basename -- "$target") == .gitconfig ]] && grep -q '^\[user\]' "$target" 2>/dev/null; then
        echo
        printf '  %-8s NOTE       %s has a [user] section.\n' "$module" "$target"
        echo '           It will be backed up, not lost, but your identity has to move to'
        echo '           ~/.gitconfig.local or your next commit is authored by nobody:'
        echo
        printf '             git config --file ~/.gitconfig.local user.name  "%s"\n' "$(git config user.name 2>/dev/null || echo 'Your Name')"
        printf '             git config --file ~/.gitconfig.local user.email "%s"\n' "$(git config user.email 2>/dev/null || echo 'you@example.com')"
        echo
      fi
      backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
      if $APPLY; then
        mv -- "$target" "$backup"
        printf '  %-8s backed up  %s\n' "$module" "$backup"
      else
        printf '  %-8s would back up %s\n' "$module" "$target"
      fi
      ;;
    missing) ;;
  esac

  if $APPLY; then
    mkdir -p -- "$(dirname -- "$target")"
    if ln -s -- "$src" "$target" 2>/dev/null; then
      printf '  %-8s linked     %s -> %s\n' "$module" "$target" "$source"
      changed=$((changed + 1))
    else
      printf '  %-8s ERROR      could not link %s\n' "$module" "$target"
      if [[ $PLATFORM == gitbash ]]; then
        echo '           Symlinks on Windows need permission. Enable Developer Mode'
        echo '           (Settings > System > For developers) or run from an elevated shell.'
      fi
      errors=$((errors + 1))
    fi
  else
    printf '  %-8s would link %s -> %s\n' "$module" "$target" "$source"
  fi
done < <(selected_entries)

echo
if $APPLY; then
  echo "$changed changed, $planned considered, $errors errors."
  echo
  echo 'Next:'
  echo '  cp shared/shell/local.sh.example ~/.shell.local   # machine-local shell config'
  echo '  exec "$SHELL" -l                                  # reload'
else
  echo "$planned links planned, $errors errors. Re-run with --apply."
fi

[[ $errors -eq 0 ]]
