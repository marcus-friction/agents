# Release v1.8.0

Publish the complete consumer-visible change set since v1.7.2 as stable release
v1.8.0. The accepted release includes the review-output feature already on
`master` and the committed generic-wrap preview fix on
`fix/wrap-commit-preview`.

## Acceptance and exclusions

- Synchronize `VERSION`, both plugin-channel manifests, stable-install links,
  the public release index, and concise release notes at version 1.8.0.
- Preserve the behavioral and verification evidence already recorded for both
  accepted increments.
- Integrate through a GitHub pull request into `master`; require the local
  offline suite, the pull-request `Offline deterministic` check, and human
  review before a normal merge.
- Publish an immutable `v1.8.0` Git tag and a latest, non-draft,
  non-prerelease GitHub release at the verified merge SHA.
- Verify the remote tag, release record, and default branch identity.

Application deployment, dependencies, framework changes, force operations,
history rewriting, direct default-branch content commits, and the untracked
`docs/plans/2026-09-23-generalized-wrap-release-lifecycle/` increment are
excluded. The release does not activate or overwrite project-owned documents.

## Evidence and decisions

- `README.md` and `docs/ecosystem-reference.md` define stable installation by
  full SHA from a hosted release record; `master` is explicitly mutable.
- `CONTRIBUTING.md` requires topic branches, pull-request checks, human review,
  and `bash tests/run.sh`. GitHub currently reports no branch protection, so
  project policy remains the controlling gate.
- The latest verified release is v1.7.2 at
  `aec717c50332132bd3f7e783728b8cdd597fe655`.
- The full unreleased history includes tracker evidence `317c6d5`, the
  consumer-visible review-table feature `6c4b84d`, and the wrap fix `a139aa4`.
  Release notes describe the two consumer-visible outcomes without presenting
  tracker-only evidence as a feature.
- Version 1.8.0 is the accepted SemVer target because the unreleased set adds a
  backward-compatible user-visible feature as well as a fix.
- `VERSION`, `.agents/.claude-plugin/plugin.json`, and
  `.claude-plugin/marketplace.json` are the adopted synchronized version fields.
- The v1.7.2 release plan supplies the proven branch -> PR -> CI -> merge -> tag
  and GitHub-release sequence. No relevant compounded release solution exists;
  `docs/solutions/skill-routing-progressive-disclosure.md` informs the wrap
  release note only.

This is R1 for local metadata, documentation, tests, and commits. Push, pull
request publication, merge, tag publication, hosted release publication, and
remote cleanup are R2 public shared-state effects. Immediately before each R2
effect, revalidate the exact repository, refs, public exposure, authenticated
GitHub account over HTTPS, and recovery path. Existing authorization covers
preparation; execute public effects only after presenting their exact preview.

## Files and ownership

- `VERSION`, `.agents/.claude-plugin/plugin.json`, and
  `.claude-plugin/marketplace.json`: synchronized release identity.
- `README.md`: current stable-release link.
- `docs/ecosystem-reference.md`: stable-release link and release index entry.
- `docs/releases/2026-09-23-review-and-wrap-handoffs.md`: adoption-aware v1.8.0
  notes and verification limits.
- This plan pair: live release preparation and terminal evidence.
- The twelve files in commit `a139aa4`: already reviewed release content; do
  not amend their behavioral content during release preparation unless new
  evidence requires a separately recorded scope amendment. The planned stable
  link and release-index edits in `docs/ecosystem-reference.md` are the sole
  release-metadata exception.

## Execution

1. Create `feature/release-1.8.0` from the accepted local head, then update the
   three version fields, both stable links, release index, release notes, and
   this live tracker.
2. Review the complete release set and plan to convergence. Run focused version,
   plugin, documentation, provenance, routing, and authority contracts,
   `git diff --check`, and the complete `bash tests/run.sh` offline suite.
