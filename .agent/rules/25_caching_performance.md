---
trigger: model_decision
description: Apply when writing, reviewing, or modifying code that involves caching, performance optimization, Redis usage, HTTP response headers, or CDN configuration.
---

# Caching & Performance

## Caching Hierarchy

Apply caching at the right layer — each level serves a different purpose:

```
OPcache (PHP bytecode) → Application Cache (Redis) → HTTP Cache (headers) → CDN (Cloudflare) → Browser Cache
```

- **OPcache**: Automatic in production — no application code needed.
- **Application Cache**: `Cache::remember()` / `Cache::flexible()` for expensive queries and computations.
- **HTTP Cache**: `Cache-Control` headers on API responses for browser and CDN caching.
- **CDN**: Cloudflare Cache Rules for edge caching of static and semi-static content.
- **Browser**: Controlled by `Cache-Control` and `immutable` headers.

## Laravel Application Caching

### When to Cache

Cache data that is **expensive to compute** and **accessed frequently**. Do not cache everything — over-caching wastes memory and adds invalidation complexity.

Good candidates:
- Database aggregations, complex joins, filtered listings
- External API responses
- Computed values used across requests (nav menus, category trees, settings)

Skip caching for:
- Simple Eloquent lookups on indexed columns
- Data that changes on every request
- Authenticated, user-specific responses (unless carefully scoped)

### Cache Methods

| Method | When | Behavior |
|--------|------|----------|
| `Cache::remember($key, $ttl, $fn)` | Standard expensive operations | Checks cache → returns or executes closure and stores |
| `Cache::flexible($key, [$fresh, $stale], $fn)` | High-traffic endpoints | Serves stale instantly, regenerates in background |
| `Cache::forever($key, $value)` | Near-static data | Persists until `Cache::forget()` — requires versioning or deploy-time flush |
| `Cache::put($key, $value, $ttl)` | Explicit overwrite | Stores unconditionally |

> **Pitfall:** `Cache::remember()` treats `null` returns as cache misses. If `null` is a valid value, wrap in a DTO or use a sentinel value.

### Tagged Caching

Group related items for collective invalidation. Requires Redis (our standard driver).

```php
// Store
Cache::tags(['brands'])->remember("brand:{$id}", 3600, fn () => Brand::find($id));

// Invalidate all brands on mutation
Cache::tags(['brands'])->flush();
```

### TTL Strategy

| Data Type | TTL | Examples |
|-----------|-----|----------|
| Static / config | `forever` or 24h+ | Site settings, enum lists, nav menus |
| Semi-static | 1–4 hours | Product details, category lists, CMS pages |
| Dynamic | 5–30 minutes | Search results, filtered lists, dashboards |
| Volatile / user-specific | 1–5 minutes or skip | Cart totals, personalized feeds |

**Cache key versioning for `forever` items:** Bump the key version on schema changes (`"brands:v2:list"`) or flush tagged groups on deploy.

### Cache Invalidation

Use in order of preference:

1. **Event-driven**: Model observer or event listener flushes cache on create/update/delete.
2. **Tag-based**: `Cache::tags(['posts'])->flush()` clears all related entries.
3. **Key-based**: `Cache::forget("post:{$id}")` for surgical removal.
4. **TTL-only**: Let it expire — acceptable for eventually-consistent, non-critical data.

### Cache Warming

Schedule warming for expensive queries that power high-traffic pages:

```php
// routes/console.php
Schedule::command('cache:warm-homepage')->hourly()->withoutOverlapping();
```

## Redis Architecture

### Separate Connections

Isolate cache, session, and queue in `config/database.php` using separate Redis databases:

| Connection | DB | Purpose |
|------------|-----|---------|
| `default` | 0 | General application use |
| `cache` | 1 | Application cache |
| `session` | 2 | Session storage |
| `queue` | 3 | Queue jobs |

**Why:** `FLUSHDB` on the cache DB won't wipe sessions or queued jobs.

### Key Naming Convention

Use hierarchical colon-separated keys:

```
{entity}:{id}:{attribute}
```

Examples: `brand:42:details`, `brands:list:page:1`, `stats:homepage:daily`

### Memory Management

- Set `maxmemory` and `maxmemory-policy` in Redis config. Recommend `allkeys-lru` for cache databases.
- Keep queue job payloads small — pass IDs, fetch data in `handle()`.
- Monitor `evicted_keys` — a rising count signals memory pressure.

