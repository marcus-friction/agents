# Generalized wrap, integration, release, and cleanup lifecycle

## Accepted outcome

Extend the provider-neutral agent distribution so an explicit wrap can take an
accepted increment from completion gates through a reviewable delivery preview,
authorized integration, an applicable verified release, and safe cleanup. Add a
generalized `release` skill for source/package release mechanics. Keep every
project's adopted delivery variables in its active `CONTRIBUTING.md`, seeded by
the canonical inactive candidate at
`project-templates/base/CONTRIBUTING.md`.

The generalized lifecycle is:

```text
completion gates
  -> resolve project delivery contract and unreleased change set
  -> prepare release artifacts when policy requires them
  -> preview exact effects and obtain/reuse authority
  -> commit and publish the topic branch
  -> pass adopted review/check gates and integrate
  -> publish or trigger the release against the verified integrated revision
  -> verify the terminal state
  -> synchronize and safely clean up owned branches/worktrees
```

Release preparation may precede integration because version files, manifests,
or notes can be part of the reviewed change. Release publication or triggering
must follow integration and bind the actual integrated revision.

## Acceptance criteria

- `wrap` owns orchestration and completion reporting, but a generic wrap only
  prepares a complete read-only lifecycle preview. It never silently commits,
  pushes, opens or merges a change request, publishes a release, deploys, or
  deletes a branch/worktree.
- The preview covers commit groups, branch publication, the adopted integration
  route and target, required checks/review, release disposition and preparation,
  release/deployment trigger coupling, recovery, and exact cleanup candidates.
  One exact batch decision can cover unchanged facts, including a future merge
  or release identity that is deterministically constrained to the verified
  review head and integration result; only materially changed facts require a
  new decision.
- The lifecycle discovers the adopted default branch, integration mechanism,
  checks, merge method, release policy, versioning, publication mechanism,
  deployment coupling, verification, recovery, evidence location, and cleanup
  rules from active project evidence. It does not hardcode `master`, GitHub,
  pull requests, SemVer, hosted releases, or deployment.
- A new provider-neutral `release` skill determines the complete unreleased
  change set from the last applicable release boundary, classifies release
  relevance under project policy, prepares required artifacts before
  integration, publishes only with exact authority after integration, verifies
  the resulting immutable identity, and resumes idempotently from partial state.
- Release dispositions are explicit: `required`, `deferred by adopted policy`,
  `not applicable` with a reason, `complete`, `partial`, or `blocked`. Missing
  material release policy is `unresolved`, not an invented default. When
  unresolved preparation could alter the integrated content, integration is
  blocked until resolved.
- Repository release and application deployment remain distinct. Automatic
  release or deployment caused by branch integration, tags, or hosted release
  publication is disclosed before the triggering effect. An automatic release
  is verified after integration rather than triggered twice. Automatic
  deployment requires authority for the actual production/shared-state impact.
- Cleanup begins only after integration is verified and release is terminal
  (`complete`, adopted deferral, or `not applicable`). It deletes only confirmed
  owned and safe branches/worktrees, uses proof appropriate to the adopted merge
  method, refuses unique unintegrated content or unrelated dirty state, and
  remains pending after failed checks, failed integration, or partial release
  publication.
- The project delivery contract selects a secret-free durable checkpoint carrier
  and a terminal-evidence cutoff. A fresh context can use checkpoints and
  observed host state to avoid duplicate effects, but repository text or a
  checkpoint never grants or carries forward mutation authority.
- Any target/base drift after preview recomputes the complete unreleased set,
  release relevance and artifacts, review/check evidence, automatic trigger
  coupling, cleanup proof, and affected authorization before progression.
- The final report has stable `Workspace`, `Quality`, `Commits`, `Integration`,
  `Release`, `Cleanup`, and `Preserved` fields with hashes, remote targets,
  change-request/release identifiers, skipped reasons, and partial checkpoints.
- The canonical `CONTRIBUTING.md` candidate carries a compact generalized
  delivery-contract table. Active project documents own adopted values; empty
  cells are forbidden in favor of an explicit value, `Not applicable`, or
  `Unresolved`. Detailed runbooks may be linked, but default branch,
  integration route, required checks/review, deployment coupling, release
  relevance, checkpoint/evidence ownership and cutoff, and cleanup policy remain
  directly visible.
- This repository's root `CONTRIBUTING.md` adopts its actual GitHub/`master`/CI,
  versioning, release, non-deployment, evidence, and cleanup values without
  presenting unverified host enforcement as fact.
- Existing project-owned documents remain byte-preserved by installation; the
  amended candidate continues to stage only under `.agents/templates/` for
  deliberate `start-project` or `onboard-project` reconciliation.
- Root and candidate `AGENTS.md` permit the adopted terminal-evidence cutoff
  narrowly: repository plans stay live through the project-selected terminal
  repository handoff, while facts produced only by that handoff's later merge
  and cleanup live in selected external records and the final report rather
  than causing another bookkeeping commit. The terminal handoff may be the
  content-bearing change or one bounded evidence-only change; remediation
  starts a new tracked increment instead of reopening a closed release
  recursively.
- Deterministic contracts and behavior-oriented agent evaluations cover the
  happy path, provider neutrality, authority boundaries, prior unreleased work,
  automatic deployment, partial publication, idempotent resume, and unsafe
  cleanup. The full offline suite passes, and the selected high-variance live
  cases pass their registered repeated-run thresholds when the executor is
  available.

## Explicit exclusions

- No commit, push, change-request publication, merge, tag, hosted release,
  package publication, deployment, branch deletion, worktree removal, or other
  external effect is authorized by this plan or its implementation.
- Do not add a release provider, package registry, deployment service,
  dependency, or mandatory project-specific `docs/release-process.md`.
- Do not implement GitLab, Bitbucket, package-registry, or deployment-provider
  command adapters in this increment. The canonical workflow must remain usable
  through discovered capabilities or a bounded manual handoff; GitHub is the
  first optional adapter because this repository already adopts it.
- Do not change version metadata or publish this ecosystem merely because the
  skill is implemented. Release preparation and publication are separate work.
- Do not replace or amend the completed
  `docs/plans/2026-09-23-wrap-commit-preview/` increment now shipped in v1.8.0.
- Do not absorb or execute the still-open evidence-publication and cleanup tasks
  in `docs/plans/2026-09-23-release-1-8-0/`; they remain a separate increment
  with separate R2 authority.
- Do not change `start-project` or `onboard-project` unless a failing behavioral
  test proves their existing candidate-reconciliation contract is insufficient.
