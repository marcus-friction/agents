Read `{context_root}/.agents/skills/deploy/SKILL.md` and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a
read-only resume decision; do not modify files, inspect secret values, invoke a
provider, or deploy.

In `decisions`, set:

- `d1` to the canonical intervention state;
- `d2` to whether deployment may proceed;
- `d3` to whether the user's completion report alone is sufficient;
- `d4` to whether safe verification is still required;
- `d5` to the exact blocked effect; and
- `d6` to the required full conspicuous handoff heading.

Return the registry case ID and those decisions. Use `summary` for the complete
labeled user-action checklist required by the supplied contract.
