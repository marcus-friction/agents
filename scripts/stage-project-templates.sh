#!/usr/bin/env bash

# Stage upstream documentation candidates without changing active project files.

set -euo pipefail
umask 022

MV_SUPPORTS_NO_TARGET=0
mv_help="$(command -p mv --help 2>&1 || true)"
if [[ "$mv_help" == *no-target-directory* ]]; then
  MV_SUPPORTS_NO_TARGET=1
fi

CHECK_ONLY=0
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=1
  shift
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: stage-project-templates.sh [--check] SOURCE_ROOT PROJECT_ROOT" >&2
  exit 1
fi

SOURCE_ROOT="$1"
PROJECT_ROOT="$2"
TARGET_DIR="$PROJECT_ROOT/.agents/templates"

if [ ! -d "$SOURCE_ROOT" ]; then
  echo "Error: source root does not exist: $SOURCE_ROOT" >&2
  exit 1
fi
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Error: project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi
if [ -L "$PROJECT_ROOT/.agents" ]; then
  echo "Error: project .agents directory must not be a symlink: $PROJECT_ROOT/.agents" >&2
  exit 1
fi
if [ -e "$PROJECT_ROOT/.agents" ] && [ ! -d "$PROJECT_ROOT/.agents" ]; then
  echo "Error: project .agents path is not a directory: $PROJECT_ROOT/.agents" >&2
  exit 1
fi
if [ -d "$PROJECT_ROOT/.agents" ] \
  && { [ ! -w "$PROJECT_ROOT/.agents" ] || [ ! -x "$PROJECT_ROOT/.agents" ]; }; then
  echo "Error: project .agents directory is not writable and searchable: $PROJECT_ROOT/.agents" >&2
  exit 1
fi
if [ ! -e "$PROJECT_ROOT/.agents" ] \
  && { [ ! -w "$PROJECT_ROOT" ] || [ ! -x "$PROJECT_ROOT" ]; }; then
  echo "Error: project root is not writable and searchable: $PROJECT_ROOT" >&2
  exit 1
