# Change Rigor and Boundary Assurance

Use this reference when a workflow must choose approval, review, or
revalidation depth. Component applicability, runtime assurance, and change
rigor are independent; do not turn them into one project-wide strictness label.

## Authority before method

A skill may change the agent's method or workflow; it never grants authority.
Use clear scope already supplied by the user and do not re-ask for it. Read,
answer, report, review, and diagnose requests make no repository or external
mutation and require no approval gate. An explicit bounded implementation
request authorizes ordinary in-scope R1/R2 edits without another kickoff or
pre-edit patch gate.

Permission to test does not authorize a production fix or mutation. Classify
build output, fixtures, browser actions, cleanup, credentials, and shared-state
effects independently. Stop after diagnosis unless implementation was also
requested.

## Boundary assurance facts

Record a row when a material or non-obvious boundary fact selects controls, or
an R3 decision needs durable evidence. For ordinary R1/R2 work, concise cited
facts are enough; do not require a row-level ledger.

| Exposure | Data impact | Privilege | Reversibility / availability | Control owner | Evidence |
|---|---|---|---|---|---|
| local, private/internal, public | disposable, internal, sensitive, regulated-confirmed | anonymous, authenticated, privileged, service identity | recreatable, recoverable, material, critical | application, ingress/platform, identity provider, external service, unresolved | path, configuration, or owner decision |

Missing or contradictory facts remain **Unresolved**. Keep inexpensive universal
safeguards while escalating only decisions required by the accepted increment.
Mixed material boundaries get separate rows.

## Change rigor

| Class | Objective trigger | Handling |
|---|---|---|
| **R0 — Read-only** | No repository or external mutation. | Make zero writes: no approval gate, ledger, task mutation, or autofix. Report evidence only. |
| **R1 — Clean additive** | Absent target or clean regular file; additions only; no conflict, deletion, weakening, boundary/privilege change, or external effect. | For project documents, show the semantic summary and exact diff together for one approval, then revalidate targets and parents. User-requested code changes need no extra patch gate. |
| **R2 — Material semantic** | Clean existing meaning, component decisions, public contracts, planned dependencies, user-visible behavior, or bounded cross-file effects; no R3 trigger. | For project documents, keep a target-scoped ledger and one combined exact-patch approval. For implementation, the approved request or plan authorizes in-scope edits; run applicable reviews without a pre-edit code patch gate. |
| **R3 — Hazardous** | Deletion, move, supersession, weakened constraint, dirty target, symlink/non-regular/generated target, conflict/unknown ownership, auth/privacy/secret/permission boundary, external mutation, public disclosure or publication, destructive or published migration, production/deployment effect, irreversible external action, or relevant concurrent change. | Project documents retain separate semantic-plan and exact-patch gates, a durable relevant ledger, and strict revalidation. Implementation needs an approved plan plus just-in-time approval for the exact R3 effect. Run every applicable review and a conditional independent red team. |

The highest applicable trigger wins. Relevant uncertainty escalates; a request
may choose stricter handling but cannot waive R3. A public copy edit can be R1,
while a local credential change is R3.

## Decision cases

| ID | Situation | Required handling |
|---|---|---|
| `r0-report` | The user asks for an answer, review, report, or diagnosis only. | R0: make zero repository or external writes and ask for no approval. |
| `bounded-implementation` | The user explicitly requests a bounded R1/R2 implementation and already supplied clear scope. | Use the supplied scope; proceed without a redundant kickoff or pre-edit patch gate. |
| `test-only-failure` | An authorized test exposes a production defect, but no fix was requested. | Testing does not authorize a production fix; report the defect and stop before production mutation. |
| `r12-project-document` | A clean R1/R2 project-document change is ready. | Present its semantic summary and exact diff as one combined decision, then revalidate before writing. |
| `r3-project-document` | A project-document patch has an R3 trigger. | Obtain the semantic plan decision and a separate exact-diff decision; revalidate before writing. |
| `r3-effect` | Work would delete, publish, publicly disclose, mutate external state, elevate privilege, or act irreversibly. | Immediately before execution, present the exact target, action, scope, exposure, credential class, and recovery path for one just-in-time decision. |
| `unchanged-r3-effect` | An approved R3 effect will execute immediately and every previewed fact is unchanged. | Reuse that exact effect approval without a second unchanged gate. |
| `relevant-change` | A target or material claim/effect fact changes after approval. | Invalidate the affected approval, reclassify, and regenerate the proposal. |
| `unrelated-change` | An unrelated file changes without affecting scope or evidence. | Preserve it and continue; do not invalidate or restart accepted work. |

## Reuse and invalidation

Reuse a document approval only when its scope and artifact hash match exactly.
Reuse an effect approval only while its targets, action, scope, exposure,
credential class, recovery path, and material facts remain unchanged. Reuse an
implementation classification only while its scope, constraints, and material
evidence hashes still match; implementation authorization does not require a
pre-edit code hash or an extra exact-patch gate.

Immediately before a document write, revalidate its target, parent, and direct
claim-evidence anchors. Abort and regenerate when a relevant value changes.
Immediately before another R3 effect, present its exact target, action, scope,
exposure, credential class, and recovery path. Ask once and execute without a
second unchanged gate. Preserve unrelated dirty work; an unrelated change does
not invalidate, restart, or expand the accepted work.

## Universal floor

Treat filenames discovered by shell commands as untrusted input. Pass known
paths directly, or keep the producer and consumer bounded and NUL-delimited;
newline-delimited `xargs` can reinterpret crafted filenames as new arguments.

When applicable, retain trust-boundary validation, authorization at the owner of
a protected resource, secret isolation, parameterized data access, safe output
handling, and explicit approval for destructive operations. A component marked
Optional or Unresolved is not implementation approval.
