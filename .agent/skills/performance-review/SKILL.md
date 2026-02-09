---
name: performance-review
description: Performance analysis checklist for code review
---

# Performance Review Skill

Systematic performance analysis for code changes. Use during the performance pass of `/review` or when optimizing.

## Checklist

### Backend — Database

- [ ] **N+1 queries**: All relationship access uses eager loading (`with()`, `load()`)
- [ ] **Query count**: Use `DB::enableQueryLog()` or Telescope to verify query count per request
- [ ] **Missing indexes**: New `WHERE`, `ORDER BY`, or `JOIN` columns have indexes
- [ ] **Unnecessary queries**: No DB calls inside loops — batch or collect first
- [ ] **Pagination**: Large result sets use `paginate()` or `cursorPaginate()` — never `all()`
- [ ] **Select specifics**: Use `select()` when only a few columns are needed
- [ ] **Chunk processing**: Large datasets processed with `chunk()` or `lazy()` — never load all into memory

### Backend — Application

- [ ] **Caching**: Expensive computations or slow queries cached with appropriate TTL
- [ ] **Cache invalidation**: Cache cleared on data mutation — no stale data
- [ ] **Queue offloading**: Slow operations (email, PDF, API calls) dispatched to queues — not inline
- [ ] **Serialization**: API Resources aren't loading unnecessary relationships
- [ ] **Middleware**: No expensive operations in globally-applied middleware

### Frontend — Rendering

- [ ] **Lazy loading**: Below-fold components use `<Lazy>` prefix or dynamic imports
- [ ] **Image optimization**: Images use `<NuxtImg>` with appropriate sizes/formats
- [ ] **Component reactivity**: No unnecessary re-renders from poorly-scoped watchers
- [ ] **Bundle size**: No large libraries imported for small features

### Frontend — Data Fetching

- [ ] **useFetch/useAsyncData**: Data-fetching composables used — no raw `fetch()` in lifecycle hooks
- [ ] **Deduplication**: Same data not fetched multiple times (key your requests)
- [ ] **Payload optimization**: API responses contain only needed fields
- [ ] **SSR vs Client**: Data needed for SEO/initial render fetched on server; interactive data can be client-side

### Infrastructure

- [ ] **CDN**: Static assets served through Cloudflare
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
