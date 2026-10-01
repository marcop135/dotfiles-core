# Contributing

This repository configures four shells on three platforms from one tree. A
change is portable or it is a regression somewhere you are not sitting.

## The gate

```sh
bash ./scripts/check.sh
bash ./scripts/test-install.sh
```

Exit 0 on both or the change is not done. The first validates the manifest,
every relative markdown link, every repository path named in the markdown,
every runnable script being named by the markdown, ShellCheck at severity
error, and a parse pass over every shell file. The second runs the real write
path against a throwaway home directory: apply, unlink, restore.

There is no build step and no other test command. CI runs the same two scripts
on macOS, Ubuntu, and Windows, so a green run locally on one platform is half
the answer.

Windows contributors run the PowerShell side as well:

```powershell
.\scripts\test-install.ps1
```

## Constraints

[AGENTS.md](AGENTS.md) is the working contract and the full list. The five that
break a build most often:

- **bash 3.2.** macOS still ships it. No associative arrays, no `mapfile`, no
  `${var^^}`.
- **POSIX `sh` under `shared/shell/`.** zsh and bash both source those files. A
  bashism belongs in the platform rc file.
- **No dependencies.** No language runtime, no package manager, no `jq`.
- **LF only**, enforced by `.gitattributes`. A CRLF in a sourced file is a
  syntax error.
- **Nothing private in a tracked file.** No identity, token, employer name, or
  machine-specific path. Every rc file sources an untracked `*.local` sibling
  last, and that is where those belong.

## Adding a link

`scripts/modules.conf` decides what is linked where, and the installers and the
gate all read it. A new link is one line there, plus a row in the README's
"Installation manifest" table in the same change. The gate fails if a path named
in either stops existing.

## Writing to disk

Dry run is the default everywhere, and `--apply`, or `-Apply` in PowerShell, is
the only thing that writes. Keep it that way for anything new, and do not test
with `--apply` against a real home directory. Nothing is ever deleted: a target
that already exists is renamed to `<target>.bak.<timestamp>` first.

## Branches and pull requests

Work on `feat/*` off `develop`, and open the pull request against `develop`.
`main` receives release pull requests only. Describe which platforms you
exercised the change on; the pull request template asks for exactly that.

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md) under
`[Unreleased]`, in the same pull request as the change.
