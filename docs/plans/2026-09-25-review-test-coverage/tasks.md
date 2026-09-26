# Review test coverage

- [x] Inspect repository rules, review skills, and existing contract tests.
- [x] Require affected-test inventory and established coverage in primary review.
- [x] Align review-plan, review-quality, and adversarial guidance.
- [x] Validate changed skills, existing contract checks, offline suite, and diff.

Verification on 2026-09-25: all four `quick_validate.py` checks, both targeted
review contract tests, `git diff --check`, and `bash tests/run.sh` passed. The
offline suite did not execute its 75 registered live-agent cases. Final review
found no runtime code or authority changes.

## Wrap and release preparation

- [x] Prepare `v1.11.0` version metadata, stable documentation, and release notes.
- [x] Verify the complete prepared payload and inspect sensitive-artifact risk.
- [x] Prepare the exact Git and delivery lifecycle preview.

Wrap verification on 2026-09-26: `VERSION`, plugin, and marketplace versions all
equal `1.11.0`; `git diff --check` and the full `bash tests/run.sh` offline suite
passed. The accepted paths contained no matches for the checked credential and
hook patterns. Remote `master` still matched local `master` at
`f9e8d549a0c48f6cce7ce7678e2948b20723c859`, and remote `v1.11.0` and the
proposed topic branch were absent. The delivery preview is read-only; no Git or
provider mutation was performed.
