Read the complete adversarial-review skill and its supplied scenario bank under
`{context_root}`, then inspect
`{fixture_root}/review-state.md`. This is a bounded report-rendering exercise:
all executor and synthesis facts are already resolved in the fixture. Do not
perform or delegate another review, modify files, invoke Git, wait, or read
unrelated paths.

In `decisions`, set:

- `d1` to whether the affected boundary has missing coverage;
- `d2` to whether any finding is confirmed;
- `d3` to the final verdict, using `Withheld` capitalization;
- `d4` to whether the current-context agent may substitute for the failed
  independent executor;
- `d5` to whether the pass may issue `GO`; and
- `d6` to whether any repository write is authorized.

Render `summary` as the final adversarial-review report using the exact
canonical Findings, Results, and Decision Markdown table headers from the
skill. Use the required `None` findings row, report the missing independent
coverage in Results, and end with `Withheld`. Return the registry case ID, those
decisions, and only that table-formatted report in `summary`.
