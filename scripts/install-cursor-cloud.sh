#!/usr/bin/env bash
# Optional Cursor Cloud environment install hook.
# Maintains a validated checkout and registers only the Agent Skills and Cursor
# user discovery paths. Updates are staged beside the checkout and committed as
# one recoverable transaction.

set -euo pipefail
umask 022

for git_variable in "${!GIT_@}"; do
  unset "$git_variable"
done
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_NO_REPLACE_OBJECTS=1
export GIT_NO_LAZY_FETCH=1
export GIT_OPTIONAL_LOCKS=0
export GIT_TERMINAL_PROMPT=0
export AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID="$BASHPID"

REPO_URL="https://github.com/marcus-friction/agents.git"
RELEASE_REF=""
EXPECTED_UID="$(id -u)"
HOME_ROOT=""
HOME_ID=""
HOME_FD=""
HOME_BOUND=""
DEST=""
DEST_PARENT=""
DEST_BASE=""
DEST_PARENT_ID=""
DEST_PARENT_FD=""
DEST_PARENT_BOUND=""
DEST_BOUND=""
LOCK_PATH=""
LOCK_BOUND_PATH=""
LOCK_ID=""
LOCK_HELD=0
LOCK_FD=""
LOCK_BOUND_ROOT=""
STAGE_ROOT=""
STAGE_ENTRY_BOUND=""
STAGE_BOUND_ROOT=""
STAGE_FD=""
STAGE_ID=""
STAGE_VERIFIED=0
CANDIDATE=""
CANDIDATE_BOUND=""
PRIOR=""
PRIOR_BOUND=""
FAILED_CANDIDATE=""
FAILED_CANDIDATE_BOUND=""
PRIOR_MOVED=0
NEW_ACTIVE=0
NEW_ID=""
COMMITTED=0
NO_SWAP=0
EXISTING_DEST=0
ORIGINAL_DEST_ID="absent"
ORIGINAL_DEST_FD=""
ORIGINAL_DEST_BOUND_ROOT=""
ORIGINAL_HEAD=""
ORIGINAL_CHECKOUT_MODE=""
CANDIDATE_HEAD=""
CANDIDATE_ID=""
CANDIDATE_FD=""
CANDIDATE_BOUND_ROOT=""
DEFER_SIGNALS=0
PENDING_SIGNAL=0
DISCOVERY_PATHS=()
DISCOVERY_STATES=()
DISCOVERY_TARGETS=()
DISCOVERY_UIDS=()
DISCOVERY_PARENT_STATES=()
DISCOVERY_PARENT_IDS=()
DISCOVERY_PARENT_UIDS=()
DISCOVERY_PARENT_CREATED=()
DISCOVERY_PARENT_FDS=()
DISCOVERY_PARENT_BOUNDS=()
DISCOVERY_IDS=()
DISCOVERY_CREATED_IDS=()
DISCOVERY_QUARANTINES=()
DISCOVERY_SNAPSHOT_READY=0
RETIRE_SEQUENCE=0

usage() {
  echo "Usage: $0 [--ref 40-character-commit-sha]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref)
      RELEASE_REF="${2:-}"
      if [ -z "$RELEASE_REF" ]; then
        error_message="--ref requires a full 40-character lowercase commit SHA"
        echo "Error: $error_message." >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -n "$RELEASE_REF" ] && ! [[ "$RELEASE_REF" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Error: --ref requires a full 40-character lowercase commit SHA." >&2
  exit 1
fi

error() {
  echo "Error: $*" >&2
}

warning() {
  echo "Warning: $*" >&2
}

cleanup_issue() {
  if [ "$COMMITTED" -eq 1 ]; then
    warning "$*"
  else
    error "$*"
  fi
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

safe_git() {
  GIT_ASKPASS=/usr/bin/false \
  GIT_CONFIG=/dev/null \
  GH_PROMPT_DISABLED=1 \
  SSH_ASKPASS=/usr/bin/false \
  SSH_ASKPASS_REQUIRE=never \
    git \
        --no-replace-objects \
        -c core.hooksPath=/dev/null \
        -c core.fsmonitor=false \
        -c credential.helper= \
        "$@"
}

config_git() {
  env -u GIT_CONFIG git \
    --no-replace-objects \
    -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false \
    "$@"
}

path_identity() {
  local path="$1"

  if [ -L "$path" ]; then
    printf 'symlink:%s\n' "$(stat -c '%d:%i:%u' -- "$path")"
  elif [ -d "$path" ]; then
    printf 'directory:%s\n' "$(stat -c '%d:%i:%u' -- "$path")"
  elif [ -f "$path" ]; then
    printf 'file:%s\n' "$(stat -c '%d:%i:%u' -- "$path")"
  elif [ -e "$path" ]; then
    printf 'special:%s\n' "$(stat -c '%d:%i:%u' -- "$path")"
  else
    printf 'absent\n'
  fi
}

bound_directory_identity() {
  local bound_path="$1"

  [ -n "$bound_path" ] && [ -d "$bound_path" ] || return 1
  printf 'directory:%s\n' "$(stat -Lc '%d:%i:%u' -- "$bound_path")"
}

resolve_bound_directory() {
  local bound_path="$1"
  local fallback="$2"
  local physical=""

  if [ -n "$bound_path" ] && [ -d "$bound_path" ]; then
    physical="$(cd -- "$bound_path" 2>/dev/null && pwd -P)" || physical=""
  fi
  if [ -n "$physical" ]; then
    printf '%s\n' "$physical"
  else
    printf '%s\n' "$fallback"
  fi
}

require_owned_path() {
  local path="$1"
  local actual_uid
  actual_uid="$(stat -c '%u' -- "$path")" || return 1
  if [ "$actual_uid" != "$EXPECTED_UID" ]; then
    error "$path must be owned by uid $EXPECTED_UID; found uid $actual_uid."
    return 1
  fi
}

require_physical_directory() {
  local path="$1"
  local label="$2"
  local physical

  if [ -L "$path" ] || [ ! -d "$path" ]; then
    error "$label must be a physical normalized directory: $path"
    return 1
  fi
  physical="$(cd "$path" && pwd -P)" || return 1
  if [ "$physical" != "$path" ]; then
    error "$label must be a physical normalized directory: $path"
    return 1
  fi
}

validate_home() {
  local bound_identity
  case "${HOME:-}" in
    /*) ;;
    *)
      error "HOME must be an absolute physical directory."
      return 1
      ;;
  esac
  require_physical_directory "$HOME" "HOME" || return 1
  require_owned_path "$HOME" || return 1
  HOME_ROOT="$HOME"
  HOME_ID="$(path_identity "$HOME_ROOT")" || return 1
  exec {HOME_FD}<"$HOME_ROOT" || {
    error "HOME could not be bound: $HOME_ROOT"
    return 1
  }
  HOME_BOUND="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$HOME_FD"
  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$HOME_BOUND")" \
    || return 1
  if [ "$bound_identity" != "$HOME_ID" ]; then
    error "HOME changed while it was being bound: $HOME_ROOT"
    return 1
  fi
}

verify_home() {
  local phase="$1"
  local bound_identity

  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$HOME_BOUND" 2>/dev/null)" \
    || {
      error "HOME binding was lost $phase: $HOME_ROOT"
      return 1
    }
  if [ "$bound_identity" != "$HOME_ID" ] \
    || [ -L "$HOME_ROOT" ] \
    || [ ! -d "$HOME_ROOT" ] \
    || [ "$(path_identity "$HOME_ROOT")" != "$HOME_ID" ]; then
    error "HOME changed $phase: $HOME_ROOT"
    return 1
  fi
  require_owned_path "$HOME_ROOT" || return 1
}

select_destination() {
  if [ -n "${AGENTS_ECOSYSTEM_HOME:-}" ]; then
    DEST="$AGENTS_ECOSYSTEM_HOME"
    return 0
  fi

  if [ ! -L /opt ] \
    && [ -d /opt ] \
    && [ -w /opt ] \
    && [ -x /opt ] \
    && [ "$(stat -c '%u' -- /opt)" = "$EXPECTED_UID" ]; then
    DEST="/opt/agent-ecosystem"
  else
    DEST="$HOME_ROOT/.agent-ecosystem"
  fi
}

validate_destination_path() {
  local bound_identity
  case "$DEST" in
    /*) ;;
    *)
      error "installation destination must be absolute: $DEST"
      return 1
      ;;
  esac
  case "$DEST" in
    /|*/|*//*|*/./*|*/.|*/../*|*/..)
      error "installation destination must be normalized: $DEST"
      return 1
      ;;
  esac

  DEST_PARENT="$(dirname -- "$DEST")"
  DEST_BASE="$(basename -- "$DEST")"
  require_physical_directory "$DEST_PARENT" "destination parent" || return 1
  require_owned_path "$DEST_PARENT" || return 1
  if [ ! -w "$DEST_PARENT" ] || [ ! -x "$DEST_PARENT" ]; then
    error "destination parent must be writable and searchable: $DEST_PARENT"
    return 1
  fi

  if [ -L "$DEST" ]; then
    error "installation destination must not be a symlink: $DEST"
    return 1
  fi
  if [ -e "$DEST" ] && [ ! -d "$DEST" ]; then
    error "installation destination must be a physical directory or absent: $DEST"
    return 1
  fi
  if [ -d "$DEST" ]; then
    require_owned_path "$DEST" || return 1
  fi

  exec {DEST_PARENT_FD}<"$DEST_PARENT" || {
    error "destination parent could not be bound: $DEST_PARENT"
    return 1
  }
  DEST_PARENT_BOUND="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$DEST_PARENT_FD"
  DEST_BOUND="$DEST_PARENT_BOUND/$DEST_BASE"
  DEST_PARENT_ID="$(path_identity "$DEST_PARENT")" || return 1
  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$DEST_PARENT_BOUND")" \
    || return 1
  if [ "$bound_identity" != "$DEST_PARENT_ID" ]; then
    error "destination parent changed while it was being bound: $DEST_PARENT"
    return 1
  fi
}

bind_original_checkout() {
  local bound_identity

  exec {ORIGINAL_DEST_FD}<"$DEST_BOUND" || {
    error "existing checkout could not be bound: $DEST"
    return 1
  }
  ORIGINAL_DEST_BOUND_ROOT="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$ORIGINAL_DEST_FD"
  bound_identity="$(bound_directory_identity "$ORIGINAL_DEST_BOUND_ROOT")" \
    || return 1
  if [ "$bound_identity" != "$ORIGINAL_DEST_ID" ]; then
    error "existing checkout changed while it was being bound: $DEST"
    return 1
  fi
}

bind_candidate_checkout() {
  local bound_identity

  exec {CANDIDATE_FD}<"$CANDIDATE_BOUND" || {
    error "candidate checkout could not be bound: $CANDIDATE"
    return 1
  }
  CANDIDATE_BOUND_ROOT="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$CANDIDATE_FD"
  bound_identity="$(bound_directory_identity "$CANDIDATE_BOUND_ROOT")" \
    || return 1
  if [ "$bound_identity" != "$CANDIDATE_ID" ]; then
    error "candidate checkout changed while it was being bound: $CANDIDATE"
    return 1
  fi
}

bind_lock_directory() {
  local bound_identity

  exec {LOCK_FD}<"$LOCK_BOUND_PATH" || {
    error "installation lock could not be bound: $LOCK_PATH"
    return 1
  }
  LOCK_BOUND_ROOT="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$LOCK_FD"
  bound_identity="$(bound_directory_identity "$LOCK_BOUND_ROOT")" \
    || return 1
  if [ "$bound_identity" != "$LOCK_ID" ]; then
    error "installation lock changed while it was being bound: $LOCK_PATH"
    return 1
  fi
}

verify_destination_parent() {
  local context="$1"
  local bound_identity

  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$DEST_PARENT_BOUND" 2>/dev/null)" \
    || {
      error "destination parent binding was lost $context: $DEST_PARENT"
      return 1
    }
  if [ "$bound_identity" != "$DEST_PARENT_ID" ] \
    || [ -L "$DEST_PARENT" ] \
    || [ ! -d "$DEST_PARENT" ] \
    || [ "$(path_identity "$DEST_PARENT")" != "$DEST_PARENT_ID" ]; then
    error "destination parent changed $context: $DEST_PARENT"
    return 1
  fi
  require_owned_path "$DEST_PARENT" || return 1
}

validate_tracked_index_flags() {
  local checkout="$1"
  local entry
  local tag

  if ! safe_git -C "$checkout" ls-files -v -z -- \
    | while IFS= read -r -d '' entry; do
      if [ "${#entry}" -lt 3 ] || [ "${entry:1:1}" != " " ]; then
        error "could not validate tracked index flags for checkout: $checkout"
        exit 1
      fi
      tag="${entry:0:1}"
      case "$tag" in
        H)
          ;;
        S|[a-z])
          error "checkout contains unsafe tracked index flags (assume-unchanged or skip-worktree): $checkout"
          exit 1
          ;;
        *)
          ;;
      esac
    done; then
    return 1
  fi
}

