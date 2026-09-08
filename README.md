# Laravel and Nuxt Agent Ecosystem

An opinionated, reusable instruction set for coding agents working with Laravel
13, PHP 8.4, Nuxt 4, Vue 3, Tailwind CSS 4, and their surrounding tools. It
combines concise project governance, on-demand skills, safe document candidates,
and multi-tool discovery without making every change follow the same ceremony.

## Why It Exists

Coding agents need enough context to respect a project without carrying an
entire handbook into every task. This ecosystem provides:

- **Stack-aware guidance:** Laravel, Nuxt, Vue, Pinia, Filament, Pest, Vitest,
  Playwright, PostgreSQL, Redis, and deployment conventions load when relevant.
- **Proportional assurance:** routine changes stay lightweight; risky or
  irreversible work receives stronger planning, approval, and review.
- **Project evidence first:** active repository decisions override candidates
  and generic framework defaults.
- **Safe adoption:** managed skills can update while project-owned documents and
  local extensions remain under project control.

## How Assurance Scales

| Change | Expected handling |
|---|---|
| **R0 — read-only** | Inspect and report with no repository or external writes. |
| **R1 — clean additive** | Implement within scope and verify the result. |
| **R2 — bounded semantic** | Add proportionate planning, tests, and standard review. |
| **R3 — hazardous** | Revalidate exact targets and require explicit decisions for destructive, privileged, production, or irreversible effects. |

The complete classifier lives in
[`change-rigor.md`](.agents/skills/review/references/change-rigor.md). Runtime
component applicability, security assurance, and change rigor are separate
decisions: a small public copy edit can be R1 while a local credential change is
R3.

## Preferred Stack

| Capability | Default specialization |
|---|---|
| Backend | Laravel 13, PHP 8.4, Eloquent, PostgreSQL 17 |
| Admin | FilamentPHP 4 |
| Frontend | Nuxt 4, Vue 3 Composition API, TypeScript, Tailwind CSS 4 |
| State and server | Pinia 3, Nitro |
| Search and identity | Laravel Scout with Meilisearch, Laravel Sanctum |
| Cache and background work | Redis, Laravel Horizon |
| Quality | Larastan Level 9, Pint, Pest 4, ESLint, Vitest, Playwright |
| Observability | Telescope for development, Pulse for production |
| Delivery | Laravel Sail locally; Forge, PM2, and Cloudflare in deployed environments |

Downstream projects classify each capability as **Adopted**, **Optional**, **Not
applicable**, or **Unresolved**. Guidance applies only to adopted components.
Existing project structure and recorded decisions remain authoritative until an
approved migration replaces them.

## Install in a Project

### Edge channel

The repository is public. For the mutable `master` channel, clone a physical
checkout and run its installer from the target project:

<!-- edge-project-quickstart -->
```bash
(
  set -euo pipefail
  for git_variable in "${!GIT_@}"; do unset "$git_variable"; done
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_SYSTEM=/dev/null
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_ASKPASS=/usr/bin/false GIT_TERMINAL_PROMPT=0
  export GIT_NO_REPLACE_OBJECTS=1
  export SSH_ASKPASS=/usr/bin/false SSH_ASKPASS_REQUIRE=never
  edge_git() {
    git --no-replace-objects \
      -c core.hooksPath=/dev/null \
      -c core.fsmonitor=false \
      -c credential.helper= \
      "$@"
  }

  source_dir="$(mktemp -d)"
  trap 'rm -rf "$source_dir"' EXIT
  edge_git clone --depth 1 --no-tags \
    https://github.com/marcus-friction/agents.git "$source_dir"
  [ -f "$source_dir/install.sh" ] && [ ! -L "$source_dir/install.sh" ]
  bash "$source_dir/install.sh" --from-local "$source_dir"
)
```

The default path changes no host tooling. Use `--deps frontend`, `--deps
backend`, `--deps docker`, or `--deps all` to review and confirm a component
setup plan; use `--skip-deps` to omit dependency guidance.

### Stable channel (not yet published)

Version **1.7.0** identifies this integration, but it is not stable until a
release record binds its exact full commit SHA. The block below is ready for
that release. Until then, use it only with a reviewed detached checkout through
`AGENTS_ECOSYSTEM_SOURCE` or an explicitly reviewed full SHA.

