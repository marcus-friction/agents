# Release v1.7.2

Publish the accepted plan/task maintenance policy as patch release 1.7.2.
The user authorized wrap and release, following the prior PR/CI release flow.
Source master: `aca384c3f84cd20c4d5eb5fd5f70a77afe68f54d`.
Latest published release: v1.7.1. Use `codex/release-1.7.2` and target master.

## Scope and evidence

- Accepted behavior: keep plans and task lists current before progress reports
  or handoff; append dated extensions; add emerging tasks; verify completion;
  report against task items. Preserve approval and read-only boundaries.
- Files: root and `project-templates/base/AGENTS.md`; `VERSION`;
  `.agents/.claude-plugin/plugin.json`; `.claude-plugin/marketplace.json`;
  current release links in `README.md` and `docs/ecosystem-reference.md`;
  `docs/releases/2026-09-14-plan-task-maintenance.md`; this plan pair.
- Evidence: README, CONTRIBUTING, both AGENTS files, wrap/setup/handoff,
  change-rigor, plan and review-plan skills, previous scoped review, version
  contracts, CI workflow and v1.7.1 release. `docs/solutions/` is absent.
- Knowledge: low/not applicable; this straightforward clarification is already
  the requested policy, not a non-obvious reusable troubleshooting lesson.
- R1 local documentation/metadata; R2 public push, PR, merge, tag and release
  in `marcus-friction/agents`, using the existing authenticated user CLI account.
  Runtime, data, UI, dependencies and application deployment are not affected.
- Skills, stack, installer, credentials, historical plans/releases, existing
  branches and tags are excluded. Existing projects retain their AGENTS.md;
  the installer stages an inactive candidate for deliberate reconciliation.

## Execution

1. Review the release plan and final policy wording independently. Synchronize
   all three version fields, current release links and concise release notes.
2. Run policy, document-budget, documentation, authority, provenance and plugin
   contracts plus whitespace checks; run `bash tests/run.sh`. Prose has no new
   production behavior to unit-test. Live-agent evaluations are not performed.
3. Commit only the scoped files, push the new branch and open a master PR.
   Wait for full CI success. Revalidate exact PR head and unchanged tested base
   before normal merge; do not bypass failed checks.
4. Verify the actual merge SHA and remote master. Publish latest, non-draft,
   non-prerelease v1.7.2 at that exact SHA, with the full immutable reference,
   verification and adoption limits in the release record. Verify the tag.
5. Fast-forward local master. Commit/push this tracker alone as post-release
   evidence; do not move the published tag. Verify clean, synchronized master.

Update tasks as each result is verified, before reporting progress. Append a
dated amendment here and extend tasks if accepted scope changes.

## Failure handling and acceptance

Failed checks block publication. Stop on unexpected conflicting work, an
existing target tag/release or rejected Git mutation; never force, rewrite a
tag, automatically rebase/retry or delete branches. If publication fails after
merge, report partial completion. Recovery uses a corrective/revert commit or
later release, not history replacement.

Complete when the policy and metadata agree, local checks and PR CI pass, the
reviewed PR is merged, the release tag/record bind its exact merge SHA, and
master is clean and synchronized with final evidence recorded.
