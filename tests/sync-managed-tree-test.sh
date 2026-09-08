#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/scripts/sync-managed-tree.sh"
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

test_overlay_updates_managed_files_and_retains_extensions() {
  local case_root="$TEST_ROOT/overlay"
  mkdir -p "$case_root/source/standard" "$case_root/target/local-only"
  printf 'new managed content\n' > "$case_root/source/standard/rule.md"
  printf 'old managed content\n' > "$case_root/target/old.md"
  printf 'local extension\n' > "$case_root/target/local-only/SKILL.md"
  mkdir -p "$case_root/target/standard"
  printf 'nested local extension\n' > \
    "$case_root/target/standard/local-extension.md"

  bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" >/dev/null || return 1

  grep -q 'new managed content' "$case_root/target/standard/rule.md" || return 1
  grep -q 'old managed content' "$case_root/target/old.md" || return 1
  grep -q 'local extension' "$case_root/target/local-only/SKILL.md" || return 1
  grep -q 'nested local extension' \
    "$case_root/target/standard/local-extension.md"
}

test_collision_preflight_prevents_every_write() {
  local case_root="$TEST_ROOT/symlink-collision"
  local output
  mkdir -p "$case_root/source" "$case_root/target"
  printf 'replacement one\n' > "$case_root/source/one.md"
  printf 'replacement two\n' > "$case_root/source/two.md"
  printf 'original one\n' > "$case_root/target/one.md"
  printf 'external victim\n' > "$case_root/victim.md"
  ln -s "$case_root/victim.md" "$case_root/target/two.md"

  if output="$(bash "$SYNC_SCRIPT" \
    "$case_root/source" "$case_root/target" 2>&1)"; then
    return 1
  fi

  grep -q 'must not be a symlink' <<< "$output" || return 1
  grep -q 'original one' "$case_root/target/one.md" || return 1
  grep -q 'external victim' "$case_root/victim.md"
}

test_atomic_replace_does_not_modify_hardlink_peer() {
  local case_root="$TEST_ROOT/hardlink"
  mkdir -p "$case_root/source" "$case_root/target"
  printf 'replacement\n' > "$case_root/source/rule.md"
  printf 'external original\n' > "$case_root/external.md"
  ln "$case_root/external.md" "$case_root/target/rule.md"

  bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" >/dev/null || return 1

  grep -q 'replacement' "$case_root/target/rule.md" || return 1
  grep -q 'external original' "$case_root/external.md"
}

test_unsearchable_directory_fails_before_any_write() {
  local case_root="$TEST_ROOT/unsearchable-target"
  local output

  if [ "$(id -u)" -eq 0 ]; then
    echo "# skip - uid 0 bypasses directory permission checks"
    return 0
  fi

  mkdir -p "$case_root/source/z" "$case_root/target/z"
  printf 'new first file\n' > "$case_root/source/a.md"
  printf 'new nested file\n' > "$case_root/source/z/rule.md"
  printf 'original first file\n' > "$case_root/target/a.md"
  printf 'original nested file\n' > "$case_root/target/z/rule.md"
  chmod 0222 "$case_root/target/z"

  if output="$(bash "$SYNC_SCRIPT" \
    "$case_root/source" "$case_root/target" 2>&1)"; then
    chmod 0755 "$case_root/target/z"
    return 1
  fi
  chmod 0755 "$case_root/target/z"

  grep -q 'not writable and searchable' <<< "$output" || return 1
  grep -q 'original first file' "$case_root/target/a.md" || return 1
  grep -q 'original nested file' "$case_root/target/z/rule.md"
}

test_source_symlinks_are_rejected() {
  local case_root="$TEST_ROOT/source-symlink"
  local output
  mkdir -p "$case_root/source" "$case_root/target"
  printf 'outside\n' > "$case_root/outside.md"
  ln -s "$case_root/outside.md" "$case_root/source/rule.md"

  if output="$(bash "$SYNC_SCRIPT" \
    "$case_root/source" "$case_root/target" 2>&1)"; then
    return 1
  fi

  grep -q 'source contains a symlink or special file' <<< "$output" || return 1
  [ -z "$(find "$case_root/target" -mindepth 1 -print -quit)" ]
}

