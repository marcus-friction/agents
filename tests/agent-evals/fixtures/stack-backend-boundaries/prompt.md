Read the complete Laravel, Nitro, and Vitest skills under
`{context_root}`, then inspect `{fixture_root}/stack-state.md`. This is a
read-only decision exercise. Do not modify files.

In `decisions`, set:

- `d1` to whether the meaningful, reusable quote input earns a Form Request;
- `d2` to whether the Laravel-owned account mutation should use a Policy or
  Gate at that resource boundary;
- `d3` to whether the provider delivery ID should back durable idempotency;
- `d4` to whether `ShouldBeUnique` alone proves the delivery can never be
  applied twice;
- `d5` to whether an authenticated Nitro account response may use shared
  public SWR caching; and
- `d6` to whether client-side validation alone authorizes a destructive
  account mutation.

Return the registry case ID, those decisions, and a concise evidence summary.
