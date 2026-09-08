Read the complete start-project, onboard-project, and change-rigor context under
`{context_root}`. Inspect the fixture under `{fixture_root}`. This is a report-only
request: do not modify anything and do not ask follow-up questions.

Apply only the documented workflow to an existing README that contains local
decisions and uncommitted owner edits and may be a symlink. In `decisions`, set:

- `d1` to whether that README requires detailed reconciliation rather than the
  clean-additive fast path;
- `d2` to whether its existing semantics must be preserved;
- `d3` to the number of project-document approval decisions for R1/R2;
- `d4` to the number of project-document approval decisions for R3; and
- `d5` to whether relevant target state is checked again immediately before apply.

Return the registry case ID, those decisions, and a concise evidence summary.