test_source_symlink_race_is_rejected_before_chmod() {
  local case_root="$TEST_ROOT/source-symlink-race"
  local fake_bin="$case_root/bin"
  local real_cp
  local original_mode
  local output
  mkdir -p "$case_root/source" "$case_root/target" "$fake_bin"
  printf 'validated source\n' > "$case_root/source/rule.md"
  printf 'original target\n' > "$case_root/target/rule.md"
  printf 'external victim\n' > "$case_root/external.md"
  chmod 0666 "$case_root/external.md"
  original_mode="$(stat -c '%a' -- "$case_root/external.md")"

  cat > "$fake_bin/cp" <<'EOF'
#!/usr/bin/env bash
case "${2:-}" in
  */.managed-tree-stage.*/next/rule.md) is_staged_file=1 ;;
  *) is_staged_file=0 ;;
esac
if [ "$is_staged_file" -eq 1 ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MUTATED" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MUTATED"
  rm -f -- "$AGENTS_ECOSYSTEM_TEST_SOURCE_FILE"
  ln -s -- "$AGENTS_ECOSYSTEM_TEST_EXTERNAL_FILE" \
    "$AGENTS_ECOSYSTEM_TEST_SOURCE_FILE"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_CP" "$@"
EOF
  chmod +x "$fake_bin/cp"
  real_cp="$(command -p -v cp)"

  if output="$(
    PATH="$fake_bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_REAL_CP="$real_cp" \
    AGENTS_ECOSYSTEM_TEST_SOURCE_FILE="$case_root/source/rule.md" \
    AGENTS_ECOSYSTEM_TEST_EXTERNAL_FILE="$case_root/external.md" \
    AGENTS_ECOSYSTEM_TEST_MUTATED="$case_root/mutated" \
      bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" 2>&1
  )"; then
    return 1
  fi

  grep -Eqi 'source.*changed|staged.*regular|symlink' <<< "$output" || return 1
  grep -q 'external victim' "$case_root/external.md" || return 1
  [ "$(stat -c '%a' -- "$case_root/external.md")" = "$original_mode" ] || return 1
  grep -q 'original target' "$case_root/target/rule.md" || return 1
  [ -z "$(find "$case_root" -path '*/next/rule.md' -type l -print -quit)" ]
}

test_sync_uses_safe_directory_modes() {
  local case_root="$TEST_ROOT/safe-directory-modes"
  mkdir -p "$case_root/source/nested"
  printf 'content\n' > "$case_root/source/nested/rule.md"
  chmod 0666 "$case_root/source/nested/rule.md"

  (
    umask 000
    bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" >/dev/null
  ) || return 1

  [ -z "$(find "$case_root/target" -type d -perm -002 -print -quit)" ] || return 1
  [ -z "$(find "$case_root/target" -type f -perm -020 -print -quit)" ] || return 1
  [ -z "$(find "$case_root/target" -type f -perm -002 -print -quit)" ]
}

test_commit_failure_restores_prior_tree() {
  local case_root="$TEST_ROOT/commit-rollback"
  local fake_bin="$case_root/bin"
  local count_file="$case_root/mv-count"
  local real_mv
  local output
  mkdir -p "$case_root/source/nested" "$case_root/target" "$fake_bin"
  printf 'replacement\n' > "$case_root/source/a.md"
  printf 'new managed file\n' > "$case_root/source/nested/b.md"
  printf 'original\n' > "$case_root/target/a.md"
  printf 'local extension\n' > "$case_root/target/local.md"

  cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
count=0
if [ -f "$AGENTS_ECOSYSTEM_TEST_MV_COUNT" ]; then
  count="$(cat "$AGENTS_ECOSYSTEM_TEST_MV_COUNT")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$AGENTS_ECOSYSTEM_TEST_MV_COUNT"
if [ "$count" -eq 2 ]; then
  exit 55
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
EOF
  chmod +x "$fake_bin/mv"
  real_mv="$(command -p -v mv)"

  if output="$(
    PATH="$fake_bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_MV_COUNT="$count_file" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
      bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" 2>&1
  )"; then
    return 1
  fi

  grep -q 'original' "$case_root/target/a.md" || return 1
  grep -q 'local extension' "$case_root/target/local.md" || return 1
  [ ! -e "$case_root/target/nested/b.md" ] || return 1
  [ -z "$(find "$case_root" -maxdepth 1 -name '.managed-tree-stage.*' -print -quit)" ]
}

