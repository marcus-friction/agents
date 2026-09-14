# v1.7.2 — Keep plans and tasks current

Release date: 2026-09-14. Use the full commit SHA from the
[release record](https://github.com/marcus-friction/agents/releases/tag/v1.7.2)
with installer `--ref` for stable installation. `master` remains mutable.

AGENTS.md and its project template now require agents to:

- Update plans and task lists as work changes, before progress reports or handoff.
- Append dated plan amendments for extensions and add emerging tasks promptly.
- Track actual status, verify completion and report against task items,
  blockers and next steps.

Existing approval and read-only limits remain. Skills, the Laravel/Nuxt stack
and installer behavior are unchanged.

Updating an existing project does not overwrite its AGENTS.md. Reconcile the
new policy from the staged `.agents/templates/AGENTS.md` candidate to adopt it.
Offline checks validate document and policy contracts; live-agent compliance
evaluations were not performed.
