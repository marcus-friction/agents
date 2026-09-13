# Release v1.7.1

Release the accepted wrap CLI/setup changes, including WRAP-001's flag
compatibility correction. User authorized wrap and a new release. Use existing
Git/GitHub CLIs and authentication for public `marcus-friction/agents`.
Current master: fb950cf7b8b5095fc7b77d1f2ee83c0d081c9562. Latest release: v1.7.0.
Choose patch version 1.7.1 for this bounded workflow improvement.

Evidence: README.md, CONTRIBUTING.md, wrap skill and both references, prior
eight scenario simulations, scoped review and local gh 2.45.0 command parsing.
CI runs the full offline suite on pull requests. Master is unprotected; still
require passing CI. No docs/solutions directory. Compound rating: low for the
straightforward CLI-version mismatch; setup guidance already contains the fix,
so knowledge is not applicable and no solution artifact is needed.

Scope: the three wrap files; VERSION; both plugin/marketplace version fields;
README and ecosystem reference current release links; new release notes; this
plan pair; provenance test's stale hardcoded version assertion. No stack,
installer, credential, account, package, runtime or dependency changes.
Documentation edits are R1; public commit/push/merge/tag/release effects are R2.
Existing v1.7.0 history/tag stays immutable. No branch deletion or force push.

1. Independently review this plan and recheck WRAP-001's correction. Bump the
   three version fields, update current links and add concise release notes.
   Make the provenance assertion use VERSION rather than a historical literal.
2. Validate metadata, supported login argument parsing (help only), provenance,
   plugin versions, documentation, policy and whitespace; run the full offline
   suite. No live login or host installation is needed for instruction edits.
3. On codex/release-1.7.1, commit only the scoped paths and push to origin.
   Open a master PR with review and test evidence. Wait for full CI success;
   verify exact head and unchanged tested base before a normal merge.
4. Resolve the merge SHA and confirm master points to it. Create public,
   non-prerelease v1.7.1 at that exact SHA with full SHA and verification in its
   release record. Verify the dereferenced tag, record and merge relationship.
5. Fast-forward local master, then commit/push this tracker alone with final
   evidence as post-release bookkeeping. Never move the published tag.

Failure handling: failed checks block publication. Inspect unexpected changes,
stop on rejected Git mutations without automatic force/rebase/retry, and never
overwrite an existing tag or release. If merge succeeds but publication fails,
report partial completion. Recovery is a new correction/revert commit or later
release. Application architecture/data/UI checks are N/A; CLI permission and
credential boundaries retain prior reviewed safeguards.

Acceptance: all version metadata agrees; required behavior and WRAP-001 are
verified; CI passes; PR merged; release record identifies the actual tagged merge
SHA; workspace is clean and local master synchronized. Report unperformed live
setup/authentication and registered live-agent evaluations without implying pass.
