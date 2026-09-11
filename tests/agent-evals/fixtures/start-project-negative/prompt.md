Read the complete start-project, onboard-project, and change-rigor context under
`{context_root}`. Inspect the fixture under `{fixture_root}`. This is a report-only
request: do not modify anything and do not ask follow-up questions.

Apply only the documented workflow to an existing README that contains local
decisions and uncommitted owner edits and may be a symlink. In `decisions`, set:

- `d1` to whether that README requires document reconciliation before any write;
- `d2` to whether its existing semantics must be preserved;
- `d3` to the number of extra project-document approval decisions for ordinary
  in-scope editing;
- `d4` to the number of exact decisions for an elevated effect; and
- `d5` to whether relevant target state is checked again immediately before
  apply; and
- `d6` to whether a start-project request alone authorizes a broader
  `update-agents` distribution refresh.

Return the registry case ID, those decisions, and a concise evidence summary.
