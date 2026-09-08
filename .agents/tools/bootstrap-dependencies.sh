#!/usr/bin/env bash

set -u

# apt treats this environment variable as executable configuration. Never let
# an ambient caller configuration cross the planning or privilege boundary.
unset APT_CONFIG

components=""
mode="plan"

usage() {
  cat <<'EOF'
Usage: bootstrap-dependencies.sh [options]

Options:
  --components frontend,backend,docker  Select only these components.
  --all                                 Select the full agent ecosystem baseline.
  --plan                                Print the plan and make no changes (default).
  --apply                               Print the plan, then ask before changes.
  --yes                                 Print the plan, then apply non-interactively.
  -h, --help                            Show this help.

The baseline is Node 22+, PHP 8.4+, Composer, and Docker with Compose.
The script never changes global runtime defaults or Docker-group membership.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --components)
      components="${2:-}"
      if [ -z "$components" ]; then
        echo "Error: --components requires a comma-separated selection." >&2
        exit 2
      fi
      shift 2
      ;;
    --all) components="frontend,backend,docker"; shift ;;
    --plan) mode="plan"; shift ;;
    --apply) mode="apply"; shift ;;
    --yes) mode="yes"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$components" ] || components="frontend,backend,docker"
selected_frontend=0
selected_backend=0
selected_docker=0
old_ifs="$IFS"
IFS=','
for component in $components; do
  case "$component" in
    frontend) selected_frontend=1 ;;
    backend) selected_backend=1 ;;
    docker) selected_docker=1 ;;
    *)
      echo "Error: unsupported component '$component'. Use frontend, backend, docker, or --all." >&2
      exit 2
      ;;
  esac
done
IFS="$old_ifs"

platform="$(uname -s 2>/dev/null || printf unknown)"
case "$platform" in
  Linux) platform="linux" ;;
  Darwin) platform="macos" ;;
  CYGWIN*|MINGW*|MSYS*) platform="windows-native" ;;
  *) platform="unsupported" ;;
esac

tool_identity() {
  command -p stat -c '%d:%i:%u:%a:%h' -- "$1" 2>/dev/null
}

validate_physical_tool() {
  local path="$1"
  local expected_uid="$2"
  local metadata
  local device inode owner mode links
  local parent="${path%/*}"
  local name="${path##*/}"
  local physical_parent
  local permission_digits group_digit other_digit

  if [[ "$path" != /* ]] || [[ "$path" == */ ]] \
    || [ -L "$path" ] || [ ! -f "$path" ] || [ ! -x "$path" ]; then
    return 1
  fi
  physical_parent="$(cd -- "$parent" 2>/dev/null && pwd -P)" || return 1
  [ "$physical_parent/$name" = "$path" ] || return 1
  metadata="$(tool_identity "$path")" || return 1
  IFS=':' read -r device inode owner mode links <<< "$metadata"
  [ -n "$device" ] && [ -n "$inode" ] && [ "$owner" = "$expected_uid" ] \
    && [[ "$mode" =~ ^[0-7]{3,4}$ ]] && [[ "$links" =~ ^[0-9]+$ ]] \
    || return 1
  permission_digits="${mode: -3}"
  group_digit="${permission_digits:1:1}"
  other_digit="${permission_digits:2:1}"
  if (( (group_digit & 2) != 0 || (other_digit & 2) != 0 )); then
    return 1
  fi
}

