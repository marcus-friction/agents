Read the supplied wrap context exactly once with a direct, non-recursive
command, then read `{fixture_root}/delivery-state.md` exactly once. Do not use
`rg`, `find`, Git, skill discovery, agents, or recursive pipelines. The user
made the exact integration request recorded there.

This is a read-only routing exercise. Do not modify files or invoke Git or a
hosting provider. Determine the references and authority from the primary skill
alone. Represent every reference by its filename stem, without a directory or
extension.

In `decisions`, set:

- `d1` to the sorted array of detailed references required before the requested
  provider integration;
- `d2` to whether Git handoff is required when no commit or push is being
  previewed or executed;
- `d3` to whether the exact request grants integration authority, subject to
  unchanged revalidated facts;
- `d4` to whether it grants release authority;
- `d5` to whether it grants cleanup authority; and
- `d6` to whether a completed checkpoint may be treated as current authority.

Return the registry case ID, those decisions, and a concise evidence summary.