validate_local_git_config() {
  local checkout="$1"
  local config_output
  local entry
  local required
  local -A seen=()

  if [ -L "$checkout/.git/config" ] \
    || [ ! -f "$checkout/.git/config" ] \
    || [ "$(stat -c '%h' -- "$checkout/.git/config")" -ne 1 ]; then
    error "checkout Git config must be a single-link physical file: $checkout/.git/config"
    return 1
  fi
  config_output="$(
    config_git config --file "$checkout/.git/config" \
      --no-includes --list
  )" || {
    error "checkout local Git configuration could not be parsed safely"
    return 1
  }
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    case "$entry" in
      core.repositoryformatversion=0|core.filemode=true|core.filemode=false|core.bare=false|core.logallrefupdates=true|remote.origin.url="$REPO_URL"|remote.origin.fetch='+refs/heads/*:refs/remotes/origin/*'|remote.origin.fetch=+refs/heads/master:refs/remotes/origin/master|remote.origin.tagopt=--no-tags|branch.master.remote=origin|branch.master.merge=refs/heads/master)
        ;;
      remote.origin.url=*)
        error "checkout must use the canonical origin $REPO_URL; found ${entry#*=}."
        return 1
        ;;
      *)
        error "checkout contains unmanaged local Git configuration: ${entry%%=*}"
        return 1
        ;;
    esac
    seen["${entry%%=*}"]=$(( ${seen["${entry%%=*}"]:-0} + 1 ))
  done <<< "$config_output"

  for required in \
    core.repositoryformatversion \
    core.filemode \
    core.bare \
    core.logallrefupdates \
    remote.origin.url \
    remote.origin.fetch \
    branch.master.remote \
    branch.master.merge; do
    if [ "${seen[$required]:-0}" -ne 1 ]; then
      error "checkout local Git configuration must contain exactly one $required"
      return 1
    fi
  done
  if [ "${seen[remote.origin.tagopt]:-0}" -gt 1 ]; then
    error "checkout local Git configuration repeats remote.origin.tagopt"
    return 1
  fi
}

validate_tracked_modes() {
  local checkout="$1"
  local entry
  local metadata
  local mode
  local path

  if ! safe_git -C "$checkout" ls-files --stage -z -- \
    | while IFS= read -r -d '' entry; do
      metadata="${entry%%$'\t'*}"
      path="${entry#*$'\t'}"
      mode="${metadata%% *}"
      case "$mode" in
        100644|100755)
          if [ -L "$checkout/$path" ] || [ ! -f "$checkout/$path" ]; then
            error "tracked file type differs from the index: $checkout/$path"
            exit 1
          fi
          if { [ "$mode" = 100644 ] && [ -x "$checkout/$path" ]; } \
            || { [ "$mode" = 100755 ] && [ ! -x "$checkout/$path" ]; }; then
            error "tracked file mode differs from the index: $checkout/$path"
            exit 1
          fi
          ;;
        120000)
          if [ ! -L "$checkout/$path" ]; then
            error "tracked symlink type differs from the index: $checkout/$path"
            exit 1
          fi
          ;;
        *)
          error "unsupported tracked index mode $mode: $checkout/$path"
          exit 1
          ;;
      esac
    done; then
    return 1
  fi
}

validate_no_unreachable_objects() {
  local checkout="$1"
  local unreachable

  unreachable="$(
    safe_git -C "$checkout" fsck \
      --full --unreachable --no-reflogs --no-progress 2>&1
  )" || {
    error "checkout Git objects could not be verified: $checkout"
    return 1
  }
  if [ -n "$unreachable" ]; then
    error "checkout contains recoverable Git objects outside managed refs: $checkout"
    return 1
  fi
}

validate_no_empty_worktree_directories() {
  local checkout="$1"
  local empty_directory

  empty_directory="$(
    find "$checkout" -path "$checkout/.git" -prune -o \
      -type d -empty -print -quit
  )" || return 1
  if [ -n "$empty_directory" ]; then
    error "checkout contains an untracked empty directory that would be lost: $empty_directory"
    return 1
  fi
}

validate_managed_refs() {
  local checkout="$1"
  local ref

  if ! safe_git -C "$checkout" for-each-ref --format='%(refname)' refs \
    | while IFS= read -r ref; do
      case "$ref" in
        refs/heads/master|refs/remotes/origin/HEAD|refs/remotes/origin/master)
          ;;
        *)
          error "checkout contains an unmanaged Git ref that would be lost: $ref"
          exit 1
          ;;
      esac
    done; then
    return 1
  fi
}

