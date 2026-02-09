---
name: security-review
description: Security audit checklist for code review
---

# Security Review Skill

Systematic security audit for code changes. Use during the security pass of `/review` or when reviewing security-sensitive code.

## Checklist

### Input Validation
- [ ] All user input validated on the backend (frontend validation is UX only)
- [ ] Form Requests used for all controller inputs
- [ ] `$request->validated()` used — never `$request->all()` or `$request->only()`
- [ ] File upload validation: type, size, extension
- [ ] JSON/array input has explicit structural validation

### Authentication & Authorization
- [ ] `$this->authorize()` called before resource access
- [ ] Policy classes used — no inline authorization in controllers
- [ ] Sanctum guards applied to protected routes
- [ ] No user ID or role spoofing possible via client input
- [ ] Rate limiting on auth endpoints (`throttle` middleware)

### Data Exposure
- [ ] API Resources filter output — no `toArray()` dumping full models
- [ ] Sensitive fields excluded from responses (passwords, tokens, internal IDs)
- [ ] Error responses reveal no internal structure in production
- [ ] No secrets in logs, debug output, or error messages

### SQL & Query Safety
- [ ] Eloquent/Query Builder used (prepared statements by default)
- [ ] Raw SQL uses parameter bindings — never string concatenation
- [ ] Mass assignment: `$fillable` defined, no `$guarded = []`

### XSS Prevention
- [ ] Blade: `{{ }}` used (auto-escapes). No `{!! !!}` with user content
- [ ] Vue: `{{ }}` used (auto-escapes). No `v-html` with user content
- [ ] Rich text sanitized with HTMLPurifier/DOMPurify before storage/display

### Secrets & Config
- [ ] No hardcoded secrets in code or config files
- [ ] `.env.example` has placeholders, not real values
- [ ] `config()` used — never `env()` outside config files
- [ ] Nuxt: private `runtimeConfig` for secrets, `public` for safe values only

### CSRF & Transport
- [ ] CSRF tokens on all forms and AJAX requests
- [ ] HTTPS enforced — no mixed content
- [ ] Security headers present (HSTS, X-Frame-Options, CSP)

### Dependencies
- [ ] `composer audit` / `npm audit` pass
- [ ] No known vulnerable packages
- [ ] No unmaintained or abandoned dependencies

## Severity Guide

- 🔴 **Critical**: Unvalidated input, missing authorization, exposed secrets, SQL injection
- 🟡 **High**: Missing rate limiting, overly broad API responses, missing CSRF
- 🟢 **Medium**: Missing security headers, no audit logging, missing dependency audit
