Read the complete TDD and repository-quality context under `{context_root}` and
inspect the slug helper fixture under `{fixture_root}`. The requested behavior
change is to collapse repeated spaces into one separator. README.md is prose and
settings.conf declares a behavior-free unused value. This is a report-only
request; do not modify files. Separately, sending a notification through an
external client is the accepted outbound boundary contract, including its
recipient and payload. A price component consumes only the schema-required
`amount` and `currency` fields from that external response.

In `decisions`, set:

- `d1` to whether the implementation should be deleted and recreated;
- `d2` to whether tests should be invented for README prose;
- `d3` to whether tests should be invented for the unused config; and
- `d4` to whether the coverage target is scoped to testable production behavior;
- `d5` to whether a test may verify the notification client's recipient and
  payload when dispatch is the observable boundary contract; and
- `d6` to whether a test double containing the schema-required `amount` and
  `currency` fields is sufficient for the price component without unrelated
  external response fields.

Return the registry case ID, those decisions, and a concise evidence summary.
