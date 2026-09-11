#!/usr/bin/env bash
# Install the agent ecosystem once for this machine and register every available
# user-scoped tool adapter against the canonical checkout.
#
# Idempotent. Never force-overwrites a dirty checkout or a non-symlink skills dir.

set -euo pipefail
umask 022

DEST="${AGENTS_ECOSYSTEM_HOME:-$HOME/.agent-ecosystem}"
REPO_URL="https://github.com/marcus-friction/agents.git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_REF=""
RELEASE_LOCK=""
RELEASE_LOCK_OWNED=0
RELEASE_STAGE=""
RELEASE_STAGE_ID=""
RELEASE_PRIOR=""
RELEASE_SWAPPED=0
RELEASE_HAD_PRIOR=0
RELEASE_COMPLETE=0
RELEASE_REGISTRAR=""
RELEASE_TRUSTED_SCRIPTS_ID=""
RELEASE_CANDIDATE_ID=""
RELEASE_NEW_ID=""
RELEASE_EXISTING=0
RELEASE_REGISTRATION_COMMITTED=0
RELEASE_ORIGINAL_ID="absent"
RELEASE_ORIGINAL_HEAD=""
VALIDATED_RELEASE_ID=""
VALIDATED_RELEASE_HEAD=""
DEFER_SIGNALS=0
PENDING_SIGNAL=0
MOVE_NO_REPLACE_MODE=""

for git_variable in "${!GIT_@}"; do
  unset "$git_variable"
done

