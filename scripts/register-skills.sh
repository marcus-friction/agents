#!/usr/bin/env bash

# Register the canonical skill tree with available consumers. This script uses a
# cooperative concurrency model: it preflights all targets, then creates only
# absent links and rolls back links still equal to those it created.

set -euo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/trusted-path.sh"
ADAPTER_DIR="$SCRIPT_DIR/skill-adapters"
DISTRIBUTION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SCOPE=project
PROJECT_ROOT="$(pwd -P)"
SKILLS_SOURCE=""
REQUESTED=all
PREFLIGHT_ONLY=0
JOURNAL=""
JOURNAL_ID="" JOURNAL_PARENT="" JOURNAL_PARENT_ID="" JOURNAL_TMP="" JOURNAL_TMP_ID=""

usage() {
  cat <<'EOF'
Usage: register-skills.sh [options]
  --scope project|user
  --project-root PATH
  --source PATH
  --adapters NAME[,NAME...]
  --preflight-only
  --journal-output FILE
EOF
}

need_value() { [ -n "${2:-}" ] || { echo "Error: $1 requires a value." >&2; exit 1; }; }
path_identity() {
  local kind
  if [ -L "$1" ]; then kind=symlink
  elif [ -d "$1" ]; then kind=directory
  elif [ -f "$1" ]; then kind=file
  elif [ -e "$1" ]; then kind=other
  else echo absent; return 0
  fi
  if stat -c '%d:%i:%u' -- "$1" >/dev/null 2>&1; then
    printf '%s:%s\n' "$kind" "$(stat -c '%d:%i:%u' -- "$1")"
  else
    printf '%s:%s\n' "$kind" "$(stat -f '%d:%i:%u' "$1")"
  fi
}
file_metadata() {
  stat -c '%u:%a:%h' -- "$1" 2>/dev/null || stat -f '%u:%Lp:%l' "$1"
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope) need_value "$1" "${2:-}"; SCOPE="$2"; shift 2 ;;
    --project-root) need_value "$1" "${2:-}"; PROJECT_ROOT="$2"; shift 2 ;;
    --source) need_value "$1" "${2:-}"; SKILLS_SOURCE="$2"; shift 2 ;;
    --adapters) need_value "$1" "${2:-}"; REQUESTED="$2"; shift 2 ;;
    --preflight-only) PREFLIGHT_ONLY=1; shift ;;
    --journal-output) need_value "$1" "${2:-}"; JOURNAL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$SCOPE" in project|user) ;; *) echo "Error: --scope must be project or user." >&2; exit 1 ;; esac
[ ! -L "$PROJECT_ROOT" ] && [ -d "$PROJECT_ROOT" ] || { echo "Error: project root must be a physical directory." >&2; exit 1; }
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd -P)"

if [ -z "$SKILLS_SOURCE" ]; then
  [ "$SCOPE" = project ] || { echo "Error: --source is required for user scope." >&2; exit 1; }
  SKILLS_SOURCE="$PROJECT_ROOT/.agents/skills"
fi
if [ "$SCOPE" = project ]; then
  [ "$SKILLS_SOURCE" = "$PROJECT_ROOT/.agents/skills" ] || {
    echo "Error: project source must be $PROJECT_ROOT/.agents/skills" >&2; exit 1;
  }
  if [ -e "$SKILLS_SOURCE" ] || [ -L "$SKILLS_SOURCE" ]; then
    [ ! -L "$SKILLS_SOURCE" ] && [ -d "$SKILLS_SOURCE" ] || { echo "Error: skill source must be a physical directory: $SKILLS_SOURCE" >&2; exit 1; }
    [ "$(cd "$SKILLS_SOURCE" && pwd -P)" = "$SKILLS_SOURCE" ] || { echo "Error: skill source crosses a symlink." >&2; exit 1; }
  elif [ "$PREFLIGHT_ONLY" -eq 0 ]; then
    echo "Error: skill source must exist: $SKILLS_SOURCE" >&2; exit 1
  fi
else
  [ ! -L "$SKILLS_SOURCE" ] && [ -d "$SKILLS_SOURCE" ] || { echo "Error: skill source must be a physical directory: $SKILLS_SOURCE" >&2; exit 1; }
  SKILLS_SOURCE="$(cd "$SKILLS_SOURCE" && pwd -P)"
fi

if [ "$SCOPE" = user ]; then
  [ -n "${HOME:-}" ] && [ ! -L "$HOME" ] && [ -d "$HOME" ] || { echo "Error: HOME must be a physical directory." >&2; exit 1; }
  SCOPE_ROOT="$(cd "$HOME" && pwd -P)"
  require_trusted_parent "$SCOPE_ROOT"
else
  SCOPE_ROOT="$PROJECT_ROOT"
fi

