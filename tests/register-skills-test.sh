#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTER_SCRIPT="$REPO_ROOT/scripts/register-skills.sh"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

failures=0

run_test() {
  local name="$1"
  shift

  if ("$@"); then
    echo "ok - $name"
  else
    echo "not ok - $name"
    failures=$((failures + 1))
  fi
}

assert_link() {
  local path="$1"
  local expected="$2"

  [ -L "$path" ] && [ "$(readlink "$path")" = "$expected" ]
}

assert_absent() {
  local path="$1"

  [ ! -e "$path" ] && [ ! -L "$path" ]
}

test_project_registration() {
  local project="$TEST_ROOT/project"
  mkdir -p "$project/.agents/skills"
  touch "$project/.agents/skills/example-skill"

  bash "$REGISTER_SCRIPT" --scope project --project-root "$project" >/dev/null || return 1

  assert_link "$project/.cursor/skills" "../.agents/skills" || return 1
  assert_link "$project/.claude/skills" "../.agents/skills" || return 1
  [ -f "$project/.agents/skills/example-skill" ]
}

test_user_registration() {
  local case_root="$TEST_ROOT/user"
  local source="$case_root/source/.agents/skills"
  mkdir -p "$source" "$case_root/home"

  HOME="$case_root/home" bash "$REGISTER_SCRIPT" \
    --scope user \
    --source "$source" >/dev/null || return 1

  assert_link "$case_root/home/.agents/skills" "$source" || return 1
  assert_link "$case_root/home/.cursor/skills" "$source" || return 1
  assert_link "$case_root/home/.claude/skills" "$source"
}

test_atomic_user_links_roll_back_only_owned_changes() {
  local case_root="$TEST_ROOT/atomic-user-links"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local fake_bin="$case_root/bin"
  local first_link="$user_home/.agents/skills"
  local fail_link="$user_home/.claude/skills"
  local linked_marker="$case_root/linked"
  local real_ln
  local output
  mkdir -p "$source" "$user_home" "$fake_bin"
  real_ln="$(command -p -v ln)"

  cat > "$fake_bin/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FIRST_LINK" ]; then
  "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
  : > "$AGENTS_ECOSYSTEM_TEST_LINKED_MARKER"
  exit 0
fi
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FAIL_LINK" ] \
  && [ -e "$AGENTS_ECOSYSTEM_TEST_LINKED_MARKER" ]; then
  exit 73
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
EOF
  chmod +x "$fake_bin/ln"

  if output="$(
    PATH="$fake_bin:$PATH" \
    HOME="$user_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_FIRST_LINK="$first_link" \
    AGENTS_ECOSYSTEM_TEST_FAIL_LINK="$fail_link" \
    AGENTS_ECOSYSTEM_TEST_LINKED_MARKER="$linked_marker" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links 2>&1
  )"; then
    return 1
  fi

  [ -e "$linked_marker" ] || return 1
  grep -q "rolled back" <<< "$output" || return 1
  assert_absent "$first_link" || return 1
  assert_absent "$fail_link" || return 1
  assert_absent "$user_home/.cursor/skills" || return 1
  assert_absent "$user_home/.agents" || return 1
  assert_absent "$user_home/.claude" || return 1
  assert_absent "$user_home/.cursor"
}

