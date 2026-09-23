# Generalized wrap, integration, release, and cleanup lifecycle

- [x] T1 — Inspect repository policy, wrap/release evidence, template ownership,
  distribution contracts, current release history, and overlapping dirty work.
- [x] T2 — Review this plan for strategy, architecture, authority and operations,
  testing, and independent adversarial failure paths; incorporate every retained
  finding and record the final verdict.
- [x] T2A — Re-review the amended plan against exact v1.8.0 origin/tag/PR/CI
  evidence and the still-open local evidence branch; incorporate retained
  findings and record the updated verdict.
- [x] ADV-V180-001 — Verify both allowed implementation bases distinguish
  inherited evidence ancestry from this increment's diff and forbid stale local
  `master` or in-place evidence-branch implementation.
- [x] ADV-V180-002 — Record and verify the current partial checkpoint: evidence
  branch push and PR #6 publication/CI are complete, while merge/cutoff and
  cleanup remain pending separate authority.
- [x] ADV-001 — Define and verify a terminal-evidence cutoff that ends repository
  bookkeeping after the project-selected terminal handoff without weakening
  normal live tracking or creating a second evidence integration/cleanup loop.
- [x] ADV-002 — Define and verify the provider-neutral, secret-free durable
  checkpoint/provenance contract, fresh-context authority boundary, and
  missing/corrupt recovery behavior.
- [x] ADV-003 — Define and test merge-method-specific cleanup proof for merge,
  squash, and rebase integration without confusing unique commit objects with
  unique unintegrated content.
- [x] ADV-004 — Require and test full release-set, artifact, trigger, check,
  cleanup-proof, and authority recomputation after target/base drift.
- [x] T3 — Verify v1.8.0 contains the completed generic wrap-preview increment,
  its focused 3/3 live evidence, and its structural/offline regression baseline.
- [x] T3A — Before implementation, complete the separate v1.8.0 evidence cutoff
  and use its verified `origin/master` merge SHA as base, or branch from exact
  v1.8.0 commit `edca625` while PR #6 remains open; preserve `1963b88` and
  exclude its evidence change from the implementation diff in either case.
- [x] T4 — Add red deterministic and consuming-agent cases for generalized
  delivery discovery, complete previews, authority boundaries, prior unreleased
  work and target drift, automatic release/deployment, default-branch topic
  creation, durable checkpoints, terminal evidence, partial publication,
  fresh-context resume, and merge-method-aware safe cleanup.
- [x] T5 — Amend the canonical and active contribution contracts with explicit
  integration, release, deployment-coupling, checkpoint, terminal-evidence,
  recovery, and cleanup values; add the narrow AGENTS terminal cutoff while
  preserving project ownership and the existing CONTRIBUTING/AGENTS budgets.
- [x] T6 — Create and structurally validate the provider-neutral `release` skill
  and optional GitHub release adapter.
- [x] T7 — Extend `wrap` with provider-neutral integration/release orchestration,
  lifecycle reporting, partial-state resume, and terminal safe cleanup; move
  GitHub-specific behavior behind its adapter without weakening auth controls.
- [x] T8 — Clarify the separate deployment authority boundary and update the
  public workflow, skill catalog, portability name set, and ownership guidance.
- [x] T9 — Pass focused structural, portability, contribution-policy, template,
  catalog, routing, and agent-evaluation registry checks.
- [x] T10 — Pass the new and changed live agent cases at their registered
  repeated-run thresholds, or record the exact unavailable evidence without
  claiming behavioral verification.
- [x] AR-001 — Make missing-repository initialization an exact separately
  authorized Git effect; verify generic wrap, commit-only, push-only, and
  read-only requests cannot create `.git` silently.
- [x] AR-002 — Keep the tracker current through preparation/publication of the
  selected terminal handoff while recording its later verified merge identity
  externally, with no recursive evidence change.
- [x] SR-001 — Treat checkpoint and provider free text as untrusted data,
  allow-list fields/status values, ignore embedded instructions/authority, and
  use validated refs/IDs as argument-safe data.
- [x] SR-002 — Add a redaction-safe secret/sensitive-artifact gate for every
  accepted commit/release payload, blocking publication without printing values.
- [x] SR-003 — Select the terminal cutoff before delivery and make the verified
  content-bearing merge the cutoff when no optional evidence PR is selected.
- [x] ADV-FINAL-001 — Load the detailed Git handoff, integration/cleanup,
  checkpoint, and confirmed-provider references for their exact-effect routes,
  not only for a generic wrap; verify primary-skill-only commit and integration
  routing.
- [x] T11 — Pass `git diff --check` and the full offline `bash tests/run.sh`
  suite with no unexplained regression.
- [x] T12 — Complete scoped architecture, authority/security, provider-neutrality,
  documentation-ownership, and independent adversarial review; resolve and
  verify every retained finding.
- [x] T13 — Account for every changed path, update this plan pair to actual
  status, and hand off without committing, pushing, merging, releasing,
  deploying, or deleting branches/worktrees unless separately authorized.
