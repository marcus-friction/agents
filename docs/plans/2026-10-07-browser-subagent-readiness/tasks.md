# Require browser subagents and reachable test targets

- [x] Inspect repository rules and browser-testing skill routes.
- [x] Review the scoped plan and acceptance criteria.
- [x] Update `end2end` and `playwright` execution instructions.
- [x] Run structural, affected contract, and offline suite verification.
- [x] Inspect the scoped diff and record final evidence.
- [x] Complete the requested scoped review and record retained findings.
- [x] REVIEW-BSR-001 (P2, `.agents/skills/playwright/SKILL.md:18`):
  make port forwarding and subagent-browser reachability checks conditional on
  using a subagent so the no-subagent host fallback remains executable. Verify
  both available- and unavailable-subagent paths.
- [x] REVIEW-BSR-002 (P2, `.agents/skills/end2end/SKILL.md:48` and
  `.agents/skills/playwright/SKILL.md:17`): add focused contract and agent
  evaluation cases for subagent selection, browser-side readiness and
  forwarding, blocked targets, and host fallback. Execute the relevant checks
  and record outcome coverage rather than relying on a green suite alone.
- [x] Add a failing fallback contract check before revising Playwright wording.
- [x] Register and validate focused consuming-agent cases for the browser
  routing and readiness decisions.
- [x] Rerun affected checks and the offline suite, then inspect the full diff.
- [x] Prepare v1.12.0 version metadata, stable-install references, and release
  notes for the complete consumer-facing skill increment.
- [x] Resolve the live behavior evidence and reviewed-head quality gates.
- [ ] Commit the exact reviewed payload on an owned topic branch and push that
  branch to `origin`.
- [ ] Open and review the PR, confirm passing CI on the exact head, and verify
  integration before publication.
- [ ] Publish and verify the v1.12.0 tag and GitHub release at the merge SHA.
- [x] Complete the pre-commit delivery review and record retained findings.
- [x] REVIEW-BSR-003 (P2, `tests/agent-evals/cases.json`): isolate available
  and blocked end-to-end cases from Playwright context, and cover Playwright's
  available-subagent route separately. Verify registration and the relevant
  consuming-agent outcomes.
- [x] REVIEW-BSR-004 (P2, `.agents/skills/playwright/SKILL.md:31`): add a
  Playwright-only source-review case with an available subagent and unready app;
  assert no startup, forwarding, or browser handoff. Verify registry and result.
- [x] Diagnose and repair the live evaluator's socket preflight, restricted
  command availability, and bounded rollout; verify with focused and selected
  live cases while preserving the evaluator's own sandbox.
- [x] Review the evaluator repair and test coverage before delivery.
- [x] REVIEW-EVAL-001 (P2, `tests/agent-evals/runner.py:1554`): apply socket
  preflight to a real selected CLI through `AGENT_EVAL_CODEX_BIN`, exempt only
  the deterministic offline fake, and verify the override path.
- [x] REVIEW-EVAL-002 (P2, `tests/agent-evals/cases.json:2335`): cover the
  end-to-end no-subagent host fallback with an isolated consuming-agent case.
- [x] REVIEW-EVAL-003 (P2, `tests/agent-evals/cases.json:2360`): cover
  Playwright's unreachable target and no-host-substitution path with an
  isolated consuming-agent case.
- [x] REVIEW-EVAL-004 (P2, `tests/agent-evals/cases.json:2323`): assert the
  end-to-end subagent handoff includes bounded flows, expected outcomes,
  allowed effects, and an openable URL.
- [x] REVIEW-EVAL-005 (P2, `tests/agent-eval-profile-test.sh:89`): test the
  socket preflight's absent, unsafe type, and wrong-owner branches.

Verification on 2026-10-07: both skills passed `quick_validate.py`; the skill
effect and stack contracts, `git diff --check`, and the complete
`bash tests/run.sh` offline suite passed. The first full-suite attempt timed out
in the previous-project installer boundary test at its 60-second subprocess
limit; that test passed alone in 43 seconds, and the full suite passed on retry.
No browser flow was run because this increment changes skill instructions only.

Review remediation evidence on 2026-10-07: the new fallback contract assertion
failed against the reviewed Playwright wording and passed after the conditional
preflight fix. The three available, unavailable, and unreachable agent cases
passed registry/profile validation. Both skill validators and the complete
offline suite passed with 78 registered live cases; live execution awaits the
owner's cost decision.

