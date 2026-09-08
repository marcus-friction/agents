# Ecosystem Reference

Detailed installation, ownership, compatibility, stack, skill, source, release,
and limitation reference for the Laravel and Nuxt Agent Ecosystem. Read the root
`README.md` first for the concise overview.

## Installation

`.agents/skills/` is the canonical skill source. Generic installers update the
managed source, stage inactive project-document candidates, and register small
compatibility adapters. Adapters link to the canonical source; they do not copy
or fork skill content.

The source repository is public:

```text
https://github.com/marcus-friction/agents.git
```

### Install in one project

For the mutable edge channel, run this from the target repository. The public
route needs no GitHub CLI or private-repository authentication:

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

The default installation changes no host tooling. Dependency setup is explicit:

Add one of these options to the final installer command inside that self-cleaning
checkout:

```text
--deps frontend
--deps backend
--deps docker
--deps all
```

Each `--deps` mode presents the exact component plan and asks before host
changes. Use `--skip-deps` to omit dependency guidance. Frontend covers the
Node/Nuxt toolchain, backend covers PHP/Composer/Laravel requirements, and
Docker covers the local Sail/container capability. Projects may adopt any
subset.

### Immutable source boundary

`master` is mutable and is not a stable release. To install an audited revision,
use its full 40-character commit SHA for both acquisition and installation:

```bash
(
  set -euo pipefail
  AGENTS_ECOSYSTEM_SHA="PASTE_A_REVIEWED_40_CHARACTER_COMMIT_SHA"
  [[ "$AGENTS_ECOSYSTEM_SHA" =~ ^[0-9a-f]{40}$ ]]
  source_dir="$(mktemp -d)"
  trap 'rm -rf "$source_dir"' EXIT
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
  release_git init -q "$source_dir"
  release_git -C "$source_dir" fetch --depth 1 --no-tags \
    https://github.com/marcus-friction/agents.git "$AGENTS_ECOSYSTEM_SHA"
  release_git -C "$source_dir" checkout -q --detach FETCH_HEAD
  [ "$(release_git -C "$source_dir" rev-parse 'HEAD^{commit}')" = "$AGENTS_ECOSYSTEM_SHA" ]
  ! release_git -C "$source_dir" symbolic-ref -q HEAD
  [ -f "$source_dir/install.sh" ] && [ ! -L "$source_dir/install.sh" ]
  bash "$source_dir/install.sh" \
    --from-local "$source_dir" --ref "$AGENTS_ECOSYSTEM_SHA"
)
```

This verifies source consistency after a revision is selected; it does not by
itself authenticate the publisher. Version 1.7.0 identifies this integration,
but it is not stable until a release record binds its full commit SHA.

### User-level installation

`install-global.sh [--ref FULL_40_SHA]` maintains one canonical checkout and
registers supported user adapters. Without `--ref`, it tracks mutable `master`.
For an immutable release, run a physical `install-global.sh` from the reviewed
checkout and pass the release record's full SHA:

```bash
AGENTS_ECOSYSTEM_SHA="PASTE_THE_40_CHARACTER_SHA_FROM_THE_RELEASE"
./install-global.sh --ref "$AGENTS_ECOSYSTEM_SHA"
```

Set the destination explicitly when the default `~/.agent-ecosystem` is
unsuitable:

```bash
AGENTS_ECOSYSTEM_HOME=/absolute/path/to/.agent-ecosystem \
  ./install-global.sh --ref "$AGENTS_ECOSYSTEM_SHA"
```

Do not use `~/.agents` as the checkout; that path is reserved for discovery.

Reload supported agent tools after registration. Remote environments do not
inherit links from a local home directory, so install into the repository or
its environment separately.

### Install into several repositories

Run the bulk installer from a clean, detached checkout at the same reviewed
full SHA. Its default phase prepares private, reviewable artifacts and has no
remote effect:

```bash
./scripts/install-into-repos.sh --ref "$AGENTS_ECOSYSTEM_SHA" \
  --plan-dir /absolute/private/path/agents-plan \
  OWNER/repo-one OWNER/repo-two
```

Inspect each patch and the aggregate digest. Applying is a separate explicit
operation that revalidates the source, targets, bases, host, and plan before it
pushes an import branch:

```bash
./scripts/install-into-repos.sh --ref "$AGENTS_ECOSYSTEM_SHA" \
  --plan-dir /absolute/private/path/agents-plan \
  --apply --expected-plan-sha256 PASTE_REVIEWED_PLAN_DIGEST \
  --author-name "YOUR NAME" --author-email "YOU@example.com" \
  OWNER/repo-one OWNER/repo-two
```

