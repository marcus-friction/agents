# Cursor project and user skill discovery paths.

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
    printf '%s/.cursor/skills\n' "$project_root"
  else
    printf '%s/.cursor/skills\n' "$HOME"
  fi
}

skill_adapter_link_source() {
  if [ "$1" = "project" ]; then
    printf '../.agents/skills\n'
  else
    printf '%s\n' "$2"
  fi
}
