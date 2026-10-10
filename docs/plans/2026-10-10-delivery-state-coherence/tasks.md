# Tasks — Delivery state coherence

- [x] Inspect PR #9 against current master and confirm both fixes are absent.
- [x] Read repository rules and create the approved topic branch.
- [x] Inventory affected tests and add drift/checkpoint boundary evaluations.
- [x] Port the four delivery-guidance files and prepare v1.13.1 metadata/docs.
- [x] Run affected checks and the complete offline deterministic suite.
- [x] Complete independent contract/testing review and resolve findings.
- [x] COH-C1 — Align wrap/deploy reporting for unknown discovery; verify the
  unknown-inventory case emits no fabricated intervention form or state.
- [x] COH-C2 — Align deploy's direct drift contract; include it in empty/unknown
  inventory evaluation contexts and verify both outcomes.
- [x] TEST-001 — Update both stale registry counts to 85; run profile/full suite.
- [x] Inspect the exact accepted payload for sensitive artifacts; commit/push.
- [x] Publish and verify the replacement PR against current master.
- [x] Comment on and close #9 as superseded; preserve its source branch.

Merge, release publication and branch deletion are outside this approved batch.

## Verification evidence

- Existing drift/missing-action, `none`, resume, hostile-checkpoint and terminal
  cutoff case expectations remain valid: these retain identified-action blocking,
  safe reconciliation and authority boundaries.
- Three new cases distinguish drift with a verified empty inventory, drift with
  incomplete discovery, and a checkpoint continuation with pending identities.
  The deterministic grading checks reject the unsafe alternative for every new
  decision. They establish evaluator sensitivity rather than live model behavior.
- The new static contract check failed against the pre-fix guidance and passed
  after porting PR #9's four delivery files. No testable production code changed;
  runtime line/branch coverage is not applicable to these instruction edits.
- Independent testing and standards/operations reviews identified COH-C1,
  COH-C2 and TEST-001. Bounded rechecks confirmed all code/instruction corrections
  without new findings. The profile test and final full suite passed.
- A fresh clean-context subagent executed all three final scenario prompts.
  Each result's six decisions passed the registered grader. This is one-pass
  subagent smoke evidence, not the formal live runner's three-run qualification.
- Final verification: `bash tests/run.sh` passed on the completed skill/test
  payload (`offline-deterministic=passed`, `live-agent-v2=not-run`, 85 registered
  cases). `git diff --check` passed. The redaction-safe payload check accounted
  for all 22 regular files and found no unexpected paths or credential patterns.

## Verified repository handoff — 2026-10-10

- Published substantive commit `467fcd0dcfd4d99f3a53f7b1230472476b7d130d`
  on `fix/delivery-state-coherence-v1.13.1`, based on the unchanged v1.13.0
  `master` revision named in the plan.
- Replacement PR [#13](https://github.com/marcus-friction/agents/pull/13)
  is open against `master`; its published substantive head was verified.
- [Supersession comment](https://github.com/marcus-friction/agents/pull/9#issuecomment-6101882357)
  links #9 to #13. PR #9 is closed; its remote branch remains at
  `93f801e4a2bc8fc289e5ce3ef959c76204d3ca8e`.
- This final tracker update records observed handoff facts before the terminal
  merge cutoff. Exact final PR head/CI outcomes remain host evidence. Human
  review, merge, release publication and cleanup remain later delivery gates.
