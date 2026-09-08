#!/usr/bin/env bash

set -euo pipefail
umask 022

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$REPO_ROOT/tests/validate-specialty-preservation.py"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

python3 "$VALIDATOR" "$REPO_ROOT"

candidate="$TEST_ROOT/candidate"
mkdir -p "$candidate/.agents"
cp -a "$REPO_ROOT/.agents/skills" "$candidate/.agents/skills"
cp -a "$REPO_ROOT/project-templates" "$candidate/project-templates"
cp "$REPO_ROOT/AGENTS.md" "$candidate/AGENTS.md"
python3 "$VALIDATOR" "$candidate" >/dev/null

# On POSIX filemode-preserving checkouts, repository executable intent follows
# the owner execute bit rather than complete permission bits. A restrictive
# umask must not reject an otherwise identical specialty payload.
find "$candidate/.agents/skills" -type d -exec chmod 700 {} +
find "$candidate/.agents/skills" -type f -exec chmod 600 {} +
if ! python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator rejected a restrictive but Git-equivalent checkout mode" >&2
  exit 1
fi

chmod g+x "$candidate/.agents/skills/laravel/SKILL.md"
if ! python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator treated group execute permission as Git executable intent" >&2
  exit 1
fi
chmod g-x "$candidate/.agents/skills/laravel/SKILL.md"

chmod o+x "$candidate/.agents/skills/laravel/SKILL.md"
if ! python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator treated other execute permission as Git executable intent" >&2
  exit 1
fi
chmod o-x "$candidate/.agents/skills/laravel/SKILL.md"

chmod u+x "$candidate/.agents/skills/laravel/SKILL.md"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted changed executable intent" >&2
  exit 1
fi
chmod u-x "$candidate/.agents/skills/laravel/SKILL.md"

mv "$candidate/.agents/skills/laravel/SKILL.md" \
  "$TEST_ROOT/laravel-SKILL.md"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted a missing Laravel skill" >&2
  exit 1
fi
mv "$TEST_ROOT/laravel-SKILL.md" \
  "$candidate/.agents/skills/laravel/SKILL.md"

mkdir "$candidate/.agents/skills/next-best-practices"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted a source-only framework skill" >&2
  exit 1
fi
mv "$candidate/.agents/skills/next-best-practices" \
  "$TEST_ROOT/next-best-practices"

cp "$candidate/AGENTS.md" "$TEST_ROOT/AGENTS.md"
awk '{ sub("Pest for Laravel", "Jest for Laravel"); print }' \
  "$candidate/AGENTS.md" > "$TEST_ROOT/mutated-AGENTS.md"
mv "$TEST_ROOT/mutated-AGENTS.md" "$candidate/AGENTS.md"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted a changed backend test runner" >&2
  exit 1
fi
mv "$TEST_ROOT/AGENTS.md" "$candidate/AGENTS.md"

cp "$candidate/.agents/skills/ma-review/SKILL.md" "$TEST_ROOT/ma-review-SKILL.md"
awk 'index($0, ".agents/skills/ma-security-review/SKILL.md") == 0' \
  "$candidate/.agents/skills/ma-review/SKILL.md" \
  > "$TEST_ROOT/mutated-ma-review-SKILL.md"
mv "$TEST_ROOT/mutated-ma-review-SKILL.md" \
  "$candidate/.agents/skills/ma-review/SKILL.md"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted an incomplete review persona router" >&2
  exit 1
fi
mv "$TEST_ROOT/ma-review-SKILL.md" \
  "$candidate/.agents/skills/ma-review/SKILL.md"

nuxt_reference="$candidate/.agents/skills/nuxt/references/core-config.md"
cp "$nuxt_reference" "$TEST_ROOT/nuxt-core-config.md"
printf '\ncontent mutation with unchanged file count\n' >> "$nuxt_reference"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted changed Nuxt reference bytes" >&2
  exit 1
fi
mv "$TEST_ROOT/nuxt-core-config.md" "$nuxt_reference"

mv "$nuxt_reference" \
  "$candidate/.agents/skills/nuxt/references/renamed-core-config.md"
if python3 "$VALIDATOR" "$candidate" >/dev/null 2>&1; then
  echo "Specialty validator accepted a renamed Nuxt reference" >&2
  exit 1
fi

echo "Stack specialty preservation tests passed"
