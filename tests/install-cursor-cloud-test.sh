#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${INSTALLER_UNDER_TEST:-$REPO_ROOT/scripts/install-cursor-cloud.sh}"
CANONICAL_URL="https://github.com/marcus-friction/agents.git"
TEST_ROOT="$(mktemp -d)"
SYSTEM_PATH="$PATH"
REAL_MKDIR="$(command -p -v mkdir)"
REAL_STAT="$(command -p -v stat)"
REAL_GIT="$(command -v git)"
REAL_LN="$(command -p -v ln)"
REAL_MV="$(command -p -v mv)"
REAL_FIND="$(command -p -v find)"
REAL_MKTEMP="$(command -p -v mktemp)"
REAL_RM="$(command -p -v rm)"
REAL_RMDIR="$(command -p -v rmdir)"
GUARD_BIN="$TEST_ROOT/guard-bin"
FAULT_REGISTRAR="$TEST_ROOT/fault-register-skills.sh"
MV_FAULT_BIN="$TEST_ROOT/mv-fault-bin"
LINK_FAULT_BIN="$TEST_ROOT/link-fault-bin"
LOCK_SIGNAL_BIN="$TEST_ROOT/lock-signal-bin"
STAGE_SIGNAL_BIN="$TEST_ROOT/stage-signal-bin"
PARENT_RACE_BIN="$TEST_ROOT/parent-race-bin"
STAGE_CLEANUP_BIN="$TEST_ROOT/stage-cleanup-bin"
FINALIZE_FAULT_BIN="$TEST_ROOT/finalize-fault-bin"
DISCOVERY_OWNER_BIN="$TEST_ROOT/discovery-owner-bin"
ACTIVE_PIDS=()
failures=0
attempted=0
completed=0
EXPECTED_TESTS=61

cleanup() {
  local pid
  for pid in "${ACTIVE_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$GUARD_BIN"
cat > "$GUARD_BIN/mkdir" <<'EOF'
#!/usr/bin/env bash
for argument in "$@"; do
  if [ "$argument" = "/opt/agent-ecosystem" ]; then
    exit 1
  fi
done
exec "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$@"
EOF
chmod +x "$GUARD_BIN/mkdir"

cat > "$GUARD_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
args=("$@")
credential_reset=0
canonical_remote=0
for index in "${!args[@]}"; do
  if [ "${args[$index]}" = "-c" ]; then
    case "${args[$((index + 1))]:-}" in
      credential.helper=)
        credential_reset=1
        ;;
    esac
  elif [ "${args[$index]}" = "https://github.com/marcus-friction/agents.git" ]; then
    canonical_remote=1
  fi
done
if [ "$canonical_remote" -eq 1 ] \
  && [ "$credential_reset" -ne 1 ]; then
  echo "public GitHub fetch did not clear ambient credential helpers" >&2
  exit 97
fi
if [ "$canonical_remote" -eq 1 ] \
  && { [ "${GIT_ASKPASS:-}" != /usr/bin/false ] \
    || [ "${SSH_ASKPASS:-}" != /usr/bin/false ] \
    || [ "${SSH_ASKPASS_REQUIRE:-}" != never ]; }; then
  echo "public GitHub fetch permits an ambient askpass fallback" >&2
  exit 96
fi
exec env GIT_ALLOW_PROTOCOL=file "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" \
  -c "url.file://$AGENTS_ECOSYSTEM_TEST_TRANSPORT_ROOT/.insteadOf=https://github.com/" \
  "${args[@]}"
EOF
chmod +x "$GUARD_BIN/git"
mkdir -p \
  "$MV_FAULT_BIN" \
  "$LINK_FAULT_BIN" \
  "$LOCK_SIGNAL_BIN" \
  "$STAGE_SIGNAL_BIN" \
  "$PARENT_RACE_BIN" \
  "$STAGE_CLEANUP_BIN" \
  "$FINALIZE_FAULT_BIN" \
  "$DISCOVERY_OWNER_BIN"
cat > "$MV_FAULT_BIN/mv" <<'EOF'
#!/usr/bin/env bash
source_path="${@: -2:1}"
target_path="${@: -1}"
transition=""
source_name="${source_path##*/}"
target_name="${target_path##*/}"
dest_name="${AGENTS_ECOSYSTEM_TEST_DEST##*/}"
if { [ "$source_path" = "$AGENTS_ECOSYSTEM_TEST_DEST" ] \
    || [ "$source_name" = "$dest_name" ]; } \
  && [ "$target_name" = prior ]; then
  transition="old"
elif [ "$source_name" = candidate ] \
  && { [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_DEST" ] \
    || [ "$target_name" = "$dest_name" ]; }; then
  transition="new"
fi

case "${AGENTS_ECOSYSTEM_TEST_MV_MODE:-}:$transition" in
  signal-before-old:old|signal-before-new:new)
    kill -TERM "${AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID:-$PPID}"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  signal-after-old:old|signal-after-new:new)
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@" || exit "$?"
    kill -TERM "${AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID:-$PPID}"
    exit 0
    ;;
  fail-old:old|fail-new:new)
    exit 71
    ;;
  inject-untracked-before-old:old)
    printf 'concurrent local work\n' > "$source_path/concurrent-local.txt"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  record-old-move:old)
    : > "$AGENTS_ECOSYSTEM_TEST_OLD_MOVE_MARKER"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  swap-parent-at-old-move:old)
    printf '%s\n%s\n' "$source_path" "$target_path" \
      > "$AGENTS_ECOSYSTEM_TEST_MOVE_PATH_RECORD"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
      "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT" \
      "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT.concurrent-original" || exit "$?"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" -p -- "$AGENTS_ECOSYSTEM_TEST_DEST"
    printf 'visible concurrent destination\n' \
      > "$AGENTS_ECOSYSTEM_TEST_DEST/concurrent-owner.txt"
    "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" -c '%d:%i:%u' -- "$AGENTS_ECOSYSTEM_TEST_DEST" \
      > "$AGENTS_ECOSYSTEM_TEST_CONCURRENT_DEST_ID_RECORD"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  external-before-old:old)
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
      "$AGENTS_ECOSYSTEM_TEST_DEST" "$AGENTS_ECOSYSTEM_TEST_DEST.external-original" || exit "$?"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$AGENTS_ECOSYSTEM_TEST_DEST"
    printf 'external owner\n' > "$AGENTS_ECOSYSTEM_TEST_DEST/external-owner.txt"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  external-after-old:old)
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@" || exit "$?"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$AGENTS_ECOSYSTEM_TEST_DEST"
    printf 'external owner\n' > "$AGENTS_ECOSYSTEM_TEST_DEST/external-owner.txt"
    exit 0
    ;;
  discovery-create-before-old:old)
    "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT"
    printf 'concurrent parent\n' > "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  discovery-replace-before-old:old)
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
      "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT" \
      "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT.concurrent-original" || exit "$?"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT"
    printf 'concurrent replacement\n' > "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  discovery-owner-change-before-old:old)
    printf 'owner changed\n' > "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER"
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
  *)
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
    ;;
esac
EOF
chmod +x "$MV_FAULT_BIN/mv"

cat > "$LINK_FAULT_BIN/ln" <<'EOF'
#!/usr/bin/env bash
source_path="${@: -2:1}"
target_path="${@: -1}"

if [[ "$source_path" != */.agents/skills ]]; then
  exec "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
fi

count=0
if [ -f "$AGENTS_ECOSYSTEM_TEST_LINK_COUNT" ]; then
  read -r count < "$AGENTS_ECOSYSTEM_TEST_LINK_COUNT"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$AGENTS_ECOSYSTEM_TEST_LINK_COUNT"

case "${AGENTS_ECOSYSTEM_TEST_LINK_MODE:-}" in
  wait-before-first)
    if [ "$count" -eq 1 ]; then
      : > "$AGENTS_ECOSYSTEM_TEST_READY"
      attempts=0
      while [ ! -e "$AGENTS_ECOSYSTEM_TEST_RELEASE" ]; do
        attempts=$((attempts + 1))
        if [ "$attempts" -gt 200 ]; then
          exit 70
        fi
        sleep 0.05
      done
    fi
    ;;
  interrupt-after-first)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 1 ]; then
      kill -TERM "$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID"
      exit 143
    fi
    exit 0
    ;;
  interrupt-after-second)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 2 ]; then
      kill -TERM "$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID"
    fi
    exit 0
    ;;
  add-private-and-interrupt-after-second)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 2 ]; then
      printf 'concurrent private metadata\n' \
        > "$AGENTS_ECOSYSTEM_TEST_DEST/.git/private-note"
      "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" -c '%d:%i:%u' -- \
        "$AGENTS_ECOSYSTEM_TEST_DEST/.git/private-note" \
        > "$AGENTS_ECOSYSTEM_TEST_PRIVATE_NOTE_ID_RECORD"
      kill -TERM "$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID"
    fi
    exit 0
    ;;
  fail-after-first)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 1 ]; then
      exit 42
    fi
    exit 0
    ;;
  fail-second)
    if [ "$count" -eq 2 ]; then
      exit 42
    fi
    ;;
  recovery-failure-after-first)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 1 ]; then
      "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
        "$AGENTS_ECOSYSTEM_TEST_DEST" "$AGENTS_ECOSYSTEM_TEST_DEST.displaced" || exit "$?"
      "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" -- "$AGENTS_ECOSYSTEM_TEST_DEST" || exit "$?"
      printf 'concurrent owner\n' > "$AGENTS_ECOSYSTEM_TEST_DEST/concurrent-owner.txt"
      exit 43
    fi
    exit 0
    ;;
  rename-stage-after-second)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 2 ]; then
      for stage_path in "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT/.${AGENTS_ECOSYSTEM_TEST_DEST##*/}.stage."*; do
        [ -d "$stage_path" ] || continue
        renamed_stage="$stage_path.concurrent-renamed"
        "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- "$stage_path" "$renamed_stage" \
          || exit "$?"
        printf '%s\n' "$renamed_stage" > "$AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD"
        break
      done
      [ -s "$AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD" ] || exit 72
    fi
    exit 0
    ;;
  add-stage-entry-after-second)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 2 ]; then
      for stage_path in "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT/.${AGENTS_ECOSYSTEM_TEST_DEST##*/}.stage."*; do
        [ -d "$stage_path" ] || continue
        printf 'concurrent stage entry\n' > "$stage_path/concurrent-owner.txt"
        printf '%s\n' "$stage_path" > "$AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD"
        break
      done
      [ -s "$AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD" ] || exit 73
    fi
    exit 0
    ;;
  replace-leaf-after-first)
    "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@" || exit "$?"
    if [ "$count" -eq 1 ]; then
      "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
        "$target_path" "$AGENTS_ECOSYSTEM_TEST_DISPLACED_DISCOVERY_LINK" || exit "$?"
      "$AGENTS_ECOSYSTEM_TEST_REAL_LN" -s -- "$source_path" "$target_path" || exit "$?"
      "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" -c '%d:%i:%u' -- "$target_path" \
        > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_ID_RECORD"
      exit 44
    fi
    exit 0
    ;;
esac

exec "$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
EOF
chmod +x "$LINK_FAULT_BIN/ln"

cat > "$LOCK_SIGNAL_BIN/mkdir" <<'EOF'
#!/usr/bin/env bash
last="${@: -1}"
if [[ "$last" == *.install.lock ]]; then
  "$AGENTS_ECOSYSTEM_TEST_NEXT_MKDIR" "$@" || exit "$?"
  kill -TERM "${AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID:-$PPID}"
  exit 0
fi
exec "$AGENTS_ECOSYSTEM_TEST_NEXT_MKDIR" "$@"
EOF
chmod +x "$LOCK_SIGNAL_BIN/mkdir"

cat > "$STAGE_SIGNAL_BIN/mktemp" <<'EOF'
#!/usr/bin/env bash
created="$($AGENTS_ECOSYSTEM_TEST_REAL_MKTEMP "$@")" || exit "$?"
printf '%s\n' "$created" > "$AGENTS_ECOSYSTEM_TEST_STAGE_RECORD"
kill -TERM "${AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID:-$PPID}"
printf '%s\n' "$created"
EOF
chmod +x "$STAGE_SIGNAL_BIN/mktemp"

cat > "$PARENT_RACE_BIN/mkdir" <<'EOF'
#!/usr/bin/env bash
last="${@: -1}"
if [[ "$last" == *.install.lock ]] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_PARENT_RACE_MARKER" ]; then
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
    "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT" "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT.concurrent-original" \
    || exit "$?"
  "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$AGENTS_ECOSYSTEM_TEST_DEST_PARENT" || exit "$?"
  printf 'concurrent parent\n' > "$AGENTS_ECOSYSTEM_TEST_PARENT_RACE_MARKER"
fi
exec "$AGENTS_ECOSYSTEM_TEST_NEXT_MKDIR" "$@"
EOF
chmod +x "$PARENT_RACE_BIN/mkdir"