Keep the plan directory private: a patch can contain removed repository data.
The installer never merges the branch and never approves its pull request.

### Cursor Cloud environment adapter

Prefer project installation. When a Cursor Cloud environment cannot carry
`.agents/skills`, run the physical adapter from a reviewed checkout:

```bash
./scripts/install-cursor-cloud.sh --ref "$AGENTS_ECOSYSTEM_SHA"
```

It registers only the generic Agent Skills and Cursor user paths. It does not
create or replace `.cursor/environment.json`. Remote homes do not inherit local
machine links, so run it in each intended environment.

### Claude Code plugin — edge only

The public marketplace exposes plugin `agents` through
`marcus-friction-plugins`, backed by `./.agents`:

```text
/plugin marketplace add marcus-friction/agents
/plugin install agents@marcus-friction-plugins
```

Restart Claude Code after first installation. For a deliberately installed
local development checkout, use `/reload-plugins` after an edit.

The Claude marketplace route is edge-only. The marketplace source cannot be
pinned to a full commit SHA by the documented host contract. An isolated probe
with Claude Code 2.1.112 also treated a 40-character `@ref` as a branch name and
rejected it. Therefore the marketplace route is mutable and must not be
presented as stable; immutable use goes through the verified Git installers.
Inspect changes before requesting a marketplace update, and do not enable
unattended updates for this edge channel.

### Discovery compatibility

| Consumer | Project discovery | User discovery |
|---|---|---|
| Agent Skills-compatible tools | `.agents/skills` | `~/.agents/skills` |
| Cursor | `.cursor/skills` → `../.agents/skills` | `~/.cursor/skills` → canonical checkout |
| Claude Code | `.claude/skills` → `../.agents/skills` | `~/.claude/skills` → canonical checkout |

The Claude router is staged as an inactive candidate at
`.agents/templates/adapters/claude/CLAUDE.md`; an installer never appends to or
replaces a project's existing provider instructions. A pre-existing discovery
path that is not the exact expected link is a collision and remains untouched.
Claude marketplace metadata exposes plugin `agents` through marketplace
`marcus-friction-plugins`, with `./.agents` as its source.

## Ownership and Update Contract

Installation and semantic adoption are separate operations:

| Path | Owner | Install or update behavior |
|---|---|---|
| `.agents/skills/` | Mixed by path | Refresh upstream paths; retain and report local-only skill paths. |
| `.agents/tools/` | Upstream | Refresh managed component-aware tools. |
| `.agents/legal/` and `.agents/.claude-plugin/` | Upstream after marked adoption | Refresh only through the managed-tree contract. |
| `project-templates/base/` | Upstream | Canonical source for document candidates. |
| `.agents/templates/` | Upstream-generated candidate state | Restage inactive candidates; never activate them. |
| `.agents/project/` | Project | Never overwrite; store approved reconciliation state here. |
| Root project documents | Project | Never create, append to, or replace mechanically. |
| Existing provider instructions | Project | Never append to or replace mechanically. |

Root project documents include `README.md`, `AGENTS.md`, `CONTRIBUTING.md`,
`ARCHITECTURE.md`, `DESIGN.md`, and any established equivalents. Installation
preserves their bytes even when a newer upstream candidate exists.

Before the first write, installation preflights managed targets, candidates,
adapter paths, symlink ancestors, non-regular files, and type conflicts. Managed
updates are assembled away from the target and revalidated before replacement.
Run one installer at a time. Restoration after an interrupted commit is
best-effort; crash-level atomicity is not claimed.

Put durable project context under `.agents/project/` and give local skills
unique names. An updater cannot distinguish an intentional modification from an
obsolete upstream file when both use the same managed path.

## Candidate Adoption

`project-templates/base/` contains candidates for `README.md`, `AGENTS.md`,
`ARCHITECTURE.md`, `CONTRIBUTING.md`, and `DESIGN.md`. Installation stages
byte-identical copies under `.agents/templates/`.

Use `onboard-project` to compare candidates with repository evidence. The
workflow preserves existing content, inventories relevant meaning, classifies
the proposed change, and presents an exact patch for approval. Clean R1/R2
document changes may combine the semantic summary and patch decision. R3 changes
retain separate gates, a durable relevant inventory, and strict revalidation.

