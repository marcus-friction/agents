# v1.12.0 — Browser subagent readiness

Prepared 2026-10-07. For stable installation, use the full commit SHA in the
[v1.12.0 release record](https://github.com/marcus-friction/agents/releases/tag/v1.12.0)
once published. `master` remains mutable.

Browser tests now use a browser-capable subagent whenever one is available.
Before testing, the orchestrating agent confirms that the application and its
required local services are ready. For remote development, it uses the active
browser tool's private port forwarding and verifies that the subagent's browser
can open the target URL. Host-local reachability alone is insufficient.

When no browser subagent is available, Playwright can use the host browser
harness after verifying its target. If a selected subagent cannot reach the app,
the browser work is blocked until readiness or forwarding is resolved within
scope. The skills do not authorize public exposure, real credentials, or shared
or production changes to make tests run.

The live-agent evaluator now detects a masked Codex app-server socket before
dispatch, supplies exact context paths and usable shell commands to each case,
and uses an explicit low reasoning effort. Its own filesystem and network
restrictions remain in force.
