#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

source_root="$TEST_ROOT/source"
project="$TEST_ROOT/project"
mkdir -p \
  "$source_root/project-templates/base" \
  "$project/.agents/templates/profiles"

for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  printf '%s candidate\n' "$document" \
    > "$source_root/project-templates/base/$document.md"
done
printf '%s\n' 'retired profile' \
  > "$project/.agents/templates/profiles/legacy-stack.md"

bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$source_root" \
  "$project" >/dev/null

for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  cmp -s \
    "$source_root/project-templates/base/$document.md" \
    "$project/.agents/templates/$document.md"
done
[ ! -e "$project/.agents/templates/profiles" ]

failure_project="$TEST_ROOT/failure-project"
failure_bin="$TEST_ROOT/failure-bin"
mkdir -p \
  "$failure_project/.agents/templates/profiles" \
  "$failure_bin"
printf '%s\n' 'retired profile must survive' \
  > "$failure_project/.agents/templates/profiles/legacy-project.md"
for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  printf '%s prior candidate\n' "$document" \
    > "$failure_project/.agents/templates/$document.md"
done
cat > "$failure_bin/cp" <<'EOF'
#!/usr/bin/env bash
exit 73
EOF
chmod +x "$failure_bin/cp"
if PATH="$failure_bin:$PATH" \
  bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
    "$source_root" "$failure_project" \
      >"$TEST_ROOT/staging-failure.out" 2>&1; then
  echo "Template staging ignored a candidate copy failure" >&2
  exit 1
fi
grep -qx 'retired profile must survive' \
  "$failure_project/.agents/templates/profiles/legacy-project.md"
for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  grep -qx "$document prior candidate" \
    "$failure_project/.agents/templates/$document.md"
done
[ -z "$(find "$failure_project/.agents" -maxdepth 1 \
  -name '.template-stage.*' -print -quit)" ]

real_mv="$(command -v mv)"
move_failure_bin="$TEST_ROOT/move-failure-bin"
mkdir -p "$move_failure_bin"
cat > "$move_failure_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source_path="${@: -2:1}"
destination_path="${@: -1}"
case "$source_path:$destination_path" in
  *'/.template-stage.'*/*.md:*'/.agents/templates/'*.md)
    candidate_move_count=0
    if [ -f "$CANDIDATE_MOVE_COUNT_FILE" ]; then
      candidate_move_count="$(cat "$CANDIDATE_MOVE_COUNT_FILE")"
    fi
    candidate_move_count=$((candidate_move_count + 1))
    printf '%s\n' "$candidate_move_count" > "$CANDIDATE_MOVE_COUNT_FILE"
    if [ "$candidate_move_count" -eq "$FAIL_CANDIDATE_MOVE" ]; then
      exit 74
    fi
    ;;
esac

exec "$REAL_MV" "$@"
EOF
chmod +x "$move_failure_bin/mv"

for failed_candidate_move in 2 5; do
  move_failure_project="$TEST_ROOT/move-failure-project-$failed_candidate_move"
  move_failure_before="$TEST_ROOT/move-failure-before-$failed_candidate_move"
  move_count_file="$TEST_ROOT/move-count-$failed_candidate_move"
  mkdir -p \
    "$move_failure_project/.agents/templates/profiles" \
    "$move_failure_project/.agents/templates/local"
  printf '%s\n' "retired profile before move $failed_candidate_move" \
    > "$move_failure_project/.agents/templates/profiles/legacy-project.md"
  printf '%s\n' "unrelated local content before move $failed_candidate_move" \
    > "$move_failure_project/.agents/templates/local/project-owned.md"
  for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
    printf '%s prior candidate before move %s\n' \
      "$document" "$failed_candidate_move" \
      > "$move_failure_project/.agents/templates/$document.md"
  done
  cp -a "$move_failure_project/.agents/templates" "$move_failure_before"

  if REAL_MV="$real_mv" \
    CANDIDATE_MOVE_COUNT_FILE="$move_count_file" \
    FAIL_CANDIDATE_MOVE="$failed_candidate_move" \
    PATH="$move_failure_bin:$PATH" \
    bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
      "$source_root" "$move_failure_project" \
        >"$TEST_ROOT/move-failure-$failed_candidate_move.out" 2>&1; then
    echo "Template staging ignored candidate move failure $failed_candidate_move" >&2
    exit 1
  fi

  diff -r \
    "$move_failure_before" \
    "$move_failure_project/.agents/templates"
  [ -z "$(find "$move_failure_project/.agents" -maxdepth 1 \
    -name '.template-stage.*' -print -quit)" ]
done

concurrent_source_a="$TEST_ROOT/concurrent-source-a"
concurrent_source_b="$TEST_ROOT/concurrent-source-b"
concurrent_project="$TEST_ROOT/concurrent-project"
concurrent_bin="$TEST_ROOT/concurrent-bin"
concurrent_state="$TEST_ROOT/concurrent-state"
mkdir -p \
  "$concurrent_source_a/project-templates/base" \
  "$concurrent_source_b/project-templates/base" \
  "$concurrent_project/.agents/templates/local" \
  "$concurrent_bin" \
  "$concurrent_state"
for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  printf '%s generation A\n' "$document" \
    > "$concurrent_source_a/project-templates/base/$document.md"
  printf '%s generation B\n' "$document" \
    > "$concurrent_source_b/project-templates/base/$document.md"
  printf '%s prior candidate\n' "$document" \
    > "$concurrent_project/.agents/templates/$document.md"
done
printf '%s\n' 'unrelated project candidate content' \
  > "$concurrent_project/.agents/templates/local/project-owned.md"

cat > "$concurrent_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source_path="${@: -2:1}"
destination_path="${@: -1}"
"$REAL_MV" "$@"

case "$source_path:$destination_path" in
  *'/.template-stage.'*/*.md:*'/.agents/templates/'*.md)
    move_count=0
    move_count_file="$CONCURRENT_STATE/$STAGE_ACTOR-move-count"
    if [ -f "$move_count_file" ]; then
      move_count="$(cat "$move_count_file")"
    fi
    move_count=$((move_count + 1))
    printf '%s\n' "$move_count" > "$move_count_file"
    if [ "$STAGE_ACTOR" = A ] && [ "$move_count" -eq 1 ]; then
      : > "$CONCURRENT_STATE/a-first-move"
      while [ ! -f "$CONCURRENT_STATE/release-a" ]; do
        sleep 0.01
      done
    elif [ "$STAGE_ACTOR" = B ] && [ "$move_count" -eq 5 ]; then
      : > "$CONCURRENT_STATE/b-finished-moves"
    fi
    ;;
