# Git and GitHub setup

Use the CLIs throughout the handoff. Browser interaction is for the user's
account signup and CLI-initiated login, not a replacement for Git operations.
This setup does not authorize a commit, push, or remote repository creation.

## Missing tools

Check `git --version` and, for a GitHub handoff, `gh --version`. Resolve a
missing command separately from an installed command that fails. Inspect the
host OS and existing package manager; use current official instructions for
[Git](https://git-scm.com/downloads/) and
[GitHub CLI](https://cli.github.com/). Install the missing tool after confirming
the package, installation scope and any elevated permissions with the user.
Do not silently add a package manager, change system policy, or upgrade working
tools. Verify the CLI version afterward. If installation is declined or blocked,
finish unaffected handoff work and report the exact setup step still needed;
do not switch to another integration to bypass the CLI requirement.

## Missing local repository

After Git works, run `git -C <project-root> rev-parse --show-toplevel`.
An existing parent repository, worktree or submodule counts as a repository:
do not initialize a nested replacement. A `.git` file is valid for worktrees.
Permission, unsafe-ownership and corrupt-metadata errors are not evidence that
the repository is absent; diagnose them without deleting metadata or adding a
global trust exception.

When the intended project root genuinely has no repository, an explicit wrap
includes `git init <project-root>`. Preserve an adopted initial-branch choice;
otherwise keep Git's configured default. Never initialize a home/workspace
parent in place of the project. Verify the resulting top-level path and status.
If the request is strictly read-only, forbids Git changes, or limits writes to
an exact commit/push scope, ask before initialization. Do not stage files, make
an initial commit, add a remote, or publish as a side effect of initialization.
Before an authorized first commit, inspect ignore rules and secrets and resolve
missing author name/email with the user; do not invent identity or change global
configuration.

## GitHub authentication

For a GitHub handoff, resolve the host from the intended remote. Preserve other
hosting providers and local-only requests. If no host is chosen, ask whether
the user wants GitHub before setting it up; an absent remote is not consent to
create one. GitHub Enterprise uses its actual hostname, not `github.com`.

Check `gh auth status --hostname <host>` without `--show-token`. Inspect the
active account as well as failures; network errors or access denial do not prove
that the user lacks an account. Reuse working authentication for the intended
account. Before login or an account switch, ask whether the user already has
an account on that host and wants to authorize this CLI. If they do not have a
GitHub.com account, guide them to [Create an account](https://github.com/signup)
to sign up and verify their email themselves, then return to CLI login. For an
enterprise host, use its account/invitation process. Never ask for passwords,
tokens, recovery codes or two-factor codes in chat.

Inspect `gh auth login --help` from the installed CLI before choosing flags.
After consent, use `gh auth login --hostname <host> --web` in an interactive
terminal. Add `--skip-ssh-key` only when that help lists it; otherwise decline
any SSH-key generation/upload prompt explicitly. If the installed flow cannot
skip an unapproved effect, stop and explain instead of accepting it or silently
upgrading the CLI. Let the user complete its browser/device flow. Preserve
the adopted Git transport when answering protocol prompts; decline offered Git
credential configuration unless it was approved. Do not generate/upload SSH
keys, change credential helpers or request additional scopes without covering
those effects in approval.
Check credential-store availability before login: `gh` can fall back to a
plaintext file. Do not select `--insecure-storage` or accept that fallback
silently; if secure storage cannot be verified, resolve it or obtain an explicit
storage choice before starting login.
Keep existing environment-provided credentials private and do not overwrite
them to force a different account.

Recheck authentication and the intended repository access with the CLI. A
working login alone does not prove push permission or configure Git transport.
If authorization is declined, expires, or cannot be completed, pause only the
GitHub effects and explain how to resume. Do not repeatedly prompt or substitute
another account. Continue local work that remains authorized.

Command references: [login](https://cli.github.com/manual/gh_auth_login),
[authentication status](https://cli.github.com/manual/gh_auth_status).
