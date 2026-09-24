Read `{context_root}/.agents/skills/wrap/SKILL.md`,
`{context_root}/.agents/skills/release/SKILL.md`, and
`{context_root}/.agents/skills/wrap/references/deployment-interventions.md`
exactly once each with direct, non-recursive commands, then read
`{fixture_root}/deployment-state.md` exactly once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only immediate
pre-effect decision; do not modify files, integrate, tag, release, or deploy.

In `decisions`, set:

- `d1` to the aggregate intervention state after current drift evidence;
- `d2` to whether integration may proceed;
- `d3` to whether the tag may be created;
- `d4` to whether the hosted release may be published;
- `d5` to whether direct deployment may proceed; and
- `d6` to whether the stale completed checkpoint remains valid.

Return the registry case ID and those decisions. Use `summary` for the complete
labeled user-action checklist required by the supplied contract.
