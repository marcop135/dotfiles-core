# Support

## Something is not working on your machine

Run the doctor first. It checks the things that go wrong on a real machine
rather than in the repository: a missing shell, a target that is a regular file
instead of a link, a link pointing at a tree that has moved, symlink permission
on Windows.

```sh
./scripts/doctor.sh
```

```powershell
.\scripts\doctor.ps1
```

Then see the current link state, which is a dry run and changes nothing:

```sh
./scripts/install.sh --status
```

If that does not explain it, open a
[discussion](https://github.com/marcop135/dotfiles-core/discussions) and paste
the doctor output, your platform, and your shell.

## Something is wrong with the repository

A manifest that links the wrong file, an installer that fails on one platform,
a shell fragment with a syntax error: that is a bug. Open an
[issue](https://github.com/marcop135/dotfiles-core/issues/new/choose) using the
bug form.

## A credential or personal detail in the tree

Not an issue and not a discussion. [SECURITY.md](SECURITY.md) has the private
route.

## Scope

This is a personal configuration repository published in the open. Issues and
pull requests are welcome, and there is no support commitment attached to
either. [CONTRIBUTING.md](CONTRIBUTING.md) covers what a change has to hold to.
