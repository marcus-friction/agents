# [Project Name]

`[One sentence explaining what the project does and who it serves.]`

> [!WARNING]
> This is an inactive upstream candidate. Preserve an existing README's
> structure, badges, links, verified commands, license, and local decisions
> unless their exact replacement is approved.

## Vision and Scope

- **Problem:** `[What concrete problem exists today?]`
- **Outcome:** `[What should improve for users?]`
- **Primary users:** `[Specific roles and contexts.]`
- **Goals:** `[Measurable outcomes or milestones.]`
- **Non-goals:** `[Work explicitly outside the accepted scope.]`
- **Constraints:** `[Compatibility, budget, timeline, regulatory, or operational limits.]`

## Adopted Components

Classify every relevant capability as **Adopted**, **Optional**, **Not
applicable**, or **Unresolved**. Only adopted components activate their rules.

| Capability | Preferred ecosystem option | Project status and evidence |
|---|---|---|
| Backend | Laravel 13 on PHP 8.4 | `[status; composer.json or decision]` |
| Web | Nuxt 4, Vue 3, TypeScript, Tailwind CSS 4 | `[status; package.json or decision]` |
| Admin | FilamentPHP 4 | `[status and evidence]` |
| Data | PostgreSQL 17, Redis where justified | `[status and evidence]` |
| Identity and search | Sanctum; Scout with Meilisearch | `[status and evidence]` |
| Quality | Pest 4, Larastan, Pint, ESLint, Vitest, Playwright | `[status and commands]` |
| Delivery | Sail locally; Forge, PM2, Cloudflare when adopted | `[status and evidence]` |

Established alternatives remain valid until an approved migration replaces
them. Record detailed boundaries and component decisions in `ARCHITECTURE.md`.

## Run and Verify

### Requirements

- **Runtimes and services:** `[Verified versions and required components.]`
- **Configuration:** `[Required variable names; never include secret values.]`

```text
[verified installation and startup commands]
```

```text
[verified formatter, linter, type-check, build, and test commands]
```

## Working Agreement

Use `CONTRIBUTING.md` for change rigor, branches, reviews, and quality gates.
Use `DESIGN.md` for adopted interface work. Keep credentials out of source,
logs, examples, and client bundles.

## Known Limitations

- `[Limitation, current impact, evidence, and next decision.]`

## License

`[Preserve the existing license statement and link.]`