validate_checkout() {
  local checkout="$1"
  local expected_identity="${2:-}"
  local inspect_recoverable_objects="${3:-0}"
  local expected_head="${4:-}"
  local checkout_mode="${5:-requested}"
  local current_branch
  local head
  local local_branches
  local remote_head
  local status
  local top_level

  if [ -L "$checkout" ] || [ ! -d "$checkout" ]; then
    error "checkout must be a physical directory: $checkout"
    return 1
  fi
  if [ -n "$expected_identity" ] \
    && [ "$(path_identity "$checkout")" != "$expected_identity" ]; then
    error "checkout changed during installation: $checkout"
    return 1
  fi
  require_owned_path "$checkout" || return 1
  if [ -L "$checkout/.git" ] || [ ! -d "$checkout/.git" ]; then
    error "checkout Git metadata must be a physical directory: $checkout/.git"
    return 1
  fi
  if [ -e "$checkout/.git/worktrees" ] \
    || [ -L "$checkout/.git/worktrees" ]; then
    error "checkout has linked worktrees and cannot be relocated safely: $checkout"
    return 1
  fi
  validate_local_git_config "$checkout" || return 1
  top_level="$(safe_git -C "$checkout" rev-parse --show-toplevel 2>/dev/null)" || {
    error "installation destination is not a Git checkout: $checkout"
    return 1
  }
  if [ "$top_level" != "$checkout" ]; then
    error "checkout root does not match the installation destination: $checkout"
    return 1
  fi
  current_branch="$(
    safe_git -C "$checkout" symbolic-ref --quiet HEAD 2>/dev/null || true
  )"
  local_branches="$(
    safe_git -C "$checkout" for-each-ref \
      --format='%(refname)' refs/heads 2>/dev/null || true
  )"
  head="$(safe_git -C "$checkout" rev-parse --verify HEAD 2>/dev/null || true)"
  remote_head="$(
    safe_git -C "$checkout" rev-parse \
      --verify refs/remotes/origin/master 2>/dev/null || true
  )"
  if [ "$checkout_mode" = requested ]; then
    if [ -n "$RELEASE_REF" ]; then
      checkout_mode=release
    else
      checkout_mode=edge
    fi
  fi
  if [ "$checkout_mode" = release ]; then
    if [ -n "$current_branch" ] || [ -z "$head" ]; then
      error "checkout must use detached HEAD in immutable release mode: $checkout"
      return 1
    fi
    if [ -n "$expected_head" ] && [ "$head" != "$expected_head" ]; then
      error "checkout HEAD $head does not match expected release commit $expected_head: $checkout"
      return 1
    fi
  elif [ "$checkout_mode" = edge ]; then
    if [ "$current_branch" != "refs/heads/master" ] \
      || [ "$local_branches" != "refs/heads/master" ] \
      || [ -z "$head" ] \
      || [ "$head" != "$remote_head" ]; then
      error "checkout must be a managed branch with only master tracking and matching origin/master: $checkout"
      return 1
    fi
  else
    error "unknown checkout validation mode: $checkout_mode"
    return 1
  fi
  validate_managed_refs "$checkout" || return 1
  validate_tracked_index_flags "$checkout" || return 1
  validate_tracked_modes "$checkout" || return 1
  if [ "$inspect_recoverable_objects" -eq 1 ]; then
    validate_no_unreachable_objects "$checkout" || return 1
  fi
  status="$(
    safe_git -C "$checkout" status \
      --porcelain=v1 \
      --untracked-files=all \
      --ignored=matching
  )" || return 1
  if [ -n "$status" ]; then
    error "checkout must be clean and contain no ignored local entries before installation: $checkout"
    return 1
  fi
  validate_no_empty_worktree_directories "$checkout" || return 1
}

validate_candidate() {
  local expected_identity="${1:-}"
  local registrar="$CANDIDATE/scripts/register-skills.sh"
  local remote_head

  validate_checkout "$CANDIDATE" "$expected_identity" 0 "$RELEASE_REF" || return 1
  if [ -L "$CANDIDATE/.agents" ] \
    || [ ! -d "$CANDIDATE/.agents" ] \
    || [ -L "$CANDIDATE/.agents/skills" ] \
    || [ ! -d "$CANDIDATE/.agents/skills" ]; then
    error "candidate skills must be a physical directory: $CANDIDATE/.agents/skills"
    return 1
  fi
  if [ -L "$CANDIDATE/scripts" ] \
    || [ ! -d "$CANDIDATE/scripts" ] \
    || [ -L "$registrar" ] \
    || [ ! -f "$registrar" ]; then
    error "registrar must be a physical file: $registrar"
    return 1
  fi
  CANDIDATE_HEAD="$(safe_git -C "$CANDIDATE" rev-parse HEAD)" || return 1
  if [ -z "$RELEASE_REF" ]; then
    remote_head="$(safe_git -C "$CANDIDATE" rev-parse refs/remotes/origin/master 2>/dev/null)" || {
      error "canonical origin has no master ref."
      return 1
    }
    if [ "$CANDIDATE_HEAD" != "$remote_head" ]; then
      error "candidate HEAD does not match canonical origin/master."
      return 1
    fi
  fi
}

validate_prior_checkout() {
  validate_checkout \
    "$PRIOR" "$ORIGINAL_DEST_ID" 0 "$ORIGINAL_HEAD" "$ORIGINAL_CHECKOUT_MODE" \
    || return 1
  if [ "$(safe_git -C "$PRIOR" rev-parse HEAD)" != "$ORIGINAL_HEAD" ]; then
    error "prior checkout HEAD changed during installation: $PRIOR"
    return 1
  fi
}

snapshot_discovery_paths() {
  local bound_identity
  local bound_path
  local identity
  local path
  local parent
  local parent_fd
  local uid
  local expected_source="$DEST/.agents/skills"

  DISCOVERY_PATHS=(
    "$HOME_ROOT/.agents/skills"
    "$HOME_ROOT/.cursor/skills"
  )
  for path in "${DISCOVERY_PATHS[@]}"; do
    parent="$(dirname -- "$path")"
    if [ -L "$parent" ]; then
      error "discovery parent must not be a symlink: $parent"
      return 1
    fi
    if [ -e "$parent" ] && [ ! -d "$parent" ]; then
      error "discovery parent must be a directory or absent: $parent"
      return 1
    fi
    if [ -d "$parent" ]; then
      require_physical_directory "$parent" "discovery parent" || return 1
      require_owned_path "$parent" || return 1
      identity="$(path_identity "$parent")" || return 1
      uid="$(stat -c '%u' -- "$parent")" || return 1
      exec {parent_fd}<"$parent" || {
        error "discovery parent could not be bound: $parent"
        return 1
      }
      bound_path="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$parent_fd"
      bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$bound_path")" \
        || return 1
      if [ "$bound_identity" != "$identity" ]; then
        error "discovery parent changed while it was being bound: $parent"
        return 1
      fi
      DISCOVERY_PARENT_STATES+=(directory)
      DISCOVERY_PARENT_IDS+=("$identity")
      DISCOVERY_PARENT_UIDS+=("$uid")
      DISCOVERY_PARENT_FDS+=("$parent_fd")
      DISCOVERY_PARENT_BOUNDS+=("$bound_path")
    else
      DISCOVERY_PARENT_STATES+=(absent)
      DISCOVERY_PARENT_IDS+=(absent)
      DISCOVERY_PARENT_UIDS+=("")
      DISCOVERY_PARENT_FDS+=("")
      DISCOVERY_PARENT_BOUNDS+=("")
    fi
    DISCOVERY_PARENT_CREATED+=(0)
    DISCOVERY_CREATED_IDS+=("")
    DISCOVERY_QUARANTINES+=("")

    if [ -L "$path" ]; then
      DISCOVERY_STATES+=(symlink)
      DISCOVERY_TARGETS+=("$(readlink -- "$path")")
      DISCOVERY_UIDS+=("$(stat -c '%u' -- "$path")")
      DISCOVERY_IDS+=("$(path_identity "$path")")
      if [ "${DISCOVERY_TARGETS[${#DISCOVERY_TARGETS[@]}-1]}" != "$expected_source" ]; then
        error "discovery path is already a different symlink: $path"
        return 1
      fi
      require_owned_path "$path" || return 1
    elif [ -e "$path" ]; then
      error "discovery path must be absent or the expected symlink: $path"
      return 1
    else
      DISCOVERY_STATES+=(absent)
      DISCOVERY_TARGETS+=("")
      DISCOVERY_UIDS+=("")
      DISCOVERY_IDS+=(absent)
    fi
  done
  DISCOVERY_SNAPSHOT_READY=1
}