`start-project` delegates document reconciliation to the same workflow. A
request to start fresh does not authorize erasing an existing README, badge,
setup command, license, local constraint, or uncommitted edit.

## Component Applicability and Assurance

The ecosystem prefers Laravel 13/PHP 8.4 with Nuxt 4/Vue 3, but a project must
classify each capability:

| Status | Effect |
|---|---|
| **Adopted** | The component and its applicable rules are active. |
| **Optional** | Preferred if needed later; not implementation approval. |
| **Not applicable** | Outside the accepted scope. |
| **Unresolved** | A material decision is missing; do not invent it. |

For every affected trust or data boundary, record exposure, data impact,
privilege, reversibility or availability, control owner, and evidence. These
facts select security and operational controls. They are independent of
component status and change rigor.

The preferred full stack includes:

- Laravel 13, PHP 8.4, Eloquent, PostgreSQL 17, and Redis;
- Nuxt 4, Vue 3 Composition API, TypeScript, Tailwind CSS 4, Pinia, and Nitro;
- Filament 4, Sanctum, Scout/Meilisearch, Horizon, Telescope, and Pulse when
  their capabilities are adopted;
- Pest 4, Larastan Level 9, Pint, ESLint, Vitest, and Playwright;
- Sail for local development and the adopted Forge, PM2, and Cloudflare
  delivery path unless the project approves a replacement.

Existing project evidence wins over a preferred default. A migration requires
an explicit scope, parity plan, and replacement decision.

## Change Rigor

The canonical classifier is
`.agents/skills/review/references/change-rigor.md`:

| Level | Typical trigger | Handling |
|---|---|---|
| **R0** | Read-only inspection | No repository or external writes. |
| **R1** | Clean additive and reversible work | Implement directly and verify. |
| **R2** | Public contracts, existing meaning, planned dependencies, or bounded cross-file effects | Add proportionate planning, tests, and standard review. |
| **R3** | Deletion, weakening, dirty or special targets, conflict, sensitive boundaries, destructive migration, production effect, or irreversibility | Require explicit decisions, exact-target revalidation, and conditional independent review. |

The highest trigger wins, and relevant uncertainty escalates. Runtime exposure
does not determine approval count. Skills alter the method used inside existing
authority; they never create authority to mutate code, documents, hosts, or
external systems.

## Testing and Review Policy

Aim for 100% line and branch coverage of testable production behavior. Cover
changed observable outcomes and meaningful failure paths, test-first by
default. For existing implementation, characterize valid behavior and add a
failing test for the intended delta; do not delete working code because it
predates its tests.

Do not invent tests for human prose, behavior-free configuration, generated
artifacts, unreachable code, or trivial forwarding without an executable
contract. Record justified exclusions. Coverage demonstrates execution, not
correctness; assertions and boundary selection still matter.

Use `review` for normal work. `ma-review` may run applicable architecture,
security, and performance specialties in parallel while remaining report-only
unless fixes were explicitly authorized. Reserve `review-gstack` and independent
adversarial review for R3, significant architecture/security/data/production
work, or an explicit request.

## Skills

The catalog follows declared skill names, including the
`laravel-best-practices` name exposed by the physical `laravel/` directory.