esac
EOF
chmod +x "$concurrent_bin/mv"

real_mkdir="$(command -v mkdir)"
cat > "$concurrent_bin/mkdir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

for argument in "$@"; do
  if [ "$STAGE_ACTOR" = B ] \
    && [ "$argument" = "$CONCURRENT_LOCK_PATH" ]; then
    : > "$CONCURRENT_STATE/b-attempted-lock"
  fi
done

exec "$REAL_MKDIR" "$@"
EOF
chmod +x "$concurrent_bin/mkdir"

REAL_MV="$real_mv" \
REAL_MKDIR="$real_mkdir" \
CONCURRENT_STATE="$concurrent_state" \
CONCURRENT_LOCK_PATH="$concurrent_project/.agents/.template-stage.lock" \
STAGE_ACTOR=A \
PATH="$concurrent_bin:$PATH" \
bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$concurrent_source_a" "$concurrent_project" \
    >"$TEST_ROOT/concurrent-a.out" 2>&1 &
concurrent_a_pid="$!"

wait_attempt=0
while [ "$wait_attempt" -lt 500 ]; do
  if [ -f "$concurrent_state/a-first-move" ]; then
    break
  fi
  if ! kill -0 "$concurrent_a_pid" 2>/dev/null; then
    echo "First concurrent staging process exited before its first move" >&2
    wait "$concurrent_a_pid" || true
    exit 1
  fi
  wait_attempt=$((wait_attempt + 1))
  sleep 0.01
done
if [ ! -f "$concurrent_state/a-first-move" ]; then
  echo "Timed out waiting for the first concurrent candidate move" >&2
  exit 1
fi

REAL_MV="$real_mv" \
REAL_MKDIR="$real_mkdir" \
CONCURRENT_STATE="$concurrent_state" \
CONCURRENT_LOCK_PATH="$concurrent_project/.agents/.template-stage.lock" \
STAGE_ACTOR=B \
PATH="$concurrent_bin:$PATH" \
bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$concurrent_source_b" "$concurrent_project" \
    >"$TEST_ROOT/concurrent-b.out" 2>&1 &
concurrent_b_pid="$!"