cat > "$STAGE_CLEANUP_BIN/rm" <<'EOF'
#!/usr/bin/env bash
last="${@: -1}"
if [ "${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" = mark-prior-delete ] \
  && { [ "${last##*/}" = prior ] || [[ "$last" == */prior/* ]]; }; then
  : > "$AGENTS_ECOSYSTEM_TEST_PRIOR_CLEANUP_MARKER"
  exit 77
fi
if [[ "$last" == *"/.cloud-checkout.stage."* ]]; then
  case "${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" in
    fail)
      exit 77
      ;;
    replace)
      stage_path="${last%/*}"
      "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
        "$stage_path" "$stage_path.concurrent-original" || exit "$?"
      "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$stage_path"
      printf 'replacement sentinel\n' > "$stage_path/concurrent-owner.txt"
      : > "$AGENTS_ECOSYSTEM_TEST_RACE_INJECTED"
      exec "$AGENTS_ECOSYSTEM_TEST_REAL_RM" "$@"
      ;;
  esac
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_RM" "$@"
EOF
chmod +x "$STAGE_CLEANUP_BIN/rm"

cat > "$STAGE_CLEANUP_BIN/find" <<'EOF'
#!/usr/bin/env bash
stage_path="$PWD"
if [ "${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" \
    = rename-stage-on-third-prior-validation ] \
  && [ "${1##*/}" = prior ]; then
  count=0
  if [ -f "$AGENTS_ECOSYSTEM_TEST_STAGE_FIND_COUNT" ]; then
    read -r count < "$AGENTS_ECOSYSTEM_TEST_STAGE_FIND_COUNT"
  fi
  count=$((count + 1))
  printf '%s\n' "$count" > "$AGENTS_ECOSYSTEM_TEST_STAGE_FIND_COUNT"
  if [ "$count" -eq 3 ]; then
    stage_path="${1%/prior}"
    renamed_stage="$stage_path.concurrent-renamed"
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- "$stage_path" "$renamed_stage" \
      || exit "$?"
    printf '%s\n' "$renamed_stage" \
      > "$AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD"
  fi
fi
if [ "${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" = mark-prior-delete ] \
  && [ "${stage_path##*/}" = prior ]; then
  for argument in "$@"; do
    if [ "$argument" = -delete ]; then
      : > "$AGENTS_ECOSYSTEM_TEST_PRIOR_CLEANUP_MARKER"
      exit 77
    fi
  done
fi
if [[ "$stage_path" == */.cloud-checkout.stage.* ]] \
  || [ "${stage_path##*/}" = candidate ] \
  || [ "${stage_path##*/}" = failed-candidate ]; then
  case "${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" in
    fail)
      exit 77
      ;;
    replace)
      "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
        "$stage_path" "$stage_path.concurrent-original" || exit "$?"
      "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$stage_path"
      printf 'replacement sentinel\n' > "$stage_path/concurrent-owner.txt"
      : > "$AGENTS_ECOSYSTEM_TEST_RACE_INJECTED"
      exec "$AGENTS_ECOSYSTEM_TEST_REAL_FIND" "$@"
      ;;
  esac
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_FIND" "$@"
EOF
chmod +x "$STAGE_CLEANUP_BIN/find"

cat > "$STAGE_CLEANUP_BIN/rmdir" <<'EOF'
#!/usr/bin/env bash
last="${@: -1}"
if [ "${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" = replace-public-at-rmdir ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_RACE_INJECTED" ]; then
  public_path="$last"
  if [[ "$public_path" == *.retire.* ]]; then
    public_path="${public_path%%.retire.*}"
  else
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
      "$public_path" "$public_path.concurrent-original" || exit "$?"
  fi
  "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" -- "$public_path" || exit "$?"
  public_parent="$(cd -- "$(dirname -- "$public_path")" && pwd -P)" \
    || exit "$?"
  public_physical="$public_parent/$(basename -- "$public_path")"
  printf '%s\n' "$public_physical" \
    > "$AGENTS_ECOSYSTEM_TEST_RMDIR_REPLACEMENT_PATH_RECORD"
  "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" -c '%d:%i:%u' -- "$public_path" \
    > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_ID_RECORD"
  : > "$AGENTS_ECOSYSTEM_TEST_RACE_INJECTED"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_RMDIR" "$@"
EOF
chmod +x "$STAGE_CLEANUP_BIN/rmdir"

cat > "$FINALIZE_FAULT_BIN/rmdir" <<'EOF'
#!/usr/bin/env bash
last="${@: -1}"
if [ "${AGENTS_ECOSYSTEM_TEST_FINALIZE_MODE:-}" = replace-public-lock ]; then
  public_lock="$AGENTS_ECOSYSTEM_TEST_LOCK_PATH"
  public_base="${public_lock##*/}"
  last_base="${last##*/}"
  if [ "$last_base" = "$public_base" ]; then
    "$AGENTS_ECOSYSTEM_TEST_REAL_MV" -Tn -- \
      "$public_lock" "$public_lock.concurrent-original" || exit "$?"
  elif [[ "$last_base" != "$public_base".release.* ]]; then
    exec "$AGENTS_ECOSYSTEM_TEST_REAL_RMDIR" "$@"
  fi
  "$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" -- "$public_lock" || exit "$?"
  "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" -c '%d:%i:%u' -- "$public_lock" \
    > "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_ID_RECORD"
  exec "$AGENTS_ECOSYSTEM_TEST_REAL_RMDIR" "$@"
fi
if { [[ "$last" == *.install.lock ]] \
    || [[ "$last" == *.install.lock.release.* ]]; } \
  && [ "${AGENTS_ECOSYSTEM_TEST_FINALIZE_MODE:-}" = "release-fail" ]; then
  exit 78
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_RMDIR" "$@"
EOF
chmod +x "$FINALIZE_FAULT_BIN/rmdir"

cat > "$DISCOVERY_OWNER_BIN/stat" <<'EOF'
#!/usr/bin/env bash
last="${!#}"
if [ "$last" = "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_TARGET" ] \
  && [ -e "$AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_MARKER" ] \
  && [ "$1" = "-c" ] \
  && [ "$2" = "%u" ]; then
  printf '%s\n' "$AGENTS_ECOSYSTEM_TEST_WRONG_UID"
  exit 0
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" "$@"
EOF
chmod +x "$DISCOVERY_OWNER_BIN/stat"

cat > "$FAULT_REGISTRAR" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ -n "${AGENTS_ECOSYSTEM_TEST_REGISTRAR_EXECUTION_MARKER:-}" ]; then
  printf 'checkout registrar executed: %s\n' "$0" \
    > "$AGENTS_ECOSYSTEM_TEST_REGISTRAR_EXECUTION_MARKER"
  exit 97
fi

source_path=""
preflight_only=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --source)
      source_path="$2"
      shift 2
      ;;
    --preflight-only)
      preflight_only=1
      shift
      ;;
    --scope|--adapters|--project-root)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

[ -n "$source_path" ]
if [ "$preflight_only" -eq 1 ]; then
  exit 0
fi

create_link() {
  local parent="$1"
  mkdir -p "$parent"
  if [ -L "$parent/skills" ]; then
    [ "$(readlink "$parent/skills")" = "$source_path" ]
  elif [ -e "$parent/skills" ]; then
    return 1
  else
    ln -s "$source_path" "$parent/skills"
  fi
}

case "${AGENTS_ECOSYSTEM_TEST_REGISTRAR_MODE:-success}" in
  partial)
    create_link "$HOME/.agents"
    exit 42
    ;;
  interrupt)
    create_link "$HOME/.agents"
    kill -TERM "$PPID"
    exit 143
    ;;
  wait)
    if [ "${AGENTS_ECOSYSTEM_TEST_REGISTRAR_ROLE:-first}" = "first" ]; then
      : > "$AGENTS_ECOSYSTEM_TEST_READY"
      count=0
      while [ ! -e "$AGENTS_ECOSYSTEM_TEST_RELEASE" ]; do
        count=$((count + 1))
        if [ "$count" -gt 200 ]; then
          exit 70
        fi
        sleep 0.05
      done
    fi
    create_link "$HOME/.agents"
    create_link "$HOME/.cursor"
    ;;
  recovery-failure)
    create_link "$HOME/.agents"
    destination="${source_path%/.agents/skills}"
    mv "$destination" "$destination.displaced"
    mkdir "$destination"
    printf 'concurrent owner\n' > "$destination/concurrent-owner.txt"
    exit 43
    ;;
  rename-stage-before-finish)
    create_link "$HOME/.agents"
    create_link "$HOME/.cursor"
    destination="${source_path%/.agents/skills}"
    destination_parent="$(dirname -- "$destination")"
    destination_base="$(basename -- "$destination")"
    for stage_path in "$destination_parent/.${destination_base}.stage."*; do
      [ -d "$stage_path" ] || continue
      renamed_stage="$stage_path.concurrent-renamed"
      mv -Tn -- "$stage_path" "$renamed_stage" || exit "$?"
      printf '%s\n' "$renamed_stage" > "$AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD"
      break
    done
    [ -s "$AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD" ]
    ;;
  add-stage-entry-before-finish)
    create_link "$HOME/.agents"
    create_link "$HOME/.cursor"
    destination="${source_path%/.agents/skills}"
    destination_parent="$(dirname -- "$destination")"
    destination_base="$(basename -- "$destination")"
    for stage_path in "$destination_parent/.${destination_base}.stage."*; do
      [ -d "$stage_path" ] || continue
      printf 'concurrent stage entry\n' > "$stage_path/concurrent-owner.txt"
      printf '%s\n' "$stage_path" > "$AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD"
      break
    done
    [ -s "$AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD" ]
    ;;
  *)
    create_link "$HOME/.agents"
    create_link "$HOME/.cursor"
    ;;
esac
EOF
chmod +x "$FAULT_REGISTRAR"

run_test() {
  local name="$1"
  shift

  attempted=$((attempted + 1))
  if ("$@"); then
    echo "ok - $name"
  else
    echo "not ok - $name"
    failures=$((failures + 1))
  fi
  completed=$((completed + 1))
}

fixture_git() {
  env \
    -u GIT_DIR \
    -u GIT_WORK_TREE \
    -u GIT_INDEX_FILE \
    -u GIT_OBJECT_DIRECTORY \
    -u GIT_ALTERNATE_OBJECT_DIRECTORIES \
    -u GIT_COMMON_DIR \
    -u GIT_CONFIG_COUNT \
    -u GIT_CONFIG_PARAMETERS \
    -u GIT_CONFIG_SYSTEM \
    -u GIT_CONFIG_GLOBAL \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    GIT_ALLOW_PROTOCOL=file \
      "$REAL_GIT" "$@"
}

assert_absent() {
  local path="$1"
  [ ! -e "$path" ] && [ ! -L "$path" ]
}

assert_link() {
  local path="$1"
  local expected="$2"
  [ -L "$path" ] && [ "$(readlink "$path")" = "$expected" ]
}

discovery_entry_snapshot() {
  local path="$1"

  if [ -L "$path" ]; then
    printf 'symlink:%s:%s\n' \
      "$(stat -c '%a:%u:%g:%d:%i:%h' -- "$path")" \
      "$(readlink -- "$path")"
  elif [ -e "$path" ]; then
    printf 'other:%s\n' "$(stat -c '%F:%a:%u:%g:%d:%i:%h' -- "$path")"
  else
    printf 'absent\n'
  fi
}

assert_old_checkout() {
  grep -qx 'old skill' "$CASE_DEST/.agents/skills/example/SKILL.md"
}

assert_new_checkout() {
  grep -qx 'new skill' "$CASE_DEST/.agents/skills/example/SKILL.md"
}

assert_no_transaction_artifacts() {
  local parent
  local base
  parent="$(dirname "$CASE_DEST")"
  base="$(basename "$CASE_DEST")"
  [ ! -e "$parent/.${base}.install.lock" ] \
    && [ -z "$(find "$parent" -maxdepth 1 -name ".${base}.stage.*" -print -quit)" ]
}

snapshot_checkout_tree() {
  local checkout="$1"
  local snapshot="$2"

  [ -d "$checkout" ] && [ ! -L "$checkout" ] || return 1
  (
    set -o pipefail
    cd -- "$checkout" || exit 1
    find . -xdev -print0 \
      | LC_ALL=C sort -z \
      | while IFS= read -r -d '' entry; do
          metadata="$(stat -c '%a:%u:%g:%d:%i:%h' -- "$entry")" || exit 1
          if [ -L "$entry" ]; then
            target="$(readlink -- "$entry")" || exit 1
            printf 'symlink\0%s\0%s\0%s\0' "$entry" "$metadata" "$target"
          elif [ -d "$entry" ]; then
            printf 'directory\0%s\0%s\0' "$entry" "$metadata"
          elif [ -f "$entry" ]; then
            digest="$(sha256sum -- "$entry")" || exit 1
            digest="${digest%% *}"
            size="$(stat -c '%s' -- "$entry")" || exit 1
            printf 'file\0%s\0%s\0%s\0%s\0' \
              "$entry" "$metadata" "$size" "$digest"
          else
            kind="$(stat -c '%F:%t:%T' -- "$entry")" || exit 1
            printf 'special\0%s\0%s\0%s\0' "$entry" "$metadata" "$kind"
          fi
        done
  ) > "$snapshot"
}

assert_checkout_tree_matches_snapshot() {
  local checkout="$1"
  local expected_snapshot="$2"
  local actual_snapshot

  actual_snapshot="$($REAL_MKTEMP "$TEST_ROOT/checkout-snapshot.XXXXXX")" \
    || return 1
  if ! snapshot_checkout_tree "$checkout" "$actual_snapshot"; then
    "$REAL_RM" -f -- "$actual_snapshot"
    return 1
  fi
  if ! cmp -s -- "$expected_snapshot" "$actual_snapshot"; then
    echo "checkout tree changed: $checkout" >&2
    "$REAL_RM" -f -- "$actual_snapshot"
    return 1
  fi
  "$REAL_RM" -f -- "$actual_snapshot"
}