test_target_change_during_staging_aborts_before_commit() {
  local case_root="$TEST_ROOT/concurrent-target-change"
  local fake_bin="$case_root/bin"
  local real_cp
  local real_mv
  local output
  mkdir -p \
    "$case_root/source" \
    "$case_root/target" \
    "$case_root/external" \
    "$fake_bin"
  printf 'replacement\n' > "$case_root/source/rule.md"
  printf 'original\n' > "$case_root/target/rule.md"

  cat > "$fake_bin/cp" <<'EOF'
#!/usr/bin/env bash
"$AGENTS_ECOSYSTEM_TEST_REAL_CP" "$@"
if [ ! -e "$AGENTS_ECOSYSTEM_TEST_MUTATED" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MUTATED"
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$AGENTS_ECOSYSTEM_TEST_TARGET" "$AGENTS_ECOSYSTEM_TEST_SAVED_TARGET"
  ln -s "$AGENTS_ECOSYSTEM_TEST_EXTERNAL" "$AGENTS_ECOSYSTEM_TEST_TARGET"
fi
EOF
  chmod +x "$fake_bin/cp"
  real_cp="$(command -p -v cp)"
  real_mv="$(command -p -v mv)"

  if output="$(
    PATH="$fake_bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_REAL_CP="$real_cp" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_MUTATED="$case_root/mutated" \
    AGENTS_ECOSYSTEM_TEST_TARGET="$case_root/target" \
    AGENTS_ECOSYSTEM_TEST_SAVED_TARGET="$case_root/saved-target" \
    AGENTS_ECOSYSTEM_TEST_EXTERNAL="$case_root/external" \
      bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" 2>&1
  )"; then
    return 1
  fi

  grep -q 'changed during staging' <<< "$output" || return 1
  [ -L "$case_root/target" ] || return 1
  [ -z "$(find "$case_root/external" -mindepth 1 -print -quit)" ] || return 1
  grep -q 'original' "$case_root/saved-target/rule.md"
}

test_target_replacement_at_commit_boundary_is_preserved() {
  local case_root="$TEST_ROOT/commit-boundary-replacement"
  local fake_bin="$case_root/bin"
  local real_cmp
  local real_mkdir
  local real_mv
  local count_file="$case_root/cmp-count"
  local output
  mkdir -p "$case_root/source" "$case_root/target" "$fake_bin"
  printf 'replacement\n' > "$case_root/source/rule.md"
  printf 'original\n' > "$case_root/target/rule.md"

  cat > "$fake_bin/cmp" <<'EOF'
#!/usr/bin/env bash
"$AGENTS_ECOSYSTEM_TEST_REAL_CMP" "$@"
status="$?"
if [ "$status" -eq 0 ]; then
  count=0
  [ ! -f "$AGENTS_ECOSYSTEM_TEST_CMP_COUNT" ] \
    || count="$(cat "$AGENTS_ECOSYSTEM_TEST_CMP_COUNT")"
  count=$((count + 1))
  printf '%s\n' "$count" > "$AGENTS_ECOSYSTEM_TEST_CMP_COUNT"
  if [ "$count" -eq 2 ]; then
    : > "$AGENTS_ECOSYSTEM_TEST_MUTATED"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$AGENTS_ECOSYSTEM_TEST_TARGET" "$AGENTS_ECOSYSTEM_TEST_SAVED_TARGET"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$AGENTS_ECOSYSTEM_TEST_TARGET"
    printf 'concurrent owner content\n' > "$AGENTS_ECOSYSTEM_TEST_TARGET/concurrent.md"
  fi
fi
exit "$status"
EOF
  chmod +x "$fake_bin/cmp"
  real_cmp="$(command -p -v cmp)"
  real_mkdir="$(command -p -v mkdir)"
  real_mv="$(command -p -v mv)"

  if output="$(
    PATH="$fake_bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_REAL_CMP="$real_cmp" \
    AGENTS_ECOSYSTEM_TEST_REAL_MKDIR="$real_mkdir" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_TARGET="$case_root/target" \
    AGENTS_ECOSYSTEM_TEST_SAVED_TARGET="$case_root/saved-target" \
    AGENTS_ECOSYSTEM_TEST_MUTATED="$case_root/mutated" \
    AGENTS_ECOSYSTEM_TEST_CMP_COUNT="$count_file" \
      bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" 2>&1
  )"; then
    return 1
  fi

  grep -Eqi 'changed.*commit|quarantin|replacement' <<< "$output" || return 1
  grep -q 'concurrent owner content' "$case_root/target/concurrent.md" || return 1
  grep -q 'original' "$case_root/saved-target/rule.md"
}

