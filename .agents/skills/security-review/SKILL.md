---
name: security-review
description: Review code and plans for proportionate, evidence-backed security controls. Use for security-sensitive changes or the security pass of a scoped code review.
---

# Security Review

Review outcomes at real trust and data boundaries. Do not apply a framework
checklist to components the project has not adopted.

## Applicability preflight

Before detailed checks:

1. Read the approved scope and relevant `AGENTS.md`, `ARCHITECTURE.md`, and
   executable configuration.
2. Identify changed trust boundaries and adopted components.
3. Record each boundary's exposure, data impact, privilege, reversibility or
   availability, control owner, and evidence.
4. Mark a check **not applicable** only with an evidence-backed reason. Keep
   missing or contradictory facts unresolved.
5. Preserve universal safeguards: validate untrusted input, authorize protected
   resources at their owning boundary, isolate secrets, parameterize data
   access, handle output safely, and require approval for destructive actions.

Mixed flows get separate rows. A project label such as “prototype” does not
waive a boundary safeguard.

## Applicable checks

### Input and output

- Validate untrusted data at the first authoritative server boundary. Frontend
  validation supports UX but is not the trust decision.
- Validate file type, content, size, name, and storage behavior when untrusted
  files enter the system.
- Treat a server-side URL or outbound destination influenced by untrusted input
  as an SSRF boundary. Allow-list intended schemes, hosts, and destinations;
  resolve every address and reject private, loopback, link-local, multicast,
  and reserved ranges unless that internal target is explicitly adopted.
  Revalidate every redirect. Prevent DNS rebinding or resolution races by
  pinning or verifying the actual connection target against the validated
  addresses while preserving the intended HTTP host and TLS identity.
- Use typed request contracts when they improve validation or reuse; do not
  prescribe a particular request-class shape.
- In Laravel, use Form Requests for meaningful or complex payloads, reused
  rules, request authorization, or an established convention, and consume
  validated data rather than broad request bags. A small, one-off input may
  remain inline when its validation boundary is clear and testable.
- Use framework escaping by default. If untrusted rich text is accepted,
  sanitize at the trusted server boundary; client sanitization is defense-in-
  depth and UX, not the authority.
- Preserve Blade `{{ }}` and Vue interpolation escaping. Treat `{!! !!}` and
  `v-html` with user-controlled content as unsafe unless a reviewed server-side
  sanitization contract makes the exact output safe.
- Keep persistence entities and sensitive fields out of public responses.
  Classify identifiers by context rather than assuming every internal ID is
  sensitive.
- Use Laravel API Resources or the project's established response DTOs when
  they define the public field contract.
- Return production errors without secrets or unnecessary internal structure.

### Identity, sessions, and authorization

Assess these separately:

- **Identity:** where credentials or delegated identity are established.
- **Browser session:** which component owns cookies, CSRF posture, logout, and
  renewal.
- **Token or claim exchange:** what crosses service boundaries, with audience,
  expiry, mapping, revocation, and service-identity behavior.
- **Resource authorization:** which boundary owns the protected resource and
  makes the authoritative decision.

Laravel Sanctum, browser-session cookies, API tokens, route middleware, and
Policies are options only when their component and flow are adopted. If Nuxt
and Laravel share a flow, require one documented trust handoff and keep the
authoritative resource-policy decision in the server that owns the protected
resource. Use Laravel Policies or Gates when Laravel is that owner.

Apply throttling to exposed authentication, recovery, or abuse-sensitive flows
when evidence shows it is needed; do not prescribe Redis, Bucket4j, or another
implementation without an approved component decision. Prevent client-supplied
identity or role spoofing.

### Data and secrets

- Use Eloquent or parameter binding for every data technology; reject query
  construction that combines untrusted strings with executable syntax. Define
  explicit `$fillable` fields and reject `$guarded = []`.
- Keep credentials out of source, logs, examples, error output, and client
  bundles. Ignored local environment files are acceptable; deployed secrets
  use the approved platform or runtime secret boundary.
- Read runtime values through Laravel `config()` rather than `env()` outside
  config files. Keep Nuxt secrets in private `runtimeConfig`, never its public
  section.
- Record retention and recovery for material data. Before destructive work,
  back up non-recreatable data or prove the disposable data rebuild path.
- Use least privilege for people and service identities. Background work may use
  an approved service identity; do not invent an end-user identity.

### Browser and edge controls

Apply CSRF protection to credential-bearing browser requests whose session
model creates the risk. For Sanctum cookie authentication, verify the adopted
stateful-domain, cookie, origin, and CSRF flow rather than assuming bearer-token
semantics.

Check TLS, HSTS, CSP, and framing at the component that owns ingress. Verified
platform or edge controls count; do not require duplicate application headers.
Record unresolved ownership instead of assuming protection.

### Dependencies and operations

- Treat an exact package and purpose in an approved plan or request as approved.
  Reuse of an unchanged installed dependency needs no new decision.
- Escalate unplanned packages, replacements, major upgrades, licensing concerns,
  external services, and permission or runtime expansion.
- Evaluate advisories by reachable behavior, exploitability, maintained
  alternatives, and project tooling. A scanner command is evidence, not a
  universal requirement or zero-finding guarantee.
- Require logs and health evidence sufficient to diagnose adopted runtimes.
  Use Horizon, Telescope, Pulse, platform metrics, alerts, and audit trails only
  when exposure, availability, privilege, or sensitive operations justify them.
  Audit material privileged or sensitive actions, not every event. Treat
  `composer audit` and `npm audit` as inputs whose findings still require
  reachability and exploitability analysis.

## Severity and report

Derive severity from **exploitability, exposure, impact, and reversibility**,
including existing compensating controls and their verified owner. Absence of a
checklist item alone does not determine severity.

For each finding report: affected boundary, evidence, realistic abuse or failure
path, severity rationale, smallest effective correction, and verification. List
evidence-backed N/A checks briefly so reviewers can distinguish intentional
scope from omission.

## Parent review handoff

When invoked by the parent review, use its supplied finding contract and review
packet. Do not widen the accepted file set. Return either evidence-backed N/A
coverage or normalized findings with classification, severity, confidence,
exact location, affected boundary, abuse or failure path, consequence, smallest
correction, verification, and pre-existing status.
