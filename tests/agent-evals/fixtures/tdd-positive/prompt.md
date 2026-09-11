Read the complete TDD and repository-quality context under `{context_root}` and
fix the existing slug helper under `{fixture_root}` so repeated whitespace
becomes one hyphen. The failing `test_slugify.sh` is the executable contract.
Run it before and after the smallest implementation change. Change only
`slugify.sh` as production behavior. Retain the generated `.tdd-cycle` after
the green run as evaluation evidence; that test artifact is an expected
mutation, not an additional implementation change.

In `decisions`, set:

- `d1` to whether the same `test_slugify.sh` failed for the expected behavior
  before the change and passed after it;
- `d2` to whether the existing function was preserved and edited rather than
  deleted and recreated; and
- `d3` to whether only the requested behavior was changed.

Return the registry case ID, those decisions, and a concise evidence summary.
