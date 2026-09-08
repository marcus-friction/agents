#!/usr/bin/env bash
# Register the canonical .agents/skills directory with installed agent tools.
# Provider paths are defined by scripts/skill-adapters/*.sh so the canonical
# skill content and generic installers do not need vendor-specific knowledge.

set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTER_DIR="$SCRIPT_DIR/skill-adapters"
DISTRIBUTION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SCOPE="project"
PROJECT_ROOT="$(pwd)"
SKILLS_SOURCE=""
REQUESTED_ADAPTERS="all"
PREFLIGHT_ONLY=0
ATOMIC_USER_LINKS=0
ATOMIC_USER_LINKS_COMPLETE=0
ATOMIC_ORIGINAL_TARGET_IDS=()
ATOMIC_ORIGINAL_TARGET_LINKS=()
ATOMIC_ORIGINAL_PARENT_IDS=()
ATOMIC_CREATED_TARGET_IDS=()
ATOMIC_CREATED_TARGET_LINKS=()
ATOMIC_CREATED_PARENT_IDS=()
ATOMIC_TARGET_ACTIVE=()
ATOMIC_STAGE_DIRS=()
ATOMIC_STAGE_DIR_IDS=()
ATOMIC_STAGE_ANCHORS=()
ATOMIC_DEFER_SIGNALS=0
ATOMIC_PENDING_SIGNAL=0
MOVE_NO_REPLACE_MODE=""

usage() {
  cat <<'EOF'
Usage: register-skills.sh [options]

Options:
  --scope project|user       Registration scope (default: project)
  --project-root PATH        Project root for project-scoped adapters
  --source PATH              Canonical .agents/skills directory
  --adapters NAME[,NAME...]  Register selected adapters (default: all)
  --preflight-only           Validate every target without changing anything
  --atomic-user-links        Atomically register user links; skip configure hooks
  -h, --help                 Show this help
EOF
}

require_option_value() {
  local option="$1"
  local value="${2:-}"

  if [ -z "$value" ]; then
    echo "Error: $option requires a value." >&2
    usage >&2
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope)
      require_option_value "$1" "${2:-}"
      SCOPE="${2:-}"
      shift 2
      ;;
    --project-root)
      require_option_value "$1" "${2:-}"
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --source)
      require_option_value "$1" "${2:-}"
      SKILLS_SOURCE="${2:-}"
      shift 2
      ;;
    --adapters)
      require_option_value "$1" "${2:-}"
      REQUESTED_ADAPTERS="${2:-}"
      shift 2
      ;;
    --preflight-only)
      PREFLIGHT_ONLY=1
      shift
      ;;
    --atomic-user-links)
      ATOMIC_USER_LINKS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$SCOPE" in
  project|user) ;;
  *)
    echo "Error: --scope must be 'project' or 'user'." >&2
    exit 1
    ;;
esac

if [ "$ATOMIC_USER_LINKS" -eq 1 ] && [ "$SCOPE" != "user" ]; then
  echo "Error: --atomic-user-links requires --scope user." >&2
  exit 1
fi

USER_ROOT=""
if [ "$SCOPE" = "user" ]; then
  if [ -z "${HOME:-}" ] || [ -L "$HOME" ] || [ ! -d "$HOME" ]; then
    echo "Error: user registration root must be a physical directory: ${HOME:-<unset>}" >&2
    exit 1
  fi
  USER_ROOT="$(cd "$HOME" && pwd -P)"
  if [ "$HOME" != "$USER_ROOT" ]; then
    echo "Error: user registration root must be a normalized physical path: $HOME" >&2
    exit 1
  fi
fi

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Error: project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd -P)"

if [ -z "$SKILLS_SOURCE" ]; then
  if [ "$SCOPE" = "project" ]; then
    SKILLS_SOURCE="$PROJECT_ROOT/.agents/skills"
  else
    echo "Error: --source is required for user-scoped registration." >&2
    exit 1
  fi
fi

skills_source_ancestor="$(dirname "$SKILLS_SOURCE")"
if [ -L "$skills_source_ancestor" ] \
  || { [ -e "$skills_source_ancestor" ] && [ ! -d "$skills_source_ancestor" ]; }; then
  echo "Error: canonical source ancestor must be a physical directory: $skills_source_ancestor" >&2
  exit 1
fi
if [ -L "$SKILLS_SOURCE" ] \
  || { [ -e "$SKILLS_SOURCE" ] && [ ! -d "$SKILLS_SOURCE" ]; }; then
  echo "Error: canonical skills source must be a physical directory: $SKILLS_SOURCE" >&2
  exit 1
fi

if [ "$SCOPE" = "project" ] && [ "$PREFLIGHT_ONLY" -eq 1 ]; then
  expected_project_source="$PROJECT_ROOT/.agents/skills"
  if [ "$SKILLS_SOURCE" != "$expected_project_source" ]; then
    echo "Error: Project-scoped source must be $expected_project_source" >&2
    exit 1
  fi
elif [ ! -d "$SKILLS_SOURCE" ]; then
  echo "Error: canonical skills directory not found: $SKILLS_SOURCE" >&2
  exit 1