if [ -n "$JOURNAL" ]; then
  [ "$PREFLIGHT_ONLY" -eq 0 ] || { echo "Error: journal and preflight-only are incompatible." >&2; exit 1; }
  case "$JOURNAL" in /*) ;; *) echo "Error: journal path must be absolute." >&2; exit 1 ;; esac
  [ ! -L "$JOURNAL" ] && [ -f "$JOURNAL" ] || { echo "Error: journal must be a precreated physical file." >&2; exit 1; }
  JOURNAL_PARENT="$(dirname "$JOURNAL")"
  require_trusted_parent "$JOURNAL_PARENT"
  [ ! -L "$JOURNAL_PARENT" ] && [ -d "$JOURNAL_PARENT" ] \
    && [ "$(cd "$JOURNAL_PARENT" && pwd -P)" = "$JOURNAL_PARENT" ] || {
      echo "Error: journal parent must be a normalized physical directory." >&2; exit 1;
    }
  [ "$(file_metadata "$JOURNAL")" = "$(id -u):600:1" ] || {
    echo "Error: journal must be owner-owned mode 0600 with one link." >&2; exit 1;
  }
  JOURNAL_ID="$(path_identity "$JOURNAL")"
  JOURNAL_PARENT_ID="$(path_identity "$JOURNAL_PARENT")"
fi

[ ! -L "$ADAPTER_DIR" ] && [ -d "$ADAPTER_DIR" ] || { echo "Error: adapter directory must be physical." >&2; exit 1; }
ADAPTER_FILES=()
if [ "$REQUESTED" = all ]; then
  for adapter in "$ADAPTER_DIR"/*.sh; do [ -f "$adapter" ] && [ ! -L "$adapter" ] && ADAPTER_FILES+=("$adapter"); done
else
  IFS=',' read -r -a names <<< "$REQUESTED"
  for name in "${names[@]}"; do
    [[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "Error: invalid adapter name: $name" >&2; exit 1; }
    adapter="$ADAPTER_DIR/$name.sh"
    [ ! -L "$adapter" ] && [ -f "$adapter" ] || { echo "Error: unknown adapter: $name" >&2; exit 1; }
    ADAPTER_FILES+=("$adapter")
  done
fi
[ "${#ADAPTER_FILES[@]}" -gt 0 ] || { echo "Error: no adapters selected." >&2; exit 1; }

REGISTRATION_LOCK=""
if [ "$PREFLIGHT_ONLY" -eq 0 ]; then
  REGISTRATION_LOCK="$SCOPE_ROOT/.agents-ecosystem-registration.lock"
  mkdir "$REGISTRATION_LOCK" 2>/dev/null || {
    echo "Error: another skill registration is in progress" >&2; exit 1;
  }
  trap 'rmdir "$REGISTRATION_LOCK"' EXIT
fi
TARGETS=() SOURCES=() ACTIVE_ADAPTERS=()
inside_scope() { case "$1" in "$SCOPE_ROOT"/*) return 0 ;; *) return 1 ;; esac; }
safe_parent_chain() {
  local path="$1" parent current
  parent="$(dirname "$path")"; current="$parent"
  while [ "$current" != "$SCOPE_ROOT" ]; do
    inside_scope "$current" || { echo "Error: adapter target escapes scope: $path" >&2; return 1; }
    [ ! -L "$current" ] || { echo "Error: adapter path crosses a symlink: $current" >&2; return 1; }
    [ ! -e "$current" ] || [ -d "$current" ] || { echo "Error: adapter ancestor is not a directory: $current" >&2; return 1; }
    if [ "$SCOPE" = user ] && [ -d "$current" ]; then require_trusted_parent "$current"; fi
    current="$(dirname "$current")"
  done
}

# Adapter scripts are trusted distribution code. Evaluate each in isolation,
# capture its target, and complete every collision check before mutation.
for adapter in "${ADAPTER_FILES[@]}"; do
  unset -f skill_adapter_supports_scope skill_adapter_target skill_adapter_link_source skill_adapter_preflight skill_adapter_configure 2>/dev/null || true
  # shellcheck source=/dev/null
  source "$adapter"
  declare -F skill_adapter_supports_scope >/dev/null && declare -F skill_adapter_target >/dev/null && declare -F skill_adapter_link_source >/dev/null || {
    echo "Error: invalid adapter contract: $adapter" >&2; exit 1;
  }
  skill_adapter_supports_scope "$SCOPE" || continue
  target="$(skill_adapter_target "$SCOPE" "$PROJECT_ROOT")"
  link_source="$(skill_adapter_link_source "$SCOPE" "$SKILLS_SOURCE")"
  case "$target" in /*) ;; *) echo "Error: adapter target must be absolute: $target" >&2; exit 1 ;; esac
  inside_scope "$target" || { echo "Error: adapter target escapes scope: $target" >&2; exit 1; }
  safe_parent_chain "$target"
  if [ -e "$target" ] && [ ! -L "$target" ]; then echo "Error: adapter target exists and is not a symlink: $target" >&2; exit 1; fi
  if [ -L "$target" ] && [ "$(readlink "$target")" != "$link_source" ]; then echo "Error: adapter target points elsewhere: $target" >&2; exit 1; fi
  if declare -F skill_adapter_preflight >/dev/null; then skill_adapter_preflight "$SCOPE" "$PROJECT_ROOT" "$SKILLS_SOURCE" "$DISTRIBUTION_ROOT"; fi
  TARGETS+=("$target"); SOURCES+=("$link_source"); ACTIVE_ADAPTERS+=("$adapter")
done

if [ "$PREFLIGHT_ONLY" -eq 1 ]; then echo "   [Ready] Adapter targets passed preflight"; exit 0; fi

CREATED=() CREATED_SOURCES=() CREATED_PARENTS=() CREATED_IDENTITIES=()
rollback() {
  local status=$? i target source parent identity
  if [ "$status" -ne 0 ]; then
    for ((i=${#CREATED[@]}-1; i>=0; i--)); do
      target="${CREATED[$i]}"; source="${CREATED_SOURCES[$i]}"
      parent="${CREATED_PARENTS[$i]}"; identity="${CREATED_IDENTITIES[$i]}"
      if [ "$(path_identity "$(dirname "$target")")" = "$parent" ] \
        && [ "$(path_identity "$target")" = "$identity" ] \
        && [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        rm -f -- "$target"
      fi
    done
  fi
  if [ -n "$JOURNAL_TMP" ] && [ "$(path_identity "$JOURNAL_TMP")" = "$JOURNAL_TMP_ID" ]; then
    rm -f -- "$JOURNAL_TMP"
  fi
  if [ -n "$REGISTRATION_LOCK" ]; then rmdir "$REGISTRATION_LOCK" || status=1; fi
  exit "$status"
}
trap rollback EXIT
trap 'exit 130' INT TERM

for i in "${!TARGETS[@]}"; do
  target="${TARGETS[$i]}"; source="${SOURCES[$i]}"
  if [ -L "$target" ]; then
    [ "$(readlink "$target")" = "$source" ] || { echo "Error: adapter target changed after preflight: $target" >&2; exit 1; }
    echo "   [Unchanged] $target -> $source"; continue
  fi
  mkdir -p "$(dirname "$target")"
  safe_parent_chain "$target"
  ln -s -n "$source" "$target"
  CREATED+=("$target")
  CREATED_SOURCES+=("$source")
  CREATED_PARENTS+=("$(path_identity "$(dirname "$target")")")
  CREATED_IDENTITIES+=("$(path_identity "$target")")
  echo "   [Linked] $target -> $source"
done

for i in "${!ACTIVE_ADAPTERS[@]}"; do
  unset -f skill_adapter_supports_scope skill_adapter_target skill_adapter_link_source skill_adapter_preflight skill_adapter_configure 2>/dev/null || true
  source "${ACTIVE_ADAPTERS[$i]}"
  if declare -F skill_adapter_configure >/dev/null; then skill_adapter_configure "$SCOPE" "$PROJECT_ROOT" "$SKILLS_SOURCE" "$DISTRIBUTION_ROOT"; fi
done

if [ -n "$JOURNAL" ]; then
  [ "$(path_identity "$JOURNAL_PARENT")" = "$JOURNAL_PARENT_ID" ] \
    && [ "$(path_identity "$JOURNAL")" = "$JOURNAL_ID" ] \
    && [ "$(file_metadata "$JOURNAL")" = "$(id -u):600:1" ] || {
      echo "Error: journal changed before publication." >&2; exit 1;
    }
  JOURNAL_TMP="$(mktemp "$JOURNAL_PARENT/.agents-ecosystem-registration-journal.XXXXXX")"
  chmod 0600 "$JOURNAL_TMP"
  JOURNAL_TMP_ID="$(path_identity "$JOURNAL_TMP")"
  for i in "${!CREATED[@]}"; do
    printf '%s\t%s\t%s\t%s\n' \
      "${CREATED[$i]}" "${CREATED_SOURCES[$i]}" \
      "${CREATED_PARENTS[$i]}" "${CREATED_IDENTITIES[$i]}" >> "$JOURNAL_TMP"
  done
  [ "$(path_identity "$JOURNAL_PARENT")" = "$JOURNAL_PARENT_ID" ] \
    && [ "$(path_identity "$JOURNAL")" = "$JOURNAL_ID" ] \
    && [ "$(path_identity "$JOURNAL_TMP")" = "$JOURNAL_TMP_ID" ] || {
      echo "Error: journal changed during publication." >&2; exit 1;
    }
  mv -- "$JOURNAL_TMP" "$JOURNAL"
  JOURNAL_TMP="" JOURNAL_TMP_ID=""
fi
rmdir "$REGISTRATION_LOCK"
REGISTRATION_LOCK=""
trap - EXIT INT TERM
