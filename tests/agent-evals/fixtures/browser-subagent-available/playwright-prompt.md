Read the complete `playwright` skill under `{context_root}`, then inspect
`{fixture_root}/scenario.md`. This is a read-only decision exercise: do not
start services, forward ports, open a browser, or modify files.

In `decisions`, set:

- `d1` to the browser executor to select: `subagent` or `host`;
- `d2` to whether the orchestrating agent must start the app and wait for
  readiness before browser testing;
- `d3` to whether the active tool's private port forwarding is needed before
  this subagent can reach the app;
- `d4` to whether the subagent's browser must open the target URL before the
  cart flow begins;
- `d5` to whether the cart flow may begin immediately in the stopped state; and
- `d6` to whether the app may be exposed publicly to avoid forwarding.

Return the registry case ID, the decisions, and a concise evidence summary.
