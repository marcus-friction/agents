#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

project="$TEST_ROOT/legacy-project"
mkdir -p "$project/.agents/templates/profiles"
printf '%s\n' 'retired stack policy' \
  > "$project/.agents/templates/profiles/legacy-stack.md"
printf '%s\n' 'old web design policy' \
  > "$project/.agents/templates/profiles/web-design.md"

(
  cd "$project"
  bash "$REPO_ROOT/install.sh" \
    --skip-deps \
    --from-local "$REPO_ROOT" >/dev/null
)

cmp -s \
  "$REPO_ROOT/project-templates/base/ARCHITECTURE.md" \
  "$project/.agents/templates/ARCHITECTURE.md"

if [ -e "$project/.agents/templates/profiles" ] \
  || [ -L "$project/.agents/templates/profiles" ]; then
  echo "Installer retained retired conditional profiles"
  exit 1
fi

for active_document in AGENTS.md README.md CONTRIBUTING.md DESIGN.md ARCHITECTURE.md; do
  if [ -e "$project/$active_document" ] || [ -L "$project/$active_document" ]; then
    echo "Installing the architecture candidate activated $active_document"
    exit 1
  fi
done

echo "Base architecture staging tests passed"
