#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP="$REPO_ROOT/.agents/tools/bootstrap-dependencies.sh"
WRAPPER="$REPO_ROOT/install-dependencies.sh"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

[ -x "$BOOTSTRAP" ] || {
  echo "Persistent dependency bootstrap is missing or not executable"
  exit 1
}

if grep -Eqi 'java|jdk|gradle' "$BOOTSTRAP" "$WRAPPER"; then
  echo "Dependency setup still contains the source repository Java/Gradle backend"
  exit 1
fi
grep -Eqi 'php.{0,20}8\.4|8\.4.{0,20}php' "$BOOTSTRAP"
grep -Eqi 'composer' "$BOOTSTRAP"

fake_bin="$TEST_ROOT/bin"
compatible_bin="$fake_bin"
mkdir -p "$fake_bin"

make_fake() {
  local name="$1"
  local body="$2"
  apply_target="$fake_bin/$name"
  printf '#!/usr/bin/env bash\n%s\n' "$body" > "$apply_target"
  chmod 755 "$apply_target"
}

make_fake node 'echo v22.11.0'
make_fake php 'if [ "${1:-}" = -r ]; then echo 80400; else echo "PHP 8.4.4"; fi'
make_fake composer 'echo "Composer version 2.8.8"'
make_fake docker 'if [ "${1:-}" = compose ]; then echo "Docker Compose version v2.29.2"; else echo "Docker version 27.2.0"; fi'

before="$(find "$TEST_ROOT" -mindepth 1 -printf '%P %s\n' | sort)"
output="$(PATH="$fake_bin:$PATH" "$BOOTSTRAP" --components frontend)"
after="$(find "$TEST_ROOT" -mindepth 1 -printf '%P %s\n' | sort)"
[ "$before" = "$after" ]
grep -Eqi 'plan|no changes' <<< "$output"
grep -Eqi 'frontend.*compatible|node.*22' <<< "$output"

plan_output="$(PATH="$fake_bin:$PATH" "$BOOTSTRAP" --plan --components backend)"
grep -Eqi 'PHP 8\.4.*compatible' <<< "$plan_output"
grep -Eqi 'Composer.*available' <<< "$plan_output"
if grep -Eqi 'node|docker' <<< "$plan_output"; then
  echo "Backend-only planning probed or reported an unselected component"
  exit 1
fi

all_output="$(PATH="$fake_bin:$PATH" "$BOOTSTRAP" --plan --all)"
grep -Eqi 'frontend' <<< "$all_output"
grep -Eqi 'backend' <<< "$all_output"
grep -Eqi 'docker' <<< "$all_output"

mutating_bin="$TEST_ROOT/mutating-bin"
mutation_log="$TEST_ROOT/mutation.log"
node_state="$TEST_ROOT/node-installed"
mkdir -p "$mutating_bin"
fake_bin="$mutating_bin"
export AGENTS_ECOSYSTEM_TEST_MUTATION_LOG="$mutation_log"
export AGENTS_ECOSYSTEM_TEST_NODE_STATE="$node_state"
make_fake node 'if [ -f "$AGENTS_ECOSYSTEM_TEST_NODE_STATE" ]; then echo v22.12.0; else echo v18.20.0; fi'
make_fake apt-cache 'if [ "${1:-}" = policy ]; then echo "  Candidate: 22.12.0-1"; else exit 0; fi'
make_fake id 'echo 1000'
make_fake sudo 'exec "$@"'
make_fake apt-get 'echo "$*" >> "$AGENTS_ECOSYSTEM_TEST_MUTATION_LOG"; if [[ " $* " == *" install "* ]]; then touch "$AGENTS_ECOSYSTEM_TEST_NODE_STATE"; fi'

