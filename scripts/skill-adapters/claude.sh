# Claude Code project and user skill discovery paths.

skill_adapter_supports_scope() {
  case "$1" in
    project|user) return 0 ;;
    *) return 1 ;;
  esac
}

skill_adapter_target() {
  local scope="$1"
  local project_root="$2"

  if [ "$scope" = "project" ]; then
    printf '%s/.claude/skills\n' "$project_root"
  else
    printf '%s/.claude/skills\n' "$HOME"
  fi
}

skill_adapter_link_source() {
  if [ "$1" = "project" ]; then
    printf '../.agents/skills\n'
  else
    printf '%s\n' "$2"
  fi
}

skill_adapter_preflight() {
  local scope="$1"
  local project_root="$2"
  local distribution_root="$4"
  local agents_dir="$project_root/.agents"
  local templates_dir="$agents_dir/templates"
  local candidate_parent="$project_root/.agents/templates/adapters"
  local candidate_dir="$candidate_parent/claude"
  local target_router="$candidate_dir/CLAUDE.md"
  local source_router="$distribution_root/scripts/skill-adapters/claude-router.md"

  if [ "$scope" != "project" ]; then
    return 0
  fi
  if [ ! -e "$agents_dir" ] \
    && { [ ! -w "$project_root" ] || [ ! -x "$project_root" ]; }; then
    echo "Error: project root is not writable and searchable: $project_root" >&2
    return 1
  fi
  if [ -L "$source_router" ] || [ ! -f "$source_router" ]; then
    echo "Error: Claude router candidate must be a physical file: $source_router" >&2
    return 1
  fi
  for directory in \
    "$agents_dir" \
    "$templates_dir" \
    "$candidate_parent" \
    "$candidate_dir"; do
    if [ -L "$directory" ]; then
      echo "Error: adapter template directory must not be a symlink: $directory" >&2
      return 1
    fi
    if [ -e "$directory" ] && [ ! -d "$directory" ]; then
      echo "Error: adapter template path is not a directory: $directory" >&2
      return 1
    fi
    if [ -d "$directory" ] \
      && { [ ! -w "$directory" ] || [ ! -x "$directory" ]; }; then
      echo "Error: adapter template directory is not writable and searchable: $directory" >&2
      return 1
    fi
  done
  if [ -L "$target_router" ]; then
    echo "Error: adapter template must not be a symlink: $target_router" >&2
    return 1
  fi
  if [ -e "$target_router" ] && [ ! -f "$target_router" ]; then
    echo "Error: adapter template is not a regular file: $target_router" >&2
    return 1
  fi
}

skill_adapter_configure() {
  local scope="$1"
  local project_root="$2"
  local skills_source="$3"
  local distribution_root="$4"
  local source_router="$distribution_root/scripts/skill-adapters/claude-router.md"
  local candidate_dir="$project_root/.agents/templates/adapters/claude"
  local target_router="$candidate_dir/CLAUDE.md"
  local staging_dir

  if [ "$scope" != "project" ] || [ ! -f "$source_router" ]; then
    return 0
  fi

  skill_adapter_preflight \
    "$scope" \
    "$project_root" \
    "$skills_source" \
    "$distribution_root"
  mkdir -p "$candidate_dir"
  staging_dir="$(mktemp -d "$candidate_dir/.router-stage.XXXXXX")"
  if ! cp -a "$source_router" "$staging_dir/CLAUDE.md"; then
    rm -rf "$staging_dir"
    return 1
  fi
  if ! chmod go-w "$staging_dir/CLAUDE.md"; then
    rm -rf "$staging_dir"
    return 1
  fi
  if ! mv -f "$staging_dir/CLAUDE.md" "$target_router"; then
    rm -rf "$staging_dir"
    return 1
  fi
  rmdir "$staging_dir"
  echo "   [Staged] Claude router candidate at $target_router"

  if [ -e "$project_root/CLAUDE.md" ] || [ -L "$project_root/CLAUDE.md" ]; then
    echo "   [Existing] Project-owned CLAUDE.md left untouched"
  else
    echo "   [Missing] Project-owned CLAUDE.md left for onboarding"
  fi
}
