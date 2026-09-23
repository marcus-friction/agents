# Review table output

Change the `review` and `adversarial-review` report contracts from bulleted
results to Markdown tables. This is a formatting-only R1 repository change: it
does not alter review scope, authority, finding classification, tracker writes,
or verdict rules.

## Scope and acceptance

- Update both skill report sections to require table output for findings,
  supporting results, and the final verdict or recommendation.
- Preserve every currently required finding attribute, coverage disclosure,
  tracker status, and verdict condition.
- Define an explicit no-findings table row so successful reviews keep the same
  tabular shape.
- Extend the existing deterministic skill-contract checks to protect the table
  requirement without adding a separate prose-test harness.
- Validate both skill structures, targeted contracts, whitespace, and the full
  offline repository suite.

No dependencies, runtime behavior, external services, publication, or unrelated
skills are in scope. If validation exposes an unrelated failure, record it
without expanding this change.

## Execution

1. Record the accepted formatting contract in this plan and its task tracker.
2. Replace each skill's bulleted report contract with explicit Markdown table
   schemas while retaining its existing semantics.
3. Add narrow assertions to the existing review and adversarial-review contract
   tests.
4. Run targeted and full validation, inspect the final diff, and update the
   tracker with verified results before handoff.

Recovery is a normal Git revert of these scoped documentation and contract-test
edits. No irreversible effect is authorized or required.

## Amendment — 2026-09-23: align both table schemas

The user requested strict consistency after reviewing the first table versions.
Use the clearer structure for each conflict: separate `ID` and `Severity`, one
compact eight-column Findings table shared by both skills, the existing shared
Results table, and a neutral `Decision | Basis` table with code-formatted decision
values. Preserve skill-specific finding details as labeled content within the
shared columns. This remains a formatting-only refinement with no authority,
classification, tracking, or decision-rule change.