test_atomic_user_links_preserve_preexisting_and_concurrent_entries() {
  local case_root="$TEST_ROOT/atomic-user-preservation"
  local source="$case_root/source/.agents/skills"
  local existing_home="$case_root/existing-home"
  local concurrent_home="$case_root/concurrent-home"
  local fake_bin="$case_root/bin"
  local real_ln
  local output
  mkdir -p \
    "$source" \
    "$existing_home/.agents" \
    "$concurrent_home" \
    "$fake_bin"
  real_ln="$(command -p -v ln)"
  ln -s "$source" "$existing_home/.agents/skills"

  cat > "$fake_bin/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FAIL_LINK" ]; then
  if [ -n "${AGENTS_ECOSYSTEM_TEST_REPLACE_LINK:-}" ]; then
    rm -- "$AGENTS_ECOSYSTEM_TEST_REPLACE_LINK"
    printf 'concurrent owner\n' > "$AGENTS_ECOSYSTEM_TEST_REPLACE_LINK"
  fi
  exit 73
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
EOF
  chmod +x "$fake_bin/ln"

  if output="$(
    PATH="$fake_bin:$PATH" \
    HOME="$existing_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_FAIL_LINK="$existing_home/.claude/skills" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links 2>&1
  )"; then
    return 1
  fi
  assert_link "$existing_home/.agents/skills" "$source" || return 1

  if output="$(
    PATH="$fake_bin:$PATH" \
    HOME="$concurrent_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_FAIL_LINK="$concurrent_home/.claude/skills" \
    AGENTS_ECOSYSTEM_TEST_REPLACE_LINK="$concurrent_home/.agents/skills" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links 2>&1
  )"; then
    return 1
  fi
  grep -q "preserved" <<< "$output" || return 1
  grep -qx 'concurrent owner' "$concurrent_home/.agents/skills"
}

test_atomic_user_links_are_link_only() {
  local case_root="$TEST_ROOT/atomic-user-link-only"
  local fixture_root="$case_root/distribution"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local configure_marker="$case_root/configured"
  mkdir -p "$fixture_root/skill-adapters" "$source" "$user_home"
  cp "$REGISTER_SCRIPT" "$fixture_root/register-skills.sh"

  cat > "$fixture_root/skill-adapters/configuring.sh" <<'EOF'
skill_adapter_supports_scope() { [ "$1" = "user" ]; }
skill_adapter_target() { printf '%s/.configuring/skills\n' "$HOME"; }
skill_adapter_link_source() { printf '%s\n' "$2"; }
skill_adapter_configure() {
  : > "$AGENTS_ECOSYSTEM_TEST_CONFIGURE_MARKER"
  return 73
}
EOF

  HOME="$user_home" \
  AGENTS_ECOSYSTEM_TEST_CONFIGURE_MARKER="$configure_marker" \
    bash "$fixture_root/register-skills.sh" \
      --scope user \
      --source "$source" \
      --atomic-user-links >/dev/null || return 1

  # The constrained mode remains link-only when the requested link already
  # exists; idempotence must not expose configure side effects.
  HOME="$user_home" \
  AGENTS_ECOSYSTEM_TEST_CONFIGURE_MARKER="$configure_marker" \
    bash "$fixture_root/register-skills.sh" \
      --scope user \
      --source "$source" \
      --atomic-user-links >/dev/null || return 1

  assert_link "$user_home/.configuring/skills" "$source" || return 1
  assert_absent "$configure_marker"
}

test_atomic_user_links_preserve_matching_concurrent_entry() {
  local case_root="$TEST_ROOT/atomic-user-matching-concurrent"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local fake_bin="$case_root/bin"
  local concurrent_parent="$user_home/.claude"
  local concurrent_link="$concurrent_parent/skills"
  local fail_link="$user_home/.cursor/skills"
  local concurrent_marker="$case_root/concurrent-created"
  local real_ln
  local real_mkdir
  mkdir -p "$source" "$user_home" "$fake_bin"
  real_ln="$(command -p -v ln)"
  real_mkdir="$(command -p -v mkdir)"

  cat > "$fake_bin/mkdir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
"$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$@"
if { [ "$*" = "-p $AGENTS_ECOSYSTEM_TEST_CONCURRENT_PARENT" ] \
    || [ "$*" = "$AGENTS_ECOSYSTEM_TEST_CONCURRENT_PARENT" ]; } \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_CONCURRENT_MARKER" ]; then
  "$AGENTS_ECOSYSTEM_TEST_REAL_LN" -s \
    "$AGENTS_ECOSYSTEM_TEST_SOURCE" \
    "$AGENTS_ECOSYSTEM_TEST_CONCURRENT_LINK"
  : > "$AGENTS_ECOSYSTEM_TEST_CONCURRENT_MARKER"
fi
EOF
  cat > "$fake_bin/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FAIL_LINK" ]; then
  exit 73
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
EOF
  chmod +x "$fake_bin/mkdir" "$fake_bin/ln"

  if PATH="$fake_bin:$PATH" \
    HOME="$user_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_REAL_MKDIR="$real_mkdir" \
    AGENTS_ECOSYSTEM_TEST_CONCURRENT_PARENT="$concurrent_parent" \
    AGENTS_ECOSYSTEM_TEST_CONCURRENT_LINK="$concurrent_link" \
    AGENTS_ECOSYSTEM_TEST_CONCURRENT_MARKER="$concurrent_marker" \
    AGENTS_ECOSYSTEM_TEST_SOURCE="$source" \
    AGENTS_ECOSYSTEM_TEST_FAIL_LINK="$fail_link" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links >/dev/null 2>&1; then
    return 1
  fi

  [ -e "$concurrent_marker" ] || return 1
  assert_link "$concurrent_link" "$source" || return 1
  assert_absent "$user_home/.agents/skills" || return 1
  assert_absent "$user_home/.cursor/skills"
}