- [x] REVIEW-001 (P1) — In `tests/agent-evals/cases.json`, add asserted
  behavioral coverage for the complete earlier-plus-current unreleased set and
  the authorized integration → immutable release → terminal cleanup path; map
  every retained lifecycle test-map promise to a result/state assertion and
  verify the cases at 3/3 plus a failing negative control and `bash tests/run.sh`.
  The chronology-only fixture passed 3/3 at bound digest
  `6adbcdeb…04cbd`, and the production grader rejects a latest-only release-set
  counterexample. The test map matches its assertions; final full-suite
  verification is recorded below.
- [x] REVIEW-002 (P2) — In the exact commit/integration lifecycle prompts,
  remove canonical routing answers that can be copied without using the skill;
  keep expected values in registry assertions and verify current-versus-
  route-stripped subjects at the registered threshold.
  The answer-bearing arrays are removed, deterministic leakage checks pass, both
  current routes pass 3/3, and the v1.8.0 integration comparison fails 0/3.
- [x] REVIEW-003 (P2) — Cover
  `.agents/skills/release/references/github.md` in deterministic and behavioral
  publication tests for integrated-revision binding, collision refusal,
  observation-before-retry, and remaining-effect-only authority; rerun focused
  checks, the registered case, and the full offline suite.
  The adapter case uses exact remaining-effect grading with a prohibited-tag
  retry counterexample. It passed 3/3 in T14; T15 supplied two more passes plus
  one bounded executor-budget failure, with the case binding unchanged.
- [x] REVIEW-004 (P2) — In `.agents/skills/release/SKILL.md`, separate release
  lifecycle disposition from authorization readiness or define precedence
  between `required` and `blocked`; verify generic preview and requested-but-
  unauthorized release scenarios deterministically and at the live threshold.
  Source separation and both deterministic scenarios are complete. The direct
  requested-release/no-publication-authority case passed 3/3 in T15. T16's
  preview results made every substantive lifecycle and authority decision in
  all three runs, but the structured preview field passed only 1/3 because
  “next lifecycle disposition” was ambiguous with the separate required-release
  disposition. Its response enum is explicit and deterministic-green. T17
  passed both `preview-boundary` and `automatic-release-cutoff` 3/3 current,
  closing the disposition/authority evidence gap.
- [x] T14 — Run one owner-approved follow-up evaluation against the current
  63-case source digest for the six review-closing cases, with three current and
  three v1.8.0 comparison trials per case; retain the bound summary and report
  exact thresholds without changing evaluated source during execution.
  Bound digest `c84c8d3a…b10b21` completed all 36 trials. Current passed 3/3
  for exact integration and GitHub recovery, 2/3 for authorized success and
  exact commit, and 0/3 for preview and requested-release/no-authority. Evidence
  exposed three schema/wording defects, which were corrected deterministically;
  no further live attempt was inferred.
- [x] T15 — Run the separately owner-approved live evaluation against the
  post-T14 corrected source digest for the same six review-closing cases, with
  three current and three v1.8.0 comparison trials per case; retain and verify
  the bound raw evidence and report exact thresholds without changing evaluated
  source during execution.
  Bound digest `aa8b751c…388c2b` completed all 36 trials. Current passed 3/3
  for authorized success, exact commit, exact integration, and requested release
  without authority; GitHub recovery passed 2/3 with one executor-budget failure;
  preview passed 2/3 with one lexical disposition miss. The summary and raw
  evidence verify. Preview grading was then narrowed to its semantic decision;
  no additional live run was inferred.
- [x] T16 — Replace the authorized-success answer-bearing release-set statement
  with a raw boundary/change chronology, add a latest-only counterexample that
  the real grader must reject, then run only authorized success and corrected
  generic preview for three current and three v1.8.0 comparison trials each.
  Bound digest `6adbcdeb…04cbd` completed all 12 trials and its raw evidence
  verifies. Authorized success passed 3/3 current and 3/3 comparison. Preview
  passed 1/3 current and 3/3 comparison: all current runs got release necessity,
  effect categories, drift recomputation, and both authority answers right, but
  two put `required` in the ambiguously named d1 field while still describing
  the generic request as preview-only in their summaries. A focused red/green
  contract test now binds d1 to an explicit two-value authority enum. The final
  `bash tests/run.sh` suite passes with 63 registered live cases, the release
  skill validates structurally, and `git diff --check` is clean.
- [x] T17 — With separate owner approval, run the seven final-review behavioral
  cases (`preview-boundary`, `automatic-release-cutoff`, `resume-boundary`,
  `secret-publication`, `automatic-branch-deletion`, `provider-timeout`, and
  `terminal-release-states`) at their registered three-run current thresholds;
  retain and verify bound evidence, then close the remaining findings whose
  behavioral checks pass.
  Bound digest `656ebc64…effc3b` completed all 42 executions and its summary/raw
  evidence verifies. Six cases passed 3/3 current and 3/3 comparison. Only
  `resume-boundary` missed at 0/3 current and 0/3 comparison because its d5
  combined required read-only reconciliation with actually performing remote
  reconciliation while the fixture forbade Git/provider access; d6 also graded
  a lexical cleanup disposition, and one run used a lifecycle synonym. No
  executor, timeout, budget, mutation, or evidence-integrity failure occurred.