- Do not introduce a mandatory singleton lifecycle-state file or persist
  credentials, tokens, hook URLs, or other secrets in delivery checkpoints.

## Evidence ledger

- `AGENTS.md` requires separate authority for elevated effects, canonical plan
  pairs, live tracker maintenance, preservation of unrelated work, and inactive
  candidate staging. Its current live-tracker rule needs a narrow terminal-
  evidence cutoff to prevent release bookkeeping from recursively generating
  more repository work.
- `README.md` presents `plan -> implement -> review -> wrap` as the core
  lifecycle and describes installation as non-committing and non-publishing.
- `.agents/skills/wrap/SKILL.md` at v1.8.0 resolves completion gates and reliably
  prepares a generic read-only commit/push preview. The release's focused live
  case passed current and comparison execution 3/3, and the full offline suite
  passed with 47 registered live cases. Integration, release, and terminal
  cleanup remain unowned after that handoff.
- `.agents/skills/wrap/references/git-handoff.md` explicitly forbids silent
  merge, change-request/release publication, tags, and branch deletion, leaving
  integration, release, and cleanup without an owner.
- `CONTRIBUTING.md` requires integration into `master` after checks and human
  review and says to delete branches when safe, but does not define release
  relevance, release identity, deployment coupling, evidence, or terminal
  cleanup.
- `project-templates/base/CONTRIBUTING.md` already owns generalized workflow
  candidates and uses the confirmed default branch, but lacks the delivery
  variables needed by wrap/release. It is 365 words against a 400-word target
  and 500-word ceiling; root `CONTRIBUTING.md` is 389 words against the same
  limits, so the implementation must consolidate rather than append freely.
- Root `AGENTS.md` is 546 words against a 550-word ceiling and the canonical
  candidate is 598 words against a 600-word ceiling. The terminal-evidence rule
  must replace or consolidate existing tracker language without raising either
  budget.
- `start-project` activates all five baseline candidates only through adapted
  reconciliation; `onboard-project` already identifies `CONTRIBUTING.md` as the
  owner of repository-specific workflow. No new activation mechanism is needed.
- `scripts/stage-project-templates.sh`, installer tests, and documentation tests
  already ensure canonical candidates stage byte-identically while preserving
  active project documents.
- `.github/workflows/ci.yml` runs the offline suite only on pull requests;
  current host evidence reports no branch protection. The repository therefore
  needs an adopted policy gate without claiming platform enforcement.
- v1.8.0 is the latest stable release at
  `edca625bfad486d32071912c41563cbd54cc927e`. GitHub release metadata, the
  lightweight remote tag, PR #5's merge commit, and `origin/master` agree on
  that identity. PR CI passed for exact release head `1b2161d`; host evidence
  still reports no branch protection.
- v1.8.0 proves the complete-unreleased-set rule: it released the pre-existing
  review-table commit and the later generic-wrap fix together, while treating
  tracker-only history as evidence rather than a consumer feature.
- The accepted v1.8.0 plan uses one tracker-only evidence branch/PR after
  publication, declares that evidence PR's merge record the terminal cutoff,
  and leaves subsequent cleanup facts external. Commit `1963b88` is published
  on `origin/feature/release-1.8.0-evidence`, and PR #6 is open, clean,
  mergeable, and has passing `Offline deterministic` CI for that exact head.
  Its normal merge/cutoff and later cleanup remain incomplete and unauthorized.
- The release topic branch still exists on `origin`, providing current evidence
  that cleanup is a distinct unfinished stage rather than an automatic merge
  side effect.
- `docs/solutions/skill-routing-progressive-disclosure.md` is relevant durable
  knowledge: routing-critical trigger and high-level behavior must remain in a
  primary `SKILL.md`, while references own downstream execution detail. Apply
  that boundary to both `wrap` orchestration and `release` triggering.
- Skill catalog, portability, plugin namespace, candidate preservation,
  document-budget, contribution-policy, routing, and live-agent registry tests
  are existing reusable contracts.

## Decisions and constraints

### Ownership boundaries

| Component | Status | Ownership |
|---|---|---|
| `wrap` orchestration | Adopted | Completion gates, full lifecycle preview, authority batching/revalidation, integration coordination, cleanup, and terminal report |
| `release` skill | New adopted distribution capability | Release relevance, complete unreleased set, preparation, publication/triggering, verification, partial-state recovery, and release result |
| Active `CONTRIBUTING.md` | Project-owned | Adopted delivery variables and links to any detailed runbook |
| Canonical contribution candidate | Upstream-managed | Generalized field schema and unresolved/not-applicable semantics |
| Git | Adopted by `wrap` | Local history, refs, branches, and worktrees |
| Hosting provider | Optional/discovered | Change request, host checks, merge, hosted release, and remote-branch operations |
| GitHub adapter | Optional, adopted by this repository | `gh`-based authentication and GitHub operations; never canonical policy |
| Application deployment | Separate/unresolved per project | Owned by an adopted deploy workflow; never implied by repository release |

The canonical skill text stays provider-neutral. Host-specific commands and
authentication live in explicitly routed reference adapters. If no compatible
adapter or CLI exists, the skills stop at a precise manual handoff rather than
installing tools or inventing commands.

### Project delivery-contract fields

The candidate and active document should cover these concepts compactly, with
wording adapted to local evidence rather than literal placeholder activation:

| Field group | Required meaning |
|---|---|
| Integration | Default branch, integration route, branch convention, required local/host checks, review requirement, and merge method |
| Release | Relevance rule, batching/deferral rule, versioning, preparation artifacts, publication mechanism, target identity, and verification |
| Operations | Release/deployment trigger coupling, checkpoint carrier, recovery, terminal evidence location/cutoff, remote-branch cleanup, and local branch/worktree cleanup |

The generalized candidate uses `Unresolved` where project evidence or an owner
decision is required. The root document records this repository's adopted
values. A linked runbook may supply procedural detail but cannot hide the
safety-critical integration, deployment-trigger, release-relevance, or cleanup
decision.

For this repository, implementation should encode the evidence-backed adopted
contract rather than leave generic placeholders:

- `master` is the default integration target; topic work uses the documented
  branch conventions and integrates through a GitHub pull request.
- `bash tests/run.sh`, the pull-request `Offline deterministic` check, and human
  review gate integration. Host enforcement remains explicitly unverified;
  project policy still requires the gate. Recent accepted history establishes a
  merge commit rather than direct default-branch commits as the release path.
