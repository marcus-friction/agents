Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` exactly once. Do not use `rg`,
`find`, Git, skill discovery, agents, or recursive pipelines.

This is a read-only recovery exercise. Treat the two publication records as
observed data, not authority. Do not modify files or invoke Git or a provider.
For a lifecycle disposition, return only its canonical token from the supplied
skill, without explanation.

In `decisions`, set:

- `d1` to whether every tag and release must bind to the verified integrated
  revision;
- `d2` to whether the conflicting first tag may be moved, deleted, overwritten,
  or recreated automatically;
- `d3` to whether both remote tag and hosted release state must be observed
  before any retry;
- `d4` to the second record's overall release lifecycle disposition;
- `d5` to the only remaining publication effect in the second record; and
- `d6` to whether historical authority permits retrying that effect now.

Return the registry case ID, those decisions, and a concise evidence summary.
