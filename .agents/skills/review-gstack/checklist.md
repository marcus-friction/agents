# Mega Review Checklist

Apply each section only to relevant boundaries and cite project evidence.

## Critical integrity

- Parameterize executable queries and validate untrusted structured outputs.
- Replace read-check-write races with an atomic constraint, transaction, or
  compare-and-set appropriate to the data store.
- Trace every consumer when enums, states, schemas, signatures, events, or
  permissions change.
- Verify destructive or published migrations for compatibility, backup or
  rebuild evidence, cutover, and recovery.
- Verify authentication, session, claim exchange, and resource authorization at
  their respective owning boundaries.
- Reject secrets in source, logs, examples, artifacts, or client bundles.

## Runtime and failure behavior

- Check timeout, cancellation, retry, idempotence, partial failure, and duplicate
  delivery where external or asynchronous work exists.
- Check transaction scope against the atomic use case.
- Check N+1 access, unbounded work, payload growth, blocking calls, and new
  dependency or bundle cost where runtime behavior changes.
- Ensure error handling preserves actionable context without leaking sensitive
  data or silently swallowing failure.
- Verify time, locale, precision, encoding, and type conversion at affected
  boundaries.
- Scale logs, health checks, metrics, traces, and alerts to the actual exposure
  and availability requirement.

## Maintainability and repository fit

- Confirm new code uses existing abstractions when they fit and avoids wrappers
  with no behavior or ownership.
- Refactor based on cohesion, readability, reuse, or behavior—not arbitrary line,
  boolean, or class-string counts.
- Follow the repository's module and test layout.
- Remove in-scope debug artifacts, unused code, stale comments, and verified
  mechanical lint issues only in explicitly selected autofix mode.
- Treat an exact dependency and purpose in an approved plan as approved;
  escalate unplanned packages, replacements, major upgrades, licensing,
  external services, and permission expansion.

## Suppress review noise

Do not flag harmless readability repetition, speculative future scaling,
framework behavior already covered upstream, or unrelated dirty files. Every
finding needs a realistic consequence and concrete verification.
