# What-If Matrix

Adversarial scenarios to apply during Red Team review. For each, ask: "What happens if..."

## Concurrency & Race Conditions
Race conditions cause silent data corruption — the most dangerous class of bug because they pass all tests.

1. **Simultaneous writes:** Two users update the same record at the same time. Does the second write silently overwrite the first?
2. **Double submission:** User clicks submit twice quickly. Does it create duplicate records?
3. **Queue race:** Two workers pick up the same job simultaneously. Does the system handle idempotency?
4. **Optimistic locking gap:** Record is read, modified in memory, then saved — but another process changed it in between.

## Trust Boundaries
Server-side must always be the source of truth — never trust client input.

5. **Frontend validation bypass:** Malicious user sends a raw API request skipping all frontend validation. Does the server reject it?
6. **Authorization escalation:** User modifies a resource ID in the URL/payload to access another user's data.
7. **Mass assignment:** User sends extra fields in a POST/PUT body that aren't in the form. Does the server accept them?
8. **Token replay:** Expired or revoked token is reused. Does the system reject it?

## Infrastructure Failures
Systems fail — the question is whether they fail gracefully or catastrophically.

9. **Database lock:** Long-running transaction locks a table. Do other requests queue or timeout gracefully?
10. **Third-party API timeout:** External service responds after 30 seconds instead of 200ms. Does the request hang the user?
11. **Redis unavailable:** Cache layer goes down. Does the app serve stale data, error, or degrade gracefully?
12. **Disk full:** Storage fills up. Do uploads fail with a clear error or silently corrupt?

## Deployment & Migration Race
Zero-downtime requires backward compatibility during the transition window.

13. **Schema migration mid-deploy:** New code expects a column that old code doesn't have. Do both versions coexist safely?
14. **Feature flag inconsistency:** Feature is enabled for some users but the database migration hasn't run yet.
15. **Rollback safety:** If this deployment is rolled back, does the previous version still work with the current database state?

## Data Integrity & Edge Cases
The "impossible" inputs that eventually arrive in production.

16. **Null/empty input:** Every nullable field receives null. Does the system handle it or crash?
17. **Extreme length:** A field receives 10,000 characters. Does validation catch it before hitting the database?
18. **Unicode/emoji:** Names, descriptions, and search queries contain emoji, RTL text, or zero-width characters.
19. **Clock skew:** Server clocks are 5 minutes apart. Do time-based comparisons (token expiry, rate limiting) still work?
20. **Orphaned references:** A related record is deleted. Do foreign key constraints catch it, or does the system show a broken page?

> Sourced from [garrytan/gstack](https://github.com/garrytan/gstack) review patterns, adapted for this ecosystem.