Delivery preparation on 2026-10-07: `v1.11.0` is the latest verified release
boundary and `master` was at that tag. The v1.12.0 metadata, stable-install
references, and release note passed `bash tests/run.sh`, skill validation, and
`git diff --check`. A redaction-safe scan found no classified sensitive
artifact in the 19 changed files. The owned topic branch is
`feature/browser-subagent-readiness-v1.12.0`.

The delivery review retained REVIEW-BSR-003 and REVIEW-BSR-004. The five
skill-specific agent cases now register and the complete offline suite passes
with 80 live cases registered. The three open coverage findings remain unchecked
until consuming-agent results are observed; no commit or push has occurred.

Approved live-evaluation attempt on 2026-10-07: the bound five-case run and
two focused environment probes failed before any model turn. Every attempt
reported that the local Codex sandbox could not create its app-server socket
directory because its mode/ownership check failed. A private
`XDG_RUNTIME_DIR` and omitting that variable produced the same failure. The
runner recorded no completed model turn or case decision. Per the repository's
three-attempt blocker rule, live behavior evidence remains unavailable; the
coverage findings and delivery effects stay pending.

Evaluator repair evidence on 2026-10-08: syscall tracing showed the nested
Codex helper rejecting `/tmp/codex-daemon-1000`, which this tool sandbox mounts
read-only with mode 000. A read-only host-shell check found the actual directory
owned by the user with mode 0700. A focused evaluator run from that host shell
started successfully. The new preflight fails before any model dispatch in the
masked environment with a specific host-shell instruction; its offline test
failed before implementation and passes now. The runner supplies exact context
paths, names usable shell tools, and requests low reasoning effort. A focused
host-shell current case passed every browser handoff assertion at a 10,000-token
per-call limit. The comparison side still exhausted that limit, and the five
selected cases require a larger planned batch limit than the earlier cost
approval; the owner decision is pending.
The complete `bash tests/run.sh` offline suite passed with 80 registered live
cases; `git diff --check` also passed. Neither result substitutes for the
remaining four live current-case outcomes.

Approved five-case host-shell run on 2026-10-08: at a 100,000-token planned
limit (10,000 per execution), the unavailable-subagent, unreachable-target,
and Playwright source-only current cases completed and passed all assertions.
The end-to-end available-subagent and Playwright available-subagent current
cases emitted the expected decision JSON but exhausted the per-call rollout
before a completed turn; the runner correctly rejected both. Baseline
comparisons were also limited by the budget, except the unreachable-target
comparison, which completed. A focused 60,000-token retry for the two
incomplete case pairs is awaiting an owner cost decision. No failed case is
counted as proven behavioral coverage.

Review remediation on 2026-10-08: the registry now has seven isolated browser
cases, including end-to-end host fallback and Playwright unreachable target.
The end-to-end available case now checks the actual flow, outcome, allowed
effect, and URL in the proposed subagent handoff. The preflight test covers
missing paths, unsafe file/symlink types, foreign owner, masked mode, and
valid mode. The preflight now checks every selected live CLI, including an
override path; the bound offline fake-executor marker is the only exemption.
A manual override-path probe failed before executing its dummy binary in the
masked environment, and the focused profile and stack contracts passed. The
earlier focused 60,000-token retry request is superseded by a pending owner
decision for a seven-case, 210,000-token revised batch.
The full `bash tests/run.sh` offline suite passed with 82 live cases registered;
the seven browser cases were not executed by that suite. `git diff --check`
passed, and a redaction-safe scan of all 25 changed paths found no classified
credential artifact. Live outcome coverage remains pending.

A follow-up testing review found that the first fake-executor marker could
also exempt a real CLI selected by override. The final exemption now requires
the marker, `test-model`, and the deterministic profile script signature;
the focused test was red before this correction and passes now. The reviewer
confirmed that a real alternate CLI still reaches the socket preflight. The
complete `bash tests/run.sh` suite passed against this runner revision with
82 live cases registered; it did not execute those cases.

Approved revised live evaluation on 2026-10-08: all seven current browser
cases completed a Codex turn and passed every assertion under the
210,000-token planned limit (14 current/comparison executions, two concurrent).
All comparison turns completed; six passed and the end-to-end available case
failed only its handoff-flow assertion. The saved summary and raw evidence
verified with `--check-summary` at
`/tmp/agents-browser-revised-batch-1791451922377`. Its
`release_qualified=false` is expected for a selected, uncommitted subset. The
evaluator, skill, and fixture content has not changed since that run; this
tracker update records the result without altering those tested files.