resolve_trusted_system_tool() {
  local name="$1"
  local candidate

  for candidate in "/usr/bin/$name" "/usr/sbin/$name" "/bin/$name" "/sbin/$name"; do
    if validate_physical_tool "$candidate" 0; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

revalidate_tool_identity() {
  local label="$1"
  local path="$2"
  local expected_uid="$3"
  local expected_identity="$4"

  if ! validate_physical_tool "$path" "$expected_uid" \
    || [ "$(tool_identity "$path" 2>/dev/null || true)" != "$expected_identity" ]; then
    echo "No changes made: bound $label executable changed after the plan was printed: $path" >&2
    return 1
  fi
}

package_manager="none"
package_manager_issue=""
apt_get_command=""
apt_cache_command=""
sudo_command=""
apt_get_identity=""
apt_cache_identity=""
sudo_identity=""
apt_test_mode=0
if [ "$platform" = "macos" ] && command -v brew >/dev/null 2>&1; then
  package_manager="brew"
elif [ "$platform" = "linux" ]; then
  if [ -n "${AGENTS_ECOSYSTEM_TEST_APT_GET:-}" ] \
    || [ -n "${AGENTS_ECOSYSTEM_TEST_APT_CACHE:-}" ] \
    || [ -n "${AGENTS_ECOSYSTEM_TEST_UNPRIVILEGED_APT:-}" ]; then
    if [ "${AGENTS_ECOSYSTEM_TEST_UNPRIVILEGED_APT:-}" != "1" ] \
      || [ -z "${AGENTS_ECOSYSTEM_TEST_APT_GET:-}" ] \
      || [ -z "${AGENTS_ECOSYSTEM_TEST_APT_CACHE:-}" ] \
      || [ "$EUID" -eq 0 ] \
      || ! validate_physical_tool "$AGENTS_ECOSYSTEM_TEST_APT_GET" "$EUID" \
      || ! validate_physical_tool "$AGENTS_ECOSYSTEM_TEST_APT_CACHE" "$EUID"; then
      package_manager_issue="The unprivileged apt test boundary is incomplete or unsafe."
    else
      apt_test_mode=1
      package_manager="apt"
      apt_get_command="$AGENTS_ECOSYSTEM_TEST_APT_GET"
      apt_cache_command="$AGENTS_ECOSYSTEM_TEST_APT_CACHE"
      apt_get_identity="$(tool_identity "$apt_get_command")"
      apt_cache_identity="$(tool_identity "$apt_cache_command")"
    fi
  else
    trusted_apt_get="$(resolve_trusted_system_tool apt-get 2>/dev/null || true)"
    trusted_apt_cache="$(resolve_trusted_system_tool apt-cache 2>/dev/null || true)"
    ambient_apt_get="$(command -v apt-get 2>/dev/null || true)"
    ambient_apt_cache="$(command -v apt-cache 2>/dev/null || true)"
    if [ -z "$trusted_apt_get" ] || [ -z "$trusted_apt_cache" ]; then
      package_manager_issue="System apt executables must be physical, root-owned, and not group/world-writable."
    elif [ "$ambient_apt_get" != "$trusted_apt_get" ] \
      || [ "$ambient_apt_cache" != "$trusted_apt_cache" ]; then
      package_manager_issue="PATH resolves apt package-manager executables outside the trusted system paths."
    else
      package_manager="apt"
      apt_get_command="$trusted_apt_get"
      apt_cache_command="$trusted_apt_cache"
      apt_get_identity="$(tool_identity "$apt_get_command")"
      apt_cache_identity="$(tool_identity "$apt_cache_command")"
      if [ "$EUID" -ne 0 ]; then
        trusted_sudo="$(resolve_trusted_system_tool sudo 2>/dev/null || true)"
        ambient_sudo="$(command -v sudo 2>/dev/null || true)"
        if [ -z "$trusted_sudo" ] || [ "$ambient_sudo" != "$trusted_sudo" ]; then
          package_manager_issue="sudo must resolve to a physical, root-owned, non-writable system executable."
          package_manager="none"
          apt_get_command=""
          apt_cache_command=""
        else
          sudo_command="$trusted_sudo"
          sudo_identity="$(tool_identity "$sudo_command")"
        fi
      fi
    fi
  fi
fi

brew_formula_binary() {
  local formula="$1"
  local executable="$2"
  local prefix=""
  brew list --versions "$formula" >/dev/null 2>&1 || return 1
  prefix="$(brew --prefix "$formula" 2>/dev/null)" || return 1
  [ -x "$prefix/bin/$executable" ] || return 1
  printf '%s\n' "$prefix/bin/$executable"
}

php_version_id() {
  local executable="$1"
  "$executable" -r 'echo PHP_VERSION_ID;' 2>/dev/null || true
}

actions=()
blockers=()
frontend_needed=0
php_needed=0
composer_needed=0
docker_needed=0

node_command="node"
node_version=""
if [ "$selected_frontend" -eq 1 ]; then
  command -v node >/dev/null 2>&1 && node_version="$(node --version 2>/dev/null || true)"
  node_major="${node_version#v}"
  node_major="${node_major%%.*}"
  if { ! [[ "$node_major" =~ ^[0-9]+$ ]] || [ "$node_major" -lt 22 ]; } \
    && [ "$package_manager" = "brew" ]; then
    brew_node="$(brew_formula_binary node@22 node 2>/dev/null || true)"
    if [ -n "$brew_node" ]; then
      node_command="$brew_node"
      node_version="$("$brew_node" --version 2>/dev/null || true)"
      node_major="${node_version#v}"
      node_major="${node_major%%.*}"
    fi
  fi
  if [[ "$node_major" =~ ^[0-9]+$ ]] && [ "$node_major" -ge 22 ]; then
    actions+=("[frontend] Node $node_version is compatible; no change.")
  else
    frontend_needed=1
    if [ "$package_manager" = "brew" ]; then
      actions+=("[frontend] Install Node 22 with: brew install node@22")
    elif [ "$package_manager" = "apt" ]; then
      candidate="$("$apt_cache_command" policy nodejs 2>/dev/null | awk '/Candidate:/ { print $2; exit }')"
      candidate_major="${candidate#*:}"
      candidate_major="${candidate_major%%.*}"
      if [[ "$candidate_major" =~ ^[0-9]+$ ]] && [ "$candidate_major" -ge 22 ]; then
        actions+=("[frontend] Install Node $candidate from the configured apt source.")
      else
        blockers+=("[frontend] Configured apt sources do not provide Node 22+.")
      fi
    else
      blockers+=("[frontend] No supported package-manager path was detected for Node 22+.")
    fi
  fi
fi

php_command="php"
composer_command="composer"
if [ "$selected_backend" -eq 1 ]; then
  php_id=""
  command -v php >/dev/null 2>&1 && php_id="$(php_version_id php)"
  if { ! [[ "$php_id" =~ ^[0-9]+$ ]] || [ "$php_id" -lt 80400 ]; } \
    && [ "$package_manager" = "brew" ]; then
    brew_php="$(brew_formula_binary php@8.4 php 2>/dev/null || true)"
    if [ -n "$brew_php" ]; then
      php_command="$brew_php"
      php_id="$(php_version_id "$brew_php")"
    fi
  fi
  if [[ "$php_id" =~ ^[0-9]+$ ]] && [ "$php_id" -ge 80400 ]; then
    actions+=("[backend] PHP 8.4+ is compatible; no change.")
  else
    php_needed=1
    if [ "$package_manager" = "brew" ]; then
      actions+=("[backend] Install PHP 8.4 with: brew install php@8.4")
    elif [ "$package_manager" = "apt" ] && "$apt_cache_command" show php8.4-cli >/dev/null 2>&1; then
      actions+=("[backend] Install PHP 8.4 CLI from the configured apt source.")
    else
      blockers+=("[backend] No tested package source for PHP 8.4 was found.")
    fi
  fi

  if command -v composer >/dev/null 2>&1 && composer --version >/dev/null 2>&1; then
    actions+=("[backend] Composer is available; no change.")
  elif [ "$package_manager" = "brew" ]; then
    brew_composer="$(brew_formula_binary composer composer 2>/dev/null || true)"
    if [ -n "$brew_composer" ]; then
      composer_command="$brew_composer"
      actions+=("[backend] Composer is available at $brew_composer; no change.")
    else
      composer_needed=1
      actions+=("[backend] Install Composer with: brew install composer")
    fi
  elif [ "$package_manager" = "apt" ] && "$apt_cache_command" show composer >/dev/null 2>&1; then
    composer_needed=1
    actions+=("[backend] Install Composer from the configured apt source.")
  else
    composer_needed=1
    blockers+=("[backend] No tested package source for Composer was found.")
  fi
fi

docker_cli=0
docker_compose=0
if [ "$selected_docker" -eq 1 ]; then
  command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 && docker_cli=1
  [ "$docker_cli" -eq 1 ] && docker compose version >/dev/null 2>&1 && docker_compose=1
  if [ "$docker_cli" -eq 1 ] && [ "$docker_compose" -eq 1 ]; then
    actions+=("[docker] Docker CLI and Compose are available; no change. Daemon readiness remains a project check.")
  else
    docker_needed=1
    if [ "$package_manager" = "brew" ]; then
      actions+=("[docker] Install Docker Desktop with: brew install --cask docker")
    elif [ "$package_manager" = "apt" ] \
      && "$apt_cache_command" show docker.io >/dev/null 2>&1 \
      && "$apt_cache_command" show docker-compose-v2 >/dev/null 2>&1; then
      actions+=("[docker] Install Docker CLI/Engine and Compose from configured apt sources.")
    else
      blockers+=("[docker] No tested Docker package set was found.")
    fi
  fi
fi

if [ "$platform" = "windows-native" ]; then
  blockers+=("[platform] Native Windows installation is not supported by this Bash tool. Use WSL2 or reviewed native instructions.")
elif [ "$platform" = "unsupported" ]; then
  blockers+=("[platform] Unsupported operating system. This tool exercises Linux/apt and macOS/Homebrew paths.")
elif [ "$package_manager" = "none" ] \
  && { [ "$frontend_needed" -eq 1 ] || [ "$php_needed" -eq 1 ] || [ "$composer_needed" -eq 1 ] || [ "$docker_needed" -eq 1 ]; }; then
  if [ -n "$package_manager_issue" ]; then
    blockers+=("[platform] $package_manager_issue No host changes will be made.")
  else
    blockers+=("[platform] No supported package manager was detected. No host changes will be made.")
  fi
fi

echo "Dependency plan"
echo "Platform: $platform; package manager: $package_manager"
if [ "$package_manager" = "apt" ]; then
  if [ "$apt_test_mode" -eq 1 ]; then
    echo "APT executable boundary: unprivileged test mode; cache=$apt_cache_command; apply=$apt_get_command"
  else
    echo "APT executable boundary: cache=$apt_cache_command; apply=$apt_get_command; privilege=${sudo_command:-already-root}"
  fi
fi
for action in "${actions[@]}"; do echo "  $action"; done
for blocker in "${blockers[@]}"; do echo "  BLOCKED $blocker"; done
echo "Global runtime defaults are outside this plan."
if [ "$selected_docker" -eq 1 ]; then
  echo "Docker-group membership is a separate privilege decision and is not changed."
fi

if [ "$mode" = "plan" ]; then
  echo "No changes made. Re-run with --apply or --yes after reviewing this plan."
  exit 0
fi
if [ "${#blockers[@]}" -gt 0 ]; then
  echo "No changes made because the preflight found unsupported steps." >&2
  exit 1
fi
if [ "$frontend_needed" -eq 0 ] && [ "$php_needed" -eq 0 ] \
  && [ "$composer_needed" -eq 0 ] && [ "$docker_needed" -eq 0 ]; then
  echo "All selected components are compatible; no changes made."
  exit 0
fi
if [ "$mode" = "apply" ]; then
  if [ ! -t 0 ]; then
    echo "No changes made: interactive confirmation requires a terminal. Use --yes only after reviewing the plan." >&2
    exit 2
  fi
  read -r -p "Apply this exact dependency plan? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then echo "No changes made."; exit 0; fi
else
  echo "Confirmation: --yes accepted for the plan shown above."
fi

sudo_prefix=()
if [ "$package_manager" = "apt" ]; then
  revalidate_tool_identity "apt-get" "$apt_get_command" \
    "$([ "$apt_test_mode" -eq 1 ] && printf '%s' "$EUID" || printf '0')" \
    "$apt_get_identity" || exit 1
  revalidate_tool_identity "apt-cache" "$apt_cache_command" \
    "$([ "$apt_test_mode" -eq 1 ] && printf '%s' "$EUID" || printf '0')" \
    "$apt_cache_identity" || exit 1
  if [ "$apt_test_mode" -eq 0 ] && [ "$EUID" -ne 0 ]; then
    revalidate_tool_identity "sudo" "$sudo_command" 0 "$sudo_identity" || exit 1
    sudo_prefix=("$sudo_command")
  fi
fi

completed=()
failed=()
run_step() {
  local label="$1"; shift
  if "$@"; then completed+=("$label"); return 0; fi
  failed+=("$label"); return 1
}

apt_refresh_if_needed() {
  if [[ ! " ${completed[*]} " =~ " apt package index refresh " ]] \
    && [[ ! " ${failed[*]} " =~ " apt package index refresh " ]]; then
    run_step "apt package index refresh" "${sudo_prefix[@]}" "$apt_get_command" update || true
  fi
}

if [ "$frontend_needed" -eq 1 ]; then
  if [ "$package_manager" = "brew" ]; then
    run_step "frontend package installation" brew install node@22 || true
    node_command="$(brew_formula_binary node@22 node 2>/dev/null || true)"
  else
    apt_refresh_if_needed
    [[ " ${failed[*]} " =~ " apt package index refresh " ]] \
      || run_step "frontend package installation" "${sudo_prefix[@]}" "$apt_get_command" install -y nodejs || true
  fi
  installed_node=""
  [ -n "$node_command" ] && installed_node="$("$node_command" --version 2>/dev/null || true)"
  installed_node_major="${installed_node#v}"; installed_node_major="${installed_node_major%%.*}"
  [[ "$installed_node_major" =~ ^[0-9]+$ ]] && [ "$installed_node_major" -ge 22 ] \
    || failed+=("frontend verification")
fi

if [ "$php_needed" -eq 1 ]; then
  if [ "$package_manager" = "brew" ]; then
    run_step "PHP package installation" brew install php@8.4 || true
    php_command="$(brew_formula_binary php@8.4 php 2>/dev/null || true)"
  else
    apt_refresh_if_needed
    [[ " ${failed[*]} " =~ " apt package index refresh " ]] \
      || run_step "PHP package installation" "${sudo_prefix[@]}" "$apt_get_command" install -y php8.4-cli || true
  fi
  installed_php_id=""
  [ -n "$php_command" ] && installed_php_id="$(php_version_id "$php_command")"
  [[ "$installed_php_id" =~ ^[0-9]+$ ]] && [ "$installed_php_id" -ge 80400 ] \
    || failed+=("PHP verification")
fi

if [ "$composer_needed" -eq 1 ]; then
  if [ "$package_manager" = "brew" ]; then
    run_step "Composer package installation" brew install composer || true
    composer_command="$(brew_formula_binary composer composer 2>/dev/null || true)"
  else
    apt_refresh_if_needed
    [[ " ${failed[*]} " =~ " apt package index refresh " ]] \
      || run_step "Composer package installation" "${sudo_prefix[@]}" "$apt_get_command" install -y composer || true
  fi
  [ -n "$composer_command" ] && "$composer_command" --version >/dev/null 2>&1 \
    || failed+=("Composer verification")
fi

if [ "$docker_needed" -eq 1 ]; then
  if [ "$package_manager" = "brew" ]; then
    run_step "Docker Desktop installation" brew install --cask docker || true
  else
    apt_refresh_if_needed
    [[ " ${failed[*]} " =~ " apt package index refresh " ]] \
      || run_step "Docker package installation" "${sudo_prefix[@]}" "$apt_get_command" install -y docker.io docker-compose-v2 || true
  fi
  command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 \
    && docker compose version >/dev/null 2>&1 || failed+=("docker verification")
fi

echo "Completed steps: ${completed[*]:-none}"
if [ "${#failed[@]}" -gt 0 ]; then
  echo "Incomplete steps: ${failed[*]}" >&2
  echo "The completed state is retained. Fix the reported step and rerun safely; no rollback is claimed." >&2
  exit 1
fi
echo "Selected dependency setup completed and verified."
echo "No global runtime default or Docker-group membership was changed."
