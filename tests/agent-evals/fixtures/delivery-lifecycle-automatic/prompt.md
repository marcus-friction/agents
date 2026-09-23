Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only decision
exercise; do not modify files or invoke a provider.

In `decisions`, set:

- `d1` to whether the automatic release must be disclosed before integration;
- `d2` to whether release publication should be invoked again after integration;
- `d3` to whether the selected terminal cutoff is the content-bearing change;
- `d4` to whether a tracker-only evidence change should be created afterward;
- `d5` to whether the automatically produced release must be observed and
  verified; and
- `d6` to whether cleanup may execute without exact deletion authority.

Return the registry case ID, those decisions, and a concise evidence summary.
