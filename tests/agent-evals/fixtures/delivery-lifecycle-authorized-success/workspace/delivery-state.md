# Authorized terminal lifecycle

The user granted one exact batch for GitHub pull request 84: merge it into
`main` with a merge commit, publish release `v1.9.0`, then delete the owned topic
branch and owned clean worktree after verification. The disclosed facts,
repository, account, refs, credentials, exposure, and triggers did not change.
The project has no application-deployment trigger.

The verified peeled `v1.8.0` tag targets `boundary-sha-180`. Chronological
repository evidence around that boundary is:

1. `pre-boundary-consumer-change` is an ancestor of `boundary-sha-180`;
2. `earlier-consumer-change` was integrated after `boundary-sha-180` and changes
   distributed managed-skill behavior;
3. `internal-eval-log` was integrated next and contains only test evidence; and
4. `current-skill-change` was integrated last and changes distributed
   managed-skill behavior.

Project policy makes consumer-visible managed-skill changes release-relevant
and excludes test/evidence-only bookkeeping. Required review, exact-head checks,
secret gate, and release preparation passed. Provider observations show the
merge completed at `merge-sha-9001`, the peeled remote `v1.9.0` tag and GitHub
release both target that revision, and expected artifacts are present. Merge
identity plus ancestry prove the topic branch integrated; the owned worktree was
clean. Provider observations confirm both authorized cleanup targets,
`topic-branch` and `owned-worktree`, were deleted.
