#!/usr/bin/env bash

set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SYNC="$ROOT/scripts/sync-managed-tree.sh"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
failures=0

run() { local name="$1"; shift; if ("$@"); then echo "ok - $name"; else echo "not ok - $name"; failures=$((failures + 1)); fi; }

initial_and_update() {
  local base="$TMP/update"
  mkdir -p "$base/source/nested" "$base/target/local"
  printf 'one\n' > "$base/source/nested/rule.md"
  printf 'keep\n' > "$base/target/local/extension.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  grep -q one "$base/target/nested/rule.md" || return 1
  grep -q keep "$base/target/local/extension.md" || return 1
  grep -q '^agents-ecosystem-managed-state-v2$' "$base/target/.agents-ecosystem-managed-state-v2" || return 1
  printf 'two\n' > "$base/source/nested/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  grep -q two "$base/target/nested/rule.md"
}

retires_only_managed() {
  local base="$TMP/retire"
  mkdir -p "$base/source" "$base/target"
  printf 'managed\n' > "$base/source/old.md"
  printf 'local\n' > "$base/target/local.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  rm "$base/source/old.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  [ ! -e "$base/target/old.md" ] && grep -q local "$base/target/local.md"
}

retired_symlink_ancestor_blocks() {
  local base="$TMP/retired-symlink" output
  mkdir -p "$base/source/nested" "$base/target" "$base/external/nested"
  printf 'managed\n' > "$base/source/nested/old.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  rm "$base/source/nested/old.md"
  rmdir "$base/source/nested"
  cp "$base/target/nested/old.md" "$base/external/nested/old.md"
  rm "$base/target/nested/old.md"
  rmdir "$base/target/nested"
  ln -s "$base/external/nested" "$base/target/nested"
  if output="$(bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'crosses a symlink' <<< "$output" \
    && grep -q managed "$base/external/nested/old.md" \
    && [ -L "$base/target/nested" ]
}

modified_managed_blocks() {
  local base="$TMP/modified" output
  mkdir -p "$base/source"
  printf 'managed\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'owner edit\n' > "$base/target/rule.md"
  printf 'upstream edit\n' > "$base/source/rule.md"
  if output="$(bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'changed locally' <<< "$output" && grep -q 'owner edit' "$base/target/rule.md"
}

