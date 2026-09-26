# Laravel and Nuxt Agent Ecosystem

[![Offline deterministic](https://github.com/marcus-friction/agents/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/marcus-friction/agents/actions/workflows/ci.yml)

A public set of skills, project templates, and safety rules for AI developers
building Laravel and Nuxt web applications.

## What It Does

- Guides new projects from product questions to a reviewed first increment.
- Gives agents Laravel, Nuxt, Vue, Nitro, Pinia, Vite, Vitest, VueUse, testing,
  security, performance, and delivery guidance when relevant.
- Keeps product context, architecture, plans, and decisions in the repository.
- Uses a `plan → implement → review → wrap` workflow, with integration,
  applicable release, and safe cleanup governed by each project's delivery
  contract.
- Preserves project-owned documents and unrelated work.
- Requires explicit approval for destructive, privileged, production,
  publication, and other difficult-to-reverse actions.

## Get Started

Clone this repository, open the project you want to work on, and install the
skills:

```bash
git clone --depth 1 https://github.com/marcus-friction/agents.git /path/to/agents
cd /path/to/your/project
bash /path/to/agents/install.sh --from-local /path/to/agents
```

Replace the example paths with real folders. For a new folder, run `git init`.
Reload your AI coding tool after installation.

Start a new application with:

```text
Use start-project. I want to build [your idea]. Guide me through the
decisions one at a time and plan the smallest useful first increment.
```

For an existing application, use:

```text
Use onboard-project. Explain this codebase and establish the missing project
context without overwriting existing documentation.
```

Skills load automatically when applicable. Direct installations use names such
as `review`. The Claude plugin adds `ma:`, for example `ma:review`; never `ma-`.

## Core Workflows

| Task | Skill |
|---|---|
| Start a new application | `start-project` |
| Understand an existing repository | `onboard-project` |
| Plan a change | `plan`, then `review-plan` |
| Diagnose a bug | `systematic-debugging` |
| Review completed work | `review` |
| Finish and hand off | `wrap` |
| Prepare or publish a release | `release` |
| Plan a rewrite | `migrate-project` |
| Deploy Laravel and Nuxt to Laravel Cloud | `deploy` |

`wrap` prepares the complete delivery preview but never silently commits,
pushes, integrates, releases, deploys, or cleans up. Project-specific delivery
variables belong in active `CONTRIBUTING.md`; `release` owns provider-neutral
release preparation, publication, verification, and recovery.

For a deployment readiness report, ask:

```text
Use deploy. Check whether this application is ready for Laravel Cloud.
Report the setup, costs, and blockers without changing anything.
```

To prepare and deploy, ask:

```text
Use deploy. Prepare this application for Laravel Cloud, then show me the
target, resources, costs, and recovery approach before deploying.
```

`deploy` supports Laravel-only and Laravel + Nuxt applications, including
monorepos and separate repositories. It uses the official Cloud CLI, preserves
existing project choices, and verifies the deployed application. Cloud account
access and authorization for paid resources or production changes are handled
when needed. If a secret, dashboard setting, owner decision, or other user-owned
prerequisite is required, the agent pauses the dependent effect, presents a
conspicuous names-only action checklist, and explains safe verification and the
non-secret resume signal. Otherwise it reports `User intervention: none`.

## Default Stack

New projects default to Laravel 13 on PHP 8.4, Nuxt 4, Vue 3, TypeScript,
Tailwind CSS 4, PostgreSQL 17, Pest, Vitest, and Playwright. Redis, Filament,
Sanctum, search, queues, email, Docker, observability, and deployment services
are added only when needed. Existing projects keep their documented choices
unless a replacement is explicitly approved.

The installer adds managed skills and inactive document candidates. It does not
install host runtimes or packages, overwrite project documents, commit, push,
or publish anything.

## Installation Channels

The short installation above uses the mutable `master` edge channel.

### Edge channel

This self-cleaning variant isolates the temporary checkout:

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
    git --no-replace-objects -c core.hooksPath=/dev/null \
      -c core.fsmonitor=false -c credential.helper= "$@"
  }
  source_dir="$(mktemp -d)"
  trap 'rm -rf "$source_dir"' EXIT
  edge_git clone --depth 1 --no-tags \
    https://github.com/marcus-friction/agents.git "$source_dir"
  [ -f "$source_dir/install.sh" ] && [ ! -L "$source_dir/install.sh" ]
  bash "$source_dir/install.sh" --from-local "$source_dir"
)
```

### Stable installation

Stable installation uses the full commit SHA in the
[v1.11.0 release record](https://github.com/marcus-friction/agents/releases/tag/v1.11.0).
A version becomes stable only when its release record binds that exact SHA.

<!-- stable-project-quickstart -->
```bash
(
  set -euo pipefail
  AGENTS_ECOSYSTEM_SHA="${AGENTS_ECOSYSTEM_SHA:-PASTE_THE_40_CHARACTER_SHA_FROM_THE_RELEASE}"
  AGENTS_ECOSYSTEM_SOURCE="${AGENTS_ECOSYSTEM_SOURCE:-https://github.com/marcus-friction/agents.git}"
  [[ "$AGENTS_ECOSYSTEM_SHA" =~ ^[0-9a-f]{40}$ ]]
  release_dir="$(mktemp -d)"
  trap 'rm -rf "$release_dir"' EXIT
  for git_variable in "${!GIT_@}"; do unset "$git_variable"; done
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
  export GIT_ASKPASS=/usr/bin/false GIT_TERMINAL_PROMPT=0
  export GIT_NO_REPLACE_OBJECTS=1
  export SSH_ASKPASS=/usr/bin/false SSH_ASKPASS_REQUIRE=never
  release_git() {
    git --no-replace-objects -c core.hooksPath=/dev/null \
      -c core.fsmonitor=false -c credential.helper= "$@"
  }
  release_git init -q "$release_dir"
  release_git -C "$release_dir" fetch --depth 1 --no-tags \
    "$AGENTS_ECOSYSTEM_SOURCE" "$AGENTS_ECOSYSTEM_SHA"
  release_git -C "$release_dir" checkout -q --detach FETCH_HEAD
  [ "$(release_git -C "$release_dir" rev-parse 'HEAD^{commit}')" = "$AGENTS_ECOSYSTEM_SHA" ]
  ! release_git -C "$release_dir" symbolic-ref -q HEAD
  [ -f "$release_dir/install.sh" ] && [ ! -L "$release_dir/install.sh" ]
  bash "$release_dir/install.sh" \
    --from-local "$release_dir" --ref "$AGENTS_ECOSYSTEM_SHA"
)
```

See the [ecosystem reference](docs/ecosystem-reference.md) for global and bulk
installation, updates, discovery paths, the complete skill catalog, sources,
and limitations.

## Verification

```bash
bash tests/run.sh
```

The offline suite checks installer safety, document preservation, skill routing,
portability, provenance, and deterministic evaluation contracts. Live agent
evaluations are opt-in.

## License

Original material is licensed under the [MIT License](LICENSE). Adapted material
and source notices are documented in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
