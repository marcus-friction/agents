#!/usr/bin/env bash

# Install one verified user-scoped source snapshot. Concurrency is cooperative:
# a sibling lock serializes Agents Ecosystem installers, while unrelated same-user hostile
# mutation is outside this tool's threat model.

set -euo pipefail
umask 077

REPOSITORY_URL="https://github.com/marcus-friction/agents.git"
DEST="" ADAPTERS=all RELEASE_REF="" CHANNEL=edge
STATE_V1=".agents-ecosystem-install-state-v1"
MANIFEST_V1=".agents-ecosystem-content-manifest-v1"
STATE_V2=".agents-ecosystem-install-state-v2"
MANIFEST_V2=".agents-ecosystem-content-manifest-v2"

usage() { echo "Usage: $0 --destination ABSOLUTE-PATH [--adapters NAME[,NAME...]] [--ref 40-character-commit-sha]"; }
error() { echo "Error: $*" >&2; }
need_value() { [ -n "${2:-}" ] || { error "$1 requires a value"; exit 1; }; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --destination) need_value "$1" "${2:-}"; DEST="$2"; shift 2 ;;
    --adapters) need_value "$1" "${2:-}"; ADAPTERS="$2"; shift 2 ;;
    --ref) need_value "$1" "${2:-}"; RELEASE_REF="$2"; CHANNEL=release; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) error "unknown option: $1"; usage >&2; exit 1 ;;
  esac
done

[ -n "$DEST" ] || { error "--destination is required"; exit 1; }
case "$DEST" in /*) ;; *) error "destination must be absolute"; exit 1 ;; esac
case "$DEST" in /|*/|*//*|*/./*|*/.|*/../*|*/..) error "destination must be a normalized child path"; exit 1 ;; esac
[[ "$ADAPTERS" =~ ^(all|[a-z0-9-]+(,[a-z0-9-]+)*)$ ]] || { error "invalid adapter selection"; exit 1; }
[ -z "$RELEASE_REF" ] || [[ "$RELEASE_REF" =~ ^[0-9a-f]{40}$ ]] || { error "--ref requires a full lowercase commit SHA"; exit 1; }

DEST_PARENT="$(dirname "$DEST")"; DEST_BASE="$(basename "$DEST")"
[ ! -L "$DEST_PARENT" ] && [ -d "$DEST_PARENT" ] || { error "destination parent must be a physical directory"; exit 1; }
[ "$(cd "$DEST_PARENT" && pwd -P)" = "$DEST_PARENT" ] || { error "destination path crosses a symlink"; exit 1; }
DEST_PARENT="$(cd "$DEST_PARENT" && pwd -P)"; DEST="$DEST_PARENT/$DEST_BASE"
source "$(dirname "${BASH_SOURCE[0]}")/trusted-path.sh"
require_trusted_parent "$DEST_PARENT"
[ ! -L "$DEST" ] || { error "destination must not be a symlink"; exit 1; }
[ ! -e "$DEST" ] || [ -d "$DEST" ] || { error "destination must be a directory or absent"; exit 1; }

for git_variable in "${!GIT_@}"; do unset "$git_variable"; done
safe_git() {
  GIT_CONFIG=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
  GIT_ASKPASS=/usr/bin/false GIT_NO_REPLACE_OBJECTS=1 GIT_TERMINAL_PROMPT=0 \
  GH_PROMPT_DISABLED=1 SSH_ASKPASS=/usr/bin/false SSH_ASKPASS_REQUIRE=never \
    git --no-replace-objects -c core.hooksPath=/dev/null -c core.fsmonitor=false \
      -c credential.helper= "$@"
}
hash_file() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
file_mode() { stat -c '%a' -- "$1" 2>/dev/null || stat -f '%Lp' "$1"; }
file_uid() { stat -c '%u' -- "$1" 2>/dev/null || stat -f '%u' "$1"; }
state_value() { sed -n "s/^$2=//p" "$1"; }
path_identity() {
  local kind
  if [ -L "$1" ]; then kind=symlink
  elif [ -d "$1" ]; then kind=directory
  elif [ -e "$1" ]; then kind=other
  else echo absent; return 0
  fi
  if stat -c '%d:%i:%u' -- "$1" >/dev/null 2>&1; then
    printf '%s:%s\n' "$kind" "$(stat -c '%d:%i:%u' -- "$1")"
  else
    printf '%s:%s\n' "$kind" "$(stat -f '%d:%i:%u' "$1")"
  fi
}