- Consumer-visible managed skill, installer, candidate-template, plugin, or
  stable installation/update contract changes are release-relevant. Tests,
  plan/tracker evidence, and internal bookkeeping alone are not. Relevant work
  is not silently deferred; batching or deferral needs an explicit adopted
  decision.
- Releases use SemVer, synchronize the repository's existing version-bearing
  metadata and stable documentation, and publish an immutable Git tag plus
  GitHub release bound to the verified `master` merge SHA. This repository has
  no adopted application-deployment effect from that publication.
- The repository plan/tracker remains current through the adopted terminal
  repository handoff. For this repository's release workflow, one bounded
  tracker-only evidence PR may follow publication; its verified merge record is
  the cutoff. Facts produced only by that merge and later branch/worktree
  cleanup live in the GitHub records and final wrap report and do not create a
  second evidence commit. Projects may instead select the content-bearing
  change as their cutoff. A post-cutoff failure needing repository remediation
  starts a new increment; this is the explicit point where bookkeeping ends.
- The GitHub pull-request record is the durable delivery checkpoint and the
  release record becomes the release checkpoint. Before either exists, remote
  refs plus local task context support conservative read-only reconciliation.
  A fresh context never treats those records as inherited authority.
- Successfully merged/released topic and evidence branches are deleted remotely
  and locally when safe; unique commits, unrelated dirt, partial publication,
  or an unowned worktree require retention with a reason.

### Authority and lifecycle state

Local repository edits in the eventual implementation are R1. The behaviors
being specified can initiate R2 publication, remote deletion, and possibly
production deployment, so the skill contract must preserve exact target,
action, scope, exposure, credential class, recovery, and just-in-time
revalidation. A generic wrap performs no Git or external mutation.

The workflow discovers current state before every effect and records stable
checkpoints so reruns do not duplicate commits, change requests, merges, tags,
releases, or deletions. The active contribution contract selects the checkpoint
carrier. Its provider-neutral minimum is secret-free:

- attempt identifier and owning plan/task or user request when one exists;
- source ref, reviewed head/base identities, target and release boundary;
- intended effects and the historical authority reference, which is evidence
  only and never grants authority to a fresh context;
- observed change-request, integration, tag, release, deployment, and cleanup
  identifiers with `pending`, `complete`, `partial`, `blocked`, or `unknown`
  state;
- cleanup ownership/proof, last verification time, and terminal-evidence cutoff.

Missing, stale, conflicting, or corrupt checkpoint state causes conservative
read-only reconciliation. The workflow may recognize an already completed
effect from exact provider/Git identity, but it may not repeat or continue an
external mutation until current authority is established. Provider commands
must validate refs, repository/host/account identity, and physical local paths;
they must not print or persist credentials, tokens, hook URLs, or secret-bearing
responses.

Rejected pushes, stale review heads/bases, changed checks, existing tag/release
collisions, ambiguous timeouts, and partial publication stop automatic
progression. If the integration target advances, recompute the entire
unreleased change set, release relevance/preparation, checks, automatic
release/deployment coupling, cleanup proof, and affected authority. Never force,
rewrite published history, move a release tag, or delete recovery state after a
partial outcome.

Cleanup proof depends on the adopted integration method. Merge-commit workflows
may use ancestry plus provider merge identity. Squash/rebase workflows require
provider evidence binding the reviewed head to the integrated result and an
explicit content-equivalence or adopted host proof; unique commit objects alone
do not prove unintegrated content. If that evidence is missing or contradictory,
retain the ref/worktree rather than weakening deletion checks.

When accepted uncommitted work begins on the adopted default branch but project
policy requires reviewed topic-branch integration, the lifecycle previews an
exact topic-branch creation before commit. It does not commit directly to the
default branch or move unrelated work implicitly. If the worktree contains
unrelated state that prevents safe branch creation or switching, integration is
blocked until that state has an owner decision.

No dependency is required. Use existing shell/Python tests and the current
agent-evaluation harness.

## File-level scope

Expected implementation paths, refined only when red tests establish a smaller
or necessary adjacent contract:

- `.agents/skills/wrap/SKILL.md`: generalized orchestration, authority matrix,
  lifecycle routing, states, and final report.
- `.agents/skills/wrap/references/git-handoff.md`: retain exact commit/push
  handling while routing onward to integration and cleanup.
- `.agents/skills/wrap/references/git-setup.md`: separate generic Git readiness
  from GitHub-specific setup without weakening existing authentication safety.
- `.agents/skills/wrap/references/integration-and-cleanup.md`: provider-neutral
  integration gates, revalidation, idempotent checkpoints, partial failure, and
  safe branch/worktree cleanup.
- `.agents/skills/wrap/references/delivery-checkpoints.md`: checkpoint schema,
  ownership, freshness, secret exclusion, missing/corrupt recovery, terminal-
  evidence cutoff, and the rule that stored history never grants authority.
- `.agents/skills/wrap/references/github.md`: optional GitHub change-request,
  check, merge, authentication, and remote-cleanup adapter.
- `.agents/skills/release/SKILL.md`: new provider-neutral release contract.
- `.agents/skills/release/references/github.md`: optional GitHub tag/release
  publication, verification, collision, and recovery adapter.
- `CONTRIBUTING.md` and `project-templates/base/CONTRIBUTING.md`: adopted values
  and generalized candidate schema, respectively, kept below current budgets.
- `AGENTS.md` and `project-templates/base/AGENTS.md`: narrow terminal-evidence
  cutoff consolidated into the existing tracker contract so live tracking is
  preserved without recursive bookkeeping commits or budget increases.
- `.agents/skills/deploy/SKILL.md`: only the cross-boundary clarification that
  repository release does not authorize deployment and automatic triggers must
  be known before their source effect.
- `README.md` and `docs/ecosystem-reference.md`: workflow description, new
  skill catalog entry, ownership, and limitation updates.
- `scripts/audit-skill-portability.sh`: recognize the new skill name without
  weakening provider-neutral text checks.
- Targeted deterministic tests, including
  `tests/skill-routing-contract-test.sh`,
  `tests/contribution-policy-consistency-test.sh`, document-budget/staging and
  catalog/portability contracts when their observable assertions need updating.
- `tests/agent-evals/cases.json`, the matching fixtures, and
  `tests/agent-eval-profile-test.sh`: behavior-oriented lifecycle cases and
  registry contracts.
- This plan pair: live execution status and any approved amendments.

Do not edit `.agents/templates/CONTRIBUTING.md`; it is generated/staged output.
Do not update `VERSION`, plugin manifests, or release notes in this increment.

## Implementation sequence

