# v1.7.1 — CLI-first wrap setup

Release date: 2026-09-13. Use the full commit SHA from the
[release record](https://github.com/marcus-friction/agents/releases/tag/v1.7.1)
with installer `--ref` for stable installation. `master` remains mutable.

- `wrap` uses `git` for repository work and `gh` for GitHub operations.
- It initializes genuinely missing local repositories without replacing parent
  repositories, worktrees or damaged metadata.
- Missing tools are installed with approval. GitHub login asks about the user's
  account and consent, with signup guidance when needed.
- Login flags are checked against installed CLI help; older versions need not
  support `--skip-ssh-key`. Unapproved key and credential changes stay blocked.
- Commit, push and publication permissions remain separate from setup.

The Laravel/Nuxt stack and installer behavior are unchanged. Reload your coding
tool after updating. Validation includes skill contracts, offline checks and
help-only command parsing on gh 2.45.0. Real installation/login and registered
live-agent evaluations were not performed.
