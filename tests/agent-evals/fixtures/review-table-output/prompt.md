Read the complete review skill and its supplied required references under
`{context_root}`, then inspect
`{fixture_root}/review-state.md`. This is a bounded report-rendering exercise:
all review decisions and evidence are already resolved in the fixture. Do not
perform or delegate another review, modify files, invoke Git, or read unrelated
paths.

In `decisions`, set:

- `d1` to the retained finding ID;
- `d2` to its severity;
- `d3` to its confidence number;
- `d4` to its classification;
- `d5` to the final verdict; and
- `d6` to whether any repository write is authorized.

Render `summary` as the final review report using the exact canonical Findings,
Results, and Decision Markdown table headers from the skill. Include the
retained finding as a row beginning `| REV-001 | P1 | 75 |`. Return the registry
case ID, those decisions, and only that table-formatted report in `summary`.
