#!/usr/bin/env bash

# Cooperatively synchronize a distribution-managed tree. The target-local state
# records exactly which files the distribution owns; other paths are preserved.

set -euo pipefail
umask 022

CHECK_ONLY=0
LEGACY_MANIFEST=""
EXCLUDED=()
STATE_V1=".agents-ecosystem-managed-state-v1"
STATE_V2=".agents-ecosystem-managed-state-v2"

usage() {
  echo "Usage: $0 [--check] [--exclude-top-level NAME] SOURCE_DIR TARGET_DIR" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1; shift ;;
    --legacy-manifest)
      [ -n "${2:-}" ] || exit 1
      LEGACY_MANIFEST="$2"; shift 2 ;;
    --exclude-top-level)
      [ -n "${2:-}" ] && [[ "$2" != */* ]] && [ "$2" != "." ] && [ "$2" != ".." ] || {
        echo "Error: --exclude-top-level requires one safe name." >&2; exit 1;
      }
      EXCLUDED+=("$2"); shift 2 ;;
    --*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *) break ;;
  esac
done
[ "$#" -eq 2 ] || { usage; exit 1; }

SOURCE_INPUT="$1"
TARGET_INPUT="$2"
[ ! -L "$SOURCE_INPUT" ] && [ -d "$SOURCE_INPUT" ] || {
  echo "Error: managed source must be a physical directory: $SOURCE_INPUT" >&2; exit 1;
}
SOURCE_DIR="$(cd "$SOURCE_INPUT" && pwd -P)"
case "$SOURCE_INPUT" in
  /*) SOURCE_EXPECTED="${SOURCE_INPUT%/}" ;;
  ./*) SOURCE_EXPECTED="$(pwd -P)/${SOURCE_INPUT#./}" ;;
  *) SOURCE_EXPECTED="$(pwd -P)/$SOURCE_INPUT" ;;
esac
[ "$SOURCE_DIR" = "$SOURCE_EXPECTED" ] || {
  echo "Error: managed source must use a normalized physical path: $SOURCE_INPUT" >&2; exit 1;
}

case "$TARGET_INPUT" in
  ""|/|.|..|*/|*//*|*/./*|*/.|*/../*|*/..) echo "Error: target must be a normalized child path: $TARGET_INPUT" >&2; exit 1 ;;
esac
TARGET_PARENT_INPUT="$(dirname "$TARGET_INPUT")"
TARGET_NAME="$(basename "$TARGET_INPUT")"
[ ! -L "$TARGET_PARENT_INPUT" ] && [ -d "$TARGET_PARENT_INPUT" ] || {
  echo "Error: target parent must be a physical directory: $TARGET_PARENT_INPUT" >&2; exit 1;
}
TARGET_PARENT="$(cd "$TARGET_PARENT_INPUT" && pwd -P)"
case "$TARGET_PARENT_INPUT" in
  .) TARGET_PARENT_EXPECTED="$(pwd -P)" ;;
  /*) TARGET_PARENT_EXPECTED="${TARGET_PARENT_INPUT%/}" ;;
  ./*) TARGET_PARENT_EXPECTED="$(pwd -P)/${TARGET_PARENT_INPUT#./}" ;;
  *) TARGET_PARENT_EXPECTED="$(pwd -P)/$TARGET_PARENT_INPUT" ;;
esac
[ "$TARGET_PARENT" = "$TARGET_PARENT_EXPECTED" ] || {
  echo "Error: managed target path crosses a symlink or is not normalized: $TARGET_INPUT" >&2; exit 1;
}
TARGET_DIR="$TARGET_PARENT/$TARGET_NAME"
[ ! -L "$TARGET_DIR" ] || { echo "Error: managed target must not be a symlink: $TARGET_DIR" >&2; exit 1; }
[ ! -e "$TARGET_DIR" ] || [ -d "$TARGET_DIR" ] || {
  echo "Error: managed target is not a directory: $TARGET_DIR" >&2; exit 1;
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

file_mode() {
  stat -c '%a' -- "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

stat_metadata() {
  stat -c '%a:%u:%g' -- "$1" 2>/dev/null || stat -f '%Lp:%u:%g' "$1"
}

path_identity() {
  local kind
  if [ -L "$1" ]; then kind=symlink
  elif [ -d "$1" ]; then kind=directory
  elif [ -e "$1" ]; then kind=other
  else echo absent; return 0
  fi
  if stat -c '%d:%i' -- "$1" >/dev/null 2>&1; then
    printf '%s:%s\n' "$kind" "$(stat -c '%d:%i' -- "$1")"
  else
    printf '%s:%s\n' "$kind" "$(stat -f '%d:%i' "$1")"
  fi
}

snapshot_target() {
  local output="$1" root="${2:-$TARGET_DIR}" entry rel
  : > "$output"
  if [ -L "$root" ]; then printf 'root-symlink\0%s\0' "$(readlink "$root")" > "$output"; return; fi
  if [ ! -e "$root" ]; then printf 'root-missing\0' > "$output"; return; fi
  if [ ! -d "$root" ]; then printf 'root-special\0' > "$output"; return; fi
  printf 'root-directory\0%s\0' "$(stat_metadata "$root")" > "$output"
  while IFS= read -r -d '' entry; do
    rel="${entry#"$root"/}"
    if [ -L "$entry" ]; then
      printf 'symlink\0%s\0%s\0%s\0' "$rel" "$(readlink "$entry")" "$(stat_metadata "$entry")" >> "$output"
    elif [ -d "$entry" ]; then
      printf 'directory\0%s\0%s\0' "$rel" "$(stat_metadata "$entry")" >> "$output"
    elif [ -f "$entry" ]; then
      printf 'file\0%s\0%s\0%s\0' "$rel" "$(hash_file "$entry")" "$(stat_metadata "$entry")" >> "$output"
    else
      printf 'special\0%s\0' "$rel" >> "$output"
    fi
  done < <(find "$root" -mindepth 1 -print0)
}

is_excluded() {
  local rel="$1" top="${1%%/*}" name
  for name in "${EXCLUDED[@]}"; do [ "$top" = "$name" ] && return 0; done
  return 1
}

valid_rel() {
  case "$1" in ""|/*|./*|../*|*//*|*/./*|*/../*|*/.|*/..|*$'\t'*|*$'\n'*) return 1 ;; esac
  [ "$1" != "$STATE_V1" ] && [ "$1" != "$STATE_V2" ]
}

