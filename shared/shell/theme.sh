# shellcheck shell=sh
# Make terminal tools follow the OS light/dark setting.
#
# A terminal emulator switches with the OS; the programs inside it cannot see
# that switch. bat, delta, less, and vim read COLORFGBG instead, which encodes
# "foreground;background" as ANSI colour indices:
#
#   "15;0"  bright on dark  -> the tool picks a dark theme
#   "0;15"  dark on bright  -> the tool picks a light theme
#
# Nothing sets it for you on macOS or Windows. Deriving it once at startup means
# one OS toggle moves the terminal, the pager, the diff viewer, and the editor
# together. A shell started before the toggle keeps the old value; call
# `theme_refresh` to re-read it.

# Print "light" or "dark" for the current OS appearance.
theme_detect() {
  # macOS: the key is absent entirely in light mode, which is why the exit
  # status is the signal rather than the value.
  if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
    if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
      echo dark
    else
      echo light
    fi
    return 0
  fi

  # Windows, reached from Git Bash (reg.exe on PATH) or from WSL (reg.exe under
  # the /mnt/c mount). AppsUseLightTheme: 0x0 = dark, 0x1 = light.
  _theme_reg=''
  if command -v reg.exe >/dev/null 2>&1; then
    _theme_reg=reg.exe
  elif [ -x /mnt/c/Windows/System32/reg.exe ]; then
    _theme_reg=/mnt/c/Windows/System32/reg.exe
  fi

  if [ -n "$_theme_reg" ]; then
    # `//v` rather than `/v`: MSYS rewrites a leading single slash into a
    # Windows path before reg.exe ever sees it, and the doubled slash is the
    # documented escape. Under WSL there is no such rewriting, but the doubled
    # form is accepted there too, so one code path covers both.
    _theme_value=$("$_theme_reg" query \
      'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' \
      //v AppsUseLightTheme 2>/dev/null | tr -d '\r' |
      awk '/AppsUseLightTheme/ { print $NF }')
    unset _theme_reg
    if [ "$_theme_value" = "0x1" ]; then
      unset _theme_value
      echo light
      return 0
    fi
    unset _theme_value
    echo dark
    return 0
  fi

  # Linux with no Windows registry in reach. There is no portable answer, so
  # honour an explicit override and otherwise assume dark, which is what most
  # terminals default to.
  case "${DOTFILES_THEME-}" in
    light | dark)
      echo "$DOTFILES_THEME"
      ;;
    *)
      echo dark
      ;;
  esac
}

# Re-read the OS appearance and export COLORFGBG.
theme_refresh() {
  if [ "$(theme_detect)" = "light" ]; then
    COLORFGBG='0;15'
  else
    COLORFGBG='15;0'
  fi
  export COLORFGBG
}

theme_refresh