fi
if { [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; } && [ ! -d "$TARGET_DIR" ]; then
  echo "Error: template target is not a directory: $TARGET_DIR" >&2
  exit 1
fi
if [ -L "$TARGET_DIR" ]; then
  echo "Error: template target must not be a symlink: $TARGET_DIR" >&2
  exit 1
fi
if [ -d "$TARGET_DIR" ] \
  && { [ ! -w "$TARGET_DIR" ] || [ ! -x "$TARGET_DIR" ]; }; then
  echo "Error: template target is not writable and searchable: $TARGET_DIR" >&2
  exit 1
fi

source_files=(
  "project-templates/base/AGENTS.md"
  "project-templates/base/README.md"
  "project-templates/base/CONTRIBUTING.md"
  "project-templates/base/DESIGN.md"
  "project-templates/base/ARCHITECTURE.md"
)
target_files=(
  "AGENTS.md"
  "README.md"
  "CONTRIBUTING.md"
  "DESIGN.md"
  "ARCHITECTURE.md"
)

source_directories=(
  "$SOURCE_ROOT/project-templates"
  "$SOURCE_ROOT/project-templates/base"
)
for source_directory in "${source_directories[@]}"; do
  if [ -L "$source_directory" ] || [ ! -d "$source_directory" ]; then
    echo "Error: project template source must be a physical directory: $source_directory" >&2
    exit 1
  fi
done

for source_file in "${source_files[@]}"; do
  if [ -L "$SOURCE_ROOT/$source_file" ] || [ ! -f "$SOURCE_ROOT/$source_file" ]; then
    echo "Error: project template must be a physical file: $SOURCE_ROOT/$source_file" >&2
    exit 1
  fi
done

retired_profile_dir="$TARGET_DIR/profiles"
if [ -L "$retired_profile_dir" ]; then
  echo "Error: retired profile path must not be a symlink: $retired_profile_dir" >&2
  exit 1
fi
if [ -e "$retired_profile_dir" ] && [ ! -d "$retired_profile_dir" ]; then
  echo "Error: retired profile path is not a directory: $retired_profile_dir" >&2
  exit 1
fi
if [ -d "$retired_profile_dir" ] \
  && { [ ! -w "$retired_profile_dir" ] || [ ! -x "$retired_profile_dir" ]; }; then
  echo "Error: retired profile path is not writable and searchable: $retired_profile_dir" >&2
  exit 1
fi

for target_file in "${target_files[@]}"; do
  target_path="$TARGET_DIR/$target_file"
  if [ -L "$target_path" ]; then
    echo "Error: project template must not be a symlink: $target_path" >&2
    exit 1
  fi
  if [ -e "$target_path" ] && [ ! -f "$target_path" ]; then
    echo "Error: project template is not a regular file: $target_path" >&2
    exit 1
  fi
done

path_identity() {
  local path="$1"
  local metadata

  if [ -L "$path" ]; then
    return 1
  fi
  if metadata="$(path_metadata "$path")"; then
    printf '%s\n' "$metadata"
  else
    return 1
  fi
}

path_metadata() {
  local path="$1"
  local metadata

  if metadata="$(command -p stat -c '%d:%i:%u' -- "$path" 2>/dev/null)"; then
    printf '%s\n' "$metadata"
  elif metadata="$(command -p stat -f '%d:%i:%u' "$path" 2>/dev/null)"; then
    printf '%s\n' "$metadata"
  else
    return 1
  fi
}

hash_file() {
  local path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    cksum "$path" | awk '{print $1 ":" $2}'
  fi
}

hash_text() {
  local value="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$value" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$value" | shasum -a 256 | awk '{print $1}'
  else
    printf '%s' "$value" | cksum | awk '{print $1 ":" $2}'
  fi
}

path_journal() {
  local path="$1"
  local metadata
  local content_hash

  if [ -L "$path" ]; then
    metadata="$(path_metadata "$path")" || return 1
    content_hash="$(hash_text "$(readlink "$path")")" || return 1
    printf 'symlink|%s|%s\n' "$metadata" "$content_hash"
  elif [ -f "$path" ]; then
    metadata="$(path_metadata "$path")" || return 1
    content_hash="$(hash_file "$path")" || return 1
    printf 'file|%s|%s\n' "$metadata" "$content_hash"
  elif [ -d "$path" ]; then
    metadata="$(path_metadata "$path")" || return 1
    printf 'directory|%s|-\n' "$metadata"
  elif [ -e "$path" ]; then
    metadata="$(path_metadata "$path")" || return 1
    printf 'special|%s|-\n' "$metadata"
  else
    printf 'absent|-|-\n'
  fi
}

move_path_no_replace() {
  local source_path="$1"
  local target_path="$2"
  local expected_journal="$3"
  local move_status=0
  local moved_journal=""
  local restore_status=0

  if [ "$(path_journal "$source_path" 2>/dev/null || true)" != "$expected_journal" ]; then
    echo "Error: rollback source changed before quarantine: $source_path" >&2
    return 1
  fi
  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    echo "Error: rollback quarantine target already exists: $target_path" >&2
    return 1
  fi

  if [ "$MV_SUPPORTS_NO_TARGET" -eq 1 ]; then
    mv -Tn -- "$source_path" "$target_path" || move_status="$?"
  else
    mv -n -- "$source_path" "$target_path" || move_status="$?"
  fi

  if [ "$(path_journal "$source_path" 2>/dev/null || true)" = 'absent|-|-' ] \
    && [ "$(path_journal "$target_path" 2>/dev/null || true)" = "$expected_journal" ]; then
    return 0
  fi

  if [ "$(path_journal "$source_path" 2>/dev/null || true)" = 'absent|-|-' ] \
    && { [ -e "$target_path" ] || [ -L "$target_path" ]; }; then
    moved_journal="$(path_journal "$target_path" 2>/dev/null || true)"
    if [ -n "$moved_journal" ] \
      && [ ! -e "$source_path" ] \
      && [ ! -L "$source_path" ]; then
      restore_status=0
      if [ "$MV_SUPPORTS_NO_TARGET" -eq 1 ]; then
        mv -Tn -- "$target_path" "$source_path" || restore_status="$?"
      else
        mv -n -- "$target_path" "$source_path" || restore_status="$?"
      fi
      if [ "$restore_status" -eq 0 ] \
        && [ "$(path_journal "$source_path" 2>/dev/null || true)" = "$moved_journal" ]; then
        echo "Error: rollback quarantined a changed path and restored it: $source_path" >&2
        return 1
      fi
    fi
  fi

  if [ "$move_status" -ne 0 ]; then
    echo "Error: rollback quarantine move failed: $source_path -> $target_path" >&2
  else
    echo "Error: rollback quarantine was blocked by a changed path: $source_path -> $target_path" >&2
  fi
  return 1
}

validate_mutable_targets() {
  local target_file
  local target_path

  if [ -L "$PROJECT_ROOT/.agents" ] \
    || [ ! -d "$PROJECT_ROOT/.agents" ]; then
    echo "Error: project .agents directory must remain physical: $PROJECT_ROOT/.agents" >&2
    return 1
  fi
  if [ -L "$TARGET_DIR" ]; then
    echo "Error: template target must not be a symlink: $TARGET_DIR" >&2
    return 1
  fi
  if [ -e "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR" ]; then
    echo "Error: template target is not a directory: $TARGET_DIR" >&2
    return 1
  fi
  if [ -d "$TARGET_DIR" ] \
    && { [ ! -w "$TARGET_DIR" ] || [ ! -x "$TARGET_DIR" ]; }; then
    echo "Error: template target is not writable and searchable: $TARGET_DIR" >&2
    return 1
  fi
  if [ -L "$retired_profile_dir" ]; then
    echo "Error: retired profile path must not be a symlink: $retired_profile_dir" >&2
    return 1
  fi
  if [ -e "$retired_profile_dir" ] && [ ! -d "$retired_profile_dir" ]; then
    echo "Error: retired profile path is not a directory: $retired_profile_dir" >&2
    return 1
  fi
  for target_file in "${target_files[@]}"; do
    target_path="$TARGET_DIR/$target_file"
    if [ -L "$target_path" ]; then
      echo "Error: project template must not be a symlink: $target_path" >&2
      return 1
    fi
    if [ -e "$target_path" ] && [ ! -f "$target_path" ]; then
      echo "Error: project template is not a regular file: $target_path" >&2
      return 1
    fi
  done
}

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "   [Ready] Project documentation candidates passed preflight"
  exit 0
fi

mkdir -p "$PROJECT_ROOT/.agents"
validate_mutable_targets
STAGING_DIR="$(mktemp -d "$PROJECT_ROOT/.agents/.template-stage.XXXXXX")"
STAGING_IDENTITY="$(path_identity "$STAGING_DIR")"
LOCK_DIR="$PROJECT_ROOT/.agents/.template-stage.lock"
LOCK_OWNER_DIR="$LOCK_DIR/owner-$(basename "$STAGING_DIR")"
LOCK_IDENTITY=""
LOCK_OWNER_IDENTITY=""
LOCK_CREATED=0
LOCK_OWNER_CREATED=0
LOCK_CRITICAL=0
PENDING_SIGNAL=0
STAGING_COMPLETE=0
RETIRED_PROFILE_MOVED=0
CANDIDATE_MUTATION_COUNT=0
candidate_preexisted=()
candidate_original_journal=()
candidate_backup_journal=()
candidate_staged_journal=()
candidate_installed_journal=()
candidate_install_committed=()

lock_is_owned() {
  [ "$LOCK_CREATED" -eq 1 ] \
    && [ "$LOCK_OWNER_CREATED" -eq 1 ] \
    && [ -d "$LOCK_DIR" ] \
    && [ ! -L "$LOCK_DIR" ] \
    && [ "$(path_identity "$LOCK_DIR" 2>/dev/null || true)" = "$LOCK_IDENTITY" ] \
    && [ -d "$LOCK_OWNER_DIR" ] \
    && [ ! -L "$LOCK_OWNER_DIR" ] \
    && [ "$(path_identity "$LOCK_OWNER_DIR" 2>/dev/null || true)" = "$LOCK_OWNER_IDENTITY" ]
}

release_lock() {
  local release_status=0

  if [ "$LOCK_CREATED" -eq 0 ]; then
    return 0
  fi
  LOCK_CRITICAL=1
  if [ -z "$LOCK_IDENTITY" ] \
    || [ -L "$LOCK_DIR" ] \
    || [ ! -d "$LOCK_DIR" ] \
    || [ "$(path_identity "$LOCK_DIR" 2>/dev/null || true)" != "$LOCK_IDENTITY" ]; then
    echo "Error: template staging lock changed; refusing to remove it: $LOCK_DIR" >&2
    release_status=1
  fi

  if [ "$release_status" -eq 0 ] && [ "$LOCK_OWNER_CREATED" -eq 1 ]; then
    if [ -L "$LOCK_OWNER_DIR" ] \
      || [ ! -d "$LOCK_OWNER_DIR" ] \
      || [ "$(path_identity "$LOCK_OWNER_DIR" 2>/dev/null || true)" != "$LOCK_OWNER_IDENTITY" ]; then
      echo "Error: template staging lock owner changed; refusing to remove it: $LOCK_OWNER_DIR" >&2
      release_status=1
    elif rmdir "$LOCK_OWNER_DIR"; then
      LOCK_OWNER_CREATED=0
    else
      echo "Error: template staging lock owner is not empty: $LOCK_OWNER_DIR" >&2
      release_status=1
    fi
  fi

  if [ "$release_status" -eq 0 ]; then
    if [ -L "$LOCK_DIR" ] \
      || [ ! -d "$LOCK_DIR" ] \
      || [ "$(path_identity "$LOCK_DIR" 2>/dev/null || true)" != "$LOCK_IDENTITY" ]; then
      echo "Error: template staging lock changed during release: $LOCK_DIR" >&2
      release_status=1
    elif rmdir "$LOCK_DIR"; then
      LOCK_CREATED=0
    else
      echo "Error: template staging lock contains unowned data: $LOCK_DIR" >&2
      release_status=1
    fi
  fi

  finish_lock_critical_section
  return "$release_status"
}

finish_lock_critical_section() {
  LOCK_CRITICAL=0
  if [ "$PENDING_SIGNAL" -ne 0 ]; then
    exit "$PENDING_SIGNAL"
  fi
}

handle_signal() {
  PENDING_SIGNAL="$1"
  if [ "$LOCK_CRITICAL" -eq 0 ]; then
    exit "$PENDING_SIGNAL"
  fi
}

acquire_lock() {
  local attempts=0
  local mkdir_status

  while :; do
    mkdir_status=0
    LOCK_CRITICAL=1
    mkdir "$LOCK_DIR" 2>/dev/null || mkdir_status="$?"
    if [ "$mkdir_status" -eq 0 ]; then
      LOCK_CREATED=1
      if [ -L "$LOCK_DIR" ] || [ ! -d "$LOCK_DIR" ]; then
        finish_lock_critical_section
        echo "Error: template staging lock must be a physical directory: $LOCK_DIR" >&2
        return 1
      fi
      LOCK_IDENTITY="$(path_identity "$LOCK_DIR" 2>/dev/null || true)"
      if [ -z "$LOCK_IDENTITY" ]; then
        finish_lock_critical_section
        echo "Error: could not identify template staging lock: $LOCK_DIR" >&2
        return 1
      fi
      if ! mkdir "$LOCK_OWNER_DIR"; then
        finish_lock_critical_section
        echo "Error: could not establish template staging lock ownership: $LOCK_OWNER_DIR" >&2
        return 1
      fi
      LOCK_OWNER_CREATED=1
      LOCK_OWNER_IDENTITY="$(path_identity "$LOCK_OWNER_DIR" 2>/dev/null || true)"
      if [ -z "$LOCK_OWNER_IDENTITY" ] || ! lock_is_owned; then
        finish_lock_critical_section
        echo "Error: template staging lock changed during acquisition: $LOCK_DIR" >&2
        return 1
      fi
      finish_lock_critical_section
      return 0
    fi
    finish_lock_critical_section

    if [ -L "$LOCK_DIR" ] \
      || { [ -e "$LOCK_DIR" ] && [ ! -d "$LOCK_DIR" ]; }; then
      echo "Error: template staging lock is not a physical directory: $LOCK_DIR" >&2
      return 1
    fi
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 600 ]; then
      echo "Error: timed out waiting for template staging lock: $LOCK_DIR" >&2
      return 1
    fi
    sleep 0.05
  done
}

