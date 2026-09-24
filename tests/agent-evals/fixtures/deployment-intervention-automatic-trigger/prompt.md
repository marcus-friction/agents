Read `{context_root}/.agents/skills/wrap/SKILL.md`,
`{context_root}/.agents/skills/release/SKILL.md`, and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a
read-only lifecycle decision; do not modify files, integrate, tag, release, or
deploy.

In `decisions`, set:

- `d1` to the canonical intervention state;
- `d2` to whether integration may proceed;
- `d3` to whether the tag may be created;
- `d4` to whether the hosted release may be published;
- `d5` to the exact dependent effect blocked by the intervention; and
- `d6` to whether repository release authority alone authorizes that effect.

Return the registry case ID and those decisions. Use `summary` for the complete
labeled user-action checklist required by the supplied contract.
