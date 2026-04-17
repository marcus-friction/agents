---
name: performance-review
description: Performance analysis checklist for code review
---

# Performance Review Skill

Systematic performance analysis for code changes. Use during the performance pass of `/review` or when optimizing. See `25_caching_performance.md` rule for implementation standards.

## Checklist

### Backend — Database

- [ ] **N+1 queries**: All relationship access uses eager loading (`with()`, `load()`)
- [ ] **Query count**: Use `DB::enableQueryLog()` or Telescope to verify query count per request
- [ ] **Missing indexes**: New `WHERE`, `ORDER BY`, or `JOIN` columns have indexes
- [ ] **Unnecessary queries**: No DB calls inside loops — batch or collect first
- [ ] **Pagination**: Large result sets use `paginate()` or `cursorPaginate()` — never `all()`
- [ ] **Select specifics**: Use `select()` when only a few columns are needed
- [ ] **Chunk processing**: Large datasets processed with `chunk()` or `lazy()` — never load all into memory

### Backend — Caching

- [ ] **Cache appropriateness**: Expensive computations or slow queries cached with appropriate TTL
- [ ] **Method choice**: High-traffic endpoints use `Cache::flexible()` (SWR); standard queries use `Cache::remember()`
- [ ] **Tagged caching**: Related cache entries grouped with tags for collective invalidation
- [ ] **Cache invalidation**: Cache cleared on data mutation — no stale data risk
- [ ] **Event-driven invalidation**: Model observers or event listeners handle invalidation, not manual `forget()` scattered through code
- [ ] **TTL alignment**: TTL matches data volatility (see tiered strategy in `25_caching_performance.md`)
- [ ] **Null handling**: `Cache::remember()` closures don't return bare `null` (treated as cache miss)
- [ ] **Key naming**: Cache keys follow `entity:id:attribute` convention — descriptive and hierarchical

### Backend — Application

- [ ] **Queue offloading**: Slow operations (email, PDF, API calls) dispatched to queues — not inline
- [ ] **Serialization**: API Resources aren't loading unnecessary relationships
- [ ] **Middleware**: No expensive operations in globally-applied middleware
- [ ] **Job payloads**: Queue jobs pass IDs, not full models — data fetched in `handle()`

### Backend — Redis

- [ ] **Connection isolation**: Cache, session, and queue use separate Redis databases (not all on DB 0)
- [ ] **Memory awareness**: No unbounded `Cache::forever()` without versioning or deploy-time flush
- [ ] **Tag cleanup**: Tagged cache sets monitored — they grow even when individual items have TTL

### Frontend — Rendering

- [ ] **Lazy loading**: Below-fold components use `<Lazy>` prefix or dynamic imports
- [ ] **Image optimization**: Images use `<NuxtImg>` with appropriate sizes/formats
- [ ] **Component reactivity**: No unnecessary re-renders from poorly-scoped watchers
- [ ] **Bundle size**: No large libraries imported for small features

### Frontend — Data Fetching & Caching

- [ ] **useFetch/useAsyncData**: Data-fetching composables used — no raw `fetch()` in lifecycle hooks
- [ ] **Deduplication**: Same data not fetched multiple times (key your requests)
- [ ] **getCachedData**: Navigation-heavy pages use `getCachedData` to prevent redundant API calls
- [ ] **Payload optimization**: API responses contain only needed fields
- [ ] **SSR vs Client**: Data needed for SEO/initial render fetched on server; interactive data can be client-side
- [ ] **routeRules**: Appropriate caching strategy set per route (prerender/ISR/SWR/SSR)

### Infrastructure — HTTP & CDN

- [ ] **Cache-Control headers**: API responses include appropriate directives (`public`/`private`/`no-store`)
- [ ] **s-maxage**: CDN edge TTL set independently from browser TTL where needed
- [ ] **Set-Cookie check**: Cacheable responses don't include `Set-Cookie` headers (blocks Cloudflare caching)
- [ ] **Cloudflare Cache Rules**: Static assets and SSR pages configured in Cache Rules (not deprecated Page Rules)
- [ ] **Asset immutability**: `/_nuxt/*` served with `Cache-Control: public, max-age=31536000, immutable`
- [ ] **Compression**: Responses gzipped/brotli compressed
- [ ] **Connection pooling**: Database connections not exhausted under load

## Red Flags

These patterns almost always indicate a performance problem:

| Pattern | Issue | Fix |
|---------|-------|-----|
| `Model::all()` | Loads entire table | `paginate()` or scoped query |
| `foreach ($items as $item) { $item->relation }` | N+1 | `$items->load('relation')` |
| `DB::` inside a loop | Repeated queries | Batch query before the loop |
| `sleep()` in request | Blocks worker | Queue job |
| `file_get_contents()` for URLs | No timeout, blocking | HTTP client with timeout, or queue |
| `Cache::forever()` without invalidation | Stale data after changes | Version keys or tag-flush on deploy |
| `Cache::remember()` returning `null` | Infinite re-computation | Wrap in DTO or sentinel |
| Caching with `public` on auth responses | Data leaks between users | `private` or `no-store` |
| `Cache::tags()` with `file` driver | Runtime exception | Enforce Redis driver |
| Raw `fetch()` in Nuxt lifecycle hooks | No SSR dedup, no caching | `useFetch` / `useAsyncData` |
| Missing `key` on `useFetch` | Cache collisions | Always set explicit key |
