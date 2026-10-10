# Require browser subagents and reachable test targets

Update the browser-testing skills so actual browser execution uses an available
browser-capable subagent and starts only after the application is reachable from
that subagent, including through the active tool's port forwarding in remote
development.

## Scope and acceptance

- In `end2end`, require an available browser subagent, define the parent agent's
  startup and readiness duties, and verify the browser-visible URL before any
  test flow. Preserve the existing fallback when no subagent is available.
- In `playwright`, apply the same rule when executing browser tests while leaving
  source-only writing and review work unaffected.
- Preserve existing test-only authority and restrictions on shared or
  production effects. An unreachable target is blocked, not a passing test.

This is an R1 change to two upstream-managed skill files and this plan pair.
It needs no new dependencies or external effects. Reversion is a normal scoped
revert.

## Evidence and execution

`end2end` currently prefers the host browser. `playwright` has no subagent or
remote-port readiness rule. The Vue testing skill routes end-to-end work to
Playwright, so these two primary skill files cover the execution paths.

1. Make the routing and reachability contract explicit in both skills.
2. Validate both skill structures, run the existing affected skill contracts
   and repository offline suite, and inspect the final diff.

No browser application is changed here, so browser flow tests would not verify
this prose change. The key failure modes are treating host-local `localhost` as
subagent reachability, testing before forwarding is active, or creating a new
permission to expose a service publicly.

## Plan review

Scope, method, authority, and verification are proportionate to a skill-only
edit. The instructions belong in the main skills because they affect routing
before any conditional reference is loaded. No architecture, runtime, data, or
deployment changes are involved. Verdict: GO.

## Amendment — 2026-10-07: resolve reviewed fallback and coverage findings

The user selected both retained review findings for correction. Extend the
owned scope to the focused skill contract test, agent-evaluation registry and
fixtures, and its registered-case-count contract. First add a failing check for
the no-subagent fallback, then
condition Playwright's forwarding and subagent-browser preflight on actual
subagent use. Add realistic positive, negative, and boundary evaluation cases
for selection, startup/readiness, forwarding, blocked targets, and fallback.
Run the narrow checks, evaluation validation and available execution, and the
offline suite. Keep test-only authority and remote-service exposure unchanged.

## Amendment — 2026-10-07: prepare the requested delivery

The user requested commit, push, and release. The managed-skill change is
release-relevant under `CONTRIBUTING.md`; `v1.11.0` is the verified latest
release and the current `master` boundary. Prepare `v1.12.0` as a minor release
for the new browser-subagent workflow. Add `VERSION`, plugin and marketplace
metadata, stable-install references, and a release note to the owned scope.
Re-run verification on the complete payload and resolve the open quality/review
gates before any commit or publication effect. Delivery uses a topic branch,
reviewed PR and merge commit into `master`, then a tag and public GitHub release
at the verified merge SHA. The unrelated open PR remains outside scope.

## Amendment — 2026-10-07: isolate skill behavior in evaluations

The delivery testing review found that cases loading both skills could pass
while one skill's new instructions regress. Make the available and blocked
end-to-end paths consume only `end2end`, and add corresponding Playwright-only
coverage where needed. Add a source-only Playwright case proving that writing or
reviewing test code does not trigger startup, forwarding, or browser handoff.
Keep the registry, profile count, and fixtures in scope. These are coverage
corrections inside the already-authorized browser workflow and release payload.

## Amendment — 2026-10-08: repair live evaluator execution

The user requested evaluator repair after the approved live run failed before
any model turn. A syscall trace identified `/tmp/codex-daemon-1000` as a
read-only mode-000 mount in this tool sandbox; the same host directory is
user-owned mode 0700 outside it. The nested Codex CLI requires that socket
directory, so execute live cases from the host shell while retaining the
evaluator's own restricted filesystem and network policy. Add a focused
preflight that explains this environmental blocker before dispatch, and cover
it in the offline profile test. The first host probes also exposed an
inaccessible `rg` on the inherited PATH and rollout limits too small for the
current CLI/model bootstrap. Point the evaluated agent to exact bound context
paths and the available standard shell tools, and set an explicit efficient
reasoning effort. Verify with a focused live case before repeating the
selected five-case batch. Preserve
credential isolation, exact subject binding, and the original behavioral
assertions.

## Amendment — 2026-10-08: close evaluator review findings

The pre-commit evaluator review found that the supported executor override
could skip the socket preflight, several meaningful preflight branches lacked
offline tests, and three browser-skill decision paths lacked isolated
consuming-agent assertions. Extend the scoped test registry and fixtures to
cover the end-to-end host fallback, Playwright unreachable target, and complete
end-to-end subagent handoff payload. Make the socket preflight apply to the
selected real CLI while explicitly exempting the deterministic fake executor
used by the offline profile test. Add meaningful branch tests, rerun offline
verification, and then seek a revised live budget for the expanded selection.