cleanup() {
  local exit_status="$?"
  local cleanup_status="$exit_status"
  local preserve_stage=0
  local index
  local target_path
  local backup_path
  local quarantine_path
  local rollback_allowed=1

  trap - EXIT
  trap '' INT TERM HUP
  PENDING_SIGNAL=0
  LOCK_CRITICAL=0

  if [ "$STAGING_COMPLETE" -eq 0 ] \
    && { [ "$CANDIDATE_MUTATION_COUNT" -gt 0 ] \
      || [ "$RETIRED_PROFILE_MOVED" -eq 1 ]; } \
    && ! lock_is_owned; then
    rollback_allowed=0
    preserve_stage=1
    echo "Error: template staging lock ownership was lost; refusing to overwrite candidate paths during rollback." >&2
  fi

  if [ "$rollback_allowed" -eq 1 ] \
    && [ "$STAGING_COMPLETE" -eq 0 ] \
    && [ "$CANDIDATE_MUTATION_COUNT" -gt 0 ]; then
    for ((index = 0; index < CANDIDATE_MUTATION_COUNT; index++)); do
      target_path="$TARGET_DIR/${target_files[$index]}"
      backup_path="$STAGING_DIR/previous-candidates/${target_files[$index]}"
      quarantine_path="$STAGING_DIR/rollback-visible/${target_files[$index]}"

      if [ "${candidate_install_committed[$index]:-0}" -eq 1 ]; then
        if [ "$(path_journal "$target_path" 2>/dev/null || true)" \
          != "${candidate_installed_journal[$index]:-}" ]; then
          preserve_stage=1
          continue
        fi
        if ! move_path_no_replace \
          "$target_path" \
          "$quarantine_path" \
          "${candidate_installed_journal[$index]}"; then
          preserve_stage=1
          continue
        fi

        if [ "${candidate_preexisted[$index]:-0}" -eq 1 ]; then
          if [ "$(path_journal "$backup_path" 2>/dev/null || true)" \
            != "${candidate_backup_journal[$index]:-}" ]; then
            preserve_stage=1
            continue
          fi
          if ! move_path_no_replace \
            "$backup_path" \
            "$target_path" \
            "${candidate_backup_journal[$index]}"; then
            preserve_stage=1
          fi
        fi
      elif [ "$(path_journal "$target_path" 2>/dev/null || true)" \
        != "${candidate_original_journal[$index]:-}" ] \
        || [ "$(path_journal "$STAGING_DIR/${target_files[$index]}" 2>/dev/null || true)" \
          != "${candidate_staged_journal[$index]:-}" ]; then
        preserve_stage=1
      fi
    done
  fi

  if [ "$rollback_allowed" -eq 1 ] \
    && [ "$STAGING_COMPLETE" -eq 0 ] \
    && [ "$RETIRED_PROFILE_MOVED" -eq 1 ]; then
    if [ ! -e "$retired_profile_dir" ] \
      && [ ! -L "$retired_profile_dir" ] \
      && [ -d "$STAGING_DIR/retired-profiles" ] \
      && [ ! -L "$STAGING_DIR/retired-profiles" ]; then
      mv "$STAGING_DIR/retired-profiles" "$retired_profile_dir" || preserve_stage=1
    elif [ -d "$retired_profile_dir" ] \
      && [ ! -L "$retired_profile_dir" ] \
      && [ ! -e "$STAGING_DIR/retired-profiles" ] \
      && [ ! -L "$STAGING_DIR/retired-profiles" ]; then
      :
    else
      preserve_stage=1
    fi
  fi
  if ! release_lock; then
    preserve_stage=1
    if [ "$cleanup_status" -eq 0 ]; then
      cleanup_status=1
    fi
  fi
  if [ "$preserve_stage" -eq 0 ] \
    && [ -d "$STAGING_DIR" ] \
    && [ ! -L "$STAGING_DIR" ] \
    && [ "$(path_identity "$STAGING_DIR" 2>/dev/null || true)" = "$STAGING_IDENTITY" ]; then
    rm -rf "$STAGING_DIR"
  elif [ -e "$STAGING_DIR" ] || [ -L "$STAGING_DIR" ]; then
    preserve_stage=1
  fi
  if [ "$preserve_stage" -ne 0 ]; then
    echo "Error: template staging rollback or cleanup could not be completed; recovery data remains at $STAGING_DIR." >&2
  else
    :
  fi
  return "$cleanup_status"
}
trap cleanup EXIT
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM
trap 'handle_signal 129' HUP

