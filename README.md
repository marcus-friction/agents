# Agent Rules

Opinionated rule files for AI coding agents working on a **Laravel 13 + Nuxt 4** full-stack monorepo. These rules ensure agents follow ecosystem conventions, project standards, and established workflows — instead of reinventing the wheel.

## Stack

| Layer | Technology |
|---|---|
| Backend | Laravel 13, PHP 8.4, PostgreSQL 17, Redis |
| Admin | FilamentPHP 4 |
| Frontend | Nuxt 4 (SSR), Tailwind CSS 4, Pinia 3, TypeScript |
| Search | Meilisearch via Laravel Scout |
| Auth | Laravel Sanctum |
| Infrastructure | Laravel Sail (dev), Laravel Forge (deploy), PM2 (SSR), Cloudflare (CDN) |
| Quality | Larastan (L9), Laravel Pint, Pest 4, ESLint, Vitest |
| Monitoring | Laravel Horizon, Telescope (dev), Pulse (prod) |

## Rule Files

Rules live in `.agent/rules/` and are numbered by category:

| # | File | Purpose |
|---|---|---|
| `00` | `00_meta.md` | Agent persona, conduct, and anti-patterns |
| `10` | `10_project.md` | Project context template (name, vision, goals, users) |
| `20` | `20_stack.md` | Tech stack, directory structure, dependency discipline |
| `21` | `21_standards_laravel.md` | Laravel conventions, first-party tool usage, refactoring triggers |
| `22` | `22_standards_nuxt.md` | Nuxt conventions, SSR patterns, component standards |
| `23` | `23_design_system.md` | Design tokens, color, typography, motion, spacing |
| `24` | `24_accessibility.md` | WCAG compliance, ARIA, keyboard navigation |
| `40` | `40_workflow_development.md` | Branching, PRs, review checklist, git hooks |
| `41` | `41_workflow_testing.md` | Pest, Vitest, architecture tests, coverage expectations |
| `42` | `42_workflow_debugging.md` | Debugging procedures and tools |
| `43` | `43_workflow_deployment.md` | Deploy pipeline, rollback strategy, pre-merge checklist |
| `44` | `44_workflow_database.md` | Migration standards, backup procedures, safety rules |
| `50` | `50_security.md` | Security hardening (general, Laravel, Nuxt) |
| `60` | `60_infrastructure.md` | Environment matrix, service configuration |

## Skills

Skills live in `.agent/skills/` and provide deep, on-demand guidance when a task matches:

