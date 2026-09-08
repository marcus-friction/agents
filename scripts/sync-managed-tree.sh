#!/usr/bin/env bash

# Overlay a distribution-managed tree without following destination symlinks.
# Existing paths absent from the source are retained for local extensions.

set -euo pipefail
umask 022

CHECK_ONLY=0
EXCLUDED_TOP_LEVEL=()
MV_SUPPORTS_NO_TARGET=0

mv_help="$(command -p mv --help 2>&1 || true)"
if [[ "$mv_help" == *no-target-directory* ]]; then
  MV_SUPPORTS_NO_TARGET=1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --exclude-top-level)
      if [ -z "${2:-}" ]; then
        echo "Error: --exclude-top-level requires a name." >&2
        exit 1
      fi
      if [[ "$2" == */* ]] || [ "$2" = "." ] || [ "$2" = ".." ]; then
        echo "Error: excluded top-level path must be one name: $2" >&2
        exit 1
      fi
      EXCLUDED_TOP_LEVEL+=("$2")
      shift 2
      ;;
    --*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -ne 2 ]; then
  echo "Usage: sync-managed-tree.sh [--check] [--exclude-top-level NAME] SOURCE_DIR TARGET_DIR" >&2
  exit 1
fi

SOURCE_INPUT="$1"
TARGET_INPUT="$2"

if [ -L "$SOURCE_INPUT" ] || [ ! -d "$SOURCE_INPUT" ]; then
  echo "Error: managed source must be a physical directory: $SOURCE_INPUT" >&2
  exit 1
fi

SOURCE_DIR="$(cd "$SOURCE_INPUT" && pwd -P)"
TARGET_PARENT_INPUT="$(dirname "$TARGET_INPUT")"
TARGET_NAME="$(basename "$TARGET_INPUT")"

if [ ! -d "$TARGET_PARENT_INPUT" ]; then
  echo "Error: managed target parent does not exist: $TARGET_PARENT_INPUT" >&2
  exit 1
fi
TARGET_PARENT="$(cd "$TARGET_PARENT_INPUT" && pwd -P)"
TARGET_DIR="$TARGET_PARENT/$TARGET_NAME"

is_excluded_source_path() {
  local source_path="$1"
  local relative_path="${source_path#"$SOURCE_DIR"/}"
  local top_level="${relative_path%%/*}"
  local excluded_name

  for excluded_name in "${EXCLUDED_TOP_LEVEL[@]}"; do
    if [ "$top_level" = "$excluded_name" ]; then
      return 0
    fi
  done
  return 1
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

validate_physical_source_file() {
  local path="$1"
  local parent
  local physical_parent

  if [ -L "$path" ] || [ ! -f "$path" ]; then
    return 1
  fi
  parent="$(dirname "$path")"
  physical_parent="$(cd "$parent" 2>/dev/null && pwd -P)" || return 1
  [ "$physical_parent" = "$parent" ]
}

path_identity() {
  local path="$1"
  local kind
  local metadata

  if [ -L "$path" ]; then
    kind="symlink"
  elif [ -d "$path" ]; then
    kind="directory"
  elif [ -f "$path" ]; then
    kind="file"
  elif [ -e "$path" ]; then
    kind="special"
  else
    printf 'absent\n'
    return 0
  fi

  if metadata="$(command -p stat -c '%d:%i:%u' -- "$path" 2>/dev/null)"; then
    printf '%s:%s\n' "$kind" "$metadata"
  elif metadata="$(command -p stat -f '%d:%i:%u' "$path" 2>/dev/null)"; then
    printf '%s:%s\n' "$kind" "$metadata"
  else
    return 1
  fi
}

snapshot_tree() {
  local root_path="$1"
  local output_path="$2"
  local entry
  local relative_path

  : > "$output_path"
  if [ -L "$root_path" ]; then
    printf 'root-symlink\0%s\0' "$(readlink "$root_path")" > "$output_path"
    return 0
  fi
  if [ ! -e "$root_path" ]; then
    printf 'root-missing\0' > "$output_path"
    return 0
  fi
  if [ ! -d "$root_path" ]; then
    printf 'root-special\0' > "$output_path"
    return 0
  fi

  printf 'root-directory\0' > "$output_path"
  while IFS= read -r -d '' entry; do
    relative_path="${entry#"$root_path"/}"
    if [ -L "$entry" ]; then
      printf 'symlink\0%s\0%s\0' \
        "$relative_path" "$(readlink "$entry")" >> "$output_path"
    elif [ -d "$entry" ]; then
      printf 'directory\0%s\0' "$relative_path" >> "$output_path"
    elif [ -f "$entry" ]; then
      printf 'file\0%s\0%s\0' \
        "$relative_path" "$(hash_file "$entry")" >> "$output_path"
    else
      printf 'special\0%s\0' "$relative_path" >> "$output_path"
    fi
  done < <(find "$root_path" -mindepth 1 -print0)
}

snapshot_target() {
  snapshot_tree "$TARGET_DIR" "$1"
}

move_directory_no_replace() {
  local source="$1"
  local target="$2"
  local expected_identity="$3"
  local move_status=0
  local moved_identity=""
  local restore_status=0

  if [ -L "$source" ] || [ ! -d "$source" ] \
    || [ "$(path_identity "$source" 2>/dev/null || true)" != "$expected_identity" ]; then
    echo "Error: managed-tree move source changed before transition: $source" >&2
    return 1
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "Error: managed-tree move target already exists: $target" >&2
    return 1
  fi

  if [ "$MV_SUPPORTS_NO_TARGET" -eq 1 ]; then
    mv -Tn -- "$source" "$target" || move_status="$?"
  else
    # BSD mv has no -T. The preflight only permits an absent destination; the
    # post-move identity check remains authoritative.
    mv -n -- "$source" "$target" || move_status="$?"
  fi

  if [ ! -e "$source" ] && [ ! -L "$source" ] \
    && [ -d "$target" ] && [ ! -L "$target" ] \
    && [ "$(path_identity "$target" 2>/dev/null || true)" = "$expected_identity" ]; then
    return 0
  fi

  if [ ! -e "$source" ] && [ ! -L "$source" ] \
    && [ -d "$target" ] && [ ! -L "$target" ]; then
    moved_identity="$(path_identity "$target" 2>/dev/null || true)"
    if [ -n "$moved_identity" ] && [ ! -e "$source" ] && [ ! -L "$source" ]; then
      restore_status=0
      if [ "$MV_SUPPORTS_NO_TARGET" -eq 1 ]; then
        mv -Tn -- "$target" "$source" || restore_status="$?"
      else
        mv -n -- "$target" "$source" || restore_status="$?"
      fi
      if [ "$restore_status" -eq 0 ] \
        && [ "$(path_identity "$source" 2>/dev/null || true)" = "$moved_identity" ]; then
        echo "Error: managed-tree transition moved an unexpected replacement and restored it." >&2
        return 1
      fi
    fi
  fi

  if [ "$move_status" -ne 0 ]; then
    echo "Error: managed-tree directory transition failed: $source -> $target" >&2
  else
    echo "Error: managed-tree directory transition was blocked by a changed path: $source -> $target" >&2
  fi
  return 1
}

validate_legal_adoption() {
  local source_legal="$SOURCE_DIR/legal"
  local target_legal="$TARGET_DIR/legal"
  local source_entry
  local target_entry

  if [ ! -e "$source_legal" ]; then
    return 0
  fi
  if [ ! -f "$source_legal/.agents-ecosystem-managed" ]; then
    echo "Error: managed legal source lacks its ownership marker." >&2
    return 1
  fi
  if [ ! -e "$target_legal" ] && [ ! -L "$target_legal" ]; then
    return 0
  fi
  if [ -L "$target_legal" ] || [ ! -d "$target_legal" ]; then
    echo "Error: target legal payload must be a physical directory: $target_legal" >&2
    return 1
  fi
  if [ -f "$target_legal/.agents-ecosystem-managed" ] \
    && [ ! -L "$target_legal/.agents-ecosystem-managed" ] \
    && cmp -s "$source_legal/.agents-ecosystem-managed" \
      "$target_legal/.agents-ecosystem-managed"; then
    return 0
  fi

  while IFS= read -r -d '' source_entry; do
    target_entry="$target_legal/${source_entry##*/}"
    if [ ! -e "$target_entry" ] && [ ! -L "$target_entry" ]; then
      continue
    fi
    if [ -L "$target_entry" ] \
      || [ ! -f "$target_entry" ] \
      || ! cmp -s "$source_entry" "$target_entry"; then
      echo "Error: unmanaged .agents/legal collision: $target_entry" >&2
      return 1
    fi
  done < <(find "$source_legal" -mindepth 1 -maxdepth 1 -type f -print0)
}

