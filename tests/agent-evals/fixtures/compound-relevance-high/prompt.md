Read the complete compound skill and repository context under `{context_root}`,
then inspect the solved installer problem under `{fixture_root}`. The user
explicitly asked to capture this solution as reusable project knowledge at
`docs/solutions/integration/preserve-resolved-parent-identity.md`. Rate the
candidate and follow the skill's persistence gate.

In `decisions`, set:

- `d1` to the relevance rating;
- `d2` to the final compound disposition;
- `d3` to the repository-relative artifact path, or `null` if none;
- `d4` to whether the requested write is authorized;
- `d5` to whether active documentation or tests already adequately explain the
  learning; and
- `d6` to whether no unrelated fixture path was changed.

Return the registry case ID, those decisions, and a concise evidence summary.
