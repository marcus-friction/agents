# Development Workflow

> [!WARNING]
> This inactive candidate becomes policy only through evidence-backed
> reconciliation.

## Git and Pull Requests

- Use the confirmed default branch as PR target; do not assume `staging` unless
  project documentation adopts it.
- Name branches `feature/*`, `fix/*`, or `hotfix/*`. Use imperative commit
  subjects within 72 characters and keep WIP commits off shared branches.
- Merge after applicable checks and human review. Preserve unrelated work and
  delete branches when safe.
- The repository CI contract is its documented local check suite; GitHub host
  enforcement exists only when confirmed with host evidence such as required
  checks or branch protection.

## Change Rigor

Use `.agents/skills/review/references/change-rigor.md`:

- **R0 — read-only:** inspect and report with no repository or external writes.
- **R1 — ordinary:** make reversible, in-scope repository changes under the
  user's implementation request, including tracked edits and deletions. Preserve
  unrelated work and verify; no second kickoff or document gate.
- **R2 — elevated:** before destructive, privileged, auth/privacy/secret/
  permission, production/shared-state, publication, or irreversible effects,
  confirm the exact target, scope, exposure, credentials, and recovery path.

The highest applicable trigger wins. Skills change method, never authority.
Approved implementation scope needs no second kickoff or pre-edit patch. Exact
planned dependencies are approved; unplanned packages, replacements, major
upgrades, licensing concerns, external services, or expanded permissions need a
new decision.

## Tests and Review

Run the real commands for affected adopted components:

- Laravel: Larastan Level 9, Pint, and Pest line and branch coverage.
- Nuxt: ESLint, type-check, Vitest coverage, and production build.
- Browser: Playwright for changed critical flows.

Aim for 100% coverage of testable production behavior. Test changed outcomes
and meaningful failures, test-first by default. Characterize valid existing
behavior before changing it. Do not invent tests for prose, generated artifacts,
declarative configuration, or trivial forwarding without an executable contract.

Use `review` normally; it selects applicable specialist passes.
Reserve deep and independent adversarial review for R2 or significant
architecture/security/data/production work, or explicit requests.

## Data and Delivery

Use additive migrations and never modify a published migration. Back up material
non-recreatable data before approved destructive work; prove a rebuild path for
disposable data. When adopted, document Forge, PM2, and Cloudflare environments,
triggers, rollback, and ownership from executable evidence.
