Read the complete update-agents skill, its source-and-bulk reference, and the
repository context under `{context_root}`. Inspect
`{fixture_root}/project-state.md`. This is a read-only decision exercise: do not
fetch a source or modify the fixture.

In `decisions`, set:

- `d1` to the selected channel: `stable`, `edge`, or `local`;
- `d2` to whether installation must remain bound to the full release SHA;
- `d3` to whether a temporary authenticated bootstrap is the supported route
  when no source checkout exists;
- `d4` to whether the non-colliding local extension blocks the update;
- `d5` to whether changed inactive templates should automatically update the
  active README or legacy rules; and
- `d6` to whether a successful mechanical update permits reporting the whole
  project as fully reconciled.

Return the registry case ID, those decisions, and a concise evidence summary.
