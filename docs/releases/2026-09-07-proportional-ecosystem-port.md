# v1.7.0 — Agent Ecosystem and Cloud Deployment

Release date: 2026-09-11. The
[GitHub release record](https://github.com/marcus-friction/agents/releases/tag/v1.7.0)
binds this version to its full commit SHA. `master` remains a mutable edge channel.

## Changes

- Aligned workflow skills with TomFit Agents 0.2.0, including its review workflow,
  proportional R0–R2 rigor, and removal of retired skills.
- Retained and tuned Laravel/Nuxt stack guidance. Direct installs use declared
  skill names; the Claude plugin uses `ma:`, not `ma-`.
- Added `deploy` for Laravel-only and Laravel + Nuxt applications on Laravel
  Cloud, covering readiness, separate app releases, verification and recovery.
  Existing hosting choices and external-effect approval remain required.
- Hardened global snapshots, legacy migration, edge fast-forward checks,
  managed ownership, discovery registration and private filesystem boundaries.
- Isolated evaluation fixtures and rejected unsafe paths before reading input.
- Simplified onboarding documentation and kept project templates inactive until
  adopted. Installers preserve project-owned documents and local extensions.

## Updating

Use the full 40-character SHA from the release record with `--ref`; see the
[installation reference](../ecosystem-reference.md). Reload your coding tool
after updating. Local edits or ambiguous ownership can block an update; inspect
the reported paths instead of deleting local state to force installation.
Verified legacy global checkouts retain a recovery copy. Known unchanged legacy
project files can be adopted, while unknown or modified local files stay local.

The stack remains Laravel 13/PHP 8.4, Nuxt 4/Vue 3 and PostgreSQL 17. Optional
services are adopted only when needed. Cloud guidance does not migrate a project
from Forge, PM2, Cloudflare or another existing provider automatically.

## Verification

The offline deterministic suite and independent reviews passed during the
integration; release PR checks verify the final candidate. Deploy guidance also
passed simulated readiness, release, authentication and recovery scenarios.
Live Cloud integration, registered live-agent evaluations, ShellCheck and macOS
runtime checks were not performed. Consuming applications still need their own
Laravel, Nuxt and browser verification.
