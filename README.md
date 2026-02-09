# Agent Rules

Opinionated rule files for AI coding agents working on a **Laravel 12 + Nuxt 4** full-stack monorepo. These rules ensure agents follow ecosystem conventions, project standards, and established workflows — instead of reinventing the wheel.

## Stack

| Layer | Technology |
|---|---|
| Backend | Laravel 12, PHP 8.4, PostgreSQL 17, Redis |
| Admin | FilamentPHP 4 |
| Frontend | Nuxt 4 (SSR), Tailwind CSS 4, Pinia 3, TypeScript |
| Search | Meilisearch via Laravel Scout |
| Auth | Laravel Sanctum |
| Infrastructure | Laravel Sail (dev), Laravel Forge (deploy), PM2 (SSR), Cloudflare (CDN) |
| Quality | Larastan (L9), Laravel Pint, Pest 3, ESLint, Vitest |
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

## Key Principles

- **Framework-first** — check if Laravel/Nuxt provides it before building custom solutions
- **Lookup order** — framework core → first-party packages → existing third-party → custom (last resort)
- **Refactoring triggers** — controller >15 lines, component >300 lines, class string >80 chars
- **Why, not How** — comments explain business intent, not implementation
- **No magic numbers** — config files or constants only

## Usage

Copy `.agent/rules/` into your project. Fill in `10_project.md` with your project-specific context. Adapt `23_design_system.md` to your actual design tokens.

The rules use YAML frontmatter with a `trigger` field:
- `always_on` — always loaded into the agent's context
- `model_decision` — loaded when the agent determines the rule is relevant based on the `description` field

## License

MIT