if [ -L "$TARGET_INPUT" ]; then
  echo "Error: managed target must not be a symlink: $TARGET_INPUT" >&2
  exit 1
fi
if [ -e "$TARGET_INPUT" ] && [ ! -d "$TARGET_INPUT" ]; then
  echo "Error: managed target is not a directory: $TARGET_INPUT" >&2
  exit 1
fi
if [ ! -w "$TARGET_PARENT" ] || [ ! -x "$TARGET_PARENT" ]; then
  echo "Error: managed target parent is not writable and searchable: $TARGET_PARENT" >&2
  exit 1
fi
if [ -d "$TARGET_INPUT" ] \
  && { [ ! -w "$TARGET_INPUT" ] || [ ! -x "$TARGET_INPUT" ]; }; then
  echo "Error: managed target is not writable and searchable: $TARGET_INPUT" >&2
  exit 1
fi
invalid_source=""
while IFS= read -r -d '' entry; do
  if is_excluded_source_path "$entry"; then
    continue
  fi
  invalid_source="$entry"
  break
done < <(find "$SOURCE_DIR" -mindepth 1 ! -type d ! -type f -print0)

if [ -n "$invalid_source" ]; then
  echo "Error: managed source contains a symlink or special file: $invalid_source" >&2
  exit 1
