# Deploy skill tasks

- [x] Review the accepted implementation plan and resolve material findings.
- [x] Create the `deploy` entrypoint and three linked Cloud/stack/recovery references.
- [x] Add invocation and catalog documentation with Cloud explicitly selectable.

- [x] Validate skill metadata, reference paths, catalog and portability.
- [x] Evaluate realistic deployment, readiness and failure scenarios.
- [x] Run `bash tests/run.sh` and record applicable verification results.
- [x] Complete scoped review and resolve retained in-scope findings.
- [x] Report the result and distinguish local validation from live Cloud testing.

## Evidence

- Plan review: independent read-only review returned GO, with strategy,
  architecture, security/operations and testing PASS; design N/A. No findings.
- Skill validator passed; catalog passed with 42 skills; canonical portability
  passed. All local reference links resolve to regular files and all 22 unique
  external source URLs returned HTTP 200.
- A fresh agent applied the skill to eight independent supplied scenarios.
  Inspected responses and proposed actions met the following outcomes:

  | Scenario | Observed decision |
  |---|---|
  | First monorepo | Proposes two apps, retains runtime/SSR choices, verifies PostgreSQL offering, prepares locally before external decisions. |
  | Repeat release | Reuses existing approval, explicitly targets both staging apps, revalidates and monitors each release. |
  | Readiness only | Reports storage/session blockers; no writes, CLI install or host migration. |
  | Sanctum failure | Traces cookies/CORS/SSR, recommends owned domains, preserves report-only scope. |
  | Nitro output | Identifies incompatible output/start path while preserving the still-live previous host. |
  | Horizon | Retains Redis-backed Horizon and verifies long-job/process limits instead of replacing queue semantics. |
  | Partial timeout | Queries exact deployment and possible resource creation before any retry; no schema rollback. |
  | Wrong organization | Stops effects, resolves secure authentication and preserves the original target authorization. |

  Raw prompts/responses remain in `/tmp/deploy-skill-scenarios.json` and
  `/tmp/deploy-skill-scenario-responses.md`. These are simulations of decisions
  and proposed actions, not executed Cloud commands or a live integration test.
- `bash tests/run.sh` passed (exit 0); log: `/tmp/deploy-skill-suite.log`.
  Its summary reports offline-deterministic passed, live-agent-v2 not run, and
  44 registered live cases. The separate eight simulations above are not those
  registered live tests. No live Cloud integration was attempted.
- Scoped diff/new-file whitespace checks passed. Concurrent unrelated installer
  and documentation edits were preserved and excluded from this review.
- Independent final review: Ready, no actionable findings. Correctness,
  standards, architecture, security, operations and testing completed;
  UI/accessibility/SEO and runtime performance N/A for instruction-only work.
- Handoff: skill and invocation/catalog documentation completed. Local checks
  and simulated scenarios passed; live Cloud deployment remains untested.

## Requested follow-up review — 2026-09-11

- [x] Complete the requested report-only review and record all retained findings.
- [x] DEP-001 (P2, Primary, confidence 75, gated_auto): in
  `.agents/skills/deploy/references/laravel-cloud.md:87`, scope
  `APP_ENV=production` to production targets and preserve the adopted value for
  staging/other environments after inspecting its consumers. Verify with a
  staging redeployment scenario using `APP_ENV=staging` and environment-specific
  mail or scheduler behavior; retain the value and keep `APP_DEBUG=false`.

Evidence: the general Laravel settings section says “Keep
`APP_ENV=production`” without a target restriction, while the accepted skill
must preserve existing application choices across first/repeat deployments.
[Laravel environment detection](https://laravel.com/framework/docs/13.x/configuration#determining-the-current-environment)
uses `APP_ENV`, so changing an adopted staging value changes conditional
application behavior. This is an instruction defect, not an observed live
incident. Root reviewer identified it; the security/operations reviewer
validated it in a follow-up challenge (not independent corroboration).

Correctness, standards, architecture, security, operations and testing passes
completed; runtime performance and UI/accessibility/SEO are not applicable.
Metadata, catalog (42 skills), portability and scoped diff checks passed again.
The four skill files still match the previously validated draft, so the prior
full-suite pass and eight scenario simulations were reused. Those simulations
did not cover an explicitly adopted non-production `APP_ENV`; live Cloud
integration and registered live-agent-v2 tests remain unperformed.

Review verdict before correction: Not ready until DEP-001 resolves the explicit environment
preservation requirement. No implementation fixes applied; only this authorized
tracker was updated. Unrelated working-tree changes remain outside review.

## DEP-001 correction — 2026-09-11

The user authorized the fix. The reference now limits `APP_ENV=production` to
production targets, preserves adopted values in staging/other environments,
and calls for inspecting environment-dependent behavior before proposing changes.
`APP_DEBUG=false` and the existing key/URL/resource guidance remain intact.

Verification: metadata validator, catalog (42 skills), portability and scoped
whitespace checks passed. A fresh agent simulated staging and production
preparation: both retained their adopted `APP_ENV` and `APP_DEBUG=false`;
staging verification covers mail-sink routing and exclusion of production-only
billing tasks. Its diff review found no unintended changes or concrete issues.
The full suite was not rerun for this bounded prose correction; the earlier
full-suite pass remains historical evidence. No live Cloud tests were run.

Current verdict: Ready. DEP-001 is resolved; no open review findings remain.
