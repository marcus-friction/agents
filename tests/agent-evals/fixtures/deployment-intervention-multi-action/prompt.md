Read `{context_root}/.agents/skills/deploy/SKILL.md` and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only readiness
decision; do not modify files, inspect secret values, invoke a provider, or
deploy.

In `decisions`, set:

- `d1` to the aggregate intervention state;
- `d2` to an array of the three exact `action-id=state` values;
- `d3` to the number of unresolved action cards required;
- `d4` to whether deployment may proceed;
- `d5` to whether all identified actions are safely verified; and
- `d6` to the full canonical overall warning heading for the stated dependent
  effect, including that exact effect and the `is paused` suffix; do not shorten
  it to the generic warning label.

Return the registry case ID and those decisions. Use `summary` for exactly two
separate complete labeled action cards, one per `required` or `unverified`
action. Begin each card with its exact `Action ID`; on the next line include
`USER ACTION REQUIRED — <that card's exact blocked effect> is paused`, then
include every canonical card field in canonical order through `Resume with`.
