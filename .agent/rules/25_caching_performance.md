---
trigger: model_decision
description: Apply when writing, reviewing, or modifying code that involves caching, performance optimization, Redis usage, HTTP response headers, or CDN configuration.
---

# Caching & Performance

## Caching Strategy
- **Hierarchy:** OPcache (PHP) → Redis (App) → HTTP Headers → Cloudflare (CDN) → Browser.
- **Application Cache (Laravel):** Cache expensive/frequent queries, external API calls, and computed values. Do not cache simple indexed DB lookups.
  - Use `Cache::remember()`. *Warning: `null` returns bypass cache. Wrap in a DTO if `null` is valid.*
  - Use `Cache::tags()` (Redis) for grouping/invalidation. 
  - Invalidate via Events > Tags > Keys > TTL. Warm caches for high-traffic views.
- **TTLs:** Forever/24h+ (Static - use versioned keys `brands:v2:list`), 1-4h (Semi-static), 5-30m (Dynamic).
- **Middleware:** Any `share()` / `handle()` that queries the database must use `Cache::remember()`. Pair every cached model with `FlushCacheObserver` registration. Use namespaced keys matching invalidation scope (e.g., `translations:{locale}`).
- **Observer Efficiency:** Cache invalidation observers must not query the database to build cache keys. Use the model's foreign keys directly (e.g., `Cache::forget("variant:{$vc->variant_id}")` not `Variant::find($vc->variant_id)`).

## Redis Architecture
- **Isolation:** Use separate DBs in `config/database.php` for `default` (0), `cache` (1), `session` (2), `queue` (3) to prevent `FLUSHDB` collateral damage.
- **Key Naming:** Use `{entity}:{id}:{attribute}` (e.g. `brand:42:details`).
- Set `maxmemory-policy` to `allkeys-lru` for the cache DB. Monitor `evicted_keys`. Keep queue payloads small.

## HTTP & CDN Caching
- **Headers:** Apply `Cache-Control` via middleware (`public, max-age=...` for open data, `private` or `no-store` for auth/mutations).
  - *Hazard:* Laravel's `web` middleware adds `Set-Cookie`, breaking CDN caching. Use stateless groups (e.g., `api`) for cacheable routes.
- **Cloudflare Rules:** Cache Static assets and SSR anonymous pages. Bypass `/api/*` and Admin routes. Purge via API (by URL/Tag).
- **Nuxt SSR:** Configure `routeRules` (`prerender`, `isr: 3600`, `swr: 600`, `ssr: true`). Use `getCachedData` in `useFetch` to prevent redundant client side calls. Key all requests for deduplication.
- **Assets:** Vite hashes guarantee uniqueness (`app.[hash].js`). Serve `/_nuxt/*` with `immutable` (+1 year max-age). Use `<NuxtImg>`.

## Production Checklist & Monitoring
- Run `artisan config:cache`, `route:cache`, `view:cache`, `event:cache` on deploy.
- Monitor Cache hit rate (>80%), Redis memory (<80%), Evicted keys, Queue latency (<30s), TTFB (<500ms).
