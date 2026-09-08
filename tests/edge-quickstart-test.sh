#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
REAL_GIT="$(command -p -v git)"
CANONICAL_URL='https://github.com/marcus-friction/agents.git'

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fixture_git() {
  env \
    -u GIT_DIR \
    -u GIT_WORK_TREE \
    -u GIT_INDEX_FILE \
    -u GIT_OBJECT_DIRECTORY \
    -u GIT_ALTERNATE_OBJECT_DIRECTORIES \
    -u GIT_COMMON_DIR \
    -u GIT_CONFIG_COUNT \
    -u GIT_CONFIG_PARAMETERS \
    -u GIT_CONFIG_SYSTEM \
    -u GIT_CONFIG_GLOBAL \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
      "$REAL_GIT" "$@"
}

make_remote() {
  local name="$1"
  local result="$2"
  local source="$TEST_ROOT/$name-source"
  local remote="$TEST_ROOT/$name.git"

  mkdir -p "$source"
  cat > "$source/install.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' '$result' > "\$AGENTS_ECOSYSTEM_TEST_INSTALL_RESULT"
EOF
  chmod +x "$source/install.sh"
  fixture_git -C "$source" init -q
  fixture_git -C "$source" \
    -c user.name='Edge Quickstart Test' \
    -c user.email='edge-quickstart@example.invalid' \
    add install.sh
  fixture_git -C "$source" \
    -c user.name='Edge Quickstart Test' \
    -c user.email='edge-quickstart@example.invalid' \
    commit -qm "$name fixture"
  fixture_git clone -q --bare "$source" "$remote"
  printf '%s\n' "$remote"
}

canonical_remote="$(make_remote canonical canonical)"
evil_remote="$(make_remote evil evil)"
hostile_hooks="$TEST_ROOT/hostile-hooks"
hostile_config="$TEST_ROOT/hostile-gitconfig"
mkdir -p "$hostile_hooks" "$TEST_ROOT/bin"
cat > "$hostile_hooks/post-checkout" <<'EOF'
#!/usr/bin/env bash
printf 'executed\n' > "$AGENTS_ECOSYSTEM_TEST_HOOK_MARKER"
EOF
chmod +x "$hostile_hooks/post-checkout"
fixture_git config --file "$hostile_config" \
  "url.file://$evil_remote.insteadOf" "file://$canonical_remote"
fixture_git config --file "$hostile_config" core.hooksPath "$hostile_hooks"

cat > "$TEST_ROOT/bin/git" <<'EOF'
#!/usr/bin/env bash
arguments=()
for argument in "$@"; do
  if [ "$argument" = "$AGENTS_ECOSYSTEM_TEST_CANONICAL_URL" ]; then
    arguments+=("file://$AGENTS_ECOSYSTEM_TEST_CANONICAL_REMOTE")
  else
    arguments+=("$argument")
  fi
done
exec "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" "${arguments[@]}"
EOF
chmod +x "$TEST_ROOT/bin/git"

extract_quickstart() {
  local document="$1"
  local output="$2"

  python3 - "$document" "$output" <<'PY'
from pathlib import Path
import re
import sys

document = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r"(?ms)^### (?:Edge channel|Install in one project)\n.*?^```bash\n(.*?)^```$",
    document,
)
if match is None:
    raise SystemExit(f"edge quickstart not found in {sys.argv[1]}")
Path(sys.argv[2]).write_text(match.group(1), encoding="utf-8")
PY
}

failures=0
for document in README.md docs/ecosystem-reference.md; do
  label="${document//\//-}"
  quickstart="$TEST_ROOT/$label.sh"
  project="$TEST_ROOT/$label-project"
  install_result="$TEST_ROOT/$label-install-result"
  hook_marker="$TEST_ROOT/$label-hook-marker"
  output="$TEST_ROOT/$label.out"
  mkdir -p "$project"

  if ! extract_quickstart "$REPO_ROOT/$document" "$quickstart"; then
    echo "not ok - $document exposes an executable edge quickstart"
    failures=$((failures + 1))
    continue
  fi

  if ! (
    cd "$project"
    PATH="$TEST_ROOT/bin:$PATH" \
    GIT_CONFIG_GLOBAL="$hostile_config" \
    GIT_CONFIG_NOSYSTEM=1 \
    GIT_ALLOW_PROTOCOL=file \
    AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
    AGENTS_ECOSYSTEM_TEST_CANONICAL_URL="$CANONICAL_URL" \
    AGENTS_ECOSYSTEM_TEST_CANONICAL_REMOTE="$canonical_remote" \
    AGENTS_ECOSYSTEM_TEST_INSTALL_RESULT="$install_result" \
    AGENTS_ECOSYSTEM_TEST_HOOK_MARKER="$hook_marker" \
      bash "$quickstart" > "$output" 2>&1
  ); then
    cat "$output"
    echo "not ok - $document edge quickstart executes successfully"
    failures=$((failures + 1))
    continue
  fi

  if ! grep -qx 'canonical' "$install_result" 2>/dev/null; then
    echo "not ok - $document edge quickstart ignores hostile URL rewrites"
    failures=$((failures + 1))
  elif [ -e "$hook_marker" ]; then
    echo "not ok - $document edge quickstart disables ambient Git hooks"
    failures=$((failures + 1))
  else
    echo "ok - $document edge quickstart isolates Git acquisition"
  fi
done

if [ "$failures" -ne 0 ]; then
  exit 1
fi

echo "All edge quickstart tests passed"