verify_discovery_parent() {
  local index="$1"
  local phase="$2"
  local path="${DISCOVERY_PATHS[$index]}"
  local parent
  local expected_identity="${DISCOVERY_PARENT_IDS[$index]}"
  local expected_uid="${DISCOVERY_PARENT_UIDS[$index]}"
  local bound_path="${DISCOVERY_PARENT_BOUNDS[$index]}"
  local bound_identity
  local actual_identity
  local actual_uid
  local physical

  parent="$(dirname -- "$path")"
  verify_home "$phase" || return 1
  if [ "$expected_identity" = "absent" ]; then
    if [ -n "$bound_path" ] || [ -e "$parent" ] || [ -L "$parent" ]; then
      error "discovery parent changed $phase: $parent"
      return 1
    fi
    return 0
  fi
  if [ "$expected_identity" = "unverified" ] \
    || [ -L "$parent" ] \
    || [ ! -d "$parent" ]; then
    error "discovery parent changed $phase: $parent"
    return 1
  fi
  physical="$(cd "$parent" && pwd -P)" || return 1
  actual_identity="$(path_identity "$parent")" || return 1
  actual_uid="$(stat -c '%u' -- "$parent")" || return 1
  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$bound_path" 2>/dev/null)" \
    || return 1
  if [ "$physical" != "$parent" ] \
    || [ "$actual_identity" != "$expected_identity" ] \
    || [ "$bound_identity" != "$expected_identity" ] \
    || [ "$actual_uid" != "$expected_uid" ] \
    || [ "$actual_uid" != "$EXPECTED_UID" ]; then
    error "discovery parent changed $phase: $parent"
    return 1
  fi
}

verify_discovery_parents() {
  local phase="$1"
  local index

  for index in "${!DISCOVERY_PATHS[@]}"; do
    verify_discovery_parent "$index" "$phase" || return 1
  done
}

prepare_discovery_parents() {
  local index
  local parent
  local parent_base
  local parent_bound_entry
  local parent_bound
  local parent_fd
  local bound_identity
  local created_identity
  local created_uid

  verify_discovery_parents "before parent creation" || return 1
  for index in "${!DISCOVERY_PATHS[@]}"; do
    if [ "${DISCOVERY_PARENT_STATES[$index]}" != "absent" ]; then
      continue
    fi
    parent="$(dirname -- "${DISCOVERY_PATHS[$index]}")"
    parent_base="$(basename -- "$parent")"
    parent_bound_entry="$HOME_BOUND/$parent_base"
    begin_transition
    if ! verify_home "before discovery parent creation" \
      || ! mkdir -m 755 -- "$parent_bound_entry"; then
      end_transition
      error "discovery parent changed before creation: $parent"
      return 1
    fi
    DISCOVERY_PARENT_CREATED[$index]=1
    DISCOVERY_PARENT_IDS[$index]=unverified
    DISCOVERY_PARENT_UIDS[$index]=""
    if [ -L "$parent" ] \
      || [ ! -d "$parent" ] \
      || ! require_physical_directory "$parent" "created discovery parent" \
      || ! require_owned_path "$parent"; then
      end_transition
      return 1
    fi
    created_identity="$(path_identity "$parent")" || {
      end_transition
      return 1
    }
    created_uid="$(stat -c '%u' -- "$parent")" || {
      end_transition
      return 1
    }
    exec {parent_fd}<"$parent_bound_entry" || {
      end_transition
      return 1
    }
    parent_bound="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$parent_fd"
    bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$parent_bound")" \
      || {
        end_transition
        return 1
      }
    if [ "$bound_identity" != "$created_identity" ]; then
      error "created discovery parent changed while it was being bound: $parent"
      end_transition
      return 1
    fi
    DISCOVERY_PARENT_IDS[$index]="$created_identity"
    DISCOVERY_PARENT_UIDS[$index]="$created_uid"
    DISCOVERY_PARENT_FDS[$index]="$parent_fd"
    DISCOVERY_PARENT_BOUNDS[$index]="$parent_bound"
    end_transition
  done
  verify_discovery_parents "after parent creation"
}

verify_discovery_snapshot() {
  local index
  local path
  local bound_path

  verify_discovery_parents "during discovery revalidation" || return 1
  for index in "${!DISCOVERY_PATHS[@]}"; do
    path="${DISCOVERY_PATHS[$index]}"
    bound_path="${DISCOVERY_PARENT_BOUNDS[$index]}"
    if [ -n "$bound_path" ]; then
      bound_path="$bound_path/$(basename -- "$path")"
    fi
    if [ "${DISCOVERY_STATES[$index]}" = "absent" ]; then
      if [ -e "$path" ] || [ -L "$path" ] \
        || { [ -n "$bound_path" ] \
          && { [ -e "$bound_path" ] || [ -L "$bound_path" ]; }; }; then
        error "discovery path changed during staging: $path"
        return 1
      fi
    elif [ ! -L "$path" ] \
      || [ "$(readlink -- "$path")" != "${DISCOVERY_TARGETS[$index]}" ] \
      || [ "$(stat -c '%u' -- "$path")" != "${DISCOVERY_UIDS[$index]}" ] \
      || [ "$(path_identity "$path")" != "${DISCOVERY_IDS[$index]}" ]; then
      error "discovery path changed during staging: $path"
      return 1
    fi
  done
}

verify_registered_discovery_paths() {
  local index
  local path
  local bound_path
  local expected_source="$DEST/.agents/skills"

  verify_discovery_parents "during registration postcondition" || return 1
  for index in "${!DISCOVERY_PATHS[@]}"; do
    path="${DISCOVERY_PATHS[$index]}"
    bound_path="${DISCOVERY_PARENT_BOUNDS[$index]}/$(basename -- "$path")"
    if [ ! -L "$path" ] \
      || [ ! -L "$bound_path" ] \
      || [ "$(readlink -- "$path")" != "$expected_source" ] \
      || [ "$(readlink -- "$bound_path")" != "$expected_source" ] \
      || [ "$(stat -c '%u' -- "$path")" != "$EXPECTED_UID" ] \
      || [ "$(path_identity "$path")" != "$(path_identity "$bound_path")" ]; then
      error "registration postcondition failed: $path"
      return 1
    fi
  done
  verify_discovery_parents "after registration postcondition"
}

register_discovery_paths() {
  local index
  local path
  local bound_path
  local created_identity
  local expected_source="$DEST/.agents/skills"

  verify_discovery_snapshot || return 1
  for index in "${!DISCOVERY_PATHS[@]}"; do
    if [ "${DISCOVERY_STATES[$index]}" != "absent" ]; then
      continue
    fi
    path="${DISCOVERY_PATHS[$index]}"
    bound_path="${DISCOVERY_PARENT_BOUNDS[$index]}/$(basename -- "$path")"
    begin_transition
    if ! verify_discovery_parent "$index" "before registration" \
      || [ -e "$bound_path" ] \
      || [ -L "$bound_path" ] \
      || ! ln -s -- "$expected_source" "$bound_path"; then
      end_transition
      error "discovery path changed before registration: $path"
      return 1
    fi
    created_identity="$(path_identity "$bound_path")" || {
      end_transition
      return 1
    }
    DISCOVERY_CREATED_IDS[$index]="$created_identity"
    if [ ! -L "$path" ] \
      || [ "$(path_identity "$path")" != "$created_identity" ] \
      || [ "$(readlink -- "$path")" != "$expected_source" ] \
      || [ "$(stat -c '%u' -- "$path")" != "$EXPECTED_UID" ]; then
      end_transition
      error "registered discovery path could not be verified: $path"
      return 1
    fi
    end_transition
  done
  verify_registered_discovery_paths
}

verify_lock() {
  verify_destination_parent "while checking the installation lock" || return 1
  if [ "$LOCK_HELD" -ne 1 ] \
    || [ "$(bound_directory_identity "$LOCK_BOUND_ROOT" 2>/dev/null || true)" \
      != "$LOCK_ID" ] \
    || [ -L "$LOCK_BOUND_PATH" ] \
    || [ ! -d "$LOCK_BOUND_PATH" ] \
    || [ "$(path_identity "$LOCK_BOUND_PATH")" != "$LOCK_ID" ] \
    || [ -L "$LOCK_PATH" ] \
    || [ ! -d "$LOCK_PATH" ] \
    || [ "$(path_identity "$LOCK_PATH")" != "$LOCK_ID" ]; then
    error "installation lock changed while held: $LOCK_PATH"
    return 1
  fi
}