find_single_retained_prior() {
  local allow_lock="${1:-0}"
  local parent
  local base
  local stage
  local priors=()
  local entries=()

  parent="$(dirname -- "$CASE_DEST")"
  base="$(basename -- "$CASE_DEST")"
  mapfile -t priors < <(
    find "$parent" -mindepth 2 -maxdepth 2 \
      -path "$parent/.${base}.stage.*/prior" -type d -print \
      | LC_ALL=C sort
  )
  if [ "${#priors[@]}" -ne 1 ]; then
    echo "expected one retained prior for $CASE_DEST; found ${#priors[@]}" >&2
    return 1
  fi
  stage="$(dirname -- "${priors[0]}")"
  mapfile -t entries < <(find "$stage" -mindepth 1 -maxdepth 1 -print)
  if [ "${#entries[@]}" -ne 1 ] || [ "${entries[0]}" != "${priors[0]}" ]; then
    echo "retained stage contains material other than its prior: $stage" >&2
    return 1
  fi
  if [ "$allow_lock" -ne 1 ]; then
    [ ! -e "$parent/.${base}.install.lock" ] || return 1
  fi
  printf '%s\n' "${priors[0]}"
}

write_real_registrar() {
  local source_root="$1"
  mkdir -p "$source_root/scripts/skill-adapters"
  cp "$REPO_ROOT/scripts/register-skills.sh" "$source_root/scripts/register-skills.sh"
  cp "$REPO_ROOT/scripts/skill-adapters/agents.sh" \
    "$source_root/scripts/skill-adapters/agents.sh"
  cp "$REPO_ROOT/scripts/skill-adapters/cursor.sh" \
    "$source_root/scripts/skill-adapters/cursor.sh"
}

prepare_case() {
  local case_root="$1"

  CASE_ROOT="$case_root"
  CASE_HOME="$case_root/home"
  CASE_DEST="$case_root/cloud-checkout"
  CASE_TRANSPORT_ROOT="$case_root/transport"
  CASE_REMOTE="$CASE_TRANSPORT_ROOT/marcus-friction/agents.git"
  CASE_SOURCE="$case_root/source"
  CASE_GIT_CONFIG="$case_root/gitconfig"

  mkdir -p \
    "$CASE_HOME" \
    "$CASE_SOURCE/.agents/skills/example" \
    "$(dirname "$CASE_REMOTE")"
  : > "$CASE_GIT_CONFIG"
  fixture_git init -q --bare "$CASE_REMOTE"
  fixture_git -C "$CASE_SOURCE" init -q
  fixture_git -C "$CASE_SOURCE" branch -M master
  fixture_git -C "$CASE_SOURCE" config user.name "Cloud Installer Test"
  fixture_git -C "$CASE_SOURCE" config user.email "cloud-installer@example.invalid"
  printf 'old skill\n' > "$CASE_SOURCE/.agents/skills/example/SKILL.md"
  write_real_registrar "$CASE_SOURCE"
  fixture_git -C "$CASE_SOURCE" add .
  fixture_git -C "$CASE_SOURCE" commit -qm "old fixture"
  fixture_git -C "$CASE_SOURCE" remote add origin "$CASE_REMOTE"
  fixture_git -C "$CASE_SOURCE" push -q -u origin master
  fixture_git --git-dir="$CASE_REMOTE" symbolic-ref HEAD refs/heads/master
}

clone_old_checkout() {
  fixture_git clone -q "file://$CASE_REMOTE" "$CASE_DEST"
  fixture_git -C "$CASE_DEST" remote set-url origin "$CANONICAL_URL"
  [ "$(fixture_git -C "$CASE_DEST" config --get remote.origin.url)" = "$CANONICAL_URL" ]
}

publish_candidate() {
  local registrar_kind="${1:-real}"

  printf 'new skill\n' > "$CASE_SOURCE/.agents/skills/example/SKILL.md"
  case "$registrar_kind" in
    real)
      write_real_registrar "$CASE_SOURCE"
      ;;
    fault)
      mkdir -p "$CASE_SOURCE/scripts"
      cp "$FAULT_REGISTRAR" "$CASE_SOURCE/scripts/register-skills.sh"
      rm -rf "$CASE_SOURCE/scripts/skill-adapters"
      ;;
    missing)
      rm -rf "$CASE_SOURCE/scripts"
      ;;
    *)
      return 1
      ;;
  esac
  fixture_git -C "$CASE_SOURCE" add -A
  fixture_git -C "$CASE_SOURCE" commit -qm "candidate fixture"
  fixture_git -C "$CASE_SOURCE" push -q origin master
}

run_cloud_installer() {
  local extra_path="${AGENTS_ECOSYSTEM_TEST_EXTRA_PATH:-}"
  local effective_path="$GUARD_BIN:$SYSTEM_PATH"
  if [ -n "$extra_path" ]; then
    effective_path="$extra_path:$effective_path"
  fi

  env \
    HOME="$CASE_HOME" \
    AGENTS_ECOSYSTEM_HOME="$CASE_DEST" \
    GIT_CONFIG_GLOBAL="$CASE_GIT_CONFIG" \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_ALLOW_PROTOCOL=file \
    PATH="$effective_path" \
    AGENTS_ECOSYSTEM_TEST_REAL_MKDIR="$REAL_MKDIR" \
    AGENTS_ECOSYSTEM_TEST_REGISTRAR_MODE="${AGENTS_ECOSYSTEM_TEST_REGISTRAR_MODE:-success}" \
    AGENTS_ECOSYSTEM_TEST_REGISTRAR_ROLE="${AGENTS_ECOSYSTEM_TEST_REGISTRAR_ROLE:-first}" \
    AGENTS_ECOSYSTEM_TEST_READY="${AGENTS_ECOSYSTEM_TEST_READY:-$CASE_ROOT/ready}" \
    AGENTS_ECOSYSTEM_TEST_RELEASE="${AGENTS_ECOSYSTEM_TEST_RELEASE:-$CASE_ROOT/release}" \
    AGENTS_ECOSYSTEM_TEST_OWNER_TARGET="${AGENTS_ECOSYSTEM_TEST_OWNER_TARGET:-}" \
    AGENTS_ECOSYSTEM_TEST_WRONG_UID="${AGENTS_ECOSYSTEM_TEST_WRONG_UID:-}" \
    AGENTS_ECOSYSTEM_TEST_REAL_STAT="${AGENTS_ECOSYSTEM_TEST_REAL_STAT:-$REAL_STAT}" \
    AGENTS_ECOSYSTEM_TEST_REAL_GIT="${AGENTS_ECOSYSTEM_TEST_REAL_GIT:-$REAL_GIT}" \
    AGENTS_ECOSYSTEM_TEST_REAL_LN="${AGENTS_ECOSYSTEM_TEST_REAL_LN:-$REAL_LN}" \
    AGENTS_ECOSYSTEM_TEST_REAL_MV="${AGENTS_ECOSYSTEM_TEST_REAL_MV:-$REAL_MV}" \
    AGENTS_ECOSYSTEM_TEST_REAL_FIND="${AGENTS_ECOSYSTEM_TEST_REAL_FIND:-$REAL_FIND}" \
    AGENTS_ECOSYSTEM_TEST_REAL_MKTEMP="${AGENTS_ECOSYSTEM_TEST_REAL_MKTEMP:-$REAL_MKTEMP}" \
    AGENTS_ECOSYSTEM_TEST_REAL_RM="${AGENTS_ECOSYSTEM_TEST_REAL_RM:-$REAL_RM}" \
    AGENTS_ECOSYSTEM_TEST_REAL_RMDIR="${AGENTS_ECOSYSTEM_TEST_REAL_RMDIR:-$REAL_RMDIR}" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE="${AGENTS_ECOSYSTEM_TEST_MV_MODE:-}" \
    AGENTS_ECOSYSTEM_TEST_OLD_MOVE_MARKER="${AGENTS_ECOSYSTEM_TEST_OLD_MOVE_MARKER:-$CASE_ROOT/old-move}" \
    AGENTS_ECOSYSTEM_TEST_MOVE_PATH_RECORD="${AGENTS_ECOSYSTEM_TEST_MOVE_PATH_RECORD:-$CASE_ROOT/move-paths}" \
    AGENTS_ECOSYSTEM_TEST_CONCURRENT_DEST_ID_RECORD="${AGENTS_ECOSYSTEM_TEST_CONCURRENT_DEST_ID_RECORD:-$CASE_ROOT/concurrent-dest-id}" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE="${AGENTS_ECOSYSTEM_TEST_LINK_MODE:-}" \
    AGENTS_ECOSYSTEM_TEST_LINK_COUNT="${AGENTS_ECOSYSTEM_TEST_LINK_COUNT:-$CASE_ROOT/link-count}" \
    AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE="${AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE:-}" \
    AGENTS_ECOSYSTEM_TEST_STAGE_FIND_COUNT="${AGENTS_ECOSYSTEM_TEST_STAGE_FIND_COUNT:-$CASE_ROOT/stage-find-count}" \
    AGENTS_ECOSYSTEM_TEST_RMDIR_REPLACEMENT_PATH_RECORD="${AGENTS_ECOSYSTEM_TEST_RMDIR_REPLACEMENT_PATH_RECORD:-$CASE_ROOT/rmdir-replacement-path}" \
    AGENTS_ECOSYSTEM_TEST_PRIOR_CLEANUP_MARKER="${AGENTS_ECOSYSTEM_TEST_PRIOR_CLEANUP_MARKER:-$CASE_ROOT/prior-cleanup-attempted}" \
    AGENTS_ECOSYSTEM_TEST_FINALIZE_MODE="${AGENTS_ECOSYSTEM_TEST_FINALIZE_MODE:-}" \
    AGENTS_ECOSYSTEM_TEST_LOCK_PATH="${AGENTS_ECOSYSTEM_TEST_LOCK_PATH:-$CASE_ROOT/.cloud-checkout.install.lock}" \
    AGENTS_ECOSYSTEM_TEST_RACE_INJECTED="${AGENTS_ECOSYSTEM_TEST_RACE_INJECTED:-$CASE_ROOT/race-injected}" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT="${AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT:-$CASE_HOME/.agents}" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER="${AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER:-$CASE_HOME/.agents/concurrent-owner.txt}" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_TARGET="${AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_TARGET:-$CASE_HOME/.agents}" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_MARKER="${AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_MARKER:-$CASE_HOME/.agents/owner-changed}" \
    AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD="${AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD:-$CASE_ROOT/renamed-stage}" \
    AGENTS_ECOSYSTEM_TEST_STAGE_RECORD="${AGENTS_ECOSYSTEM_TEST_STAGE_RECORD:-$CASE_ROOT/stage-record}" \
    AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD="${AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD:-$CASE_ROOT/stage-entry-record}" \
    AGENTS_ECOSYSTEM_TEST_REGISTRAR_EXECUTION_MARKER="${AGENTS_ECOSYSTEM_TEST_REGISTRAR_EXECUTION_MARKER:-}" \
    AGENTS_ECOSYSTEM_TEST_DISPLACED_DISCOVERY_LINK="${AGENTS_ECOSYSTEM_TEST_DISPLACED_DISCOVERY_LINK:-$CASE_ROOT/displaced-installer-link}" \
    AGENTS_ECOSYSTEM_TEST_REPLACEMENT_ID_RECORD="${AGENTS_ECOSYSTEM_TEST_REPLACEMENT_ID_RECORD:-$CASE_ROOT/replacement-id}" \
    AGENTS_ECOSYSTEM_TEST_PRIVATE_NOTE_ID_RECORD="${AGENTS_ECOSYSTEM_TEST_PRIVATE_NOTE_ID_RECORD:-$CASE_ROOT/private-note-id}" \
    AGENTS_ECOSYSTEM_TEST_DEST_PARENT="${AGENTS_ECOSYSTEM_TEST_DEST_PARENT:-$(dirname -- "$CASE_DEST")}" \
    AGENTS_ECOSYSTEM_TEST_PARENT_RACE_MARKER="${AGENTS_ECOSYSTEM_TEST_PARENT_RACE_MARKER:-$(dirname -- "$CASE_DEST")/concurrent-owner.txt}" \
    AGENTS_ECOSYSTEM_TEST_DEST="$CASE_DEST" \
    AGENTS_ECOSYSTEM_TEST_NEXT_MKDIR="$GUARD_BIN/mkdir" \
    AGENTS_ECOSYSTEM_TEST_GUARD_GIT="$GUARD_BIN/git" \
    AGENTS_ECOSYSTEM_TEST_CANONICAL_URL="$CANONICAL_URL" \
    AGENTS_ECOSYSTEM_TEST_REMOTE="$CASE_REMOTE" \
    AGENTS_ECOSYSTEM_TEST_TRANSPORT_ROOT="$CASE_TRANSPORT_ROOT" \
      bash "$INSTALLER" "$@"
}

test_clean_update_is_atomic_and_idempotent() {
  local active_snapshot
  local prior
  local prior_snapshot
  prepare_case "$TEST_ROOT/success"
  clone_old_checkout || return 1
  mkdir -p "$CASE_HOME/.agents" "$CASE_HOME/.cursor"
  ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.agents/skills"
  ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.cursor/skills"
  publish_candidate real || return 1
  prior_snapshot="$CASE_ROOT/prior.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$prior_snapshot" || return 1

  run_cloud_installer >/dev/null || return 1
  grep -qx 'new skill' "$CASE_DEST/.agents/skills/example/SKILL.md" || return 1
  [ -z "$(fixture_git -C "$CASE_DEST" status --porcelain --untracked-files=all)" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" config --get remote.origin.url)" = "$CANONICAL_URL" ] || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  prior="$(find_single_retained_prior)" || return 1
  assert_checkout_tree_matches_snapshot "$prior" "$prior_snapshot" || return 1
  active_snapshot="$CASE_ROOT/active.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$active_snapshot" || return 1

  run_cloud_installer >/dev/null || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$active_snapshot" || return 1
  [ "$(find_single_retained_prior)" = "$prior" ] || return 1
  assert_checkout_tree_matches_snapshot "$prior" "$prior_snapshot"
}

