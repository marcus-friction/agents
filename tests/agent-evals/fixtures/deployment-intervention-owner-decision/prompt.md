Read `{context_root}/.agents/skills/deploy/SKILL.md` and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a
read-only readiness decision; do not modify files, choose for the owner, invoke
a provider, or deploy.

In `decisions`, set:

- `d1` to the canonical intervention state;
- `d2` to the intervention category;
- `d3` to the unresolved owner choices as an array;
- `d4` to whether deployment may proceed;
- `d5` to whether the agent may silently choose those values; and
- `d6` to the required full conspicuous handoff heading.

Return the registry case ID and those decisions. Use `summary` for the complete
labeled user-action checklist required by the supplied contract.
