# Bulk installer temporary-cleanup race

## Objective

Make bulk-installer work-directory cleanup tolerate the confirmed transient
`ENOTEMPTY` boundary without broadening deletion scope, hiding a persistent
failure, or weakening installer effect checks. Restore the required exact-head
**Offline deterministic** gate on PR #7.

## Evidence and root cause

GitHub Actions runs `35930588950` and `35930995881` both completed the final
bulk-installer clone, commit, push, and simulated pull-request publication, then
failed at `cleanup_work` because its single `rm -rf` could not remove the exact
owned temporary clone while `.git` was transiently non-empty. The same targeted
test passed three consecutive local repetitions. The failure predates the
generalized lifecycle change and occurs only at the filesystem cleanup boundary;
all functional and effect assertions before it pass.

The current implementation makes one removal attempt under `set -e`, so a
recoverable filesystem race fails the whole suite. The accepted fix is a small,
bounded retry at that exact owned path. It must still fail after its retry limit
when the directory persists, and it must never delete a symlink or a path outside
`/tmp/agents-ecosystem-bulk-work.*`.

## Test-first implementation

1. Extend `tests/install-into-repos-test.sh` with a narrow `rm` wrapper that
   fails the first cleanup of one exact bulk-work directory, records that path,
   and delegates every other removal to the real command.
2. Run the targeted test against current production code and retain the expected
   red failure at cleanup.
3. Change only `cleanup_work` in `scripts/install-into-repos.sh` to retry the
   exact validated physical directory a bounded number of times. Succeed only
   when the path is absent; report and return failure when it persists.
4. Prove the new regression green, run repeated targeted executions, then run
   `git diff --check` and the complete `bash tests/run.sh` suite.
5. Commit the plan pair, test, and implementation as
   `fix(installer): retry transient worktree cleanup`; push without force to the
   existing PR #7 branch, update checkpoint comment `5804270691`, and observe
   **Offline deterministic** on the exact new head.

## Boundaries

No dependency, architecture, release artifact, version, provider policy, or
unrelated cleanup change is included. The authorized increment stops after the
exact-head check. PR integration, v1.9.0 tag and GitHub release publication,
deployment, and current-branch cleanup remain unauthorized.

## Verification map

| Outcome | Evidence |
|---|---|
| A one-time exact-path cleanup failure recovers | New deterministic wrapper case fails red, then passes green |
| A persistent cleanup failure remains visible | Existing nonzero cleanup behavior plus the bounded retry exhaustion assertion |
| Scope and symlink protections remain intact | Existing bulk-installer boundary suite |
| No regression across the distribution | `bash tests/run.sh` and `git diff --check` |
| Host gate binds the remediation | PR #7 **Offline deterministic** success on the exact pushed head |

## Local verification evidence

- The narrowed regression failed against the original single-attempt cleanup
  only at the injected exact-root removal.
- The regression passed after the bounded retry change and passed three further
  consecutive targeted repetitions.
- `bash -n scripts/install-into-repos.sh tests/install-into-repos-test.sh` and
  `git diff --check` passed.
- `bash tests/run.sh` passed with
  `offline-deterministic=passed` and 66 registered live-agent cases not run by
  that offline profile.
