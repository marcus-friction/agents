#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
REAL_GIT="$(command -v git)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

copy_distribution() {
  local destination="$1"
  mkdir -p "$destination"
  cp -R "$REPO_ROOT/.agents" "$destination/.agents"
  cp -R "$REPO_ROOT/project-templates" "$destination/project-templates"
  cp -R "$REPO_ROOT/scripts" "$destination/scripts"
  cp "$REPO_ROOT/install.sh" "$destination/install.sh"
  git -C "$destination" init -q -b master
  git -C "$destination" config user.name "Installer Ref Test"
  git -C "$destination" config user.email "installer-ref@example.invalid"
  git -C "$destination" add .
  git -C "$destination" commit -qm "release fixture A"
}

assert_empty_project() {
  local project="$1"
  [ -z "$(find "$project" -mindepth 1 -print -quit)" ] || {
    echo "installer mutated a project before verifying its source ref" >&2
    return 1
  }
}

source_checkout="$TEST_ROOT/source"
copy_distribution "$source_checkout"
release_a="$(git -C "$source_checkout" rev-parse HEAD)"

invalid_project="$TEST_ROOT/invalid-project"
mkdir -p "$invalid_project"
if (
  cd "$invalid_project"
  bash "$REPO_ROOT/install.sh" --from-local "$source_checkout" --ref master
) >"$TEST_ROOT/invalid.out" 2>&1; then
  echo "installer accepted a mutable release ref" >&2
  exit 1
fi
grep -Fq 'full 40-character lowercase commit SHA' "$TEST_ROOT/invalid.out"
assert_empty_project "$invalid_project"

attached_project="$TEST_ROOT/attached-project"
mkdir -p "$attached_project"
if (
  cd "$attached_project"
  bash "$REPO_ROOT/install.sh" --from-local "$source_checkout" --ref "$release_a"
) >"$TEST_ROOT/attached.out" 2>&1; then
  echo "installer accepted an attached release checkout" >&2
  exit 1
fi
grep -Fq 'detached HEAD' "$TEST_ROOT/attached.out"
assert_empty_project "$attached_project"

git -C "$source_checkout" checkout -q --detach "$release_a"

legal_collision_project="$TEST_ROOT/legal-collision-project"
mkdir -p "$legal_collision_project/.agents/legal"
printf 'project-owned legal text\n' \
  > "$legal_collision_project/.agents/legal/LICENSE"
if (
  cd "$legal_collision_project"
  bash "$REPO_ROOT/install.sh" \
    --from-local "$source_checkout" --ref "$release_a"
) >"$TEST_ROOT/legal-collision.out" 2>&1; then
  echo "installer overwrote an unowned first-adoption legal payload" >&2
  exit 1
fi
grep -Eqi 'collision|collides' "$TEST_ROOT/legal-collision.out"
grep -qx 'project-owned legal text' \
  "$legal_collision_project/.agents/legal/LICENSE"
[ ! -e "$legal_collision_project/.agents/skills" ]

legal_race_project="$TEST_ROOT/legal-race-project"
legal_race_bin="$TEST_ROOT/legal-race-bin"
legal_race_once="$TEST_ROOT/legal-race-fired"
real_bash="$(command -v bash)"
mkdir -p "$legal_race_project" "$legal_race_bin"
cat > "$legal_race_bin/bash" <<'WRAPPER'
#!/bin/bash
set -euo pipefail
is_mutating_sync=0
case "${1:-}" in
  */scripts/sync-managed-tree.sh)
    is_mutating_sync=1
    for argument in "$@"; do
      [ "$argument" = --check ] && is_mutating_sync=0
    done
    ;;
