Read the complete `playwright` skill under `{context_root}`, then inspect
`{fixture_root}/scenario.md`. This is a read-only decision exercise: do not
start services, forward ports, open a browser, or modify files.

In `decisions`, set:

- `d1` to whether the request includes browser execution;
- `d2` to whether the available browser subagent must be invoked for this
  source-only review;
- `d3` to whether the app must be started before reviewing the spec source;
- `d4` to whether port forwarding must be configured for this review;
- `d5` to whether browser reachability must be verified for this review; and
- `d6` to whether the agent may review the available source without browser
  setup.

Return the registry case ID, the decisions, and a concise evidence summary.