test_fresh_install_creates_no_recovery_material() {
  local remote_head
  prepare_case "$TEST_ROOT/fresh-install"
  publish_candidate real || return 1
  remote_head="$(fixture_git --git-dir="$CASE_REMOTE" rev-parse refs/heads/master)" \
    || return 1

  run_cloud_installer >/dev/null || return 1

  assert_new_checkout || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$remote_head" ] || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_no_transaction_artifacts
}

test_same_head_reconciles_links_without_swap_or_recovery() {
  local checkout_snapshot
  local move_marker="$TEST_ROOT/same-head/old-move"
  prepare_case "$TEST_ROOT/same-head"
  clone_old_checkout || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
  AGENTS_ECOSYSTEM_TEST_MV_MODE=record-old-move \
  AGENTS_ECOSYSTEM_TEST_OLD_MOVE_MARKER="$move_marker" \
    run_cloud_installer >/dev/null || return 1

  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_absent "$move_marker" || {
    echo "same-HEAD install attempted to swap the checkout" >&2
    return 1
  }
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_no_transaction_artifacts
}

test_real_update_retains_exact_prior_with_cached_ref_and_private_metadata() {
  local cached_head
  local expected_private="$TEST_ROOT/retained-prior/private-note.expected"
  local prior
  local prior_snapshot="$TEST_ROOT/retained-prior/prior.snapshot"
  local remote_head
  prepare_case "$TEST_ROOT/retained-prior"
  clone_old_checkout || return 1
  cached_head="$(fixture_git -C "$CASE_DEST" rev-parse refs/remotes/origin/master)" \
    || return 1
  publish_candidate real || return 1
  remote_head="$(fixture_git --git-dir="$CASE_REMOTE" rev-parse refs/heads/master)" \
    || return 1
  [ "$cached_head" != "$remote_head" ] || return 1
  mkdir -p "$CASE_DEST/.git/refs/remotes/origin"
  printf '%s\n' "$cached_head" > "$CASE_DEST/.git/refs/remotes/origin/master"
  printf 'private\000metadata\nwith trailing bytes\377' > "$expected_private"
  cp "$expected_private" "$CASE_DEST/.git/private-note"
  snapshot_checkout_tree "$CASE_DEST" "$prior_snapshot" || return 1

  run_cloud_installer >/dev/null || return 1

  prior="$(find_single_retained_prior)" || return 1
  assert_checkout_tree_matches_snapshot "$prior" "$prior_snapshot" || return 1
  cmp -s -- "$expected_private" "$prior/.git/private-note" || return 1
  [ "$(fixture_git -C "$prior" rev-parse refs/remotes/origin/master)" \
    = "$cached_head" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$remote_head" ]
}

test_reflog_only_commit_is_rejected_with_exact_destination_unchanged() {
  local checkout_snapshot
  local head
  local hidden_commit
  local output
  local tree
  prepare_case "$TEST_ROOT/reflog-only"
  clone_old_checkout || return 1
  head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  tree="$(fixture_git -C "$CASE_DEST" rev-parse 'HEAD^{tree}')" || return 1
  hidden_commit="$({
    printf 'reflog-only fixture\n' \
      | fixture_git -C "$CASE_DEST" \
          -c user.name='Cloud Installer Test' \
          -c user.email=cloud-installer@example.invalid \
          commit-tree "$tree" -p "$head"
  })" || return 1
  fixture_git -C "$CASE_DEST" update-ref -m 'hide local fixture' \
    refs/heads/master "$hidden_commit" "$head" || return 1
  fixture_git -C "$CASE_DEST" update-ref -m 'restore managed head' \
    refs/heads/master "$head" "$hidden_commit" || return 1
  fixture_git -C "$CASE_DEST" fsck --full --unreachable --no-reflogs \
    2>/dev/null | grep -Fq "$hidden_commit" || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted a reflog-only local commit" >&2
    return 1
  fi

  grep -Fq 'recoverable Git objects' <<< "$output" || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_no_transaction_artifacts
}

test_tracked_mode_delta_is_rejected_with_exact_destination_unchanged() {
  local checkout_snapshot
  local output
  local tracked
  prepare_case "$TEST_ROOT/tracked-mode-delta"
  clone_old_checkout || return 1
  tracked="$CASE_DEST/.agents/skills/example/SKILL.md"
  chmod 755 -- "$tracked"
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted a tracked executable-bit delta" >&2
    return 1
  fi

  grep -Fq 'tracked file mode differs from the index' <<< "$output" || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_no_transaction_artifacts
}

test_checkout_registrar_is_never_executed() {
  local execution_marker="$TEST_ROOT/registrar-boundary/executed"
  local prior
  local prior_snapshot="$TEST_ROOT/registrar-boundary/prior.snapshot"
  prepare_case "$TEST_ROOT/registrar-boundary"
  clone_old_checkout || return 1
  publish_candidate fault || return 1
  snapshot_checkout_tree "$CASE_DEST" "$prior_snapshot" || return 1

  AGENTS_ECOSYSTEM_TEST_REGISTRAR_EXECUTION_MARKER="$execution_marker" \
    run_cloud_installer >/dev/null || return 1

  assert_absent "$execution_marker" || {
    echo "installer crossed the checkout-owned registrar execution boundary" >&2
    return 1
  }
  assert_new_checkout || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  prior="$(find_single_retained_prior)" || return 1
  assert_checkout_tree_matches_snapshot "$prior" "$prior_snapshot"
}

test_wrong_origin_is_rejected_before_mutation() {
  local output
  prepare_case "$TEST_ROOT/wrong-origin"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  fixture_git -C "$CASE_DEST" remote set-url origin "file://$CASE_REMOTE"

  if output="$(run_cloud_installer 2>&1)"; then
    return 1
  fi

  grep -q 'canonical origin' <<< "$output" || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_ambient_git_config_cannot_spoof_a_wrong_origin() {
  local hostile_config
  local hostile_before
  local output
  prepare_case "$TEST_ROOT/ambient-git-config"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  fixture_git -C "$CASE_DEST" remote set-url origin "file://$CASE_REMOTE"
  hostile_config="$CASE_ROOT/hostile-git-config"
  fixture_git config --file "$hostile_config" remote.origin.url "$CANONICAL_URL"
  hostile_before="$(sha256sum "$hostile_config")" || return 1

  if output="$(GIT_CONFIG="$hostile_config" run_cloud_installer 2>&1)"; then
    echo "ambient GIT_CONFIG spoofed a noncanonical checkout" >&2
    return 1
  fi

  grep -q 'canonical origin' <<< "$output" || return 1
  assert_old_checkout || return 1
  [ "$(fixture_git -C "$CASE_DEST" config --get remote.origin.url)" = \
    "file://$CASE_REMOTE" ] || return 1
  [ "$(sha256sum "$hostile_config")" = "$hostile_before" ] || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_executable_local_git_config_is_rejected_without_running() {
  local marker
  local output
  local tracked_path
  prepare_case "$TEST_ROOT/local-git-command"
  printf '*.md filter=sentinel\n' > "$CASE_SOURCE/.gitattributes"
  fixture_git -C "$CASE_SOURCE" add .gitattributes
  fixture_git -C "$CASE_SOURCE" commit -qm 'add filter attributes'
  fixture_git -C "$CASE_SOURCE" push -q origin master
  clone_old_checkout || return 1
  marker="$CASE_ROOT/filter-ran"
  fixture_git -C "$CASE_DEST" config filter.sentinel.clean \
    "sh -c 'printf invoked > $marker; cat'"
  tracked_path="$CASE_DEST/.agents/skills/example/SKILL.md"
  touch -d '2001-01-01 00:00:00 UTC' -- "$tracked_path"
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted executable checkout-local Git configuration" >&2
    return 1
  fi

  grep -Fq 'unmanaged local Git configuration' <<< "$output" || return 1
  [ ! -e "$marker" ] || {
    echo "checkout-local Git filter executed during validation" >&2
    return 1
  }
  assert_old_checkout || return 1
  assert_no_transaction_artifacts
}

test_linked_worktree_is_rejected_and_preserved() {
  local linked="$TEST_ROOT/linked-worktree/linked"
  local output
  prepare_case "$TEST_ROOT/linked-worktree"
  clone_old_checkout || return 1
  fixture_git -C "$CASE_DEST" worktree add -q --detach "$linked" HEAD
  printf 'staged linked worktree change\n' > \
    "$linked/.agents/skills/example/SKILL.md"
  fixture_git -C "$linked" add .agents/skills/example/SKILL.md
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded linked-worktree metadata" >&2
    return 1
  fi

  grep -Fq 'linked worktrees' <<< "$output" || return 1
  assert_old_checkout || return 1
  grep -qx 'staged linked worktree change' \
    "$linked/.agents/skills/example/SKILL.md" || return 1
  [ -n "$(fixture_git -C "$linked" diff --cached --name-only)" ] || return 1
  assert_no_transaction_artifacts
}

test_empty_untracked_directory_is_rejected_and_preserved() {
  local output
  prepare_case "$TEST_ROOT/empty-directory"
  clone_old_checkout || return 1
  mkdir "$CASE_DEST/local-empty"
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded an empty untracked directory" >&2
    return 1
  fi

  grep -Fq 'untracked empty directory' <<< "$output" || return 1
  [ -d "$CASE_DEST/local-empty" ] || return 1
  assert_old_checkout || return 1
  assert_no_transaction_artifacts
}

test_replace_ref_is_rejected_and_preserved() {
  local head
  local output
  prepare_case "$TEST_ROOT/replace-ref"
  clone_old_checkout || return 1
  head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  fixture_git -C "$CASE_DEST" update-ref "refs/replace/$head" "$head"
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted a checkout with a replace ref" >&2
    return 1
  fi

  grep -Fq 'unmanaged Git ref' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse "refs/replace/$head")" = \
    "$head" ] || return 1
  assert_old_checkout || return 1
  assert_no_transaction_artifacts
}

test_global_url_rewrite_cannot_redirect_the_canonical_clone() {
  local evil_remote="$TEST_ROOT/global-url-rewrite/evil.git"
  local evil_source="$TEST_ROOT/global-url-rewrite/evil-source"
  local evil_head
  local resolved_head
  prepare_case "$TEST_ROOT/global-url-rewrite"
  publish_candidate real || return 1

  mkdir -p "$evil_source/.agents/skills/example"
  fixture_git init -q --bare "$evil_remote"
  fixture_git -C "$evil_source" init -q
  fixture_git -C "$evil_source" branch -M master
  fixture_git -C "$evil_source" config user.name "Cloud Installer Test"
  fixture_git -C "$evil_source" config user.email "cloud-installer@example.invalid"
  printf 'redirected skill\n' > "$evil_source/.agents/skills/example/SKILL.md"
  write_real_registrar "$evil_source"
  fixture_git -C "$evil_source" add .
  fixture_git -C "$evil_source" commit -qm "redirected fixture"
  fixture_git -C "$evil_source" remote add origin "$evil_remote"
  fixture_git -C "$evil_source" push -q -u origin master
  fixture_git --git-dir="$evil_remote" symbolic-ref HEAD refs/heads/master
  evil_head="$(fixture_git --git-dir="$evil_remote" rev-parse refs/heads/master)"

  fixture_git config --file "$CASE_GIT_CONFIG" \
    "url.file://$evil_remote.insteadOf" "$CANONICAL_URL"

  resolved_head="$(
    GIT_CONFIG_GLOBAL="$CASE_GIT_CONFIG" \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_ALLOW_PROTOCOL=file \
    GIT_ASKPASS=/usr/bin/false \
    SSH_ASKPASS=/usr/bin/false \
    SSH_ASKPASS_REQUIRE=never \
    AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
    AGENTS_ECOSYSTEM_TEST_TRANSPORT_ROOT="$CASE_TRANSPORT_ROOT" \
      "$GUARD_BIN/git" \
        -c credential.helper= \
        ls-remote "$CANONICAL_URL" refs/heads/master \
      | awk '{print $1}'
  )" || return 1
  [ "$resolved_head" = "$evil_head" ] || return 1

  run_cloud_installer >/dev/null || return 1
  grep -qx 'new skill' "$CASE_DEST/.agents/skills/example/SKILL.md"
}

test_dirty_checkout_is_rejected_before_mutation() {
  local output
  prepare_case "$TEST_ROOT/dirty"
  clone_old_checkout || return 1
  printf 'keep me\n' > "$CASE_DEST/local-notes.md"
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    return 1
  fi

  grep -q 'must be clean' <<< "$output" || return 1
  assert_old_checkout || return 1
  grep -qx 'keep me' "$CASE_DEST/local-notes.md" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills"
}

