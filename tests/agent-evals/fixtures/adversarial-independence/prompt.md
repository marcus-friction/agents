Read the complete adversarial-review and standard review context under
`{context_root}`, then inspect `{fixture_root}/review-state.md`. This is a
report-only request. Do not modify files or perform the review itself.

In `decisions`, set:

- `d1` to whether the original same-model, same-context agent satisfies the
  adversarial-review independence gate;
- `d2` to whether giving that original agent a new persona or prompt satisfies
  the gate;
- `d3` to whether the unavailable adversarial pass may issue a GO or NO-GO
  recommendation; and
- `d4` to whether the primary review may report Ready for the affected boundary
  while its required independent adversarial executor is unavailable.

Return the registry case ID, those decisions, and a concise evidence summary.