content_change_during_staging_is_preserved() {
  local base="$TMP/content-race" fake="$TMP/content-race/bin" output real_cp
  mkdir -p "$base/source" "$fake"
  printf 'managed v1\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'managed v2\n' > "$base/source/rule.md"
  real_cp="$(command -p -v cp)"
  cat > "$fake/cp" <<'EOF'
#!/bin/bash
"$AGENTS_ECOSYSTEM_TEST_CP" "$@" || exit $?
if [ "${1:-}" = -a ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MARKER"
  printf 'owner edit during staging\n' > "$AGENTS_ECOSYSTEM_TEST_TARGET/rule.md"
fi
EOF
  chmod +x "$fake/cp"
  if output="$(PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_CP="$real_cp" \
    AGENTS_ECOSYSTEM_TEST_MARKER="$base/triggered" AGENTS_ECOSYSTEM_TEST_TARGET="$base/target" \
    bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'changed during staging' <<< "$output" \
    && grep -q 'owner edit during staging' "$base/target/rule.md"
}

mode_change_during_staging_is_preserved() {
  local base="$TMP/mode-race" fake="$TMP/mode-race/bin" output real_cp
  mkdir -p "$base/source" "$fake"
  printf 'managed v1\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'managed v2\n' > "$base/source/rule.md"
  real_cp="$(command -p -v cp)"
  cat > "$fake/cp" <<'EOF'
#!/bin/bash
"$AGENTS_ECOSYSTEM_TEST_CP" "$@" || exit $?
if [ "${1:-}" = -a ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MARKER"
  chmod 0600 "$AGENTS_ECOSYSTEM_TEST_TARGET/rule.md"
fi
EOF
  chmod +x "$fake/cp"
  if output="$(PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_CP="$real_cp" \
    AGENTS_ECOSYSTEM_TEST_MARKER="$base/triggered" AGENTS_ECOSYSTEM_TEST_TARGET="$base/target" \
    bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'changed during staging' <<< "$output" \
    && [ "$(stat -c '%a' "$base/target/rule.md")" = 600 ]
}

unsafe_source_file_modes_are_normalized() {
  local base="$TMP/source-modes"
  mkdir -p "$base/source"
  printf 'plain\n' > "$base/source/plain.md"
  printf '#!/bin/sh\n' > "$base/source/tool.sh"
  chmod 0666 "$base/source/plain.md"
  chmod 0777 "$base/source/tool.sh"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  [ "$(stat -c '%a' "$base/target/plain.md")" = 644 ] \
    && [ "$(stat -c '%a' "$base/target/tool.sh")" = 755 ]
}

existing_target_root_mode_is_preserved() {
  local base="$TMP/target-root-mode"
  mkdir -p "$base/source"
  printf 'managed v1\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  chmod 0700 "$base/target"
  printf 'managed v2\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  [ "$(stat -c '%a' "$base/target")" = 700 ] \
    && grep -q 'managed v2' "$base/target/rule.md"
}

permissive_managed_state_mode_is_rejected() {
  local base="$TMP/state-mode" output
  mkdir -p "$base/source"
  printf 'managed v1\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  chmod 0666 "$base/target/.agents-ecosystem-managed-state-v2"
  printf 'managed v2\n' > "$base/source/rule.md"
  if output="$(bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'managed state mode' <<< "$output" \
    && [ "$(stat -c '%a' "$base/target/.agents-ecosystem-managed-state-v2")" = 666 ] \
    && grep -q 'managed v1' "$base/target/rule.md"
}

future_collision_blocks_before_mutation() {
  local base="$TMP/collision" output
  mkdir -p "$base/source" "$base/target"
  printf 'v1\n' > "$base/source/current.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'local\n' > "$base/target/future.md"
  printf 'upstream\n' > "$base/source/future.md"
  if output="$(bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'collides with a local extension' <<< "$output" \
    && grep -q local "$base/target/future.md" \
    && grep -q v1 "$base/target/current.md"
}

matching_local_collision_blocks() {
  local base="$TMP/matching-collision" output
  mkdir -p "$base/source" "$base/target"
  printf 'v1\n' > "$base/source/current.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'same bytes\n' > "$base/source/future.md"
  printf 'same bytes\n' > "$base/target/future.md"
  if output="$(bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'collides with a local extension' <<< "$output" \
    && grep -q 'same bytes' "$base/target/future.md"
}

activation_gap_fresh_preserves_concurrent_target() {
  local base="$TMP/activation-fresh" fake="$TMP/activation-fresh/bin" output real_mv
  mkdir -p "$base/source" "$fake"
  printf 'managed\n' > "$base/source/rule.md"
  real_mv="$(command -p -v mv)"
  cat > "$fake/mv" <<'EOF'
#!/bin/bash
if [ "${1##*/}" = next ] && [ "${2:-}" = "$AGENTS_ECOSYSTEM_TEST_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MARKER"
  mkdir "$AGENTS_ECOSYSTEM_TEST_TARGET"
  printf 'concurrent owner\n' > "$AGENTS_ECOSYSTEM_TEST_TARGET/concurrent.md"
fi
exec "$AGENTS_ECOSYSTEM_TEST_MV" "$@"
EOF
  chmod +x "$fake/mv"
  if output="$(PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_TARGET="$base/target" AGENTS_ECOSYSTEM_TEST_MARKER="$base/triggered" \
    bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'changed during activation' <<< "$output" \
    && grep -q 'concurrent owner' "$base/target/concurrent.md" \
    && [ ! -e "$base/target/next" ]
}

activation_gap_update_retains_prior() {
  local base="$TMP/activation-update" fake="$TMP/activation-update/bin" output real_mv recovery
  mkdir -p "$base/source" "$fake"
  printf 'managed v1\n' > "$base/source/rule.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'managed v2\n' > "$base/source/rule.md"
  real_mv="$(command -p -v mv)"
  cat > "$fake/mv" <<'EOF'
#!/bin/bash
if [ "${1##*/}" = next ] && [ "${2:-}" = "$AGENTS_ECOSYSTEM_TEST_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MARKER"
  mkdir "$AGENTS_ECOSYSTEM_TEST_TARGET"
  printf 'concurrent owner\n' > "$AGENTS_ECOSYSTEM_TEST_TARGET/concurrent.md"
fi
exec "$AGENTS_ECOSYSTEM_TEST_MV" "$@"
EOF
  chmod +x "$fake/mv"
  if output="$(PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_MV="$real_mv" \
    AGENTS_ECOSYSTEM_TEST_TARGET="$base/target" AGENTS_ECOSYSTEM_TEST_MARKER="$base/triggered" \
    bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'changed during activation' <<< "$output" || return 1
  grep -q 'concurrent owner' "$base/target/concurrent.md" || return 1
  [ ! -e "$base/target/next" ] || return 1
  recovery="$(find "$base" -maxdepth 3 -path '*/previous/rule.md' -print -quit)"
  [ -n "$recovery" ] && grep -q 'managed v1' "$recovery"
}

backup_cleanup_failure_keeps_new_tree() {
  local base="$TMP/backup-cleanup" fake="$TMP/backup-cleanup/bin" output real_rm recovery
  mkdir -p "$base/source" "$base/target/local" "$fake"
  printf 'managed v1\n' > "$base/source/rule.md"
  printf 'owner\n' > "$base/target/local/keep.md"
  bash "$SYNC" "$base/source" "$base/target" >/dev/null || return 1
  printf 'managed v2\n' > "$base/source/rule.md"
  real_rm="$(command -p -v rm)"
  cat > "$fake/rm" <<'EOF'
#!/bin/bash
last="${!#}"
if [ "${last##*/}" = previous ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MARKER"
  "$AGENTS_ECOSYSTEM_TEST_RM" -f -- "$last/.agents-ecosystem-managed-state-v2" "$last/rule.md"
  exit 71
fi
exec "$AGENTS_ECOSYSTEM_TEST_RM" "$@"
EOF
  chmod +x "$fake/rm"
  if output="$(PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_RM="$real_rm" \
    AGENTS_ECOSYSTEM_TEST_MARKER="$base/triggered" bash "$SYNC" \
    "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'backup cleanup failed' <<< "$output" || return 1
  grep -q 'managed v2' "$base/target/rule.md" || return 1
  [ -f "$base/target/.agents-ecosystem-managed-state-v2" ] || return 1
  grep -q owner "$base/target/local/keep.md" || return 1
  recovery="$(find "$base" -maxdepth 4 -path '*/previous/local/keep.md' -print -quit)"
  [ -n "$recovery" ] && grep -q owner "$recovery"
}

stage_cleanup_failure_releases_lock() {
  local base="$TMP/stage-cleanup" fake="$TMP/stage-cleanup/bin" real_rm
  mkdir -p "$base/source" "$fake"
  printf 'managed\n' > "$base/source/rule.md"
  real_rm="$(command -p -v rm)"
  cat > "$fake/rm" <<'EOF'
#!/bin/bash
last="${!#}"
if [[ "${last##*/}" = .target.agents-ecosystem-stage.* ]]; then exit 72; fi
exec "$AGENTS_ECOSYSTEM_TEST_RM" "$@"
EOF
  chmod +x "$fake/rm"
  if PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_RM="$real_rm" \
    bash "$SYNC" "$base/source" "$base/target" >/dev/null 2>&1; then
    return 1
  fi
  [ ! -e "$base/.target.agents-ecosystem-sync.lock" ] \
    && grep -q managed "$base/target/rule.md"
}

early_lock_cleanup_failure_is_reported() {
  local base="$TMP/early-lock-cleanup" fake="$TMP/early-lock-cleanup/bin" output real_rmdir
  mkdir -p "$base/source" "$base/target" "$fake"
  printf 'managed\n' > "$base/source/rule.md"
  printf 'invalid-state\n' > "$base/target/.agents-ecosystem-managed-state-v2"
  chmod 0600 "$base/target/.agents-ecosystem-managed-state-v2"
  real_rmdir="$(command -p -v rmdir)"
  cat > "$fake/rmdir" <<'EOF'
#!/bin/bash
if [[ "${1##*/}" = .target.agents-ecosystem-sync.lock ]]; then exit 75; fi
exec "$AGENTS_ECOSYSTEM_TEST_RMDIR" "$@"
EOF
  chmod +x "$fake/rmdir"
  if output="$(PATH="$fake:$PATH" AGENTS_ECOSYSTEM_TEST_RMDIR="$real_rmdir" \
    bash "$SYNC" "$base/source" "$base/target" 2>&1)"; then return 1; fi
  grep -q 'managed-tree lock cleanup failed' <<< "$output"
}

check_is_read_only() {
  local base="$TMP/check"
  mkdir -p "$base/source"
  printf 'managed\n' > "$base/source/rule.md"
  bash "$SYNC" --check "$base/source" "$base/target" >/dev/null || return 1
  [ ! -e "$base/target" ] && [ ! -e "$base/.target.agents-ecosystem-sync.lock" ]
}

exclusion_works() {
  local base="$TMP/exclude"
  mkdir -p "$base/source/templates" "$base/source/skills"
  printf 'candidate\n' > "$base/source/templates/README.md"
  printf 'skill\n' > "$base/source/skills/SKILL.md"
  bash "$SYNC" --exclude-top-level templates "$base/source" "$base/target" >/dev/null || return 1
  [ ! -e "$base/target/templates" ] && [ -f "$base/target/skills/SKILL.md" ]
}

symlinks_are_rejected() {
  local base="$TMP/symlink"
  mkdir -p "$base/source" "$base/external" "$base/target"
  printf 'outside\n' > "$base/external/rule.md"
  ln -s "$base/external/rule.md" "$base/source/rule.md"
  ! bash "$SYNC" "$base/source" "$base/target" >/dev/null 2>&1 || return 1
  rm "$base/source/rule.md"
  printf 'managed\n' > "$base/source/rule.md"
  ln -s "$base/external" "$base/target/nested"
  mkdir -p "$base/source/nested"
  printf 'managed\n' > "$base/source/nested/rule.md"
  ! bash "$SYNC" "$base/source" "$base/target" >/dev/null 2>&1
}

cooperative_lock_blocks() {
  local base="$TMP/lock"
  mkdir -p "$base/source" "$base/.target.agents-ecosystem-sync.lock"
  printf 'managed\n' > "$base/source/rule.md"
  ! bash "$SYNC" "$base/source" "$base/target" >/dev/null 2>&1
}

run "initial install and update preserve local extensions" initial_and_update
run "retirement removes only unchanged managed files" retires_only_managed
run "retirement rejects a symlinked managed ancestor" retired_symlink_ancestor_blocks
run "local managed edits block refresh" modified_managed_blocks
run "content change during staging is detected and preserved" content_change_during_staging_is_preserved
run "mode change during staging is detected and preserved" mode_change_during_staging_is_preserved
run "unsafe source file modes are normalized" unsafe_source_file_modes_are_normalized
run "existing target root mode is preserved" existing_target_root_mode_is_preserved
run "permissive managed state mode is rejected" permissive_managed_state_mode_is_rejected
run "future upstream collision blocks before mutation" future_collision_blocks_before_mutation
run "matching local content is not silently adopted" matching_local_collision_blocks
run "fresh activation gap preserves concurrent target" activation_gap_fresh_preserves_concurrent_target
run "update activation gap retains prior recovery" activation_gap_update_retains_prior
run "backup cleanup failure keeps the verified new tree" backup_cleanup_failure_keeps_new_tree
run "stage cleanup failure releases cooperative lock" stage_cleanup_failure_releases_lock
run "early lock cleanup failure is reported" early_lock_cleanup_failure_is_reported
run "check mode is read-only" check_is_read_only
run "top-level exclusions remain absent" exclusion_works
run "source and destination symlinks are rejected" symlinks_are_rejected
run "cooperative lock rejects overlapping updates" cooperative_lock_blocks

[ "$failures" -eq 0 ] || { echo "$failures sync test(s) failed" >&2; exit 1; }
echo "All managed-tree sync tests passed."
