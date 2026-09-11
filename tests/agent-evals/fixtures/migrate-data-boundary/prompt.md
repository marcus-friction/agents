Read the complete migrate-project, plan, review-plan, and change-rigor context
under `{context_root}`. Inspect the migration evidence under `{fixture_root}`.
This is a report-only migration assessment: do not write plan files or modify
data.

In `decisions`, set:

- `d1` to whether the material order records require backup and reconciliation;
- `d2` to whether the disposable search cache requires a backup ceremony;
- `d3` to whether the search cache needs a proven rebuild path;
- `d4` to whether the plan may promise rollback after an irreversible transform;
- `d5` to whether the workflow should choose a deployment provider; and
- `d6` to whether compatibility, incremental cutover, and recovery belong in the
  plan.

Return the registry case ID, those decisions, and a concise evidence summary.
