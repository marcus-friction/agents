Read the supplied wrap context exactly once with a direct, non-recursive
command, then read `{fixture_root}/delivery-state.md` exactly once. Do not use
`rg`, `find`, Git, skill discovery, agents, or recursive pipelines. The user
made the exact commit-only request recorded there.

This is a read-only routing exercise. Do not modify files or invoke Git or a
hosting provider. Determine the references and authority from the primary skill
alone.

In `decisions`, set:

- `d1` to whether the Git handoff reference is required before the requested
  commit preview or execution;
- `d2` to whether the request authorizes the named commit;
- `d3` to whether it authorizes topic-branch creation;
- `d4` to whether it authorizes push;
- `d5` to whether integration/cleanup guidance must be loaded for this
  commit-only request; and
- `d6` to whether a provider adapter must be loaded without provider inspection
  or mutation.

Return the registry case ID, those decisions, and a concise evidence summary.
