#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

project="$TEST_ROOT/existing-project"
originals="$TEST_ROOT/originals"
mkdir -p "$project" "$originals"

cat > "$project/AGENTS.md" <<'EOF'
# Agent Instructions & Pragmatic Guidelines

This project deliberately retains the upstream heading but has local rules.
EOF
cat > "$project/README.md" <<'EOF'
# Existing product

The README contains business context that installation must not rewrite.
EOF
cat > "$project/CONTRIBUTING.md" <<'EOF'
# Existing contribution workflow

Releases require the project's bespoke approval process.
EOF
cat > "$project/DESIGN.md" <<'EOF'
# Existing design system

The project uses its own established visual language.
EOF
cat > "$project/ARCHITECTURE.md" <<'EOF'
# Existing architecture

The asynchronous boundary described here is intentional.
EOF
cat > "$project/CLAUDE.md" <<'EOF'
# Existing provider guidance

This file is also project-owned and must remain byte-for-byte intact.
EOF
cat > "$project/install-dependencies.sh" <<'EOF'
#!/usr/bin/env bash

echo "Project-specific dependency setup"
EOF

for document in AGENTS.md README.md CONTRIBUTING.md DESIGN.md ARCHITECTURE.md CLAUDE.md; do
  cp "$project/$document" "$originals/$document"
done
cp "$project/install-dependencies.sh" "$originals/install-dependencies.sh"