test_unpushed_commit_is_rejected_and_preserved() {
  local original_head
  local output
  prepare_case "$TEST_ROOT/unpushed-commit"
  clone_old_checkout || return 1
  printf 'local committed work\n' > "$CASE_DEST/local-commit.txt"
  fixture_git -C "$CASE_DEST" add local-commit.txt
  fixture_git -C "$CASE_DEST" \
    -c user.name="Cloud Installer Test" \
    -c user.email=cloud-installer@example.invalid \
    commit -qm "local unpushed work"
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded an unpushed local commit" >&2
    return 1
  fi

  grep -q 'managed branch' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'local committed work' "$CASE_DEST/local-commit.txt" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_diverged_branch_is_rejected_and_preserved() {
  local original_head
  local output
  prepare_case "$TEST_ROOT/diverged-branch"
  clone_old_checkout || return 1
  printf 'local divergent work\n' > "$CASE_DEST/local-divergent.txt"
  fixture_git -C "$CASE_DEST" add local-divergent.txt
  fixture_git -C "$CASE_DEST" \
    -c user.name="Cloud Installer Test" \
    -c user.email=cloud-installer@example.invalid \
    commit -qm "local divergent work"
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  publish_candidate real || return 1
  fixture_git -C "$CASE_DEST" fetch -q "file://$CASE_REMOTE" \
    master:refs/remotes/origin/master || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded a diverged local commit" >&2
    return 1
  fi

  grep -q 'managed branch' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'local divergent work' "$CASE_DEST/local-divergent.txt" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_nonmanaged_branch_is_rejected_and_preserved() {
  local original_head
  local output
  prepare_case "$TEST_ROOT/nonmanaged-branch"
  clone_old_checkout || return 1
  fixture_git -C "$CASE_DEST" switch -qc local-work || return 1
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded a non-managed clean branch" >&2
    return 1
  fi

  grep -q 'managed branch' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" symbolic-ref --short HEAD)" = "local-work" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_additional_local_branch_is_rejected_and_preserved() {
  local branch_head
  local output
  prepare_case "$TEST_ROOT/additional-local-branch"
  clone_old_checkout || return 1
  fixture_git -C "$CASE_DEST" switch -qc local-backup || return 1
  printf 'branch-only committed work\n' > "$CASE_DEST/branch-only.txt"
  fixture_git -C "$CASE_DEST" add branch-only.txt
  fixture_git -C "$CASE_DEST" \
    -c user.name="Cloud Installer Test" \
    -c user.email=cloud-installer@example.invalid \
    commit -qm "branch-only local work"
  branch_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  fixture_git -C "$CASE_DEST" switch -q master || return 1
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded an additional local branch" >&2
    return 1
  fi

  grep -q 'managed branch' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse refs/heads/local-backup)" \
    = "$branch_head" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" show local-backup:branch-only.txt)" \
    = "branch-only committed work" ] || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_stashed_work_is_rejected_and_preserved() {
  local output
  local stash_head
  prepare_case "$TEST_ROOT/stashed-work"
  clone_old_checkout || return 1
  printf 'stashed local work\n' > \
    "$CASE_DEST/.agents/skills/example/SKILL.md"
  fixture_git -C "$CASE_DEST" stash push -qm "local retained work" || return 1
  stash_head="$(fixture_git -C "$CASE_DEST" rev-parse refs/stash)" || return 1
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded stashed local work" >&2
    return 1
  fi

  grep -q 'unmanaged Git ref' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse refs/stash)" \
    = "$stash_head" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" show \
    refs/stash:.agents/skills/example/SKILL.md)" \
    = "stashed local work" ] || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_local_tag_is_rejected_and_preserved() {
  local output
  local tag_head
  prepare_case "$TEST_ROOT/local-tag"
  clone_old_checkout || return 1
  fixture_git -C "$CASE_DEST" switch -qc tag-source || return 1
  printf 'tag-only committed work\n' > "$CASE_DEST/tag-only.txt"
  fixture_git -C "$CASE_DEST" add tag-only.txt
  fixture_git -C "$CASE_DEST" \
    -c user.name="Cloud Installer Test" \
    -c user.email=cloud-installer@example.invalid \
    commit -qm "tag-only local work"
  fixture_git -C "$CASE_DEST" tag local-only
  tag_head="$(fixture_git -C "$CASE_DEST" rev-parse refs/tags/local-only)" || return 1
  fixture_git -C "$CASE_DEST" switch -q master || return 1
  fixture_git -C "$CASE_DEST" branch -qD tag-source || return 1
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer discarded a local tag" >&2
    return 1
  fi

  grep -q 'unmanaged Git ref' <<< "$output" || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse refs/tags/local-only)" \
    = "$tag_head" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" show local-only:tag-only.txt)" \
    = "tag-only committed work" ] || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_pre_mutation_failure_preserves_index_bytes() {
  local index_hash_before
  local output
  local original_head
  local original_identity
  local tracked_path
  prepare_case "$TEST_ROOT/index-preservation"
  clone_old_checkout || return 1
  publish_candidate missing || return 1
  tracked_path="$CASE_DEST/.agents/skills/example/SKILL.md"
  touch -d '2001-01-01 00:00:00 UTC' -- "$tracked_path" || return 1
  index_hash_before="$(sha256sum "$CASE_DEST/.git/index" | awk '{print $1}')" \
    || return 1
  original_identity="$(stat -c '%d:%i:%u' -- "$CASE_DEST")" || return 1
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted a candidate without a registrar" >&2
    return 1
  fi

  grep -q 'registrar must be a physical file' <<< "$output" || return 1
  [ "$(sha256sum "$CASE_DEST/.git/index" | awk '{print $1}')" \
    = "$index_hash_before" ] || {
    echo "read-only validation changed the existing checkout index" >&2
    return 1
  }
  [ "$(stat -c '%d:%i:%u' -- "$CASE_DEST")" = "$original_identity" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'old skill' "$tracked_path" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_assume_unchanged_modification_is_rejected_and_preserved() {
  local output
  local original_head
  local original_identity
  local tracked_path='.agents/skills/example/SKILL.md'
  prepare_case "$TEST_ROOT/assume-unchanged"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  fixture_git -C "$CASE_DEST" update-index --assume-unchanged -- "$tracked_path" \
    || return 1
  printf 'assume-unchanged sentinel\n' > "$CASE_DEST/$tracked_path"
  original_identity="$(stat -c '%d:%i:%u' -- "$CASE_DEST")" || return 1
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted an assume-unchanged tracked modification" >&2
    return 1
  fi

  grep -q 'unsafe tracked index flags' <<< "$output" || return 1
  [ "$(stat -c '%d:%i:%u' -- "$CASE_DEST")" = "$original_identity" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'assume-unchanged sentinel' "$CASE_DEST/$tracked_path" || return 1
  [ "$(fixture_git -C "$CASE_DEST" ls-files -v -- "$tracked_path")" \
    = "h $tracked_path" ] || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_skip_worktree_modification_is_rejected_and_preserved() {
  local output
  local original_head
  local original_identity
  local tracked_path='.agents/skills/example/SKILL.md'
  prepare_case "$TEST_ROOT/skip-worktree"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  fixture_git -C "$CASE_DEST" update-index --skip-worktree -- "$tracked_path" \
    || return 1
  printf 'skip-worktree sentinel\n' > "$CASE_DEST/$tracked_path"
  original_identity="$(stat -c '%d:%i:%u' -- "$CASE_DEST")" || return 1
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted a skip-worktree tracked modification" >&2
    return 1
  fi

  grep -q 'unsafe tracked index flags' <<< "$output" || return 1
  [ "$(stat -c '%d:%i:%u' -- "$CASE_DEST")" = "$original_identity" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'skip-worktree sentinel' "$CASE_DEST/$tracked_path" || return 1
  [ "$(fixture_git -C "$CASE_DEST" ls-files -v -- "$tracked_path")" \
    = "S $tracked_path" ] || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_ignored_checkout_entry_is_rejected_before_mutation() {
  local original_head
  local original_identity
  local output
  prepare_case "$TEST_ROOT/ignored-entry"
  printf 'local-cache/\n' > "$CASE_SOURCE/.gitignore"
  fixture_git -C "$CASE_SOURCE" add .gitignore
  fixture_git -C "$CASE_SOURCE" commit -qm "ignore local cache fixture"
  fixture_git -C "$CASE_SOURCE" push -q origin master
  clone_old_checkout || return 1
  mkdir -p "$CASE_DEST/local-cache"
  printf 'ignored sentinel\n' > "$CASE_DEST/local-cache/sentinel.txt"
  original_identity="$(stat -c '%d:%i:%u' -- "$CASE_DEST")" || return 1
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    echo "installer accepted an ignored local checkout entry" >&2
    return 1
  fi

  grep -q 'must be clean' <<< "$output" || return 1
  assert_old_checkout || return 1
  [ "$(stat -c '%d:%i:%u' -- "$CASE_DEST")" = "$original_identity" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'ignored sentinel' \
    "$CASE_DEST/local-cache/sentinel.txt" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_symlink_destination_is_rejected_without_following_it() {
  local actual_checkout
  local output
  prepare_case "$TEST_ROOT/symlink-destination"
  actual_checkout="$CASE_ROOT/actual-checkout"
  CASE_DEST="$actual_checkout"
  clone_old_checkout || return 1
  CASE_DEST="$CASE_ROOT/cloud-checkout"
  ln -s "$actual_checkout" "$CASE_DEST"
  publish_candidate real || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    return 1
  fi

  grep -q 'must not be a symlink' <<< "$output" || return 1
  grep -qx 'old skill' "$actual_checkout/.agents/skills/example/SKILL.md" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills"
}

test_special_destination_is_preserved() {
  local output
  prepare_case "$TEST_ROOT/special-destination"
  mkfifo "$CASE_DEST"

  if output="$(run_cloud_installer 2>&1)"; then
    return 1
  fi

  grep -q 'must be a physical directory or absent' <<< "$output" || return 1
  [ -p "$CASE_DEST" ] || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills"
}

test_symlinked_ancestor_is_rejected_without_escape() {
  local external_parent
  local output
  prepare_case "$TEST_ROOT/symlink-ancestor"
  external_parent="$CASE_ROOT/external-parent"
  mkdir -p "$external_parent"
  ln -s "$external_parent" "$CASE_ROOT/alias-parent"
  CASE_DEST="$CASE_ROOT/alias-parent/cloud-checkout"

  if output="$(run_cloud_installer 2>&1)"; then
    return 1
  fi

  grep -q 'physical normalized directory' <<< "$output" || return 1
  [ -z "$(find "$external_parent" -mindepth 1 -print -quit)" ] || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills"
}

test_owner_mismatch_is_rejected() {
  local fake_bin="$TEST_ROOT/owner/bin"
  local output
  prepare_case "$TEST_ROOT/owner"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  mkdir -p "$fake_bin"
  cat > "$fake_bin/stat" <<'EOF'
#!/usr/bin/env bash
last="${!#}"
if [ "$last" = "$AGENTS_ECOSYSTEM_TEST_OWNER_TARGET" ] && [ "$1" = "-c" ] && [ "$2" = "%u" ]; then
  printf '%s\n' "$AGENTS_ECOSYSTEM_TEST_WRONG_UID"
  exit 0
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_STAT" "$@"
EOF
  chmod +x "$fake_bin/stat"

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$fake_bin" \
    AGENTS_ECOSYSTEM_TEST_OWNER_TARGET="$CASE_DEST" \
    AGENTS_ECOSYSTEM_TEST_WRONG_UID="$(( $(id -u) + 1 ))" \
    AGENTS_ECOSYSTEM_TEST_REAL_STAT="$REAL_STAT" \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  grep -q 'must be owned by uid' <<< "$output" || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills"
}

test_destination_lock_rejects_a_second_installer() {
  local first_output="$TEST_ROOT/concurrent/first.out"
  local first_pid
  local ready="$TEST_ROOT/concurrent/ready"
  local release="$TEST_ROOT/concurrent/release"
  local prior
  local prior_snapshot="$TEST_ROOT/concurrent/prior.snapshot"
  local second_output
  local count
  prepare_case "$TEST_ROOT/concurrent"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  snapshot_checkout_tree "$CASE_DEST" "$prior_snapshot" || return 1

  AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
  AGENTS_ECOSYSTEM_TEST_LINK_MODE=wait-before-first \
  AGENTS_ECOSYSTEM_TEST_READY="$ready" \
  AGENTS_ECOSYSTEM_TEST_RELEASE="$release" \
    run_cloud_installer >"$first_output" 2>&1 &
  first_pid=$!
  ACTIVE_PIDS+=("$first_pid")

  count=0
  while [ ! -e "$ready" ]; do
    count=$((count + 1))
    if [ "$count" -gt 200 ] || ! kill -0 "$first_pid" 2>/dev/null; then
      return 1
    fi
    sleep 0.05
  done

  if second_output="$(
      run_cloud_installer 2>&1
  )"; then
    : > "$release"
    wait "$first_pid" || true
    return 1
  fi
  grep -q 'installation already in progress' <<< "$second_output" || return 1

  : > "$release"
  wait "$first_pid" || return 1
  ACTIVE_PIDS=()
  grep -qx 'new skill' "$CASE_DEST/.agents/skills/example/SKILL.md" || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  prior="$(find_single_retained_prior)" || return 1
  assert_checkout_tree_matches_snapshot "$prior" "$prior_snapshot"
}

test_signal_and_fault_boundaries_restore_both_transitions() {
  local cursor_snapshot
  local failed_candidate
  local mode
  local output
  local stage_root
  for mode in \
    signal-before-old \
    signal-after-old \
    fail-old \
    signal-before-new \
    signal-after-new \
    fail-new; do
    prepare_case "$TEST_ROOT/transition-$mode"
    clone_old_checkout || return 1
    mkdir -p "$CASE_HOME/.cursor"
    ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.cursor/skills"
    cursor_snapshot="$(discovery_entry_snapshot "$CASE_HOME/.cursor/skills")" \
      || return 1
    publish_candidate real || return 1

    if output="$(
      AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
      AGENTS_ECOSYSTEM_TEST_MV_MODE="$mode" \
        run_cloud_installer 2>&1
    )"; then
      echo "transition injection unexpectedly succeeded: $mode" >&2
      return 1
    fi

    assert_old_checkout || {
      echo "prior checkout was not restored: $mode" >&2
      return 1
    }
    assert_absent "$CASE_HOME/.agents/skills" || return 1
    assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
    [ "$(discovery_entry_snapshot "$CASE_HOME/.cursor/skills")" \
      = "$cursor_snapshot" ] || return 1
    case "$mode" in
      signal-before-new|signal-after-new)
        stage_root="$(
          find "$CASE_ROOT" -maxdepth 1 -name '.cloud-checkout.stage.*' \
            -type d -print -quit
        )"
        [ -n "$stage_root" ] || return 1
        failed_candidate="$stage_root/failed-candidate"
        grep -qx 'new skill' \
          "$failed_candidate/.agents/skills/example/SKILL.md" || return 1
        grep -Fq "$failed_candidate" <<< "$output" || return 1
        ;;
      *)
        assert_no_transaction_artifacts || {
          echo "transaction artifacts remained: $mode" >&2
          return 1
        }
        ;;
    esac
  done
}

test_signal_during_lock_acquisition_does_not_leave_a_stale_lock() {
  local output
  prepare_case "$TEST_ROOT/lock-signal"
  clone_old_checkout || return 1
  publish_candidate real || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LOCK_SIGNAL_BIN" \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_signal_during_stage_creation_removes_the_recorded_stage() {
  local output
  local stage_record
  prepare_case "$TEST_ROOT/stage-signal"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  stage_record="$CASE_ROOT/created-stage"

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$STAGE_SIGNAL_BIN" \
    AGENTS_ECOSYSTEM_TEST_STAGE_RECORD="$stage_record" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer ignored a signal during stage creation" >&2
    return 1
  fi

  [ -s "$stage_record" ] || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_destination_parent_replacement_is_rejected_and_preserved() {
  local original_parent
  local output
  prepare_case "$TEST_ROOT/destination-parent-race"
  CASE_DEST="$CASE_ROOT/install/cloud-checkout"
  mkdir -p "$(dirname -- "$CASE_DEST")"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  original_parent="$(dirname -- "$CASE_DEST").concurrent-original"

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$PARENT_RACE_BIN" \
    AGENTS_ECOSYSTEM_TEST_DEST_PARENT="$(dirname -- "$CASE_DEST")" \
    AGENTS_ECOSYSTEM_TEST_PARENT_RACE_MARKER="$(dirname -- "$CASE_DEST")/concurrent-owner.txt" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer committed through a replaced destination parent" >&2
    return 1
  fi

  grep -qx 'old skill' \
    "$original_parent/cloud-checkout/.agents/skills/example/SKILL.md" || return 1
  grep -qx 'concurrent parent' \
    "$(dirname -- "$CASE_DEST")/concurrent-owner.txt" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  [ -z "$(find "$original_parent" "$(dirname -- "$CASE_DEST")" \
    -maxdepth 1 -name '.cloud-checkout.install.lock' -print -quit)" ] || return 1
  grep -Fq 'destination parent changed' <<< "$output" || return 1
  grep -Fq "$original_parent/cloud-checkout" <<< "$output"
}

test_parent_swap_at_checkout_move_uses_bound_paths_and_preserves_visible_state() {
  local checkout_snapshot
  local concurrent_id
  local move_paths="$TEST_ROOT/parent-swap-at-move/move-paths"
  local original_parent
  local output
  local recovery_stage
  local source_path
  local target_path
  prepare_case "$TEST_ROOT/parent-swap-at-move"
  CASE_DEST="$CASE_ROOT/install/cloud-checkout"
  mkdir -p "$(dirname -- "$CASE_DEST")"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1
  original_parent="$(dirname -- "$CASE_DEST").concurrent-original"

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=swap-parent-at-old-move \
    AGENTS_ECOSYSTEM_TEST_MOVE_PATH_RECORD="$move_paths" \
    AGENTS_ECOSYSTEM_TEST_CONCURRENT_DEST_ID_RECORD="$CASE_ROOT/concurrent-id" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer committed across a destination-parent swap at move" >&2
    return 1
  fi

  [ -s "$move_paths" ] || {
    echo "old-checkout move boundary was not reached" >&2
    return 1
  }
  {
    IFS= read -r source_path
    IFS= read -r target_path
  } < "$move_paths" || return 1
  [[ "$source_path" == /proc/*/fd/*/cloud-checkout ]] || {
    echo "old-checkout move did not use its bound source: $source_path" >&2
    return 1
  }
  [[ "$target_path" == /proc/*/fd/*/prior ]] || {
    echo "old-checkout move did not use its bound target: $target_path" >&2
    return 1
  }
  assert_checkout_tree_matches_snapshot \
    "$original_parent/cloud-checkout" "$checkout_snapshot" || return 1
  concurrent_id="$(cat "$CASE_ROOT/concurrent-id")" || return 1
  [ "$(stat -c '%d:%i:%u' -- "$CASE_DEST")" = "$concurrent_id" ] || return 1
  grep -qx 'visible concurrent destination' \
    "$CASE_DEST/concurrent-owner.txt" || return 1
  recovery_stage="$(
    find "$original_parent" -maxdepth 1 -name '.cloud-checkout.stage.*' \
      -type d -print -quit
  )"
  [ -n "$recovery_stage" ] || return 1
  grep -Fq 'destination parent changed' <<< "$output" || return 1
  grep -Fq "$original_parent/cloud-checkout" <<< "$output" || return 1
  grep -Fq "$recovery_stage" <<< "$output"
}

test_external_destination_replacement_is_preserved_with_recovery() {
  local output
  local recovery_checkout
  prepare_case "$TEST_ROOT/external-transition-replacement"
  clone_old_checkout || return 1
  mkdir -p "$CASE_HOME/.cursor"
  ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.cursor/skills"
  publish_candidate real || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=external-after-old \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  grep -q 'Recovery required' <<< "$output" || return 1
  grep -qx 'external owner' "$CASE_DEST/external-owner.txt" || return 1
  recovery_checkout="$(
    find "$CASE_ROOT" -path '*/.cloud-checkout.stage.*/prior' -type d -print -quit
  )"
  [ -n "$recovery_checkout" ] || return 1
  grep -qx 'old skill' \
    "$recovery_checkout/.agents/skills/example/SKILL.md" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_pre_move_destination_replacement_retains_all_recovery_material() {
  local candidate_recovery
  local checkout_snapshot
  local output
  local stage_root
  prepare_case "$TEST_ROOT/pre-move-external-replacement"
  clone_old_checkout || return 1
  mkdir -p "$CASE_HOME/.cursor"
  ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.cursor/skills"
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=external-before-old \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  assert_checkout_tree_matches_snapshot \
    "$CASE_DEST.external-original" "$checkout_snapshot" || return 1
  grep -qx 'external owner' "$CASE_DEST/external-owner.txt" || return 1
  stage_root="$(
    find "$CASE_ROOT" -maxdepth 1 -name '.cloud-checkout.stage.*' \
      -type d -print -quit
  )"
  [ -n "$stage_root" ] || return 1
  candidate_recovery="$stage_root/candidate"
  grep -qx 'new skill' \
    "$candidate_recovery/.agents/skills/example/SKILL.md" || return 1
  grep -q 'Recovery required' <<< "$output" || return 1
  grep -Fq "$CASE_DEST.external-original" <<< "$output" || return 1
  grep -Fq "$stage_root" <<< "$output" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_pre_move_in_place_change_is_rejected_and_preserved() {
  local original_head
  local original_identity
  local output
  prepare_case "$TEST_ROOT/pre-move-in-place-change"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  original_identity="$(stat -c '%d:%i:%u' -- "$CASE_DEST")" || return 1
  original_head="$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=inject-untracked-before-old \
      run_cloud_installer 2>&1
  )"; then
    echo "installer discarded an in-place change at the old-checkout move" >&2
    return 1
  fi

  [ "$(stat -c '%d:%i:%u' -- "$CASE_DEST")" = "$original_identity" ] || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$original_head" ] || return 1
  grep -qx 'concurrent local work' "$CASE_DEST/concurrent-local.txt" || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fq 'must be clean' <<< "$output" || return 1
  grep -Fq 'Recovery required' <<< "$output"
}

test_interruption_restores_checkout_and_discovery_paths() {
  local checkout_snapshot
  local failed_candidate
  local output
  local quarantined_link
  local stage_root
  prepare_case "$TEST_ROOT/interruption"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=interrupt-after-first \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  assert_old_checkout || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  quarantined_link="$(
    find "$CASE_HOME" -path '*/.agent-ecosystem.rollback-parent.*/*' \
      -type l -print -quit
  )"
  [ -n "$quarantined_link" ] || return 1
  [ "$(readlink -- "$quarantined_link")" = "$CASE_DEST/.agents/skills" ] \
    || return 1
  stage_root="$(
    find "$CASE_ROOT" -maxdepth 1 -name '.cloud-checkout.stage.*' \
      -type d -print -quit
  )"
  [ -n "$stage_root" ] || return 1
  failed_candidate="$stage_root/failed-candidate"
  grep -qx 'new skill' \
    "$failed_candidate/.agents/skills/example/SKILL.md" || return 1
  grep -Fq "$(dirname -- "$quarantined_link")" <<< "$output" || return 1
  grep -Fq "$stage_root" <<< "$output" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_interrupted_staging_removes_only_the_verified_candidate() {
  local fake_bin="$TEST_ROOT/staging-interruption/bin"
  local output
  prepare_case "$TEST_ROOT/staging-interruption"
  mkdir -p "$fake_bin"
  cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
is_clone=0
for argument in "$@"; do
  if [ "$argument" = "clone" ]; then
    is_clone=1
    break
  fi
done
if [ "$is_clone" -eq 1 ]; then
  "$AGENTS_ECOSYSTEM_TEST_GUARD_GIT" "$@" || exit "$?"
  kill -TERM "$PPID"
  exit 143
fi
exec "$AGENTS_ECOSYSTEM_TEST_GUARD_GIT" "$@"
EOF
  chmod +x "$fake_bin/git"

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$fake_bin" \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  assert_absent "$CASE_DEST" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_missing_registrar_never_replaces_the_old_checkout() {
  local output
  prepare_case "$TEST_ROOT/missing-registrar"
  clone_old_checkout || return 1
  publish_candidate missing || return 1

  if output="$(run_cloud_installer 2>&1)"; then
    return 1
  fi

  grep -q 'registrar must be a physical file' <<< "$output" || return 1
  assert_old_checkout || return 1
  [ -f "$CASE_DEST/scripts/register-skills.sh" ] || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  assert_no_transaction_artifacts
}

