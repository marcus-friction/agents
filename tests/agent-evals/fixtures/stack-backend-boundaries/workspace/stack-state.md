# Backend stack state

The project adopts PHP 8.4, Laravel 13, Nitro 3, PostgreSQL 17, and Vitest 5.
Laravel owns accounts and provider deliveries. Nitro provides the web-facing
BFF. No new package or persistence system is part of this increment.

The proposed increment has three parts:

1. Add a quote endpoint whose nested line-item rules are reused by create and
   preview flows. Laravel owns the protected account and authorization rule.
2. Consume a provider webhook through a queued job. The provider supplies a
   stable delivery ID. Concurrent delivery and retry can outlive a queue lock,
   so the database side effect needs durable idempotency as well as any
   `ShouldBeUnique` optimization.
3. Proxy the authenticated account response through Nitro. The payload is
   personalized and must not be stored in a shared public SWR cache.
4. Keep transport validation and authorization at the owning server boundary;
   browser validation is user experience, not an authorization control.

Vitest covers the Nitro handler contract without changing Laravel ownership.
