# Review test coverage

## Accepted increment

Make review workflows verify that every test affected by a change is updated or
still valid, and that testable changed behavior has established coverage. Keep
existing review authority, proportionate applicability, and existing report
formats intact.

## Evidence and scope

- `README.md` defines the plan, implement, review, wrap workflow.
- `CONTRIBUTING.md` and `AGENTS.md` call for changed outcomes and meaningful
  failures to be tested, aiming for full line and branch coverage of testable
  production behavior.
- `.agents/skills/review/SKILL.md` currently selects testing only for changed
  behavior, failure handling, or a harness, and does not require an explicit
  test inventory or coverage basis in the verdict.
- `.agents/skills/review-plan/SKILL.md` already calls for a coverage map; the
  review guidance and adversarial review need the same expectation.
- `docs/solutions/skill-routing-progressive-disclosure.md` supports keeping
  the review decision rule in the primary `SKILL.md`.

Scope is the primary review, review-plan, code-review-excellence, and
adversarial-review skill text. No runtime code, dependencies, publication, or
external effects are required. This is an R1 reversible documentation change.

## Execution and acceptance

1. Require review to inventory affected tests, decide which need updates, and
   map testable changed outcomes and failure branches to coverage evidence.
2. Make missing relevant test updates or material coverage a visible finding
   and verdict issue; distinguish unavailable evidence from proven gaps.
3. Align plan review, review-quality guidance, and independent challenge with
   the primary review contract without turning behavior-free edits into a
   demand for tests.
4. Validate skill structure, existing contract checks, full offline suite, and
   final diff.

Coverage evidence may be an available line/branch report or a specific
test-to-code trace with execution results. A passing suite alone does not prove
coverage. If a project's required measurement cannot run under review authority,
the review reports unavailable evidence. Recovery is a scoped Git revert.

## Amendment — 2026-09-25: wrap and release preparation

The accepted wrap request invokes the active delivery contract. Managed-skill
changes require a release, and `v1.10.0` is the last release boundary. Prepare
`v1.11.0` as a minor release for the added review behavior: synchronize `VERSION`,
plugin and marketplace metadata, stable-install documentation, and release
notes. Re-run the offline suite and inspect the final payload before the exact
read-only Git and delivery preview. Commit, push, PR, integration, tag, release,
checkpoint comment, and cleanup effects remain outside this local preparation.