test_link_registration_failure_rolls_back_checkout_and_both_paths() {
  local checkout_snapshot
  local cursor_snapshot
  local failed_candidate
  local output
  local quarantined_link
  local stage_root
  prepare_case "$TEST_ROOT/registrar-failure"
  clone_old_checkout || return 1
  mkdir -p "$CASE_HOME/.cursor"
  ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.cursor/skills"
  cursor_snapshot="$(discovery_entry_snapshot "$CASE_HOME/.cursor/skills")" \
    || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=fail-after-first \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  assert_old_checkout || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  [ "$(discovery_entry_snapshot "$CASE_HOME/.cursor/skills")" \
    = "$cursor_snapshot" ] || return 1
  quarantined_link="$(
    find "$CASE_HOME" -path '*/.agent-ecosystem.rollback-parent.*/*' \
      -type l -print -quit
  )"
  [ -n "$quarantined_link" ] || return 1
  [ "$(readlink -- "$quarantined_link")" = "$CASE_DEST/.agents/skills" ] \
    || return 1
  stage_root="$(
    find "$CASE_ROOT" -maxdepth 1 -name '.cloud-checkout.stage.*' \
      -type d -print -quit
  )"
  [ -n "$stage_root" ] || return 1
  failed_candidate="$stage_root/failed-candidate"
  grep -qx 'new skill' \
    "$failed_candidate/.agents/skills/example/SKILL.md" || return 1
  grep -Fq "$(dirname -- "$quarantined_link")" <<< "$output" || return 1
  grep -Fq "$stage_root" <<< "$output" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_post_activation_private_git_state_is_retained() {
  local failed_candidate
  local output
  local private_note_id
  local stage_root
  prepare_case "$TEST_ROOT/post-activation-private-git-state"
  clone_old_checkout || return 1
  publish_candidate real || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=add-private-and-interrupt-after-second \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  private_note_id="$(cat "$CASE_ROOT/private-note-id")" || return 1
  stage_root="$(
    find "$CASE_ROOT" -maxdepth 1 -name '.cloud-checkout.stage.*' \
      -type d -print -quit
  )"
  [ -n "$stage_root" ] || {
    echo "once-visible failed candidate was removed" >&2
    return 1
  }
  failed_candidate="$stage_root/failed-candidate"
  grep -qx 'concurrent private metadata' \
    "$failed_candidate/.git/private-note" || return 1
  [ "$(stat -c '%d:%i:%u' -- "$failed_candidate/.git/private-note")" \
    = "$private_note_id" ] || return 1
  assert_old_checkout || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fq "$failed_candidate" <<< "$output" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_recovery_failure_preserves_concurrent_state_and_prior_checkout() {
  local checkout_snapshot
  local output
  local recovery_checkout
  prepare_case "$TEST_ROOT/recovery-failure"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=recovery-failure-after-first \
      run_cloud_installer 2>&1
  )"; then
    return 1
  fi

  grep -q 'Recovery required' <<< "$output" || return 1
  grep -qx 'concurrent owner' "$CASE_DEST/concurrent-owner.txt" || return 1
  grep -qx 'new skill' \
    "$CASE_DEST.displaced/.agents/skills/example/SKILL.md" || return 1
  grep -Fq "$CASE_DEST.displaced" <<< "$output" || return 1
  recovery_checkout="$(
    find "$CASE_ROOT" -path '*/.cloud-checkout.stage.*/prior' -type d -print -quit
  )"
  [ -n "$recovery_checkout" ] || return 1
  grep -qx 'old skill' \
    "$recovery_checkout/.agents/skills/example/SKILL.md" || return 1
  assert_checkout_tree_matches_snapshot \
    "$recovery_checkout" "$checkout_snapshot" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_clean_update_never_attempts_prior_cleanup() {
  local cleanup_marker="$TEST_ROOT/postcommit-cleanup-failure/prior-cleanup-attempted"
  local output
  local prior
  local prior_identity
  local prior_snapshot="$TEST_ROOT/postcommit-cleanup-failure/prior.snapshot"
  prepare_case "$TEST_ROOT/postcommit-cleanup-failure"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  snapshot_checkout_tree "$CASE_DEST" "$prior_snapshot" || return 1

  if ! output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$STAGE_CLEANUP_BIN" \
    AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE=mark-prior-delete \
    AGENTS_ECOSYSTEM_TEST_PRIOR_CLEANUP_MARKER="$cleanup_marker" \
      run_cloud_installer 2>&1
  )"; then
    echo "a committed install was reported as a failed transaction" >&2
    return 1
  fi

  assert_new_checkout || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_absent "$cleanup_marker" || {
    echo "committed prior cleanup was attempted" >&2
    return 1
  }
  prior="$(find_single_retained_prior)" || return 1
  assert_checkout_tree_matches_snapshot "$prior" "$prior_snapshot" || return 1
  prior_identity="directory:$(stat -c '%d:%i:%u' -- "$prior")" || return 1
  grep -Fq "$prior" <<< "$output" || return 1
  grep -Fq "$prior_identity" <<< "$output" || return 1
  if grep -Fq 'Error:' <<< "$output"; then
    echo "committed prior retention emitted a misleading error" >&2
    return 1
  fi
  return 0
}

