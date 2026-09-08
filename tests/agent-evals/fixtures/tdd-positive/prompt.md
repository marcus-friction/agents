Read the complete TDD and repository-quality context under `{context_root}` and
inspect the existing slug helper under `{fixture_root}`. The requested behavior
change is to collapse repeated spaces into one separator. Do not change the
implementation in this evaluation; record the required development sequence in
`case-note.md`, which is the only authorized fixture write.

In `decisions`, set:

- `d1` to whether the existing implementation remains until a test proves the
  intended change;
- `d2` to whether current behavior should be characterized when useful; and
- `d3` to whether a failing test for the separator change comes before the
  production change.

Return the registry case ID, those decisions, and a concise evidence summary.