else
  SKILLS_SOURCE="$(cd "$SKILLS_SOURCE" && pwd -P)"
fi

if [ "$SCOPE" = "project" ] && [ "$PREFLIGHT_ONLY" -eq 0 ]; then
  expected_project_source="$PROJECT_ROOT/.agents/skills"
  if [ ! -d "$expected_project_source" ]; then
    echo "Error: project-scoped source must exist at $expected_project_source" >&2
    exit 1
  fi
  expected_project_source="$(cd "$expected_project_source" && pwd -P)"
  if [ "$SKILLS_SOURCE" != "$expected_project_source" ]; then
    echo "Error: Project-scoped source must be $PROJECT_ROOT/.agents/skills" >&2
    exit 1
  fi
fi

if [ -L "$ADAPTER_DIR" ] || [ ! -d "$ADAPTER_DIR" ]; then
  echo "Error: skill adapter directory must be physical: $ADAPTER_DIR" >&2
  exit 1
fi

adapter_files=()
if [ "$REQUESTED_ADAPTERS" = "all" ]; then
  for adapter_file in "$ADAPTER_DIR"/*.sh; do
    if [ -L "$adapter_file" ]; then
      echo "Error: skill adapter must be a physical file: $adapter_file" >&2
      exit 1
    fi
    [ -f "$adapter_file" ] && adapter_files+=("$adapter_file")
  done
else
  IFS=',' read -r -a adapter_names <<< "$REQUESTED_ADAPTERS"
  for adapter_name in "${adapter_names[@]}"; do
    if [[ ! "$adapter_name" =~ ^[a-z0-9-]+$ ]]; then
      echo "Invalid adapter name: $adapter_name" >&2
      exit 1
    fi
    adapter_file="$ADAPTER_DIR/$adapter_name.sh"
    if [ -L "$adapter_file" ] || [ ! -f "$adapter_file" ]; then
      echo "Unknown adapter: $adapter_name" >&2
      exit 1
    fi
    adapter_files+=("$adapter_file")
  done
fi

if [ "${#adapter_files[@]}" -eq 0 ]; then
  echo "Error: no skill adapters found in $ADAPTER_DIR" >&2
  exit 1
fi

revalidate_target_ancestors() {
  local target="$1"
  local target_parent
  local target_root="$PROJECT_ROOT"
  local scope_label="project"
  local ancestor
  local next_ancestor

  if [ "$SCOPE" = "user" ]; then
    target_root="$USER_ROOT"
    scope_label="user"
  fi
  if [ -L "$target_root" ] || [ ! -d "$target_root" ]; then
    echo "Error: $scope_label registration root changed before linking: $target_root" >&2
    return 1
  fi

  target_parent="$(dirname "$target")"
  ancestor="$target_parent"
  while [ "$ancestor" != "$target_root" ]; do
    if [ -L "$ancestor" ]; then
      echo "Error: $scope_label adapter ancestor must not be a symlink: $ancestor" >&2
      return 1
    fi
    if [ -e "$ancestor" ] && [ ! -d "$ancestor" ]; then
      echo "Error: $scope_label adapter ancestor is not a directory: $ancestor" >&2
      return 1
    fi
    next_ancestor="$(dirname "$ancestor")"
    if [ "$next_ancestor" = "$ancestor" ]; then
      echo "Error: $scope_label adapter target escapes the $scope_label root: $target" >&2
      return 1
    fi
    ancestor="$next_ancestor"
  done
}

stat_identity() {
  local path="$1"

  if stat -c '%d:%i:%u' -- "$path" >/dev/null 2>&1; then
    stat -c '%d:%i:%u' -- "$path"
  else
    stat -f '%d:%i:%u' "$path"
  fi
}

path_identity() {
  local path="$1"
  local identity

  if [ -L "$path" ]; then
    identity="$(stat_identity "$path")" || return 1
    printf 'symlink:%s\n' "$identity"
  elif [ -d "$path" ]; then
    identity="$(stat_identity "$path")" || return 1
    printf 'directory:%s\n' "$identity"
  elif [ -f "$path" ]; then
    identity="$(stat_identity "$path")" || return 1
    printf 'file:%s\n' "$identity"
  elif [ -e "$path" ]; then
    identity="$(stat_identity "$path")" || return 1
    printf 'special:%s\n' "$identity"
  else
    printf 'absent\n'
  fi
}

platform_move_no_replace() {
  local source="$1"
  local target="$2"

  if [ -z "$MOVE_NO_REPLACE_MODE" ]; then
    if mv --help 2>&1 | grep -q -- '--no-target-directory'; then
      MOVE_NO_REPLACE_MODE=gnu
    else
      MOVE_NO_REPLACE_MODE=bsd
    fi
  fi
  if [ "$MOVE_NO_REPLACE_MODE" = gnu ]; then
    mv -Tn -- "$source" "$target"
  else
    mv -n -- "$source" "$target"
  fi
}

begin_atomic_transition() {
  ATOMIC_DEFER_SIGNALS=1
}

end_atomic_transition() {
  local signal_status

  ATOMIC_DEFER_SIGNALS=0
  if [ "$ATOMIC_PENDING_SIGNAL" -ne 0 ]; then
    signal_status="$ATOMIC_PENDING_SIGNAL"
    ATOMIC_PENDING_SIGNAL=0
    exit "$signal_status"
  fi
}

handle_atomic_signal() {
  local signal_status="$1"

  if [ "$ATOMIC_USER_LINKS_COMPLETE" -eq 1 ]; then
    return 0
  fi
  if [ "$ATOMIC_DEFER_SIGNALS" -eq 1 ]; then
    if [ "$ATOMIC_PENDING_SIGNAL" -eq 0 ]; then
      ATOMIC_PENDING_SIGNAL="$signal_status"
    fi
    return 0
  fi
  exit "$signal_status"
}

snapshot_atomic_user_links() {
  local index
  local target
  local target_parent
  local identity

  for index in "${!targets[@]}"; do
    target="${targets[$index]}"
    target_parent="$(dirname "$target")"
    identity="$(path_identity "$target")" || return 1
    ATOMIC_ORIGINAL_TARGET_IDS[$index]="$identity"
    ATOMIC_ORIGINAL_TARGET_LINKS[$index]=""
    if [[ "$identity" == symlink:* ]]; then
      ATOMIC_ORIGINAL_TARGET_LINKS[$index]="$(readlink "$target")" || return 1
    fi
    ATOMIC_ORIGINAL_PARENT_IDS[$index]="$(path_identity "$target_parent")" \
      || return 1
    ATOMIC_CREATED_TARGET_IDS[$index]=""
    ATOMIC_CREATED_TARGET_LINKS[$index]=""
    ATOMIC_CREATED_PARENT_IDS[$index]=""
    ATOMIC_TARGET_ACTIVE[$index]=0
    ATOMIC_STAGE_DIRS[$index]=""
    ATOMIC_STAGE_DIR_IDS[$index]=""
    ATOMIC_STAGE_ANCHORS[$index]=""
  done
}

verify_atomic_user_snapshot() {
  local index="$1"
  local target="${targets[$index]}"
  local target_parent
  local current_identity
  local current_link=""

  target_parent="$(dirname "$target")"
  current_identity="$(path_identity "$target")" || return 1
  if [ "$current_identity" != "${ATOMIC_ORIGINAL_TARGET_IDS[$index]}" ]; then
    echo "Error: user adapter target changed after transaction snapshot: $target" >&2
    return 1
  fi
  if [[ "$current_identity" == symlink:* ]]; then
    current_link="$(readlink "$target")" || return 1
    if [ "$current_link" != "${ATOMIC_ORIGINAL_TARGET_LINKS[$index]}" ]; then
      echo "Error: user adapter link changed after transaction snapshot: $target" >&2
      return 1
    fi
  fi
  current_identity="$(path_identity "$target_parent")" || return 1
  if [ "$current_identity" != "${ATOMIC_ORIGINAL_PARENT_IDS[$index]}" ]; then
    echo "Error: user adapter parent changed after transaction snapshot: $target_parent" >&2
    return 1
  fi
}

prepare_atomic_user_parent() {
  local index="$1"
  local target="${targets[$index]}"
  local target_parent
  local parent_identity
  local physical_parent
  local parent_created=0

  target_parent="$(dirname "$target")"
  verify_atomic_user_snapshot "$index" || return 1
  if [ "${ATOMIC_ORIGINAL_PARENT_IDS[$index]}" != "absent" ]; then
    return 0
  fi

  if [ "$(dirname "$target_parent")" != "$USER_ROOT" ]; then
    echo "Error: atomic user registration cannot create nested adapter parents: $target_parent" >&2
    return 1
  fi
  begin_atomic_transition
  if mkdir "$target_parent" \
    && revalidate_target_ancestors "$target"; then
    physical_parent="$(cd "$target_parent" && pwd -P 2>/dev/null || true)"
    parent_identity="$(path_identity "$target_parent" 2>/dev/null || true)"
    if [ "$physical_parent" = "$target_parent" ] \
      && [[ "$parent_identity" == directory:* ]]; then
      ATOMIC_CREATED_PARENT_IDS[$index]="$parent_identity"
      parent_created=1
    fi
  fi
  end_atomic_transition
  if [ "$parent_created" -ne 1 ]; then
    echo "Error: user adapter parent appeared or changed during atomic registration: $target_parent" >&2
    return 1
  fi
}

atomic_parent_matches_record() {
  local index="$1"
  local target="${targets[$index]}"
  local target_parent
  local expected_parent_identity
  local physical_parent

  target_parent="$(dirname "$target")"
  expected_parent_identity="${ATOMIC_CREATED_PARENT_IDS[$index]:-}"
  if [ -z "$expected_parent_identity" ]; then
    expected_parent_identity="${ATOMIC_ORIGINAL_PARENT_IDS[$index]}"
  fi

  revalidate_target_ancestors "$target" || return 1
  if [ "$(path_identity "$target_parent")" != "$expected_parent_identity" ]; then
    return 1
  fi
  physical_parent="$(cd "$target_parent" && pwd -P)" || return 1
  [ "$physical_parent" = "$target_parent" ]
}

discard_private_staged_link() {
  local staging_dir="$1"
  local staging_identity="$2"
  local staged_link="$3"
  local staged_identity="$4"
  local expected_link="$5"
  local physical_staging=""

  if [ -d "$staging_dir" ] && [ ! -L "$staging_dir" ]; then
    physical_staging="$(cd "$staging_dir" && pwd -P 2>/dev/null || true)"
  fi
  if [ "$physical_staging" != "$staging_dir" ] \
    || [ "$(path_identity "$staging_dir" 2>/dev/null || true)" != "$staging_identity" ]; then
    echo "Warning: changed link staging directory was preserved: $staging_dir" >&2
    return 1
  fi

  if [ -e "$staged_link" ] || [ -L "$staged_link" ]; then
    if [ "$(path_identity "$staged_link" 2>/dev/null || true)" != "$staged_identity" ] \
      || [ "$(readlink "$staged_link" 2>/dev/null || true)" != "$expected_link" ] \
      || [ "$(path_identity "$staged_link" 2>/dev/null || true)" != "$staged_identity" ]; then
      echo "Warning: changed staged link was preserved: $staged_link" >&2
      return 1
    fi
    rm -- "$staged_link" || return 1
  fi

  if [ "$(path_identity "$staging_dir" 2>/dev/null || true)" = "$staging_identity" ]; then
    rmdir "$staging_dir" 2>/dev/null || true
  fi
}

register_atomic_user_link() {
  local index="$1"
  local target="${targets[$index]}"
  local expected_link="${link_sources[$index]}"
  local target_parent
  local target_name
  local current_identity
  local staging_dir
  local staging_identity
  local staged_link
  local staged_identity
  local probe_dir
  local probe_link
  local probe_identity
  local target_after
  local activation_succeeded=0
  local link_status=0

  target_parent="$(dirname "$target")"
  target_name="$(basename "$target")"
  if ! atomic_parent_matches_record "$index"; then
    echo "Error: user adapter parent changed before atomic link activation: $target_parent" >&2
    return 1
  fi

  current_identity="$(path_identity "$target")" || return 1
  if [ "${ATOMIC_ORIGINAL_TARGET_IDS[$index]}" != "absent" ]; then
    if [ "$current_identity" = "${ATOMIC_ORIGINAL_TARGET_IDS[$index]}" ] \
      && [ "$(readlink "$target" 2>/dev/null || true)" = "${ATOMIC_ORIGINAL_TARGET_LINKS[$index]}" ]; then
      echo "   [Unchanged] $target -> $expected_link"
      return 0
    fi
    echo "Error: user adapter target changed after transaction snapshot: $target" >&2
    return 1
  fi
  if [ "$current_identity" != "absent" ]; then
    echo "Error: user adapter target appeared before atomic link activation: $target" >&2
    return 1
  fi

  staging_dir="$(mktemp -d "$target_parent/.${target_name}.link-stage.XXXXXX")" \
    || return 1
  staging_identity="$(path_identity "$staging_dir")" || return 1
  staged_link="$staging_dir/$target_name"
  if [ -L "$staging_dir" ] \
    || [ ! -d "$staging_dir" ] \
    || [ "$(cd "$staging_dir" && pwd -P)" != "$staging_dir" ] \
    || [[ "$staging_identity" != directory:* ]] \
    || ! atomic_parent_matches_record "$index"; then
    echo "Error: link staging directory changed before activation: $staging_dir" >&2
    return 1
  fi
  if ! ln -s "$expected_link" "$staged_link"; then
    rmdir "$staging_dir" 2>/dev/null || true
    return 1
  fi
  staged_identity="$(path_identity "$staged_link")" || return 1
  if [[ "$staged_identity" != symlink:* ]] \
    || [ "$(readlink "$staged_link")" != "$expected_link" ]; then
    echo "Error: staged user adapter link did not match its requested state: $staged_link" >&2
    return 1
  fi

  probe_dir="$staging_dir/probe"
  probe_link="$probe_dir/$target_name"
  if ! mkdir "$probe_dir" \
    || ! ln -P "$staged_link" "$probe_dir"; then
    echo "Error: atomic user registration requires physical symlink links on this filesystem." >&2
    return 1
  fi
  probe_identity="$(path_identity "$probe_link" 2>/dev/null || true)"
  if [ "$probe_identity" != "$staged_identity" ] \
    || [ "$(readlink "$probe_link" 2>/dev/null || true)" != "$expected_link" ]; then
    echo "Error: physical symlink link probe did not preserve identity: $target_parent" >&2
    return 1
  fi
  rm -- "$probe_link"
  rmdir "$probe_dir"

  ATOMIC_CREATED_TARGET_IDS[$index]="$staged_identity"
  ATOMIC_CREATED_TARGET_LINKS[$index]="$expected_link"
  ATOMIC_TARGET_ACTIVE[$index]=0
  ATOMIC_STAGE_DIRS[$index]="$staging_dir"
  ATOMIC_STAGE_DIR_IDS[$index]="$staging_identity"
  ATOMIC_STAGE_ANCHORS[$index]="$staged_link"
  if [ "$(path_identity "$target")" != "absent" ] \
    || ! atomic_parent_matches_record "$index"; then
    echo "Error: user adapter target changed before atomic link activation: $target" >&2
    return 1
  fi

  begin_atomic_transition
  ln -P "$staged_link" "$target_parent" || link_status="$?"
  target_after="$(path_identity "$target" 2>/dev/null || true)"
  if [ "$target_after" = "$staged_identity" ] \
    && [ "$(readlink "$target" 2>/dev/null || true)" = "$expected_link" ] \
    && [ "$(path_identity "$staged_link" 2>/dev/null || true)" = "$staged_identity" ] \
    && [ "$(readlink "$staged_link" 2>/dev/null || true)" = "$expected_link" ] \
    && atomic_parent_matches_record "$index"; then
    ATOMIC_TARGET_ACTIVE[$index]=1
    activation_succeeded=1
  fi
  end_atomic_transition

  if [ "$activation_succeeded" -ne 1 ]; then
    if [ "$link_status" -ne 0 ]; then
      echo "Error: atomic user adapter link activation failed: $target" >&2
    else
      echo "Error: user adapter target changed during atomic link activation: $target" >&2
    fi
    return 1
  fi
  echo "   [Linked]  $target -> $expected_link"
}

cleanup_atomic_link_stages() {
  local index
  local staging_dir
  local staging_identity
  local staged_link
  local staged_identity
  local expected_link

  for ((index = ${#targets[@]} - 1; index >= 0; index--)); do
    staging_dir="${ATOMIC_STAGE_DIRS[$index]:-}"
    [ -n "$staging_dir" ] || continue
    staging_identity="${ATOMIC_STAGE_DIR_IDS[$index]:-}"
    staged_link="${ATOMIC_STAGE_ANCHORS[$index]:-}"
    staged_identity="${ATOMIC_CREATED_TARGET_IDS[$index]:-}"
    expected_link="${ATOMIC_CREATED_TARGET_LINKS[$index]:-}"
    if discard_private_staged_link \
      "$staging_dir" "$staging_identity" \
      "$staged_link" "$staged_identity" "$expected_link"; then
      ATOMIC_STAGE_DIRS[$index]=""
      ATOMIC_STAGE_DIR_IDS[$index]=""
      ATOMIC_STAGE_ANCHORS[$index]=""
    fi
  done
}

verify_atomic_user_commit() {
  local index
  local target
  local expected_identity
  local expected_link
  local ownership_anchor

  for index in "${!targets[@]}"; do
    target="${targets[$index]}"
    expected_identity="${ATOMIC_CREATED_TARGET_IDS[$index]:-}"
    expected_link="${ATOMIC_CREATED_TARGET_LINKS[$index]:-}"
    ownership_anchor="${ATOMIC_STAGE_ANCHORS[$index]:-}"
    if [ -z "$expected_identity" ]; then
      expected_identity="${ATOMIC_ORIGINAL_TARGET_IDS[$index]}"
      expected_link="${ATOMIC_ORIGINAL_TARGET_LINKS[$index]}"
      if [ "$(path_identity "$target")" != "$expected_identity" ]; then
        echo "Error: preexisting user adapter entry changed before transaction commit: $target" >&2
        return 1
      fi
      if [[ "$expected_identity" == symlink:* ]] \
        && [ "$(readlink "$target" 2>/dev/null || true)" != "$expected_link" ]; then
        echo "Error: preexisting user adapter link changed before transaction commit: $target" >&2
        return 1
      fi
      continue
    fi

    if [ "${ATOMIC_TARGET_ACTIVE[$index]:-0}" -ne 1 ] \
      || [ "$(path_identity "$target")" != "$expected_identity" ] \
      || [ "$(readlink "$target" 2>/dev/null || true)" != "$expected_link" ] \
      || [ "$(path_identity "$ownership_anchor" 2>/dev/null || true)" != "$expected_identity" ] \
      || [ "$(readlink "$ownership_anchor" 2>/dev/null || true)" != "$expected_link" ]; then
      echo "Error: created user adapter link changed before transaction commit: $target" >&2
      return 1
    fi
  done
}

rollback_atomic_user_links() {
  local index
  local target
  local target_parent
  local target_name
  local expected_identity
  local expected_link
  local expected_parent_identity
  local created_parent_identity
  local ownership_anchor
  local current_identity
  local current_link
  local physical_parent
  local quarantine_dir
  local quarantine_identity
  local quarantined_entry
  local quarantined_identity
  local quarantined_link
  local move_status
  local restored=0

  for ((index = ${#targets[@]} - 1; index >= 0; index--)); do
    target="${targets[$index]}"
    target_parent="$(dirname "$target")"
    target_name="$(basename "$target")"
    expected_identity="${ATOMIC_CREATED_TARGET_IDS[$index]:-}"
    expected_link="${ATOMIC_CREATED_TARGET_LINKS[$index]:-}"
    ownership_anchor="${ATOMIC_STAGE_ANCHORS[$index]:-}"
    created_parent_identity="${ATOMIC_CREATED_PARENT_IDS[$index]:-}"
    expected_parent_identity="$created_parent_identity"
    if [ -z "$expected_parent_identity" ]; then
      expected_parent_identity="${ATOMIC_ORIGINAL_PARENT_IDS[$index]}"
    fi

    if [ -n "$expected_identity" ] \
      && [ "${ATOMIC_TARGET_ACTIVE[$index]:-0}" -eq 1 ]; then
      current_identity="$(path_identity "$target" 2>/dev/null || true)"
      current_link=""
      if [ -L "$target" ]; then
        current_link="$(readlink "$target" 2>/dev/null || true)"
      fi
      physical_parent=""
      if [ -d "$target_parent" ] && [ ! -L "$target_parent" ]; then
        physical_parent="$(cd "$target_parent" && pwd -P 2>/dev/null || true)"
      fi
      if [ "$current_identity" != "$expected_identity" ] \
        || [ "$current_link" != "$expected_link" ] \
        || [ "$physical_parent" != "$target_parent" ] \
        || [ "$(path_identity "$ownership_anchor" 2>/dev/null || true)" != "$expected_identity" ] \
        || [ "$(readlink "$ownership_anchor" 2>/dev/null || true)" != "$expected_link" ]; then
        echo "Warning: changed user adapter entry was preserved during rollback: $target" >&2
      else
        quarantine_dir="$(mktemp -d "$target_parent/.${target_name}.rollback.XXXXXX" 2>/dev/null || true)"
        quarantine_identity="$(path_identity "$quarantine_dir" 2>/dev/null || true)"
        quarantined_entry="$quarantine_dir/$target_name"
        if [ -z "$quarantine_dir" ] \
          || [ -L "$quarantine_dir" ] \
          || [ ! -d "$quarantine_dir" ] \
          || [[ "$quarantine_identity" != directory:* ]] \
          || [ "$(cd "$quarantine_dir" && pwd -P 2>/dev/null || true)" != "$quarantine_dir" ] \
          || [ "$(path_identity "$target_parent" 2>/dev/null || true)" != "$expected_parent_identity" ] \
          || [ "$(path_identity "$target" 2>/dev/null || true)" != "$expected_identity" ] \
          || [ "$(readlink "$target" 2>/dev/null || true)" != "$expected_link" ]; then
          echo "Warning: user adapter link changed before quarantine and was preserved: $target" >&2
        else
          move_status=0
          platform_move_no_replace "$target" "$quarantined_entry" \
            || move_status="$?"
          quarantined_identity="$(path_identity "$quarantined_entry" 2>/dev/null || true)"
          quarantined_link=""
          if [ -L "$quarantined_entry" ]; then
            quarantined_link="$(readlink "$quarantined_entry" 2>/dev/null || true)"
          fi

          if [ "$quarantined_identity" = "$expected_identity" ] \
            && [ "$quarantined_link" = "$expected_link" ] \
            && [ "$(path_identity "$quarantine_dir" 2>/dev/null || true)" = "$quarantine_identity" ] \
            && [ "$(cd "$quarantine_dir" && pwd -P 2>/dev/null || true)" = "$quarantine_dir" ]; then
            ATOMIC_TARGET_ACTIVE[$index]=0
            if [ "$(path_identity "$quarantined_entry" 2>/dev/null || true)" = "$expected_identity" ] \
              && [ "$(readlink "$quarantined_entry" 2>/dev/null || true)" = "$expected_link" ] \
              && rm -- "$quarantined_entry"; then
              echo "Warning: rolled back user adapter link: $target" >&2
            else
              echo "Warning: owned user adapter link was quarantined for recovery: $quarantined_entry" >&2
            fi
          elif [ "$quarantined_identity" != "absent" ]; then
            restored=0
            if { [ -L "$quarantined_entry" ] || [ -f "$quarantined_entry" ]; } \
              && [ "$(path_identity "$target" 2>/dev/null || true)" = "absent" ] \
              && ln -P "$quarantined_entry" "$target_parent" \
              && [ "$(path_identity "$target" 2>/dev/null || true)" = "$quarantined_identity" ]; then
              restored=1
              if [ "$(path_identity "$quarantined_entry" 2>/dev/null || true)" = "$quarantined_identity" ]; then
                rm -- "$quarantined_entry" || true
              fi
            fi
            if [ "$restored" -eq 1 ]; then
              echo "Warning: concurrent user adapter entry was restored at $target" >&2
            else
              echo "Warning: concurrent user adapter entry was retained at $quarantined_entry" >&2
            fi
          elif [ "$move_status" -ne 0 ]; then
            echo "Warning: matching user adapter link could not be quarantined and was preserved: $target" >&2
          else
            echo "Warning: user adapter link changed during quarantine and was preserved: $target" >&2
          fi
        fi

        if [ -n "$quarantine_dir" ] \
          && [ "$(path_identity "$quarantine_dir" 2>/dev/null || true)" = "$quarantine_identity" ]; then
          rmdir "$quarantine_dir" 2>/dev/null || true
        fi
      fi
    fi

    if [ -n "${ATOMIC_STAGE_DIRS[$index]:-}" ] \
      && discard_private_staged_link \
        "${ATOMIC_STAGE_DIRS[$index]}" \
        "${ATOMIC_STAGE_DIR_IDS[$index]}" \
        "${ATOMIC_STAGE_ANCHORS[$index]}" \
        "$expected_identity" \
        "$expected_link"; then
      ATOMIC_STAGE_DIRS[$index]=""
      ATOMIC_STAGE_DIR_IDS[$index]=""
      ATOMIC_STAGE_ANCHORS[$index]=""
    fi

    if [ -n "$created_parent_identity" ]; then
      current_identity="$(path_identity "$target_parent" 2>/dev/null || true)"
      physical_parent=""
      if [ -d "$target_parent" ] && [ ! -L "$target_parent" ]; then
        physical_parent="$(cd "$target_parent" && pwd -P 2>/dev/null || true)"
      fi
      if [ "$current_identity" = "$expected_parent_identity" ] \
        && [ "$physical_parent" = "$target_parent" ] \
        && [ "$(path_identity "$target_parent" 2>/dev/null || true)" = "$expected_parent_identity" ]; then
        if rmdir "$target_parent" 2>/dev/null; then
          echo "Warning: rolled back empty user adapter directory: $target_parent" >&2
        elif [ "$(path_identity "$target_parent" 2>/dev/null || true)" != "$expected_parent_identity" ]; then
          echo "Warning: changed user adapter directory was preserved during rollback: $target_parent" >&2
        fi
      else
        echo "Warning: changed user adapter directory was preserved during rollback: $target_parent" >&2
      fi
    fi
  done
}

cleanup_atomic_user_links() {
  local exit_status="$?"

  trap - EXIT
  trap '' HUP INT TERM
  set +e
  if [ "$ATOMIC_USER_LINKS" -eq 1 ] \
    && [ "$ATOMIC_USER_LINKS_COMPLETE" -eq 0 ]; then
    rollback_atomic_user_links
  fi
  if [ "$ATOMIC_USER_LINKS" -eq 1 ]; then
    cleanup_atomic_link_stages
  fi
  return "$exit_status"
}

register_link() {
  local link_source="$1"
  local target="$2"
  local target_parent
  local target_name
  local physical_parent
  target_parent="$(dirname "$target")"
  target_name="$(basename "$target")"

  mkdir -p "$target_parent"
  revalidate_target_ancestors "$target" || return 1
  physical_parent="$(cd "$target_parent" && pwd -P)"
  if [ "$physical_parent" != "$target_parent" ]; then
    echo "Error: adapter parent changed before linking: $target_parent" >&2
    return 1
  fi

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Error: $target exists and is not a symlink." >&2
    echo "       Move or rename it, then re-run registration." >&2
    return 1
  fi

  if [ -L "$target" ]; then
    if [ "$(readlink "$target")" = "$link_source" ]; then
      echo "   [Unchanged] $target -> $link_source"
      return 0
    fi
    echo "Error: $target is already a symlink to $(readlink "$target")." >&2
    echo "       Remove or repoint it explicitly before registering $link_source." >&2
    return 1
  fi

  if ! (
    cd "$target_parent"
    ln -s "$link_source" "$target_name"
  ); then
    echo "Error: could not create adapter link: $target" >&2
    return 1
  fi
  if echo "   [Linked]  $target -> $link_source"; then
    return 0
  fi
  return 0
}

echo "=> Registering $SCOPE skill adapters from $SKILLS_SOURCE"
targets=()
link_sources=()
active_adapter_files=()

for adapter_file in "${adapter_files[@]}"; do
  unset -f \
    skill_adapter_supports_scope \
    skill_adapter_target \
    skill_adapter_link_source \
    skill_adapter_preflight \
    skill_adapter_configure 2>/dev/null || true
  # shellcheck source=/dev/null
  source "$adapter_file"

  if ! declare -F skill_adapter_supports_scope >/dev/null \
    || ! declare -F skill_adapter_target >/dev/null \
    || ! declare -F skill_adapter_link_source >/dev/null; then
    echo "Error: invalid skill adapter: $adapter_file" >&2
    exit 1
  fi

  if ! skill_adapter_supports_scope "$SCOPE"; then
    continue
  fi

  if declare -F skill_adapter_preflight >/dev/null; then
    skill_adapter_preflight \
      "$SCOPE" \
      "$PROJECT_ROOT" \
      "$SKILLS_SOURCE" \
      "$DISTRIBUTION_ROOT"
  fi

  target="$(skill_adapter_target "$SCOPE" "$PROJECT_ROOT")"
  link_source="$(skill_adapter_link_source "$SCOPE" "$SKILLS_SOURCE")"
  targets+=("$target")
  link_sources+=("$link_source")
  active_adapter_files+=("$adapter_file")
done

if [ "${#targets[@]}" -eq 0 ]; then
  echo "Error: selected adapters do not support the '$SCOPE' scope." >&2
  exit 1
fi

# Every target must have exactly one owner. Otherwise all adapters can pass
# filesystem preflight and the later adapter can fail after an earlier link was
# already created.
for ((index = 0; index < ${#targets[@]}; index++)); do
  for ((previous_index = 0; previous_index < index; previous_index++)); do
    if [ "${targets[$index]}" = "${targets[$previous_index]}" ]; then
      echo "Error: multiple adapters resolve to the same target: ${targets[$index]}" >&2
      echo "       ${active_adapter_files[$previous_index]}" >&2
      echo "       ${active_adapter_files[$index]}" >&2
      exit 1
    fi
  done
done

for index in "${!targets[@]}"; do
  target="${targets[$index]}"
  link_source="${link_sources[$index]}"
  target_parent="$(dirname "$target")"
  target_root="$PROJECT_ROOT"
  scope_label="project"
  if [ "$SCOPE" = "user" ]; then
    target_root="$USER_ROOT"
    scope_label="user"
  fi
  target_prefix="${target_root%/}/"
  case "$target" in
    "$target_prefix"*) ;;
    *)
      echo "Error: $scope_label adapter target escapes the $scope_label root: $target" >&2
      exit 1
      ;;
  esac
  case "$target" in
    */../*|*/..|*/./*|*/.|*//*|*/)
      echo "Error: $scope_label adapter target must be normalized: $target" >&2
      exit 1
      ;;
  esac

  ancestor="$target_parent"
  while [ "$ancestor" != "$target_root" ]; do
    if [ -L "$ancestor" ]; then
      echo "Error: $scope_label adapter ancestor must not be a symlink: $ancestor" >&2
      exit 1
    fi
    if [ -e "$ancestor" ] && [ ! -d "$ancestor" ]; then
      echo "Error: $scope_label adapter ancestor is not a directory: $ancestor" >&2
      exit 1
    fi
    next_ancestor="$(dirname "$ancestor")"
    if [ "$next_ancestor" = "$ancestor" ]; then
      echo "Error: $scope_label adapter target escapes the $scope_label root: $target" >&2
      exit 1
    fi
    ancestor="$next_ancestor"
  done
  if { [ -e "$target_parent" ] || [ -L "$target_parent" ]; } \
    && [ ! -d "$target_parent" ]; then
    echo "Error: adapter parent is not a directory: $target_parent" >&2
    exit 1
  fi
  write_probe="$target_parent"
  while [ ! -e "$write_probe" ] && [ ! -L "$write_probe" ]; do
    next_probe="$(dirname "$write_probe")"
    if [ "$next_probe" = "$write_probe" ]; then
      echo "Error: no existing parent found for adapter target: $target" >&2
      exit 1
    fi
    write_probe="$next_probe"
  done
  if [ ! -d "$write_probe" ]; then
    echo "Error: adapter ancestor is not a directory: $write_probe" >&2
    exit 1
  fi
  if [ ! -w "$write_probe" ] || [ ! -x "$write_probe" ]; then
    echo "Error: adapter ancestor is not writable and searchable: $write_probe" >&2
    exit 1
  fi
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "Error: $target exists and is not a symlink." >&2
    echo "       Move or rename it, then re-run registration." >&2
    exit 1
  fi
  if [ -L "$target" ] && [ "$(readlink "$target")" != "$link_source" ]; then
    echo "Error: $target is already a symlink to $(readlink "$target")." >&2
    echo "       Remove or repoint it explicitly before registering $link_source." >&2
    exit 1
  fi