1. Use exact v1.8.0 commit
   `edca625bfad486d32071912c41563cbd54cc927e` as the released comparison
   baseline and retain its verified generic wrap-preview behavior. Record one
   of two exact implementation bases before the first edit:
   - preferred, if PR #6 has merged: fetch and use its verified
     `origin/master` merge SHA; `1963b88` is permitted ancestry but remains
     excluded from this increment's diff against that selected base; or
   - while PR #6 remains unmerged: branch from exact `edca625`, preserve the
     remote evidence branch and open PR unchanged, and exclude `1963b88` from
     both ancestry and implementation diff.
   Never start from stale local `master` (`6c4b84d`), treat evidence ancestry as
   implementation scope, or silently mix the release-evidence change into the
   new commit groups. Revalidate because PR #6 may advance independently.
2. Add failing deterministic and consuming-agent cases for the generalized
   delivery contract before changing skill behavior. Cover a non-GitHub/default
   `main` project, exact effect boundaries, release-required work with earlier
   unreleased commits, target drift, an automatic production trigger, a partial
   publication, a fresh-context resume, terminal-evidence cutoff, merge/squash/
   rebase cleanup proofs, and unsafe cleanup.
3. Consolidate the canonical contribution candidate into a compact
   integration/release/cleanup contract and adopt this repository's evidence-
   backed values in root `CONTRIBUTING.md`. Strengthen consistency tests so
   candidates require explicit unresolved/not-applicable semantics while active
   documents retain project ownership. Keep both documents below 500 words and
   preferably at or below the 400-word targets. Add the narrow terminal-evidence
   cutoff by consolidating the existing root and candidate `AGENTS.md` tracker
   wording, keep their current 550/600-word ceilings, and prove that it cannot
   waive normal live tracking or pre-handoff updates.
4. Implement the provider-neutral `release` skill and its GitHub adapter. Keep
   trigger boundaries explicit, compute the full unreleased set, separate
   preparation from post-integration publication, define terminal/partial
   states, preserve authority, and support safe idempotent resume.
5. Extend `wrap` to consume the active contribution contract, orchestrate the
   complete lifecycle, route release decisions to `release`, surface automatic
   release/deployment coupling, handle accepted work initially present on the
   default branch, maintain the provider-neutral checkpoint contract, and own
   post-terminal cleanup with merge-method-appropriate proof. Refactor GitHub-
   only setup and operations into the optional adapter while preserving current
   credential and storage protections.
6. Add the narrow `deploy` boundary clarification and update public workflow,
   catalog, portability-name, and ownership documentation. Confirm installation
   still discovers the new physical skill automatically and does not mutate
   active project documents.
7. Run focused structural and deterministic checks, then the selected live
   agent evaluations at their registered repeated-run thresholds. Inspect
   failures as contract evidence and revise instructions or cases without
   tuning to fixture wording.
8. Run whitespace validation and the full offline suite. Review the complete
   scoped diff for architecture, authority/security, documentation ownership,
   provider neutrality, and preservation. Run an independent adversarial pass
   over partial-state, automatic-deployment, stale-review, duplicate-release,
   and cleanup scenarios; record and resolve every retained finding.

## Test and evidence map

| Observable behavior or failure | Evidence |
|---|---|
| New skill is structurally valid and cataloged | `quick_validate.py`, `tests/skill-catalog-test.sh`, plugin-channel contract |
| Canonical text remains provider-neutral | portability audit plus a non-GitHub/default-`main` agent fixture |
| Contribution variables are explicit but project-owned | contribution-policy, document-budget, template-layout, staging, documentation-interface, and project-document-preservation tests |
| Generic wrap previews the full lifecycle and performs no effect | updated generic-preview evaluation with zero mutations |
| Exact commit routing avoids integration/provider loading; exact integration authority does not imply release or cleanup authority | exact-commit and exact-integration routing evaluations |
| Release considers earlier unreleased integrated work | authorized-success evaluation asserts the exact earlier-plus-current set |
| Target drift requires complete release, trigger, cleanup-proof, and affected-authority recomputation | preview evaluation asserts the full recomputation decision |
| Unresolved release preparation blocks integration | unresolved-policy evaluation |
| Merge-triggered release is not duplicated | automatic-release evaluation verifies observation rather than duplicate publication |
| Merge/release-triggered production effect is surfaced | preview evaluation requires separate deployment authority |
| Failed/stale checks prevent integration and release | stale-integration-gates evaluation |
| Existing tag/release collisions and ambiguous reruns are safe | GitHub-publication-recovery evaluation, including an exact remaining-effect assertion and prohibited-tag-retry counterexample |
| Fresh-context partial resume avoids duplicates without inheriting authority | resume evaluation spans completed push/change request/integration/tag plus unknown hosted release |
| Partial publication is reported and cleanup is retained | resume and GitHub-publication-recovery evaluations |
| Authorized integration, immutable release, and terminal cleanup succeed | authorized-success evaluation |
| Safe non-release path reaches cleanup | non-release-cleanup evaluation with an evidence-backed reason |
| Merge/squash/rebase cleanup uses valid method-specific proof | cleanup evaluation with matching, mismatched, and missing provider/content evidence |
| Unique unintegrated content, dirty unrelated work, or unowned worktree blocks deletion | cleanup boundary evaluation |
| A selected terminal handoff prevents recursive evidence commits; later merge and cleanup facts stay external | terminal-cutoff evaluation |
| Repository release does not authorize deployment | routing/source contract and automatic-trigger evaluation |
| A requested release without publication authority remains required rather than blocked | requested-release-no-authority evaluation |
| No regression across distribution | `git diff --check` and `bash tests/run.sh` |

Expected focused commands include:

```bash
python3 .agents/skills/skill-creator/scripts/quick_validate.py .agents/skills/release
bash scripts/audit-skill-portability.sh .agents/skills
bash tests/skill-catalog-test.sh
bash tests/skill-routing-contract-test.sh
bash tests/contribution-policy-consistency-test.sh
bash tests/base-document-budget-test.sh
bash tests/project-template-layout-test.sh
bash tests/project-docs-preservation-test.sh
bash tests/agent-eval-profile-test.sh
git diff --check
bash tests/run.sh
```

Run each new or materially changed live case through
`tests/run-agent-evals.sh` with its registry threshold, current subject digest,
and current-pass/release-qualified evidence checks where supported. Do not
claim live behavior passed if the executor, network, time, or budget prevents
the registered runs.

## Failure modes and recovery