usage() {
  echo "Usage: $0 [--ref 40-character-commit-sha]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref)
      RELEASE_REF="${2:-}"
      if [ -z "$RELEASE_REF" ]; then
        echo "Error: --ref requires a full 40-character lowercase commit SHA." >&2
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

safe_git() {
  GIT_CONFIG=/dev/null \
  GIT_CONFIG_NOSYSTEM=1 \
  GIT_CONFIG_GLOBAL=/dev/null \
  GIT_ASKPASS=/usr/bin/false \
  GIT_NO_REPLACE_OBJECTS=1 \
  GIT_TERMINAL_PROMPT=0 \
  GH_PROMPT_DISABLED=1 \
  SSH_ASKPASS=/usr/bin/false \
  SSH_ASKPASS_REQUIRE=never \
    git --no-replace-objects \
      -c core.hooksPath=/dev/null \
      -c core.fsmonitor=false \
      -c credential.helper= \
      "$@"
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

handle_signal() {
  local signal_status="$1"

  if [ "$DEFER_SIGNALS" -eq 1 ]; then
    if [ "$PENDING_SIGNAL" -eq 0 ]; then
      PENDING_SIGNAL="$signal_status"
    fi
    return 0
  fi
  exit "$signal_status"
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
    echo "Error: move source changed before transition: $source_label" >&2
    return 1
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "Error: checkout transition target already exists and was preserved: $target_label" >&2
    return 1
  fi

  platform_move_no_replace "$source" "$target" || move_status="$?"
  if [ ! -e "$source" ] \
    && [ ! -L "$source" ] \
    && [ -d "$target" ] \
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
    echo "Error: checkout transition failed from $source_label to $target_label." >&2
    return 1
  fi

  if [ ! -e "$source" ] \
    && [ ! -L "$source" ] \
    && [ -d "$target" ] \
    && [ ! -L "$target" ]; then
    moved_identity="$(path_identity "$target")"
    if [ -n "$moved_identity" ] \
      && platform_move_no_replace "$target" "$source" \
      && [ "$(path_identity "$source")" = "$moved_identity" ]; then
      echo "Error: checkout transition moved an unexpected replacement and restored it at $source_label." >&2
      return 1
    fi
  fi

  echo "Error: checkout transition became ambiguous; recovery material was preserved at $source_label or $target_label." >&2
  return 1
}

safe_remove_completed_stage() {
  local unexpected_entry=""

  case "$RELEASE_STAGE" in
    "${DEST}.release."*) ;;
    *)
      echo "Warning: transaction staging path was not recognized and was retained: $RELEASE_STAGE" >&2
      return 1
      ;;
  esac
  if [ -L "$RELEASE_STAGE" ] \
    || [ ! -d "$RELEASE_STAGE" ] \
    || [ "$(path_identity "$RELEASE_STAGE")" != "$RELEASE_STAGE_ID" ]; then
    echo "Warning: transaction staging path changed and was retained: $RELEASE_STAGE" >&2
    return 1
  fi
  if [ -L "$RELEASE_STAGE/trusted-scripts" ] \
    || [ ! -d "$RELEASE_STAGE/trusted-scripts" ] \
    || [ "$(path_identity "$RELEASE_STAGE/trusted-scripts")" != "$RELEASE_TRUSTED_SCRIPTS_ID" ]; then
    echo "Warning: trusted script staging path changed and the transaction was retained: $RELEASE_STAGE" >&2
    return 1
  fi
  if [ -e "$RELEASE_STAGE/candidate" ] \
    || [ -L "$RELEASE_STAGE/candidate" ] \
    || [ -e "$RELEASE_STAGE/failed-candidate" ] \
    || [ -L "$RELEASE_STAGE/failed-candidate" ]; then
    echo "Warning: unexpected candidate recovery material was retained: $RELEASE_STAGE" >&2
    return 1
  fi
  if [ "$RELEASE_EXISTING" -eq 1 ]; then
    if [ -L "$RELEASE_PRIOR" ] \
      || [ ! -d "$RELEASE_PRIOR" ] \
      || [ "$(path_identity "$RELEASE_PRIOR")" != "$RELEASE_ORIGINAL_ID" ]; then
      echo "Warning: previous checkout recovery material changed and was retained: $RELEASE_STAGE" >&2
      return 1
    fi
    if ! validate_existing_release_destination \
      "$RELEASE_PRIOR" "$RELEASE_ORIGINAL_ID" "$RELEASE_ORIGINAL_HEAD"; then
      echo "Warning: previous checkout no longer matched its validated state and was retained: $RELEASE_STAGE" >&2
      return 1
    fi
  elif [ -e "$RELEASE_PRIOR" ] || [ -L "$RELEASE_PRIOR" ]; then
    echo "Warning: unexpected previous checkout material was retained: $RELEASE_STAGE" >&2
    return 1
  fi
  unexpected_entry="$(find "$RELEASE_STAGE" -mindepth 1 -maxdepth 1 \
    ! -name trusted-scripts ! -name prior -print -quit)"
  if [ -n "$unexpected_entry" ]; then
    echo "Warning: unexpected transaction material was retained at $RELEASE_STAGE" >&2
    return 1
  fi
  rm -rf -- "$RELEASE_STAGE"
}