apply_output="$(
  PATH="$mutating_bin:$PATH" \
  AGENTS_ECOSYSTEM_TEST_UNPRIVILEGED_APT=1 \
  AGENTS_ECOSYSTEM_TEST_APT_GET="$mutating_bin/apt-get" \
  AGENTS_ECOSYSTEM_TEST_APT_CACHE="$mutating_bin/apt-cache" \
    "$BOOTSTRAP" --components frontend --yes
)"
grep -q '^update$' "$mutation_log"
grep -q '^install -y nodejs$' "$mutation_log"
grep -q 'completed and verified' <<< "$apply_output"
if grep -Eqi 'php|composer|docker' "$mutation_log"; then
  echo "Frontend installation mutated an unselected component"
  exit 1
fi

mutation_lines="$(wc -l < "$mutation_log")"
rerun_output="$(
  PATH="$mutating_bin:$PATH" \
  AGENTS_ECOSYSTEM_TEST_UNPRIVILEGED_APT=1 \
  AGENTS_ECOSYSTEM_TEST_APT_GET="$mutating_bin/apt-get" \
  AGENTS_ECOSYSTEM_TEST_APT_CACHE="$mutating_bin/apt-cache" \
    "$BOOTSTRAP" --components frontend --yes
)"
[ "$(wc -l < "$mutation_log")" -eq "$mutation_lines" ]
grep -Eqi 'compatible.*no change|no changes made' <<< "$rerun_output"

partial_bin="$TEST_ROOT/partial-bin"
partial_log="$TEST_ROOT/partial.log"
mkdir -p "$partial_bin"
fake_bin="$partial_bin"
export AGENTS_ECOSYSTEM_TEST_MUTATION_LOG="$partial_log"
make_fake node 'echo v18.20.0'
make_fake apt-cache 'if [ "${1:-}" = policy ]; then echo "  Candidate: 22.12.0-1"; else exit 0; fi'
make_fake id 'echo 1000'
make_fake sudo 'exec "$@"'
make_fake apt-get 'echo "$*" >> "$AGENTS_ECOSYSTEM_TEST_MUTATION_LOG"; if [[ " $* " == *" install "* ]]; then exit 17; fi'

if partial_output="$(
  PATH="$partial_bin:$PATH" \
  AGENTS_ECOSYSTEM_TEST_UNPRIVILEGED_APT=1 \
  AGENTS_ECOSYSTEM_TEST_APT_GET="$partial_bin/apt-get" \
  AGENTS_ECOSYSTEM_TEST_APT_CACHE="$partial_bin/apt-cache" \
    "$BOOTSTRAP" --components frontend --yes 2>&1
)"; then
  echo "Bootstrap concealed a partial package failure"
  exit 1
fi
grep -q '^update$' "$partial_log"
grep -q '^install -y nodejs$' "$partial_log"
grep -Eqi 'Incomplete steps:.*package installation' <<< "$partial_output"
grep -Eqi 'no rollback is claimed' <<< "$partial_output"

hostile_privilege_bin="$TEST_ROOT/hostile-privilege-bin"
hostile_privilege_log="$TEST_ROOT/hostile-privilege.log"
mkdir -p "$hostile_privilege_bin"
fake_bin="$hostile_privilege_bin"
export AGENTS_ECOSYSTEM_TEST_MUTATION_LOG="$hostile_privilege_log"
make_fake node 'echo v18.20.0'
make_fake apt-cache 'if [ "${1:-}" = policy ]; then echo "  Candidate: 22.12.0-1"; else exit 0; fi'
make_fake apt-get 'echo "apt-get $*" >> "$AGENTS_ECOSYSTEM_TEST_MUTATION_LOG"'
make_fake sudo 'echo "sudo $*" >> "$AGENTS_ECOSYSTEM_TEST_MUTATION_LOG"; exec "$@"'
if hostile_privilege_output="$(PATH="$hostile_privilege_bin:$PATH" \
  "$BOOTSTRAP" --components frontend --yes 2>&1)"; then
  echo "Bootstrap accepted PATH-substituted privileged package tools"
  exit 1
fi
[ ! -e "$hostile_privilege_log" ]
grep -Eqi 'trusted|unsafe|physical|package-manager executable' \
  <<< "$hostile_privilege_output"