validate_content_paths() {
  local root="$1" scope="${2:-installed}" invalid
  if [ "$scope" = checkout ]; then
    invalid="$(find "$root" -path "$root/.git" -prune -o -mindepth 1 ! -type d ! -type f -print -quit)"
  else
    invalid="$(find "$root" -mindepth 1 ! -type d ! -type f -print -quit)"
  fi
  [ -z "$invalid" ] || { error "snapshot contains a symlink or special entry: $invalid"; return 1; }
}

write_manifest_v2() {
  local root="$1" output="$2" entry rel
  {
    echo "agents-ecosystem-content-manifest-v2"
    while IFS= read -r -d '' entry; do
      rel="${entry#"$root"/}"
      case "$rel" in "$STATE_V2"|"$MANIFEST_V2") continue ;; esac
      case "$rel" in *$'\t'*|*$'\n'*) error "unsupported snapshot path: $rel"; return 1 ;; esac
      if [ -d "$entry" ]; then
        printf 'directory\t-\t%s\t%s\n' "$(file_mode "$entry")" "$rel"
      else
        printf 'file\t%s\t%s\t%s\n' "$(hash_file "$entry")" "$(file_mode "$entry")" "$rel"
      fi
    done < <(find "$root" -mindepth 1 \( -type d -o -type f \) -print0)
  } > "$output"
  chmod 0600 "$output"
}

write_manifest_v1() {
  local root="$1" output="$2" entry rel
  printf 'agents-ecosystem-content-manifest-v2\0' > "$output"
  while IFS= read -r -d '' entry; do
    rel="${entry#"$root"/}"
    case "$rel" in "$STATE_V1"|"$MANIFEST_V1") continue ;; esac
    if [ -d "$entry" ]; then
      printf 'directory\0\0%s\0%s\0' "$(file_mode "$entry")" "$rel" >> "$output"
    else
      printf 'file\0%s\0%s\0%s\0' \
        "$(hash_file "$entry")" "$(file_mode "$entry")" "$rel" >> "$output"
    fi
  done < <(find "$root" -mindepth 1 \( -type d -o -type f \) -print0)
  chmod 0600 "$output"
}

