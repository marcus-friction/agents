# Git Handoff

Load this reference only when wrap needs to preview or execute a commit or push.
All completion gates in `../SKILL.md` must already be resolved.

Use `git` for local history and transport, and `gh` for GitHub operations.
Resolve missing tools, repository state, and required authentication through
[Git and GitHub setup](git-setup.md) before executing Git effects. Setup does
not grant commit, remote creation, push, or publication authority.

## Preview

Reinspect the workspace and group only accepted changes into atomic commits
that each leave the repository coherent. Show:

- every gate disposition;
- each proposed Conventional Commit message and its exact files or reviewed
  hunks; and
- any push destination, remote ref, exposure, credential class, and recovery
  path.

A generic wrap asks once which Git effects to execute. An already authorized
exact commit may proceed without a redundant kickoff. Commit and push are
independent effects; approval for one never implies the other.

## Execute

Immediately before mutation, revalidate the exact files or hunks, branch,
remote, ref, and relevant worktree state. Stop if a relevant fact changed and
preserve unrelated work.

- Stage exact physical files or reviewed hunks; never use `git add .` or
  `git add -A`.
- Create only authorized commits, in dependency order, and report their hashes
  and subjects.
- Push only with exact push authority and just-in-time confirmation of the
  remote, ref, exposure, credential class, and recovery path. Never force.
  Revalidate these facts; do not ask again when existing approval still covers
  them. CLI setup or login consent is not push approval.
- If push is rejected, report options. Do not automatically pull, rebase,
  merge, amend, retry, or rewrite history.

## Boundaries

Never silently rebase, merge, amend, force-push, rewrite history, delete files
or branches, publish a pull request or release, create tags, or create release
documentation. Each destructive or publication effect requires its own exact
authority.