esac
if [ "$is_mutating_sync" -eq 1 ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_RACE_ONCE" ]; then
  mkdir -p "$AGENTS_ECOSYSTEM_TEST_PROJECT/.agents/legal"
  printf 'raced project-owned legal text\n' \
    > "$AGENTS_ECOSYSTEM_TEST_PROJECT/.agents/legal/LICENSE"
  : > "$AGENTS_ECOSYSTEM_TEST_RACE_ONCE"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_BASH" "$@"
WRAPPER
chmod +x "$legal_race_bin/bash"
if (
  cd "$legal_race_project"
  PATH="$legal_race_bin:$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_BASH="$real_bash" \
  AGENTS_ECOSYSTEM_TEST_PROJECT="$legal_race_project" \
  AGENTS_ECOSYSTEM_TEST_RACE_ONCE="$legal_race_once" \
    bash "$REPO_ROOT/install.sh" \
      --from-local "$source_checkout" --ref "$release_a"
) >"$TEST_ROOT/legal-race.out" 2>&1; then
  echo "installer accepted an unmanaged legal collision introduced during staging" >&2
  exit 1
fi
grep -Eqi 'collision|collides' "$TEST_ROOT/legal-race.out"
grep -qx 'raced project-owned legal text' \
  "$legal_race_project/.agents/legal/LICENSE"
[ ! -e "$legal_race_project/.agents/skills" ]

dirty_project="$TEST_ROOT/dirty-project"
mkdir -p "$dirty_project"
printf '\ndirty release source\n' >> "$source_checkout/scripts/sync-managed-tree.sh"
if (
  cd "$dirty_project"
  bash "$REPO_ROOT/install.sh" --from-local "$source_checkout" --ref "$release_a"
) >"$TEST_ROOT/dirty.out" 2>&1; then
  echo "installer accepted a dirty release checkout" >&2
  exit 1
fi
grep -Fq 'immutable source must be clean' "$TEST_ROOT/dirty.out"
assert_empty_project "$dirty_project"
git -C "$source_checkout" restore scripts/sync-managed-tree.sh

hidden_index_project="$TEST_ROOT/hidden-index-project"
mkdir -p "$hidden_index_project"
git -C "$source_checkout" update-index --assume-unchanged install.sh
printf '\nhidden local installer change\n' >> "$source_checkout/install.sh"
if (
  cd "$hidden_index_project"
  bash "$REPO_ROOT/install.sh" \
    --from-local "$source_checkout" --ref "$release_a"
) >"$TEST_ROOT/hidden-index.out" 2>&1; then
  echo "installer accepted hidden immutable-source index state" >&2
  exit 1
fi
grep -Fq 'immutable source has hidden index state' \
  "$TEST_ROOT/hidden-index.out"
assert_empty_project "$hidden_index_project"
git -C "$source_checkout" update-index --no-assume-unchanged install.sh
git -C "$source_checkout" restore install.sh

mismatch_project="$TEST_ROOT/mismatch-project"
mkdir -p "$mismatch_project"
mismatch="0000000000000000000000000000000000000000"
if (
  cd "$mismatch_project"
  bash "$REPO_ROOT/install.sh" --from-local "$source_checkout" --ref "$mismatch"
) >"$TEST_ROOT/mismatch.out" 2>&1; then
  echo "installer accepted a mismatched release checkout" >&2
  exit 1
fi
grep -Fq 'does not match expected release commit' "$TEST_ROOT/mismatch.out"
assert_empty_project "$mismatch_project"

local_project="$TEST_ROOT/local-project"
tar_bin="$TEST_ROOT/tar-bin"
tar_marker="$TEST_ROOT/tar-options-visible"
real_tar="$(command -v tar)"
mkdir -p "$local_project"
mkdir -p "$tar_bin"
cat > "$tar_bin/tar" <<'WRAPPER'
#!/bin/bash
if [ -n "${TAR_OPTIONS+x}" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_TAR_MARKER"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_TAR" "$@"
WRAPPER
chmod +x "$tar_bin/tar"
cat > "$tar_bin/gh" <<'WRAPPER'
#!/bin/bash
printf 'invoked\n' > "$AGENTS_ECOSYSTEM_TEST_GH_MARKER"
exit 95
WRAPPER
chmod +x "$tar_bin/gh"
local_gh_marker="$TEST_ROOT/local-gh-invoked"
(
  cd "$local_project"
  PATH="$tar_bin:$PATH" \
  TAR_OPTIONS='hostile ambient tar options' \
  AGENTS_ECOSYSTEM_TEST_GH_MARKER="$local_gh_marker" \
  AGENTS_ECOSYSTEM_TEST_REAL_TAR="$real_tar" \
  AGENTS_ECOSYSTEM_TEST_TAR_MARKER="$tar_marker" \
  bash "$REPO_ROOT/install.sh" \
    --from-local "$source_checkout" \
    --ref "$release_a"
) >"$TEST_ROOT/local.out"
[ ! -e "$tar_marker" ]
[ ! -e "$local_gh_marker" ]
grep -Fq "Verified immutable source at $release_a" "$TEST_ROOT/local.out"
test -f "$local_project/.agents/skills/start-project/SKILL.md"
cmp -s "$REPO_ROOT/LICENSE" "$local_project/.agents/legal/LICENSE"
cmp -s "$REPO_ROOT/THIRD_PARTY_NOTICES.md" \
  "$local_project/.agents/legal/THIRD_PARTY_NOTICES.md"

race_project="$TEST_ROOT/race-project"
race_bin="$TEST_ROOT/race-bin"
race_marker="$TEST_ROOT/shared-source-code-ran"
race_once="$TEST_ROOT/race-fired"
evil_sync="$TEST_ROOT/evil-sync-managed-tree.sh"
mkdir -p "$race_project" "$race_bin"
cat > "$evil_sync" <<EOF
#!/usr/bin/env bash
printf 'executed\n' > "$race_marker"
exit 99
EOF
chmod +x "$evil_sync"
cat > "$race_bin/git" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
args=("$@")
is_source_status=0
for index in "${!args[@]}"; do
  if [ "${args[$index]}" = "-C" ] \
    && [ "${args[$((index + 1))]:-}" = "$AGENTS_ECOSYSTEM_TEST_SOURCE" ]; then
    for argument in "${args[@]}"; do
      if [ "$argument" = status ]; then
        is_source_status=1
      fi
    done
  fi
done
if [ "$is_source_status" -eq 1 ] && [ ! -e "$AGENTS_ECOSYSTEM_TEST_RACE_ONCE" ]; then
  output="$("$AGENTS_ECOSYSTEM_TEST_REAL_GIT" "${args[@]}")"
  status=$?
  cp "$AGENTS_ECOSYSTEM_TEST_EVIL_SYNC" \
    "$AGENTS_ECOSYSTEM_TEST_SOURCE/scripts/sync-managed-tree.sh"
  : > "$AGENTS_ECOSYSTEM_TEST_RACE_ONCE"
  printf '%s' "$output"
  exit "$status"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" "${args[@]}"
WRAPPER
chmod +x "$race_bin/git"
if ! (
  cd "$race_project"
  PATH="$race_bin:$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$source_checkout" \
  AGENTS_ECOSYSTEM_TEST_EVIL_SYNC="$evil_sync" \
  AGENTS_ECOSYSTEM_TEST_RACE_ONCE="$race_once" \
    bash "$REPO_ROOT/install.sh" \
      --from-local "$source_checkout" --ref "$release_a"
) >"$TEST_ROOT/race.out" 2>&1; then
  if [ -e "$race_marker" ]; then
    echo "installer executed a concurrently replaced shared-source script" >&2
  else
    cat "$TEST_ROOT/race.out" >&2
  fi
  exit 1
fi
[ ! -e "$race_marker" ]
test -f "$race_project/.agents/skills/start-project/SKILL.md"
git -C "$source_checkout" restore scripts/sync-managed-tree.sh

git -C "$source_checkout" switch -q master
printf '\nrelease B only\n' >> "$source_checkout/.agents/skills/start-project/SKILL.md"
git -C "$source_checkout" add .agents/skills/start-project/SKILL.md
git -C "$source_checkout" commit -qm "release fixture B"

git_wrapper="$TEST_ROOT/bin/git"
mkdir -p "$(dirname "$git_wrapper")"
cat > "$git_wrapper" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
args=("$@")
credential_reset=0
for index in "${!args[@]}"; do
  if [ "${args[$index]}" = "-c" ]; then
    case "${args[$((index + 1))]:-}" in
      credential.helper=)
        credential_reset=1
        ;;
    esac
  fi
  if [ "${args[$index]}" = "https://github.com/marcus-friction/agents.git" ]; then
    if [ "$credential_reset" -ne 1 ]; then
      echo "public GitHub fetch lacks the credential reset" >&2
      exit 97
    fi
    if [ "${GIT_ASKPASS:-}" != /usr/bin/false ] \
      || [ "${SSH_ASKPASS:-}" != /usr/bin/false ] \
      || [ "${SSH_ASKPASS_REQUIRE:-}" != never ]; then
      echo "public GitHub fetch permits an ambient askpass fallback" >&2
      exit 96
    fi
    args[$index]="file://$AGENTS_ECOSYSTEM_TEST_SOURCE"
  fi
done
GIT_ALLOW_PROTOCOL=file exec "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" "${args[@]}"
WRAPPER
chmod +x "$git_wrapper"

remote_project="$TEST_ROOT/remote-project"
mkdir -p "$remote_project"
(
  cd "$remote_project"
  PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$source_checkout" \
    bash "$REPO_ROOT/install.sh" --ref "$release_a"
) >"$TEST_ROOT/remote.out" 2>&1

grep -Fq "Verified immutable source at $release_a" "$TEST_ROOT/remote.out"
if grep -Fq 'release B only' \
  "$remote_project/.agents/skills/start-project/SKILL.md"; then
  echo "installer followed the mutable branch instead of the approved commit" >&2
  exit 1
fi
test -f "$remote_project/.agents/legal/THIRD_PARTY_NOTICES.md"

echo "Immutable installer ref contract tests passed"
