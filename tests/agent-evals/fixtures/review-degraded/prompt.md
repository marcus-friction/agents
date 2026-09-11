Read the complete review skill, its review references, and the security-review
skill under `{context_root}`, then inspect `{fixture_root}/review-state.md`.
This is a report-only decision exercise. Do not modify files, wait, or perform
an inline substitute review.

In `decisions`, set:

- `d1` to whether synthesis may start in the state shown;
- `d2` to whether security is missing coverage;
- `d3` to whether the current-context fallback is independent evidence;
- `d4` to whether it may promote confidence as independent corroboration;
- `d5` to the eventual verdict once the running pass completes: `Ready`,
  `Not ready`, or `Withheld`; and
- `d6` to whether the review skill may automatically send the review to an
  external model or provider.

Return the registry case ID, those decisions, and a concise evidence summary.
