# v1.13.0 — Independent review dispatch

Prepared 2026-10-10. For stable installation, use the full commit SHA in the
[v1.13.0 release record](https://github.com/marcus-friction/agents/releases/tag/v1.13.0)
once published. `master` remains mutable.

All eleven review-named skills now route separable review work to fresh,
clean-context subagents when available. The invoking reviewer retains scope,
evidence validation, and synthesis. A delegated reviewer executes its assigned
pass without delegating it again; each packet identifies that executor role.
When subagents are unavailable, direct reviews label their same-context work
and do not count it as independent corroboration. Adversarial review retains
its requirement for a successful independent executor.

Review packets and code require separate authority before transfer to an
external model or provider. The change does not grant commit, release,
deployment, or other external-effect authority.

The offline deterministic suite and focused review and specialty contracts
passed. Direct specialty, `review-plan`, and stack persona smoke passes
completed in clean-context subagents without recursive delegation. Registered
live decision evaluations were not run by the offline suite; tool-level
no-subagent and failed-adversarial-executor routes remain unverified.