| Skill | Purpose | Source |
|---|---|---|
| `architecture-review` | Architecture compliance checklist for code review | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `performance-review` | Performance analysis checklist for code review | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `security-review` | Security audit checklist for code review | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `seo-review` | Comprehensive SEO, Core Web Vitals, Semantic HTML, and E-E-A-T review | Adapted from [Agentic-SEO-Skill](https://github.com/Bhanunamikaze/Agentic-SEO-Skill) & [skills.sh](https://skills.sh/coreyhaines31/marketingskills/seo-audit) |
| `review-gstack` | Mega Review pipeline w/ Target Scope Detection and Auto-Fixing | Adapted from [gstack](https://github.com/garrytan/gstack) |
| `review-plan` | 5-Phase Mega Plan Review (CEO, Design, Eng) w/ interactive questioning | Adapted from [gstack](https://github.com/garrytan/gstack) |
| `adversarial-review` | Destructive "Red Team" review to eliminate shared blind spots | Adapted from [gstack](https://github.com/garrytan/gstack) |
| `changelog` | Generates engaging changelogs from recent merges | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `systematic-debugging` | Reproduce → Isolate → Hypothesize → Verify → Fix | Adapted from [Vercel Skills.sh](https://skills.sh) |
| `test-driven-development` | Red → Green → Refactor TDD cycle | Adapted from [Vercel Skills.sh](https://skills.sh) |
| `ui-accessibility-review` | Design system, responsive, WCAG AA checklist | Adapted from [Vercel Skills.sh](https://skills.sh) |
| `code-review-excellence` | Meta-level review guidance — how to review well | Adapted from [Vercel Skills.sh](https://skills.sh) |
| `laravel` | Laravel operational patterns — Artisan generators, Eloquent, testing, Laravel 13 structure | Synthesized from [laravel/boost](https://github.com/laravel/boost) |
| `vue-best-practices` | Vue 3 Composition API reference — reactivity, components, SSR, TypeScript | From [antfu/skills](https://github.com/antfu/skills) |
| `nuxt` | Nuxt framework reference — routing, SSR, data fetching, Nitro, modules | From [antfu/skills](https://github.com/antfu/skills) |
| `vitest` | Vitest API reference — test/describe, mocking, coverage, environments | From [antfu/skills](https://github.com/antfu/skills) |
| `pinia` | Pinia store patterns — composables, testing, SSR, plugins | From [antfu/skills](https://github.com/antfu/skills) |
| `vueuse-functions` | VueUse composable catalog — browser, state, sensors, reactivity | From [antfu/skills](https://github.com/antfu/skills) |
| `tailwind-v4-shadcn` | Tailwind v4 + shadcn/ui — @theme, CSS variables, dark mode | From [jezweb/claude-skills](https://github.com/jezweb/claude-skills) |
| `office-hours` | Brainstorming and startup validation check ("Boil the Lake") | From [garrytan/gstack](https://github.com/garrytan/gstack) |
| `skill-creator` | Create new skills, modify existing skills, and measure skill performance | From [anthropics/skills](https://github.com/anthropics/skills) |
| `design-consultation` | Comprehensive design, typography, color, and aesthetic consultation | From [garrytan/gstack](https://github.com/garrytan/gstack) |
| `copywriting` | Principles for clear, user-centric marketing and UI copy | From [skills.sh](https://skills.sh/coreyhaines31/marketingskills/copywriting) |
| `copy-editing` | The Seven Sweeps framework for reviewing and enhancing existing copy | From [skills.sh](https://skills.sh/coreyhaines31/marketingskills/copy-editing) |
| `compound` | Document solved problems as structured, searchable knowledge | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |

## Workflows

Workflows live in `.agent/workflows/` and define multi-step procedures:

| Command | Purpose | Source |
|---|---|---|
| `/plan` | Scope, architect, and plan engineering tasks using the Mega Plan Review | Adapted from [gstack](https://github.com/garrytan/gstack) |
| `/review-gstack` | Scope, verify, and auto-fix code changes using the rigorous `review-gstack` pipeline | Adapted from [gstack](https://github.com/garrytan/gstack) |
| `/review` | Multi-angle code review (standards, security, performance, architecture, accessibility, tests) | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `/brainstorm` | Structured brainstorming divergent/convergent workflow | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `/project` | Interactive onboarding — collects project context | Original |
| `/wrap` | Atomic commits and push to origin | Original |
| `/stats` | Summarize the day's work and put it in context | Original |
| `/design-system` | Propose and establish the project's visual identity | Adapted from [garrytan/gstack](https://github.com/garrytan/gstack) |

## Key Principles

- **Framework-first** — check if Laravel/Nuxt provides it before building custom solutions
- **Lookup order** — framework core → first-party packages → existing third-party → custom (last resort)
- **Refactoring triggers** — controller >15 lines, component >300 lines, class string >80 chars
- **Why, not How** — comments explain business intent, not implementation
- **No magic numbers** — config files or constants only

## Usage

Copy `.agent/` into your project. Fill in `10_project.md` with your project-specific context. Adapt `23_design_system.md` to your actual design tokens.

The rules use YAML frontmatter with a `trigger` field:
- `always_on` — always loaded into the agent's context
- `model_decision` — loaded when the agent determines the rule is relevant based on the `description` field

## Sources

- **gstack** by [Garry Tan](https://github.com/garrytan/gstack) — inspired the 5-phase Mega Plan Review and adversarial checks in the `review-plan` & `review-gstack` skills, and the `/plan` & `/review-gstack` workflows.
- **Compound Engineering** methodology by [Kieran Klaassen](https://github.com/kieranklaassen) — inspired the workflows (`/review`, `/brainstorm`, `/wrap`) and skills (`compound`, `architecture-review`, `performance-review`, `security-review`)
- **Skills.sh** by [Vercel Labs](https://skills.sh) — 4 skills adapted from their open-source agent skills registry (`systematic-debugging`, `test-driven-development`, `ui-accessibility-review`, `code-review-excellence`)
- **antfu/skills** by [Anthony Fu](https://github.com/antfu/skills) — 5 framework reference skills auto-generated from source (`vue-best-practices`, `nuxt`, `vitest`, `pinia`, `vueuse-functions`)
- **jezweb/claude-skills** by [jezweb](https://github.com/jezweb/claude-skills) — Tailwind v4 + shadcn/ui skill (`tailwind-v4-shadcn`)
- **Laravel Boost** by [Laravel](https://github.com/laravel/boost) — official Laravel MCP server `.ai/` guidelines, synthesized into the `laravel` skill
- **anthropics/skills** by [Anthropic](https://github.com/anthropics/skills) — official Claude skills repository, adapted the `skill-creator` for agentic use

## Releases

- **v1.3.0** (March 2026) — Framework bump. Upgraded baseline standards to Laravel 13 and Pest 4.
- **v1.2.0** (March 2026) — Skill professionalization. Migrated 9 skills from workflows to standalone skills with `references/` architecture. Applied path-to-10 quality audit (pushy descriptions, structured output templates, extracted reference files, generalized paths). Removed `heal-skill` and `research-solutions`. Added JSON-LD schema templates to `seo-review`. Total SKILL.md lines reduced 32% (~1,900 → 1,289).
- **v1.1.0** (March 2026) — Dense compaction update. Streamlined meta rules, hyper-compressed skills (`tailwind-v4-shadcn`, `vueuse`, `vue-best-practices` ~60-80% smaller), strict verification gates added to `/plan` and `/review`, and introduced `/brainstorm` workflow alongside `seo-review` and `changelog`.
- **v1.0.0** (February 2026) — Initial release. Baseline Laravel 12 + Nuxt 4 + Tailwind v4 + shadcn/ui agent standards, review checklists, and standard operating procedures.

## License

MIT
