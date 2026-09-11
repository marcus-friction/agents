# Deploy skill for Laravel Cloud

## Accepted outcome and scope

Implement the user's accepted research proposal: a provider-neutral `deploy`
skill that prepares, deploys, verifies, and diagnoses Laravel-only and Laravel
+ Nuxt applications on Laravel Cloud. Support monorepos and separate repos.
Use the official Cloud CLI and current documentation; add no custom API client.
The user approved implementation on 2026-09-11. This is R1 skill/document work,
not authorization to create accounts, install dependencies, publish, or deploy
a live application. Preserve all unrelated working-tree changes.

Acceptance criteria:

- Discover `deploy` through ordinary skill installation and the catalog.
- Distinguish readiness-only, preparation, deployment, and diagnosis requests.
- Inspect project evidence and prepare a concrete result before asking for any
  missing elevated-effect authorization; reuse unchanged existing approvals.
- Handle two independent Cloud applications, runtime versions, Nuxt SSR,
  Sanctum, resources, secrets, release ordering, and partial failure.
- Finish deployed work with monitored status and relevant user-flow evidence;
  do not equate a successful build or HTTP 200 with a working application.
- Include first/repeat deployment and recovery guidance with current sources.
- Pass metadata/reference, catalog, portability, and repository checks; assess
  realistic scenarios without claiming an unperformed live Cloud deployment.

Exclusions: account/resource creation, live deployment, dependency installation,
custom deployment scripts, CI runtime implementation, production migrations,
replacing project architecture defaults, committing, pushing, or publishing.

## Evidence and decisions

- `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, and
  `docs/ecosystem-reference.md`: Laravel 13, PHP 8.4, Nuxt 4, PostgreSQL 17;
  preserve adopted project choices and authorization boundaries. Forge/PM2/
  Cloudflare remain an existing path; Cloud becomes explicitly selectable.
- `.agents/skills/skill-creator/SKILL.md`: progressive disclosure, original
  instructions, proportionate behavioral evaluation, no unrequested effects.
- `.agents/skills/review/references/change-rigor.md`: R1 authorizes local
  implementation; future R2 effects require exact target/scope authorization.
- `tests/skill-catalog-test.sh`, `tests/distribution-manifest.json`, installer
  discovery: new skill directories are discovered without a per-skill manifest.
- `docs/solutions/`, `.agents/project/`, and root `ARCHITECTURE.md` are absent.
  The inspected repository and accepted proposal supply the relevant context.
- Official sources reviewed 2026-09-11: Cloud supports Nuxt and monorepos;
  each app is independently deployed. CLI options and resource capabilities
  must be discovered at execution time. Sources are linked in the skill.
- Write original guidance, referencing documentation and the upstream skill
  without copying their instruction text; no additional license payload needed.

## Boundaries and failure modes

The changed artifacts are instructions, not application runtime code. Future
Cloud operations expose public services, incur usage charges, carry secrets,
and may mutate material data. The project owner authorizes those effects;
Laravel and Nuxt retain their established resource and identity ownership.

| Failure | Required behavior |
|---|---|
| Readiness or diagnosis mistaken for deployment authority | Preserve read-only scope; report concrete findings. |
| Wrong org/app/environment or pending settings | Resolve explicit IDs and inspect staged changes before effects. |
| CLI timeout after provisioning/deploy | Inspect remote state before retrying; avoid duplicates. |
| Nuxt builds unusable output | Check Nitro preset, startup, port, SSR and API flow. |
| Cookie authentication fails | Verify adopted domains, CSRF, cookies and SSR forwarding. |
| Database or queue service differs from adopted behavior | Verify versions/extensions and Horizon/driver compatibility. |
| One application fails after another releases | Track both revisions; recover compatible code without automatic schema rollback. |
| Secrets enter output or client bundle | Use secure input, minimal redacted output and private runtime settings. |
| Documentation or CLI is stale/unavailable | State gap; discover supported behavior or give a bounded dashboard handoff. |

## File ownership and sequence

1. Add this project-owned plan and sibling tracker; review against accepted scope.
2. Add upstream distribution source `.agents/skills/deploy/SKILL.md` and three
   references: `laravel-cloud.md`, `laravel-nuxt.md`, and
   `verification-and-recovery.md`.
3. Make bounded edits to project-owned `README.md` and
   `docs/ecosystem-reference.md` for invocation, catalog, and selectable Cloud
   delivery. Preserve existing content and infrastructure choices.
4. Validate metadata and links and evaluate fresh/repeat/readiness-only,
   authentication, Nitro, Horizon, wrong-target, and partial-failure scenarios.
   Use an isolated agent scenario where available; keep raw output in `/tmp`.
5. Run applicable existing checks and `bash tests/run.sh`; review the scoped
   result and fix in-scope defects under the implementation authorization.

## Verification and completion

- Structural validation using the existing skill validator if dependencies
  are available; physical reference-path and external source checks.
- `bash tests/skill-catalog-test.sh` and
  `bash tests/canonical-skill-portability-test.sh`.
- `bash tests/run.sh` for installer/distribution and existing contracts.
- Scenario evaluation examines decisions and tool effects, not heading matches.
  No prose-mirroring tests or new executable production behavior are needed.
- Independent scoped review covers correctness, standards, instruction-level
  security/operations and architecture; UI and runtime performance are N/A.
- Report unavailable live integration evidence explicitly. No Cloud credentials
  or live resources are needed to complete this skill increment.

Recovery for this repository change is removal of the new skill and reversal of
only this increment's documentation edits; no runtime/data migration occurs.

## Plan review

Hold scope. Independent review of acceptance, instruction authority,
two-application releases, discovery, test fit and recovery returned GO with no
blocking findings. Strategy, architecture, security/operations and testing
passed; design is not applicable. Execution evidence is in the sibling tracker.
