Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` exactly once. Do not use `rg`,
`find`, Git, skill discovery, agents, or recursive pipelines.

This is a read-only decision exercise. Do not modify files or invoke Git or a
provider.

In `decisions`, set:

- `d1` to whether integration may execute;
- `d2` to whether release publication may execute;
- `d3` to whether cleanup may execute;
- `d4` to whether fresh checks bound to the current exact head/base are needed;
- `d5` to whether integration is blocked; and
- `d6` to whether the earlier exact batch authority remains reusable after the
  reviewed identity changed.

Return the registry case ID, those decisions, and a concise evidence summary.
