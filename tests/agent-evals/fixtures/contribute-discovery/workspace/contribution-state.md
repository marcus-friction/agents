# Contribution state

The user asked to prepare a contribution proposal for the changed `example`
skill and base template, but explicitly said not to publish.

Repository policy declares `.agents/skills/` and `project-templates/` as managed
distribution sources. Comparison with the named public upstream and base finds:

- `.agents/skills/example/SKILL.md`: changed, physical regular file, safe.
- `.agents/skills/example/README.md`: changed support file, physical and safe.
- `project-templates/base/AGENTS.md`: changed, physical and safe.
- `AGENTS.md`: changed but project-owned.
- `.agents/project/customer.md`: contains customer and credential material.
- `docs/solutions/internal-incident.md`: reusable local knowledge excluded by
  the contribution policy.

The repository license and authorship metadata affirm redistribution authority
for the three selected safe files. The user already named both candidate
groups. No publication batch has been previewed or approved.