test_postcommit_lock_release_failure_reports_success_and_retained_lock() {
  local lock_path
  local output
  local prior
  local retained_lock
  prepare_case "$TEST_ROOT/postcommit-lock-failure"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  lock_path="$CASE_ROOT/.cloud-checkout.install.lock"

  if ! output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$FINALIZE_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_FINALIZE_MODE=release-fail \
      run_cloud_installer 2>&1
  )"; then
    echo "a committed install was reported as failed after lock release failed" >&2
    return 1
  fi

  assert_new_checkout || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  retained_lock="$(
    find "$CASE_ROOT" -maxdepth 1 \
      -name '.cloud-checkout.install.lock.release.*' -type d -print -quit
  )"
  [ -n "$retained_lock" ] || return 1
  assert_absent "$lock_path" || return 1
  grep -Fqi 'installation committed successfully' <<< "$output" || return 1
  grep -Fq "$retained_lock" <<< "$output" || return 1
  if grep -Fq 'Error:' <<< "$output"; then
    echo "committed lock-release failure emitted a misleading error" >&2
    return 1
  fi
  prior="$(find_single_retained_prior 1)" || return 1
  grep -qx 'old skill' "$prior/.agents/skills/example/SKILL.md"
}

test_public_lock_replacement_at_release_is_preserved() {
  local output
  local replacement_id
  local lock_path
  prepare_case "$TEST_ROOT/public-lock-release-race"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  lock_path="$CASE_ROOT/.cloud-checkout.install.lock"

  if ! output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$FINALIZE_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_FINALIZE_MODE=replace-public-lock \
    AGENTS_ECOSYSTEM_TEST_LOCK_PATH="$lock_path" \
      run_cloud_installer 2>&1
  )"; then
    echo "committed install failed during a concurrent lock acquisition" >&2
    return 1
  fi

  replacement_id="$(cat "$CASE_ROOT/replacement-id")" || return 1
  [ -d "$lock_path" ] && [ ! -L "$lock_path" ] || {
    echo "concurrent public lock was removed during release" >&2
    return 1
  }
  [ "$(stat -c '%d:%i:%u' -- "$lock_path")" = "$replacement_id" ] \
    || return 1
  assert_absent "$lock_path.concurrent-original" || return 1
  [ -z "$(find "$CASE_ROOT" -maxdepth 1 \
    -name '.cloud-checkout.install.lock.release.*' -print -quit)" ] || return 1
  assert_new_checkout || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  if grep -Fq 'Error:' <<< "$output"; then
    echo "concurrent public lock made a committed install look failed" >&2
    return 1
  fi
}

test_postcommit_renamed_stage_reports_current_recovery_path() {
  local output
  local prior_snapshot
  local renamed_stage
  prepare_case "$TEST_ROOT/postcommit-renamed-stage-cleanup"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  prior_snapshot="$CASE_ROOT/prior.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$prior_snapshot" || return 1

  if ! output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$STAGE_CLEANUP_BIN" \
    AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE=rename-stage-on-third-prior-validation \
      run_cloud_installer 2>&1
  )"; then
    echo "committed install failed after a cleanup-stage rename" >&2
    return 1
  fi

  renamed_stage="$(cat "$CASE_ROOT/renamed-stage")" || return 1
  assert_new_checkout || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_checkout_tree_matches_snapshot \
    "$renamed_stage/prior" "$prior_snapshot" || return 1
  grep -Fqi 'installation committed successfully' <<< "$output" || return 1
  grep -Fq "$renamed_stage" <<< "$output" || return 1
  grep -Fq "$renamed_stage/prior" <<< "$output" || return 1
  if grep -Fq 'Error:' <<< "$output"; then
    echo "committed cleanup recovery was reported as an install error" >&2
    return 1
  fi
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_precommit_renamed_stage_fails_with_retained_recovery() {
  local checkout_snapshot
  local expected_identity
  local output
  local recorded_stage
  local renamed_stage
  prepare_case "$TEST_ROOT/postcommit-renamed-stage"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1
  recorded_stage="$CASE_ROOT/renamed-stage"

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=rename-stage-after-second \
    AGENTS_ECOSYSTEM_TEST_RENAMED_STAGE_RECORD="$recorded_stage" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer committed after its recovery stage was renamed" >&2
    return 1
  fi

  renamed_stage="$(cat "$recorded_stage")" || return 1
  [ -d "$renamed_stage" ] && [ ! -L "$renamed_stage" ] || return 1
  grep -qx 'new skill' \
    "$renamed_stage/failed-candidate/.agents/skills/example/SKILL.md" || return 1
  expected_identity="directory:$(stat -c '%d:%i:%u' -- "$renamed_stage")" || return 1
  assert_old_checkout || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fqi 'Error:' <<< "$output" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  grep -Fq "$renamed_stage" <<< "$output" || return 1
  grep -Fq "$renamed_stage/failed-candidate" <<< "$output" || return 1
  grep -Fq "$expected_identity" <<< "$output" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_unexpected_stage_entry_is_retained_after_commit() {
  local output
  local recorded_stage
  local stage_path
  prepare_case "$TEST_ROOT/unexpected-stage-entry"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  recorded_stage="$CASE_ROOT/stage-with-concurrent-entry"

  output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=add-stage-entry-after-second \
    AGENTS_ECOSYSTEM_TEST_STAGE_ENTRY_RECORD="$recorded_stage" \
      run_cloud_installer 2>&1
  )" || {
    echo "committed install failed while retaining an unexpected stage entry" >&2
    return 1
  }

  stage_path="$(cat "$recorded_stage")" || return 1
  assert_new_checkout || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills" || return 1
  grep -qx 'concurrent stage entry' "$stage_path/concurrent-owner.txt" || return 1
  grep -Fqi 'retained recovery' <<< "$output" || return 1
  grep -Fq "$stage_path" <<< "$output" || return 1
  [ ! -e "$CASE_ROOT/.cloud-checkout.install.lock" ]
}

test_stage_replacement_during_cleanup_is_preserved() {
  local checkout_snapshot
  local output
  local replacement_sentinel
  prepare_case "$TEST_ROOT/stage-cleanup-replacement"
  clone_old_checkout || return 1
  publish_candidate missing || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$STAGE_CLEANUP_BIN" \
    AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE=replace \
    AGENTS_ECOSYSTEM_TEST_RACE_INJECTED="$CASE_ROOT/race-injected" \
      run_cloud_installer 2>&1
  )"; then
    echo "registration fault unexpectedly committed" >&2
    return 1
  fi

  [ -f "$CASE_ROOT/race-injected" ] || return 1
  replacement_sentinel="$(
    find "$CASE_ROOT" -maxdepth 3 \
      -path '*/.cloud-checkout.stage.*/concurrent-owner.txt' \
      -type f -print -quit
  )"
  [ -n "$replacement_sentinel" ] || {
    echo "stage-path replacement was recursively removed" >&2
    return 1
  }
  grep -qx 'replacement sentinel' "$replacement_sentinel" || return 1
  assert_old_checkout || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  grep -Fqi 'Recovery required' <<< "$output" || return 1
  grep -Fq "$(dirname "$replacement_sentinel")" <<< "$output"
}

test_stage_entry_replacement_at_rmdir_is_preserved() {
  local checkout_snapshot
  local output
  local replacement_id
  local replacement_path
  prepare_case "$TEST_ROOT/stage-entry-rmdir-race"
  clone_old_checkout || return 1
  publish_candidate missing || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$STAGE_CLEANUP_BIN" \
    AGENTS_ECOSYSTEM_TEST_STAGE_CLEANUP_MODE=replace-public-at-rmdir \
      run_cloud_installer 2>&1
  )"; then
    echo "invalid candidate unexpectedly committed" >&2
    return 1
  fi

  replacement_path="$(cat "$CASE_ROOT/rmdir-replacement-path")" || return 1
  replacement_id="$(cat "$CASE_ROOT/replacement-id")" || return 1
  [ -d "$replacement_path" ] && [ ! -L "$replacement_path" ] || {
    echo "concurrent stage entry was removed at the rmdir boundary" >&2
    return 1
  }
  [ "$(stat -c '%d:%i:%u' -- "$replacement_path")" = "$replacement_id" ] \
    || return 1
  assert_old_checkout || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  grep -Fq "$replacement_path" <<< "$output"
}

test_concurrent_discovery_parent_creation_is_rejected_and_preserved() {
  local output
  prepare_case "$TEST_ROOT/discovery-parent-create-race"
  clone_old_checkout || return 1
  publish_candidate real || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=discovery-create-before-old \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT="$CASE_HOME/.agents" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER="$CASE_HOME/.agents/concurrent-owner.txt" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer accepted a concurrently created discovery parent" >&2
    return 1
  fi

  assert_old_checkout || return 1
  grep -qx 'concurrent parent' "$CASE_HOME/.agents/concurrent-owner.txt" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fq 'Recovery required' <<< "$output"
}

test_concurrent_discovery_parent_replacement_is_rejected_and_preserved() {
  local output
  prepare_case "$TEST_ROOT/discovery-parent-replace-race"
  clone_old_checkout || return 1
  mkdir -p "$CASE_HOME/.agents"
  ln -s "$CASE_DEST/.agents/skills" "$CASE_HOME/.agents/skills"
  publish_candidate real || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=discovery-replace-before-old \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT="$CASE_HOME/.agents" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER="$CASE_HOME/.agents/concurrent-owner.txt" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer accepted a concurrently replaced discovery parent" >&2
    return 1
  fi

  assert_old_checkout || return 1
  grep -qx 'concurrent replacement' \
    "$CASE_HOME/.agents/concurrent-owner.txt" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_link \
    "$CASE_HOME/.agents.concurrent-original/skills" \
    "$CASE_DEST/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  grep -Fq "$CASE_HOME/.agents.concurrent-original/skills" <<< "$output"
}