validate_physical_ancestors() {
  local root="$1" rel="$2" parent current part
  local -a parts
  parent="${rel%/*}"
  [ "$parent" != "$rel" ] || return 0
  current="$root"
  IFS='/' read -r -a parts <<< "$parent"
  for part in "${parts[@]}"; do
    current="$current/$part"
    [ ! -L "$current" ] || {
      echo "Error: managed destination crosses a symlink: $current" >&2; return 1;
    }
    [ ! -e "$current" ] || [ -d "$current" ] || {
      echo "Error: managed destination ancestor is not a directory: $current" >&2; return 1;
    }
  done
}

validate_tree() {
  local root="$1" entry rel
  while IFS= read -r -d '' entry; do
    rel="${entry#"$root"/}"
    valid_rel "$rel" || { echo "Error: unsupported managed path: $rel" >&2; return 1; }
    if [ -L "$entry" ] || { [ ! -d "$entry" ] && [ ! -f "$entry" ]; }; then
      echo "Error: managed trees may contain only physical files and directories: $entry" >&2
      return 1
    fi
  done < <(find "$root" -mindepth 1 -print0)
}

validate_tree "$SOURCE_DIR"
for reserved in "$STATE_V1" "$STATE_V2"; do
  [ ! -e "$SOURCE_DIR/$reserved" ] && [ ! -L "$SOURCE_DIR/$reserved" ] || {
    echo "Error: source uses reserved state path: $reserved" >&2; exit 1;
  }
done

if [ -d "$TARGET_DIR" ] && [ "$(cd "$TARGET_DIR" && pwd -P)" = "$SOURCE_DIR" ]; then
  echo "   [Unchanged] Managed source and target are the same directory"
  exit 0
fi

LOCK="$TARGET_PARENT/.$TARGET_NAME.agents-ecosystem-sync.lock"
if [ "$CHECK_ONLY" -eq 0 ]; then
  if ! mkdir "$LOCK" 2>/dev/null; then
    echo "Error: another managed-tree update is in progress: $LOCK" >&2; exit 1
  fi
  release_lock() {
    local status=$?
    if ! rmdir "$LOCK" 2>/dev/null; then
      echo "Error: managed-tree lock cleanup failed: $LOCK" >&2
      status=1
    fi
    exit "$status"
  }
  trap release_lock EXIT
  trap 'exit 130' INT TERM
fi

declare -a OLD_PATHS=() OLD_HASHES=() OLD_MODES=()
STATE_PATH=""
if [ -e "$TARGET_DIR/$STATE_V2" ] || [ -L "$TARGET_DIR/$STATE_V2" ]; then
  STATE_PATH="$TARGET_DIR/$STATE_V2"
