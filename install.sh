#!/usr/bin/env bash

# Agent Ecosystem Installation Script
# Installs upstream-managed .agents/ content, stages documentation candidates,
# and delegates tool discovery to the available skill adapters. Active project
# documentation remains project-owned and is never created or changed here.
#
# Usage:
#   bash install.sh
#   bash install.sh --skip-deps
#   bash install.sh --deps frontend,backend
#   bash install.sh --skip-deps --from-local /path/to/agents
#   bash install.sh --skip-deps --ref <40-character-commit-sha>

set -euo pipefail
umask 022

REPO_URL="https://github.com/marcus-friction/agents.git"
SKIP_DEPS=0
DEPS_SELECTION=""
FROM_LOCAL=""
RELEASE_REF=""

for git_variable in "${!GIT_@}"; do
  unset "$git_variable"
done

usage() {
  echo "Usage: $0 [--skip-deps] [--deps selection] [--from-local path] [--ref 40-character-commit-sha]"
}

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

validate_immutable_source_config() {
  local source="$1"
  local config="$source/.git/config"
  local config_keys
  local key
  local link_count

  if [ -L "$config" ] || [ ! -f "$config" ]; then
    echo "Error: immutable source local Git configuration must be a physical file: $config" >&2
    return 1
  fi
  if link_count="$(command -p stat -c '%h' -- "$config" 2>/dev/null)"; then
    :
  elif link_count="$(command -p stat -f '%l' -- "$config" 2>/dev/null)"; then
    :
  else
    echo "Error: immutable source local Git configuration identity could not be verified: $config" >&2
    return 1
  fi
  if [ "$link_count" != "1" ]; then
    echo "Error: immutable source local Git configuration must have one physical link: $config" >&2
    return 1
  fi
  config_keys="$(safe_git config --file "$config" \
    --no-includes --name-only --list)" || {
    echo "Error: immutable source local Git configuration could not be parsed safely: $config" >&2
    return 1
  }
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    case "$key" in
      core.repositoryformatversion|core.filemode|core.bare|core.logallrefupdates|\
      core.ignorecase|core.precomposeunicode|core.symlinks|extensions.objectformat|\
      user.name|user.email|remote.origin.url|remote.origin.fetch|\
      branch.*.remote|branch.*.merge)
        ;;
      *)
        echo "Error: immutable source has unsupported local Git configuration: $key" >&2
        return 1
        ;;
    esac
  done <<< "$config_keys"
}

verify_immutable_source() {
  local source="$1"
  local expected="$2"
  local actual
  local index_flags
  local status

  if [ -L "$source/.git" ] || [ ! -d "$source/.git" ]; then
    echo "Error: immutable source must have a physical .git directory: $source" >&2
    return 1
  fi
  validate_immutable_source_config "$source"
  actual="$(safe_git -C "$source" rev-parse --verify 'HEAD^{commit}' 2>/dev/null || true)"
  if [ "$actual" != "$expected" ]; then
    echo "Error: source HEAD $actual does not match expected release commit $expected." >&2
    return 1
  fi
  if safe_git -C "$source" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "Error: immutable source must use detached HEAD at $expected." >&2
    return 1
  fi
  status="$(safe_git -C "$source" status \
    --porcelain=v1 --untracked-files=all --ignored=matching)"
  if [ -n "$status" ]; then
    echo "Error: immutable source must be clean before repository code executes: $source" >&2
    return 1
  fi
  index_flags="$(safe_git -C "$source" ls-files -v | sed -n '/^[a-zS]/p')"
  if [ -n "$index_flags" ]; then
    echo "Error: immutable source has hidden index state; refusing to materialize it: $source" >&2
    return 1
  fi
  echo "=> Verified immutable source at $expected (detached HEAD)."
}