## HTTP Response Caching

### Cache-Control Headers

Apply via middleware, not per-controller:

| Endpoint Type | Header |
|---------------|--------|
| Public GET, anonymous | `public, max-age=3600, s-maxage=86400` |
| Authenticated responses | `private, max-age=300` |
| Sensitive / mutation | `no-store` |
| Public with SWR | `public, max-age=60, stale-while-revalidate=300` |

> **Set-Cookie hazard:** Laravel's `web` middleware adds `Set-Cookie`, which makes Cloudflare skip caching entirely. Our decoupled API pattern avoids this (API routes use `api` middleware group). If Laravel ever serves cacheable HTML directly, use a stateless middleware group.

## Nuxt SSR Caching

### Route-Level Caching (`routeRules`)

Configure in `nuxt.config.ts` — processed by Nitro:

| Strategy | Config | Best For |
|----------|--------|----------|
| Prerender | `prerender: true` | Static pages (about, legal) |
| ISR | `isr: 3600` | Blog, product listings — cached, regenerated after TTL |
| SWR | `swr: 600` | Catalog, search — serves stale, revalidates in background |
| SSR | `ssr: true` | Authenticated dashboards — fresh every request |

### Client-Side Caching (`getCachedData`)

Prevent redundant API calls on client navigation:

```typescript
const { data } = useFetch('/api/brands', {
  key: 'brands',
  getCachedData(key, nuxtApp) {
    return nuxtApp.payload.data[key] || nuxtApp.static.data[key]
  },
})
```

### Data Fetching Rules

- **Use `useFetch` / `useAsyncData`** — never raw `fetch()` in lifecycle hooks.
- **Key your requests** — same key = shared state across components (deduplication).
- **SSR for SEO data**, client-only for interactive data.

## Cloudflare CDN

### What to Cache

| Content | Cache? | Mechanism |
|---------|--------|-----------|
| Static assets (JS, CSS, fonts, images) | ✅ | Automatic by extension |
| Prerendered / ISR pages | ✅ | `Cache-Control` from Nitro |
| Anonymous API GET responses | Selectively | Cache Rule + response headers |
| Authenticated API responses | ❌ | `Cache-Control: private, no-store` |

### Cache Rules

Use Cloudflare **Cache Rules** (not deprecated Page Rules):

1. **Static assets** (`/_nuxt/*`): Cache Everything, Edge TTL 30 days, Browser TTL 1 year
2. **SSR pages** (anonymous): Respect Origin headers
3. **API routes** (`/api/*`): Bypass Cache — let application headers govern
4. **Admin / auth routes**: Bypass Cache

### Cache Purging

- **Purge by URL**: Single content update.
- **Purge by Cache-Tag**: Related content group.
- **Purge Everything**: Deployment only — use sparingly.
- Automate purging in deployment scripts via Cloudflare API.

## Frontend Assets

- Vite content hashing (`app.DfX4k2.js`) guarantees unique URLs per build.
- Serve `/_nuxt/*` with `Cache-Control: public, max-age=31536000, immutable`.
- `immutable` tells browsers to never revalidate — the hash is the version.
- Use `<NuxtImg>` for image optimization.

## Production Deploy Checklist

Run in deployment scripts:

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

### Monitoring

| Metric | Tool | Alert On |
|--------|------|----------|
| Cache hit rate | Pulse / Telescope | Below 80% |
| Redis memory | Horizon / `INFO` | Above 80% capacity |
| Evicted keys | Redis `INFO stats` | Rising trend |
| Queue latency | Horizon | Jobs waiting > 30s |
| TTFB | Cloudflare Analytics | Above 500ms |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| `Cache::forever()` without invalidation | Stale data after schema changes | Version keys or tag-flush on deploy |
| Caching authenticated responses as `public` | Data leaks between users | Use `private` or `no-store` |
| `Cache::remember()` with `null` return | Infinite re-computation | Wrap in DTO or use sentinel |
| No TTL on `Cache::put()` | Unbounded memory growth | Always set explicit TTL |
| Cloudflare caching routes with `Set-Cookie` | Cloudflare silently skips caching | Use stateless middleware group |
| `Cache::tags()` with `file` driver | Runtime exception | Enforce Redis driver |
| Raw `fetch()` in Nuxt components | No SSR deduplication, no caching | Use `useFetch` / `useAsyncData` |
| Missing `key` on `useFetch` | Cache collisions, stale data | Always provide explicit key |