(
  cd "$project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

(
  cd "$project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" </dev/null >/dev/null
)

mkdir -p "$project/.agents/project"
mkdir -p "$project/.agents/rules"
cat > "$project/.agents/project/local-context.md" <<'EOF'
# Local agent context

This project-owned state must survive repeated installation.
EOF
cat > "$project/.agents/rules/legacy-context.md" <<'EOF'
# Legacy context

This meaning must remain until onboarding accounts for it.
EOF

(
  cd "$project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

for document in AGENTS.md README.md CONTRIBUTING.md DESIGN.md ARCHITECTURE.md CLAUDE.md; do
  if ! cmp -s "$originals/$document" "$project/$document"; then
    echo "Installer changed existing project-owned file: $document"
    exit 1
  fi
done
cmp -s "$originals/install-dependencies.sh" "$project/install-dependencies.sh"

grep -q "must survive repeated installation" \
  "$project/.agents/project/local-context.md"
grep -q "must remain until onboarding" \
  "$project/.agents/rules/legacy-context.md"

cmp -s "$REPO_ROOT/project-templates/base/AGENTS.md" "$project/.agents/templates/AGENTS.md"
cmp -s "$REPO_ROOT/project-templates/base/README.md" "$project/.agents/templates/README.md"
cmp -s "$REPO_ROOT/project-templates/base/CONTRIBUTING.md" "$project/.agents/templates/CONTRIBUTING.md"
cmp -s "$REPO_ROOT/project-templates/base/DESIGN.md" "$project/.agents/templates/DESIGN.md"
cmp -s "$REPO_ROOT/project-templates/base/ARCHITECTURE.md" "$project/.agents/templates/ARCHITECTURE.md"
cmp -s "$REPO_ROOT/scripts/skill-adapters/claude-router.md" \
  "$project/.agents/templates/adapters/claude/CLAUDE.md"
[ -z "$(find "$project/.agents/templates" -type f -perm -020 -print -quit)" ]
[ -z "$(find "$project/.agents/templates" -type f -perm -002 -print -quit)" ]

fresh_project="$TEST_ROOT/fresh-project"
mkdir -p "$fresh_project"

(
  cd "$fresh_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

for document in AGENTS.md README.md CONTRIBUTING.md DESIGN.md ARCHITECTURE.md CLAUDE.md; do
  if [ -e "$fresh_project/$document" ] || [ -L "$fresh_project/$document" ]; then
    echo "Installer created active project documentation without onboarding: $document"
    exit 1
  fi
done

collision_project="$TEST_ROOT/template-symlink-project"
external_templates="$TEST_ROOT/external-templates"
mkdir -p "$collision_project/.agents" "$external_templates"
ln -s "$external_templates" "$collision_project/.agents/templates"

if (
  cd "$collision_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null 2>&1
); then
  echo "Installer accepted a symlinked template target"
  exit 1
fi

[ ! -e "$collision_project/.agents/skills" ]
[ -z "$(find "$external_templates" -mindepth 1 -print -quit)" ]

managed_collision_project="$TEST_ROOT/managed-symlink-project"
managed_collision_original="$TEST_ROOT/managed-collision-original"
managed_collision_victim="$TEST_ROOT/managed-collision-victim"
mkdir -p "$managed_collision_project/.agents/skills/onboard-project"
cat > "$managed_collision_victim" <<'EOF'
External content that a managed-tree sync must never overwrite.
EOF
cp "$managed_collision_victim" "$managed_collision_original"
ln -s "$managed_collision_victim" \
  "$managed_collision_project/.agents/skills/onboard-project/SKILL.md"

if (
  cd "$managed_collision_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null 2>&1
); then
  echo "Installer accepted a symlink inside an upstream-managed destination"
  exit 1
fi

cmp -s "$managed_collision_original" "$managed_collision_victim"
[ -L "$managed_collision_project/.agents/skills/onboard-project/SKILL.md" ]
[ ! -e "$managed_collision_project/.agents/templates" ]
[ ! -e "$managed_collision_project/.cursor" ]

adapter_collision_project="$TEST_ROOT/adapter-collision-project"
adapter_collision_original="$TEST_ROOT/adapter-collision-original"
mkdir -p \
  "$adapter_collision_project/.agents/skills/onboard-project" \
  "$adapter_collision_project/.cursor/skills"
cat > "$adapter_collision_project/.agents/skills/onboard-project/SKILL.md" <<'EOF'
Existing managed-path content used to prove failure atomicity.
EOF
cp "$adapter_collision_project/.agents/skills/onboard-project/SKILL.md" \
  "$adapter_collision_original"
touch "$adapter_collision_project/.cursor/skills/project-owned-sentinel"

if (
  cd "$adapter_collision_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null 2>&1
); then
  echo "Installer accepted a provider discovery collision"
  exit 1
fi

cmp -s "$adapter_collision_original" \
  "$adapter_collision_project/.agents/skills/onboard-project/SKILL.md"
[ -f "$adapter_collision_project/.cursor/skills/project-owned-sentinel" ]
[ ! -e "$adapter_collision_project/.agents/templates" ]
[ ! -e "$adapter_collision_project/.claude" ]

template_hardlink_project="$TEST_ROOT/template-hardlink-project"
template_hardlink_root_victim="$template_hardlink_project/README.md"
template_hardlink_adapter_victim="$template_hardlink_project/provider-notes.md"
mkdir -p "$template_hardlink_project"
printf 'project README must remain intact\n' > "$template_hardlink_root_victim"
printf 'provider notes must remain intact\n' > "$template_hardlink_adapter_victim"

(
  cd "$template_hardlink_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

rm "$template_hardlink_project/.agents/templates/AGENTS.md"
rm "$template_hardlink_project/.agents/templates/adapters/claude/CLAUDE.md"
ln "$template_hardlink_root_victim" \
  "$template_hardlink_project/.agents/templates/AGENTS.md"
ln "$template_hardlink_adapter_victim" \
  "$template_hardlink_project/.agents/templates/adapters/claude/CLAUDE.md"

(
  cd "$template_hardlink_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

grep -q 'project README must remain intact' "$template_hardlink_root_victim"
grep -q 'provider notes must remain intact' "$template_hardlink_adapter_victim"
cmp -s "$REPO_ROOT/project-templates/base/AGENTS.md" \
  "$template_hardlink_project/.agents/templates/AGENTS.md"
cmp -s "$REPO_ROOT/scripts/skill-adapters/claude-router.md" \
  "$template_hardlink_project/.agents/templates/adapters/claude/CLAUDE.md"

incomplete_source="$TEST_ROOT/incomplete-source"
incomplete_target="$TEST_ROOT/incomplete-target"
mkdir -p "$incomplete_source/.agents" "$incomplete_target"
cp -a "$REPO_ROOT/scripts" "$incomplete_source/scripts"
cp -a "$REPO_ROOT/project-templates" "$incomplete_source/project-templates"

if (
  cd "$incomplete_target"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$incomplete_source" >/dev/null 2>&1
); then
  echo "Installer accepted a distribution without canonical skills"
  exit 1
fi

[ -z "$(find "$incomplete_target" -mindepth 1 -print -quit)" ]

reserved_source="$TEST_ROOT/reserved-source"
reserved_target="$TEST_ROOT/reserved-target"
cp -a "$incomplete_source" "$reserved_source"
mkdir -p \
  "$reserved_source/.agents/skills/example" \
  "$reserved_source/.agents/rules" \
  "$reserved_target"
printf '%s\n' '---' 'name: example' '---' > \
  "$reserved_source/.agents/skills/example/SKILL.md"
printf 'legacy source content\n' > \
  "$reserved_source/.agents/rules/legacy.md"

if (
  cd "$reserved_target"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$reserved_source" >/dev/null 2>&1
); then
  echo "Installer accepted reserved project context in a distribution"
  exit 1
fi

[ -z "$(find "$reserved_target" -mindepth 1 -print -quit)" ]

symlink_source="$TEST_ROOT/symlink-template-source"
symlink_source_target="$TEST_ROOT/symlink-template-target"
cp -a "$incomplete_source" "$symlink_source"
mkdir -p \
  "$symlink_source/.agents/skills/example" \
  "$symlink_source_target"
printf '%s\n' '---' 'name: example' '---' > \
  "$symlink_source/.agents/skills/example/SKILL.md"
rm "$symlink_source/project-templates/base/AGENTS.md"
ln -s "$REPO_ROOT/project-templates/base/AGENTS.md" \
  "$symlink_source/project-templates/base/AGENTS.md"

if (
  cd "$symlink_source_target"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$symlink_source" >/dev/null 2>&1
); then
  echo "Installer accepted a symlinked distribution template"
  exit 1
fi

[ -z "$(find "$symlink_source_target" -mindepth 1 -print -quit)" ]

if [ "$(id -u)" -ne 0 ]; then
  readonly_adapter_project="$TEST_ROOT/readonly-adapter-project"
  readonly_adapter_original="$TEST_ROOT/readonly-adapter-original"
  mkdir -p \
    "$readonly_adapter_project/.agents/skills/onboard-project" \
    "$readonly_adapter_project/.agents/templates/adapters/claude"
  printf 'preflight must preserve this old managed file\n' > \
    "$readonly_adapter_project/.agents/skills/onboard-project/SKILL.md"
  cp "$readonly_adapter_project/.agents/skills/onboard-project/SKILL.md" \
    "$readonly_adapter_original"
  chmod 0555 "$readonly_adapter_project/.agents/templates/adapters/claude"

  if (
    cd "$readonly_adapter_project"
    HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
      --from-local "$REPO_ROOT" >/dev/null 2>&1
  ); then
    echo "Installer accepted an unwritable adapter template directory"
    exit 1
  fi

  cmp -s "$readonly_adapter_original" \
    "$readonly_adapter_project/.agents/skills/onboard-project/SKILL.md"
  [ ! -e "$readonly_adapter_project/.agents/templates/AGENTS.md" ]
  [ ! -e "$readonly_adapter_project/.cursor" ]
  [ ! -e "$readonly_adapter_project/.claude" ]
else
  echo "Skipping chmod-based unwritable-directory case as uid 0"
fi

target_only_source="$TEST_ROOT/target-only-source"
target_only_project="$TEST_ROOT/target-only-project"
target_only_original="$TEST_ROOT/target-only-original"
cp -a "$incomplete_source" "$target_only_source"
mkdir -p \
  "$target_only_source/.agents/skills/example" \
  "$target_only_source/.agents/templates" \
  "$target_only_project/.agents/skills/onboard-project"
printf '%s\n' '---' 'name: example' '---' > \
  "$target_only_source/.agents/skills/example/SKILL.md"
printf 'source collision\n' > \
  "$target_only_source/.agents/templates/adapters"
printf 'old managed content must survive preflight\n' > \
  "$target_only_project/.agents/skills/onboard-project/SKILL.md"
cp "$target_only_project/.agents/skills/onboard-project/SKILL.md" \
  "$target_only_original"

if ! (
  cd "$target_only_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$target_only_source" >/dev/null 2>&1
); then
  echo "Installer failed to isolate a target-only source templates path"
  exit 1
fi

cmp -s "$target_only_original" \
  "$target_only_project/.agents/skills/onboard-project/SKILL.md"
cmp -s "$target_only_source/project-templates/base/AGENTS.md" \
  "$target_only_project/.agents/templates/AGENTS.md"
[ -d "$target_only_project/.agents/templates/adapters" ]
[ ! -f "$target_only_project/.agents/templates/adapters" ]
[ -L "$target_only_project/.cursor/skills" ]
[ -L "$target_only_project/.claude/skills" ]

self_install_project="$TEST_ROOT/self-install-project"
cp -a "$incomplete_source" "$self_install_project"
mkdir -p "$self_install_project/.agents/skills/example"
printf '%s\n' '---' 'name: example' '---' > \
  "$self_install_project/.agents/skills/example/SKILL.md"

for run in 1 2; do
  (
    cd "$self_install_project"
    HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
      --from-local "$self_install_project" >/dev/null
  )
done

cmp -s "$self_install_project/project-templates/base/AGENTS.md" \
  "$self_install_project/.agents/templates/AGENTS.md"
[ -L "$self_install_project/.cursor/skills" ]
[ -L "$self_install_project/.claude/skills" ]

echo "Project document preservation tests passed"