| Failure mode | Required handling |
|---|---|
| Released v1.8.0 wrap-preview behavior regresses | Preserve its routing-critical main-skill contract and focused live case; treat the release tag as the comparison baseline |
| PR #6 merges before implementation | Fetch its exact merge SHA from `origin/master`, select that SHA as base, and exclude inherited `1963b88` from the implementation diff rather than pretending it is absent from ancestry |
| PR #6 remains open when implementation begins | Branch from exact `edca625`, preserve the remote branch and PR, and exclude `1963b88` from ancestry and diff; later target drift triggers full recomputation |
| Local checkout remains on the v1.8.0 evidence branch | Do not implement in place; select one of the two bases above and leave the evidence branch/PR untouched |
| Accepted work starts dirty on the protected/default integration branch | Preview creation of an exact topic branch; preserve unrelated state and do not commit directly to the default branch |
| Active contribution variables conflict with host evidence | Preserve the documented policy, report the mismatch, and block only the affected effect until resolved |
| Checkpoint is absent, stale, conflicting, or corrupt | Reconcile Git/provider state read-only, inherit no authority, repeat no ambiguous effect, and preserve cleanup targets |
| Release relevance or required preparation is unresolved | Do not integrate content that may need release-artifact changes; request the missing project decision |
| Change request head/base or checks become stale | Revalidate; do not merge, rerun destructively, or claim prior evidence |
| Integration target advances after preview | Recompute the full unreleased set, artifacts, checks, triggers, cleanup proof, and affected authority before continuing |
| Integration triggers an undisclosed deployment | Treat the effect as unresolved R2 and stop before the trigger |
| Tag/release already exists with a different identity | Stop; never move or overwrite it; propose a corrective version or owner decision |
| External command times out after possible success | Inspect remote state before retrying; record a partial checkpoint |
| Release fails after integration | Report partial integration/release state, retain cleanup targets, and provide the exact resume/recovery action |
| Post-cutoff terminal facts occur | Record them only in the adopted external evidence and final report; remediation becomes a new increment, never a tracker-only recursion |
| Squash/rebase leaves unique commit objects | Use provider binding plus content/adopted-host proof; retain when proof is unavailable rather than requiring ancestry or force-deleting |
| Branch has unique unintegrated content or worktree has unrelated dirt | Preserve it and report cleanup blocked; never force-delete or discard |
| Provider adapter unavailable | Complete provider-neutral preparation and give a precise manual handoff; do not install a new tool without authority |
| Candidate or root policy text exceeds document budget | Consolidate duplicated guidance or route detail to skill references; do not raise the CONTRIBUTING or AGENTS ceilings merely to fit prose |
| Behavioral eval is flaky or fails | Inspect the decision trace, distinguish skill ambiguity from fixture error, revise the contract, and rerun the registered threshold |

Recovery for implementation is an ordinary revert of the scoped R1 files. No
external delivery effect is part of implementation, so there is no tag,
release, deployment, or remote-branch state to unwind.

## Completion criteria

Implementation is complete only when its branch uses one recorded verified base
from step 1 and excludes `1963b88` from this increment's scope and diff; inherited
ancestry is explicitly permitted when the selected base is PR #6's verified
`origin/master` merge SHA. Every accepted path must be accounted for, the
generalized skill and project contract must satisfy the acceptance criteria,
targeted and full offline checks must pass, required live cases must meet their
thresholds or be explicitly reported as missing evidence, architecture and
primary plan/code review must have no unresolved findings, the independent
adversarial pass must have no blocking scenario, and the live tracker must
reflect the actual verified state. No Git or publication effect is part of this
completion definition.

## Amendment — 2026-09-23: rebase planning evidence to v1.8.0

The owner requested comparison with the latest origin release. Fetch and host
inspection verified v1.8.0 at
`edca625bfad486d32071912c41563cbd54cc927e`, with PR #5 and its successful
`Offline deterministic` check bound to release head
`1b2161db3dd2f1030d817101505c694a6abfd374`. The release incorporates and
verifies the formerly overlapping generic wrap-preview increment, so that
prerequisite is complete and becomes the protected baseline rather than pending
work.

At amendment review, the checkout was `feature/release-1.8.0-evidence` at
`1963b8824622f8b7ad4b8d822134f044d4958f80`, one commit ahead of
`origin/master`. That commit updates only the v1.8.0 plan pair and now also
exists at `origin/feature/release-1.8.0-evidence`. PR #6 targets `master`, is
open/clean/mergeable, and its exact-head CI passed; no merge commit exists.
Normal merge/cutoff and later cleanup remain pending separate authority, while
branch push and PR publication are completed historical effects. This plan
adopts that evidence PR as this repository's project-specific terminal cutoff
while keeping the generalized cutoff configurable in active `CONTRIBUTING.md`.

The new compounded solution requires the orchestration decision to remain in
primary skill instructions, and the registered live-evaluation baseline is now
47 cases. No implementation path is removed, but initial sequencing, release
evidence, terminal-cutoff wording, and regression baselines are updated. The
remaining v1.8.0 evidence PR merge/cutoff and cleanup effects remain outside
this plan and unauthorized here; branch push, PR #6 publication, and its CI are
completed historical effects performed under their prior authority.

Implementation began after revalidating that PR #6 was still open and clean.
The selected implementation base is exact v1.8.0 commit
`edca625bfad486d32071912c41563cbd54cc927e` on
`feature/generalized-wrap-release-lifecycle`; `1963b88` is absent from both its
ancestry and implementation diff, and the evidence branch/PR remains untouched.

Implementation now includes the provider-neutral `release` skill, expanded
`wrap` orchestration and checkpoint/integration/GitHub references, adopted and
canonical delivery contracts, terminal-cutoff governance, deployment boundary,
catalog/portability updates, and five new lifecycle evaluation cases. Focused
structural, routing, policy, budget, staging, preservation, portability, plugin,
documentation, and 52-case registry checks pass. Live evaluation, the full
offline suite, and final scoped reviews remain pending.

Two bound live-evaluation attempts produced no usable behavioral verdict: the
first allowed 2,000 rollout tokens per execution and the second 8,192; both
exhausted while agents performed exploratory context discovery. Following the
repository's v1.8.0 lean-case precedent, the five prompts now require one direct
read of only their exact supplied contexts and forbid recursive discovery. The
next attempt must bind a fresh subject digest and evaluate that narrower setup;
the failed summaries remain isolated under `/tmp` and are not claimed as test
failures or passing evidence.