test_atomic_user_links_defer_signal_until_ownership_is_recorded() {
  local case_root="$TEST_ROOT/atomic-user-signal-window"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local fake_bin="$case_root/bin"
  local first_link="$user_home/.agents/skills"
  local signal_marker="$case_root/signal-fired"
  local real_ln
  local real_mv
  mkdir -p "$source" "$user_home" "$fake_bin"
  real_ln="$(command -p -v ln)"
  real_mv="$(command -p -v mv)"

  cat > "$fake_bin/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
"$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER"
  kill -TERM "$PPID"
fi
EOF
cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -eq 1 ] && [ "$1" = "--help" ]; then
  exit 1
fi
source_path=""
target_path=""
after_options=0
for argument in "$@"; do
  if [ "$after_options" -eq 0 ]; then
    case "$argument" in
      --) after_options=1; continue ;;
      -*) continue ;;
    esac
  fi
  source_path="$target_path"
  target_path="$argument"
done
"$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER"
  kill -TERM "$PPID"
fi
EOF
  chmod +x "$fake_bin/ln" "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" \
    HOME="$user_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET="$first_link" \
    AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER="$signal_marker" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links >/dev/null 2>&1; then
    return 1
  fi

  [ -e "$signal_marker" ] || return 1
  assert_absent "$first_link" || return 1
  assert_absent "$user_home/.claude/skills" || return 1
  assert_absent "$user_home/.cursor/skills"
}

test_atomic_user_links_do_not_claim_same_target_replacement() {
  local case_root="$TEST_ROOT/atomic-user-replaced-before-record"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local fake_bin="$case_root/bin"
  local first_link="$user_home/.agents/skills"
  local fail_link="$user_home/.claude/skills"
  local replacement_marker="$case_root/replaced"
  local real_ln
  local real_mv
  local real_rm
  mkdir -p "$source" "$user_home" "$fake_bin"
  real_ln="$(command -p -v ln)"
  real_mv="$(command -p -v mv)"
  real_rm="$(command -p -v rm)"

  cat > "$fake_bin/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FAIL_LINK" ] \
  && [ -e "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER" ]; then
  exit 73
fi
"$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER" ]; then
  replacement_path="$target_path.concurrent"
  "$AGENTS_ECOSYSTEM_TEST_REAL_LN" -s \
    "$AGENTS_ECOSYSTEM_TEST_SOURCE" "$replacement_path"
  "$AGENTS_ECOSYSTEM_TEST_REAL_RM" -- "$target_path"
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$replacement_path" "$target_path"
  : > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER"
fi
EOF
  cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
target_path=""
after_options=0
for argument in "$@"; do
  if [ "$after_options" -eq 0 ]; then
    case "$argument" in
      --) after_options=1; continue ;;
      -*) continue ;;
    esac
  fi
  source_path="$target_path"
  target_path="$argument"
