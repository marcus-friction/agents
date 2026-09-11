# Adversarial Scenario Bank

Use only the sections that can challenge the accepted boundary. Begin with the
primary review's findings and ask what lies between or beyond its categories.

## Attack the happy path

- What breaks at ten times expected load or when a dependency becomes slow?
- What happens when two requests target the same resource or an action is
  submitted twice?
- Can ordering, retries, clock skew, or stale reads change the outcome?

## Find silent and partial failures

- Can an exception be swallowed, logged without recovery, or mistaken for
  success?
- Can a multi-step operation complete only some writes, messages, uploads, or
  external calls?
- Can a background task fail without alerting, retry bounds, idempotency, or a
  recoverable state?
- Can rollback leave old and new versions unable to share current data?

## Exploit trust assumptions

- Can client-side validation, an internal-only assumption, or resource ownership
  be bypassed at the owning boundary?
- Can extra fields, malformed structured output, replayed credentials, hostile
  paths, URLs, or configuration cross into a privileged effect?
- Can secrets or sensitive data reach logs, errors, client bundles, caches, or
  an unintended tenant?

## Break edge cases

- Try absent first-run state, null and empty values, extreme sizes, Unicode and
  directionality, expired state, and orphaned references.
- Remove or corrupt a dependency response. Fill or exhaust a constrained
  resource. Interrupt work between durable steps.
- For UI flows, test stale state, repeated actions, keyboard-only recovery,
  inaccessible errors, and feedback that claims success too early.

## Find gaps between reviewers

- Which integration boundary belongs to no prior specialist?
- Which finding crosses categories, such as a performance path that becomes a
  denial of service or a retry that duplicates money or messages?
- Which deployment configuration, mixed-version window, permission combination,
  or recovery path was assumed rather than verified?
- Which changed public value, schema, state, or contract still has an untraced
  consumer?

Adapted from gstack's `review/specialists/red-team.md` and adversarial review
resolver at revision `1211b6b40becb684eaf29b0f30a650a8a9b222a5`.