elif [ -e "$TARGET_DIR/$STATE_V1" ] || [ -L "$TARGET_DIR/$STATE_V1" ]; then
  STATE_PATH="$TARGET_DIR/$STATE_V1"
fi

old_contains() {
  local requested="$1" existing
  for existing in "${OLD_PATHS[@]}"; do [ "$existing" = "$requested" ] && return 0; done
  return 1
}

add_old() {
  local hash="$1" mode="$2" rel="$3" index="${#OLD_PATHS[@]}"
  valid_rel "$rel" && [[ "$hash" =~ ^[0-9a-f]+$ ]] && [[ "$mode" =~ ^[0-7]+$ ]] && ! old_contains "$rel" || {
    echo "Error: invalid or duplicate managed-state record." >&2; return 1;
  }
  case "$rel" in project|project/*|rules|rules/*|templates|templates/*)
    echo "Error: managed state claims protected project content: $rel" >&2; return 1 ;;
  esac
  if is_excluded "$rel"; then
    echo "Error: managed state claims excluded content: $rel" >&2; return 1
  fi
  OLD_PATHS+=("$rel"); OLD_HASHES+=("$hash"); OLD_MODES+=("$mode")
}

if [ -n "$STATE_PATH" ]; then
  [ ! -L "$STATE_PATH" ] && [ -f "$STATE_PATH" ] || { echo "Error: managed state must be a physical file." >&2; exit 1; }
  case "$(file_mode "$STATE_PATH")" in
    600|644) ;;
    *) echo "Error: managed state mode must remain 0600 or 0644: $STATE_PATH" >&2; exit 1 ;;
  esac
  if [ "${STATE_PATH##*/}" = "$STATE_V2" ]; then
    IFS= read -r header < "$STATE_PATH"
    [ "$header" = "agents-ecosystem-managed-state-v2" ] || { echo "Error: invalid managed-state header." >&2; exit 1; }
    while IFS=$'\t' read -r hash mode rel extra; do
      [ -n "$hash$mode$rel$extra" ] || continue
      [ -z "$extra" ] || { echo "Error: invalid managed-state record." >&2; exit 1; }
      add_old "$hash" "$mode" "$rel"
    done < <(sed '1d' "$STATE_PATH")
  else
    exec 3<"$STATE_PATH"
    IFS= read -r -d '' header <&3 || true
    [ "$header" = "agents-ecosystem-managed-state-v1" ] || { exec 3<&-; echo "Error: invalid legacy managed-state header." >&2; exit 1; }
    while IFS= read -r -d '' hash <&3; do
      IFS= read -r -d '' mode <&3 && IFS= read -r -d '' rel <&3 || {
        exec 3<&-; echo "Error: partial legacy managed-state record." >&2; exit 1;
      }
      add_old "$hash" "$mode" "$rel"
    done
    exec 3<&-
  fi
fi