wait_attempt=0
while [ "$wait_attempt" -lt 500 ]; do
  if [ -f "$concurrent_state/b-finished-moves" ] \
    || [ -f "$concurrent_state/b-attempted-lock" ]; then
    break
  fi
  if ! kill -0 "$concurrent_b_pid" 2>/dev/null; then
    echo "Second concurrent staging process exited before coordination" >&2
    wait "$concurrent_b_pid" || true
    exit 1
  fi
  wait_attempt=$((wait_attempt + 1))
  sleep 0.01
done
if [ ! -f "$concurrent_state/b-finished-moves" ] \
  && [ ! -f "$concurrent_state/b-attempted-lock" ]; then
  echo "Timed out coordinating concurrent template staging" >&2
  exit 1
fi
: > "$concurrent_state/release-a"

concurrent_a_status=0
concurrent_b_status=0
wait "$concurrent_a_pid" || concurrent_a_status="$?"
wait "$concurrent_b_pid" || concurrent_b_status="$?"
if [ "$concurrent_a_status" -ne 0 ] || [ "$concurrent_b_status" -ne 0 ]; then
  echo "Concurrent template staging did not complete successfully" >&2
  exit 1
fi

candidate_generation=''
for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  if cmp -s \
    "$concurrent_source_a/project-templates/base/$document.md" \
    "$concurrent_project/.agents/templates/$document.md"; then
    document_generation=A
  elif cmp -s \
    "$concurrent_source_b/project-templates/base/$document.md" \
    "$concurrent_project/.agents/templates/$document.md"; then
    document_generation=B
  else
    echo "Concurrent staging left an unknown $document candidate" >&2
    exit 1
  fi
  if [ -z "$candidate_generation" ]; then
    candidate_generation="$document_generation"
  elif [ "$candidate_generation" != "$document_generation" ]; then
    echo "Concurrent staging mixed candidate generations" >&2
    exit 1
  fi
done
if [ "$candidate_generation" != B ]; then
  echo "Concurrent staging did not commit the second complete generation" >&2
  exit 1
fi
grep -qx 'unrelated project candidate content' \
  "$concurrent_project/.agents/templates/local/project-owned.md"
[ -z "$(find "$concurrent_project/.agents" -maxdepth 1 \
  -name '.template-stage.*' -print -quit)" ]

lock_symlink_project="$TEST_ROOT/lock-symlink-project"
external_lock="$TEST_ROOT/external-template-lock"
mkdir -p "$lock_symlink_project/.agents" "$external_lock"
printf '%s\n' 'foreign lock data' > "$external_lock/foreign-owner"
ln -s "$external_lock" \
  "$lock_symlink_project/.agents/.template-stage.lock"
if bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$source_root" "$lock_symlink_project" \
    >"$TEST_ROOT/lock-symlink.out" 2>&1; then
  echo "Template staging accepted a symlinked transaction lock" >&2
  exit 1
fi
[ -L "$lock_symlink_project/.agents/.template-stage.lock" ]
grep -qx 'foreign lock data' "$external_lock/foreign-owner"
[ -z "$(find "$lock_symlink_project/.agents" -maxdepth 1 \
  -type d -name '.template-stage.*' -print -quit)" ]

real_rmdir="$(command -v rmdir)"
release_signal_project="$TEST_ROOT/release-signal-project"
release_signal_bin="$TEST_ROOT/release-signal-bin"
release_signal_state="$TEST_ROOT/release-signal-state"
mkdir -p \
  "$release_signal_project/.agents/templates" \
  "$release_signal_bin" \
  "$release_signal_state"
cat > "$release_signal_bin/rmdir" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

target_path="${@: -1}"
"$REAL_RMDIR" "$@"
case "$target_path" in
  *'/.template-stage.lock/owner-'*)
    if [ ! -f "$RELEASE_SIGNAL_STATE/sent" ]; then
      : > "$RELEASE_SIGNAL_STATE/sent"
      kill -TERM "$PPID"
    fi
    ;;
esac
EOF
chmod +x "$release_signal_bin/rmdir"

release_signal_status=0
REAL_RMDIR="$real_rmdir" \
RELEASE_SIGNAL_STATE="$release_signal_state" \
PATH="$release_signal_bin:$PATH" \
bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$source_root" "$release_signal_project" \
    >"$TEST_ROOT/release-signal.out" 2>&1 \
  || release_signal_status="$?"
if [ "$release_signal_status" -ne 143 ]; then
  echo "Template staging did not preserve TERM status during lock release" >&2
  exit 1
