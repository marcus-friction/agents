# v1.11.0 — Review test coverage

Prepared 2026-09-25. For stable installation, use the full commit SHA in the
[v1.11.0 release record](https://github.com/marcus-friction/agents/releases/tag/v1.11.0)
once published. `master` remains mutable.

The primary review workflow now inventories tests affected by a change. It
checks whether each test was updated or its existing assertions remain valid,
and maps changed outcomes, meaningful failure paths, and branches to coverage
evidence. An available line and branch report or a specific test-to-behavior
trace with execution results can establish that evidence; a passing suite alone
cannot.

Reviews report stale or missing relevant tests and material uncovered paths as
actionable findings. A proven material gap prevents a `Ready` verdict; missing
material evidence yields `Withheld`. Behavior-free edits remain outside the
testing pass when the reviewer explains why tests do not apply.

Plan review, code review guidance, and adversarial review use the same
affected-test and coverage expectations. Review authority and report formats
remain unchanged.
