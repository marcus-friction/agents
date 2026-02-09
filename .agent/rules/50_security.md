---
trigger: model_decision
description: Apply when writing, reviewing, or modifying code that handles user input, authentication, authorization, secrets, API keys, file uploads, or data access.
---

# Security

## Core Principles

- **Never trust input.** All user input is hostile until validated. Frontend validation is UX — backend validation is security.
- **Principle of least privilege.** Users, API keys, database users, and service accounts get the minimum permissions required.
- **Defense in depth.** Validate at the boundary, authorize at the resource, escape at output.

## Secrets & Environment

- Secrets live in `.env` only — never in code, config files, or version control.
- `.env.example` contains placeholder values, never real credentials.
- `.env` is in `.gitignore`. No exceptions.
- Never log, dump, or expose secrets in error responses.
- **Laravel:** never use `env()` outside config files — always `config()`. Keep `APP_DEBUG=false` in production.
- **Nuxt:** private `runtimeConfig` (server-only) for secret keys. Public `runtimeConfig` for safe values only. Override via `NUXT_` prefixed env vars.

## Dependencies

- Run `composer audit` and `npm audit` in CI.
- No unmaintained or abandoned packages.
- Pin major versions. Review changelogs before upgrading.

## Transport & Headers

- **HTTPS everywhere** in production. No mixed content.
- Set security headers: `Strict-Transport-Security`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy`, `Referrer-Policy: strict-origin-when-cross-origin`.

## Logging

- Log authentication failures, permission denials, and suspicious activity.
- Never log passwords, tokens, API keys, or PII.
- Integrate with monitoring (e.g., Sentry) for real-time alerting.
- Use structured logging (JSON format) in production for machine-parseable output.
- Include request ID or correlation ID to trace frontend errors to backend logs.

---

## Laravel

### Mass Assignment

- Always define `$fillable` on models — never use `$guarded = []`.
- **Always use `$request->validated()`** to pass data to `create()` / `update()` — never `$request->all()` or `$request->only()`. This ensures only explicitly validated fields enter the domain layer.

### SQL Injection

- Use Eloquent or Query Builder — they use prepared statements by default.
- If raw SQL is unavoidable, always use parameter bindings: `DB::select('... WHERE id = ?', [$id])`.
- Never concatenate user input into queries.

### XSS

- `{{ }}` in Blade auto-escapes. Never use `{!! !!}` with user content unless sanitized with HTMLPurifier.
- Sanitize rich text on the backend before storage.

### CSRF

- `@csrf` on all forms. Include CSRF token in headers for AJAX requests.

### Authentication & Authorization

- **Sanctum** for API token authentication. **Filament** handles admin panel auth.
- Authorization via **Policy classes** — never inline in controllers.
- `$this->authorize()` before any resource access.
- Never trust client-side role or permission data.

### Rate Limiting

- `throttle` middleware on login, registration, password reset, API endpoints, and expensive operations.
- Define custom rate limiters in `AppServiceProvider` for tiered access.

### Passwords

- `Hash::make()` for all passwords. Never store plaintext or use reversible encryption.
- Enforce password complexity via validation rules.

### File Uploads

- Validate file type, size, and extension on every upload.
- Store outside web root or use cloud disk (S3, DO Spaces).
- Never trust client-provided filenames — generate safe names server-side.

---

## Nuxt

### XSS

- Vue's `{{ }}` auto-escapes HTML — use for all dynamic content.
- **Never use `v-html` with user content.** Sanitize with DOMPurify if absolutely required.

### API Key Proxying

- Never expose secret keys client-side. Use `server/api/` proxy routes for third-party calls requiring secrets.

### SSR State Isolation

- Use `useState` for SSR-safe reactive state — prevents cross-request state pollution.
- Never use module-level mutable state in SSR mode.

### Content Security Policy

- Configure CSP headers via Nuxt server middleware or Nitro config.
- Restrict script sources. Review CSP violations in logs.

---

## Code Review

- Security-sensitive changes (auth, payments, file uploads, API keys) require explicit reviewer attention.
- Check for hardcoded secrets, unvalidated input, and missing authorization on every PR.
