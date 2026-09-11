#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

generic_files=(
  "$REPO_ROOT/install.sh"
  "$REPO_ROOT/install-global.sh"
  "$REPO_ROOT/scripts/install-user-snapshot.sh"
  "$REPO_ROOT/scripts/link-user-skills.sh"
  "$REPO_ROOT/.agents/skills/start-project/SKILL.md"
  "$REPO_ROOT/.agents/skills/update-agents/SKILL.md"
)

for file in "${generic_files[@]}"; do
  if grep -Eq '\.cursor/skills|\.claude/skills' "$file"; then
    echo "Provider discovery path leaked into generic file: $file"
    exit 1
  fi
done

strict_neutral_files=(
  "$REPO_ROOT/install.sh"
  "$REPO_ROOT/.agents/skills/start-project/SKILL.md"
  "$REPO_ROOT/.agents/skills/update-agents/SKILL.md"
)

for file in "${strict_neutral_files[@]}"; do
  if grep -q 'CLAUDE.md' "$file"; then
    echo "Provider router handling leaked into canonical workflow: $file"
    exit 1
  fi
done

if grep -Eqi 'cursor/import|Agents Ecosystem Cursor skills|Cursor discover' \
  "$REPO_ROOT/scripts/install-into-repos.sh"; then
  echo "Bulk product installer uses provider-specific workflow branding"
  exit 1
fi

if ! grep -q 'status --porcelain --untracked-files=all' \
  "$REPO_ROOT/scripts/install-into-repos.sh"; then
  echo "Bulk product installer does not require a clean disposable clone"
  exit 1
fi

if grep -Eq '@(start-project|onboard-project)' "$REPO_ROOT/install.sh"; then
  echo "Generic installer prints tool-specific skill invocation syntax"
  exit 1
fi

if grep -q 'chmod +x "$REGISTRAR"' \
  "$REPO_ROOT/install-global.sh" \
  "$REPO_ROOT/scripts/install-cursor-cloud.sh"; then
  echo "An installer mutates the registrar mode at runtime"
  exit 1
fi

portable_installer_files=(
  "$REPO_ROOT/scripts/sync-managed-tree.sh"
  "$REPO_ROOT/scripts/install-user-snapshot.sh"
)

for file in "${portable_installer_files[@]}"; do
  if grep -Eq 'declare[[:space:]]+-A|sort[[:space:]]+-z|exec[[:space:]]+\{' "$file"; then
    echo "Installer requires GNU tools or Bash 4 despite macOS support: $file"
    exit 1
  fi
done

echo "Tool boundary tests passed"