fi

if [ -d "$TARGET_INPUT" ] && [ "$(cd "$TARGET_INPUT" && pwd -P)" = "$SOURCE_DIR" ]; then
  echo "   [Unchanged] Managed source and target are the same directory"
  exit 0
fi

# Complete collision preflight before creating or replacing anything.
while IFS= read -r -d '' source_path; do
  if is_excluded_source_path "$source_path"; then
    continue
  fi
  relative_path="${source_path#"$SOURCE_DIR"/}"
  target_path="$TARGET_DIR/$relative_path"

  if [ -L "$target_path" ]; then
    echo "Error: managed destination must not be a symlink: $target_path" >&2
    exit 1
  fi
  if [ -d "$source_path" ]; then
    if [ -e "$target_path" ] && [ ! -d "$target_path" ]; then
      echo "Error: managed destination is not a directory: $target_path" >&2
      exit 1
    fi
    if [ -d "$target_path" ] \
      && { [ ! -w "$target_path" ] || [ ! -x "$target_path" ]; }; then
      echo "Error: managed destination directory is not writable and searchable: $target_path" >&2
      exit 1
    fi
  elif [ -e "$target_path" ] && [ ! -f "$target_path" ]; then
    echo "Error: managed destination is not a regular file: $target_path" >&2
    exit 1
  fi
done < <(find "$SOURCE_DIR" -mindepth 1 -print0)

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "   [Ready] Managed-tree destinations passed preflight"
  exit 0
fi

STAGING_DIR="$(mktemp -d "$TARGET_PARENT/.managed-tree-stage.XXXXXX")"
NEXT_DIR="$STAGING_DIR/next"
BACKUP_DIR="$STAGING_DIR/original"
SNAPSHOT_BEFORE="$STAGING_DIR/target-before"
SNAPSHOT_AFTER="$STAGING_DIR/target-after"
SNAPSHOT_COMMIT="$STAGING_DIR/target-at-commit"
SNAPSHOT_QUARANTINED="$STAGING_DIR/target-quarantined"
ORIGINAL_MOVED=0
COMMIT_COMPLETE=0
KEEP_STAGING=0
TARGET_IDENTITY="absent"
NEXT_IDENTITY=""
DEFER_SIGNALS=0
PENDING_SIGNAL=0

handle_signal() {
  local status="$1"
  if [ "$DEFER_SIGNALS" -eq 1 ]; then
    PENDING_SIGNAL="$status"
    return 0
  fi
  exit "$status"
}

begin_transition() {
  DEFER_SIGNALS=1
}

end_transition() {
  local signal_status
  DEFER_SIGNALS=0
  if [ "$PENDING_SIGNAL" -ne 0 ]; then
    signal_status="$PENDING_SIGNAL"
    PENDING_SIGNAL=0
    exit "$signal_status"
  fi
}