<!-- stable-project-quickstart -->
```bash
(
  set -euo pipefail
  for git_variable in "${!GIT_@}"; do unset "$git_variable"; done
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
  export GIT_ASKPASS=/usr/bin/false GIT_TERMINAL_PROMPT=0
  export GIT_NO_REPLACE_OBJECTS=1
  export SSH_ASKPASS=/usr/bin/false SSH_ASKPASS_REQUIRE=never
  release_git() {
    git --no-replace-objects \
      -c core.hooksPath=/dev/null \
      -c core.fsmonitor=false \
      -c credential.helper= \
      "$@"
  }

  if [ -n "${AGENTS_ECOSYSTEM_SOURCE:-}" ]; then
    release_dir="$(cd "$AGENTS_ECOSYSTEM_SOURCE" && pwd -P)"
    release_sha="${AGENTS_ECOSYSTEM_SHA:-$(release_git -C "$release_dir" rev-parse 'HEAD^{commit}')}"
  else
    release_sha="${AGENTS_ECOSYSTEM_SHA:-PASTE_THE_40_CHARACTER_SHA_FROM_THE_RELEASE}"
    release_dir="$(mktemp -d)"
    trap 'rm -rf "$release_dir"' EXIT
    release_git init -q "$release_dir"
    release_git -C "$release_dir" fetch --depth 1 --no-tags \
      https://github.com/marcus-friction/agents.git "$release_sha"
    release_git -C "$release_dir" checkout -q --detach FETCH_HEAD
  fi

  [[ "$release_sha" =~ ^[0-9a-f]{40}$ ]]
  [ "$(release_git -C "$release_dir" rev-parse 'HEAD^{commit}')" = "$release_sha" ]
  ! release_git -C "$release_dir" symbolic-ref -q HEAD
  [ -f "$release_dir/install.sh" ] && [ ! -L "$release_dir/install.sh" ]
  bash "$release_dir/install.sh" \
    --from-local "$release_dir" --ref "$release_sha"
)
```

The mutable `master` branch remains the edge channel and must not be presented
as the stable 1.7.0 release.

After installation, ask the agent to run `onboard-project` for an existing
repository or `start-project` for a new one. Review inactive document candidates
before adopting any of them as project policy.

## Ownership and Safe Adoption

| Path | Ownership and update behavior |
|---|---|
| `.agents/skills/`, `.agents/tools/`, `.agents/legal/` | Upstream-managed; local-only skill paths are retained. |
| `project-templates/base/` | Canonical source for inactive document candidates. |
| `.agents/templates/` | Regenerated candidate state; never activated automatically. |
| `.agents/project/` | Project-owned reconciliation state; never overwritten. |
| Root `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, `ARCHITECTURE.md`, `DESIGN.md` | Project-owned; installation never creates, appends to, or replaces them. |

Tool adapters expose the same canonical skills through `.agents/skills`,
`.cursor/skills`, and `.claude/skills`. The installer preflights collisions and
unsafe target types before updating managed content. See the
[`ecosystem reference`](docs/ecosystem-reference.md) for installation channels,
recovery limits, compatibility paths, and the full skill catalog.

## Core Workflows

| Need | Skill |
|---|---|
| Understand an existing repository | `onboard-project` |
| Shape a new product and its first increment | `start-project`, `office-hours` |
| Plan a bounded change or migration | `plan`, `review-plan`, `migrate-project` |
| Diagnose unexpected behavior | `systematic-debugging` |
| Implement testable behavior | `test-driven-development` |
| Test a user flow | `end2end`, `playwright` |
| Review ordinary changes | `review` |
| Run parallel specialist review | `ma-review` |
| Review hazardous or significant work | `review-gstack`, `adversarial-review` |
| Prepare requested commits and pushes | `wrap` |

Framework references for Laravel, Nuxt, Nitro, Vue, Vue Router, Pinia, Vite,
Vitest, VueUse, and Tailwind remain first-class specialties. Marketing, design,
accessibility, SEO, security, performance, debugging, and skill-authoring
guidance load only when their task matches.

## Repository Map

| Path | Purpose |
|---|---|
| `.agents/skills/` | Canonical task-specific workflows and framework references. |
| `.agents/tools/` | Managed, component-aware supporting tools. |
| `project-templates/base/` | Inactive candidates for foundational project documents. |
| `tests/` | Offline policy, installer, portability, and workflow contracts. |
| `docs/` | Extended reference, releases, and implementation knowledge. |

## Verification

Run the offline repository contracts with:

```bash
bash tests/run.sh
```

Consuming projects should run their own Laravel, Nuxt, and browser checks for
the components affected by a change. Coverage is execution evidence, not proof
of correctness; assertions must cover observable outcomes and meaningful
failure paths.

## Documentation and Sources

Read [`AGENTS.md`](AGENTS.md) for always-on repository rules and
[`CONTRIBUTING.md`](CONTRIBUTING.md) for the development workflow. The
[`ecosystem reference`](docs/ecosystem-reference.md) contains detailed
installation guidance, the complete skill and source inventory, release history,
document budgets, and known limitations.

Original ecosystem material is covered by [`LICENSE`](LICENSE). Adapted
material retains its upstream notices and provenance in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md), also distributed with the
managed tree.
