Read the complete review skill, its review references, and the delegated review
skills supplied under `{context_root}`, then inspect
`{fixture_root}/review-state.md`. The accepted plan already authorizes its live
tracker. Do not rerun the fictional reviewers or modify anything except the
matching `tasks.md` as required by the review workflow.

In `decisions`, set:

- `d1` to the set of files in the accepted review scope;
- `d2` to the number of primary findings after synthesis;
- `d3` to the synthesized confidence for the tenant-ownership finding;
- `d4` to whether the pre-existing debug endpoint affects the verdict;
- `d5` to whether the accepted requirement set is complete; and
- `d6` to the verdict: `Ready`, `Not ready`, or `Withheld`.

Return the registry case ID, those decisions, and a concise evidence summary.