apt_config_bin="$TEST_ROOT/apt-config-bin"
apt_config_marker="$TEST_ROOT/apt-config-visible.log"
apt_config_file="$TEST_ROOT/hostile-apt.conf"
apt_config_node_state="$TEST_ROOT/apt-config-node-installed"
mkdir -p "$apt_config_bin"
printf '%s\n' 'APT::Update::Pre-Invoke { "touch /tmp/should-not-run"; };' \
  > "$apt_config_file"
fake_bin="$apt_config_bin"
export AGENTS_ECOSYSTEM_TEST_APT_CONFIG_MARKER="$apt_config_marker"
export AGENTS_ECOSYSTEM_TEST_NODE_STATE="$apt_config_node_state"
make_fake node 'if [ -f "$AGENTS_ECOSYSTEM_TEST_NODE_STATE" ]; then echo v22.12.0; else echo v18.20.0; fi'
make_fake apt-cache '
[ -z "${APT_CONFIG:-}" ] || printf "apt-cache:%s\n" "$APT_CONFIG" >> "$AGENTS_ECOSYSTEM_TEST_APT_CONFIG_MARKER"
if [ "${1:-}" = policy ]; then echo "  Candidate: 22.12.0-1"; fi'
make_fake apt-get '
[ -z "${APT_CONFIG:-}" ] || printf "apt-get:%s\n" "$APT_CONFIG" >> "$AGENTS_ECOSYSTEM_TEST_APT_CONFIG_MARKER"
if [[ " $* " == *" install "* ]]; then touch "$AGENTS_ECOSYSTEM_TEST_NODE_STATE"; fi'
APT_CONFIG="$apt_config_file" \
  PATH="$apt_config_bin:$PATH" \
  AGENTS_ECOSYSTEM_TEST_UNPRIVILEGED_APT=1 \
  AGENTS_ECOSYSTEM_TEST_APT_GET="$apt_config_bin/apt-get" \
  AGENTS_ECOSYSTEM_TEST_APT_CACHE="$apt_config_bin/apt-cache" \
  "$BOOTSTRAP" --components frontend --yes >/dev/null
if [ -e "$apt_config_marker" ]; then
  echo "Dependency bootstrap exposed ambient APT_CONFIG to apt" >&2
  exit 1
fi

windows_bin="$TEST_ROOT/windows-bin"
mkdir -p "$windows_bin"
fake_bin="$windows_bin"
make_fake uname 'echo MINGW64_NT-10.0'
make_fake node 'echo v18.20.0'
windows_output="$(PATH="$windows_bin:$PATH" "$BOOTSTRAP" --plan --components frontend)"
grep -Eqi 'Native Windows|WSL2' <<< "$windows_output"
grep -Eqi 'No changes made' <<< "$windows_output"

privilege_bin="$TEST_ROOT/privilege-bin"
privilege_log="$TEST_ROOT/privilege.log"
mkdir -p "$privilege_bin"
for command_path in /usr/bin/bash /usr/bin/env /usr/bin/awk /usr/bin/sed /usr/bin/head /usr/bin/uname; do
  [ -x "$command_path" ] && ln -s "$command_path" "$privilege_bin/$(basename "$command_path")"
done
fake_bin="$privilege_bin"
export AGENTS_ECOSYSTEM_TEST_MUTATION_LOG="$privilege_log"
make_fake node 'echo v18.20.0'
make_fake apt-cache 'if [ "${1:-}" = policy ]; then echo "  Candidate: 22.12.0-1"; else exit 0; fi'
make_fake apt-get 'echo "$*" >> "$AGENTS_ECOSYSTEM_TEST_MUTATION_LOG"'
make_fake id 'echo 1000'

if privilege_output="$(PATH="$privilege_bin" "$BOOTSTRAP" --components frontend --yes 2>&1)"; then
  echo "Bootstrap accepted a mutating apt plan without root or sudo"
  exit 1
fi
[ ! -e "$privilege_log" ]
grep -Eqi 'trusted|physical|package-manager executable' <<< "$privilege_output"

if "$BOOTSTRAP" --components unknown >/dev/null 2>&1; then
  echo "Bootstrap accepted an unknown component"
  exit 1
