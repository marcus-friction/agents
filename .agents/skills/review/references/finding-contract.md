# Review Finding Contract

Use one contract across the orchestrator and delegated passes. Domain skills
may collect richer facts, but synthesis normalizes every retained issue to this
shape.

## Classification

- **Primary:** the defect is on a changed line or is introduced by changed
  behavior.
- **Secondary:** the defect is in unchanged surrounding code but the accepted
  change directly invokes, exposes, or depends on it.
- **Pre-existing:** unchanged and unrelated to the accepted change. Report it
  separately; it does not affect the verdict.

Do not widen scope for nearby cleanup. If the change now depends on an old
defect for correctness, classify it Secondary rather than Pre-existing.

## Required fields

Each finding has a stable identifier and:

- classification; P0-P3 severity; confidence anchor; action class;
- exact `file:line` or the narrowest verifiable artifact location;
- a short defect statement and the concrete failure or abuse path;
- direct evidence, including the exact motivating line or project rule at
  confidence 75 or 100;
- realistic consequence, smallest effective correction, and verification;
- reporting sources and which sources are context-independent.

A question, preference, generic best practice, or missing-context suspicion is
not a finding until evidence establishes a concrete defect or contract gap.

## Severity

- **P0:** active or imminent catastrophic security, data, availability, or
  irreversible failure.
- **P1:** merge-blocking correctness, security, data-integrity, contract, or
  reliability failure with a realistic path.
- **P2:** bounded defect or material test/operability gap that should be fixed
  but is not presently a blocker.
- **P3:** concrete low-impact issue. Do not use P3 for taste or automated style.

## Confidence anchors

Use only `0`, `25`, `50`, `75`, or `100`:

- **100:** mechanically established by executable evidence or a complete,
  directly verified code path.
- **75:** direct code or governing-contract evidence establishes the defect and
  a credible failure path; quote the motivating line.
- **50:** plausible and important, but one material link remains unverified.
- **25:** speculative or dependent on unsupported assumptions.
- **0:** disproven.

Suppress findings below 75, except a plausible P0 at 50, which remains visible
as verification-required. Never inflate confidence because a risk sounds
severe.

## Action classes

| Action | Meaning |
|---|---|
| `safe_auto` | A deterministic local correction eligible only under explicit `mode:autofix`. |
| `gated_auto` | A concrete fix that changes behavior, contract, policy, dependency, or permission and needs owner authorization. |
| `manual` | Actionable work requiring project judgment, unavailable authority, or external coordination. |
| `advisory` | Evidence-backed residual risk or observation with no repository action. |

Synthesis owns the final action class. Prefer the more conservative route when
reviewers disagree.

## Deduplication and corroboration

Merge reports only when they describe the same defect, failure path, and fix
path at the same or a nearby location. Preserve separate findings when either
the failure mode or correction differs. Union their evidence and sources;
retain the clearest consequence and smallest supported correction.

Agreement from two context-independent reviewers may promote confidence by one
anchor, never beyond 100. A fresh clean-context subagent can be independent
while using the same model; a persona change or second pass in the same context
cannot. Cross-model review is a stronger subset, not a prerequisite. Never
promote severity or confidence from duplicated wording alone.