acquire_lock() {
  local acquired_identity
  LOCK_PATH="$DEST_PARENT/.$DEST_BASE.install.lock"
  LOCK_BOUND_PATH="$DEST_PARENT_BOUND/.$DEST_BASE.install.lock"
  begin_transition
  if ! verify_destination_parent "before lock acquisition"; then
    end_transition
    return 1
  fi
  if ! mkdir -m 700 -- "$LOCK_BOUND_PATH" 2>/dev/null; then
    end_transition
    error "installation already in progress for $DEST"
    return 1
  fi
  LOCK_HELD=1
  if ! acquired_identity="$(path_identity "$LOCK_BOUND_PATH")"; then
    error "installation lock identity could not be recorded: $LOCK_PATH"
    end_transition
    return 1
  fi
  LOCK_ID="$acquired_identity"
  if ! bind_lock_directory \
    || ! require_owned_path "$LOCK_BOUND_PATH" \
    || ! verify_destination_parent "after lock acquisition"; then
    end_transition
    return 1
  fi
  end_transition
}

move_directory_no_replace() {
  local source="$1"
  local target="$2"
  local expected_identity="$3"
  local source_label="${4:-$source}"
  local target_label="${5:-$target}"
  local move_status=0
  local moved_identity=""

  if [ -L "$source" ] \
    || [ ! -d "$source" ] \
    || [ "$(path_identity "$source")" != "$expected_identity" ]; then
    error "move source changed before transition: $source_label"
    return 1
  fi
  mv -Tn -- "$source" "$target" || move_status="$?"
  if [ -d "$target" ] \
    && [ ! -L "$target" ] \
    && [ "$(path_identity "$target")" = "$expected_identity" ]; then
    return 0
  fi
  if [ "$move_status" -ne 0 ] \
    && [ -d "$source" ] \
    && [ ! -L "$source" ] \
    && [ "$(path_identity "$source")" = "$expected_identity" ] \
    && [ ! -e "$target" ] \
    && [ ! -L "$target" ]; then
    error "checkout transition failed from $source_label to $target_label."
    return 1
  fi
  if [ ! -e "$source" ] \
    && [ ! -L "$source" ] \
    && [ -d "$target" ] \
    && [ ! -L "$target" ]; then
    moved_identity="$(path_identity "$target")" || true
    if [ -n "$moved_identity" ] \
      && mv -Tn -- "$target" "$source" \
      && [ "$(path_identity "$source")" = "$moved_identity" ]; then
      error "checkout transition moved an unexpected replacement and restored it at $source_label."
      return 1
    fi
  fi
  STAGE_VERIFIED=0
  if [ "$move_status" -ne 0 ]; then
    error "checkout transition failed from $source_label to $target_label."
  else
    error "checkout transition was blocked by a changed target: $target_label"
  fi
  return 1
}

retire_empty_directory() {
  local source="$1"
  local expected_identity="$2"
  local source_label="$3"
  local suffix="$4"
  local allow_source_replacement="${5:-0}"
  local parent_bound
  local parent_label
  local target
  local target_base
  local target_label

  RETIRE_SEQUENCE=$((RETIRE_SEQUENCE + 1))
  parent_bound="$(dirname -- "$source")" || return 1
  parent_label="$(resolve_bound_directory \
    "$parent_bound" "$(dirname -- "$source_label")")" || return 1
  target="$source.$suffix.$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID.$RETIRE_SEQUENCE"
  target_base="$(basename -- "$target")" || return 1
  target_label="$parent_label/$target_base"

  if [ -e "$target" ] || [ -L "$target" ]; then
    cleanup_issue "Recovery required: isolated retirement target already exists and was preserved: $target_label"
    return 1
  fi
  if [ -n "$(find "$source" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    cleanup_issue "Recovery required: directory was not empty and was retained: $source_label"
    return 1
  fi
  if ! move_directory_no_replace \
    "$source" "$target" "$expected_identity" "$source_label" "$target_label"; then
    return 1
  fi
  if [ "$(path_identity "$target")" != "$expected_identity" ]; then
    cleanup_issue "Recovery required: retired directory changed and was preserved: $target_label"
    return 1
  fi
  if ! rmdir -- "$target"; then
    cleanup_issue "Recovery required: retired empty directory was retained at $target_label"
    return 1
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    cleanup_issue "Recovery required: retirement target changed and was preserved: $target_label"
    return 1
  fi
  if [ "$allow_source_replacement" -ne 1 ] \
    && { [ -e "$source" ] || [ -L "$source" ]; }; then
    cleanup_issue "Recovery required: a concurrent replacement was preserved at $source_label"
    return 1
  fi
}

verify_stage() {
  local phase="$1"
  local bound_identity

  if [ -z "$STAGE_FD" ]; then
    error "staging directory is not bound $phase"
    return 1
  fi
  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$STAGE_BOUND_ROOT" 2>/dev/null)" \
    || return 1
  if [ "$bound_identity" != "$STAGE_ID" ] \
    || [ -L "$STAGE_ROOT" ] \
    || [ ! -d "$STAGE_ROOT" ] \
    || [ "$(path_identity "$STAGE_ROOT")" != "$STAGE_ID" ]; then
    error "staging directory changed $phase: $STAGE_ROOT"
    return 1
  fi
}

move_original_to_prior() {
  begin_transition
  if ! verify_destination_parent "before moving the existing checkout"; then
    end_transition
    return 1
  fi
  if ! verify_stage "before moving the existing checkout" \
    || ! move_directory_no_replace \
      "$DEST_BOUND" "$PRIOR_BOUND" "$ORIGINAL_DEST_ID" "$DEST" "$PRIOR"; then
    end_transition
    return 1
  fi
  PRIOR_MOVED=1
  if ! verify_destination_parent "after moving the existing checkout" \
    || ! verify_stage "after moving the existing checkout"; then
    end_transition
    return 1
  fi
  end_transition
}

activate_candidate() {
  begin_transition
  if ! verify_destination_parent "before activating the candidate"; then
    end_transition
    return 1
  fi
  if ! verify_stage "before activating the candidate" \
    || ! move_directory_no_replace \
      "$CANDIDATE_BOUND" "$DEST_BOUND" "$CANDIDATE_ID" \
      "$CANDIDATE" "$DEST"; then
    end_transition
    return 1
  fi
  NEW_ACTIVE=1
  NEW_ID="$CANDIDATE_ID"
  if ! verify_destination_parent "after activating the candidate" \
    || ! verify_stage "after activating the candidate"; then
    end_transition
    return 1
  fi
  end_transition
}

create_stage() {
  local created_stage
  local stage_base
  local stage_entry_bound
  local bound_identity

  begin_transition
  if ! verify_destination_parent "before stage creation"; then
    end_transition
    return 1
  fi
  if ! created_stage="$(
    mktemp -d "$DEST_PARENT_BOUND/.$DEST_BASE.stage.XXXXXX"
  )"; then
    end_transition
    return 1
  fi
  stage_base="$(basename -- "$created_stage")" || {
    end_transition
    return 1
  }
  STAGE_ROOT="$DEST_PARENT/$stage_base"
  STAGE_BOUND_ROOT="$DEST_PARENT_BOUND/$stage_base"
  case "$STAGE_ROOT" in
    "$DEST_PARENT/.$DEST_BASE.stage."*) ;;
    *)
      error "temporary checkout escaped the destination parent: $STAGE_ROOT"
      end_transition
      return 1
      ;;
  esac
  stage_entry_bound="$DEST_PARENT_BOUND/$stage_base"
  STAGE_ENTRY_BOUND="$stage_entry_bound"
  if ! verify_destination_parent "after stage creation" \
    || ! require_physical_directory "$STAGE_ROOT" "staging directory" \
    || ! require_owned_path "$STAGE_ROOT"; then
    end_transition
    return 1
  fi
  STAGE_ID="$(path_identity "$stage_entry_bound")" || {
    end_transition
    return 1
  }
  exec {STAGE_FD}<"$stage_entry_bound" || {
    end_transition
    return 1
  }
  STAGE_BOUND_ROOT="/proc/$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID/fd/$STAGE_FD"
  bound_identity="directory:$(stat -Lc '%d:%i:%u' -- "$STAGE_BOUND_ROOT")" \
    || {
      end_transition
      return 1
    }
  if [ "$bound_identity" != "$STAGE_ID" ]; then
    error "staging directory changed while it was being bound: $STAGE_ROOT"
    end_transition
    return 1
  fi
  STAGE_VERIFIED=1
  CANDIDATE="$STAGE_ROOT/candidate"
  CANDIDATE_BOUND="$STAGE_BOUND_ROOT/candidate"
  PRIOR="$STAGE_ROOT/prior"
  PRIOR_BOUND="$STAGE_BOUND_ROOT/prior"
  FAILED_CANDIDATE="$STAGE_ROOT/failed-candidate"
  FAILED_CANDIDATE_BOUND="$STAGE_BOUND_ROOT/failed-candidate"
  end_transition
}

