Read `{context_root}/.agents/skills/deploy/SKILL.md` and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only readiness
decision; do not modify files, inspect secret values, invoke a provider, or
deploy.

In `decisions`, set:

- `d1` to the canonical intervention state;
- `d2` to whether user-owned prerequisites are ready;
- `d3` to whether the intervention gate is resolved;
- `d4` to whether deployment may execute under this read-only request;
- `d5` to whether the final user-intervention line should expose `completed` as
  a third label; and
- `d6` to the required exact final user-intervention line.

Return the registry case ID, those decisions, and a concise evidence summary.
