# Tailwind v4 + shadcn/ui Skill

Guidance for reconciling Tailwind CSS v4 and shadcn/ui with an adopted Vite +
React project. [`SKILL.md`](SKILL.md) is the normative workflow; this README is
only a navigation aid.

## Use it for

- adding or reviewing Tailwind CSS v4 in a Vite + React project;
- integrating shadcn/ui or an existing shadcn/ui configuration;
- setting up semantic theme tokens and light/dark behavior;
- diagnosing v3-to-v4 configuration, plugin, `@apply`, or CSS-variable issues;
- planning a bounded Tailwind v3 migration.

This is a Vite-specific setup skill; do not use it for Next.js setup. Route a
Next.js project to the project's adopted Next.js guidance instead. Do not apply
this skill when Tailwind, React, or the proposed UI stack is merely optional or
unresolved.

## Operating contract

1. Inspect the package manifest, lockfile, package manager evidence, existing
   CSS and configuration, framework structure, and relevant dirty state.
2. Resolve compatible exact dependency and generator versions. State the
   purpose of every proposed package.
3. Preview material generator, migration, removal, and overwrite effects.
   Supplied implementation scope needs no redundant approval; unresolved
   dependencies or destructive effects retain their normal boundary.
4. Reconcile the reference templates with project-owned files. Never copy them
   over an existing configuration without comparing meaning and usage.
5. Add `tw-animate-css` only when selected output actually requires it.
6. Run the repository's focused build and behavior checks after the change.

## Package planning

Relevant packages may include `tailwindcss`, `@tailwindcss/vite`, `clsx`, and
`tailwind-merge`. React, Vite, and TypeScript normally already belong to the
host project. Treat names here as discovery hints, not version or installation
approval.

## Repository contents

- [`SKILL.md`](SKILL.md) — normative inspection, planning, implementation, and
  verification workflow.
- [`commands/setup.md`](commands/setup.md) — command-oriented setup guidance.
- [`rules/tailwind-v4-shadcn.md`](rules/tailwind-v4-shadcn.md) — compact rules.
- [`references/common-gotchas.md`](references/common-gotchas.md) — common
  integration failures.
- [`references/dark-mode.md`](references/dark-mode.md) — theme behavior.
- [`references/migration-guide.md`](references/migration-guide.md) — v3-to-v4
  migration considerations.
- `templates/` — reference files to compare and reconcile, never blind-copy.

For upstream framework behavior and current compatibility, verify the official
Tailwind CSS and shadcn/ui documentation at implementation time.