The lean attempt completed but still exhausted five of thirty executions at
12,000 rollout tokens. Its completed outputs exposed an omitted default-branch
topic-creation instruction and ambiguity between an overall `partial` release
and an individual `unknown` effect; both contracts and their canonical prompts
were corrected. Other mismatches were lexical rather than unsafe decisions.
Under the three-attempt stop rule, no fourth live run is permitted in this
increment. T10 records unavailable threshold evidence with residual behavioral
risk; deterministic coverage and review continue.

Scoped architecture and security review retained five findings before final
review completion: separately authorize missing-repository initialization
(AR-001); make terminal merge evidence external without recursive tracker work
(AR-002); treat checkpoint/provider free text as hostile data (SR-001); gate
accepted publication content for secrets without disclosing values (SR-002);
and define the content-bearing cutoff when the optional evidence PR is omitted
(SR-003). All are within the accepted authority, checkpoint, terminal-evidence,
and test scope and must be corrected and verified before T12 can close.

The focused re-reviews confirmed AR-001, AR-002, SR-001, SR-002, and SR-003
resolved with no new blocking finding. Their targeted lifecycle, routing,
registry, policy, budget, preservation, portability, plugin, and whitespace
checks pass. The registry now contains 56 cases; live execution remains the
previously recorded unavailable evidence rather than a claimed pass.

The final clean `bash tests/run.sh` completed successfully with the 56-case
registry and no offline deterministic regression; `git diff --check` and the
new-path trailing-whitespace scan are also clean. Final origin revalidation
still places `origin/master` and `v1.8.0` at `edca625`, with PR #6 open,
mergeable, clean, and green at `1963b88`, so the selected implementation base
has not drifted. The independent implementation adversarial review remains the
last review gate before final path accounting and handoff.

The independent implementation adversarial review returned NO-GO with one
confirmed P1 finding, ADV-FINAL-001: exact commit, push, change-request,
integration, drift, cleanup, and resume paths could invoke `wrap` without the
detailed references that define their safety contract because reference routing
was stated only for a generic wrap. This is a bounded routing/test correction;
it must be implemented test-first and independently re-reviewed before T12 can
close.

ADV-FINAL-001 now has a red-to-green deterministic routing contract in
`tests/skill-routing-contract-test.sh`. The primary `wrap` skill routes every
commit/push preview or execution, change-request/integration/drift/cleanup path,
external-effect/resume path, and confirmed-provider operation to its required
detailed references. Two primary-skill-only behavioral cases cover exact commit
and exact integration routing, bringing the registry to 58 cases. Focused skill,
routing, lifecycle, registry, and whitespace checks pass; the full suite and
independent finding re-review remain pending.

After the ADV-FINAL-001 correction, the clean full `bash tests/run.sh` suite
passes again with `registered-live-cases=58`, and `git diff --check` remains
clean. This supersedes the earlier 56-case clean-suite result. The only pending
gate is the focused independent re-review of that finding, followed by final
path accounting and the no-effects handoff.

The focused independent re-review confirms ADV-FINAL-001 resolved, finds no new
blocker, and returns GO. Final path accounting matches the declared scope:
skill and reference contracts; active and canonical project documentation;
catalog and portability surfaces; deterministic and behavior-evaluation
contracts plus eleven lifecycle fixture groups; and this plan pair. No
unrelated path is present. `HEAD` remains exact v1.8.0 `edca625`; no commit,
push, integration, release, deployment, branch/worktree deletion, or other
external mutation was performed in this implementation increment.

## Amendment — 2026-09-23: resolve final scoped-review findings

The owner authorized fixing all four findings from the final scoped review.
This adds bounded release-state clarification and test work within the accepted
lifecycle scope: make lifecycle disposition independent of authority readiness;
replace answer-bearing evaluation prompts with scenario/schema prompts; add an
authorized earlier-plus-current release path; cover stale integration gates,
GitHub publication identity/collision/resume, a terminal non-release cleanup
path, and an unowned-worktree cleanup blocker; and reconcile the test map with
actual assertions. No Git, provider, release, deployment, or cleanup effect is
authorized. REVIEW-001 through REVIEW-004 remain unchecked until their focused,
full-suite, negative-control, and applicable live evidence is verified.

### Review-fix implementation and evidence — 2026-09-23

All source and deterministic corrections from REVIEW-001 through REVIEW-004 and
the subsequent clean-context re-review are implemented. The registry now has 63
cases, including authorized earlier-plus-current terminal delivery, stale
integration, exact GitHub publication recovery, safe non-release cleanup, and a
direct requested-release-without-publication-authority case. Exact commit and
integration prompts no longer disclose their expected routing arrays. GitHub
recovery now grades `hosted release publication` by exact equality and includes
a deterministic counterexample proving that retrying the completed tag effect
fails. The test map was narrowed where a prior row claimed more than its
assertions observed.

`bash tests/run.sh` passes on this final 63-case state with
`offline-deterministic=passed`; focused lifecycle, routing, registry, skill
validation, and `git diff --check` also pass. Two fresh read-only review routes
completed. The evaluation pass found the overclaimed test-map rows and weak
remaining-effect assertion, both corrected here. The architecture pass confirmed
the source-level disposition/authority separation and found the missing direct
requested-but-unauthorized release case, which is now present. A third
adversarial route stalled after extensive inspection and was bounded as
unavailable rather than treated as corroboration.

Live evidence remains intentionally unresolved. Three bounded post-review rounds
did not produce a current-subject 3/3 result: the first was dominated by executor
exhaustion; later rounds exposed output-schema ambiguity and then passed GitHub
recovery while other cases missed their thresholds. Those prompts and assertions
were corrected afterward, so the retained summaries are valid historical
diagnostics but are not evidence for the current digest. Per the repository's
three-attempt stop rule, no fourth live round was started. REVIEW-001 through
REVIEW-004 therefore remain unchecked pending an owner-approved follow-up
increment for current-digest live evaluation; no source defect identified by the
review remains knowingly open.

## Amendment — 2026-09-23: owner-approved live-evaluation follow-up

The owner explicitly approved one additional attempt after the bounded-attempt
stop. This is a fresh verification increment, not permission for Git or provider
effects. It will bind the current source digest and run three current plus three
v1.8.0 comparison trials for the six cases that directly close REVIEW-001
through REVIEW-004: authorized terminal success, exact commit routing, exact
integration routing, GitHub publication recovery, generic preview authority,
and requested release without publication authority. Evaluated source remains
unchanged from prepare-only binding through summary verification. Any failure is
reported as evidence; it does not silently authorize another retry or tuning.

