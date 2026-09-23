# Review table output

- [x] Inspect repository rules, both skill contracts, and existing tests.
- [x] Require table-formatted findings and results in `review`.
- [x] Require table-formatted findings and results in `adversarial-review`.
- [x] Extend the existing deterministic contract checks.
- [x] Pass targeted validation, the full offline suite, and final diff review.

Verification: both `quick_validate.py` skill checks, both targeted skill-contract
tests, `git diff --check`, and `bash tests/run.sh` passed on 2026-09-23. The
offline profile passed; 44 registered live-agent cases were not run. Final diff
inspection confirmed that review scope, authority, classifications, tracker
behavior, and verdict rules are unchanged.

## Consistency refinement

- [x] Select one shared, compact schema for both skills.
- [x] Update the existing contract assertions and confirm they fail against the
  inconsistent schemas.
- [x] Apply the shared Findings, Results, and Decision table format to both
  skills without dropping specialized fields.
- [x] Re-run targeted validation, the full offline suite, and final diff review.

Consistency verification: both updated assertions failed before the skill edits
and passed afterward. Both structural validators, `git diff --check`, and the
full `bash tests/run.sh` offline profile passed on 2026-09-23; 44 registered
live-agent cases were not run. Final inspection confirmed identical Findings,
Results, and Decision headers in both skills, with all prior required fields and
decision rules retained.