if [ -z "$STATE_PATH" ] && [ -n "$LEGACY_MANIFEST" ]; then
  [ ! -L "$LEGACY_MANIFEST" ] && [ -f "$LEGACY_MANIFEST" ] || {
    echo "Error: legacy inventory must be a physical file" >&2; exit 1;
  }
  while IFS=$'\t' read -r hash mode rel extra; do
    case "$hash" in \#*|'') continue ;; esac
    [ -z "$extra" ] && valid_rel "$rel" || exit 1
    case "$rel" in skills/*|tools/*|legal/*|.*-plugin/*) ;; *) exit 1 ;; esac
    if [ -e "$TARGET_DIR/$rel" ] || [ -L "$TARGET_DIR/$rel" ]; then
      validate_physical_ancestors "$TARGET_DIR" "$rel" || exit 1
      if [ ! -L "$TARGET_DIR/$rel" ] && [ -f "$TARGET_DIR/$rel" ]; then
        actual_mode="$(file_mode "$TARGET_DIR/$rel")"
        # Git tracks owner-executable state, while checkout permissions depend
        # on the original umask. Retain the observed mode in the adopted state.
        mode_bits=$((8#$actual_mode))
        if [ $((mode_bits & 07000)) -eq 0 ] \
          && [ $((mode_bits & 0600)) -eq 384 ] \
          && { { [ "$mode" = 644 ] && [ $((mode_bits & 0111)) -eq 0 ]; } \
            || { [ "$mode" = 755 ] && [ $((mode_bits & 0100)) -ne 0 ]; }; } \
          && [ "$(hash_file "$TARGET_DIR/$rel")" = "$hash" ]; then
          add_old "$hash" "$actual_mode" "$rel"
          continue
        fi
      fi
      # No previous state proves this path was ours. Preserve it; the ordinary
      # collision check below blocks if the new source would overwrite it.
      echo "   [Preserved] Unverified legacy path: $rel"
    fi
  done < "$LEGACY_MANIFEST"
fi

# Confirm that every previously managed path is unchanged. This is the ownership
# boundary: a local edit blocks refresh instead of being overwritten.
for i in "${!OLD_PATHS[@]}"; do
  rel="${OLD_PATHS[$i]}"; path="$TARGET_DIR/$rel"
  validate_physical_ancestors "$TARGET_DIR" "$rel" || exit 1
  [ ! -L "$path" ] && [ -f "$path" ] \
    && [ "$(hash_file "$path")" = "${OLD_HASHES[$i]}" ] \
    && [ "$(file_mode "$path")" = "${OLD_MODES[$i]}" ] || {
      echo "Error: managed path changed locally since installation: $path" >&2; exit 1;
    }
done

# Preflight source collisions and physical target ancestors.
while IFS= read -r -d '' source_path; do
  rel="${source_path#"$SOURCE_DIR"/}"; is_excluded "$rel" && continue
  target_path="$TARGET_DIR/$rel"
  current="$TARGET_DIR"
  IFS='/' read -r -a parts <<< "$rel"
  for part in "${parts[@]}"; do
    current="$current/$part"
    [ ! -L "$current" ] || { echo "Error: managed destination crosses a symlink: $current" >&2; exit 1; }
  done
  if [ -f "$source_path" ] && [ -e "$target_path" ] && ! old_contains "$rel"; then
    echo "Error: upstream path collides with a local extension: $target_path" >&2; exit 1
  fi
  if [ -d "$source_path" ] && [ -e "$target_path" ] && [ ! -d "$target_path" ]; then
    echo "Error: managed destination is not a directory: $target_path" >&2; exit 1
  fi
done < <(find "$SOURCE_DIR" -mindepth 1 -print0)

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "   [Ready] Managed-tree destinations passed preflight"
  exit 0
fi

STAGE="$(mktemp -d "$TARGET_PARENT/.$TARGET_NAME.agents-ecosystem-stage.XXXXXX")"
NEXT="$STAGE/next"; BACKUP="$STAGE/previous"; mkdir "$NEXT"
SNAPSHOT_BEFORE="$STAGE/target-before"; SNAPSHOT_AFTER="$STAGE/target-after"
SNAPSHOT_COMMIT="$STAGE/target-commit"; SNAPSHOT_MOVED="$STAGE/target-moved"
ORIGINAL_ID="$(path_identity "$TARGET_DIR")"; NEXT_ID=""
BACKUP_MOVED=0; ACTIVATION_STARTED=0; KEEP_STAGE=0

restore_backup() {
  local nested="$TARGET_DIR/$(basename "$BACKUP")"
  [ "$(path_identity "$TARGET_DIR")" = absent ] || return 1
  mv "$BACKUP" "$TARGET_DIR" || return 1
  [ "$(path_identity "$TARGET_DIR")" = "$ORIGINAL_ID" ] && return 0
  if [ "$(path_identity "$nested")" = "$ORIGINAL_ID" ]; then
    mv "$nested" "$BACKUP" || true
  fi
  return 1
}

cleanup() {
  local status=$?
  trap - EXIT
  set +e
  if [ "$status" -ne 0 ] && [ "$ACTIVATION_STARTED" -eq 1 ] \
    && [ "$(path_identity "$TARGET_DIR")" = "$NEXT_ID" ]; then
    if mv "$TARGET_DIR" "$NEXT" && [ "$(path_identity "$NEXT")" = "$NEXT_ID" ]; then
      ACTIVATION_STARTED=0
    else
      echo "Error: activated managed tree could not be isolated; recovery retained at $BACKUP" >&2
      KEEP_STAGE=1
    fi
  fi
  if [ "$status" -ne 0 ] && [ "$BACKUP_MOVED" -eq 1 ]; then
    if [ "$(path_identity "$BACKUP")" = "$ORIGINAL_ID" ] && restore_backup; then
      BACKUP_MOVED=0
      echo "   [Restored] Prior managed tree after activation failure" >&2
    elif [ "$(path_identity "$TARGET_DIR")" = "$ORIGINAL_ID" ] \
      && [ "$(path_identity "$BACKUP")" = absent ]; then
      BACKUP_MOVED=0
    else
      echo "Error: automatic restore failed; prior tree retained at $BACKUP" >&2
      KEEP_STAGE=1
    fi
  fi
  if [ "$KEEP_STAGE" -eq 0 ] && [ -d "$STAGE" ] \
    && ! rm -rf -- "$STAGE"; then
    echo "Error: managed-tree staging cleanup failed: $STAGE" >&2
    status=1
  fi
  if ! rmdir "$LOCK" 2>/dev/null; then
    echo "Error: managed-tree lock cleanup failed: $LOCK" >&2
    status=1
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

snapshot_target "$SNAPSHOT_BEFORE"
if [ -d "$TARGET_DIR" ]; then cp -a "$TARGET_DIR/." "$NEXT/"; fi
rm -f -- "$NEXT/$STATE_V1" "$NEXT/$STATE_V2"
for rel in "${OLD_PATHS[@]}"; do
  validate_physical_ancestors "$NEXT" "$rel" || exit 1
  rm -f -- "$NEXT/$rel"
done
find "$NEXT" -mindepth 1 -depth -type d -empty -delete

while IFS= read -r -d '' source_path; do
  rel="${source_path#"$SOURCE_DIR"/}"; is_excluded "$rel" && continue
  if [ -d "$source_path" ]; then
    mkdir -p "$NEXT/$rel"
    chmod go-w "$NEXT/$rel"
  else
    mkdir -p "$(dirname "$NEXT/$rel")"
    cp -p "$source_path" "$NEXT/$rel"
    chmod go-w "$NEXT/$rel"
  fi
done < <(find "$SOURCE_DIR" -mindepth 1 -print0)

{
  echo "agents-ecosystem-managed-state-v2"
  while IFS= read -r -d '' path; do
    rel="${path#"$SOURCE_DIR"/}"; is_excluded "$rel" && continue
    printf '%s\t%s\t%s\n' "$(hash_file "$NEXT/$rel")" "$(file_mode "$NEXT/$rel")" "$rel"
  done < <(find "$SOURCE_DIR" -type f -print0)
} > "$NEXT/$STATE_V2"
chmod 0644 "$NEXT/$STATE_V2"

snapshot_target "$SNAPSHOT_AFTER"
cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_AFTER" || {
  echo "Error: managed target changed during staging; no changes committed: $TARGET_DIR" >&2; exit 1;
}
snapshot_target "$SNAPSHOT_COMMIT"
cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_COMMIT" || {
  echo "Error: managed target changed immediately before commit; no changes committed: $TARGET_DIR" >&2; exit 1;
}
[ "$(path_identity "$TARGET_DIR")" = "$ORIGINAL_ID" ] || {
  echo "Error: managed target identity changed before commit: $TARGET_DIR" >&2; exit 1;
}
if [ -d "$TARGET_DIR" ] && [ ! -L "$TARGET_DIR" ]; then
  BACKUP_MOVED=1
  mv "$TARGET_DIR" "$BACKUP"
  [ "$(path_identity "$BACKUP")" = "$ORIGINAL_ID" ] || {
    echo "Error: managed target changed while being isolated: $TARGET_DIR" >&2; exit 1;
  }
  snapshot_target "$SNAPSHOT_MOVED" "$BACKUP"
  cmp -s "$SNAPSHOT_BEFORE" "$SNAPSHOT_MOVED" || {
    echo "Error: managed target changed after the final comparison; prior content will be restored." >&2; exit 1;
  }
elif [ -e "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
  echo "Error: managed target changed before activation: $TARGET_DIR" >&2
  exit 1
fi
NEXT_ID="$(path_identity "$NEXT")"; ACTIVATION_STARTED=1
mv "$NEXT" "$TARGET_DIR"
if [ "$(path_identity "$TARGET_DIR")" != "$NEXT_ID" ]; then
  nested="$TARGET_DIR/$(basename "$NEXT")"
  if [ "$(path_identity "$nested")" = "$NEXT_ID" ]; then
    mv "$nested" "$NEXT" || true
  fi
  echo "Error: managed target changed during activation; concurrent content was preserved" >&2
  exit 1
fi
ACTIVATION_STARTED=0
if [ "$BACKUP_MOVED" -eq 1 ]; then
  [ "$(path_identity "$BACKUP")" = "$ORIGINAL_ID" ] || {
    echo "Error: prior managed tree changed before cleanup: $BACKUP" >&2; exit 1;
  }
  BACKUP_MOVED=0
  if ! rm -rf -- "$BACKUP"; then
    KEEP_STAGE=1
    echo "Error: backup cleanup failed; verified new tree remains active and recovery is retained at $BACKUP" >&2
    exit 1
  fi
fi
echo "   [Updated] Managed tree at $TARGET_DIR"
