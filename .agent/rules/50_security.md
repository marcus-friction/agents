---
trigger: model_decision
description: Apply when writing, reviewing, or modifying code that handles user input, authentication, authorization, secrets, API keys, file uploads, or data access.
---

# Security

## Core Principles & Environment
- **Never trust input.** Validate at the boundary, authorize at the resource, escape at the output. Enforce Least Privilege.
- **Secrets:** Store in `.env` only (never commit). Use `config()` in Laravel, never `env()` in code. In Nuxt, use private `runtimeConfig` (public only for safe values).

## Infrastructure & Dependencies
- Audit packages (`composer audit`, `npm audit`). Pin major versions.
- **Headers:** HTTPS everywhere. Set Strict-Transport-Security, X-Frame-Options: DENY, X-Content-Type-Options: nosniff, CSP, and Referrer-Policy: strict-origin-when-cross-origin.
- **Logging:** Log auth failures and permission denials. Never log passwords, API keys, or PII. Use structured JSON formatting in production.

## Laravel Security
- **Mass Assignment:** Always define `$fillable`. Do not use `$guarded = []`.
- **Validation:** Always pass `$request->validated()` to domain logic (never `$request->all()`).
- **SQLi:** Use Eloquent/Query Builder. If raw SQL is needed, use parameter bindings strictly.
- **XSS & CSRF:** Blade `{{ }}` auto-escapes. Never use `{!! !!}` with user content unless sanitized. Enforce `@csrf` on forms/AJAX headers.
- **SSRF & HTTP:** When fetching user-provided URLs (like scraped images), never rely on `gethostbyname()` (IPv4 only). Use `dns_get_record($host, DNS_A | DNS_AAAA)` and bind the validated IP to cURL via `CURLOPT_RESOLVE` to prevent DNS Rebinding (TOCTOU).
- **Auth & Roles:** Use Sanctum (API) / Filament (Admin). Use Policy classes for authorization (call `$this->authorize()`), never inline in controllers. Do not trust client-side role claims.
- **Access Limits:** Use `throttle` middleware for auth, APIs, and expensive routes. 
- **Passwords & Files:** Use `Hash::make()`. Validate all file uploads (type, size, extension), generate safe filenames server-side, and store outside the web root.

## Nuxt Security
- **XSS:** Vue `{{ }}` auto-escapes. Never use `v-html` with user content.
- **API Proxies:** Never expose secret keys client-side. Proxy third-party calls via `server/api/`.
- **SSR Isolation:** Use `useState` for reactive state. Never use mutable module-level variables in SSR contexts to prevent cross-request leakage.
- **CSP:** Configure via Nuxt server middleware or Nitro.
