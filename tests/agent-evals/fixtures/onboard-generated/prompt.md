Read the complete onboard-project, document-reconciliation, and change-rigor
context under `{context_root}`. Perform the user's bounded durable onboarding of
the repository under `{fixture_root}`. Add the exact line
`Verification: npm test` to the maintained README content. Inspect provenance
before editing; the generated `README.md` must remain unchanged. Do not create a
plan or unrelated documents.

This fixture is intentionally not a Git working tree. Do not invoke Git or seek
repository history. The generated-file provenance is fully established by the
leading `README.md` comment, the `package.json` docs command, and
`scripts/render-readme.js`; inspect those files and the target file types
directly once, then perform and verify the bounded source edit.

In `decisions`, set:

- `d1` to the path that should be changed;
- `d2` to whether `README.md` is generated output;
- `d3` to whether `README.md` should be edited directly;
- `d4` to whether document-reconciliation is required;
- `d5` to the number of extra approval decisions required for the ordinary
  authoring-source edit; and
- `d6` to whether an implementation plan should be created.

Return the registry case ID, those decisions, and a concise evidence summary.
