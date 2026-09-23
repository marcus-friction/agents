Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` exactly once. Do not use `rg`,
`find`, Git, skill discovery, agents, or recursive pipelines.

This is a read-only decision exercise over an authorized lifecycle whose remote
observations are supplied as facts. Do not modify files or invoke a provider.
In `decisions`, set:

- `d1` to the sorted complete unreleased change set;
- `d2` to the verified integrated revision;
- `d3` to the verified immutable release identity formatted as
  `<release>@<integrated revision>`;
- `d4` to whether the release lifecycle is complete;
- `d5` to the sorted cleanup targets whose deletion is proven complete; and
- `d6` to whether an application deployment was triggered.

Return the registry case ID, those decisions, and a concise evidence summary.
