# Generic user-level Agent Skills discovery path.

skill_adapter_supports_scope() {
  [ "$1" = "user" ]
}

skill_adapter_target() {
  printf '%s/.agents/skills\n' "$HOME"
}

skill_adapter_link_source() {
  printf '%s\n' "$2"
}
