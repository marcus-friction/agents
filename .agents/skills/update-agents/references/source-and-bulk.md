# Source Acquisition and Bulk Refresh

Read this reference only when a project update has no suitable source checkout
or when the request covers multiple repositories.

## Temporary public source checkout

The public distribution requires no GitHub authentication. Keep acquisition and
cleanup in one shell process, disable interactive credential discovery, and do
not print credential values inherited from the environment.

For a stable release, resolve the requested release to its full commit SHA and
fetch that exact object:

```bash
(
  set -euo pipefail
  AGENTS_ECOSYSTEM_UPDATE_TARGET="${AGENTS_ECOSYSTEM_UPDATE_TARGET:?Set the exact target project root.}"
  AGENTS_ECOSYSTEM_UPDATE_SHA="${AGENTS_ECOSYSTEM_UPDATE_SHA:?Set the release's full commit SHA.}"
  [[ "$AGENTS_ECOSYSTEM_UPDATE_SHA" =~ ^[0-9a-f]{40}$ ]]
  AGENTS_ECOSYSTEM_UPDATE_TMP="$(mktemp -d)"
  trap 'rm -rf "$AGENTS_ECOSYSTEM_UPDATE_TMP"' EXIT

  for git_variable in "${!GIT_@}"; do unset "$git_variable"; done
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
  export GIT_ASKPASS=/usr/bin/false GIT_TERMINAL_PROMPT=0
  export GIT_NO_REPLACE_OBJECTS=1 SSH_ASKPASS=/usr/bin/false
  export SSH_ASKPASS_REQUIRE=never

  git --no-replace-objects -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false -c credential.helper= init -q "$AGENTS_ECOSYSTEM_UPDATE_TMP"
  git --no-replace-objects -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false -c credential.helper= \
    -C "$AGENTS_ECOSYSTEM_UPDATE_TMP" remote add origin \
    https://github.com/marcus-friction/agents.git
  git --no-replace-objects -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false -c credential.helper= \
    -C "$AGENTS_ECOSYSTEM_UPDATE_TMP" fetch --depth 1 --no-tags origin "$AGENTS_ECOSYSTEM_UPDATE_SHA"
  git --no-replace-objects -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false -c credential.helper= \
    -C "$AGENTS_ECOSYSTEM_UPDATE_TMP" checkout --quiet --detach FETCH_HEAD

  cd "$AGENTS_ECOSYSTEM_UPDATE_TARGET"
  bash "$AGENTS_ECOSYSTEM_UPDATE_TMP/install.sh" \
    --from-local "$AGENTS_ECOSYSTEM_UPDATE_TMP" \
    --ref "$AGENTS_ECOSYSTEM_UPDATE_SHA"
)
```

For an explicitly requested edge update, clone the moving branch into a fresh
temporary checkout, report the resolved commit, verify the checkout is clean,
and invoke its installer with `--from-local` and no `--ref`. State before
execution that another run may resolve to different bytes. Never silently pull
an existing checkout or relabel edge as stable.

## Bulk refresh

Bulk refresh accepts only a clean, detached source checkout at the exact stable
commit. Preparation creates review artifacts but makes no target commit or push:

```bash
bash scripts/install-into-repos.sh \
  --ref <full-commit-sha> \
  --branch <new-branch-name> \
  --plan-dir /absolute/private/plan-directory \
  owner/repo-one owner/repo-two
```

Review each manifest, diffstat, and `changes.patch`; patches can contain removed
private-project material. Record the printed plan SHA-256. Applying is a
separate publication effect and requires exact approval of the repositories,
branch, plan digest, author identity, pushes, and pull-request creation:

```bash
bash scripts/install-into-repos.sh \
  --ref <full-commit-sha> \
  --branch <new-branch-name> \
  --plan-dir /absolute/private/plan-directory \
  --apply \
  --expected-plan-sha256 <reviewed-plan-sha256> \
  --author-name <name> \
  --author-email <email> \
  owner/repo-one owner/repo-two
```

Revalidate the exact plan and targets immediately before apply. If a target base
or remote branch changed, prepare a new plan; do not rebase, force over an
existing branch, broaden access, or retry publication automatically.