cleanup_release_work() {
  local exit_status="$?"
  local current_identity=""
  local failed_candidate=""

  trap '' HUP INT TERM
  set +e
  failed_candidate="$RELEASE_STAGE/failed-candidate"

  if [ "$RELEASE_COMPLETE" -eq 0 ]; then
    if [ "$RELEASE_SWAPPED" -eq 1 ]; then
      current_identity="$(path_identity "$DEST" 2>/dev/null || true)"
      if [ "$RELEASE_REGISTRATION_COMMITTED" -eq 1 ] \
        && [ "$RELEASE_EXISTING" -eq 0 ]; then
        echo "Warning: retained the active checkout because user registration had committed before release verification failed: $DEST" >&2
        echo "Warning: inspect $DEST and $RELEASE_STAGE before retrying the installation." >&2
      elif [ "$current_identity" = "$RELEASE_NEW_ID" ]; then
        if move_directory_no_replace \
          "$DEST" "$failed_candidate" "$RELEASE_NEW_ID" \
          "$DEST" "$failed_candidate"; then
          RELEASE_SWAPPED=0
        else
          echo "Error: failed release checkout was preserved at $DEST or $failed_candidate." >&2
        fi
      elif [[ "$current_identity" == directory:* ]]; then
        if move_directory_no_replace \
          "$DEST" "$failed_candidate" "$current_identity" \
          "$DEST" "$failed_candidate"; then
          RELEASE_SWAPPED=0
          echo "Warning: a concurrent destination replacement was quarantined at $failed_candidate." >&2
        else
          echo "Error: concurrent destination content was preserved at $DEST or $failed_candidate." >&2
        fi
      else
        echo "Error: active destination changed; recovery material was preserved at $DEST and $RELEASE_STAGE." >&2
      fi
    fi

    if [ "$RELEASE_HAD_PRIOR" -eq 1 ]; then
      if [ ! -e "$DEST" ] \
        && [ ! -L "$DEST" ] \
        && [ -d "$RELEASE_PRIOR" ] \
        && [ ! -L "$RELEASE_PRIOR" ] \
        && [ "$(path_identity "$RELEASE_PRIOR")" = "$RELEASE_ORIGINAL_ID" ] \
        && move_directory_no_replace \
          "$RELEASE_PRIOR" "$DEST" "$RELEASE_ORIGINAL_ID" \
          "$RELEASE_PRIOR" "$DEST"; then
        RELEASE_HAD_PRIOR=0
        if validate_existing_release_destination \
          "$DEST" "$RELEASE_ORIGINAL_ID" "$RELEASE_ORIGINAL_HEAD"; then
          echo "Warning: restored the previous global checkout after release installation failed." >&2
        else
          echo "Error: restored checkout did not match its validated snapshot: $DEST" >&2
        fi
      else
        echo "Error: could not restore the previous checkout; recovery data remains at $RELEASE_PRIOR." >&2
      fi
    fi

    if [ -n "$RELEASE_STAGE" ] \
      && [ -d "$RELEASE_STAGE" ] \
      && [ ! -L "$RELEASE_STAGE" ]; then
      echo "Warning: retained failed release transaction for recovery at $RELEASE_STAGE." >&2
    fi
  elif [ -n "$RELEASE_STAGE" ]; then
    safe_remove_completed_stage || true
  fi

  if [ "$RELEASE_LOCK_OWNED" -eq 1 ] \
    && [ -n "$RELEASE_LOCK" ] \
    && [ -d "$RELEASE_LOCK" ] \
    && [ ! -L "$RELEASE_LOCK" ]; then
    rmdir "$RELEASE_LOCK" 2>/dev/null || true
  fi
  return "$exit_status"
}

trap cleanup_release_work EXIT
trap 'handle_signal 129' HUP
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM

verify_release_checkout() {
  local dir="$1"
  local expected="$2"
  local actual
  local status

  actual="$(safe_git -C "$dir" rev-parse --verify 'HEAD^{commit}' 2>/dev/null || true)"
  if [ "$actual" != "$expected" ]; then
    echo "Error: checkout HEAD $actual does not match expected release commit $expected." >&2
    return 1
  fi
  if safe_git -C "$dir" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "Error: release checkout must use detached HEAD at $expected." >&2
    return 1
  fi
  status="$(safe_git -C "$dir" status \
    --porcelain=v1 --untracked-files=all --ignored=matching)"
  if [ -n "$status" ]; then
    echo "Error: immutable checkout must be clean before repository code executes: $dir" >&2
    return 1
  fi
  echo "=> Verified immutable checkout at $expected (detached HEAD)."
}

validate_destination_path() {
  local current=""
  local part
  local -a parts

  if [[ "$DEST" != /* ]]; then
    echo "Error: AGENTS_ECOSYSTEM_HOME must be an absolute path." >&2
    return 1
  fi
  if [ "$DEST" = "/" ] || [ "$DEST" = "$HOME" ] || [[ "$DEST" == */ ]]; then
    echo "Error: installation destination must be a normalized child path: $DEST" >&2
    return 1
  fi
  IFS='/' read -r -a parts <<< "$DEST"
  for part in "${parts[@]}"; do
    [ -n "$part" ] || continue
    if [ "$part" = "." ] || [ "$part" = ".." ]; then
      echo "Error: installation destination must be normalized: $DEST" >&2
      return 1
    fi
    current="$current/$part"
    if [ -L "$current" ]; then
      echo "Error: installation destination must not be a symlink: $current" >&2
      return 1
    fi
  done
}