done
"$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER" ]; then
  replacement_path="$target_path.concurrent"
  "$AGENTS_ECOSYSTEM_TEST_REAL_LN" -s \
    "$AGENTS_ECOSYSTEM_TEST_SOURCE" "$replacement_path"
  "$AGENTS_ECOSYSTEM_TEST_REAL_RM" -- "$target_path"
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$replacement_path" "$target_path"
  : > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER"
fi
EOF
  chmod +x "$fake_bin/ln" "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" \
    HOME="$user_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_REAL_RM="$real_rm" \
    AGENTS_ECOSYSTEM_TEST_SOURCE="$source" \
    AGENTS_ECOSYSTEM_TEST_REPLACEMENT_TARGET="$first_link" \
    AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER="$replacement_marker" \
    AGENTS_ECOSYSTEM_TEST_FAIL_LINK="$fail_link" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links >/dev/null 2>&1; then
    return 1
  fi

  [ -e "$replacement_marker" ] || return 1
  assert_link "$first_link" "$source"
}

test_atomic_user_rollback_quarantines_before_delete() {
  local case_root="$TEST_ROOT/atomic-user-rollback-quarantine"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local fake_bin="$case_root/bin"
  local first_link="$user_home/.agents/skills"
  local fail_link="$user_home/.claude/skills"
  local replacement_marker="$case_root/rollback-replaced"
  local real_ln
  local real_mv
  local real_rm
  mkdir -p "$source" "$user_home" "$fake_bin"
  real_ln="$(command -p -v ln)"
  real_mv="$(command -p -v mv)"
  real_rm="$(command -p -v rm)"

  cat > "$fake_bin/ln" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FAIL_LINK" ]; then
  exit 73
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
EOF
  cat > "$fake_bin/rm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target_path="${!#}"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_ROLLBACK_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER" ]; then
  "$AGENTS_ECOSYSTEM_TEST_REAL_RM" -- "$target_path"
  printf 'concurrent owner\n' > "$target_path"
  : > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_RM" "$@"
EOF
  cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
target_path=""
after_options=0
for argument in "$@"; do
  if [ "$after_options" -eq 0 ]; then
    case "$argument" in
      --) after_options=1; continue ;;
      -*) continue ;;
    esac
  fi
  source_path="$target_path"
  target_path="$argument"
done
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_FAIL_LINK" ]; then
  exit 73
fi
"$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
case "$target_path" in
  */.skills.rollback.*/skills)
    if [ "$source_path" = "$AGENTS_ECOSYSTEM_TEST_ROLLBACK_TARGET" ] \
      && [ ! -e "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER" ]; then
      printf 'concurrent owner\n' > "$source_path"
      : > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER"
    fi
    ;;
esac
EOF
  chmod +x "$fake_bin/ln" "$fake_bin/rm" "$fake_bin/mv"

  if PATH="$fake_bin:$PATH" \
    HOME="$user_home" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="$real_ln" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_REAL_RM="$real_rm" \
    AGENTS_ECOSYSTEM_TEST_FAIL_LINK="$fail_link" \
    AGENTS_ECOSYSTEM_TEST_ROLLBACK_TARGET="$first_link" \
    AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MARKER="$replacement_marker" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --atomic-user-links >/dev/null 2>&1; then
    return 1
  fi

  [ -e "$replacement_marker" ] || return 1
  [ -f "$first_link" ] || return 1
  grep -qx 'concurrent owner' "$first_link"
}

test_adapter_filter() {
  local project="$TEST_ROOT/filter"
  mkdir -p "$project/.agents/skills"

  bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor >/dev/null || return 1

  assert_link "$project/.cursor/skills" "../.agents/skills" || return 1
  assert_absent "$project/.claude/skills"
}

test_unchanged_link_is_idempotent() {
  local project="$TEST_ROOT/idempotent"
  local output
  mkdir -p "$project/.agents/skills"

  bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor >/dev/null || return 1

  output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor)" || return 1

  grep -q '\[Unchanged\]' <<< "$output" || return 1
  assert_link "$project/.cursor/skills" "../.agents/skills"
}

