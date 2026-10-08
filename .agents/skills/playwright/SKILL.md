---
name: playwright
description: Apply when writing, reviewing, or debugging Playwright tests, fixtures, or configuration. Use as the browser-testing method layer for end-to-end work, with stable locators, isolated data, and web-first assertions.
---

# Playwright Standards

## Read the existing harness

Inspect the existing Playwright config, projects, fixtures, authentication
setup, `baseURL`, data helpers, and locator conventions. Reuse valid project
infrastructure and run against the explicitly supplied or project-configured
environment; do not invent a deployment target.

## Prepare browser execution

When executing a Playwright browser test, use a browser-capable subagent whenever
one is available. The orchestrating agent must first ensure the application and
required local services are running and ready.

If a browser-capable subagent is available, configure the active tool's port
forwarding for remote services when needed, then confirm that the subagent's
browser can open the target URL before running a spec or interactive test flow. A
host-local `localhost` request or configured `baseURL` alone is not proof of
subagent access. If the target remains unreachable, resolve readiness or
forwarding within the authorized scope or report the browser run as blocked;
do not switch to the host harness merely because forwarding failed.

If no browser-capable subagent is available, verify the target is ready from
the host browser and use the host browser harness. Do not expose a service
publicly merely to make it reachable. Writing or reviewing test source without
browser execution does not require this handoff.

## Select elements by contract

Prefer accessible semantic locators that match how a user perceives the page:
`getByRole` with an accessible name, `getByLabel`, and then text or placeholder
where appropriate. Existing stable test IDs are valid when repository evidence
establishes them as the convention or translated and repeated content has no
stable semantic discriminator.

For localized applications, derive accessible names from the locale or catalog
the test exercises. When repeated matches are legitimate, scope to a stable
parent rather than relying on position.

Structural CSS, XPath, generated IDs, and positional selectors are a last resort
when no user-facing or explicit stable contract exists, such as
unchangeable third-party or canvas markup. Scope the fallback tightly, choose
the least volatile attribute, and document why a semantic or test-ID locator
is unavailable. Do not add test IDs to production markup solely under
test-only authority; a production change requires its own authorization.

## Flow, isolation, and evidence

- Seed only the data the flow requires. Clean up only a proven
  disposable, test-owned scope; preserve pre-existing or shared records and
  report retained fixture data when ownership cannot be verified.
- Rely on Playwright auto-waiting and web-first assertions such as
  `expect(locator).toBeVisible()` instead of fixed sleeps.
- Assert the meaningful state transition after an interaction, not every
  implementation detail along the way.
- Follow the project's trace, screenshot, video, retry, and parallelism policy.
  `trace: 'on-first-retry'` is a useful default when no stricter convention
  exists.

Run the narrowest affected project or spec first, then the relevant browser
matrix. When a failure depends on the environment, retain the trace and report
the observed boundary instead of weakening the assertion.