| Skill | Purpose | Source |
|---|---|---|
| `adversarial-review` | Independently challenge hazardous or significant changes | [gstack](https://github.com/garrytan/gstack) |
| `architecture-review` | Review compliance with adopted architecture boundaries | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `brainstorm` | Explore technical approaches and engineering tradeoffs | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `build-start-scripts` | Build reliable local development startup scripts | Original |
| `changelog` | Summarize recent merges as an engaging changelog | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `code-review-excellence` | Improve the method and quality of code review | Original |
| `compound` | Capture a solved problem as reusable project knowledge | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `contribute-back` | Prepare a bounded upstream contribution proposal | Original |
| `copy-editing` | Improve existing copy through structured editing sweeps | [Marketing Skills](https://github.com/coreyhaines31/marketingskills) |
| `copywriting` | Write clear, persuasive marketing and product copy | [Marketing Skills](https://github.com/coreyhaines31/marketingskills) |
| `design-consultation` | Establish or amend an evidence-backed visual system | [gstack](https://github.com/garrytan/gstack) |
| `end2end` | Plan and run browser-based user-flow tests | Original |
| `laravel-best-practices` | Apply Laravel 13 architecture, security, data, and testing patterns | [Laravel Boost](https://github.com/laravel/boost) |
| `ma-architecture-review` | Run the Laravel/Nuxt architecture review persona | Original |
| `ma-performance-review` | Run the Laravel/Nuxt performance review persona | Original |
| `ma-review` | Orchestrate parallel Laravel/Nuxt specialist reviews | Original |
| `ma-security-review` | Run the Laravel/Nuxt security review persona | Original |
| `migrate-project` | Plan a behavior-preserving migration into adopted components | [TomFit Agent Ecosystem](https://github.com/TomFitAG/tomfit-agents) |
| `nitro` | Guide Nitro server routes, storage, caching, and deployment | [antfu/skills](https://github.com/antfu/skills) |
| `nuxt` | Guide Nuxt 4 routing, SSR, data fetching, and modules | [antfu/skills](https://github.com/antfu/skills) |
| `office-hours` | Test product demand or shape a builder project | [gstack](https://github.com/garrytan/gstack) |
| `onboard-project` | Reconcile ecosystem candidates with an existing repository | Original |
| `path-to-10` | Apply a rigorous quality standard to plans and outputs | Original |
| `performance-review` | Review measured performance risks in adopted components | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `pinia` | Guide typed Pinia stores, SSR, plugins, and tests | [antfu/skills](https://github.com/antfu/skills) |
| `plan` | Scope and verify multi-step or high-risk implementation work | [gstack](https://github.com/garrytan/gstack) |
| `playwright` | Apply robust browser testing, locator, and isolation patterns | [TomFit Agent Ecosystem](https://github.com/TomFitAG/tomfit-agents) |
| `review` | Perform a scoped, multi-angle pre-merge review | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `review-gstack` | Run rigorous pre-landing review for significant changes | [gstack](https://github.com/garrytan/gstack) |
| `review-plan` | Challenge an implementation plan before execution | [gstack](https://github.com/garrytan/gstack) |
| `security-review` | Review proportionate controls at affected trust boundaries | [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) |
| `seo-review` | Review SEO, Core Web Vitals, semantics, and E-E-A-T | [Agentic SEO](https://github.com/Bhanunamikaze/Agentic-SEO-Skill) and [Marketing Skills](https://github.com/coreyhaines31/marketingskills) |
| `skill-creator` | Create, improve, and evaluate agent skills | [Anthropic Skills](https://github.com/anthropics/skills) |
| `start-project` | Clarify and plan the smallest valuable new project | Original |
| `stats` | Summarize the day's work in project context | Original |
| `systematic-debugging` | Reproduce, isolate, test hypotheses, and verify a fix | [Superpowers](https://github.com/obra/superpowers) |
| `tailwind-v4-shadcn` | Apply Tailwind v4 and shadcn/ui theme patterns | [Jezweb Claude Skills](https://github.com/jezweb/claude-skills) |
| `terminal-blindness-fix` | Diagnose missing or unreadable VS Code terminal output | Original |
| `test-driven-development` | Drive observable behavior through red, green, and refactor | [Superpowers](https://github.com/obra/superpowers) |
| `ui-accessibility-review` | Review design fit, responsiveness, and WCAG AA | Original |
| `update-agents` | Refresh managed ecosystem assets without replacing project policy | Original |
| `vite` | Guide Vite configuration, plugins, SSR, and builds | [antfu/skills](https://github.com/antfu/skills) |
| `vitest` | Guide Vitest tests, mocks, coverage, and fixtures | [antfu/skills](https://github.com/antfu/skills) |
| `vue` | Guide Vue 3 Composition API and built-in components | [antfu/skills](https://github.com/antfu/skills) |
| `vue-best-practices` | Apply Vue 3 Composition API, TypeScript, and SSR practices | [Vue.js AI Skills](https://github.com/vuejs-ai/skills) |
| `vue-router-best-practices` | Apply Vue Router 4 navigation and lifecycle patterns | [Vue.js AI Skills](https://github.com/vuejs-ai/skills) |
| `vue-testing-best-practices` | Test Vue components and flows with the appropriate layer | [Vue.js AI Skills](https://github.com/vuejs-ai/skills) |
| `vueuse-functions` | Select and apply maintainable VueUse composables | [VueUse](https://github.com/vueuse/vueuse) |
| `whats-next` | Report repository status and useful next work | Original |
| `wrap` | Prepare requested commits or pushes with separate authority | Original |

Skills load on demand. Framework skills do not authorize adopting their
framework in a project where the component is optional, absent, or unresolved.

## Document Budgets

Budgets keep high-frequency context useful. Targets prompt deduplication; hard
ceilings fail repository acceptance. They never authorize truncating a
project-owned downstream document.

| Upstream-controlled document | Preferred words | Hard ceiling |
|---|---:|---:|
| Root `README.md` | 1,500 | 1,800 |
| Root `AGENTS.md` | 450 | 550 |
| Root `CONTRIBUTING.md` | 400 | 500 |
| Base `README.md` | 350 | 450 |
| Base `AGENTS.md` | 500 | 600 |
| Base `ARCHITECTURE.md` | 900 | 1,050 |
| Base `CONTRIBUTING.md` | 400 | 500 |
| Base `DESIGN.md` | 550 | 700 |
| Combined base README, AGENTS, ARCHITECTURE, CONTRIBUTING | 2,200 | 2,500 |

Keep decisions and everyday safeguards in the base documents. Move procedures,
examples, catalogs, and extended rationale to this reference or the owning
skill. `DESIGN.md` loads only for interface work.

## Sources

This ecosystem contains original, adapted, and retained material. Exact
revisions, local paths, modification status, hashes, and required notices belong
in the repository's license, third-party notices, and retained-provenance
manifest.

Primary sources include:

| Source | Areas informed or adapted |
|---|---|
| gstack by Garry Tan | Planning, mega review, adversarial review, office hours, design consultation |
| Compound Engineering by Every and Kieran Klaassen | Review, architecture, security, performance, brainstorm, changelog, compound workflow |
| Superpowers by Jesse Vincent | Systematic debugging and test-driven development |
| Laravel Boost | Laravel framework guidance |
| antfu/skills | Nuxt, Nitro, Vue, Vite, Vitest, Pinia, and VueUse references |
| vuejs-ai/skills | Vue Router and Vue testing guidance |
| Jezweb Claude Skills and shadcn/ui | Tailwind v4 and shadcn patterns and templates |
| Anthropic Skills | Skill creator workflow and tooling |
| Agentic SEO Skill and Marketing Skills | SEO, copywriting, and copy editing |
| Google Labs DESIGN.md | Base design-document format |

Framework or vendor references do not imply that vendor text was copied. Refer
to the legal files for the authoritative classification.

## Releases

- **v1.7.0 — unreleased integration, 2026-09-07:** Added proportional
  governance, candidate ownership, safer distribution semantics, and workflow
  contracts while retaining Laravel/Nuxt specialties. See
  [`2026-09-07-proportional-ecosystem-port.md`](releases/2026-09-07-proportional-ecosystem-port.md).
- **v1.6.0 — 2026-08-20:** Synchronized Nuxt, Vitest, VueUse, Nitro, Laravel,
  debugging, TDD, marketing, SEO, and review references; consolidated root
  governance and added multi-agent review.
- **v1.5.4 — 2026-04-21:** Corrected skill front matter.
- **v1.5.3 — 2026-04-21:** Added progressive end-to-end browser testing.
- **v1.5.2 — 2026-04-21:** Added dependency onboarding, Claude discovery, and
  operational status guidance.
- **v1.5.0–v1.5.1 — 2026-04:** Restructured documentation and synchronized core
  ecosystem workflows.
- **v1.0.0–v1.4.0 — 2026-02 to 2026-04:** Established the Laravel/Nuxt baseline,
  review workflows, professionalized skills, and `.agents/` layout.

Historical release notes under `docs/releases/` remain authoritative for their
original scope and are not rewritten by later policy.

## Known Limitations

- Version 1.7.0 is an unreleased integration version. `master` remains an edge
  channel; no immutable stable release is published by this update.
- Provider links do not cross machines or remote environments automatically.
- Full dependency bootstrap targets macOS and Linux; native Windows projects use
  WSL2 for the complete Laravel/Nuxt baseline.
- Installation performs preflight and best-effort restoration but does not claim
  crash-level atomicity. Run only one installer per target at a time.
- Candidate staging cannot decide project architecture. A project owner must
  reconcile and approve active document changes.
- Forge, PM2, and Cloudflare are the ecosystem's adopted delivery defaults, not
  authority to create accounts, alter production, or replace documented project
  infrastructure.

## Licensing Status

Contributor-owned ecosystem material is licensed under the repository
[`LICENSE`](../LICENSE). Adapted and retained material keeps the source,
revision, license, notices, and modification status recorded in
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) and the distributed
provenance lock. Version 1.7.0 remains an unreleased integration; publication
still requires a release record that binds its exact full commit SHA.