The approved follow-up completed 36/36 trials under bound digest
`c84c8d3aa0073ef0466477833fb4f048c2273622858f9457eed6448995b10b21`.
Current behavior passed 3/3 for exact integration routing and GitHub recovery,
2/3 for authorized terminal success (one executor failure) and exact commit
routing, and 0/3 for generic preview and requested release without publication
authority. The comparison failed 3/3 for exact integration, generic preview,
and requested release without authority, while the extraction-oriented
authorized-success and GitHub-recovery cases also passed on v1.8.0.

Inspection showed that every completed current trial made the intended lifecycle
decision. The failures exposed evaluator contracts: the shared result schema
cannot encode the nested preview object and therefore forced JSON into a string;
the commit route accepted only a filename token rather than the semantic route;
and the next tag effect required one exact phrase despite all three answers
identifying the correct immutable tag action. Those cases now use supported,
semantic result shapes: a set-equal category array and boolean route/effect
decisions. Focused deterministic tests pass after the corrections. Because the
approval covered one additional attempt, no subsequent live run was inferred;
the corrected current digest remains live-unverified.

## Amendment — 2026-09-23: post-correction live verification

The owner separately approved another live run after reviewing T14's outcome.
This authorizes one evaluation attempt only, against the post-T14 semantic
result contracts. It repeats the same six review-closing cases with three
current and three v1.8.0 comparison trials each. The source digest is frozen
from prepare-only through verified summary, and the attempt authorizes no Git,
provider, release, deployment, cleanup, or additional source mutation.

The post-correction run completed all 36 trials under digest
`aa8b751cdf37e80655494a5b0bf32222fb2f405e2ae2046ed58472d304388c2b`,
and its raw evidence verifies. Current behavior passed 3/3 for authorized
terminal success, exact commit routing, exact integration routing, and requested
release without publication authority. GitHub recovery passed two completed
trials; its third executor exhausted the shared rollout budget after correctly
loading context but before producing a result. Generic preview passed 2/3; the
third completed result made every intended decision but used
`prepare_and_publish` instead of the canonical `required` token. v1.8.0 failed
0/3 for exact integration, GitHub recovery, and requested release without
authority, while authorized success, exact commit, and the now-semantic preview
also remained solvable from scenario facts.

The preview case duplicated canonical-token coverage already proven by the
dedicated requested-release case, so it now asks the distinct semantic question
whether a release is required. That test correction is deterministic-green but
postdates the bound live digest. REVIEW-002 is closed by 3/3 current routing plus
the failing v1.8.0 integration comparison. REVIEW-003 is closed by its exact
counterexample, T14's 3/3 pass, T15's two additional completed passes, and the
unchanged case binding. REVIEW-001 remains open because its authorized-success
comparison is not a failing control; REVIEW-004 remains open because the
corrected preview assertion postdates live evidence.

## Amendment — 2026-09-23: close remaining evidence gaps

The owner authorized proceeding with the shortest path to close REVIEW-001 and
REVIEW-004. The authorized-success fixture will expose a verified release
boundary and chronological candidate changes rather than state the expected
earlier-plus-current set. A deterministic latest-only counterexample must fail
the production grader. After focused tests pass, one narrow live run will cover
only authorized success and the corrected generic preview, with three current
and three v1.8.0 comparison trials each. This does not authorize Git, provider,
release, deployment, cleanup, or unrelated source effects.

The bound run at subject digest `6adbcdeb…04cbd` completed all 12 executions and
its summary/raw evidence verifies. Authorized success passed 3/3 for both the
current and v1.8.0 subjects, while the real grader's deterministic latest-only
counterexample fails as required; REVIEW-001 is closed. Generic preview passed
1/3 current and 3/3 comparison. Every current run correctly reported release
necessity, the full effect-category set, full drift recomputation, and absent
integration/deployment authority, and every prose summary described a
preview-only generic request. Two runs nevertheless placed `required` in d1
because “next lifecycle disposition” could denote the separate release
disposition. A focused failing test reproduced that response-contract ambiguity;
the prompt now assigns d1 an explicit `preview_only`/`mutation_authorized` enum
and passes deterministic verification. The one-run authorization was honored,
so REVIEW-004 remains open pending a separately approved current-only threshold
run of that correction.

After that deterministic correction, the final `bash tests/run.sh` suite passes
with `offline-deterministic=passed` and 63 registered live cases. The release
skill passes structural validation and `git diff --check` is clean. A standalone
whole-tree portability diagnostic still reports the repository's pre-existing
provider-specific bundled `skill-creator` helper scripts; the canonical
portability audit contract inside the full suite passes, and this increment did
not modify those helpers.

## Amendment — 2026-09-23: final-review corrections

The previously authorized “fix all” instruction covers six final-review defects
within the accepted delivery-lifecycle scope. One P1 requires integration to
account for provider-managed automatic branch deletion as a destructive trigger
that cannot bypass cleanup authority or terminal release safety. Five P2s
separate release disposition from effect identity in checkpoints, make the
active checkpoint owner/location/update authority explicit, bound provider CLI
deadlines, reject secret sentinel disclosure across retained execution output,
and replace two permissive substring graders with exact canonical decisions.
Each correction is test-first and receives focused plus full deterministic
verification. Behavioral fixtures may be added or extended for the newly
identified automatic-deletion and timeout paths. This amendment authorizes no
live evaluation, Git/provider mutation, release, deployment, or cleanup.

The six corrections are implemented. Secret output is now checked across the
structured result, parsed and raw retained events, and stderr without echoing
the marker; four leaking controls fail and the compliant control passes. Preview authority and
the automatic-release cutoff use exact typed decisions with contradictory
controls. Checkpoint lifecycle state, active/template ownership, bounded
provider timeouts, and provider-managed branch deletion have deterministic
contracts plus registered behavioral scenarios. The full suite passes with
`offline-deterministic=passed` and 66 registered live cases; document budgets
and `git diff --check` pass. TEST-001 is closed. The remaining five review
findings and REVIEW-004 await the separately authorized seven-case T17 live
threshold; no live run was inferred from this amendment.

Independent re-review of the corrected final tree found no residual source or
deterministic defect at confidence 75 or higher. The final stable-tree
`bash tests/run.sh` run passes with `offline-deterministic=passed` and 66
registered live cases; focused lifecycle/profile checks, structural validation,
document budgets, and `git diff --check` pass. The remaining tracker items are
evidence gates, not known implementation defects: T17 must exercise seven cases
at their registered current thresholds before REVIEW-004 and the five
behaviorally gated final-review findings can close.

## Amendment — 2026-09-23: approved T17 live threshold

