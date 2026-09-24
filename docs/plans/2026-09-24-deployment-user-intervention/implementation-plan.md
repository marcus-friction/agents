# Deployment user-intervention handoff

## Accepted outcome

Make deployment prerequisites that require a person unmistakable and
actionable across the provider-neutral delivery lifecycle. An agent must surface
the intervention as soon as it is known, identify the exact blocked effect,
protect secret values, stop before the dependent effect, and state how work can
resume and be verified. When no intervention is needed, the handoff must say so
explicitly.

## Acceptance criteria

- `deploy` treats user intervention as a named gate rather than incidental
  prose and distinguishes secret/access work, owner decisions, and repository
  adjustments.
- A shared provider-neutral reference defines the canonical intervention states
  `none`, `required`, `unverified`, and `completed`, plus
  required action fields: blocked effect, timing, owner, location, variable or
  setting names, sensitivity, reason, verification, consequence, and resume
  signal.
- `wrap` surfaces unresolved deployment intervention before any integration,
  tag, release, or other trigger that would deploy; `release` routes automatic
  deployment prerequisites through the same gate.
- Active and candidate `CONTRIBUTING.md` delivery contracts record deployment
  prerequisites, configuration ownership, intervention, verification, and
  recovery whenever deployment applies.
- Final delivery output always reports either `User intervention: none` or a
  conspicuous `USER ACTION REQUIRED` checklist. It never requests secret values
  in chat and never calls a deployment ready while a user-owned action is
  unresolved or unverified.
- Deterministic contracts and consuming-agent cases cover both a required
  secret/dashboard handoff and a no-intervention path, plus automatic triggers,
  owner decisions, repository adjustments, completed-but-unverified work, and
  verified completion projected to the stable no-action final label.

## Evidence ledger

- `.agents/skills/deploy/SKILL.md` already discovers variable names, owners,
  scripts, and dashboard-only steps, but has no mandatory intervention state or
  stable output contract.
- `.agents/skills/wrap/SKILL.md` owns delivery orchestration and deployment
  trigger authorization, but does not require a deployment-intervention gate.
- `.agents/skills/release/SKILL.md` blocks unauthorized automatic deployment,
  but does not route unresolved configuration or user actions explicitly.
- `.agents/skills/deploy/references/laravel-cloud.md` correctly protects secret
  values and recommends bounded dashboard handoffs; the generalized state and
  presentation rules belong above that provider adapter.
- `project-templates/base/CONTRIBUTING.md` has one deployment-coupling row but
  no place for prerequisites, variable ownership, manual actions, or verification.
- `docs/solutions/skill-routing-progressive-disclosure.md` requires routing-
  critical obligations to stay in primary skill instructions, with references
  holding downstream detail.
- `tests/delivery-lifecycle-contract-test.sh` and the v2 agent-evaluation
  registry are the existing structural and behavioral enforcement points.