validate_release_payload() {
  local dir="$1"
  local registrar="$dir/scripts/register-skills.sh"

  if [ -L "$dir/.agents" ] \
    || [ ! -d "$dir/.agents" ] \
    || [ -L "$dir/.agents/skills" ] \
    || [ ! -d "$dir/.agents/skills" ] \
    || [ -L "$dir/scripts" ] \
    || [ ! -d "$dir/scripts" ] \
    || [ -L "$registrar" ] \
    || [ ! -f "$registrar" ]; then
    echo "Error: immutable release payload has unsafe or missing managed paths." >&2
    return 1
  fi
}

validate_skills_payload() {
  local dir="$1"

  if [ -L "$dir/.agents" ] \
    || [ ! -d "$dir/.agents" ] \
    || [ -L "$dir/.agents/skills" ] \
    || [ ! -d "$dir/.agents/skills" ]; then
    echo "Error: $dir/.agents/skills must be a physical directory." >&2
    return 1
  fi
}

validate_local_checkout_config() {
  local dir="$1"
  local config="$dir/.git/config"
  local key
  local keys

  if [ -L "$config" ] || [ ! -f "$config" ]; then
    echo "Error: existing checkout must have a physical local Git config." >&2
    return 1
  fi
  keys="$(safe_git config --file "$config" --no-includes --name-only --list)" || {
    echo "Error: existing checkout has an unreadable local Git config." >&2
    return 1
  }
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    case "$key" in
      core.repositoryformatversion|core.filemode|core.bare|core.logallrefupdates|\
      core.ignorecase|core.precomposeunicode|remote.origin.url|remote.origin.fetch|\
      branch.master.remote|branch.master.merge)
        ;;
      *)
        echo "Error: existing checkout has unsupported local Git configuration: $key" >&2
        return 1
        ;;
    esac
  done <<EOF
$keys
EOF
}