safe_remove_stage() {
  local entry
  local entry_bound
  local entries=()
  local expected_identity
  local expected_head
  local expected_mode
  local retain_failed_candidate=0
  local retain_prior=0

  if [ -z "$STAGE_ROOT" ]; then
    return 0
  fi
  if [ ! -e "$STAGE_ROOT" ] && [ ! -L "$STAGE_ROOT" ]; then
    cleanup_issue "Recovery required: recorded staging path disappeared before cleanup: $STAGE_ROOT (expected identity $STAGE_ID). Transaction material may have been moved."
    return 1
  fi
  if [ "$STAGE_VERIFIED" -ne 1 ]; then
    cleanup_issue "Recovery required: unverified transaction material retained at $STAGE_ROOT"
    return 1
  fi
  if ! verify_destination_parent "before stage cleanup" \
    || ! verify_stage "before cleanup"; then
    cleanup_issue "Recovery required: staging path changed and was retained at $STAGE_ROOT"
    return 1
  fi

  shopt -s nullglob dotglob
  entries=("$STAGE_ROOT"/*)
  shopt -u nullglob dotglob
  for entry in "${entries[@]}"; do
    expected_identity=""
    expected_head=""
    expected_mode=requested
    case "$entry" in
      "$CANDIDATE")
        if [ -z "$CANDIDATE_ID" ]; then
          CANDIDATE_ID="$(path_identity "$entry")" || return 1
        fi
        if [ -z "$CANDIDATE_HEAD" ]; then
          CANDIDATE_HEAD="$(
            safe_git -C "$entry" rev-parse HEAD 2>/dev/null || true
          )"
        fi
        expected_identity="$CANDIDATE_ID"
        expected_head="$CANDIDATE_HEAD"
        ;;
      "$PRIOR")
        expected_identity="$ORIGINAL_DEST_ID"
        expected_head="$ORIGINAL_HEAD"
        expected_mode="$ORIGINAL_CHECKOUT_MODE"
        retain_prior=1
        ;;
      "$FAILED_CANDIDATE")
        expected_identity="$CANDIDATE_ID"
        expected_head="$CANDIDATE_HEAD"
        retain_failed_candidate=1
        ;;
      *)
        cleanup_issue "Recovery required: unexpected transaction material was retained at $entry"
        return 1
        ;;
    esac
    if [ -z "$expected_identity" ] \
      || [ -z "$expected_head" ] \
      || ! validate_checkout \
        "$entry" "$expected_identity" 0 "$expected_head" "$expected_mode" \
      || [ "$(safe_git -C "$entry" rev-parse HEAD 2>/dev/null || true)" != "$expected_head" ]; then
      cleanup_issue "Recovery required: unverified transaction material was retained at $entry"
      return 1
    fi
  done

  for entry in "${entries[@]}"; do
    if ! verify_destination_parent "during stage cleanup" \
      || [ "$(path_identity "$STAGE_ROOT")" != "$STAGE_ID" ]; then
      cleanup_issue "Recovery required: staging path changed and was retained at $STAGE_ROOT"
      return 1
    fi
    case "$entry" in
      "$CANDIDATE")
        expected_identity="$CANDIDATE_ID"
        entry_bound="$CANDIDATE_BOUND"
        ;;
      "$FAILED_CANDIDATE")
        continue
        ;;
      "$PRIOR")
        continue
        ;;
    esac
    if [ "$(path_identity "$entry")" != "$expected_identity" ]; then
      cleanup_issue "Recovery required: transaction material changed and was retained at $entry"
      return 1
    fi
    if ! (
      cd -- "$entry_bound" || exit 1
      if [ "$(path_identity .)" != "$expected_identity" ]; then
        exit 1
      fi
      find . -xdev -depth -mindepth 1 -delete
    ); then
      cleanup_issue "Recovery required: verified transaction material could not be cleaned at $entry"
      return 1
    fi
    if [ -L "$entry_bound" ] \
      || [ ! -d "$entry_bound" ] \
      || [ "$(path_identity "$entry_bound")" != "$expected_identity" ] \
      || [ "$(path_identity "$entry")" != "$expected_identity" ]; then
      cleanup_issue "Recovery required: cleaned transaction material moved or changed and was retained: $entry"
      return 1
    fi
    if ! retire_empty_directory \
      "$entry_bound" "$expected_identity" "$entry" retire 0; then
      return 1
    fi
  done

  if [ "$retain_prior" -eq 1 ] || [ "$retain_failed_candidate" -eq 1 ]; then
    verify_stage "before retaining recovery checkouts" || return 1
  fi
  if [ "$retain_prior" -eq 1 ]; then
    if [ "$(path_identity "$PRIOR_BOUND")" != "$ORIGINAL_DEST_ID" ]; then
      cleanup_issue "Recovery required: prior checkout moved or changed and was not cleaned: $PRIOR"
      return 1
    fi
    warning "Previous checkout retained for recovery at $(resolve_bound_directory "$PRIOR_BOUND" "$PRIOR") (identity $ORIGINAL_DEST_ID; HEAD $ORIGINAL_HEAD)."
  fi
  if [ "$retain_failed_candidate" -eq 1 ]; then
    if [ "$(path_identity "$FAILED_CANDIDATE_BOUND")" != "$CANDIDATE_ID" ]; then
      cleanup_issue "Recovery required: failed candidate moved or changed and was not cleaned: $FAILED_CANDIDATE"
      return 1
    fi
    warning "Recovery required: once-visible failed candidate retained at $(resolve_bound_directory "$FAILED_CANDIDATE_BOUND" "$FAILED_CANDIDATE") (identity $CANDIDATE_ID; HEAD $CANDIDATE_HEAD)."
  fi
  if [ "$retain_prior" -eq 1 ] || [ "$retain_failed_candidate" -eq 1 ]; then
    return 0
  fi

  if ! verify_destination_parent "after stage cleanup" \
    || ! verify_stage "after entry cleanup" \
    || [ -n "$(find "$STAGE_BOUND_ROOT" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    cleanup_issue "Recovery required: staging directory changed and was retained at $STAGE_ROOT"
    return 1
  fi
  if ! retire_empty_directory \
    "$STAGE_ENTRY_BOUND" "$STAGE_ID" \
    "$(resolve_bound_directory "$STAGE_BOUND_ROOT" "$STAGE_ROOT")" retire 0; then
    return 1
  fi
}

restore_discovery_paths() {
  local index
  local path
  local parent
  local parent_base
  local bound_parent
  local bound_path
  local quarantine_name
  local quarantine_bound
  local quarantine_path
  local created_identity
  local moved_identity
  local failed=0

  for index in "${!DISCOVERY_PATHS[@]}"; do
    path="${DISCOVERY_PATHS[$index]}"
    parent="$(dirname -- "$path")"
    parent_base="$(basename -- "$parent")"
    bound_parent="${DISCOVERY_PARENT_BOUNDS[$index]}"
    bound_path=""
    if [ -n "$bound_parent" ]; then
      bound_path="$bound_parent/$(basename -- "$path")"
    fi
    if ! verify_discovery_parent "$index" "during rollback"; then
      error "Recovery required: discovery parent changed and was preserved: $parent"
      failed=1
      continue
    fi
    if [ "${DISCOVERY_STATES[$index]}" = "absent" ]; then
      created_identity="${DISCOVERY_CREATED_IDS[$index]}"
      if [ -n "$created_identity" ]; then
        quarantine_name=".agent-ecosystem.rollback-link.$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID.$index"
        quarantine_bound="$bound_parent/$quarantine_name"
        quarantine_path="$parent/$quarantine_name"
        if [ -e "$quarantine_bound" ] || [ -L "$quarantine_bound" ] \
          || ! mv -Tn -- "$bound_path" "$quarantine_bound"; then
          error "Recovery required: discovery link could not be quarantined and was preserved: $path"
          failed=1
        else
          moved_identity="$(path_identity "$quarantine_bound")" || true
          if [ "$moved_identity" = "$created_identity" ]; then
            DISCOVERY_QUARANTINES[$index]="$quarantine_path"
            warning "Rollback recovery retained the installer-created link at $quarantine_path (identity $created_identity)."
          else
            error "Recovery required: a changed discovery entry was retained at $quarantine_path (identity ${moved_identity:-unknown})."
            failed=1
          fi
        fi
      elif [ -n "$bound_path" ] \
        && { [ -e "$bound_path" ] || [ -L "$bound_path" ]; }; then
        quarantine_name=".agent-ecosystem.rollback-unknown.$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID.$index"
        quarantine_bound="$bound_parent/$quarantine_name"
        quarantine_path="$parent/$quarantine_name"
        if [ -e "$quarantine_bound" ] || [ -L "$quarantine_bound" ] \
          || ! mv -Tn -- "$bound_path" "$quarantine_bound"; then
          error "Recovery required: changed discovery path was preserved at $path"
        else
          moved_identity="$(path_identity "$quarantine_bound")" || true
          DISCOVERY_QUARANTINES[$index]="$quarantine_path"
          error "Recovery required: changed discovery entry was quarantined at $quarantine_path (identity ${moved_identity:-unknown})."
        fi
        failed=1
      fi
    else
      if [ ! -L "$path" ] \
        || [ "$(readlink -- "$path")" != "${DISCOVERY_TARGETS[$index]}" ] \
        || [ "$(stat -c '%u' -- "$path")" != "${DISCOVERY_UIDS[$index]}" ] \
        || [ "$(path_identity "$path")" != "${DISCOVERY_IDS[$index]}" ]; then
        error "Recovery required: discovery path changed and was preserved: $path"
        failed=1
      fi
    fi

    if [ "${DISCOVERY_PARENT_STATES[$index]}" = "absent" ] \
      && [ "${DISCOVERY_PARENT_CREATED[$index]}" -eq 1 ]; then
      quarantine_name=".agent-ecosystem.rollback-parent.$AGENTS_ECOSYSTEM_INSTALLER_TRANSACTION_PID.$index"
      quarantine_bound="$HOME_BOUND/$quarantine_name"
      quarantine_path="$HOME_ROOT/$quarantine_name"
      if ! verify_discovery_parent "$index" "before parent quarantine"; then
        error "Recovery required: created discovery parent changed and was preserved: $parent"
        failed=1
      elif [ -e "$quarantine_bound" ] || [ -L "$quarantine_bound" ] \
        || ! move_directory_no_replace \
          "$HOME_BOUND/$parent_base" "$quarantine_bound" \
          "${DISCOVERY_PARENT_IDS[$index]}" "$parent" "$quarantine_path"; then
        error "Recovery required: created discovery parent was retained at $parent"
        failed=1
      else
        DISCOVERY_PARENT_CREATED[$index]=0
        DISCOVERY_PARENT_IDS[$index]=absent
        DISCOVERY_PARENT_UIDS[$index]=""
        DISCOVERY_QUARANTINES[$index]="$quarantine_path"
        warning "Rollback recovery retained the installer-created parent at $quarantine_path."
      fi
    fi
  done
  return "$failed"
}

restore_checkout() {
  local failed=0

  if [ "$NEW_ACTIVE" -eq 1 ]; then
    if [ -d "$DEST" ] \
      && [ ! -L "$DEST" ] \
      && [ "$(path_identity "$DEST")" = "$NEW_ID" ] \
      && [ ! -e "$FAILED_CANDIDATE_BOUND" ] \
      && [ ! -L "$FAILED_CANDIDATE_BOUND" ]; then
      move_directory_no_replace \
        "$DEST_BOUND" "$FAILED_CANDIDATE_BOUND" "$NEW_ID" \
        "$DEST" "$FAILED_CANDIDATE" || failed=1
      if [ "$failed" -eq 0 ]; then
        NEW_ACTIVE=0
      fi
    else
      error "Recovery required: active destination changed and was preserved: $DEST"
      failed=1
    fi
  fi

  if [ "$PRIOR_MOVED" -eq 1 ]; then
    if { [ -e "$DEST_BOUND" ] || [ -L "$DEST_BOUND" ]; } \
      || [ ! -d "$PRIOR_BOUND" ]; then
      error "Recovery required: prior checkout retained at $PRIOR"
      failed=1
    elif move_directory_no_replace \
      "$PRIOR_BOUND" "$DEST_BOUND" "$ORIGINAL_DEST_ID" \
      "$PRIOR" "$DEST"; then
      PRIOR_MOVED=0
      if [ "$(path_identity "$DEST")" != "$ORIGINAL_DEST_ID" ] \
        || ! validate_checkout \
          "$DEST" "$ORIGINAL_DEST_ID" 0 "$ORIGINAL_HEAD" "$ORIGINAL_CHECKOUT_MODE" \
        || [ "$(safe_git -C "$DEST" rev-parse HEAD)" != "$ORIGINAL_HEAD" ]; then
        error "Recovery required: restored checkout did not verify at $DEST"
        failed=1
      fi
    else
      error "Recovery required: prior checkout retained at $PRIOR"
      failed=1
    fi
  elif [ "$EXISTING_DEST" -eq 1 ]; then
    if [ -n "$PRIOR" ] && { [ -e "$PRIOR" ] || [ -L "$PRIOR" ]; }; then
      error "Recovery required: unexpected transaction material retained at $PRIOR"
      STAGE_VERIFIED=0
      failed=1
    fi
    if [ -L "$DEST" ] \
      || [ ! -d "$DEST" ] \
      || [ "$(path_identity "$DEST")" != "$ORIGINAL_DEST_ID" ]; then
      error "Recovery required: original checkout is not available at $DEST"
      failed=1
    elif ! validate_checkout \
      "$DEST" "$ORIGINAL_DEST_ID" 0 "$ORIGINAL_HEAD" "$ORIGINAL_CHECKOUT_MODE" \
      || [ "$(safe_git -C "$DEST" rev-parse HEAD)" != "$ORIGINAL_HEAD" ]; then
      error "Recovery required: original checkout no longer verifies at $DEST"
      failed=1
    fi
  elif [ "$EXISTING_DEST" -eq 0 ] \
    && { [ -e "$DEST" ] || [ -L "$DEST" ]; }; then
    error "Recovery required: new destination could not be removed safely: $DEST"
    failed=1
  fi

  return "$failed"
}

report_bound_recovery_locations() {
  local actual_parent
  local actual_path
  local actual_stage
  local bound_leaf
  local child
  local index
  local reporter="${1:-error}"

  case "$reporter" in
    error|warning) ;;
    *) reporter=error ;;
  esac

  if [ "$EXISTING_DEST" -eq 1 ] \
    && [ -n "$ORIGINAL_DEST_BOUND_ROOT" ] \
    && [ "$(bound_directory_identity "$ORIGINAL_DEST_BOUND_ROOT" 2>/dev/null || true)" \
      = "$ORIGINAL_DEST_ID" ]; then
    actual_path="$(resolve_bound_directory "$ORIGINAL_DEST_BOUND_ROOT" "$DEST")"
    "$reporter" "Recovery required: original checkout is available at $actual_path (identity $ORIGINAL_DEST_ID; HEAD $ORIGINAL_HEAD)."
  fi

  if [ "$LOCK_HELD" -eq 1 ] \
    && [ -n "$LOCK_BOUND_ROOT" ] \
    && [ "$(bound_directory_identity "$LOCK_BOUND_ROOT" 2>/dev/null || true)" \
      = "$LOCK_ID" ]; then
    actual_path="$(resolve_bound_directory "$LOCK_BOUND_ROOT" "$LOCK_PATH")"
    "$reporter" "Recovery required: installer lock is retained at $actual_path (identity $LOCK_ID)."
  fi

  if [ "$COMMITTED" -eq 0 ] \
    && [ -n "$CANDIDATE_BOUND_ROOT" ] \
    && [ "$(bound_directory_identity "$CANDIDATE_BOUND_ROOT" 2>/dev/null || true)" \
      = "$CANDIDATE_ID" ]; then
    actual_path="$(resolve_bound_directory "$CANDIDATE_BOUND_ROOT" "$CANDIDATE")"
    "$reporter" "Recovery required: candidate checkout is available at $actual_path (identity $CANDIDATE_ID; HEAD $CANDIDATE_HEAD)."
  fi

  if [ -n "$STAGE_BOUND_ROOT" ] \
    && [ "$(bound_directory_identity "$STAGE_BOUND_ROOT" 2>/dev/null || true)" \
      = "$STAGE_ID" ]; then
    actual_stage="$(resolve_bound_directory "$STAGE_BOUND_ROOT" "$STAGE_ROOT")"
    "$reporter" "Recovery required: transaction stage is available at $actual_stage (identity $STAGE_ID)."
    for child in candidate prior failed-candidate; do
      if [ -e "$STAGE_BOUND_ROOT/$child" ] \
        || [ -L "$STAGE_BOUND_ROOT/$child" ]; then
        "$reporter" "Recovery required: transaction material is available at $actual_stage/$child (identity $(path_identity "$STAGE_BOUND_ROOT/$child"))."
      fi
    done
  fi

  for index in "${!DISCOVERY_PATHS[@]}"; do
    [ -n "${DISCOVERY_PARENT_BOUNDS[$index]:-}" ] || continue
    bound_leaf="${DISCOVERY_PARENT_BOUNDS[$index]}/$(basename -- "${DISCOVERY_PATHS[$index]}")"
    if [ -e "$bound_leaf" ] || [ -L "$bound_leaf" ]; then
      actual_parent="$(resolve_bound_directory \
        "${DISCOVERY_PARENT_BOUNDS[$index]}" \
        "$(dirname -- "${DISCOVERY_PATHS[$index]}")")"
      actual_path="$actual_parent/$(basename -- "${DISCOVERY_PATHS[$index]}")"
      "$reporter" "Recovery required: discovery entry is available at $actual_path (identity $(path_identity "$bound_leaf"))."
    fi
  done
}

rollback_transaction() {
  local failed=0

  if [ "$DISCOVERY_SNAPSHOT_READY" -eq 1 ]; then
    restore_discovery_paths || failed=1
  fi
  restore_checkout || failed=1
  if [ "$failed" -eq 0 ]; then
    safe_remove_stage || failed=1
  elif [ "$PRIOR_MOVED" -eq 1 ] && [ -n "$PRIOR" ] && [ -d "$PRIOR" ]; then
    error "Recovery required: prior checkout retained at $PRIOR"
  elif [ -n "$STAGE_ROOT" ]; then
    error "Recovery required: transaction material retained at $STAGE_ROOT (expected identity $STAGE_ID)"
  fi
  if [ "$failed" -ne 0 ]; then
    report_bound_recovery_locations error
  fi
  return "$failed"
}

release_lock() {
  local parent_changed=0

  if [ "$LOCK_HELD" -ne 1 ]; then
    return 0
  fi
  if ! verify_destination_parent "before lock release"; then
    parent_changed=1
  fi
  if [ "$(bound_directory_identity "$LOCK_BOUND_ROOT" 2>/dev/null || true)" \
      != "$LOCK_ID" ] \
    || [ -L "$LOCK_BOUND_PATH" ] \
    || [ ! -d "$LOCK_BOUND_PATH" ] \
    || [ "$(path_identity "$LOCK_BOUND_PATH")" != "$LOCK_ID" ]; then
    cleanup_issue "installation lock changed and was not removed: $LOCK_PATH"
    return 1
  fi
  if ! retire_empty_directory \
    "$LOCK_BOUND_PATH" "$LOCK_ID" "$LOCK_PATH" release 1; then
    cleanup_issue "installation lock could not be released safely: $LOCK_PATH"
    return 1
  fi
  LOCK_HELD=0
  if [ "$parent_changed" -ne 0 ]; then
    cleanup_issue "destination parent changed while the installation lock was held: $DEST_PARENT"
    return 1
  fi
}

close_bound_directories() {
  local descriptor

  for descriptor in "${DISCOVERY_PARENT_FDS[@]}"; do
    if [ -n "$descriptor" ]; then
      exec {descriptor}<&-
    fi
  done
  if [ -n "${LOCK_FD:-}" ]; then
    exec {LOCK_FD}<&-
    LOCK_FD=""
  fi
  if [ -n "${STAGE_FD:-}" ]; then
    exec {STAGE_FD}<&-
    STAGE_FD=""
  fi
  if [ -n "${ORIGINAL_DEST_FD:-}" ]; then
    exec {ORIGINAL_DEST_FD}<&-
    ORIGINAL_DEST_FD=""
  fi
  if [ -n "${CANDIDATE_FD:-}" ]; then
    exec {CANDIDATE_FD}<&-
    CANDIDATE_FD=""
  fi
  if [ -n "${DEST_PARENT_FD:-}" ]; then
    exec {DEST_PARENT_FD}<&-
    DEST_PARENT_FD=""
  fi
  if [ -n "${HOME_FD:-}" ]; then
    exec {HOME_FD}<&-
    HOME_FD=""
  fi
}

finish() {
  local status="$?"
  local cleanup_failed=0
  trap - EXIT
  trap '' HUP INT TERM
  set +e

  if [ "$COMMITTED" -eq 1 ]; then
    if ! safe_remove_stage; then
      warning "Installation committed successfully, but transaction cleanup was incomplete. Retained recovery detail: ${STAGE_ROOT:-<unknown>}"
      report_bound_recovery_locations warning
    fi
    if ! release_lock; then
      warning "Installation committed successfully, but the installation lock was retained at ${LOCK_PATH:-<unknown>}."
      report_bound_recovery_locations warning
    fi
    close_bound_directories
    exit 0
  fi

  rollback_transaction || cleanup_failed=1
  if [ "$status" -eq 0 ]; then
    status=1
  fi
  if ! release_lock; then
    cleanup_failed=1
    report_bound_recovery_locations error
  fi
  if [ "$cleanup_failed" -ne 0 ]; then
    status=1
  fi
  close_bound_directories
  exit "$status"
}

handle_signal() {
  local status="$1"
  if [ "$DEFER_SIGNALS" -eq 1 ]; then
    PENDING_SIGNAL="$status"
    return 0
  fi
  exit "$status"
}

if ! command -v git >/dev/null 2>&1; then
  error "git is required to install agent ecosystem skills on this Cloud VM."
  exit 1
fi

validate_home
select_destination
validate_destination_path

if [ -d "$DEST" ]; then
  EXISTING_DEST=1
  if safe_git -C "$DEST" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    ORIGINAL_CHECKOUT_MODE=edge
  else
    ORIGINAL_CHECKOUT_MODE=release
  fi
  validate_checkout "$DEST" "" 1 "" "$ORIGINAL_CHECKOUT_MODE"
  ORIGINAL_DEST_ID="$(path_identity "$DEST")"
  ORIGINAL_HEAD="$(safe_git -C "$DEST" rev-parse HEAD)"
  bind_original_checkout
fi

trap finish EXIT
trap 'handle_signal 129' HUP
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM
acquire_lock

snapshot_discovery_paths
create_stage

echo "=> Staging the agent ecosystem for $DEST..."
verify_stage "before cloning the candidate"
if [ -n "$RELEASE_REF" ]; then
  safe_git clone --depth 1 --no-tags --no-checkout -- \
    "$REPO_URL" "$CANDIDATE_BOUND"
  safe_git -C "$CANDIDATE_BOUND" fetch \
    --depth 1 --no-tags origin "$RELEASE_REF"
  safe_git -C "$CANDIDATE_BOUND" checkout --quiet --detach FETCH_HEAD
else
  safe_git clone --depth 1 --no-tags -- "$REPO_URL" "$CANDIDATE_BOUND"
fi
verify_stage "after cloning the candidate"
validate_candidate
CANDIDATE_ID="$(path_identity "$CANDIDATE")"
bind_candidate_checkout

verify_lock
verify_discovery_snapshot
if [ "$EXISTING_DEST" -eq 1 ]; then
  validate_checkout \
    "$DEST" "$ORIGINAL_DEST_ID" 1 "$ORIGINAL_HEAD" "$ORIGINAL_CHECKOUT_MODE"
  if [ "$(safe_git -C "$DEST" rev-parse HEAD)" != "$ORIGINAL_HEAD" ]; then
    error "checkout HEAD changed during staging: $DEST"
    exit 1
  fi
  if [ "$ORIGINAL_HEAD" = "$CANDIDATE_HEAD" ] \
    && { [ "$ORIGINAL_CHECKOUT_MODE" = release ] && [ -n "$RELEASE_REF" ] \
      || [ "$ORIGINAL_CHECKOUT_MODE" = edge ] && [ -z "$RELEASE_REF" ]; }; then
    NO_SWAP=1
    NEW_ID="$ORIGINAL_DEST_ID"
  else
    move_original_to_prior
    validate_prior_checkout
  fi
fi
verify_lock
verify_discovery_snapshot
validate_candidate "$CANDIDATE_ID"
if [ "$NO_SWAP" -eq 0 ]; then
  activate_candidate
fi

verify_lock
validate_checkout "$DEST" "$NEW_ID" 0 "$RELEASE_REF"
prepare_discovery_parents
verify_discovery_snapshot
verify_lock
validate_checkout "$DEST" "$NEW_ID" 0 "$RELEASE_REF"
register_discovery_paths

verify_lock
validate_checkout "$DEST" "$NEW_ID" 0 "$RELEASE_REF"
if [ "$(safe_git -C "$DEST" rev-parse HEAD)" != "$CANDIDATE_HEAD" ]; then
  error "installed checkout HEAD changed during registration."
  exit 1
fi
verify_registered_discovery_paths

if [ "$EXISTING_DEST" -eq 1 ] && [ "$NO_SWAP" -eq 0 ]; then
  validate_prior_checkout
fi

COMMITTED=1
if [ "$NO_SWAP" -eq 1 ]; then
  echo "=> Cloud skill bake already current; discovery links reconciled without replacing $DEST."
fi
echo "=> Cloud skill bake complete ($DEST -> $HOME_ROOT/.cursor/skills)."
