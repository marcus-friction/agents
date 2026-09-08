---
name: performance-review
description: Review performance risks in affected adopted components using measured behavior and project evidence.
---

# Performance Review

Use during a scoped review when runtime cost, capacity, latency, or resource use
can change. Otherwise mark this pass not applicable with a reason.

## Preflight

Identify the affected runtime, expected workload, material data size, latency or
capacity objective, and available measurements. Apply framework checks only to
adopted components. Do not demand caches, queues, indexes, CDNs, or monitoring
because they appear on a generic checklist.

## Data and backend

When a data-backed service is affected:

- Look for N+1 access, repeated calls in loops, unbounded result sets, missing
  batching, avoidable serialization, and transaction scopes that hold scarce
  resources longer than the use case requires.
- Recommend pagination or streaming when observed or plausible cardinality
  warrants it; a deliberately small bounded set may remain a list.
- Recommend an index when an actual query/filter/order pattern and data size
  justify its write and storage cost.
- Keep API contracts separate from persistence entities to prevent accidental
  graph loading.
- Move slow work off a request only when response objectives or reliability
  require it. Choose an adopted executor or queue rather than inventing one.
- In Laravel, inspect Eloquent relationship access for missing eager loading,
  prefer `loadCount()` or `loadExists()` when only aggregate state is needed,
  and use `chunk()`, `lazy()`, `upsert()`, or batched inserts for justified bulk
  work. Do not require these APIs when the result is proven small and bounded.
- Keep queued Laravel job payloads narrow and reload authoritative state in the
  handler when staleness or serialization size matters.

## Caching

Treat caching as a response to measured cost or an explicit availability need.
Before recommending it, identify the source of truth, key, freshness contract,
invalidation owner, stampede behavior, capacity, and failure mode. Prefer the
smallest tier that meets the requirement; “no cache” is valid.

For an adopted Laravel cache, account for bare `null` results, stampedes, and
invalidation. Use a DTO or sentinel where `Cache::remember()` would otherwise
recompute a legitimate null result. Keep Redis databases for default, cache,
session, and queue isolated when the project uses the documented topology.

## Frontend

For affected interfaces:

- Preserve Nuxt SSR and keep client-only boundaries as small as the interaction
  allows.
- Measure bundle or route impact before adding a large dependency.
- Use `<NuxtImg>` or the adopted image primitive when it benefits real content;
  do not reject native images used for valid asset or rendering reasons.
- Check request waterfalls, payload size, rendering churn, layout stability, and
  caching behavior against user-visible outcomes.
- Prefer `useFetch` or `useAsyncData` for initial SSR data, with stable keys and
  cache behavior where reuse matters. Select server or client fetching from
  freshness, interaction, SEO, and trust boundaries, not a universal rule.
- Inspect watchers, computed state, Pinia subscriptions, lazy components, and
  Nuxt `routeRules` only where the changed flow can affect rendering or request
  cost.

## Infrastructure

Check compression, connection pools, HTTP caching, CDN behavior, and autoscaling
only at components that own those controls and only where load or exposure makes
them relevant. Verified ingress controls count; do not require duplicates.

For Laravel/Nuxt deployments, distinguish browser and shared-cache policy,
prevent authenticated or `Set-Cookie` responses from being cached publicly, and
verify Cloudflare, Forge, PM2, and immutable `/_nuxt/` behavior only when those
components are adopted.

## Findings

Cite evidence or label the claim as a hypothesis requiring measurement. Report
the affected workload, realistic consequence, expected benefit, tradeoff,
smallest correction, and benchmark or observation that would verify it. Avoid
arbitrary line, query, payload, or duration thresholds without project evidence.
