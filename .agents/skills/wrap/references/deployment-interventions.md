# Deployment Interventions

Use this provider-neutral contract whenever a deployment prerequisite may need
a person, or when integration, a tag, or a release can trigger deployment. A
deployment intervention is observed state, not deployment authority.

## Keep three decisions separate

Track the deployment lifecycle, deployment authority, and user-intervention
state independently. Assign a state to every identified user-owned action, then
derive exactly one aggregate intervention state:

- **`none`** — evidence shows no user-owned prerequisite is outstanding for the
  exact target and effect.
- **`required`** — at least one user-owned action or decision is outstanding.
- **`unverified`** — the action was reported or appears to be complete, but the
  project-required safe verification is unavailable, incomplete, or failed.
- **`completed`** — every identified user-owned action passed its adopted safe
  verification for the current target and effect.

When a structured result requests the intervention state, emit exactly one of
those four lowercase tokens. Do not substitute lifecycle or authority words
such as `blocked`, `pending`, `not-required`, or `ready`.

Aggregate with strict precedence: any action in `required` makes the aggregate
`required`; otherwise any action in `unverified` makes it `unverified`; otherwise
one or more identified actions all in `completed` makes it `completed`; no
identified user-owned actions makes it `none`. Never let progress on one action
hide another action's stronger blocking state. Emit one action card for every
action in `required` or `unverified`.

Discovery resolves each action to `required`. A reported or apparently applied
action moves only that action to `unverified`; only successful verification
moves it to `completed`. Failed verification returns that action to `required`
when it is still missing and otherwise leaves it `unverified` with the evidence
gap. Target, configuration, script, or trigger drift invalidates the affected
`none` or `completed` evidence. Rediscover user-owned actions for the exact
current effect before deriving a new aggregate. Drift alone is not an action:
a verified empty inventory returns `none`, while identified actions use the
precedence above. If the inventory cannot be established, pause the dependent
effect for an unresolved evidence gap without inventing a user-action card or
assigning `required` or `unverified` to a nonexistent action.

Both `required` and `unverified` block the dependent effect. The agent must not
proceed with a direct deployment or an integration, tag, release, or other
operation that triggers deployment. `none` and `completed` resolve only this
gate; neither grants authority for the dependent effect.

## Classify the action

- **Secret/access** — secret entry, account or billing access, privileged
  dashboard work, DNS, or another action the agent cannot safely perform with
  the authorized tools. Never ask the user to paste a secret value into chat.
- **Owner decision** — a choice such as environment, region, domain, budget,
  resource tier, data timing, or recovery tradeoff that only the owner can make.
- **Repository adjustment** — a build, deploy, start, migration, or application
  configuration change that belongs in reviewed source. When scoped edits are
  authorized, the agent prepares and tests them. Otherwise it requests repository
  edit authority; it does not mislabel technical work as a manual user chore.

When a structured result requests the category, emit exactly `secret/access`,
`owner decision`, or `repository adjustment`; do not change spacing or
punctuation.

## Write an actionable intervention card

For every user-owned action, report names and metadata only:

- environment/target;
- action category and owner;
- variable or setting name, never its value;
- sensitivity and secure configuration location;
- manual action and reason;
- required before which exact effect;
- associated build, deploy, start, or migration scripts;
- exact blocked effect and consequence if skipped;
- safe verification and evidence owner;
- recovery implications; and
- the resume signal the user should provide without including a secret.

The active `CONTRIBUTING.md` is the authoritative routing point for these
fields. A large inventory may live in a linked deployment record, but
`CONTRIBUTING.md` must identify that exact owned location and retain the trigger,
owner, verification, and recovery contract.

## Verify without exposing secrets

Use non-secret presence or status metadata and, where applicable, the resulting
deployment or application behavior. Do not read, echo, diff, log, or persist a
secret value merely to prove configuration. A variable name being present may
prove configuration but not operational effectiveness; apply the additional
health or behavior check adopted by the project.

A user self-report, screenshot without sufficient identity, or unavailable
metadata remains `unverified` unless the active project contract explicitly
accepts that evidence. State exactly what verification is missing. Do not ask
the user to re-enter a secret merely because agent-side verification is limited.

## Surface the gate immediately

As soon as a blocking action is known, use a conspicuous progress message and
repeat the unresolved gate in the final handoff:

```text
USER ACTION REQUIRED — <exact effect> is paused
State: required | unverified
Environment/target: <exact environment and target>
Category: <secret/access | owner decision>
Variable/setting: <name only, never a secret value>
Sensitivity: <secret | sensitive | non-secret>
Action: <bounded action, without a secret value>
Reason: <why the action is required>
Where: <secure location>
Owner: <person or role>
Required before: <effect>
Associated scripts: <build/deploy/start/migration scripts or none identified>
Blocked effect: <exact effect>
Consequence if skipped: <concrete consequence>
Verification: <safe evidence the agent will inspect>
Evidence owner: <person or role that can inspect it>
Recovery: <recovery implication or action>
Resume with: <non-secret confirmation>
```

When evidence proves that no user action is pending, say exactly:

```text
User intervention: none
```

Do not paraphrase that sentence in a final or structured handoff.

After successful verification, retain canonical state `completed` in the
checkpoint and deployment record. Because no user action remains pending, the
final user-intervention line is still exactly `User intervention: none`; report
the completed verification evidence under the deployment result instead. A
deployment summary may not say ready, complete, or verified while the
intervention state is `required` or `unverified`.

Record the state, action identifiers, blocked effect, non-secret evidence,
owner, and verification time in the adopted deployment record or checkpoint.
Never store secret values there. A checkpoint records facts and never grants
authority.

Immediately before a direct deployment or an integration, tag, release, or
other effect that triggers deployment, re-resolve every intervention action
against the exact current target, configuration, scripts, trigger, and safe
verification evidence. Stale `none` or `completed` state never survives relevant
drift. Recompute from current identified actions and evidence; a verified empty
inventory resolves to `none`. If prerequisite discovery cannot be completed,
keep the dependent effect paused as an unresolved evidence gap without claiming
a user-owned intervention state.