test_different_symlink_is_preserved() {
  local case_root="$TEST_ROOT/different-symlink"
  local project="$case_root/project"
  local existing_source="$case_root/existing-skills"
  local output
  mkdir -p "$project/.agents/skills" "$project/.cursor" "$existing_source"
  touch "$existing_source/keep-me"
  ln -s "$existing_source" "$project/.cursor/skills"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" 2>&1)"; then
    return 1
  fi

  grep -q "already a symlink" <<< "$output" || return 1
  assert_link "$project/.cursor/skills" "$existing_source" || return 1
  assert_absent "$project/.claude/skills" || return 1
  [ -f "$existing_source/keep-me" ]
}

test_existing_directory_is_preserved() {
  local project="$TEST_ROOT/preserve"
  local output
  mkdir -p "$project/.agents/skills" "$project/.cursor/skills"
  touch "$project/.cursor/skills/keep-me"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor 2>&1)"; then
    return 1
  fi

  grep -q "exists and is not a symlink" <<< "$output" || return 1
  [ -f "$project/.cursor/skills/keep-me" ] || return 1
  [ ! -L "$project/.cursor/skills" ]
}

test_project_scope_rejects_external_source() {
  local case_root="$TEST_ROOT/external-source"
  local project="$case_root/project"
  local external_source="$case_root/external/skills"
  local output
  mkdir -p "$project/.agents/skills" "$external_source"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --source "$external_source" \
    --adapters cursor 2>&1)"; then
    return 1
  fi

  grep -q "Project-scoped source must be" <<< "$output" || return 1
  assert_absent "$project/.cursor/skills"
}

test_project_scope_rejects_symlinked_agents_source_ancestor() {
  local case_root="$TEST_ROOT/symlinked-agents-source-ancestor"
  local project="$case_root/project"
  local external_agents="$case_root/external-agents"
  local output
  mkdir -p "$project" "$external_agents/skills"
  ln -s "$external_agents" "$project/.agents"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor 2>&1)"; then
    return 1
  fi

  grep -q "canonical source ancestor must be a physical directory" \
    <<< "$output" || return 1
  assert_absent "$project/.cursor/skills" || return 1
  assert_absent "$project/.claude/skills"
}

test_project_scope_rejects_symlinked_skills_source() {
  local case_root="$TEST_ROOT/symlinked-skills-source"
  local project="$case_root/project"
  local external_skills="$case_root/external-skills"
  local output
  mkdir -p "$project/.agents" "$external_skills"
  ln -s "$external_skills" "$project/.agents/skills"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor 2>&1)"; then
    return 1
  fi

  grep -q "canonical skills source must be a physical directory" \
    <<< "$output" || return 1
  assert_absent "$project/.cursor/skills" || return 1
  assert_absent "$project/.claude/skills"
}

test_preflight_prevents_partial_registration() {
  local case_root="$TEST_ROOT/preflight"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local output
  mkdir -p "$source" "$user_home/.claude/skills"
  touch "$user_home/.claude/skills/keep-me"

  if output="$(HOME="$user_home" bash "$REGISTER_SCRIPT" \
    --scope user \
    --source "$source" 2>&1)"; then
    return 1
  fi

  grep -q "exists and is not a symlink" <<< "$output" || return 1
  assert_absent "$user_home/.agents/skills" || return 1
  assert_absent "$user_home/.cursor/skills" || return 1
  [ -f "$user_home/.claude/skills/keep-me" ]
}

test_unsearchable_parent_prevents_partial_registration() {
  local case_root="$TEST_ROOT/unsearchable-parent"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local output

  if [ "$(id -u)" -eq 0 ]; then
    echo "# skip - uid 0 bypasses directory permission checks"
    return 0
  fi

  mkdir -p "$source" "$user_home/.cursor"
  chmod 0222 "$user_home/.cursor"

  if output="$(HOME="$user_home" bash "$REGISTER_SCRIPT" \
    --scope user \
    --source "$source" 2>&1)"; then
    chmod 0755 "$user_home/.cursor"
    return 1
  fi
  chmod 0755 "$user_home/.cursor"

  grep -q "not writable and searchable" <<< "$output" || return 1
  assert_absent "$user_home/.agents/skills" || return 1
  assert_absent "$user_home/.claude/skills" || return 1
  assert_absent "$user_home/.cursor/skills"
}

