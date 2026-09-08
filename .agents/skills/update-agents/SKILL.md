---
name: update-agents
description: Safely refresh upstream-managed agent skills, documentation candidates, and discovery adapters while preserving project-owned files. Use when asked to "update agents", "sync agents", or "pull the latest agent rules".
---

# Update Agent Ecosystem

Refresh the central `marcus-friction/agents` distribution without treating a project's active
documentation as an upstream-owned file set.

## Ownership Contract

| Path | Owner | Update behavior |
|---|---|---|
| `.agents/skills/<upstream-name>/` | Upstream | Updated from the distribution |
| `.agents/templates/` | Upstream | Updated candidates; never copied into root docs |
| `.agents/project/` | Project | Never changed by install or update |
| Paths below `.agents/skills/` absent upstream | Unknown/local | Retained and reported; never auto-deleted |
| Root and nested project documentation | Project | Never created, appended, replaced, or deleted |

A local edit inside an upstream-named path is not automatically distinguishable
from an outdated upstream version. Files that still exist upstream are refreshed.
Paths absent upstream are retained and reported for an explicit keep-or-cleanup
decision. Keep project-specific extensions in uniquely named skills or
`.agents/project/` so ownership stays obvious.

## Safety Rules

- Run from the repository root.
- Never infer file ownership from a title, banner, or matching content.
- Do not migrate or delete `.agents/rules/` or legacy `.agent/` content during an
  update. Preserve it for semantic reconciliation by `onboard-project`.
- Do not append incoming text to `README.md`, `DESIGN.md`, or any other active
  project document.
- Stop before updating when `.agents/` has tracked or untracked changes. Ask the
  user to commit, stash, or deliberately relocate them first.
- For the stable channel, require the release's full 40-character commit SHA.
  Treat tags as aliases and branches as edge-only; never silently substitute one.
- Do not commit or push the result unless the user separately asks.

## Update Procedure

Run this as one Bash block so the temporary checkout and cleanup trap share one
shell process:

```bash
set -euo pipefail

AGENTS_ECOSYSTEM_SHA="${AGENTS_ECOSYSTEM_SHA:?Set AGENTS_ECOSYSTEM_SHA to the approved release commit.}"
if ! [[ "$AGENTS_ECOSYSTEM_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "AGENTS_ECOSYSTEM_SHA must be a full 40-character lowercase commit SHA." >&2
  exit 1
fi

release_git() (
  for git_variable in "${!GIT_@}"; do
    unset "$git_variable"
  done
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_ASKPASS=/usr/bin/false
  export GIT_TERMINAL_PROMPT=0
  export GIT_NO_REPLACE_OBJECTS=1
  export GH_PROMPT_DISABLED=1
  export SSH_ASKPASS=/usr/bin/false
  export SSH_ASKPASS_REQUIRE=never
  git --no-replace-objects \
    -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false \
    -c credential.helper= \
    "$@"
)

project_git() (
  for git_variable in "${!GIT_@}"; do
    unset "$git_variable"
  done
  GIT_NO_REPLACE_OBJECTS=1 git --no-replace-objects \
    -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false \
    "$@"
)

PROJECT_ROOT="$(project_git rev-parse --show-toplevel)" || {
  echo "Must be in a Git repository."
  exit 1
}
cd "$PROJECT_ROOT"

if [ -n "$(project_git -C "$PROJECT_ROOT" status \
  --porcelain --untracked-files=all -- .agents)" ]; then
  echo "ERROR: .agents contains tracked or untracked changes."
  echo "Commit, stash, or relocate them before updating upstream-managed assets."
  exit 1
fi
hidden_index_state="$(project_git -C "$PROJECT_ROOT" \
  ls-files -v -- .agents | sed -n '/^[a-zS]/p')"
if [ -n "$hidden_index_state" ]; then
  echo "ERROR: .agents contains assume-unchanged or skip-worktree index state."
  echo "Clear the hidden index flags before updating upstream-managed assets."
  exit 1
fi

UPDATE_TMP="$(mktemp -d)"
trap 'rm -rf "$UPDATE_TMP"' EXIT

release_git init -q "$UPDATE_TMP"
release_git -C "$UPDATE_TMP" remote add origin \
  https://github.com/marcus-friction/agents.git
release_git -C "$UPDATE_TMP" fetch --depth 1 --no-tags origin "$AGENTS_ECOSYSTEM_SHA"
release_git -C "$UPDATE_TMP" checkout --quiet --detach FETCH_HEAD

ACTUAL_SHA="$(release_git -C "$UPDATE_TMP" rev-parse --verify 'HEAD^{commit}')"
if [ "$ACTUAL_SHA" != "$AGENTS_ECOSYSTEM_SHA" ]; then
  echo "Fetched checkout does not match the approved release commit." >&2
  exit 1
fi
if release_git -C "$UPDATE_TMP" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
  echo "Fetched release checkout is not detached." >&2
  exit 1
fi
if [ -L "$UPDATE_TMP/install.sh" ] || [ ! -f "$UPDATE_TMP/install.sh" ]; then
  echo "Fetched installer must be a physical file." >&2
  exit 1
fi

bash "$UPDATE_TMP/install.sh" \
  --skip-deps \
  --from-local "$UPDATE_TMP" \
  --ref "$AGENTS_ECOSYSTEM_SHA"

echo
echo "--- LOCAL-ONLY SKILL PATH ANALYSIS ---"
echo "These local paths are absent upstream and were retained:"
LC_ALL=C comm -23 \
  <(cd .agents/skills && find . -mindepth 1 -print | LC_ALL=C sort) \
  <(cd "$UPDATE_TMP/.agents/skills" && find . -mindepth 1 -print | LC_ALL=C sort)
echo "--------------------------------------"

if [ -d .agents/rules ] || [ -d .agent ]; then
  echo
  echo "Legacy agent context is still present and was deliberately retained."
  echo "Run onboard-project to account for its meaning before any cleanup."
fi

echo
echo "Upstream assets refreshed. Project documents were not changed."
echo "Review staged template changes, then run onboard-project to reconcile them."
project_git -C "$PROJECT_ROOT" status --short
```

## Report

Tell the user:

1. Which upstream-managed skills and templates changed.
2. That active project documents and legacy context were left untouched.
3. Which local-only skill paths were reported, asking whether they are intentional
   custom extensions or obsolete upstream remnants.
4. Whether `.agents/templates/` now differs from the last committed baseline and
   therefore needs an `onboard-project` reconciliation.

Do not claim the project is fully updated while template conflicts or legacy
context remain unresolved.