No relevant deployment-intervention solution exists beyond the routing lesson
above. `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, the affected skills,
deployment references, evaluation schema, and test harness were inspected.

## Decisions and boundaries

- Change rigor is **R1**: repository-only skill, template, fixture, and test
  edits. This work performs no deployment, secret mutation, publication, or
  other external effect.
- The canonical intervention semantics are provider-neutral and live under
  `wrap`; the Laravel Cloud `deploy` skill consumes them and retains
  provider-specific mechanics in its existing references.
- Lifecycle state, intervention state, and authority remain separate. A missing
  secret may make intervention `required` while deployment remains pending and
  deployment authority remains absent.
- The intervention state machine is:
  - discovery resolves to `none` when evidence proves no user-owned prerequisite
    exists, otherwise `required`;
  - `required` becomes `unverified` after the user reports or metadata suggests
    completion;
  - `unverified` becomes `completed` only after the adopted safe verification
    succeeds, and returns to `required` when verification proves the action is
    still missing;
  - `none` or `completed` may return to `required` or `unverified` when target,
    configuration, or trigger evidence drifts before the dependent effect.
  Both `required` and `unverified` block the dependent deployment trigger.
  Checkpoint state records observations but grants no authority.
- Safe verification may inspect non-secret presence/status metadata and the
  resulting deployment or application behavior, never secret values. A user
  self-report or unavailable verification stays `unverified` unless the active
  project contract explicitly accepts that evidence as sufficient.
- Variable names and ownership may be documented; secret values, credential
  material, and secret-bearing output may not be persisted or requested in chat.
- Repository adjustments are normal implementation work only when authorized.
  Privileged dashboard work, credential entry, billing/account access, DNS, and
  owner decisions remain explicit user actions unless a separately authorized
  tool can perform them safely.
- The active repository has no deployment target, so its new contract field is
  `Not applicable` with a reason; the candidate template remains unresolved and
  instructive.
- Version preparation, Git handoff, publication, deployment, and cleanup are
  outside this implementation request. The consumer-visible skill/template
  change is release-relevant and must be prepared before later integration.

## File-level scope and sequence

1. Add failing structural assertions to
   `tests/delivery-lifecycle-contract-test.sh` for primary-skill routing,
   reference fields, template variables, explicit no-intervention reporting,
   secret-safe resume instructions, and deployment-trigger blocking.
2. Add nine read-only consuming-agent fixtures and registry entries in
   `tests/agent-evals/`:
   - `v2.deployment-intervention.missing-secret` for a direct deploy blocked on
     a secret/dashboard action;
   - `v2.deployment-intervention.automatic-trigger` for integration/tag/release
     blocked before an automatic deployment;
   - `v2.deployment-intervention.owner-decision` for an unresolved owner choice;
   - `v2.deployment-intervention.repository-adjustment` for authorized agent
     work that must not be incorrectly delegated to the user;
   - `v2.deployment-intervention.unverified` for a reported-complete action
     whose safe verification is unavailable;
   - `v2.deployment-intervention.completed` for a safely verified action whose
     recorded state remains `completed` while the final action line is
     `User intervention: none`; and
   - `v2.deployment-intervention.drift` for stale completed evidence invalidated
     immediately before a direct or automatic deployment trigger;
   - `v2.deployment-intervention.multi-action` for per-action state and strict
     aggregate precedence across required, unverified, and completed work; and
   - `v2.deployment-intervention.none` for evidence-backed absence of user work.
   Update deterministic registry/profile expectations from 66 to 75 cases.
3. Add `.agents/skills/wrap/references/deployment-interventions.md` with the
   shared state model, action-card fields, timing, secret boundary, verification,
   resume, checkpoint, and final-report rules.
4. Amend `.agents/skills/deploy/SKILL.md`, `.agents/skills/wrap/SKILL.md`, and
   `.agents/skills/release/SKILL.md` so routing-critical gates remain in their
   primary instructions and detailed behavior loads from the shared reference.
5. Amend root and candidate `CONTRIBUTING.md` delivery contracts and the root
   `README.md` deployment interface. `CONTRIBUTING.md` remains the authoritative
   routing point and records, inline or through an explicit owned link, names-
   only fields for environment/target, variable or setting, sensitivity, owner,
   secure configuration location, required timing, verification, associated
   build/deploy/start/migration script, manual action, and recovery. The active
   repository records `Not applicable` because it has no deployment target.
6. Run narrow structural/profile tests, skill validation, the full offline
   deterministic suite, and proportionate consuming-agent evaluation when the
   local evaluator is available without new dependencies or external mutation.
7. Review the complete diff for operational clarity, authority separation,
   secret safety, provider neutrality, and consistency with the accepted scope.

## Test map

| Behavior | Evidence |
|---|---|
| Missing user-owned secret/dashboard step is conspicuous and blocks deploy | `missing-secret` agent case plus structural contract |
| Secret value is never requested or emitted | Required-intervention forbidden output and contract assertions |
| Resume and verification are exact | `missing-secret` and `unverified` decision fields and summary requirements |
| Complete prerequisites do not invent user work | `none` agent case |
| Automatic integration/tag/release deployment cannot bypass the gate | Wrap/release structural assertions and `automatic-trigger` case |
| Owner choices remain explicit user work | `owner-decision` case |
| Authorized repository fixes remain agent work | `repository-adjustment` case |
| Project variables have an adopted home | Active/candidate `CONTRIBUTING.md` assertions |
| Existing delivery behavior remains intact | Full `bash tests/run.sh` suite |

## Verification commands

```bash
python3 .agents/skills/skill-creator/scripts/quick_validate.py .agents/skills/deploy
python3 .agents/skills/skill-creator/scripts/quick_validate.py .agents/skills/wrap
python3 .agents/skills/skill-creator/scripts/quick_validate.py .agents/skills/release
bash tests/delivery-lifecycle-contract-test.sh
bash tests/agent-eval-profile-test.sh
# Prepare one bound deployment-intervention live run in a private /tmp output root with
# --runs 3, --jobs 1, --timeout-seconds 300, and
# --rollout-planned-limit-sum 1769472. Then rerun the identical selection with
# the emitted --expected-subject-digest and --expected-executor-sha256 plus
# --require-current-pass. Select the affected case IDs listed above.
bash tests/run.sh
```

The live cases are run only when the existing evaluator is available
without new dependencies or external mutation. Otherwise their absence is
reported; registry, fixture, grading, and full offline validation still run.

The first live attempt used six workers and exposed a shared runtime-home shell
snapshot race before most agents ran. Bound evaluations therefore use one
worker; this changes only harness concurrency, not the cases or subject.

The serialized attempt then exposed two harness-input issues rather than an
accepted behavior result: the prompts listed a hidden `.agents` context tree
without naming its files, so agents saw an apparently empty top-level context
directory, and the 131072 aggregate rollout budget divided to only 3640 tokens
per execution. The fixtures now name each bound context file directly. The
final aggregate budget is 1769472, which supports all 54 bound executions while
allowing 32768 tokens per execution; it is a ceiling, not a consumption target.
The intermediate 10922-token ceiling still terminated five turns after they
read the complete bound skills. Its completed results also showed that the
asserted bare heading conflicted with the contract's full `USER ACTION REQUIRED
— <effect> is paused` form and that several fixtures did not identify one exact
dependent effect. The final cases assert the full heading and name that effect.
Final-review remediation expands the bound set to nine cases so complete action
cards, mixed-state precedence, drift invalidation, verified completion, and the
resolved/no-action paths are measured. Targeted bound closure runs supersede
only the cases whose fixtures, prompts, or assertions changed after the original
nine-case batch; retained outputs were regraded against the final assertions.

## Scope amendment — 2026-09-24 release preparation

After implementation and convergence review, the user explicitly invoked
`wrap` and `release`. Prepare the adopted SemVer minor release `v1.10.0` because
the increment changes consumer-visible managed skills and the candidate
`CONTRIBUTING.md` template. Synchronize `VERSION`, plugin and marketplace
metadata, stable-install documentation, the ecosystem release index, and a
reviewed release note. Re-run the full offline suite and prepare one exact
read-only lifecycle preview. This amendment does not authorize commit, push,
pull-request publication, checkpoint publication, integration, tag or GitHub
release publication, deployment, or cleanup.

## Final evidence

- All three amended skills pass `quick_validate.py`; the lifecycle/profile
  contracts, JSON validation, and `git diff --check` pass.
- The final `bash tests/run.sh` passes with
  `offline-deterministic=passed` and 75 registered live cases.
- Owner-decision and evidence-backed-none closure is verified at
  `/tmp/agents-deployment-intervention-rerun.W18fPi/evidence/summary.json` with
  summary digest `8dff935c1b6755db7f1d74c4be4869a0c9131981a3c353e73d295cb8ebe85ece`.
- The strengthened mixed-action closure is verified at
  `/tmp/agents-deployment-intervention-multi-final3.asBnvG/evidence/summary.json`
  with summary digest
  `26d17b3252f7d2373d71a5c44f0e9eb0e627cafca130143e97676bead72004b7`.
- Independent convergence review returned GO with no actionable residuals.
- Release preparation synchronizes every adopted version artifact and stable
  documentation to `v1.10.0`. The release-prepared worktree passes all three
  skill validators, JSON parsing, `git diff --check`, and the full offline suite
  with 75 registered live cases. Read-only remote reconciliation found no
  `v1.10.0` tag, release, pull request, or remote topic branch.

## Failure modes and recovery

| Failure | Handling |
|---|---|
| Intervention appears only in a reference | Keep the trigger and stop rule in each primary skill; retain detail in the reference |
| Agent asks the user to paste a secret | Treat as a failing behavioral/security case; require secure location and presence-only verification |
| Agent reports ready while action is required | Fail the required-intervention case and block the dependent effect explicitly |
| Agent invents an intervention | Fail the no-intervention case; require evidence-backed `none` |
| User reports completion but safe verification is absent | Preserve `unverified`, state what evidence is missing, and keep the trigger blocked |
| Verified completion creates a third public label | Retain `completed` in checkpoint state but project the final action line to exact `User intervention: none` |
| Several actions have different states | Track state per action and aggregate with `required` before `unverified`, then `completed`, with `none` only when no action exists |
| A resolved target or prerequisite drifts | Invalidate stale resolved evidence and re-resolve intervention immediately before every direct or automatic trigger |
| Template becomes provider-specific | Keep names/owners/locations generic; provider adapters may give exact UI or CLI mechanics |
| Evaluation tooling is unavailable | Retain deterministic registry validation and report live behavior as unavailable, never passed |
| Scope reveals a provider or dependency requirement | Stop and request a new decision rather than expanding this increment |

## Completion criteria

The shared contract is linked from all three primary lifecycle skills; both
project delivery documents expose the variables; required and none paths are
registered and structurally validated; narrow and full offline checks pass;
live evaluation evidence is recorded if available; plan review and final source
review have no unresolved actionable finding; and the worktree contains only
accepted increment files.