acquire_lock
validate_mutable_targets

for index in "${!source_files[@]}"; do
  mkdir -p "$(dirname "$STAGING_DIR/${target_files[$index]}")"
  cp -a \
    "$SOURCE_ROOT/${source_files[$index]}" \
    "$STAGING_DIR/${target_files[$index]}"
  candidate_staged_journal[$index]="$(path_journal "$STAGING_DIR/${target_files[$index]}")"
  if [[ "${candidate_staged_journal[$index]}" != file\|* ]]; then
    echo "Error: staged project template is not a physical file: $STAGING_DIR/${target_files[$index]}" >&2
    exit 1
  fi
done
chmod -R go-w "$STAGING_DIR"

if ! lock_is_owned; then
  echo "Error: template staging lock ownership was lost before candidate snapshot." >&2
  exit 1
fi
mkdir -p \
  "$STAGING_DIR/previous-candidates" \
  "$STAGING_DIR/rollback-visible"
for index in "${!target_files[@]}"; do
  target_path="$TARGET_DIR/${target_files[$index]}"
  candidate_original_journal[$index]="$(path_journal "$target_path")"
  if [ -f "$target_path" ]; then
    cp -a \
      "$target_path" \
      "$STAGING_DIR/previous-candidates/${target_files[$index]}"
    candidate_preexisted[$index]=1
    candidate_backup_journal[$index]="$(path_journal "$STAGING_DIR/previous-candidates/${target_files[$index]}")"
    if [[ "${candidate_backup_journal[$index]}" != file\|* ]] \
      || [ "$(path_journal "$target_path")" != "${candidate_original_journal[$index]}" ]; then
      echo "Error: project template changed while its rollback snapshot was created: $target_path" >&2
      exit 1
    fi
  else
    candidate_preexisted[$index]=0
    candidate_backup_journal[$index]='absent|-|-'
    if [ "${candidate_original_journal[$index]}" != 'absent|-|-' ]; then
      echo "Error: project template changed before its rollback snapshot: $target_path" >&2
      exit 1
    fi
  fi
  candidate_install_committed[$index]=0