validate_legacy_checkout() {
  local root="$1" sha tree other entry rel expected mode expected_mode
  [ ! -L "$root/.git" ] && [ -d "$root/.git" ] \
    && [ "$(file_uid "$root")" = "$(id -u)" ] || {
      error "legacy checkout must be physical and caller-owned"; return 1;
    }
  if [ -z "$LEGACY_REFERENCE" ]; then
    sha="$(safe_git -C "$root" rev-parse --verify 'HEAD^{commit}')"
    [[ "$sha" =~ ^[0-9a-f]{40}$ ]] || return 1
    LEGACY_REFERENCE="$STAGE/legacy-reference"
    safe_git init -q "$LEGACY_REFERENCE"
    safe_git -C "$LEGACY_REFERENCE" fetch --depth 1 --no-tags "$REPOSITORY_URL" "$sha"
    safe_git -C "$LEGACY_REFERENCE" checkout --quiet --detach FETCH_HEAD
    [ "$(safe_git -C "$LEGACY_REFERENCE" rev-parse HEAD)" = "$sha" ] || return 1
    LEGACY_SHA="$sha"
  fi
  # Compare physical contents, not the possibly hidden local index state.
  # Local refs, stashes and index data survive in the retained recovery checkout.
  for tree in "$LEGACY_REFERENCE" "$root"; do
    if [ "$tree" = "$root" ]; then other="$LEGACY_REFERENCE"; else other="$root"; fi
    while IFS= read -r -d '' entry; do
      rel="${entry#"$tree"/}"; expected="$other/$rel"
      if [ -L "$entry" ]; then
        [ -L "$expected" ] && [ "$(readlink "$entry")" = "$(readlink "$expected")" ] || {
          error "legacy checkout link differs: $rel"; return 1;
        }
      elif [ -d "$entry" ]; then
        [ ! -L "$expected" ] && [ -d "$expected" ] || {
          error "legacy checkout directory differs: $rel"; return 1;
        }
      elif [ -f "$entry" ]; then
        [ ! -L "$expected" ] && [ -f "$expected" ] && cmp -s "$entry" "$expected" || {
          error "legacy checkout content differs: $rel"; return 1;
        }
        mode="$(file_mode "$entry")"; expected_mode="$(file_mode "$expected")"
        [ $((8#$mode & 0100)) -eq $((8#$expected_mode & 0100)) ] || {
          error "legacy checkout executable mode differs: $rel"; return 1;
        }
      else
        error "legacy checkout has a special entry: $rel"; return 1
      fi
    done < <(find "$tree" -path "$tree/.git" -prune -o -mindepth 1 -print0)
  done
  VALIDATED_SHA="$LEGACY_SHA"; VALIDATED_FORMAT=git
}

validate_snapshot() {
  local root="$1" state manifest actual expected expected_state sha previous channel format
  if [ -d "$root/.git" ] && [ ! -L "$root/.git" ] \
    && [ ! -e "$root/$STATE_V1" ] && [ ! -L "$root/$STATE_V1" ] \
    && [ ! -e "$root/$STATE_V2" ] && [ ! -L "$root/$STATE_V2" ] \
    && [ ! -e "$root/$MANIFEST_V1" ] && [ ! -L "$root/$MANIFEST_V1" ] \
    && [ ! -e "$root/$MANIFEST_V2" ] && [ ! -L "$root/$MANIFEST_V2" ]; then
    validate_legacy_checkout "$root"; return
  fi
  actual="$STAGE/manifest-check"
  if { [ -e "$root/$STATE_V2" ] || [ -L "$root/$STATE_V2" ] \
      || [ -e "$root/$MANIFEST_V2" ] || [ -L "$root/$MANIFEST_V2" ]; }; then
    state="$root/$STATE_V2"; manifest="$root/$MANIFEST_V2"; format=v2
    [ ! -e "$root/$STATE_V1" ] && [ ! -L "$root/$STATE_V1" ] \
      && [ ! -e "$root/$MANIFEST_V1" ] && [ ! -L "$root/$MANIFEST_V1" ] || {
        error "managed snapshot mixes v1 and v2 metadata: $root"; return 1;
      }
  else
    state="$root/$STATE_V1"; manifest="$root/$MANIFEST_V1"; format=v1
  fi
  [ ! -L "$root" ] && [ -d "$root" ] && [ ! -L "$state" ] && [ -f "$state" ] && [ ! -L "$manifest" ] && [ -f "$manifest" ] || {
    error "unmanaged destination will not be replaced: $root"; return 1;
  }
  [ "$(file_mode "$root")" = 700 ] && [ "$(file_mode "$state")" = 600 ] \
    && [ "$(file_mode "$manifest")" = 600 ] || {
      error "managed snapshot and metadata permissions changed locally"; return 1;
    }
  [ "$(file_uid "$root")" = "$(id -u)" ] \
    && [ "$(file_uid "$state")" = "$(id -u)" ] \
    && [ "$(file_uid "$manifest")" = "$(id -u)" ] || {
      error "managed snapshot and metadata must be owned by the invoking user"; return 1;
    }
  sha="$(state_value "$state" sha)"
  previous="$(state_value "$state" previous_sha)"
  channel="$(state_value "$state" channel)"
  [ "$(state_value "$state" format)" = "agents-ecosystem-user-snapshot-$format" ] \
    && [ "$(state_value "$state" source)" = "$REPOSITORY_URL" ] \
    && [[ "$sha" =~ ^[0-9a-f]{40}$ ]] \
    && [[ "$previous" =~ ^$|^[0-9a-f]{40}$ ]] \
    && { [ "$channel" = release ] || [ "$channel" = edge ]; } \
    && [[ "$(state_value "$state" manifest_sha256)" =~ ^[0-9a-f]{64}$ ]] || {
      error "managed snapshot state is invalid: $state"; return 1;
    }
  expected="$(state_value "$state" manifest_sha256)"
  expected_state="$(printf '%s\n' \
    "format=agents-ecosystem-user-snapshot-$format" \
    "source=$REPOSITORY_URL" \
    "sha=$sha" \
    "channel=$channel" \
    "previous_sha=$previous" \
    "manifest_sha256=$expected")"
  [ "$(<"$state")" = "$expected_state" ] || { error "managed snapshot state changed locally"; return 1; }
  [ "$(hash_file "$manifest")" = "$expected" ] || { error "managed snapshot manifest changed locally"; return 1; }
  validate_content_paths "$root"
  if [ "$format" = v2 ]; then write_manifest_v2 "$root" "$actual"; else write_manifest_v1 "$root" "$actual"; fi
  cmp -s "$manifest" "$actual" || { error "managed snapshot changed locally; refusing replacement"; return 1; }
  VALIDATED_SHA="$sha"
  VALIDATED_FORMAT="$format"
}

prepare_candidate() {
  CANDIDATE="$STAGE/candidate"; mkdir "$CANDIDATE"
  safe_git init -q "$CANDIDATE"
  if [ -n "$RELEASE_REF" ]; then
    safe_git -C "$CANDIDATE" fetch --depth 1 --no-tags "$REPOSITORY_URL" "$RELEASE_REF"
  else
    safe_git -C "$CANDIDATE" fetch --no-tags "$REPOSITORY_URL" master
  fi
  safe_git -C "$CANDIDATE" checkout --quiet --detach FETCH_HEAD
  NEW_SHA="$(safe_git -C "$CANDIDATE" rev-parse --verify 'HEAD^{commit}')"
  if [ -z "$RELEASE_REF" ] && [ -n "$CURRENT_SHA" ]; then
    safe_git -C "$CANDIDATE" merge-base --is-ancestor "$CURRENT_SHA" "$NEW_SHA" || {
      error "edge update is not a verified fast-forward; current installation preserved"; return 1;
    }
  fi
  [ -z "$RELEASE_REF" ] || [ "$NEW_SHA" = "$RELEASE_REF" ] || { error "fetched commit does not match --ref"; return 1; }
  [ -z "$(safe_git -C "$CANDIDATE" status --porcelain=v1 --untracked-files=all)" ] || { error "fetched snapshot is not clean"; return 1; }
  [ ! -L "$CANDIDATE/.agents/skills" ] && [ -d "$CANDIDATE/.agents/skills" ] \
    && [ ! -L "$CANDIDATE/scripts/register-skills.sh" ] && [ -f "$CANDIDATE/scripts/register-skills.sh" ] || {
      error "snapshot lacks required physical distribution paths"; return 1;
    }
  while IFS=$'\t' read -r discovery_path discovery_source; do
    if [ -L "$CANDIDATE/$discovery_path" ]; then
      [ "$(readlink "$CANDIDATE/$discovery_path")" = "$discovery_source" ] || {
        error "unexpected repository discovery link"; return 1;
      }
      rm -- "$CANDIDATE/$discovery_path"
    fi
  done < "$(dirname "${BASH_SOURCE[0]}")/snapshot-discovery-links.tsv"
  validate_content_paths "$CANDIDATE" checkout
  rm -rf -- "$CANDIDATE/.git"
  write_manifest_v2 "$CANDIDATE" "$CANDIDATE/$MANIFEST_V2"
  manifest_sha="$(hash_file "$CANDIDATE/$MANIFEST_V2")"
  printf '%s\n' \
    'format=agents-ecosystem-user-snapshot-v2' \
    "source=$REPOSITORY_URL" \
    "sha=$NEW_SHA" \
    "channel=$CHANNEL" \
    "previous_sha=$CURRENT_SHA" \
    "manifest_sha256=$manifest_sha" > "$CANDIDATE/$STATE_V2"
  chmod 0600 "$CANDIDATE/$STATE_V2"
}

rollback_links() {
  local target source parent_id leaf_id extra status=0
  [ -s "$JOURNAL" ] || return 0
  [ ! -L "$JOURNAL" ] && [ -f "$JOURNAL" ] \
    && [ "$(file_mode "$JOURNAL")" = 600 ] || {
      error "registration rollback journal is invalid: $JOURNAL"; return 1;
    }
  while IFS=$'\t' read -r target source parent_id leaf_id extra; do
    [ -n "$target" ] && [ -n "$source" ] && [ -n "$parent_id" ] \
      && [ -n "$leaf_id" ] && [ -z "$extra" ] || { status=1; continue; }
    case "$target" in "$HOME"/*) ;; *) status=1; continue ;; esac
    [ "$source" = "$DEST/.agents/skills" ] || { status=1; continue; }
    if [ "$(path_identity "$(dirname "$target")")" = "$parent_id" ] \
      && [ "$(path_identity "$target")" = "$leaf_id" ] \
      && [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
      rm -f -- "$target" || status=1
    fi
  done < "$JOURNAL"
  return "$status"
}

validate_compatibility_target() {
  local target="$1" ancestor next
  case "$target" in "$HOME"/*) ;; *) error "legacy adapter target escapes HOME: $target"; return 1 ;; esac
  case "$target" in */../*|*/..|*/./*|*/.|*//*|*/) error "legacy adapter target is not normalized: $target"; return 1 ;; esac
  ancestor="$(dirname "$target")"
  while [ "$ancestor" != "$HOME" ]; do
    [ ! -L "$ancestor" ] || { error "legacy adapter target crosses a symlink: $ancestor"; return 1; }
    [ ! -e "$ancestor" ] || [ -d "$ancestor" ] || { error "legacy adapter ancestor is not a directory: $ancestor"; return 1; }
    next="$(dirname "$ancestor")"
    [ "$next" != "$ancestor" ] || { error "legacy adapter target escapes HOME: $target"; return 1; }
    ancestor="$next"
  done
}

enumerate_legacy_user_adapters() {
  local registrar="$1" source="$2" output="$STAGE/legacy-adapter-targets"
  local adapter_dir="$(dirname "$registrar")/skill-adapters"
  : > "$output"; chmod 0600 "$output"
  (
    set -euo pipefail
    local_files=()
    if [ "$ADAPTERS" = all ]; then
      for candidate in "$adapter_dir"/*.sh; do
        [ -f "$candidate" ] && [ ! -L "$candidate" ] && local_files+=("$candidate")
      done
    else
      IFS=',' read -r -a names <<< "$ADAPTERS"
      for name in "${names[@]}"; do
        candidate="$adapter_dir/$name.sh"
        [ -f "$candidate" ] && [ ! -L "$candidate" ] || exit 1
        local_files+=("$candidate")
      done
    fi
    [ "${#local_files[@]}" -gt 0 ]
    for candidate in "${local_files[@]}"; do
      unset -f skill_adapter_supports_scope skill_adapter_target skill_adapter_link_source 2>/dev/null || true
      # shellcheck source=/dev/null
      source "$candidate"
      declare -F skill_adapter_supports_scope >/dev/null
      declare -F skill_adapter_target >/dev/null
      declare -F skill_adapter_link_source >/dev/null
      skill_adapter_supports_scope user || continue
      printf '%s\0%s\0' \
        "$(skill_adapter_target user "$(pwd -P)")" \
        "$(skill_adapter_link_source user "$source")" >> "$output"
    done
  )
  printf '%s\n' "$output"
}

publish_compatibility_link() {
  local target="$1" source="$2" parent parent_id leaf_id index
  local staging staging_id staging_link
  validate_compatibility_target "$target"
  [ "$source" = "$DEST/.agents/skills" ] || { error "legacy adapter source is unexpected: $source"; return 1; }
  parent="$(dirname "$target")"
  mkdir -p "$parent"
  require_trusted_parent "$parent"
  validate_compatibility_target "$target"
  [ "$(cd "$parent" && pwd -P)" = "$parent" ] || { error "legacy adapter parent changed: $parent"; return 1; }
  if [ -e "$target" ] || [ -L "$target" ]; then
    [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ] \
      && return 0
    error "legacy adapter target is already owned: $target"
    return 1
  fi
  parent_id="$(path_identity "$parent")"
  index="${#COMPAT_TARGETS[@]}"
  staging="$(mktemp -d "$parent/.agents-ecosystem-link-stage.XXXXXX")"
  staging_id="$(path_identity "$staging")"
  staging_link="$staging/link"
  COMPAT_TARGETS+=("$target")
  COMPAT_SOURCES+=("$source")
  COMPAT_PARENTS+=("$parent_id")
  COMPAT_LEAVES+=(pending)
  COMPAT_STAGES+=("$staging")
  COMPAT_STAGE_IDS+=("$staging_id")
  ln -s "$source" "$staging_link"
  leaf_id="$(path_identity "$staging_link")"
  COMPAT_LEAVES[$index]="$leaf_id"
  ln -P -n "$staging_link" "$target"
  [ "$(path_identity "$parent")" = "$parent_id" ] \
    && [ "$(path_identity "$target")" = "$leaf_id" ] \
    && [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ] || {
      error "legacy adapter target changed while linking: $target"; return 1;
    }
  rm -f -- "$staging_link"
  rmdir "$staging"
  COMPAT_STAGES[$index]=absent
  printf '%s\t%s\t%s\t%s\n' "$target" "$source" "$parent_id" "$leaf_id" >> "$JOURNAL"
}

rollback_compatibility_links() {
  local i target source parent_id leaf_id staging staging_id staging_link status=0
  for ((i=${#COMPAT_TARGETS[@]}-1; i>=0; i--)); do
    target="${COMPAT_TARGETS[$i]}"; source="${COMPAT_SOURCES[$i]}"
    parent_id="${COMPAT_PARENTS[$i]}"; leaf_id="${COMPAT_LEAVES[$i]}"
    staging="${COMPAT_STAGES[$i]}"; staging_id="${COMPAT_STAGE_IDS[$i]}"
    if [ "$leaf_id" != pending ] \
      && [ "$(path_identity "$(dirname "$target")")" = "$parent_id" ] \
      && [ "$(path_identity "$target")" = "$leaf_id" ] \
      && [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
      rm -f -- "$target" || status=1
    fi
    if [ "$staging" != absent ] && [ "$(path_identity "$staging")" = "$staging_id" ]; then
      staging_link="$staging/link"
      if [ -L "$staging_link" ] \
        && { [ "$leaf_id" = pending ] \
          || [ "$(path_identity "$staging_link")" = "$leaf_id" ]; } \
        && [ "$(readlink "$staging_link")" = "$source" ]; then
        rm -f -- "$staging_link" || status=1
      fi
      rmdir "$staging" 2>/dev/null || status=1
    fi
  done
  return "$status"
}

run_snapshot_registrar() {
  local registrar="$1" source="$2" help_output targets target link_source
  help_output="$(bash "$registrar" --help)"
  if grep -Fq -- '--journal-output' <<< "$help_output"; then
    bash "$registrar" --scope user --source "$source" \
      --adapters "$ADAPTERS" --journal-output "$JOURNAL"
    return
  fi

  bash "$registrar" --scope user --source "$source" \
    --adapters "$ADAPTERS" --preflight-only
  targets="$(enumerate_legacy_user_adapters "$registrar" "$source")"
  exec 4< "$targets"
  while IFS= read -r -d '' target <&4; do
    IFS= read -r -d '' link_source <&4 || {
      exec 4<&-; error "legacy adapter target list is malformed"; return 1;
    }
    publish_compatibility_link "$target" "$link_source"
  done
  exec 4<&-
  bash "$registrar" --scope user --source "$source" --adapters "$ADAPTERS"
}

LOCK="$DEST_PARENT/.${DEST_BASE#.}.agents-ecosystem-install.lock"
mkdir "$LOCK" 2>/dev/null || { error "another installation is in progress: $LOCK"; exit 1; }
STAGE=""
early_cleanup() {
  local status=$?
  trap - EXIT
  set +e
  if [ -n "$STAGE" ] && [ -d "$STAGE" ] && ! rm -rf -- "$STAGE"; then
    error "early installation staging cleanup failed: $STAGE"
    status=1
  fi
  if ! rmdir "$LOCK" 2>/dev/null; then
    error "installation lock cleanup failed: $LOCK"
    status=1
  fi
  exit "$status"
}
trap early_cleanup EXIT
trap 'exit 130' INT TERM
STAGE="$(mktemp -d "$DEST_PARENT/.${DEST_BASE#.}.agents-ecosystem-stage.XXXXXX")"
PRIOR="$STAGE/previous"; JOURNAL="$STAGE/registration-journal"; : > "$JOURNAL"; chmod 0600 "$JOURNAL"
CURRENT_SHA="" CURRENT_FORMAT="" VALIDATED_SHA="" VALIDATED_FORMAT=""
LEGACY_REFERENCE="" LEGACY_SHA=""
ORIGINAL_ID="" CANDIDATE_ID="" ACTIVE_ID=""
HAD_PRIOR=0 ACTIVATED=0 COMPLETE=0
COMPAT_TARGETS=() COMPAT_SOURCES=() COMPAT_PARENTS=() COMPAT_LEAVES=()
COMPAT_STAGES=() COMPAT_STAGE_IDS=()

restore_prior() {
  local nested="$DEST/$(basename "$PRIOR")"
  [ "$(path_identity "$DEST")" = absent ] || {
    error "destination changed during rollback; prior snapshot retained at $PRIOR"; return 1;
  }
  mv "$PRIOR" "$DEST" || { error "prior snapshot retained at $PRIOR"; return 1; }
  [ "$(path_identity "$DEST")" = "$ORIGINAL_ID" ] && return 0
  if [ "$(path_identity "$nested")" = "$ORIGINAL_ID" ]; then
    mv "$nested" "$PRIOR" || error "nested prior snapshot retained at $nested"
  fi
  error "destination changed during rollback; prior snapshot retained at $PRIOR"
  return 1
}

cleanup() {
  local status=$? retain_stage=0 failed="$STAGE/failed-candidate"
  trap - EXIT
  set +e
  if [ "$status" -ne 0 ] && [ "$ACTIVATED" -eq 1 ]; then
    rollback_links || { status=1; retain_stage=1; }
    rollback_compatibility_links || { status=1; retain_stage=1; }
    if [ "$(path_identity "$DEST")" = "$ACTIVE_ID" ]; then
      if ! mv "$DEST" "$failed" || [ "$(path_identity "$failed")" != "$ACTIVE_ID" ]; then
        error "active snapshot could not be isolated during rollback"
        status=1; retain_stage=1
      fi
    else
      error "active destination changed during rollback; concurrent content was preserved"
      status=1; retain_stage=1
    fi
  fi
  if [ "$status" -ne 0 ] && [ "$HAD_PRIOR" -eq 1 ]; then
    if [ "$(path_identity "$DEST")" = absent ] \
      && [ "$(path_identity "$PRIOR")" = "$ORIGINAL_ID" ]; then
      restore_prior || { status=1; retain_stage=1; }
    elif [ "$(path_identity "$DEST")" = "$ORIGINAL_ID" ] \
      && [ "$(path_identity "$PRIOR")" = absent ]; then
      HAD_PRIOR=0
    else
      error "destination changed before rollback; prior snapshot retained at $PRIOR"
      status=1; retain_stage=1
    fi
  fi
  if [ "$COMPLETE" -eq 1 ] && [ "$CURRENT_FORMAT" = git ] && [ -d "$PRIOR" ]; then
    recovery="$(mktemp -d "$DEST_PARENT/${DEST_BASE}.legacy-XXXXXX")"
    if [ -n "$recovery" ] && mv "$PRIOR" "$recovery/previous"; then
      echo "=> Previous Git checkout retained for recovery at $recovery/previous."
    else
      error "legacy recovery retained at $PRIOR"; status=1; retain_stage=1
    fi
  fi
  if [ "$COMPLETE" -eq 1 ] && [ -d "$PRIOR" ] \
    && [ "$CURRENT_FORMAT" != git ] \
    && [ "$(path_identity "$PRIOR")" = "$ORIGINAL_ID" ] \
    && ! rm -rf -- "$PRIOR"; then
    error "prior snapshot cleanup failed; recovery retained at $PRIOR"
    status=1; retain_stage=1
  fi
  if [ "$retain_stage" -eq 0 ] && [ -d "$STAGE" ] \
    && ! rm -rf -- "$STAGE"; then
    error "installation staging cleanup failed: $STAGE"
    status=1
  fi
  if ! rmdir "$LOCK" 2>/dev/null; then
    error "installation lock cleanup failed: $LOCK"
    status=1
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

if [ -d "$DEST" ]; then
  validate_snapshot "$DEST"
  CURRENT_SHA="$VALIDATED_SHA"; CURRENT_FORMAT="$VALIDATED_FORMAT"
  ORIGINAL_ID="$(path_identity "$DEST")"
fi
prepare_candidate

if [ "$CURRENT_FORMAT" = v2 ] && [ "$CURRENT_SHA" = "$NEW_SHA" ]; then
  validate_snapshot "$DEST"
  [ "$(path_identity "$DEST")" = "$ORIGINAL_ID" ] || { error "destination changed during update"; exit 1; }
  rm -rf -- "$CANDIDATE"
  bash "$DEST/scripts/register-skills.sh" --scope user --source "$DEST/.agents/skills" --adapters "$ADAPTERS"
  validate_snapshot "$DEST"
  [ "$(path_identity "$DEST")" = "$ORIGINAL_ID" ] || { error "destination changed during registration"; exit 1; }
  COMPLETE=1
  echo "=> User snapshot already current at $NEW_SHA; discovery links reconciled."
  exit 0
fi

if [ -d "$DEST" ]; then
  validate_snapshot "$DEST"
  [ "$(path_identity "$DEST")" = "$ORIGINAL_ID" ] || { error "destination changed during update"; exit 1; }
  HAD_PRIOR=1
  mv "$DEST" "$PRIOR"
  [ "$(path_identity "$PRIOR")" = "$ORIGINAL_ID" ] || { error "destination changed while being isolated"; exit 1; }
fi
CANDIDATE_ID="$(path_identity "$CANDIDATE")"
mv "$CANDIDATE" "$DEST"
if [ "$(path_identity "$DEST")" != "$CANDIDATE_ID" ]; then
  nested="$DEST/$(basename "$CANDIDATE")"
  if [ "$(path_identity "$nested")" = "$CANDIDATE_ID" ]; then
    mv "$nested" "$CANDIDATE" || error "nested candidate retained at $nested"
  fi
  error "destination changed during activation; concurrent content was preserved"
  exit 1
fi
ACTIVE_ID="$CANDIDATE_ID"; ACTIVATED=1
run_snapshot_registrar "$DEST/scripts/register-skills.sh" "$DEST/.agents/skills"
validate_snapshot "$DEST"
COMPLETE=1
echo "=> Installed verified user snapshot $NEW_SHA at $DEST."