3. Commit only the planned release-preparation paths. Revalidate and preview the
   first public gate: push the exact head to
   `origin/feature/release-1.8.0` and open a public PR against the named current
   `master` base. State the authenticated HTTPS account and that recovery before
   merge is a corrective branch commit or PR closure. Execute only after the
   matching owner decision.
4. Verify the PR's exact head/base and wait for the `Offline deterministic`
   check. The owner must then review that exact head after CI and explicitly
   authorize the named normal merge method. Revalidate the unchanged base and
   present this second public gate before merging; stop on failed or stale
   evidence. Resolve the merge SHA and verify remote `master` points to it.
5. With the merge SHA now known, present the third public gate for immutable
   `v1.8.0` tag publication and a latest, non-draft, non-prerelease public
   GitHub release at that exact SHA. State the authenticated account and that a
   published tag is never moved; recovery is a corrective later release.
   Execute only after the matching owner decision, then verify tag resolution,
   release flags, notes, and full-SHA installation guidance.
6. Create a tracker-only `feature/release-1.8.0-evidence` branch from the released
   `master`, update only this plan pair with the known PR/check/merge/release
   evidence, and pass documentation and whitespace checks. Present a fourth
   public gate for pushing that exact branch and publishing its public evidence
   PR against the then-current `master`; execute only after the matching owner
   decision. Keep `v1.8.0` fixed at the original release merge SHA.
7. Resolve the evidence PR identity, verify its exact head/base and passing
   `Offline deterministic` check, obtain owner review of that exact head, and
   present a fifth public gate for its named normal merge method. Execute only
   after that separate decision. The successful evidence-PR merge record is the
   terminal evidence cutoff; it does not trigger another bookkeeping commit.
8. Present branch cleanup separately after integration and publication are
   verified. Delete a remote or local branch only with exact authorization and
   only when no unique commits, active worktree, or unrelated work would be
   lost. Synchronize local `master` only while preserving unrelated work.

## Verification map

| Outcome | Evidence |
|---|---|
| Version identity agrees | `bash tests/plugin-channel-contract-test.sh` and direct value inspection |
| Stable installation and release links are current | `bash tests/documentation-interface-test.sh`, `bash tests/provenance-contract-test.sh` |
| Review and wrap behavior remain valid | routing/review contract tests and the complete offline suite |
| Repository policy is satisfied | contribution-policy contract, PR CI, and recorded human review |
| Release binds the integrated revision | remote `master`, tag resolution, and GitHub release metadata all equal the verified merge SHA |
| Publication is terminal and recoverable | no moved tag or force operation; corrections use a revert and a later release |

Exact focused commands:

```bash
bash tests/plugin-channel-contract-test.sh
bash tests/documentation-interface-test.sh
bash tests/provenance-contract-test.sh
bash tests/review-skill-contract-test.sh
bash tests/adversarial-review-contract-test.sh
bash tests/skill-routing-contract-test.sh
bash tests/authority-policy-test.sh
bash tests/contribution-policy-consistency-test.sh
git diff --check
bash tests/run.sh
```

Host verification uses read-only `git rev-parse`, `git ls-remote`,
`gh auth status --hostname github.com`, `gh pr view --json`,
`gh pr checks`, `gh api` for the PR review/merge record, `gh release view
--json`, and remote tag resolution. Never use `--show-token`.

## Failure handling and recovery

- Stop if the target tag or release already exists, the PR head/base changes,
  required checks fail, review is missing, or `master` advances after preview.
  Recompute the complete release set rather than retrying blindly.
- Never force-push, move or replace a published tag, bypass checks, rewrite
  history, or silently switch authenticated accounts.
- Before merge, recovery is branch correction or PR closure. After merge but
  before publication, recovery is a normal corrective/revert PR. After release,
  preserve v1.8.0 and publish any correction as a later SemVer release.
- If publication is partial, report the exact completed effects and retain all
  branch/checkpoint evidence until recovery is decided.
- Release-branch push/PR, release-PR merge, tag/release publication,
  tracker-evidence push/PR, tracker-evidence PR merge, and branch cleanup are
  separate R2 gates.
  Authorization for one never implies a later gate whose exact identity or SHA
  did not yet exist.

