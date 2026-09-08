Read the complete TDD and repository-quality context under `{context_root}` and
inspect the slug helper fixture under `{fixture_root}`. The requested behavior
change is to collapse repeated spaces into one separator. README.md is prose and
settings.conf declares a behavior-free unused value. This is a report-only
request; do not modify files.

In `decisions`, set:

- `d1` to whether the implementation should be deleted and recreated;
- `d2` to whether tests should be invented for README prose;
- `d3` to whether tests should be invented for the unused config; and
- `d4` to whether the coverage target is scoped to testable production behavior.

Return the registry case ID, those decisions, and a concise evidence summary.