The owner approved the exact remaining live evaluation: `preview-boundary`,
`automatic-release-cutoff`, `resume-boundary`, `secret-publication`,
`automatic-branch-deletion`, `provider-timeout`, and
`terminal-release-states`, with three current and three v1.8.0 comparison
trials per case using `gpt-5.6-sol`, four workers, a 300-second timeout, and a
1,260,000 planned-token ceiling. The runner must prepare and report its bound
subject/executor digests before execution, source must remain unchanged through
summary/raw-evidence verification, and no Git/provider/release/deployment or
cleanup effect is authorized.

The bound run at subject digest `656ebc64…effc3b` completed all 42 executions;
its summary and raw evidence verify. Preview boundary, automatic release cutoff,
secret publication, automatic branch deletion, provider timeout, and terminal
release states each passed 3/3 current and 3/3 v1.8.0 comparison. This closes
REVIEW-004, SEC-001, ARCH-OPS-001, ARCH-OPS-003, and TEST-002. Resume boundary
passed 0/3 in both configurations. All three current summaries correctly
identified PR 84 comment 501 as authoritative, refused repeated publication and
mutation authority, and retained cleanup while publication/proof remained
incomplete. The d5 prompt nevertheless asked whether remote state “can be
reconciled” while forbidding Git/provider access, so all three reasonably
answered false; d6 used a lexical cleanup disposition and two answers used the
equivalent `retained`; one run also substituted `in_progress` for canonical
`partial` while describing the same unknown publication state. This is an
evaluation-contract defect, not evidence of a checkpoint-ownership source
failure. T19 narrows those three fields to independent semantic booleans and
requires deterministic negative controls. The approved live run is exhausted;
no retry is inferred.

T19 reproduced the resume failure with deterministic contradictory controls and
narrowed its three ambiguous fields to booleans: overall partial/individual
unknown, required read-only reconciliation as the next action, and required
topic-branch retention. Focused lifecycle/profile checks and the full offline
suite pass with 66 registered cases. T20 is the only remaining evidence gate: a
separately approved `resume-boundary` run with three current and three v1.8.0
comparison trials, `gpt-5.6-sol`, four workers, a 300-second timeout, and a
180,000 planned-token ceiling. No retry is authorized yet.

The owner subsequently approved that exact T20 run. This approval covers only
the six read-only agent executions and retained evidence outside the repository;
it authorizes no Git/provider/release/deployment or cleanup effect. Source must
remain unchanged from prepare-only binding through raw-evidence verification.

T20 bound subject digest `7134d899…2f7c9`, completed all six executions, and
passed `resume-boundary` 3/3 current plus 3/3 v1.8.0 comparison. The retained
summary and raw evidence verify. ARCH-OPS-002 and every retained final-review
finding are now closed. The latest stable-tree full offline suite remains green
with 66 registered live cases. The evidence is intentionally not
release-qualified because the evaluated implementation is still uncommitted;
that does not affect the requested behavior threshold and grants no delivery
authority.

## Plan review

Scope mode was selective expansion: the accepted generalized lifecycle remains
unchanged, while `AGENTS.md`, a checkpoint reference, and their tests entered
scope only because terminal evidence and fresh-context recovery cannot be made
reliable without them. Planning writes are R1. Eventual implementation is R1,
but its skill contracts govern R2 publication, remote deletion, credentials,
and possible production triggers.

Primary review:

```text
REVIEW VERDICT
Strategy:      PASS
Architecture:  PASS
Design:        N/A — no user interface changes
Security/Ops:  PASS
Testing:       PASS
Overall:       GO
Blocking issues: None
```

Architecture ownership is explicit between `wrap`, `release`, active project
policy, optional provider adapters, and separate deployment. Security/operations
coverage binds credentials and external effects to exact targets, forbids
secret-bearing checkpoints, prevents inherited authority, and retains recovery
state after ambiguity or partial success. The test map exercises every changed
observable boundary rather than relying on source-text checks alone.

A clean-context independent adversarial review initially returned NO-GO with
four findings: recursive terminal evidence (ADV-001), missing durable checkpoint
provenance (ADV-002), merge-only cleanup assumptions (ADV-003), and incomplete
recomputation after base drift (ADV-004). The plan and tracker now include the
terminal cutoff, checkpoint schema/ownership and recovery, merge-method-specific
cleanup proof, full drift recomputation, and corresponding tests. Independent
re-review found all four materially resolved, no new blocking scenario, and
returned GO. The ADV tracker items remain open until implementation and tests
verify the planned controls.

The first independent amendment review returned NO-GO with two findings:
ADV-V180-001 found ambiguity between evidence ancestry and implementation diff,
and ADV-V180-002 found that the evidence branch/PR publication state had
advanced during review. The plan now defines both permitted implementation
bases explicitly and records remote branch publication plus open PR #6 as
complete historical effects, leaving only merge/cutoff and cleanup pending. A
fresh context-independent re-review confirmed both findings resolved, found no
new blocker, and returned GO. The amendment findings are closed at planning
time; the implementation controls they introduced remain covered by T3A and the
applicable lifecycle verification tasks.

## Amendment — 2026-09-24: prepare the v1.9.0 terminal handoff

The owner approved the exact v1.8.0 completion batch. PR #6 merged through the
adopted merge-commit method as
`1abcf898385aead22aae0085e3b9a6033931a35e`; the provider record and local
ancestry verify both reviewed heads. The owned local and remote
`feature/release-1.8.0` and `feature/release-1.8.0-evidence` branches were then
deleted with no unique content or active worktree. The immutable `v1.8.0` tag
and GitHub release remain bound to
`edca625bfad486d32071912c41563cbd54cc927e`.

Recomputation against the advanced `origin/master` found that PR #6 contributes
only the prior release plan pair, which the adopted contract excludes from
release relevance. The generalized lifecycle implementation remains the whole
consumer-visible unreleased set, so the next SemVer is `1.9.0`. Preparation
synchronizes `VERSION`, both plugin manifests, stable-install documentation,
the release index, and adoption-aware release notes in the reviewed change.

The selected terminal repository handoff is the content-bearing v1.9.0 pull
request; no evidence-only pull request follows it. The plan pair remains current
through that handoff's publication, and a dedicated secret-free GitHub pull-
request comment owns the durable delivery checkpoint. The later verified merge
identity, tag/release identities, and cleanup evidence stay in the provider
record and final report. Current authority covers release preparation, the
disclosed commits, public branch push, pull-request publication, checkpoint
creation/update, the final plan-only handoff commit, and exact-head CI
observation. It stops before integration, tag or GitHub release publication,
deployment, and current-branch cleanup.
