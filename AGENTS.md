# AGENTS.md

Shell, prompt, and git configuration for macOS (zsh), Windows Git Bash, WSL
(bash), and Windows PowerShell. Two machines, three platforms, four rc files.
`README.md` is the document for people; this is the working contract.

## The gate

```sh
bash ./scripts/check.sh
```

Exit 0 or the change is not done. It validates the manifest, every relative
markdown link, every repository path named in the markdown, every runnable
script being named by the markdown, shellcheck at severity error, and a parse
pass over every shell file. There is no other test command and no build step. CI runs the same script, and additionally applies,
unlinks, and restores the real installers against a throwaway home directory on
macOS, Ubuntu, and Windows.

## Single source of truth

`scripts/modules.conf` decides what is linked where. To change what gets
installed, edit that file and nothing else: `scripts/install.sh`,
`scripts/install.ps1`, and `scripts/check.sh` all read it. One link per line,
pipe separated:

    module | source | target | platforms

Platform keys are `macos`, `gitbash`, `wsl`, `windows`. The README's
"Installation manifest" table restates it for people, so it moves in the same
change; the gate fails if a path named there stops existing.

## Constraints

- **bash 3.2.** macOS still ships it. No associative arrays, no `mapfile`, no
  `${var^^}`. A `case` inside `$( ... )` needs a leading `(` on every pattern:
  3.2 scans for the closing paren without understanding case, so an unbalanced
  `)` ends the substitution early and the file stops parsing. It is a syntax
  error, so it fails on macOS and nowhere else.
- **POSIX `sh` under `shared/shell/`.** zsh and bash both source those files.
  A bashism belongs in the platform rc file instead.
- **No dependencies.** No language runtime, no package manager, no `jq`. A
  repository that configures shells should not need one to check itself. This is
  what keeps `shared/claude/` to two declarative files: hooks, a statusline
  command, and agent scripts would all drag a runtime in behind them.
- **LF only**, enforced by `.gitattributes`. A CRLF in a sourced file is a
  syntax error.
- **Nothing private in a tracked file.** No identity, token, employer name, or
  machine-specific path. Every rc file sources an untracked `*.local` sibling
  last, and that is where those belong.

## Writing to disk

Dry run is the default everywhere, and `--apply`, or `-Apply` in PowerShell, is
the only thing that writes. Keep it that way for anything new. Do not test with
`--apply` against a real home directory: `bash ./scripts/test-install.sh` runs
the real write path against a throwaway one, and `scripts/test-install.ps1` does
the same for PowerShell.

Nothing is ever deleted. A target that already exists is renamed to
`<target>.bak.<timestamp>` before a link replaces it.

## Layout

    shared/shell/   POSIX sh, sourced by all four shells
    shared/git/     gitconfig and the global ignore file
    shared/claude/  the two files Claude Code reads at user scope
    macos/          zshrc, bootstrap
    windows/        bashrc, bash_profile, PowerShell profile, starship
    wsl/            bashrc, bootstrap, wsl.conf examples
    scripts/        installers, doctors, install tests, the gate, the manifest

Every script's header block is its usage, and `-h` prints it. The PowerShell
scripts use comment-based help, so `Get-Help` covers those.

## README

It is short on purpose. Adding a section means cutting one.