materialize_immutable_source() {
  local source="$1"
  local expected="$2"

  if ! command -v tar >/dev/null 2>&1; then
    echo "Error: tar is required to materialize an immutable local release." >&2
    return 1
  fi
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  if ! safe_git -C "$source" archive --format=tar "$expected" \
    | env -u TAR_OPTIONS tar -xf - -C "$TMP_DIR"; then
    echo "Error: failed to materialize release commit $expected." >&2
    return 1
  fi
  SRC="$TMP_DIR"
  echo "=> Materialized immutable source from commit $expected."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-deps)
      SKIP_DEPS=1
      shift
      ;;
    --deps)
      DEPS_SELECTION="${2:-}"
      if [ -z "$DEPS_SELECTION" ]; then
        echo "Error: --deps requires frontend, backend, docker, all, or a comma-separated selection."
        exit 1
      fi
      shift 2
      ;;
    --from-local)
      FROM_LOCAL="${2:-}"
      if [ -z "$FROM_LOCAL" ]; then
        echo "Error: --from-local requires a path."
        exit 1
      fi
      shift 2
      ;;
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
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -n "$RELEASE_REF" ] && ! [[ "$RELEASE_REF" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Error: --ref requires a full 40-character lowercase commit SHA." >&2
  exit 1
fi

if [ "$SKIP_DEPS" -eq 1 ] && [ -n "$DEPS_SELECTION" ]; then
    echo "Error: --skip-deps and --deps cannot be used together."
    exit 1
fi
if [ -n "$DEPS_SELECTION" ] \
    && ! [[ "$DEPS_SELECTION" =~ ^(all|(frontend|backend|docker)(,(frontend|backend|docker))*)$ ]]; then
    echo "Error: unsupported dependency selection '$DEPS_SELECTION'." >&2
    echo "Use frontend, backend, docker, all, or a comma-separated component list." >&2
    exit 1
fi

SRC=""
TMP_DIR=""
if [ -n "$FROM_LOCAL" ]; then
    if [ ! -d "$FROM_LOCAL/.agents" ]; then
        echo "Error: --from-local path has no .agents directory: $FROM_LOCAL"
        exit 1
    fi
    SRC="$(cd "$FROM_LOCAL" && pwd -P)"
    if [ -n "$RELEASE_REF" ]; then
        verify_immutable_source "$SRC" "$RELEASE_REF"
        immutable_source="$SRC"
        materialize_immutable_source "$immutable_source" "$RELEASE_REF"
    fi
    echo "=> Installing Agent Ecosystem from local checkout $SRC..."
else
    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed but is required to download the ecosystem."
        exit 1
    fi
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    echo "=> Cloning Agent Ecosystem into a temporary directory..."
    if [ -n "$RELEASE_REF" ]; then
        safe_git init -q "$TMP_DIR"
        safe_git -C "$TMP_DIR" remote add origin "$REPO_URL"
        if ! safe_git -C "$TMP_DIR" fetch \
            --depth 1 --no-tags origin "$RELEASE_REF" >/dev/null; then
            echo "Error: Failed to fetch release commit $RELEASE_REF." >&2
            exit 1
        fi
        safe_git -C "$TMP_DIR" checkout --quiet --detach FETCH_HEAD
        verify_immutable_source "$TMP_DIR" "$RELEASE_REF"
    elif ! safe_git clone --depth 1 --no-tags "$REPO_URL" "$TMP_DIR" > /dev/null; then
        echo "Error: Failed to clone the repository."
        exit 1
    fi
    SRC="$TMP_DIR"
fi

if [ -L "$SRC/.agents/skills" ] || [ ! -d "$SRC/.agents/skills" ]; then
    echo "Error: canonical source skills must be a physical directory: $SRC/.agents/skills"
    exit 1
fi
INSTALL_ROOT="$(pwd -P)"
if [ "$SRC" != "$INSTALL_ROOT" ]; then
    for reserved_source_path in project rules; do
        if [ -e "$SRC/.agents/$reserved_source_path" ] \
            || [ -L "$SRC/.agents/$reserved_source_path" ]; then
            echo "Error: the distribution contains a reserved target-only path: $SRC/.agents/$reserved_source_path"
            exit 1
        fi
    done
fi

register_skill_adapters() {
    if [ ! -d ".agents/skills" ]; then
        return 0
    fi

    local registrar="$SRC/scripts/register-skills.sh"
    if [ ! -f "$registrar" ]; then
        echo "Error: skill adapter registrar not found: $registrar"
        exit 1
    fi

    echo "=> Registering skills through available tool adapters..."
    bash "$registrar" \
        --scope project \
        --project-root "$(pwd -P)" \
        --source "$(pwd -P)/.agents/skills"
}

stage_project_templates() {
    local staging_script="$SRC/scripts/stage-project-templates.sh"
    if [ ! -f "$staging_script" ]; then
        echo "Error: project template staging script not found: $staging_script"
        exit 1
    fi

    echo "=> Staging upstream documentation candidates..."
    bash "$staging_script" "$SRC" "$(pwd -P)"
}

preflight_legal_payload() {
    local project_root="$1"
    local source_legal="$SRC/.agents/legal"
    local target_legal="$project_root/.agents/legal"
    local source_entry
    local target_entry

    if [ ! -e "$source_legal" ] && [ ! -L "$source_legal" ]; then
        return 0
    fi
    if [ -L "$source_legal" ] || [ ! -d "$source_legal" ]; then
        echo "Error: source .agents/legal must be a physical directory." >&2
        exit 1
    fi
    if [ -L "$source_legal/.agents-ecosystem-managed" ] \
        || [ ! -f "$source_legal/.agents-ecosystem-managed" ]; then
        echo "Error: source legal payload lacks its physical management marker." >&2
        exit 1
    fi
    if [ ! -e "$target_legal" ] && [ ! -L "$target_legal" ]; then
        return 0
    fi
    if [ -L "$target_legal" ] || [ ! -d "$target_legal" ]; then
        echo "Error: target .agents/legal must be a physical directory." >&2
        exit 1
    fi
    if [ -f "$target_legal/.agents-ecosystem-managed" ] \
        && [ ! -L "$target_legal/.agents-ecosystem-managed" ] \
        && cmp -s \
            "$source_legal/.agents-ecosystem-managed" \
            "$target_legal/.agents-ecosystem-managed"; then
        return 0
    fi

    while IFS= read -r -d '' source_entry; do
        if [ -L "$source_entry" ] || [ ! -f "$source_entry" ]; then
            echo "Error: source legal payload entries must be physical files: $source_entry" >&2
            exit 1
        fi
        target_entry="$target_legal/${source_entry##*/}"
        if [ ! -e "$target_entry" ] && [ ! -L "$target_entry" ]; then
            continue
        fi
        if [ -L "$target_entry" ] \
            || [ ! -f "$target_entry" ] \
            || ! cmp -s "$source_entry" "$target_entry"; then
            echo "Error: unmanaged .agents/legal collision: $target_entry" >&2
            exit 1
        fi
    done < <(find "$source_legal" -mindepth 1 -maxdepth 1 -print0)
}

preflight_installation() {
    local project_root
    local managed_tree_sync="$SRC/scripts/sync-managed-tree.sh"
    local staging_script="$SRC/scripts/stage-project-templates.sh"
    local registrar="$SRC/scripts/register-skills.sh"
    project_root="$(pwd -P)"

    if [ -L "$SRC/scripts" ] || [ ! -d "$SRC/scripts" ]; then
        echo "Error: source scripts must be a physical directory: $SRC/scripts" >&2
        exit 1
    fi
    for required_script in "$managed_tree_sync" "$staging_script" "$registrar"; do
        if [ -L "$required_script" ] || [ ! -f "$required_script" ]; then
            echo "Error: required installation script must be a physical file: $required_script"
            exit 1
        fi
    done

    echo "=> Preflighting every managed path and adapter target..."
    preflight_legal_payload "$project_root"
    bash "$managed_tree_sync" \
        --check \
        --exclude-top-level templates \
        "$SRC/.agents" \
        "$project_root/.agents"
    bash "$staging_script" --check "$SRC" "$project_root"
    bash "$registrar" \
        --scope project \
        --project-root "$project_root" \
        --preflight-only
}

if [ -L ".agents" ]; then
    echo "Error: project .agents directory must not be a symlink: $(pwd -P)/.agents"
    exit 1
fi
if [ -e ".agents" ] && [ ! -d ".agents" ]; then
    echo "Error: project .agents path is not a directory: $(pwd -P)/.agents"
    exit 1
fi
if [ -L ".agents/templates" ]; then
    echo "Error: project template directory must not be a symlink: $(pwd -P)/.agents/templates"
    exit 1
fi
if [ -e ".agents/templates" ] && [ ! -d ".agents/templates" ]; then
    echo "Error: project template path is not a directory: $(pwd -P)/.agents/templates"
    exit 1
fi
preflight_installation

echo "=> Installing upstream-managed .agents assets..."
if [ -d "$SRC/.agents" ]; then
    managed_tree_sync="$SRC/scripts/sync-managed-tree.sh"
    bash "$managed_tree_sync" \
        --exclude-top-level templates \
        "$SRC/.agents" \
        "$(pwd -P)/.agents"
else
    echo "Warning: .agents directory not found in the source repository."
fi

stage_project_templates

echo "=> Inspecting project-owned documentation (no files will be changed)..."
for project_document in AGENTS.md README.md CONTRIBUTING.md DESIGN.md ARCHITECTURE.md; do
    if [ -e "$project_document" ] || [ -L "$project_document" ]; then
        echo "   [Existing] $project_document"
    else
        echo "   [Missing]  $project_document"
    fi
done

register_skill_adapters

if [ "$SKIP_DEPS" -eq 1 ]; then
    echo "=> [Skipped] System dependency bootstrap (--skip-deps)."
elif [ -n "$DEPS_SELECTION" ]; then
    dependency_tool="$INSTALL_ROOT/.agents/tools/bootstrap-dependencies.sh"
    if [ -L "$dependency_tool" ] || [ ! -f "$dependency_tool" ]; then
        echo "Error: installed dependency tool must be a physical file: $dependency_tool"
        exit 1
    fi
    echo "=> Preparing explicit dependency setup for: $DEPS_SELECTION"
    if [ "$DEPS_SELECTION" = "all" ]; then
        bash "$dependency_tool" --all --apply
    else
        bash "$dependency_tool" --components "$DEPS_SELECTION" --apply
    fi
else
    echo "=> [Skipped] Host dependency changes are opt-in."
    echo "   Review a non-mutating plan with:"
    echo "   .agents/tools/bootstrap-dependencies.sh --plan --all"
    echo "   Or rerun install.sh with --deps frontend|backend|docker|all."
fi

echo ""
echo "=> Installation Complete!"
echo "   Canonical skills are installed at .agents/skills."
echo "   Documentation candidates are staged at .agents/templates."
echo "   Existing and missing project documents were left untouched."
echo "   Tool discovery paths were registered through available adapters."
echo "   To initialize the ecosystem, ask your agent to run:"
echo "     - the start-project skill   (for a brand new codebase or idea)"
echo "     - the onboard-project skill (to integrate an existing repository)"
echo "   For skills in every local project (not just this repo), run:"
echo "     ./install-global.sh   (from an agents checkout)"