fi
[ -f "$release_signal_state/sent" ]
for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  cmp -s \
    "$source_root/project-templates/base/$document.md" \
    "$release_signal_project/.agents/templates/$document.md"
done
if [ -n "$(find "$release_signal_project/.agents" -maxdepth 1 \
  -name '.template-stage.*' -print -quit)" ]; then
  echo "Template staging left a stale lock after release-time TERM" >&2
  exit 1
fi

cleanup_signal_project="$TEST_ROOT/cleanup-signal-project"
cleanup_signal_before="$TEST_ROOT/cleanup-signal-before"
cleanup_signal_bin="$TEST_ROOT/cleanup-signal-bin"
cleanup_signal_state="$TEST_ROOT/cleanup-signal-state"
mkdir -p \
  "$cleanup_signal_project/.agents/templates" \
  "$cleanup_signal_bin" \
  "$cleanup_signal_state"
for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
  printf '%s prior cleanup candidate\n' "$document" \
    > "$cleanup_signal_project/.agents/templates/$document.md"
done
cp -a "$cleanup_signal_project/.agents/templates" "$cleanup_signal_before"
cat > "$cleanup_signal_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source_path="${@: -2:1}"
destination_path="${@: -1}"
"$REAL_MV" "$@"

case "$source_path:$destination_path" in
  *'/.template-stage.'*'/previous-candidates/'*.md:*'/.agents/templates/'*.md)
    if [ ! -f "$CLEANUP_SIGNAL_STATE/cleanup-signal-sent" ]; then
      : > "$CLEANUP_SIGNAL_STATE/cleanup-signal-sent"
      kill -TERM "$PPID"
    fi
    ;;
  *'/.template-stage.'*/*.md:*'/.agents/templates/'*.md)
    if [ ! -f "$CLEANUP_SIGNAL_STATE/initial-signal-sent" ]; then
      : > "$CLEANUP_SIGNAL_STATE/initial-signal-sent"
      kill -TERM "$PPID"
    fi
    ;;
esac
EOF
chmod +x "$cleanup_signal_bin/mv"

cleanup_signal_status=0
REAL_MV="$real_mv" \
CLEANUP_SIGNAL_STATE="$cleanup_signal_state" \
PATH="$cleanup_signal_bin:$PATH" \
bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$source_root" "$cleanup_signal_project" \
    >"$TEST_ROOT/cleanup-signal.out" 2>&1 \
  || cleanup_signal_status="$?"
if [ "$cleanup_signal_status" -ne 143 ]; then
  echo "Template staging did not preserve the first signal during cleanup" >&2
  exit 1
fi
[ -f "$cleanup_signal_state/initial-signal-sent" ]
[ -f "$cleanup_signal_state/cleanup-signal-sent" ]
diff -r \
  "$cleanup_signal_before" \
  "$cleanup_signal_project/.agents/templates"
if [ -n "$(find "$cleanup_signal_project/.agents" -maxdepth 1 \
  -name '.template-stage.*' -print -quit)" ]; then
  echo "Template staging left transaction data after a second cleanup signal" >&2
  exit 1
fi

rollback_replacement_bin="$TEST_ROOT/rollback-replacement-bin"
mkdir -p "$rollback_replacement_bin"
real_rm="$(command -v rm)"
real_ln="$(command -v ln)"
cat > "$rollback_replacement_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source_path="${@: -2:1}"
destination_path="${@: -1}"
case "$source_path:$destination_path" in
  *'/.template-stage.'*'/previous-candidates/'*.md:*'/.agents/templates/'*.md)
    exec "$REAL_MV" "$@"
    ;;
  *'/.template-stage.'*/*.md:*'/.agents/templates/'*.md)
    candidate_move_count=0
    if [ -f "$ROLLBACK_MOVE_COUNT_FILE" ]; then
      candidate_move_count="$(cat "$ROLLBACK_MOVE_COUNT_FILE")"
    fi
    candidate_move_count=$((candidate_move_count + 1))
    printf '%s\n' "$candidate_move_count" > "$ROLLBACK_MOVE_COUNT_FILE"
    if [ "$candidate_move_count" -eq 2 ]; then
      "$REAL_RM" -f "$ROLLBACK_REPLACEMENT_PATH"
      if [ "$ROLLBACK_REPLACEMENT_KIND" = regular ]; then
        printf '%s\n' "$ROLLBACK_FOREIGN_CONTENT" \
          > "$ROLLBACK_REPLACEMENT_PATH"
      else
        "$REAL_LN" -s \
          "$ROLLBACK_FOREIGN_REFERENT" \
          "$ROLLBACK_REPLACEMENT_PATH"
      fi
      exit 74
    fi
    ;;
