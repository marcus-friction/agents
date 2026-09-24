# Git Handoff

Load this reference when wrap previews or executes commit and push effects. All
completion gates in `../SKILL.md` must already be resolved. Provider change-
request, integration, and remote cleanup details belong in an adopted adapter;
use [GitHub](github.md) only for a confirmed GitHub remote.

## Preview

Reinspect the workspace and group only accepted changes into atomic commits
that each leave the repository coherent. Show every gate disposition, each
proposed Conventional Commit message and exact physical files or reviewed
hunks, the source branch, and any push remote/ref, exposure, credential class,
and recovery path.

A generic wrap asks once which unchanged, fully disclosed effects to execute.
An exact request may proceed without a redundant kickoff. Commit and push are
independent effects and neither implies change-request publication,
integration, release, deployment, or cleanup.

## Execute

Immediately before mutation, revalidate exact files/hunks, branch, physical
worktree, remote, ref, and relevant status. Stop if a material fact changed.

- Stage exact files or reviewed hunks; never use `git add .` or `git add -A`.
- Create only authorized commits, in dependency order, and record hashes and
  subjects in the delivery checkpoint.
- Push only the authorized local ref to the named remote/ref. Confirm exposure,
  credential class, and recovery just in time. Never force.
- If push is rejected or its outcome is ambiguous, inspect remote state. Do not
  automatically pull, rebase, merge, amend, retry, or rewrite history.

After a verified push, return to the orchestrator for review/check gates,
integration, release, and cleanup. Git setup or authentication never grants
authority for any of those effects.
