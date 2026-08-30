# shellcheck shell=sh
# Aliases shared by every platform.
#
# The bar for adding one: it must be something typed several times a day, and
# the short form must be unambiguous six months later. An alias you have to
# look up is worse than the command it replaced.

# ---------- Listing ----------
# --color=auto rather than =always: `always` emits escape codes even when the
# output is a pipe, which corrupts anything downstream that parses it.
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ---------- Navigation ----------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ---------- Safety ----------
# Interactive-on-overwrite. These do not protect against a scripted `rm`, and
# they are not a security control; they just catch the tired typo.
alias cp='cp -i'
alias mv='mv -i'

# ---------- Git ----------
# Deliberately few, and only the ones typed dozens of times a day. Anything
# longer belongs in `~/.gitconfig.local` as a git alias, where it also works
# from an IDE and from a script rather than only from an interactive shell.
alias g='git'
alias gs='git status -s'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

# ---------- Grep ----------
alias grep='grep --color=auto'

# ---------- Directory stack ----------
alias d='dirs -v'

# ---------- Misc ----------
# Human-readable by default; the byte counts are almost never what you wanted.
alias df='df -h'
alias du='du -h'

# Print the public IP without opening a browser.
alias myip='curl -fsS https://api.ipify.org && echo'

# Re-read the shell configuration in place. Faster than opening a new tab and
# losing the current directory.
alias reload='exec "$SHELL" -l'