test_duplicate_adapter_targets_fail_before_registration() {
  local case_root="$TEST_ROOT/duplicate-targets"
  local fixture_root="$case_root/distribution"
  local project="$case_root/project"
  local output
  mkdir -p "$fixture_root/skill-adapters" "$project/.agents/skills"
  cp "$REGISTER_SCRIPT" "$fixture_root/register-skills.sh"

  cat > "$fixture_root/skill-adapters/alpha.sh" <<'EOF'
skill_adapter_supports_scope() { [ "$1" = "project" ]; }
skill_adapter_target() { printf '%s/.duplicate/skills\n' "$2"; }
skill_adapter_link_source() { printf '../.agents/skills\n'; }
EOF
  cat > "$fixture_root/skill-adapters/beta.sh" <<'EOF'
skill_adapter_supports_scope() { [ "$1" = "project" ]; }
skill_adapter_target() { printf '%s/.duplicate/skills\n' "$2"; }
skill_adapter_link_source() { printf '../different-skills\n'; }
EOF

  if output="$(bash "$fixture_root/register-skills.sh" \
    --scope project \
    --project-root "$project" 2>&1)"; then
    return 1
  fi

  grep -q "multiple adapters resolve to the same target" <<< "$output" || return 1
  assert_absent "$project/.duplicate"
}

test_preflight_only_does_not_mutate() {
  local project="$TEST_ROOT/preflight-only"
  mkdir -p "$project"

  bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --preflight-only >/dev/null || return 1

  assert_absent "$project/.agents" || return 1
  assert_absent "$project/.cursor" || return 1
  assert_absent "$project/.claude" || return 1
  assert_absent "$project/CLAUDE.md"
}

test_project_adapter_parent_symlink_is_rejected() {
  local case_root="$TEST_ROOT/symlink-parent"
  local project="$case_root/project"
  local external_parent="$case_root/external-cursor"
  local output
  mkdir -p "$project/.agents/skills" "$external_parent"
  ln -s "$external_parent" "$project/.cursor"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters cursor 2>&1)"; then
    return 1
  fi

  grep -q "adapter ancestor must not be a symlink" <<< "$output" || return 1
  assert_absent "$external_parent/skills"
}

test_nested_project_adapter_ancestor_symlink_is_rejected() {
  local case_root="$TEST_ROOT/nested-symlink-parent"
  local fixture_root="$case_root/distribution"
  local project="$case_root/project"
  local external_parent="$case_root/external-provider"
  local output
  mkdir -p \
    "$fixture_root/skill-adapters" \
    "$project/.agents/skills" \
    "$external_parent"
  cp "$REGISTER_SCRIPT" "$fixture_root/register-skills.sh"
  cat > "$fixture_root/skill-adapters/nested.sh" <<'EOF'
skill_adapter_supports_scope() { [ "$1" = "project" ]; }
skill_adapter_target() { printf '%s/.vendor/nested/skills\n' "$2"; }
skill_adapter_link_source() { printf '../../.agents/skills\n'; }
EOF
  ln -s "$external_parent" "$project/.vendor"

  if output="$(bash "$fixture_root/register-skills.sh" \
    --scope project \
    --project-root "$project" 2>&1)"; then
    return 1
  fi

  grep -q "adapter ancestor must not be a symlink" <<< "$output" || return 1
  [ -z "$(find "$external_parent" -mindepth 1 -print -quit)" ]
}

