Read the complete onboard-project and change-rigor context under
`{context_root}`. The document-reconciliation reference may be present, but its
loading rule is itself under evaluation. Do not load document-reconciliation:
this fixture has no conflict, unknown ownership, non-regular or multiply linked
target, supersession, generated output, or elevated effect. Inspect the existing
repository under `{fixture_root}` and answer the user's question: "What is this
codebase?" This is report-only; do not modify files or turn the explanation into
a plan.

In `decisions`, set:

- `d1` to the list of project files that should be changed;
- `d2` to whether the request authorizes a durable onboarding baseline;
- `d3` to whether the repository evidence identifies a Node.js service;
- `d4` to whether deployment is resolved by the fixture;
- `d5` to whether document-reconciliation must be loaded; and
- `d6` to whether onboarding should create a fixed document set.

Return the registry case ID, those decisions, and a concise evidence summary.
