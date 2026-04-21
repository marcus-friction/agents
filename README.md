# Agent Rules

Opinionated rule files for AI coding agents working on a **Laravel 13 + Nuxt 4** full-stack monorepo. These rules ensure agents follow ecosystem conventions, project standards, and established workflows — instead of reinventing the wheel.

## Installation

You can instantly install the complete Agent Ecosystem into any repository by running this single command in your terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/marcus-friction/agents/master/install.sh)
```

Alternatively, you can manually copy `.agents/`, `AGENTS.md`, and `CLAUDE.md` into your project.

### System Dependencies

The ecosystem includes a multi-OS dependency bootstrapper. If executed during the installation, it safely ensures your host machine matches the rigid project baseline (Git, Docker Engine, NVM, Node.js 22 LTS, PHP 8.4, and Composer). 

It dynamically utilizes standard package managers (`apt` / `brew`) and gracefully intercepts Windows users to guide them into **WSL2** for maximum framework compatibility.

### Starting a New Project

If you are beginning a brand new project, use the **Start Project** skill. 
Run `/start-project` or ask your agent: "Run the start project skill". 
This interactive workflow interviews you about the product vision and constraints, seamlessly generating a suite of foundational documents before any code is written:
- **`10_project.md`**: Captures your core goals, specific users, rigid constraints, and competitive landscape.
- **`11_design.md`**: (Optional) Triggers a design consultation to establish UI architecture, typography, spacing, and color logic.
- **`implementation_plan.md` & `task.md`**: Architecturally scopes the End-to-End MVP and provides a comprehensive execution checklist.

### Onboarding an Existing Project

If you are dropping these rules into an established codebase, use the **Onboard Project** skill.
Run `/onboard-project` or ask your agent: "Run the onboard project skill".
The agent will systematically analyze your tech stack, map out existing directories, identify missing standards, and custom-tailor the rules and `AGENTS.md` router to fit your specific ecosystem, eliminating agent blindness.

## Core Workflow

The ecosystem is designed around a strict, predictable development loop. For any non-trivial task, enforce this cycle:

1. **`/plan`**: Never code first. Use the `/plan` or `review-plan` skills to force the agent to scope the problem, investigate the codebase, and write a detailed `implementation_plan.md`.
2. **Implement**: Supervise the agent as it executes the approved plan, tracking progress via `task.md`.
3. **`/review`**: Before concluding, run a review skill (like `/review` or `review-gstack`) to subject the code to an architecture, security, and scope-drift audit.
4. **`/wrap`**: Finally, invoke `/wrap`. The agent will structure atomic commits following conventional standards and prepare the branch for pushing.

## Featured Skills

The `.agents/skills/` directory holds deep, on-demand capabilities. Some highlights:

- **Path to 10 (`path-to-10`)**: Enforces a ruthless, uncompromising 10/10 quality standard on agent outputs. Requires proof of constraints, specific citations, and robust environmental execution.
- **Review GStack (`review-gstack`)**: A "Mega Review" pre-landing pipeline. Uses a 5-phase checking system to catch hidden scope drift, enforce fix-first policies, and mandate ASCII test flow graphs prior to any merge.
- **Design Consultation (`design-consultation`)**: Acts as a senior product designer. Researches the landscape, proposes cohesive design systems (typography, spacing, color, motion), and generates `11_design.md` as your project's visual source of truth.
- **Copywriting (`copywriting`)**: Instills professional writing principles. Use this when generating landing pages, UI microcopy, CTAs, product descriptions, or changelogs to ensure clear, user-centric messaging.
- **Copy Editing (`copy-editing`)**: Employs "The Seven Sweeps" framework to review and enhance existing text—focusing on clarity, voice, benefits, proof, specificity, emotion, and risk reversal.

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

Rules live in `.agents/rules/` and are numbered by category:

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

Skills live in `.agents/skills/` and provide deep, on-demand guidance when a task matches:

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
| `end2end` | Full end-to-end (E2E) autonomous testing skill utilizing the browser | Original |
| `laravel` | Laravel operational patterns — Artisan generators, Eloquent, testing, Laravel 13 structure | Synthesized from [laravel/boost](https://github.com/laravel/boost) |
| `build-start-scripts` | Standards for reliable local dev startup scripts — Docker / Sail cleanup, port discipline, health checks, graceful shutdown | Original |
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
| `start-project` | Interactive onboarding and project planning | Original |
| `plan` | Scope, architect, and plan engineering tasks using the Mega Plan Review | Adapted from [gstack](https://github.com/garrytan/gstack) |
| `review` | Multi-angle code review (standards, security, performance, architecture, accessibility, tests) | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `brainstorm` | Structured brainstorming divergent/convergent workflow | Adapted from [Compound Engineering](https://github.com/kieranklaassen) |
| `wrap` | Atomic commits and push to origin | Original |
| `stats` | Summarize the day's work and put it in context | Original |
| `path-to-10` | Enforces a ruthless 10/10 quality standard on agent outputs | Original |
| `update-agents` | Pulls the latest agent rules and skills non-destructively | Original |


## Key Principles

- **Framework-first** — check if Laravel/Nuxt provides it before building custom solutions
- **Lookup order** — framework core → first-party packages → existing third-party → custom (last resort)
- **Refactoring triggers** — controller >15 lines, component >300 lines, class string >80 chars
- **Why, not How** — comments explain business intent, not implementation
- **No magic numbers** — config files or constants only

## Sources

- **gstack** by [Garry Tan](https://github.com/garrytan/gstack) — inspired the 5-phase Mega Plan Review and adversarial checks in the `review-plan`, `review-gstack`, and `plan` skills.
- **Compound Engineering** methodology by [Kieran Klaassen](https://github.com/kieranklaassen) — inspired the skills (`review`, `brainstorm`, `wrap`, `compound`, `architecture-review`, `performance-review`, `security-review`)
- **Skills.sh** by [Vercel Labs](https://skills.sh) — 4 skills adapted from their open-source agent skills registry (`systematic-debugging`, `test-driven-development`, `ui-accessibility-review`, `code-review-excellence`)
- **antfu/skills** by [Anthony Fu](https://github.com/antfu/skills) — 5 framework reference skills auto-generated from source (`vue-best-practices`, `nuxt`, `vitest`, `pinia`, `vueuse-functions`)
- **jezweb/claude-skills** by [jezweb](https://github.com/jezweb/claude-skills) — Tailwind v4 + shadcn/ui skill (`tailwind-v4-shadcn`)
- **Laravel Boost** by [Laravel](https://github.com/laravel/boost) — official Laravel MCP server `.ai/` guidelines, synthesized into the `laravel` skill
- **anthropics/skills** by [Anthropic](https://github.com/anthropics/skills) — official Claude skills repository, adapted the `skill-creator` for agentic use

## Releases

- **v1.5.3** (April 2026) — Added `end2end` skill for autonomous E2E browser testing with progressive test plans and fix-loop safety boundaries.
- **v1.5.2** (April 2026) — Ecosystem Hardening. Introduced native Claude Code agent syncing (`.claude/skills` symlinking) with comprehensive Windows PowerShell fail-safes. Shipped the `install-dependencies.sh` bootstrapper to securely align any host machine with the central tech stack baseline (Docker, Target Node/PHP versions) natively during the install hook.
- **v1.5.1** (April 2026) — Documentation Restructure. Expanded `README.md` to prominently surface installation, zero-to-one onboarding (`start-project`), and the core iterative development loop (`/plan` → execute → `/review` → `/wrap`). Curated a list of featured high-leverage skills (`path-to-10`, `review-gstack`, `copy-editing`).
- **v1.5.0** (April 2026) — Upstream Ecosystem Sync. Integrated upstream execution tracking (`preamble-tier`), Compound Engineering severity routing, and the Product Pressure Test. Synchronized high-fidelity framework core reference libraries (Vue, Nuxt, Laravel, Pinia, Vite).
- **v1.4.0** (April 2026) — Ecosystem Restructure & Rules Hardening. Migrated to a standardized `.agents/` directory structure. Conducted a comprehensive `path-to-10` quality audit across all rule files, resolving architecture offsets, eliminating tool lock-in, and deduplicating cross-references.
- **v1.3.2** (April 2026) — Added `contribute-back` skill. Allows agents to automatically scan local customizations, propose upstream enhancements, and execute GitHub Pull Requests back to the central repository.
- **v1.3.1** (April 2026) — Added `build-start-scripts` skill. Standards and patterns for reliable local dev startup scripts: orphaned container cleanup, port discipline, health checks, graceful shutdown, and idempotent dependency installation.

- **v1.3.0** (March 2026) — Framework bump. Upgraded baseline standards to Laravel 13 and Pest 4.
- **v1.2.0** (March 2026) — Skill professionalization. Migrated 9 skills from workflows to standalone skills with `references/` architecture. Applied path-to-10 quality audit (pushy descriptions, structured output templates, extracted reference files, generalized paths). Removed `heal-skill` and `research-solutions`. Added JSON-LD schema templates to `seo-review`. Total SKILL.md lines reduced 32% (~1,900 → 1,289).
- **v1.1.0** (March 2026) — Dense compaction update. Streamlined meta rules, hyper-compressed skills (`tailwind-v4-shadcn`, `vueuse`, `vue-best-practices` ~60-80% smaller), strict verification gates added to `/plan` and `/review`, and introduced `/brainstorm` workflow alongside `seo-review` and `changelog`.
- **v1.0.0** (February 2026) — Initial release. Baseline Laravel 12 + Nuxt 4 + Tailwind v4 + shadcn/ui agent standards, review checklists, and standard operating procedures.

## License

MIT