validate_existing_release_destination() {
  local dir="$1"
  local expected_identity="${2:-}"
  local expected_head="${3:-}"
  local start_identity
  local final_identity
  local status
  local index_flags
  local local_refs
  local remote_refs
  local head
  local origin_head
  local origin_url
  local marker="$dir/.git/agents-ecosystem-managed"
  local private_entry
  local unreachable
  local all_refs

  if [ -L "$dir" ] \
    || [ ! -d "$dir" ] \
    || [ -L "$dir/.git" ] \
    || [ ! -d "$dir/.git" ]; then
    echo "Error: existing destination is not a physical Git checkout; refusing replacement." >&2
    return 1
  fi
  start_identity="$(path_identity "$dir")" || return 1
  if [ -n "$expected_identity" ] \
    && [ "$start_identity" != "$expected_identity" ]; then
    echo "Error: existing checkout changed after its validated snapshot: $dir" >&2
    return 1
  fi
  validate_local_checkout_config "$dir"
  if [ -e "$dir/.git/worktrees" ] || [ -L "$dir/.git/worktrees" ]; then
    echo "Error: existing checkout has linked worktrees; refusing replacement." >&2
    return 1
  fi
  status="$(safe_git -C "$dir" status \
    --porcelain=v1 --untracked-files=all --ignored=matching)"
  if [ -n "$status" ]; then
    echo "Error: immutable checkout is dirty; refusing to replace or execute it: $dir" >&2
    return 1
  fi
  index_flags="$(safe_git -C "$dir" ls-files -v | sed -n '/^[a-zS]/p')"
  if [ -n "$index_flags" ]; then
    echo "Error: existing checkout has hidden index state; refusing replacement." >&2
    return 1
  fi
  local_refs="$(safe_git -C "$dir" for-each-ref \
    --format='%(refname)' refs/heads refs/tags)"
  all_refs="$(safe_git -C "$dir" for-each-ref --format='%(refname)')"
  if ! unreachable="$(safe_git -C "$dir" fsck --unreachable --no-reflogs \
    --no-progress 2>&1)"; then
    echo "Error: existing checkout object database check failed; refusing replacement." >&2
    return 1
  fi
  if [ -n "$unreachable" ]; then
    echo "Error: existing checkout has recoverable unreachable Git objects; refusing replacement." >&2
    return 1
  fi
  if [ -e "$dir/.git/hooks" ] || [ -L "$dir/.git/hooks" ]; then
    if [ -L "$dir/.git/hooks" ] || [ ! -d "$dir/.git/hooks" ]; then
      echo "Error: existing checkout has unsafe Git hook metadata." >&2
      return 1
    fi
    while IFS= read -r -d '' private_entry; do
      case "${private_entry##*/}" in
        *.sample)
          if [ -L "$private_entry" ] || [ ! -f "$private_entry" ]; then
            echo "Error: existing checkout has unsafe Git hook metadata." >&2
            return 1
          fi
          ;;
        *)
          echo "Error: existing checkout has custom Git hook metadata; refusing replacement." >&2
          return 1
          ;;
      esac
    done < <(find "$dir/.git/hooks" -mindepth 1 -maxdepth 1 -print0)
  fi

  if [ -e "$marker" ] || [ -L "$marker" ]; then
    if [ -L "$marker" ] \
      || [ ! -f "$marker" ] \
      || [ "$(sed -n '1p' "$marker")" != "agents-ecosystem-global-release-v1" ] \
      || [ "$(sed -n '2p' "$marker")" != "" ]; then
      echo "Error: existing checkout has an invalid agent ecosystem release marker." >&2
      return 1
    fi
    if safe_git -C "$dir" symbolic-ref --quiet HEAD >/dev/null 2>&1 \
      || [ -n "$all_refs" ]; then
      echo "Error: managed release checkout has unexpected branches or tags." >&2
      return 1
    fi
    if safe_git config --file "$dir/.git/config" --no-includes \
      --name-only --get-regexp '^(remote|branch)\.' >/dev/null 2>&1; then
      echo "Error: managed release checkout has unexpected remote or branch configuration." >&2
      return 1
    fi
  else
    if [ "$(safe_git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)" != "master" ] \
      || [ "$local_refs" != "refs/heads/master" ]; then
      echo "Error: unmarked checkout is not a canonical edge checkout; refusing replacement." >&2
      return 1
    fi
    origin_url="$(safe_git config --file "$dir/.git/config" \
      --no-includes --get-all remote.origin.url 2>/dev/null || true)"
    if [ "$origin_url" != "$REPO_URL" ]; then
      echo "Error: existing edge checkout does not use the canonical agent ecosystem origin." >&2
      return 1
    fi
    head="$(safe_git -C "$dir" rev-parse --verify refs/heads/master)"
    origin_head="$(safe_git -C "$dir" rev-parse --verify refs/remotes/origin/master 2>/dev/null || true)"
    if [ "$head" != "$origin_head" ]; then
      echo "Error: existing edge checkout has commits not represented by origin/master." >&2
      return 1
    fi
    remote_refs="$(printf '%s\n' "$all_refs" | \
      sed '/^refs\/heads\/master$/d; /^refs\/remotes\/origin\/HEAD$/d; /^refs\/remotes\/origin\/master$/d')"
    if [ -n "$remote_refs" ]; then
      echo "Error: existing edge checkout has unexpected remote refs; refusing replacement." >&2
      return 1
    fi
  fi

  head="$(safe_git -C "$dir" rev-parse --verify 'HEAD^{commit}' 2>/dev/null)" || {
    echo "Error: existing checkout changed while its validated state was recorded: $dir" >&2
    return 1
  }
  final_identity="$(path_identity "$dir")" || return 1
  if [ "$final_identity" != "$start_identity" ]; then
    echo "Error: existing checkout changed during validation: $dir" >&2
    return 1
  fi
  if [ -n "$expected_head" ] && [ "$head" != "$expected_head" ]; then
    echo "Error: existing checkout HEAD changed after its validated snapshot: $dir" >&2
    return 1
  fi
  VALIDATED_RELEASE_ID="$start_identity"
  VALIDATED_RELEASE_HEAD="$head"
}

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required."
  exit 1
