---
name: playwright
description: End-to-End browser testing standards, locators, and best practices for interacting with web interfaces safely.
---

# Playwright E2E Standards

## Element selection

Prefer accessible semantic locators that match how a user perceives the page:
`getByRole` with an accessible name, `getByLabel`, and then text or placeholder
where appropriate. This makes the test exercise the accessibility contract as
well as behavior.

Existing stable test IDs are also valid when repository evidence establishes
them as the project's convention or when translated or repeated content has no
stable semantic discriminator. Do not add test IDs to production markup solely
to satisfy a new test. If a new identifier is genuinely needed, treat the
production change separately from permission to test.

For localized applications, derive accessible names from the same locale or
catalog exercised by the test. Do not use an unnamed role when multiple matches
are possible.

**Forbidden:** structural CSS classes, generated IDs, nth-child selectors, or any locator coupled to layout.

When the repository already uses test IDs, follow its naming convention and
never style by them. Prefer a stable domain key over a positional index for
repeated rows.

## Testing Flow & Logic
- **Isolation**: Seed only the data the flow requires. Clean up only a proven
  disposable, test-owned scope; preserve pre-existing or shared records and
  report retained fixture data when ownership cannot be verified.
- **Action Verification**: Use standard auto-waiting assertions (e.g., `expect(locator).toBeVisible()`) after interactions to verify state transitions in the UI rather than hard-coded timeouts.
- **Tracing**: Leverage `trace: 'on-first-retry'` to assist with difficult CI failure diagnoses.
