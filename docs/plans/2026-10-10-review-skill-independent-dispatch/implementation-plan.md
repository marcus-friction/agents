# Independent dispatch across review skills

## Accepted scope

Amend all eleven review-named skills so available subagents are used for separable review work through fresh, clean-context passes. Keep the parent reviewer responsible for scope, evidence validation, and synthesis. A pass delegated by the parent executes directly and does not recursively delegate. When subagents are unavailable, use a labeled same-context pass without claiming independent corroboration. Preserve `adversarial-review`'s stricter independent-executor gate, existing authority limits, and review output contracts.

## Evidence and approach

`review/references/scope-and-orchestration.md` already states the canonical dispatch principle. `adversarial-review` requires a successful independent route; `review-plan` currently asks for an outside-voice challenge only for elevated or significant plans. The architecture, security, performance, SEO, stack persona, and code-review method skills lack a direct-invocation dispatch rule.

1. Add a concise dispatch rule to each review skill's normal workflow, tailored to parent orchestration, direct invocation, or adversarial independence.
2. Keep the common review reference as the canonical rule and avoid changing applicability, severity, tests, or authority.
3. Inspect the complete skill diff for recursive delegation, claimed independence without a fresh context, and contradictions in fallback or failure handling.
4. Refresh only the three stack persona payload digests pinned by the specialty preservation manifest after the intended skill text changes.

## Acceptance criteria

- Every review-named skill gives available fresh subagents the substantive separable review work or explicitly routes dispatch to its parent review.
- Delegated passes do not spawn another reviewer for the same pass; standalone calls have a bounded review packet and a same-context fallback.
- Fallback evidence is labeled and never counted as independent corroboration. `adversarial-review` still withholds its verdict without a successful qualifying route.
- All modified skills validate structurally, the three affected specialty payload digests match, affected review contracts and the offline suite pass, and no unrelated path changes.

## Verification and delivery

Run skill structural validation, affected review contract checks, `bash tests/run.sh`, and `git diff --check`. Use a tool-enabled smoke review to observe an available direct specialty dispatch, its bounded packet, completion, and absence of recursive delegation. Record the parent `review` dispatch in this increment as another available route. Inspect existing decision-eval coverage for unavailable-subagent fallback and adversarial executor failure; if a tool-level no-subagent or no-success route cannot be created safely in this environment, report that behavior as unverified rather than calling text checks execution evidence. Do not invent unit tests that mirror wording. Consumer-visible skill changes require a later versioned release under `CONTRIBUTING.md`; commit, push, PR, and release are outside this implementation request.

## Approved scope amendment — 2026-10-10 explicit wrap

The user invoked `ma:wrap` after the review finding was fixed. Prepare the
required v1.13.0 release content locally: synchronize `VERSION`, plugin and
marketplace metadata, stable install documentation, and a release note for the
complete unreleased skill change. Capture the reusable terminal-executor
learning if `compound` rates it High. Re-run applicable verification after
these edits. Prepare a read-only delivery preview for a topic branch, one
reviewed commit, PR, merge-commit integration, immutable tag and GitHub release,
checkpoint, and safe cleanup. This amendment authorizes local preparation and
documentation only; each Git or external effect still needs an exact decision.