test_user_adapter_parent_symlink_is_rejected() {
  local case_root="$TEST_ROOT/user-symlink-parent"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local external_parent="$case_root/external-cursor"
  local output
  mkdir -p "$source" "$user_home" "$external_parent"
  ln -s "$external_parent" "$user_home/.cursor"

  if output="$(HOME="$user_home" bash "$REGISTER_SCRIPT" \
    --scope user \
    --source "$source" 2>&1)"; then
    return 1
  fi

  grep -q "user adapter ancestor must not be a symlink" <<< "$output" || return 1
  assert_absent "$user_home/.agents/skills" || return 1
  assert_absent "$user_home/.claude/skills" || return 1
  [ -z "$(find "$external_parent" -mindepth 1 -print -quit)" ]
}

test_user_adapter_parent_swap_before_link_is_rejected() {
  local case_root="$TEST_ROOT/user-parent-swap"
  local source="$case_root/source/.agents/skills"
  local user_home="$case_root/home"
  local external_parent="$case_root/external-cursor"
  local fake_bin="$case_root/bin"
  local real_mkdir
  local real_mv
  local output
  mkdir -p "$source" "$user_home" "$external_parent" "$fake_bin"

  cat > "$fake_bin/mkdir" <<'EOF'
#!/usr/bin/env bash
"$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$@"
if [ "$*" = "-p $AGENTS_ECOSYSTEM_TEST_TARGET_PARENT" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MUTATED" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MUTATED"
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" \
    "$AGENTS_ECOSYSTEM_TEST_TARGET_PARENT" "$AGENTS_ECOSYSTEM_TEST_SAVED_PARENT"
  ln -s "$AGENTS_ECOSYSTEM_TEST_EXTERNAL" "$AGENTS_ECOSYSTEM_TEST_TARGET_PARENT"
fi
EOF
  chmod +x "$fake_bin/mkdir"
  real_mkdir="$(command -p -v mkdir)"
  real_mv="$(command -p -v mv)"

  if output="$(
    HOME="$user_home" \
    PATH="$fake_bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_REAL_MKDIR="$real_mkdir" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_TARGET_PARENT="$user_home/.cursor" \
    AGENTS_ECOSYSTEM_TEST_SAVED_PARENT="$case_root/saved-cursor" \
    AGENTS_ECOSYSTEM_TEST_EXTERNAL="$external_parent" \
    AGENTS_ECOSYSTEM_TEST_MUTATED="$case_root/mutated" \
      bash "$REGISTER_SCRIPT" \
        --scope user \
        --source "$source" \
        --adapters cursor 2>&1
  )"; then
    return 1
  fi

  grep -q "user adapter ancestor must not be a symlink" <<< "$output" || return 1
  [ -z "$(find "$external_parent" -mindepth 1 -print -quit)" ]
}

test_registration_uses_safe_directory_modes() {
  local project="$TEST_ROOT/safe-registration-modes"
  mkdir -p "$project/.agents/skills"

  (
    umask 000
    bash "$REGISTER_SCRIPT" \
      --scope project \
      --project-root "$project" \
      --adapters cursor >/dev/null
  ) || return 1

  [ -z "$(find "$project/.cursor" -type d -perm -002 -print -quit)" ]
}

test_invalid_adapter_parent_prevents_partial_registration() {
  local project="$TEST_ROOT/invalid-parent"
  local output
  mkdir -p "$project/.agents/skills"
  touch "$project/.cursor"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" 2>&1)"; then
    return 1
  fi

  grep -q "adapter ancestor is not a directory" <<< "$output" || return 1
  assert_absent "$project/.claude/skills" || return 1
  assert_absent "$project/CLAUDE.md"
}

test_non_normalized_target_fails_before_registration() {
  local case_root="$TEST_ROOT/non-normalized-target"
  local fixture_root="$case_root/distribution"
  local project="$case_root/project"
  local output
  mkdir -p "$fixture_root/skill-adapters" "$project/.agents/skills"
  cp "$REGISTER_SCRIPT" "$fixture_root/register-skills.sh"
  cp "$REPO_ROOT/scripts/skill-adapters/cursor.sh" \
    "$fixture_root/skill-adapters/cursor.sh"
  cat > "$fixture_root/skill-adapters/alias.sh" <<'EOF'
skill_adapter_supports_scope() { [ "$1" = "project" ]; }
skill_adapter_target() { printf '%s/.cursor//skills\n' "$2"; }
skill_adapter_link_source() { printf '../other-skills\n'; }
EOF

  if output="$(bash "$fixture_root/register-skills.sh" \
    --scope project \
    --project-root "$project" 2>&1)"; then
    return 1
  fi

  grep -q "target must be normalized" <<< "$output" || return 1
  assert_absent "$project/.cursor"
}

