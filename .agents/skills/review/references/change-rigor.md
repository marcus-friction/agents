# Change Rigor and Boundary Assurance

Choose controls from the effect being performed, not from the file type being
edited. Skills change method; they never grant authority.

## Three change classes

| Class | Trigger | Handling |
|---|---|---|
| **R0 — Read-only** | No repository or external mutation. | Inspect and report. Make zero writes and ask for no approval. |
| **R1 — Ordinary** | Reversible work inside the supplied repository scope, including additions, edits, moves, and Git-tracked deletions. No privilege, secret, production, publication, or irreversible external effect. | The explicit implementation request authorizes the scoped change. Preserve unrelated work, test the result, and report the diff. No extra kickoff, document gate, or pre-edit patch approval. |
| **R2 — Elevated** | Destruction of uncommitted or non-recreatable data; auth, privacy, secret, or permission changes; privileged execution; production or shared-state mutation; public disclosure or publication; destructive migration; or another irreversible external effect. | Inspect first. Immediately before the effect, confirm the exact target, action, exposure, credentials, and recovery path, and owner decision unless the user already authorized those exact facts. Revalidate material facts and use applicable deep and independent review. |

The highest applicable class wins. Uncertainty is elevated only when it affects
an R2 fact; ordinary uncertainty is investigated without inventing ceremony.
A tracked documentation deletion can be R1, while changing a local credential
boundary is R2.

## Boundary assurance

Record material boundary facts when they select controls. Ordinary work needs a
concise evidence citation, not a permanent ledger.

| Exposure | Data impact | Privilege | Reversibility / availability | Control owner | Evidence |
|---|---|---|---|---|---|
| local, private/internal, public | disposable, internal, sensitive, regulated-confirmed | anonymous, authenticated, privileged, service identity | recreatable, recoverable, material, critical | application, ingress/platform, identity provider, external service, unresolved | path, configuration, or owner decision |

Keep unresolved facts explicit. Apply inexpensive universal safeguards, then
escalate only decisions required by the accepted increment.

## Decision cases

| ID | Situation | Required handling |
|---|---|---|
| `read-only-report` | The user asks for an answer, review, report, or diagnosis only. | R0: make zero repository or external writes and ask for no approval. |
| `planning-artifacts` | The user asks for a plan, or authorized implementation requires the plan workflow. | R1 is limited to the canonical `implementation-plan.md` and `tasks.md`; it does not authorize implementation, dependencies, production, or external effects. |
| `review-tracker` | An accepted plan already authorizes its live `tasks.md` and the requested review must record actionable work. | R1 is limited to updating that existing matching tracker. Do not create a tracker, change reviewed code, or treat bookkeeping authority as fix authority. |
| `ordinary-implementation` | The user explicitly requests a bounded repository change. | R1: use the supplied scope and proceed without a redundant kickoff, document gate, or pre-edit patch approval. |
| `test-only-failure` | An authorized test exposes a production defect, but no fix was requested. | Testing does not authorize a production fix; report it and stop before production mutation. |
| `elevated-effect` | Work would destroy uncommitted or material data, change privilege or secrets, publish, disclose publicly, mutate production/shared state, or act irreversibly. | R2: obtain or reuse an exact decision covering the exact target, action, scope, exposure, credential class, and recovery path immediately before execution. |
| `relevant-change` | A material R2 fact changes after approval. | Invalidate the affected approval and present the changed facts. |
| `unrelated-change` | An unrelated file changes without affecting scope or evidence. | Preserve it and continue; do not restart accepted work. |

## Reuse and revalidation

Reuse an R2 decision only while its target, action, scope, exposure, credential
class, recovery path, and material evidence remain unchanged. Revalidate those
facts immediately before the effect. Ordinary implementation authorization
does not require a source hash or second approval.

## Universal floor

Treat filenames from tools as untrusted input. Use exact paths or bounded,
NUL-delimited pipelines. Never follow destination symlinks during installation
or write through non-regular project-document targets.

Validate untrusted input at trust boundaries, authorize protected resources at
their owner, isolate secrets, parameterize data access, and handle output safely.
A component marked Optional or Unresolved is not implementation approval.
