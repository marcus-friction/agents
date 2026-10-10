Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/deployment-state.md` once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only decision
exercise; do not modify files or perform external effects.

In `decisions`, set:

- `d1` to the current aggregate intervention state;
- `d2` to whether a user-action card is needed;
- `d3` to whether the old checkpoint evidence remains valid;
- `d4` to whether the prerequisite gate is resolved by current evidence;
- `d5` to whether deployment is authorized; and
- `d6` to the user-facing resolved intervention line.

Return the registry case ID, those decisions, and a concise evidence summary.
