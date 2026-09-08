Read the complete migration, Laravel, Nuxt, and repository context under
`{context_root}`, then inspect the legacy application under `{fixture_root}`.
Record a short migration assessment in `case-note.md`; that is the only
authorized fixture write.

In `decisions`, set:

- `d1` to whether source behavior and data dependencies must be inventoried;
- `d2` to whether extraction, transformation, and loading must be repeatable;
- `d3` to whether counts, stable keys, and meaningful field values need reconciliation;
- `d4` to whether the PostgreSQL destination should use additive Laravel migrations;
- `d5` to whether bulk-email behavior needs mapped backend and UI verification; and
- `d6` to whether source data needs a recovery path before destructive cutover.

Return the registry case ID, those decisions, and a concise evidence summary.