esac

exec "$REAL_MV" "$@"
EOF
chmod +x "$rollback_replacement_bin/mv"

for original_state in preexisting absent; do
  for replacement_kind in regular symlink; do
    replacement_case="$original_state-$replacement_kind"
    rollback_project="$TEST_ROOT/rollback-replacement-$replacement_case"
    rollback_state="$TEST_ROOT/rollback-state-$replacement_case"
    rollback_referent="$TEST_ROOT/rollback-referent-$replacement_case"
    rollback_foreign_content="foreign $replacement_case candidate"
    mkdir -p \
      "$rollback_project/.agents/templates/local" \
      "$rollback_state"
    printf '%s\n' "unrelated $replacement_case content" \
      > "$rollback_project/.agents/templates/local/project-owned.md"
    if [ "$original_state" = preexisting ]; then
      for document in AGENTS ARCHITECTURE CONTRIBUTING DESIGN README; do
        printf '%s prior %s candidate\n' "$document" "$replacement_case" \
          > "$rollback_project/.agents/templates/$document.md"
      done
    fi
    printf '%s\n' "referent $replacement_case data" > "$rollback_referent"

    rollback_status=0
    REAL_MV="$real_mv" \
    REAL_RM="$real_rm" \
    REAL_LN="$real_ln" \
    ROLLBACK_MOVE_COUNT_FILE="$rollback_state/move-count" \
    ROLLBACK_REPLACEMENT_PATH="$rollback_project/.agents/templates/AGENTS.md" \
    ROLLBACK_REPLACEMENT_KIND="$replacement_kind" \
    ROLLBACK_FOREIGN_CONTENT="$rollback_foreign_content" \
    ROLLBACK_FOREIGN_REFERENT="$rollback_referent" \
    PATH="$rollback_replacement_bin:$PATH" \
    bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
      "$source_root" "$rollback_project" \
        >"$TEST_ROOT/rollback-replacement-$replacement_case.out" 2>&1 \
      || rollback_status="$?"
    if [ "$rollback_status" -eq 0 ]; then
      echo "Template staging ignored $replacement_case rollback failure" >&2
      exit 1
    fi

    if [ "$replacement_kind" = regular ]; then
      if [ -L "$rollback_project/.agents/templates/AGENTS.md" ] \
        || ! grep -qx "$rollback_foreign_content" \
          "$rollback_project/.agents/templates/AGENTS.md"; then
        echo "Template rollback clobbered a foreign regular $original_state replacement" >&2
        exit 1
      fi
    elif [ ! -L "$rollback_project/.agents/templates/AGENTS.md" ] \
      || [ "$(readlink "$rollback_project/.agents/templates/AGENTS.md")" != "$rollback_referent" ]; then
      echo "Template rollback clobbered a foreign symlink $original_state replacement" >&2
      exit 1
    else
      grep -qx "referent $replacement_case data" "$rollback_referent"
    fi

    rollback_recovery_dir="$(find "$rollback_project/.agents" -maxdepth 1 \
      -type d -name '.template-stage.??????' -print -quit)"
    if [ -z "$rollback_recovery_dir" ]; then
      echo "Template rollback discarded $replacement_case recovery data" >&2
      exit 1
    fi
    if [ "$original_state" = preexisting ]; then
      grep -qx "AGENTS prior $replacement_case candidate" \
        "$rollback_recovery_dir/previous-candidates/AGENTS.md"
    fi
    cmp -s \
      "$source_root/project-templates/base/README.md" \
      "$rollback_recovery_dir/README.md"
    grep -qx "unrelated $replacement_case content" \
      "$rollback_project/.agents/templates/local/project-owned.md"
    [ ! -e "$rollback_project/.agents/.template-stage.lock" ]
    [ ! -L "$rollback_project/.agents/.template-stage.lock" ]
  done
done

symlink_source="$TEST_ROOT/symlink-source"
symlink_project="$TEST_ROOT/symlink-project"
mkdir -p "$symlink_source" "$symlink_project"
ln -s "$source_root/project-templates" \
  "$symlink_source/project-templates"

if bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$symlink_source" \
  "$symlink_project" >/dev/null 2>&1; then
  echo "Template staging accepted a symlinked source directory" >&2
  exit 1
fi

[ ! -e "$symlink_project/.agents" ]

echo "Project template source-layout tests passed"
