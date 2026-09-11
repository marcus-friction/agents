#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

project="$TEST_ROOT/project"
mkdir -p "$project"
cat > "$project/AGENTS.md" <<'EOF'
# Product-specific agent guidance

Keep this content intact.
EOF
cat > "$project/CLAUDE.md" <<'EOF'
# Product-specific Claude guidance

Keep this Claude content intact.
EOF
cp "$project/AGENTS.md" "$TEST_ROOT/original-AGENTS.md"
cp "$project/CLAUDE.md" "$TEST_ROOT/original-CLAUDE.md"

(
  cd "$project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

cmp -s "$TEST_ROOT/original-AGENTS.md" "$project/AGENTS.md"

if grep -Eqi 'Cursor|Claude' "$project/AGENTS.md"; then
  echo "Custom AGENTS.md contains provider-specific registration text"
  exit 1
fi

cmp -s "$TEST_ROOT/original-CLAUDE.md" "$project/CLAUDE.md"

if grep -Eq '\.cursor/skills|\.claude/skills' \
  "$REPO_ROOT/.agents/skills/start-project/SKILL.md"; then
  echo "start-project embeds provider-specific registration paths"
  exit 1
fi

if grep -Eq '\.cursor/skills|\.claude/skills' \
  "$REPO_ROOT/.agents/skills/update-agents/SKILL.md"; then
  echo "update-agents embeds provider-specific registration paths"
  exit 1
fi

symlink_project="$TEST_ROOT/symlink-project"
mkdir -p "$symlink_project"
cat > "$symlink_project/AGENTS.md" <<'EOF'
# Symlinked project guidance

Do not append provider router content through a symlink.
EOF
ln -s AGENTS.md "$symlink_project/CLAUDE.md"

(
  cd "$symlink_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

[ -L "$symlink_project/CLAUDE.md" ]
[ "$(readlink "$symlink_project/CLAUDE.md")" = "AGENTS.md" ]

if grep -q '@AGENTS.md' "$symlink_project/AGENTS.md"; then
  echo "Claude adapter mutated AGENTS.md through a CLAUDE.md symlink"
  exit 1
fi

agents_symlink_project="$TEST_ROOT/agents-symlink-project"
external_guidance="$TEST_ROOT/shared-AGENTS.md"
mkdir -p "$agents_symlink_project"
cat > "$external_guidance" <<'EOF'
# Shared project guidance

This external file must remain unchanged.
EOF
ln -s "$external_guidance" "$agents_symlink_project/AGENTS.md"

(
  cd "$agents_symlink_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --from-local "$REPO_ROOT" >/dev/null
)

[ -L "$agents_symlink_project/AGENTS.md" ]
[ "$(readlink "$agents_symlink_project/AGENTS.md")" = "$external_guidance" ]

if grep -q '.agents/skills' "$external_guidance"; then
  echo "Installer mutated external guidance through an AGENTS.md symlink"
  exit 1
fi

echo "Tool-agnostic installer boundary tests passed"
