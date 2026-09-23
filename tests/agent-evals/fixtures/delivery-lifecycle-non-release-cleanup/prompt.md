Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` exactly once. Do not use `rg`,
`find`, Git, skill discovery, agents, or recursive pipelines.

This is a read-only decision exercise over supplied observations. Do not modify
files or invoke Git or a provider.
In `decisions`, set:

- `d1` to whether a release applies to this increment;
- `d2` to whether cleanup may execute under the supplied terminal evidence and
  exact authority;
- `d3` to the sorted cleanup targets with sufficient proof;
- `d4` to whether force deletion is needed or permitted;
- `d5` to whether integration is verified; and
- `d6` to whether executing exactly the supplied safe cleanup would complete
  delivery at a terminal state.

Return the registry case ID, those decisions, and a concise evidence summary.
