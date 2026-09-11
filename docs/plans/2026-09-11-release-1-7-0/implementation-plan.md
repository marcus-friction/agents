# Publish v1.7.0

Scope: release the reviewed TomFit 0.2.0 adaptation, fixes and deploy skill from
`codex/sync-tomfit-agents` into `master` in public `marcus-friction/agents`.
The user authorized merge and release. Use existing GitHub authentication.
No runtime changes, dependencies, force pushes, moved tags or branch deletion.

Evidence: AGENTS.md, CONTRIBUTING.md, README.md, ecosystem reference, pending
v1.7.0 notes, completed review/deploy trackers and passing deterministic suite.
GitHub master is 4d599c098f0d2cbb8575d95d4d91899554621fc2; branch head is
bd8582b9630c717f90de7fe53f2eea2a45d18bac. No releases/tags or PR exist.
CI is pull-request-only; master is unprotected. No docs/solutions directory.
Public Git publication is R2; instruction-only documentation is R1. No runtime,
data or UI architecture changes. Prior knowledge remains captured in guidance
and regressions; no new solution artifact is needed.

1. Review this plan independently. Update README.md,
   docs/ecosystem-reference.md and existing v1.7.0 release notes to describe the
   completed scope and point to the GitHub release's full-SHA record. Preserve
   stable installer placeholders and the release-record requirement.
2. Run documentation/policy checks and whitespace checks. Commit only those
   documents and this plan pair, push the existing branch, and open a PR to
   master with verification and limitations. No new application behavior tests.
3. Wait for the PR's offline suite to pass. Confirm its head SHA, mergeability,
   review state and unchanged base; use a normal merge commit, never a bypass.
4. Read the actual merge SHA, ensure it is master, and publish v1.7.0 targeting
   that exact SHA. Include the full SHA, changes, upgrade guidance and test gaps.
5. Verify the release/tag/master relationship and synchronize local master by
   fast-forward only. Report URLs and actual outcomes.

Failure handling: failed CI blocks merge; unexpected code/base changes need
inspection; rejected pushes/merges stop without automatic rebase or force.
An existing tag/release is inspected, never overwritten. If publication fails
after merge, report master as merged and release as incomplete. Recovery is a
new corrective/revert commit or successor release, not rewritten history.
Completion: PR merged, public non-prerelease v1.7.0 resolves to the verified
master SHA, release record carries that SHA, and local work is accounted for.