fi

invalid_project="$TEST_ROOT/invalid-project"
mkdir -p "$invalid_project"
if (
  cd "$invalid_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --deps unknown --from-local "$REPO_ROOT" >/dev/null 2>&1
); then
  echo "Installer accepted an unknown dependency selection"
  exit 1
fi
[ -z "$(find "$invalid_project" -mindepth 1 -print -quit)" ]

brew_bin="$TEST_ROOT/brew-bin"
brew_log="$TEST_ROOT/brew.log"
node_formula_state="$TEST_ROOT/node-formula-installed"
php_formula_state="$TEST_ROOT/php-formula-installed"
composer_formula_state="$TEST_ROOT/composer-formula-installed"
node_formula_prefix="$TEST_ROOT/homebrew/node@22"
php_formula_prefix="$TEST_ROOT/homebrew/php@8.4"
composer_formula_prefix="$TEST_ROOT/homebrew/composer"
mkdir -p "$brew_bin" "$node_formula_prefix/bin" "$php_formula_prefix/bin" "$composer_formula_prefix/bin"
fake_bin="$brew_bin"
export AGENTS_ECOSYSTEM_TEST_BREW_LOG="$brew_log"
export AGENTS_ECOSYSTEM_TEST_NODE_FORMULA_STATE="$node_formula_state"
export AGENTS_ECOSYSTEM_TEST_PHP_FORMULA_STATE="$php_formula_state"
export AGENTS_ECOSYSTEM_TEST_COMPOSER_FORMULA_STATE="$composer_formula_state"
export AGENTS_ECOSYSTEM_TEST_NODE_FORMULA_PREFIX="$node_formula_prefix"
export AGENTS_ECOSYSTEM_TEST_PHP_FORMULA_PREFIX="$php_formula_prefix"
export AGENTS_ECOSYSTEM_TEST_COMPOSER_FORMULA_PREFIX="$composer_formula_prefix"
make_fake uname 'echo Darwin'
make_fake node 'echo v18.20.0'
make_fake php 'if [ "${1:-}" = -r ]; then echo 80300; else echo "PHP 8.3"; fi'
make_fake composer 'exit 1'
make_fake brew '
case "${1:-}" in
  list)
    formula="${3:-}"
    case "$formula" in
      node@22) state="$AGENTS_ECOSYSTEM_TEST_NODE_FORMULA_STATE" ;;
      php@8.4) state="$AGENTS_ECOSYSTEM_TEST_PHP_FORMULA_STATE" ;;
      composer) state="$AGENTS_ECOSYSTEM_TEST_COMPOSER_FORMULA_STATE" ;;
      *) exit 1 ;;
    esac
    [ -f "$state" ] || exit 1
    printf "%s 1.0\n" "$formula"
    ;;
  --prefix)
    case "${2:-}" in
      node@22) printf "%s\n" "$AGENTS_ECOSYSTEM_TEST_NODE_FORMULA_PREFIX" ;;
      php@8.4) printf "%s\n" "$AGENTS_ECOSYSTEM_TEST_PHP_FORMULA_PREFIX" ;;
      composer) printf "%s\n" "$AGENTS_ECOSYSTEM_TEST_COMPOSER_FORMULA_PREFIX" ;;
      *) exit 1 ;;
    esac
    ;;
  install)
    formula="${2:-}"
    printf "install %s\n" "$formula" >> "$AGENTS_ECOSYSTEM_TEST_BREW_LOG"
    case "$formula" in
      node@22) touch "$AGENTS_ECOSYSTEM_TEST_NODE_FORMULA_STATE" ;;
      php@8.4) touch "$AGENTS_ECOSYSTEM_TEST_PHP_FORMULA_STATE" ;;
      composer) touch "$AGENTS_ECOSYSTEM_TEST_COMPOSER_FORMULA_STATE" ;;
      *) exit 1 ;;
    esac
    ;;
  *) exit 1 ;;