fi

validate_destination_path

sync_checkout() {
  local dir="$1"
  if [ ! -d "$dir/.git" ]; then
    echo "Error: $dir exists but is not a git repository. Refusing to overwrite."
    exit 1
  fi
  validate_existing_release_destination "$dir"
  echo "=> Updating $dir (fast-forward only)..."
  safe_git -C "$dir" fetch --no-tags "$REPO_URL" \
    '+refs/heads/master:refs/remotes/origin/master'
  if ! safe_git -C "$dir" merge --ff-only refs/remotes/origin/master; then
    echo "Error: fast-forward update failed. Leaving $dir as-is." >&2
    return 1
  fi
}

prepare_release_checkout() {
  local expected="$2"
  local candidate="$1"
  local invalid_script

  echo "=> Fetching immutable Agent Ecosystem release into an isolated candidate..."
  safe_git init -q "$candidate"
  safe_git -C "$candidate" fetch --depth 1 --no-tags "$REPO_URL" "$expected"
  safe_git -C "$candidate" checkout --quiet --detach FETCH_HEAD
  verify_release_checkout "$candidate" "$expected"
  validate_release_payload "$candidate"
  invalid_script="$(find "$candidate/scripts" -mindepth 1 \
    ! -type d ! -type f -print -quit)"
  if [ -n "$invalid_script" ]; then
    echo "Error: immutable release scripts must not contain symlinks or special files: $invalid_script" >&2
    return 1
  fi
  cp -R "$candidate/scripts" "$RELEASE_STAGE/trusted-scripts"
  RELEASE_REGISTRAR="$RELEASE_STAGE/trusted-scripts/register-skills.sh"
  RELEASE_TRUSTED_SCRIPTS_ID="$(path_identity "$RELEASE_STAGE/trusted-scripts")"
  printf 'agents-ecosystem-global-release-v1\n' > "$candidate/.git/agents-ecosystem-managed"
  RELEASE_CANDIDATE_ID="$(path_identity "$candidate")"
}

install_release_checkout() {
  local expected="$1"
  local candidate

  RELEASE_LOCK="${DEST}.agents-ecosystem-install.lock"
  if ! mkdir "$RELEASE_LOCK" 2>/dev/null; then
    echo "Error: another release installation may be active: $RELEASE_LOCK" >&2
    return 1
  fi
  RELEASE_LOCK_OWNED=1
  validate_destination_path
  if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    validate_existing_release_destination "$DEST"
    RELEASE_EXISTING=1
    RELEASE_ORIGINAL_ID="$VALIDATED_RELEASE_ID"
    RELEASE_ORIGINAL_HEAD="$VALIDATED_RELEASE_HEAD"
  fi

  RELEASE_STAGE="$(mktemp -d "${DEST}.release.XXXXXX")"
  RELEASE_STAGE_ID="$(path_identity "$RELEASE_STAGE")"
  RELEASE_PRIOR="$RELEASE_STAGE/prior"
  candidate="$RELEASE_STAGE/candidate"
  prepare_release_checkout "$candidate" "$expected"

  if [ "$RELEASE_EXISTING" -eq 1 ]; then
    if ! validate_existing_release_destination \
      "$DEST" "$RELEASE_ORIGINAL_ID" "$RELEASE_ORIGINAL_HEAD"; then
      return 1
    fi
  elif [ -e "$DEST" ] || [ -L "$DEST" ]; then
    echo "Error: installation destination appeared during release staging and was preserved: $DEST" >&2
    return 1
  fi

  if [ "$RELEASE_EXISTING" -eq 1 ]; then
    begin_transition
    if ! move_directory_no_replace \
      "$DEST" "$RELEASE_PRIOR" "$RELEASE_ORIGINAL_ID" \
      "$DEST" "$RELEASE_PRIOR"; then
      end_transition
      return 1
    fi
    RELEASE_HAD_PRIOR=1
    end_transition
  fi

  if [ "$RELEASE_EXISTING" -eq 1 ]; then
    validate_existing_release_destination \
      "$RELEASE_PRIOR" "$RELEASE_ORIGINAL_ID" "$RELEASE_ORIGINAL_HEAD"
  fi

  begin_transition
  if ! move_directory_no_replace \
    "$candidate" "$DEST" "$RELEASE_CANDIDATE_ID" \
    "$candidate" "$DEST"; then
    end_transition
    return 1
  fi
  RELEASE_SWAPPED=1
  RELEASE_NEW_ID="$RELEASE_CANDIDATE_ID"
  end_transition
}