## Completion

Complete when all release metadata and documentation agree on 1.8.0; local and
host checks plus human review pass for the exact head; the PR is merged into the
unchanged reviewed base; tag and release resolve to the verified merge SHA; and
the tracker-only evidence PR reaches its verified terminal host record without
moving the tag. Local/remote branch state and any retained unrelated work must
be explicitly accounted for.

## Amendment — 2026-09-23: behavior-level review-table evidence

Release testing review retained R180-T01: the review-table feature has strong
source contracts but no consuming-agent assertion that the required Findings,
Results, and Decision tables are actually rendered. This is release-relevant
verification work for the already accepted feature, not a new product behavior.

Extend the live-evaluation result grader with a normalized string-containment
operator, cover that operator directly in the offline profile test, and require
the existing review/adversarial synthesis and degraded-boundary cases to render
all three canonical table headers in their `summary`. Adapt the clean-context
adversarial case to cover the required `None` row. The added scope is:

- `tests/agent-evals/runner.py`;
- `tests/agent-eval-profile-test.sh`;
- `tests/agent-evals/cases.json`; and
- the existing review/adversarial prompts whose result assertions are
  strengthened.

Use a red-green cycle for the grader operator, run the affected live cases at
their registered 3/3 thresholds, then rerun the focused contracts and complete
offline suite. No skill behavior, authority boundary, release identity, or
public effect changes in this amendment.

### Blocked verification — 2026-09-23

The strengthened offline grader contract passed, but the existing heavyweight
review/adversarial live cases could not produce release-qualified evidence.
Three bounded attempts allocated 3,000, 6,000, then 12,000 rollout tokens per
execution. Each attempt ended with `shared rollout token budget exhausted`
while agents reread the complete multi-skill contexts. The signed summaries are
under `/tmp/agents-release-evals.XhRiiR/`,
`/tmp/agents-release-evals.k6B51z/`, and
`/tmp/agents-release-evals.EP9K2E/`; none is release-qualified.

Do not retry the same strategy automatically. Owner direction is required to
either amend the finding correction to purpose-built lean behavioral cases,
explicitly waive the live 3/3 release gate with its residual risk, or stop the
release.

### Owner-approved resolution — 2026-09-23

The owner approved purpose-built lean behavioral cases. Restore the five
pre-existing orchestration prompts and assertions to their prior scope, then add
two read-only cases that isolate only the released report contract:

- standard review renders a retained `REV-001` finding, Results, and a
  `Not ready` Decision; and
- adversarial review renders a `None` findings row, missing coverage in Results,
  and a `Withheld` Decision.

Each case loads only its primary skill, that skill's mandatory references, and
a resolved-state fixture; forbids delegation and mutation; and asserts the
canonical Markdown headers through the normalized `contains` grader. Add the
two fixture directories to the accepted scope and update the registry/profile
count from 45 to 47. Run only these lean cases at their registered 3/3
thresholds before the focused and full offline checks. The three failed
heavyweight batches remain disclosed historical evidence and are not release
evidence.

### Review correction — 2026-09-23

Re-review retained R180-002: the mandatory adversarial scenario-bank path was
attached to the pre-existing independence case instead of the new lean
table-output case. Correct only that registry wiring, rerun the affected
adversarial case at current/comparison 3/3, and repeat the focused contracts,
whitespace check, and full offline suite before requesting another review.
Testing review independently reported the same defect as R180-T02 and retained
one additional guard: the offline profile must assert that this exact case
continues to include the scenario bank.

The corrected case passed current and comparison execution 3/3 at
`/tmp/agents-release-adversarial-evals.FYeYLa/`; summary integrity was verified
against its bound raw output. The deterministic profile guard, both affected
skill contracts, whitespace check, and complete offline suite pass with 47
registered cases. Primary and testing re-reviews returned Ready with no
findings, resolving R180-T01, R180-002, and R180-T02.