test_unknown_adapter_fails() {
  local project="$TEST_ROOT/unknown"
  local output
  mkdir -p "$project/.agents/skills"

  if output="$(bash "$REGISTER_SCRIPT" \
    --scope project \
    --project-root "$project" \
    --adapters imaginary-agent 2>&1)"; then
    return 1
  fi

  grep -q "Unknown adapter: imaginary-agent" <<< "$output"
}

test_missing_option_values_fail_clearly() {
  local option
  local output

  for option in --scope --project-root --source --adapters; do
    if output="$(bash "$REGISTER_SCRIPT" "$option" 2>&1)"; then
      return 1
    fi
    grep -q -- "$option requires a value" <<< "$output" || return 1
  done
}

run_test "project adapters link to the canonical skill source" test_project_registration
run_test "user adapters link to the canonical skill source" test_user_registration
run_test "atomic user links roll back a partial registration" test_atomic_user_links_roll_back_only_owned_changes
run_test "atomic user rollback preserves preexisting and concurrent entries" test_atomic_user_links_preserve_preexisting_and_concurrent_entries
run_test "atomic user registration constrains adapters to link side effects" test_atomic_user_links_are_link_only
run_test "atomic rollback preserves a matching link created after its snapshot" test_atomic_user_links_preserve_matching_concurrent_entry
run_test "atomic user links defer signals through ownership journaling" test_atomic_user_links_defer_signal_until_ownership_is_recorded
run_test "atomic user links do not claim a same-target replacement" test_atomic_user_links_do_not_claim_same_target_replacement
run_test "atomic user rollback quarantines links before deletion" test_atomic_user_rollback_quarantines_before_delete
run_test "adapter selection limits provider-specific side effects" test_adapter_filter
run_test "re-registering an unchanged adapter is idempotent" test_unchanged_link_is_idempotent
run_test "a different provider symlink is preserved as a collision" test_different_symlink_is_preserved
run_test "existing provider directories are never overwritten" test_existing_directory_is_preserved
run_test "project links reject a non-canonical external source" test_project_scope_rejects_external_source
run_test "project links reject a symlinked canonical source ancestor" test_project_scope_rejects_symlinked_agents_source_ancestor
run_test "project links reject a symlinked canonical skills source" test_project_scope_rejects_symlinked_skills_source
run_test "adapter conflicts are detected before any link is changed" test_preflight_prevents_partial_registration
run_test "an unsearchable provider parent prevents every registration" test_unsearchable_parent_prevents_partial_registration
run_test "duplicate adapter targets fail before registration" test_duplicate_adapter_targets_fail_before_registration
run_test "preflight-only validates an uninstalled project without mutation" test_preflight_only_does_not_mutate
run_test "project adapters reject symlinked provider directories" test_project_adapter_parent_symlink_is_rejected
run_test "project adapters reject symlinked nested ancestors" test_nested_project_adapter_ancestor_symlink_is_rejected
run_test "user adapters reject symlinked provider directories before writing" test_user_adapter_parent_symlink_is_rejected
run_test "user adapters revalidate a provider parent immediately before linking" test_user_adapter_parent_swap_before_link_is_rejected
run_test "registration creates no world-writable directories" test_registration_uses_safe_directory_modes
run_test "invalid adapter parents are rejected before any mutation" test_invalid_adapter_parent_prevents_partial_registration
run_test "non-normalized adapter targets fail before registration" test_non_normalized_target_fails_before_registration
run_test "unknown adapters fail clearly" test_unknown_adapter_fails
run_test "missing option values produce actionable errors" test_missing_option_values_fail_clearly

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi

echo "All registration tests passed"
