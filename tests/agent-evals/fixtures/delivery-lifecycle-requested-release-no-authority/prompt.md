Read the supplied release context exactly once with a direct, non-recursive
command, then read `{fixture_root}/delivery-state.md` exactly once. Do not use
`rg`, `find`, Git, skill discovery, agents, or recursive pipelines.

This is a read-only release decision exercise. Do not modify files, invoke Git,
or contact a hosting provider. Keep lifecycle disposition separate from
authority readiness. For either field, return only its canonical token from the
supplied skill.

In `decisions`, set:

- `d1` to the release lifecycle disposition;
- `d2` to whether the next exact release effect is immutable tag publication;
- `d3` to authority readiness for that effect;
- `d4` to whether publication may execute now;
- `d5` to whether missing publication authority changes the lifecycle
  disposition to blocked; and
- `d6` to whether any mutation occurred in this exercise.

Return the registry case ID, those decisions, and a concise evidence summary.