test_term_after_original_rename_preserves_recovery() {
  local case_root="$TEST_ROOT/term-after-original-rename"
  local fake_bin="$case_root/bin"
  local real_mv
  local output
  mkdir -p "$case_root/source" "$case_root/target" "$fake_bin"
  printf 'replacement\n' > "$case_root/source/rule.md"
  printf 'original\n' > "$case_root/target/rule.md"

  cat > "$fake_bin/mv" <<'EOF'
#!/usr/bin/env bash
"$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
status="$?"
if [ "$status" -eq 0 ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_SENT" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_SENT"
  kill -TERM "$PPID"
fi
exit "$status"
EOF
  chmod +x "$fake_bin/mv"
  real_mv="$(command -p -v mv)"

  if output="$(
    PATH="$fake_bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_SIGNAL_SENT="$case_root/signal-sent" \
      bash "$SYNC_SCRIPT" "$case_root/source" "$case_root/target" 2>&1
  )"; then
    return 1
  fi

  if [ -f "$case_root/target/rule.md" ] \
    && grep -q 'original' "$case_root/target/rule.md"; then
    return 0
  fi
  recovery="$(find "$case_root" -path '*/original/rule.md' -type f -print -quit)"
  [ -n "$recovery" ] && grep -q 'original' "$recovery" \
    && grep -Eqi 'recover|retain|restor' <<< "$output"
}

run_test \
  "managed overlay updates upstream files and retains local-only paths" \
  test_overlay_updates_managed_files_and_retains_extensions
run_test \
  "one destination collision prevents every managed-tree write" \
  test_collision_preflight_prevents_every_write
run_test \
  "managed files replace hardlinks without modifying their peers" \
  test_atomic_replace_does_not_modify_hardlink_peer
run_test \
  "an unsearchable target directory prevents every managed-tree write" \
  test_unsearchable_directory_fails_before_any_write
run_test \
  "managed sources reject symlinks and special files" \
  test_source_symlinks_are_rejected
run_test \
  "a source symlink race is rejected before staged chmod" \
  test_source_symlink_race_is_rejected_before_chmod
run_test \
  "managed sync creates no world-writable directories" \
  test_sync_uses_safe_directory_modes
run_test \
  "a commit-time failure restores the exact prior managed tree" \
  test_commit_failure_restores_prior_tree
run_test \
  "a target changed during staging aborts before commit" \
  test_target_change_during_staging_aborts_before_commit
run_test \
  "a physical target replacement at the commit boundary is preserved" \
  test_target_replacement_at_commit_boundary_is_preserved
run_test \
  "TERM after quarantining the original retains recoverable content" \
  test_term_after_original_rename_preserves_recovery

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi

echo "All managed-tree sync tests passed"
