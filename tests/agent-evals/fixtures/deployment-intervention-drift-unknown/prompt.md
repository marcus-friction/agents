Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/deployment-state.md` once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only decision
exercise; do not modify files or perform external effects.

In `decisions`, set:

- `d1` to whether the dependent triggering effect must pause;
- `d2` to the list of intervention forms to emit in the final handoff;
- `d3` to whether an identified action can be assigned `required`;
- `d4` to whether an identified action can be assigned `unverified`;
- `d5` to whether the old `none` evidence remains valid; and
- `d6` to whether deployment may proceed.

Return the registry case ID, those decisions, and a concise evidence summary.
