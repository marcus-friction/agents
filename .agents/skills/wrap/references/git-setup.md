# Git setup

Use Git throughout the handoff. Provider CLIs and browser authentication are
optional adapters, not replacements for Git or evidence of mutation authority.
For a confirmed GitHub remote, follow [GitHub](github.md).

## Missing Git or repository

Check the installed Git version before repository inspection. Resolve a missing
command separately from a failing command. Inspect the OS and package manager,
then install from official sources only after approval for the package, scope,
and privilege. Do not add a package manager or upgrade a working tool silently.

Run `git -C <project-root> rev-parse --show-toplevel`. An existing parent
repository, worktree, submodule, or `.git` file counts; permission, ownership,
or corrupt-metadata errors do not prove absence. Repository initialization is a
separate Git effect that requires exact authority after an exact preview of the
physical project root and initial-branch choice. A generic wrap must not
initialize a repository; commit-only, push-only, and read-only requests do not
authorize it either. After exact initialization authority, preserve the
configured initial branch and verify the resulting top-level path.
Initialization never authorizes staging, commit, remote creation, or
publication. Before a first commit, inspect ignore rules and secrets and resolve
author identity without inventing or changing global configuration.

## Remote capability and authentication

Resolve the actual remote provider and hostname. Preserve local-only work and
existing providers; an absent remote is not consent to create one. Use an
installed provider CLI only when its identity and repository match the intended
target. Inspect authentication without printing tokens or secret-bearing
responses. Login, account switching, credential-helper changes, SSH-key
creation/upload, extra scopes, and insecure credential storage each need their
own applicable decision.

If setup or authorization is unavailable, finish unaffected local work and give
a precise manual handoff. Do not install an unplanned adapter, substitute an
account/provider, or treat successful login as push, integration, release, or
cleanup authority.