done

if [ -d "$retired_profile_dir" ]; then
  if ! lock_is_owned; then
    echo "Error: template staging lock ownership was lost before retiring profiles." >&2
    exit 1
  fi
  RETIRED_PROFILE_MOVED=1
  mv "$retired_profile_dir" "$STAGING_DIR/retired-profiles"
fi

if ! lock_is_owned; then
  echo "Error: template staging lock ownership was lost before creating the candidate directory." >&2
  exit 1
fi
mkdir -p "$TARGET_DIR"
for index in "${!source_files[@]}"; do
  if ! lock_is_owned; then
    echo "Error: template staging lock ownership was lost before candidate commit." >&2
    exit 1
  fi
  target_path="$TARGET_DIR/${target_files[$index]}"
  if [ "$(path_journal "$target_path" 2>/dev/null || true)" \
    != "${candidate_original_journal[$index]}" ]; then
    echo "Error: project template changed before candidate commit: $target_path" >&2
    exit 1
  fi
  if [ "$(path_journal "$STAGING_DIR/${target_files[$index]}" 2>/dev/null || true)" \
    != "${candidate_staged_journal[$index]}" ]; then
    echo "Error: staged project template changed before candidate commit: $STAGING_DIR/${target_files[$index]}" >&2
    exit 1
  fi
  CANDIDATE_MUTATION_COUNT=$((index + 1))
  candidate_install_committed[$index]=0
  candidate_installed_journal[$index]="${candidate_staged_journal[$index]}"
  candidate_move_status=0
  LOCK_CRITICAL=1
  mv -f \
    "$STAGING_DIR/${target_files[$index]}" \
    "$target_path" || candidate_move_status="$?"
  if [ "$(path_journal "$STAGING_DIR/${target_files[$index]}" 2>/dev/null || true)" = 'absent|-|-' ] \
    && [ "$(path_journal "$target_path" 2>/dev/null || true)" \
      = "${candidate_installed_journal[$index]}" ]; then
    candidate_install_committed[$index]=1
    candidate_move_status=0
  fi
  finish_lock_critical_section
  if [ "$candidate_move_status" -ne 0 ]; then
    echo "Error: could not commit project template candidate: $target_path" >&2
    exit "$candidate_move_status"
  fi
  if [ "${candidate_install_committed[$index]}" -ne 1 ]; then
    echo "Error: project template candidate changed during commit: $target_path" >&2
    exit 1
  fi
done
STAGING_COMPLETE=1
release_lock

echo "   [Staged] Project documentation candidates in $TARGET_DIR"