cleanup() {
  local status="$?"
  trap - EXIT
  trap '' INT TERM
  set +e

  if [ "$status" -ne 0 ] \
    && [ "$ORIGINAL_MOVED" -eq 1 ] \
    && [ "$COMMIT_COMPLETE" -eq 0 ]; then
    if { [ ! -e "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; } \
      && move_directory_no_replace \
        "$BACKUP_DIR" "$TARGET_DIR" "$TARGET_IDENTITY"; then
      ORIGINAL_MOVED=0
      echo "   [Restored] Prior managed tree after commit failure" >&2
    else
      KEEP_STAGING=1
      echo "Error: automatic restore failed; prior tree retained at $BACKUP_DIR" >&2
    fi
  fi

  if [ "$COMMIT_COMPLETE" -eq 1 ] && [ "$ORIGINAL_MOVED" -eq 1 ]; then
    snapshot_tree "$BACKUP_DIR" "$SNAPSHOT_QUARANTINED.cleanup" || KEEP_STAGING=1
    if [ "$(path_identity "$BACKUP_DIR" 2>/dev/null || true)" != "$TARGET_IDENTITY" ] \
      || ! cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_QUARANTINED.cleanup"; then
      KEEP_STAGING=1
      echo "Error: prior managed tree changed after commit; recovery material retained at $BACKUP_DIR" >&2
    fi
  fi

  if [ "$KEEP_STAGING" -eq 0 ]; then
    rm -rf "$STAGING_DIR"
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM

snapshot_target "$SNAPSHOT_BEFORE"
TARGET_IDENTITY="$(path_identity "$TARGET_DIR")"
validate_legal_adoption
if [ -d "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; then
  cp -a "$TARGET_DIR" "$NEXT_DIR"
else
  mkdir "$NEXT_DIR"
fi

if [ -L "$NEXT_DIR" ] || [ ! -d "$NEXT_DIR" ]; then
  echo "Error: managed target changed to a non-directory during staging: $TARGET_DIR" >&2
  exit 1
fi

while IFS= read -r -d '' source_directory; do
  if is_excluded_source_path "$source_directory"; then
    continue
  fi
  relative_path="${source_directory#"$SOURCE_DIR"/}"
  next_path="$NEXT_DIR/$relative_path"
  if [ -L "$next_path" ]; then
    echo "Error: staged managed destination must not be a symlink: $next_path" >&2
    exit 1
  fi
  mkdir -p "$next_path"
  chmod go-w "$next_path"
done < <(find "$SOURCE_DIR" -mindepth 1 -type d -print0)

while IFS= read -r -d '' source_file; do
  if is_excluded_source_path "$source_file"; then
    continue
  fi
  relative_path="${source_file#"$SOURCE_DIR"/}"
  next_path="$NEXT_DIR/$relative_path"
  if ! validate_physical_source_file "$source_file"; then
    echo "Error: managed source file changed type before copy: $source_file" >&2
    exit 1
  fi
  source_hash="$(hash_file "$source_file")"
  if ! validate_physical_source_file "$source_file"; then
    echo "Error: managed source file changed while it was validated: $source_file" >&2
    exit 1
  fi
  if [ -L "$next_path" ]; then
    echo "Error: staged managed destination must not be a symlink: $next_path" >&2
    exit 1
  fi
  rm -f "$next_path"
  cp "$source_file" "$next_path"
  if [ -L "$next_path" ] || [ ! -f "$next_path" ] \
    || [ "$(hash_file "$next_path" 2>/dev/null || true)" != "$source_hash" ]; then
    rm -f "$next_path"
    echo "Error: staged managed file does not match its validated source snapshot: $source_file" >&2
    exit 1
  fi
done < <(find "$SOURCE_DIR" -mindepth 1 -type f -print0)

snapshot_target "$SNAPSHOT_AFTER"
if ! cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER"; then
  echo "Error: managed target changed during staging; no changes committed: $TARGET_DIR" >&2
  exit 1
fi

snapshot_target "$SNAPSHOT_COMMIT"
if ! cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_COMMIT"; then
  echo "Error: managed target changed immediately before commit; no changes committed: $TARGET_DIR" >&2
  exit 1
fi

NEXT_IDENTITY="$(path_identity "$NEXT_DIR")"
begin_transition
if [ -d "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; then
  if ! move_directory_no_replace \
    "$TARGET_DIR" "$BACKUP_DIR" "$TARGET_IDENTITY"; then
    exit 1
  fi
  ORIGINAL_MOVED=1
  snapshot_tree "$BACKUP_DIR" "$SNAPSHOT_QUARANTINED"
  if [ "$(path_identity "$BACKUP_DIR")" != "$TARGET_IDENTITY" ] \
    || ! cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_QUARANTINED"; then
    echo "Error: managed target changed while it was quarantined; the concurrent tree will be restored." >&2
    exit 1
  fi
elif [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
  echo "Error: managed target changed before commit: $TARGET_DIR" >&2
  exit 1
fi

if [ "$PENDING_SIGNAL" -ne 0 ]; then
  end_transition
fi
if ! move_directory_no_replace "$NEXT_DIR" "$TARGET_DIR" "$NEXT_IDENTITY"; then
  exit 1
fi
COMMIT_COMPLETE=1
end_transition

echo "   [Synced] Upstream-managed tree at $TARGET_DIR"
