Read the complete security-review and architecture context under
`{context_root}`, then inspect `{fixture_root}/boundaries.md`. This is a
report-only review. Do not modify files.

In `decisions`, set:

- `d1` to whether the static site requires application authentication;
- `d2` to whether the static site requires database authorization checks;
- `d3` to whether the local-only prototype requires public-edge controls;
- `d4` to whether the Nuxt-only product requires Laravel authorization;
- `d5` to whether application code must duplicate verified ingress headers; and
- `d6` to whether the disposable store requires backup.

Return the registry case ID, those decisions, and a concise evidence summary.