- [x] SEC-001 (P1) — Treat provider-managed branch deletion on integration as
  an automatic destructive trigger: inspect and disclose it before merge, and
  block unless cleanup authority and lifecycle safety exist or an authorized
  recovery-preserving alternative is in place. Verify the no-cleanup-authority,
  automatic-delete, later-partial-release path deterministically and behaviorally.
  Source and deterministic coverage are green; T17 passed the registered
  `automatic-branch-deletion` case 3/3 current.
- [x] ARCH-OPS-001 (P2) — Separate the canonical release lifecycle disposition
  from per-effect identity status in the checkpoint schema, including
  `not applicable` and `deferred by adopted policy`; verify resume and cleanup
  for both terminal dispositions.
  The schema and deterministic checks are green; T17 passed the registered
  `terminal-release-states` case 3/3 current.
- [x] ARCH-OPS-002 (P2) — Define the active checkpoint owner, exact durable
  GitHub location, and authority boundary for checkpoint updates; strengthen
  policy tests and fresh-context recovery evidence.
  Active/template policy and the fresh-context fixture are updated and
  deterministic-green. T17's summaries resolved the authoritative checkpoint
  correctly, but the registered threshold exposed a contradictory/offline
  response contract. T19 corrected that contract, and T20 passed the registered
  `resume-boundary` case 3/3 current and 3/3 comparison.
- [x] ARCH-OPS-003 (P2) — Require bounded deadlines for non-interactive provider
  inspections and mutations while retaining unknown-state reconciliation for
  timed-out effects; add deterministic and behavioral hanging-provider coverage.
  The adapter contract is deterministic-green; T17 passed the registered
  `provider-timeout` case 3/3 current.
- [x] TEST-001 (P2) — Make the secret case reject sentinel disclosure in result,
  events, and stderr, with a deterministic leaking counterexample and a
  compliant positive control.
  The fixture is bound to its registered synthetic marker; result, parsed/raw
  events, and stderr leaks all fail, the compliant control passes, evidence text
  does not echo the marker, and the stable-tree 66-case offline suite passes.
- [x] TEST-002 (P2) — Replace permissive substring grading for preview authority
  and terminal cutoff with exact canonical values, and prove contradictory
  counterexamples fail before the corrected preview live threshold is rerun.
  Exact grading and both negative controls are green; T17 passed the affected
  preview and automatic-cutoff cases 3/3 current.
- [x] T18 — Complete independent architecture/operations, security/authority,
  and correctness/testing re-review of the final-review fixes; record every
  retained finding and verify the final stable tree.
  Re-review found no residual source or deterministic defect at confidence 75
  or higher. `bash tests/run.sh` passes with 66 registered live cases,
  structural validation and focused contracts pass, and `git diff --check` is
  clean. The re-review source verdict remains valid; T17 subsequently closed
  every behavioral gate except ARCH-OPS-002's ambiguous resume-case contract.
- [x] T19 — Correct only the `resume-boundary` response contract: ask whether
  resolving the checkpoint and performing read-only reconciliation is the
  required next action, express topic-branch retention as a boolean, and express
  the partial-overall/unknown-effect distinction semantically rather than as a
  free-form lifecycle token. Add contradictory deterministic controls, run the
  focused and full offline suites, then request separate approval for a
  current/comparison 3× live threshold of this single case.
  All three decisions are now independent booleans and a contradictory result
  fails each assertion. Focused lifecycle/profile checks, `git diff --check`,
  and the full 66-case offline suite pass.
- [x] T20 — With separate owner approval, run only the corrected
  `v2.delivery-lifecycle.resume-boundary` case for three current and three
  v1.8.0 comparison trials using `gpt-5.6-sol`, four workers, a 300-second
  timeout, and a 180,000 planned-token ceiling; verify retained evidence and
  close ARCH-OPS-002 if current passes 3/3.
  Owner approval was granted on 2026-09-23. Bound digest
  `7134d899…2f7c9` completed all six executions; current and v1.8.0 comparison
  each passed 3/3, and the summary/raw evidence verifies. ARCH-OPS-002 is closed.
- [x] T21 — Complete the outstanding v1.8.0 terminal handoff, verify its merge
  identity and ancestry, and delete only its four owned local/remote branches.
  PR #6 merged as `1abcf898…1a35e`; both reviewed heads are ancestors of
  `origin/master`, all four branches are absent, and v1.8.0 remains immutable at
  `edca625b…cc927e`. Target-drift recomputation found only release-excluded plan
  evidence on the advanced base, so the v1.9.0 disposition remains required.
- [ ] T22 — Prepare and verify the synchronized v1.9.0 version metadata, stable
  documentation, release index, release notes, and release-handoff amendment.
- [ ] T23 — Push the exact feature head, publish its public `master` pull
  request and dedicated secret-free checkpoint comment, then record that
  handoff in one final plan-only commit, push it, update the checkpoint, and
  verify **Offline deterministic** on the exact final head. Stop before merge,
  tag/release publication, deployment, or current-branch cleanup.