test_discovery_leaf_replacement_during_rollback_is_quarantined_and_preserved() {
  local checkout_snapshot
  local displaced_link="$TEST_ROOT/discovery-leaf-replacement/displaced-installer-link"
  local entry
  local output
  local quarantine=""
  local replacement_id
  local replacement_record="$TEST_ROOT/discovery-leaf-replacement/replacement-id"
  prepare_case "$TEST_ROOT/discovery-leaf-replacement"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  checkout_snapshot="$CASE_ROOT/checkout.snapshot"
  snapshot_checkout_tree "$CASE_DEST" "$checkout_snapshot" || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$LINK_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_LINK_MODE=replace-leaf-after-first \
    AGENTS_ECOSYSTEM_TEST_DISPLACED_DISCOVERY_LINK="$displaced_link" \
    AGENTS_ECOSYSTEM_TEST_REPLACEMENT_ID_RECORD="$replacement_record" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer committed after discovery-leaf replacement" >&2
    return 1
  fi

  replacement_id="$(cat "$replacement_record")" || return 1
  while IFS= read -r -d '' entry; do
    if [ "$(stat -c '%d:%i:%u' -- "$entry")" = "$replacement_id" ]; then
      quarantine="$entry"
      break
    fi
  done < <(find "$CASE_ROOT" -type l -print0)
  [ -n "$quarantine" ] || {
    echo "concurrent discovery replacement was not preserved" >&2
    return 1
  }
  [[ "$quarantine" == "$CASE_HOME"/.agent-ecosystem.rollback-parent.*/* ]] || {
    echo "concurrent discovery replacement was not quarantined: $quarantine" >&2
    return 1
  }
  [ "$quarantine" != "$displaced_link" ] || return 1
  [ "$(readlink -- "$quarantine")" = "$CASE_DEST/.agents/skills" ] || return 1
  assert_checkout_tree_matches_snapshot "$CASE_DEST" "$checkout_snapshot" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fq 'Recovery required' <<< "$output" || return 1
  grep -Fq "$(dirname -- "$quarantine")" <<< "$output" || return 1
  grep -Fq "$replacement_id" <<< "$output"
}

test_discovery_parent_owner_change_is_rejected_and_preserved() {
  local output
  prepare_case "$TEST_ROOT/discovery-parent-owner-change"
  clone_old_checkout || return 1
  mkdir -p "$CASE_HOME/.agents"
  publish_candidate real || return 1

  if output="$(
    AGENTS_ECOSYSTEM_TEST_EXTRA_PATH="$DISCOVERY_OWNER_BIN:$MV_FAULT_BIN" \
    AGENTS_ECOSYSTEM_TEST_MV_MODE=discovery-owner-change-before-old \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_PARENT="$CASE_HOME/.agents" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_MARKER="$CASE_HOME/.agents/owner-changed" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_TARGET="$CASE_HOME/.agents" \
    AGENTS_ECOSYSTEM_TEST_DISCOVERY_OWNER_MARKER="$CASE_HOME/.agents/owner-changed" \
    AGENTS_ECOSYSTEM_TEST_WRONG_UID="$(( $(id -u) + 1 ))" \
      run_cloud_installer 2>&1
  )"; then
    echo "installer accepted a discovery parent whose owner changed" >&2
    return 1
  fi

  assert_old_checkout || return 1
  grep -qx 'owner changed' "$CASE_HOME/.agents/owner-changed" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills" || return 1
  grep -Fq 'Recovery required' <<< "$output"
}

test_invalid_release_ref_is_rejected_before_mutation() {
  local output
  prepare_case "$TEST_ROOT/invalid-release-ref"

  if output="$(run_cloud_installer --ref master 2>&1)"; then
    echo "Cloud installer accepted a mutable release ref" >&2
    return 1
  fi

  grep -Fq 'full 40-character lowercase commit SHA' <<< "$output" || return 1
  assert_absent "$CASE_DEST" || return 1
  assert_absent "$CASE_HOME/.agents/skills" || return 1
  assert_absent "$CASE_HOME/.cursor/skills"
}

test_public_install_has_no_github_cli_dependency() {
  if grep -Eq 'require_private_repository_auth|gh auth git-credential' "$INSTALLER"; then
    echo "public Cloud installer still requires private GitHub authentication" >&2
    return 1
  fi
}

test_fresh_release_install_selects_exact_historical_commit() {
  local release_a
  prepare_case "$TEST_ROOT/fresh-release-ref"
  release_a="$(fixture_git --git-dir="$CASE_REMOTE" rev-parse refs/heads/master)" \
    || return 1
  publish_candidate real || return 1

  run_cloud_installer --ref "$release_a" >/dev/null || return 1

  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$release_a" ] || return 1
  if fixture_git -C "$CASE_DEST" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "Cloud release checkout is not detached" >&2
    return 1
  fi
  grep -qx 'old skill' "$CASE_DEST/.agents/skills/example/SKILL.md" || return 1
  assert_link "$CASE_HOME/.agents/skills" "$CASE_DEST/.agents/skills" || return 1
  assert_link "$CASE_HOME/.cursor/skills" "$CASE_DEST/.agents/skills"
}

test_release_update_and_rollback_follow_exact_commits() {
  local release_a
  local release_b
  prepare_case "$TEST_ROOT/release-update-rollback"
  release_a="$(fixture_git --git-dir="$CASE_REMOTE" rev-parse refs/heads/master)" \
    || return 1
  clone_old_checkout || return 1
  fixture_git -C "$CASE_DEST" checkout -q --detach "$release_a" || return 1
  publish_candidate real || return 1
  release_b="$(fixture_git --git-dir="$CASE_REMOTE" rev-parse refs/heads/master)" \
    || return 1

  run_cloud_installer --ref "$release_b" >/dev/null || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$release_b" ] || return 1
  grep -qx 'new skill' "$CASE_DEST/.agents/skills/example/SKILL.md" || return 1

  run_cloud_installer --ref "$release_a" >/dev/null || return 1
  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$release_a" ] || return 1
  if fixture_git -C "$CASE_DEST" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "rolled-back Cloud checkout is not detached" >&2
    return 1
  fi
  grep -qx 'old skill' "$CASE_DEST/.agents/skills/example/SKILL.md"
}

test_edge_checkout_can_migrate_to_exact_release() {
  local release_b
  prepare_case "$TEST_ROOT/edge-to-release"
  clone_old_checkout || return 1
  publish_candidate real || return 1
  release_b="$(fixture_git --git-dir="$CASE_REMOTE" rev-parse refs/heads/master)" \
    || return 1

  run_cloud_installer --ref "$release_b" >/dev/null || return 1

  [ "$(fixture_git -C "$CASE_DEST" rev-parse HEAD)" = "$release_b" ] || return 1
  if fixture_git -C "$CASE_DEST" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "Cloud migration left the stable checkout attached" >&2
    return 1
  fi
  grep -qx 'new skill' "$CASE_DEST/.agents/skills/example/SKILL.md"
}

run_test \
  "an invalid release ref is rejected before mutation" \
  test_invalid_release_ref_is_rejected_before_mutation
run_test \
  "the public installer has no GitHub CLI authentication dependency" \
  test_public_install_has_no_github_cli_dependency
run_test \
  "a fresh release install selects the exact historical commit" \
  test_fresh_release_install_selects_exact_historical_commit
run_test \
  "release updates and rollbacks follow exact commits" \
  test_release_update_and_rollback_follow_exact_commits
run_test \
  "an existing edge checkout can migrate to an exact release" \
  test_edge_checkout_can_migrate_to_exact_release

run_test \
  "clean Cloud updates are atomic and idempotent" \
  test_clean_update_is_atomic_and_idempotent
run_test \
  "a fresh install creates no recovery material" \
  test_fresh_install_creates_no_recovery_material
run_test \
  "a same-HEAD install reconciles links without a swap or recovery material" \
  test_same_head_reconciles_links_without_swap_or_recovery
run_test \
  "a real update retains the exact prior checkout including private Git metadata" \
  test_real_update_retains_exact_prior_with_cached_ref_and_private_metadata
run_test \
  "a reflog-only commit is rejected with the exact destination unchanged" \
  test_reflog_only_commit_is_rejected_with_exact_destination_unchanged
run_test \
  "a tracked mode delta is rejected with the exact destination unchanged" \
  test_tracked_mode_delta_is_rejected_with_exact_destination_unchanged
run_test \
  "checkout-owned registrar code is never executed" \
  test_checkout_registrar_is_never_executed
run_test \
  "a checkout with the wrong origin is rejected before mutation" \
  test_wrong_origin_is_rejected_before_mutation
run_test \
  "ambient Git configuration cannot spoof a wrong origin" \
  test_ambient_git_config_cannot_spoof_a_wrong_origin
run_test \
  "executable checkout-local Git configuration is rejected without running" \
  test_executable_local_git_config_is_rejected_without_running
run_test \
  "linked worktree state is rejected and preserved" \
  test_linked_worktree_is_rejected_and_preserved
run_test \
  "an empty untracked directory is rejected and preserved" \
  test_empty_untracked_directory_is_rejected_and_preserved
run_test \
  "a replace ref is rejected and preserved" \
  test_replace_ref_is_rejected_and_preserved
run_test \
  "global Git URL rewrites cannot redirect the canonical clone" \
  test_global_url_rewrite_cannot_redirect_the_canonical_clone
run_test \
  "a dirty checkout is rejected before mutation" \
  test_dirty_checkout_is_rejected_before_mutation
run_test \
  "an unpushed local commit is rejected and preserved" \
  test_unpushed_commit_is_rejected_and_preserved
run_test \
  "a diverged local branch is rejected and preserved" \
  test_diverged_branch_is_rejected_and_preserved
run_test \
  "a non-managed clean branch is rejected and preserved" \
  test_nonmanaged_branch_is_rejected_and_preserved
run_test \
  "an additional local branch is rejected and preserved" \
  test_additional_local_branch_is_rejected_and_preserved
run_test \
  "stashed local work is rejected and preserved" \
  test_stashed_work_is_rejected_and_preserved
run_test \
  "a local tag is rejected and preserved" \
  test_local_tag_is_rejected_and_preserved
run_test \
  "pre-mutation failure preserves the existing checkout index bytes" \
  test_pre_mutation_failure_preserves_index_bytes
run_test \
  "an assume-unchanged tracked modification is rejected and preserved" \
  test_assume_unchanged_modification_is_rejected_and_preserved
run_test \
  "a skip-worktree tracked modification is rejected and preserved" \
  test_skip_worktree_modification_is_rejected_and_preserved
run_test \
  "an ignored checkout entry is rejected and preserved before mutation" \
  test_ignored_checkout_entry_is_rejected_before_mutation
run_test \
  "a symlink destination is rejected without following it" \
  test_symlink_destination_is_rejected_without_following_it
run_test \
  "a special destination is preserved" \
  test_special_destination_is_preserved
run_test \
  "a symlinked destination ancestor cannot redirect installation" \
  test_symlinked_ancestor_is_rejected_without_escape
run_test \
  "a destination owned by another uid is rejected" \
  test_owner_mismatch_is_rejected
run_test \
  "a destination lock rejects a concurrent installer" \
  test_destination_lock_rejects_a_second_installer
run_test \
  "signals and move faults restore both checkout transitions" \
  test_signal_and_fault_boundaries_restore_both_transitions
run_test \
  "a signal during lock acquisition leaves no stale lock" \
  test_signal_during_lock_acquisition_does_not_leave_a_stale_lock
run_test \
  "a signal during stage creation removes the recorded stage" \
  test_signal_during_stage_creation_removes_the_recorded_stage
run_test \
  "destination-parent replacement is rejected and preserved" \
  test_destination_parent_replacement_is_rejected_and_preserved
run_test \
  "a parent swap at checkout move uses bound paths and preserves visible state" \
  test_parent_swap_at_checkout_move_uses_bound_paths_and_preserves_visible_state
run_test \
  "an external destination replacement is preserved with retained recovery" \
  test_external_destination_replacement_is_preserved_with_recovery
run_test \
  "a pre-move destination replacement retains all recovery material" \
  test_pre_move_destination_replacement_retains_all_recovery_material
run_test \
  "an in-place change at the old-checkout move is rejected and preserved" \
  test_pre_move_in_place_change_is_rejected_and_preserved
run_test \
  "an interrupted registration restores the checkout and both discovery paths" \
  test_interruption_restores_checkout_and_discovery_paths
run_test \
  "an interrupted stage removes only its verified candidate" \
  test_interrupted_staging_removes_only_the_verified_candidate
run_test \
  "a candidate without a registrar never replaces the old checkout" \
  test_missing_registrar_never_replaces_the_old_checkout
run_test \
  "link-registration failure rolls back the checkout and both discovery paths" \
  test_link_registration_failure_rolls_back_checkout_and_both_paths
run_test \
  "post-activation private Git state is retained with the failed candidate" \
  test_post_activation_private_git_state_is_retained
run_test \
  "failed recovery preserves concurrent state and an actionable prior checkout" \
  test_recovery_failure_preserves_concurrent_state_and_prior_checkout
run_test \
  "clean update never attempts cleanup of its retained prior" \
  test_clean_update_never_attempts_prior_cleanup
run_test \
  "post-commit lock-release failure is successful with an explicit retained lock" \
  test_postcommit_lock_release_failure_reports_success_and_retained_lock
run_test \
  "a concurrent public lock is preserved at the release boundary" \
  test_public_lock_replacement_at_release_is_preserved
run_test \
  "a post-commit stage rename reports the current recovery path" \
  test_postcommit_renamed_stage_reports_current_recovery_path
run_test \
  "a renamed pre-commit stage fails with its retained recovery identity" \
  test_precommit_renamed_stage_fails_with_retained_recovery
run_test \
  "an unexpected stage entry is retained after commit" \
  test_unexpected_stage_entry_is_retained_after_commit
run_test \
  "stage replacement during identity-bound cleanup is preserved" \
  test_stage_replacement_during_cleanup_is_preserved
run_test \
  "a concurrent stage entry is preserved at the rmdir boundary" \
  test_stage_entry_replacement_at_rmdir_is_preserved
run_test \
  "concurrent discovery-parent creation is rejected and preserved" \
  test_concurrent_discovery_parent_creation_is_rejected_and_preserved
run_test \
  "concurrent discovery-parent replacement is rejected and preserved" \
  test_concurrent_discovery_parent_replacement_is_rejected_and_preserved
run_test \
  "a discovery-leaf replacement during rollback is quarantined and preserved" \
  test_discovery_leaf_replacement_during_rollback_is_quarantined_and_preserved
run_test \
  "discovery-parent owner changes are rejected and preserved" \
  test_discovery_parent_owner_change_is_rejected_and_preserved

if [ "$attempted" -ne "$EXPECTED_TESTS" ] \
  || [ "$completed" -ne "$EXPECTED_TESTS" ]; then
  echo "test harness ran $completed of $attempted attempted tests; expected $EXPECTED_TESTS" >&2
  exit 1
fi

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi

echo "All Cursor Cloud installer tests passed"
