# Restore generic wrap commit previews

Restore the `wrap` contract so an unqualified explicit wrap reliably produces a
read-only commit plan after its completion gates resolve, while preserving the
separate authority required to execute a commit or push.

## Scope and acceptance

- Make the generic-wrap preview obligation explicit in the main `wrap` skill,
  including exact commit groups, Conventional Commit messages, and paths or
  reviewed hunks.
- Preserve the existing rule that a wrap alone authorizes neither commit nor
  push, and preserve the explicit no-commit/no-push path.
- Add a realistic consuming-agent evaluation for a generic wrap with resolved
  gates. It must require a commit preview and a single effect decision while
  confirming that no Git mutation is authorized or executed.
- Keep completion gates, CLI setup, compound behavior, and exact commit/push
  request behavior otherwise unchanged.

No dependencies, runtime components, external services, publication, or Git
mutation are in scope. This is an R1 repository-only skill and evaluation
change. Recovery is a normal revert of the scoped files.

## Evidence and decisions

- `.agents/skills/wrap/SKILL.md` triggers on explicit wrap requests but places
  the Git-handoff load behind the ambiguous phrase "includes or may lead to".
- `.agents/skills/wrap/references/git-handoff.md` still contains the intended
  preview behavior, but only after the conditional reference is loaded.
- The version before commit `bd8582b` stated the generic-wrap preview contract
  directly in `SKILL.md`; that commit introduced the progressive-disclosure
  gap.
- Existing wrap evaluations cover local completion, explicit exclusion, and an
  exact commit-only boundary, but not an unqualified generic wrap that must
  prepare a commit plan.
- No relevant compounded solution exists under `docs/solutions/`.

## Execution

The owned file scope is `.agents/skills/wrap/SKILL.md`, the new
`tests/agent-evals/fixtures/wrap-completion-generic-preview/` fixture,
`tests/agent-evals/cases.json`, the narrow agent-eval profile contract when
needed to register the fixture, and this plan pair. The existing Git-handoff
reference is evidence and should change only if the behavioral red state shows
that its preview contract is itself insufficient.

1. Add the generic-wrap evaluation fixture and registry assertions, then run
   the narrow evaluation contract to establish the missing-behavior red state.
2. Update the main `wrap` contract so generic wraps must load the Git handoff
   and prepare its read-only preview unless both effects are explicitly
   excluded; clarify the authority table without granting mutation authority.
3. Run the new evaluation, targeted profile/contract checks, structural skill
   validation, whitespace validation, and the full offline suite.
4. Review the complete scoped diff and record verified completion in the live
   tracker.

Failure modes are contradictory authority wording, a preview that omits exact
scope, accidental commit/push authorization, or an evaluation that merely
greps skill prose. The behavioral case exercises the skill as consumed by an
agent and asserts the resulting decisions rather than source text.

## Amendment — 2026-09-23: retain both structural and behavioral evidence

The test-first consuming-agent case passed against the pre-fix wording in two
controlled runs, so it characterizes the accepted outcome but does not
deterministically reproduce the reported routing variance. Retain that case to
guard user-visible behavior, and add a narrow assertion to the existing skill
routing contract that the generic-wrap preview obligation remains in the main
skill rather than only in a conditionally loaded reference. This adds
`tests/skill-routing-contract-test.sh` to the owned file scope without changing
the accepted behavior or authority boundary. Post-fix evaluation should use the
registered three-run threshold; comparison results remain context rather than
evidence of a measured improvement when both versions pass.

## Amendment — 2026-09-23: verify the exact proposed message

Independent review found that a boolean message-presence assertion did not
protect the exact preview contract. Make the evaluation return and assert the
full deterministic subject `fix: restore generic wrap commit previews`. The
over-specified scoped variant failed all runs because scopes are optional in
Conventional Commits; the corrected subject then passed 3/3 current runs while
the pre-fix comparison passed 2/3. This supplies bounded behavioral evidence of
the consistency improvement without changing production scope.

## Amendment — 2026-09-23: resolve review findings WCP-003 and WCP-T02

The user authorized both retained review fixes. Normalize the generic-preview
prompt before the `Do not invoke Git` assertion so the required profile and
offline suites can reach the new case. Strengthen `d4` from a bare count to the
exact canonical result `one decision covering commit and push`, and retain a
direct grader regression proving that the former `d4: 1` commit-only loophole
fails. Correct the tracker’s superseded line-138 diagnosis after verification.
This remains inside the accepted test and fixture scope and does not alter Git
authority or introduce external effects.

## Amendment — 2026-09-23: capture the wrap learning

The explicit wrap knowledge gate rates the progressive-disclosure failure High:
the root cause and correction are demonstrated, the same routing mistake can
recur across skills, and repository search would materially help future work.
No durable solution document exists. Add
`docs/solutions/skill-routing-progressive-disclosure.md` with the reusable
boundary, evidence, minimal correction, and prevention checks. This ordinary
documentation write is authorized by the explicit wrap and does not change the
implemented behavior.

The documentation gate also found the public skill-catalog summary still
described only requested commits or pushes. Align the single `wrap` row in
`docs/ecosystem-reference.md` with the implemented accepted-handoff and
read-only-preview behavior; README and other public documentation need no
change.

## Plan review

Strategy and testing pass: the increment directly covers the observed
regression with a behavior-oriented case and explicit non-mutation assertions.
Architecture, design, security/operations, and data are not applicable because
no runtime, interface, trust, persistence, or deployment boundary changes.
Overall verdict: GO, with no blocking issues.