if [ -n "$RELEASE_REF" ]; then
  install_release_checkout "$RELEASE_REF"
elif [ -d "$DEST" ]; then
    sync_checkout "$DEST"
else
  echo "=> Cloning Agent Ecosystem into $DEST..."
  safe_git clone --depth 1 --no-tags "$REPO_URL" "$DEST"
fi

validate_skills_payload "$DEST"
REGISTRAR="$DEST/scripts/register-skills.sh"
if [ -n "$RELEASE_REF" ]; then
  if [ "$(path_identity "$DEST")" != "$RELEASE_NEW_ID" ]; then
    echo "Error: active release checkout changed before verification: $DEST" >&2
    exit 1
  fi
  verify_release_checkout "$DEST" "$RELEASE_REF"
  validate_release_payload "$DEST"
  REGISTRAR="$RELEASE_REGISTRAR"
elif [ ! -f "$REGISTRAR" ] \
  && [ -f "$SCRIPT_DIR/scripts/register-skills.sh" ]; then
  REGISTRAR="$SCRIPT_DIR/scripts/register-skills.sh"
fi
REGISTRAR_DIR="$(dirname "$REGISTRAR")"
if [ -L "$REGISTRAR_DIR" ] \
  || [ ! -d "$REGISTRAR_DIR" ] \
  || [ -L "$REGISTRAR" ] \
  || [ ! -f "$REGISTRAR" ]; then
  echo "Error: scripts/register-skills.sh must be a physical file." >&2
  exit 1
fi
if [ -n "$RELEASE_REF" ]; then
  begin_transition
fi
bash "$REGISTRAR" \
  --scope user \
  --source "$DEST/.agents/skills" \
  --atomic-user-links
RELEASE_REGISTRATION_COMMITTED=1

if [ -n "$RELEASE_REF" ]; then
  if [ "$(path_identity "$DEST")" != "$RELEASE_NEW_ID" ]; then
    echo "Error: active release checkout changed during registration: $DEST" >&2
    exit 1
  fi
  verify_release_checkout "$DEST" "$RELEASE_REF"
  validate_release_payload "$DEST"
  if [ "$(path_identity "$DEST")" != "$RELEASE_NEW_ID" ]; then
    echo "Error: active release checkout changed after verification: $DEST" >&2
    exit 1
  fi
  if [ "$RELEASE_EXISTING" -eq 1 ]; then
    validate_existing_release_destination \
      "$RELEASE_PRIOR" "$RELEASE_ORIGINAL_ID" "$RELEASE_ORIGINAL_HEAD"
  fi
  RELEASE_COMPLETE=1
  end_transition
else
  RELEASE_COMPLETE=1
fi

echo ""
echo "=> Global install complete."
echo "   User-level discovery paths now reference $DEST/.agents/skills."
echo "   Reload your agent tools to discover the updated skills."
echo "   Remote environments do not inherit local home folders; run install.sh in"
echo "   each product repository or use the relevant environment adapter."