done

if [ "$PREFLIGHT_ONLY" -eq 1 ]; then
  echo "=> Adapter targets passed preflight; no registration changes made."
  exit 0
fi

if [ "$ATOMIC_USER_LINKS" -eq 1 ]; then
  snapshot_atomic_user_links
  trap cleanup_atomic_user_links EXIT
  trap 'handle_atomic_signal 129' HUP
  trap 'handle_atomic_signal 130' INT
  trap 'handle_atomic_signal 143' TERM
fi

for index in "${!targets[@]}"; do
  if [ "$ATOMIC_USER_LINKS" -eq 1 ]; then
    prepare_atomic_user_parent "$index"
  fi
  unset -f skill_adapter_configure 2>/dev/null || true
  # shellcheck source=/dev/null
  source "${active_adapter_files[$index]}"
  if [ "$ATOMIC_USER_LINKS" -eq 1 ]; then
    register_atomic_user_link "$index"
  else
    register_link "${link_sources[$index]}" "${targets[$index]}"
  fi
  if [ "$ATOMIC_USER_LINKS" -eq 0 ] \
    && declare -F skill_adapter_configure >/dev/null; then
    skill_adapter_configure \
      "$SCOPE" \
      "$PROJECT_ROOT" \
      "$SKILLS_SOURCE" \
      "$DISTRIBUTION_ROOT"
  fi
done

if [ "$ATOMIC_USER_LINKS" -eq 1 ]; then
  verify_atomic_user_commit
fi
echo "=> Registered ${#targets[@]} adapter(s); canonical skills remain at $SKILLS_SOURCE."
ATOMIC_USER_LINKS_COMPLETE=1
if [ "$ATOMIC_USER_LINKS" -eq 1 ]; then
  cleanup_atomic_link_stages
fi