esac'
printf '#!/usr/bin/env bash\necho v22.12.0\n' > "$node_formula_prefix/bin/node"
printf '#!/usr/bin/env bash\nif [ "${1:-}" = -r ]; then echo 80400; else echo "PHP 8.4.5"; fi\n' \
  > "$php_formula_prefix/bin/php"
printf '#!/usr/bin/env bash\necho "Composer version 2.8.8"\n' \
  > "$composer_formula_prefix/bin/composer"
chmod +x "$node_formula_prefix/bin/node" "$php_formula_prefix/bin/php" \
  "$composer_formula_prefix/bin/composer"

brew_frontend_output="$(PATH="$brew_bin:$PATH" "$BOOTSTRAP" --components frontend --yes)"
grep -q '^install node@22$' "$brew_log"
grep -q 'completed and verified' <<< "$brew_frontend_output"
brew_lines="$(wc -l < "$brew_log")"
brew_frontend_rerun="$(PATH="$brew_bin:$PATH" "$BOOTSTRAP" --components frontend --yes)"
[ "$(wc -l < "$brew_log")" -eq "$brew_lines" ]
grep -Eqi 'compatible.*no change|no changes made' <<< "$brew_frontend_rerun"

brew_backend_output="$(PATH="$brew_bin:$PATH" "$BOOTSTRAP" --components backend --yes)"
grep -q '^install php@8.4$' "$brew_log"
grep -q '^install composer$' "$brew_log"
grep -q 'completed and verified' <<< "$brew_backend_output"
brew_lines="$(wc -l < "$brew_log")"
brew_backend_rerun="$(PATH="$brew_bin:$PATH" "$BOOTSTRAP" --components backend --yes)"
[ "$(wc -l < "$brew_log")" -eq "$brew_lines" ]
grep -Eqi 'compatible.*no change|no changes made' <<< "$brew_backend_rerun"

if grep -En 'curl[^|]*\|[[:space:]]*(ba)?sh|wget[^|]*\|[[:space:]]*(ba)?sh' \
  "$BOOTSTRAP" "$WRAPPER"; then
  echo "Dependency setup executes a network response as shell code"
  exit 1
fi
if grep -En 'usermod|groupadd|nvm alias|sdk default' "$BOOTSTRAP" "$WRAPPER"; then
  echo "Dependency setup changes privileges or global runtime defaults"
  exit 1
fi

wrapper_output="$(PATH="$fake_bin:$PATH" "$WRAPPER" --plan --components frontend)"
grep -Eqi 'frontend.*compatible|node.*22' <<< "$wrapper_output"

project="$TEST_ROOT/project"
mkdir -p "$project"
(
  cd "$project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --skip-deps --from-local "$REPO_ROOT" >/dev/null
)
cmp -s "$BOOTSTRAP" "$project/.agents/tools/bootstrap-dependencies.sh"
[ ! -e "$project/install-dependencies.sh" ]

deps_project="$TEST_ROOT/deps-project"
mkdir -p "$deps_project"
deps_output="$(
  cd "$deps_project"
  HOME="$TEST_ROOT/home" PATH="$compatible_bin:$PATH" bash "$REPO_ROOT/install.sh" \
    --deps frontend --from-local "$REPO_ROOT"
)"
grep -Eqi 'Preparing explicit dependency setup for: frontend' <<< "$deps_output"
grep -Eqi 'Node v22.*compatible|All selected components are compatible' <<< "$deps_output"
cmp -s "$BOOTSTRAP" "$deps_project/.agents/tools/bootstrap-dependencies.sh"

conflict_project="$TEST_ROOT/conflict-project"
mkdir -p "$conflict_project"
if (
  cd "$conflict_project"
  HOME="$TEST_ROOT/home" bash "$REPO_ROOT/install.sh" \
    --skip-deps --deps frontend --from-local "$REPO_ROOT" >/dev/null 2>&1
); then
  echo "Installer accepted contradictory dependency flags"
  exit 1
fi
[ -z "$(find "$conflict_project" -mindepth 1 -print -quit)" ]

echo "Component-aware dependency bootstrap tests passed"
