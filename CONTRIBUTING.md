# Development Workflow

## Git and Pull Requests

- Use GitHub Flow with `staging` as pre-production and `master` as production.
  Branch from the correct base, open a PR to `staging`, verify it, then promote
  to `master` through a reviewed PR.
- Name branches `feature/*`, `fix/*`, or `hotfix/*`. Use imperative commit
  subjects of at most 72 characters and keep WIP commits off shared branches.
- Preserve unrelated work. Merge after applicable checks and human review, then
  delete the branch when safe.
- The repository CI contract is `bash tests/run.sh`; GitHub host enforcement
  exists only when confirmed with host evidence such as required checks or
  branch protection.

## Change Rigor

Use `.agents/skills/review/references/change-rigor.md`:

- **R0 — read-only:** inspect and report with no repository or external writes.
- **R1 — clean additive:** implement directly; combine a project-document
  summary and exact diff into one approval.
- **R2 — bounded semantic:** plan and test in proportion to contract and
  cross-file impact. Only project documents require a relevant ledger;
  ordinary R2 implementation does not.
- **R3 — hazardous:** deletions, constraint weakening, dirty or special targets,
  conflicts, auth/privacy/secret/permission boundaries, destructive migrations,
  production effects, and irreversible actions require explicit decisions,
  revalidation, and conditional independent review.

The highest trigger wins. Skills change method, not authority. Approved scope
needs no second kickoff or pre-edit patch. Unplanned packages, replacements,
major upgrades, licensing concerns, services, and permissions need a decision.

## Verification

Run the real commands for affected adopted components:

- Laravel: Larastan Level 9, Pint, and Pest with line and branch coverage.
- Nuxt: ESLint, `nuxi typecheck`, Vitest coverage, and a production build.
- Browser behavior: Playwright for changed critical flows, using semantic,
  locale-aware locators.
- Ecosystem scripts and policy: targeted shell checks and `bash tests/run.sh`.

Report unavailable checks honestly. Use `review` for ordinary changes;
`ma-review` may parallelize applicable architecture, security, and performance
passes. Reserve `review-gstack` and independent adversarial review for R3,
significant architecture/security/data/production work, or explicit requests.

## Testing, Data, and Delivery

Aim for 100% line and branch coverage of testable production behavior. Test
changed outcomes and meaningful failure paths, test-first by default. Preserve
existing valid behavior until a failing test proves a change. Do not invent
tests for human prose, generated artifacts, declarative configuration, or
trivial forwarding without an executable contract.

Use additive migrations and never alter a published migration. Back up material
non-recreatable data before approved destructive work; prove a rebuild path for
disposable data. When adopted, document and verify Laravel Forge for backend
services, PM2 for Nuxt SSR, and Cloudflare at the edge, including environment,
trigger, rollback, and ownership evidence.
