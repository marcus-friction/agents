# Restore generic wrap commit previews

- [x] Diagnose the regression, inspect repository rules, and identify the
  missing generic-wrap evaluation boundary.
- [x] Review the implementation plan to GO and incorporate its file-scope
  clarification.
- [x] Add a consuming-agent characterization case; record that the pre-fix
  wording passed two controlled runs rather than producing a deterministic red.
- [x] Add a narrow structural contract for the progressive-disclosure boundary.
- [x] Restore the generic-wrap commit-preview contract without authorizing Git
  mutation.
- [x] Pass the focused three-run evaluation and targeted structural checks.
- [x] Pass whitespace validation and the full offline repository suite.
- [x] Review the scoped diff and record the final evidence.
- [x] WCP-001: assert the exact proposed Conventional Commit message in the
  generic-wrap evaluation and verify the focused case again.
- [x] REVIEW-WCP-003: in `tests/agent-eval-profile-test.sh:150`, normalize the
  generic-preview prompt before asserting `Do not invoke Git`; verify with the
  focused profile test and `bash tests/run.sh`, then correct the stale failure
  attribution below.
- [x] REVIEW-WCP-T02: make the generic-preview `d4` result explicitly cover
  both commit and push, reject a commit-only grader probe, and rerun the focused
  three-run evaluation.
- [x] Capture and verify the High-rated progressive-disclosure learning in
  `docs/solutions/skill-routing-progressive-disclosure.md` during wrap.
- [x] Align the public `wrap` catalog summary in `docs/ecosystem-reference.md`
  and verify documentation contracts.

Final verification: the registered generic-wrap live case passed 3/3 current
runs and 3/3 comparison runs, and its retained summary passed integrity
checking. The direct commit-only grader probe fails the consolidated-effect
assertion as intended. `quick_validate.py`, the focused profile test, the skill
routing contract, registry loading/listing, `git diff --check`, and the complete
`bash tests/run.sh` offline suite all passed on 2026-09-23. The offline profile
registered 45 live cases without executing the other live cases.

Final independent correctness and testing re-reviews resolved WCP-003 and
WCP-T02, retained no new findings, and returned `Ready`. The unrelated untracked
`docs/plans/2026-09-23-generalized-wrap-release-lifecycle/` plan was preserved
and excluded from this increment.
