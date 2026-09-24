Read `{context_root}/.agents/skills/deploy/SKILL.md` and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a
read-only decision exercise; do not modify files or deploy.

In `decisions`, set:

- `d1` to the intervention category for the script problem;
- `d2` to the canonical user-intervention state for the current authorized
  preparation request;
- `d3` to whether the agent should implement and test the scoped repository fix;
- `d4` to whether repository-edit authority would be required if preparation
  had not been authorized;
- `d5` to whether the technical edit should instead be delegated to the user;
  and
- `d6` to whether production deployment may execute under this request.

Return the registry case ID, those decisions, and a concise evidence summary.
