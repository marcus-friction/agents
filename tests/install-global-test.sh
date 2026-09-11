#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

checkout="$TEST_ROOT/checkout"
user_home="$TEST_ROOT/home"
mkdir -p "$checkout/.agents/skills/example" "$user_home"
printf 'example\n' > "$checkout/.agents/skills/example/SKILL.md"

git -C "$checkout" init -q
git -C "$checkout" config user.name "Installer Test"
git -C "$checkout" config user.email "installer@example.invalid"
git -C "$checkout" add .agents/skills/example/SKILL.md
git -C "$checkout" commit -qm "test fixture"
git -C "$checkout" config --unset user.name
git -C "$checkout" config --unset user.email
printf 'project-owned untracked content\n' > "$checkout/local-notes.md"

if HOME="$user_home" \
  AGENTS_ECOSYSTEM_HOME="$checkout" \
    bash "$REPO_ROOT/install-global.sh" \
      >"$TEST_ROOT/dirty-local.out" 2>&1; then
  echo "global installer accepted a dirty local checkout" >&2
  exit 1
fi

grep -q 'dirty' "$TEST_ROOT/dirty-local.out"
grep -q 'project-owned untracked content' "$checkout/local-notes.md"
[ ! -e "$user_home/.agents/skills" ]
[ ! -e "$user_home/.cursor/skills" ]
[ ! -e "$user_home/.claude/skills" ]

dirty_exec_checkout="$TEST_ROOT/dirty-exec-checkout"
dirty_exec_home="$TEST_ROOT/dirty-exec-home"
dirty_exec_marker="$TEST_ROOT/dirty-exec-ran"
mkdir -p \
  "$dirty_exec_checkout/.agents/skills/example" \
  "$dirty_exec_checkout/scripts" \
  "$dirty_exec_home"
printf 'example\n' > "$dirty_exec_checkout/.agents/skills/example/SKILL.md"
cat > "$dirty_exec_checkout/scripts/register-skills.sh" <<EOF
#!/usr/bin/env bash
printf 'executed\n' > "$dirty_exec_marker"
EOF
git -C "$dirty_exec_checkout" init -q
git -C "$dirty_exec_checkout" config user.name "Dirty Registrar Test"
git -C "$dirty_exec_checkout" config user.email "dirty-registrar@example.invalid"
git -C "$dirty_exec_checkout" add .
git -C "$dirty_exec_checkout" commit -qm "untrusted checkout fixture"
git -C "$dirty_exec_checkout" config --unset user.name
git -C "$dirty_exec_checkout" config --unset user.email
printf 'dirty\n' > "$dirty_exec_checkout/local-dirty.txt"
if HOME="$dirty_exec_home" \
  AGENTS_ECOSYSTEM_HOME="$dirty_exec_checkout" \
    bash "$REPO_ROOT/install-global.sh" \
      >"$TEST_ROOT/dirty-exec.out" 2>&1; then
  echo "global installer executed or accepted a dirty checkout registrar" >&2
  exit 1
fi
if [ -e "$dirty_exec_marker" ]; then
  echo "global installer executed repository code from a dirty checkout" >&2
  exit 1
fi
grep -Fq 'dirty' "$TEST_ROOT/dirty-exec.out"
[ ! -e "$dirty_exec_home/.agents/skills" ]

release_source="$TEST_ROOT/release-source"
mkdir -p \
  "$release_source/.agents/skills/example" \
  "$release_source/scripts"
printf 'release A\n' > "$release_source/.agents/skills/example/SKILL.md"
cp "$REPO_ROOT/scripts/register-skills.sh" "$release_source/scripts/register-skills.sh"
cp -R "$REPO_ROOT/scripts/skill-adapters" "$release_source/scripts/skill-adapters"
cat > "$release_source/scripts/skill-adapters/zz-partial-failure.sh" <<'EOF'
skill_adapter_supports_scope() {
  [ "$1" = "user" ] && [ "${AGENTS_ECOSYSTEM_TEST_PARTIAL_FAILURE:-0}" = "1" ]
}

skill_adapter_target() {
  printf '%s/.zz-partial/skills\n' "$HOME"
}

skill_adapter_link_source() {
  printf '%s\n' "$2"
}
EOF
git -C "$release_source" init -q -b master
git -C "$release_source" config user.name "Global Ref Test"
git -C "$release_source" config user.email "global-ref@example.invalid"
git -C "$release_source" add .
git -C "$release_source" commit -qm "release A"
release_a="$(git -C "$release_source" rev-parse HEAD)"
printf 'release B\n' > "$release_source/.agents/skills/example/SKILL.md"
printf 'filtered.txt filter=external\n' > "$release_source/.gitattributes"
printf 'release payload\n' > "$release_source/filtered.txt"
git -C "$release_source" add .agents/skills/example/SKILL.md
git -C "$release_source" add .gitattributes filtered.txt
git -C "$release_source" commit -qm "release B"
release_b="$(git -C "$release_source" rev-parse HEAD)"

real_git="$(command -v git)"
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
      echo "public GitHub fetch did not clear ambient credential helpers" >&2
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
if grep -Eq 'require_private_repository_auth|gh auth git-credential' \
  "$REPO_ROOT/install-global.sh"; then
  echo "public global installer still requires private GitHub authentication" >&2
  exit 1
fi

stable_home="$TEST_ROOT/stable-home"
stable_checkout="$TEST_ROOT/stable-checkout"
mkdir -p "$stable_home"

run_stable_global() {
  PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$stable_home" \
  AGENTS_ECOSYSTEM_HOME="$stable_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$1" >/dev/null
}

partial_home="$TEST_ROOT/partial-registration-home"
partial_checkout="$TEST_ROOT/partial-registration-checkout"
partial_bin="$TEST_ROOT/partial-registration-bin"
partial_first_link="$partial_home/.agents/skills"
partial_fail_parent="$partial_home/.zz-partial"
partial_saved_parent="$TEST_ROOT/partial-registration-saved-parent"
partial_external_parent="$TEST_ROOT/partial-registration-external-parent"
partial_swap_marker="$TEST_ROOT/partial-registration-swapped"
real_mkdir="$(command -p -v mkdir)"
real_mv="$(command -p -v mv)"
mkdir -p "$partial_home" "$partial_bin" "$partial_external_parent"
cat > "$partial_bin/mkdir" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
"$AGENTS_ECOSYSTEM_TEST_REAL_MKDIR" "$@"
if { [ "$*" = "-p $AGENTS_ECOSYSTEM_TEST_FAIL_PARENT" ] \
    || [ "$*" = "$AGENTS_ECOSYSTEM_TEST_FAIL_PARENT" ]; } \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SWAP_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SWAP_MARKER"
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" \
    "$AGENTS_ECOSYSTEM_TEST_FAIL_PARENT" \
    "$AGENTS_ECOSYSTEM_TEST_SAVED_PARENT"
  ln -s \
    "$AGENTS_ECOSYSTEM_TEST_EXTERNAL_PARENT" \
    "$AGENTS_ECOSYSTEM_TEST_FAIL_PARENT"
fi
WRAPPER
chmod +x "$partial_bin/mkdir"
if PATH="$partial_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$partial_home" \
  AGENTS_ECOSYSTEM_HOME="$partial_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_PARTIAL_FAILURE=1 \
  AGENTS_ECOSYSTEM_TEST_REAL_MKDIR="$real_mkdir" \
  AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
  AGENTS_ECOSYSTEM_TEST_FAIL_PARENT="$partial_fail_parent" \
  AGENTS_ECOSYSTEM_TEST_SAVED_PARENT="$partial_saved_parent" \
  AGENTS_ECOSYSTEM_TEST_EXTERNAL_PARENT="$partial_external_parent" \
  AGENTS_ECOSYSTEM_TEST_SWAP_MARKER="$partial_swap_marker" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_a" \
      >"$TEST_ROOT/partial-registration.out" 2>&1; then
  echo "global stable install ignored a registrar target-ancestor swap" >&2
  exit 1
fi
if [ ! -e "$partial_swap_marker" ]; then
  echo "partial registrar fixture did not trigger its late failure" >&2
  exit 1
fi
grep -q 'user adapter ancestor must not be a symlink' \
  "$TEST_ROOT/partial-registration.out"
if [ -e "$partial_checkout" ] || [ -L "$partial_checkout" ]; then
  echo "failed first stable install left its checkout active" >&2
  exit 1
fi
for adapter_link in \
  "$partial_first_link" \
  "$partial_home/.claude/skills" \
  "$partial_home/.cursor/skills"; do
  if [ -e "$adapter_link" ] || [ -L "$adapter_link" ]; then
    echo "failed first stable install left a broken user adapter link: $adapter_link" >&2
    exit 1
  fi
done
for adapter_parent in \
  "$partial_home/.agents" \
  "$partial_home/.claude" \
  "$partial_home/.cursor"; do
  if [ -e "$adapter_parent" ] || [ -L "$adapter_parent" ]; then
    echo "failed first stable install left an adapter directory: $adapter_parent" >&2
    exit 1
  fi
done

registration_signal_home="$TEST_ROOT/registration-signal-home"
registration_signal_checkout="$TEST_ROOT/registration-signal-checkout"
registration_signal_bin="$TEST_ROOT/registration-signal-bin"
registration_signal_link="$registration_signal_home/.agents/skills"
registration_signal_marker="$TEST_ROOT/registration-signal-fired"
registration_signal_real_ln="$(command -p -v ln)"
registration_signal_real_mv="$(command -p -v mv)"
mkdir -p "$registration_signal_home" "$registration_signal_bin"
cat > "$registration_signal_bin/ln" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
"$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER"
  kill -TERM "$PPID"
fi
WRAPPER
cat > "$registration_signal_bin/mv" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
target_path=""
after_options=0
for argument in "$@"; do
  if [ "$after_options" -eq 0 ]; then
    case "$argument" in
      --) after_options=1; continue ;;
      -*) continue ;;
    esac
  fi
  source_path="$target_path"
  target_path="$argument"
done
"$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER"
  kill -TERM "$PPID"
fi
WRAPPER
chmod +x "$registration_signal_bin/ln" "$registration_signal_bin/mv"
if PATH="$registration_signal_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$registration_signal_home" \
  AGENTS_ECOSYSTEM_HOME="$registration_signal_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_REAL_LN="$registration_signal_real_ln" \
  AGENTS_ECOSYSTEM_TEST_REAL_MV="$registration_signal_real_mv" \
  AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET="$registration_signal_link" \
  AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER="$registration_signal_marker" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_a" \
      >"$TEST_ROOT/registration-signal.out" 2>&1; then
  echo "global stable install ignored a signal during link activation" >&2
  exit 1
fi
if [ ! -e "$registration_signal_marker" ]; then
  echo "global registration signal fixture did not reach link activation" >&2
  exit 1
fi
if [ -e "$registration_signal_checkout" ] \
  || [ -L "$registration_signal_checkout" ]; then
  echo "signal-interrupted first stable install left its checkout active" >&2
  exit 1
fi
if [ -e "$registration_signal_link" ] || [ -L "$registration_signal_link" ]; then
  echo "signal-interrupted first stable install left a broken adapter link" >&2
  exit 1
fi

outer_signal_home="$TEST_ROOT/outer-registration-signal-home"
outer_signal_checkout="$TEST_ROOT/outer-registration-signal-checkout"
outer_signal_bin="$TEST_ROOT/outer-registration-signal-bin"
outer_signal_link="$outer_signal_home/.agents/skills"
outer_signal_marker="$TEST_ROOT/outer-registration-signal-fired"
outer_signal_real_bash="$(command -v bash)"
outer_signal_real_ln="$(command -p -v ln)"
mkdir -p "$outer_signal_home" "$outer_signal_bin"
cat > "$outer_signal_bin/bash" <<'WRAPPER'
#!/bin/bash
set -euo pipefail
if [ "${1:-}" = "$AGENTS_ECOSYSTEM_TEST_INSTALLER" ]; then
  export AGENTS_ECOSYSTEM_TEST_OUTER_PID="$$"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_BASH" "$@"
WRAPPER
cat > "$outer_signal_bin/ln" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
target_name="${!#}"
target_path="$PWD/$target_name"
if [ "${1:-}" = "-P" ] && [ -d "$target_name" ]; then
  target_path="$target_name/$(basename "${2:-}")"
fi
"$AGENTS_ECOSYSTEM_TEST_REAL_LN" "$@"
if [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER"
  kill -TERM "$AGENTS_ECOSYSTEM_TEST_OUTER_PID"
fi
WRAPPER
chmod +x "$outer_signal_bin/bash" "$outer_signal_bin/ln"
outer_signal_status=0
PATH="$outer_signal_bin:$(dirname "$git_wrapper"):$PATH" \
HOME="$outer_signal_home" \
AGENTS_ECOSYSTEM_HOME="$outer_signal_checkout" \
AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
AGENTS_ECOSYSTEM_TEST_INSTALLER="$REPO_ROOT/install-global.sh" \
AGENTS_ECOSYSTEM_TEST_REAL_BASH="$outer_signal_real_bash" \
AGENTS_ECOSYSTEM_TEST_REAL_LN="$outer_signal_real_ln" \
AGENTS_ECOSYSTEM_TEST_SIGNAL_TARGET="$outer_signal_link" \
AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER="$outer_signal_marker" \
  bash "$REPO_ROOT/install-global.sh" --ref "$release_a" \
    >"$TEST_ROOT/outer-registration-signal.out" 2>&1 \
    || outer_signal_status="$?"
if [ "$outer_signal_status" -ne 143 ]; then
  echo "outer registration signal returned $outer_signal_status instead of 143" >&2
  exit 1
fi
if [ ! -e "$outer_signal_marker" ]; then
  echo "outer registration signal fixture did not reach child link publication" >&2
  exit 1
fi
if [ ! -d "$outer_signal_checkout" ] || [ -L "$outer_signal_checkout" ]; then
  echo "outer signal removed the verified first stable checkout" >&2
  exit 1
fi
if [ "$(git -C "$outer_signal_checkout" rev-parse HEAD)" != "$release_a" ]; then
  echo "outer signal retained the wrong stable checkout revision" >&2
  exit 1
fi
for adapter_link in \
  "$outer_signal_link" \
  "$outer_signal_home/.claude/skills" \
  "$outer_signal_home/.cursor/skills"; do
  if [ ! -L "$adapter_link" ] \
    || [ "$(readlink "$adapter_link")" != "$outer_signal_checkout/.agents/skills" ] \
    || [ ! -d "$adapter_link" ]; then
    echo "outer signal left an invalid committed adapter link: $adapter_link" >&2
    exit 1
  fi
done

postvalidation_home="$TEST_ROOT/postvalidation-home"
postvalidation_checkout="$TEST_ROOT/postvalidation-checkout"
postvalidation_bin="$TEST_ROOT/postvalidation-bin"
postvalidation_marker="$TEST_ROOT/postvalidation-tampered"
postvalidation_real_bash="$(command -v bash)"
mkdir -p "$postvalidation_home" "$postvalidation_bin"
cat > "$postvalidation_bin/bash" <<'WRAPPER'
#!/bin/bash
set -euo pipefail
case "${1:-}" in
  *.release.*/trusted-scripts/register-skills.sh)
    "$AGENTS_ECOSYSTEM_TEST_REAL_BASH" "$@"
    printf 'post-registration tamper\n' \
      > "$AGENTS_ECOSYSTEM_TEST_DEST/post-registration-tamper.txt"
    : > "$AGENTS_ECOSYSTEM_TEST_TAMPER_MARKER"
    exit 0
    ;;
esac
exec "$AGENTS_ECOSYSTEM_TEST_REAL_BASH" "$@"
WRAPPER
chmod +x "$postvalidation_bin/bash"
if PATH="$postvalidation_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$postvalidation_home" \
  AGENTS_ECOSYSTEM_HOME="$postvalidation_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_REAL_BASH="$postvalidation_real_bash" \
  AGENTS_ECOSYSTEM_TEST_DEST="$postvalidation_checkout" \
  AGENTS_ECOSYSTEM_TEST_TAMPER_MARKER="$postvalidation_marker" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_a" \
      >"$TEST_ROOT/postvalidation.out" 2>&1; then
  echo "global stable install accepted post-registration checkout tampering" >&2
  exit 1
fi
if [ ! -e "$postvalidation_marker" ]; then
  echo "post-registration validation fixture did not run" >&2
  exit 1
fi
if [ ! -d "$postvalidation_checkout" ] || [ -L "$postvalidation_checkout" ]; then
  echo "post-registration validation failure removed the active checkout" >&2
  exit 1
fi
if [ ! -f "$postvalidation_checkout/post-registration-tamper.txt" ]; then
  echo "post-registration recovery checkout lost its validation evidence" >&2
  exit 1
fi
for adapter_link in \
  "$postvalidation_home/.agents/skills" \
  "$postvalidation_home/.claude/skills" \
  "$postvalidation_home/.cursor/skills"; do
  if [ ! -L "$adapter_link" ] \
    || [ "$(readlink "$adapter_link")" != "$postvalidation_checkout/.agents/skills" ] \
    || [ ! -d "$adapter_link" ]; then
    echo "post-registration recovery left an invalid adapter link: $adapter_link" >&2
    exit 1
  fi
done
grep -Fq 'retained the active checkout because user registration had committed' \
  "$TEST_ROOT/postvalidation.out"

run_stable_global "$release_a"
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
if git -C "$stable_checkout" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
  echo "global stable checkout is not detached" >&2
  exit 1
fi
grep -qx 'release A' "$stable_checkout/.agents/skills/example/SKILL.md"
[ -L "$stable_home/.agents/skills" ]
[ -L "$stable_home/.cursor/skills" ]
[ -L "$stable_home/.claude/skills" ]

edge_checkout="$TEST_ROOT/edge-checkout"
edge_home="$TEST_ROOT/edge-home"
mkdir -p "$edge_home"
git clone -q "$release_source" "$edge_checkout"
git -C "$edge_checkout" config remote.origin.url \
  'https://github.com/marcus-friction/agents.git'
PATH="$(dirname "$git_wrapper"):$PATH" \
HOME="$edge_home" \
AGENTS_ECOSYSTEM_HOME="$edge_checkout" \
AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  bash "$REPO_ROOT/install-global.sh" --ref "$release_a" >/dev/null
[ "$(git -C "$edge_checkout" rev-parse HEAD)" = "$release_a" ]
[ -f "$edge_checkout/.git/agents-ecosystem-managed" ]
if git -C "$edge_checkout" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
  echo "global installer did not migrate the edge checkout to detached stable mode" >&2
  exit 1
fi

wrong_edge_checkout="$TEST_ROOT/wrong-edge-checkout"
wrong_edge_home="$TEST_ROOT/wrong-edge-home"
mkdir -p "$wrong_edge_home"
git clone -q "$release_source" "$wrong_edge_checkout"
if HOME="$wrong_edge_home" \
  AGENTS_ECOSYSTEM_HOME="$wrong_edge_checkout" \
    bash "$REPO_ROOT/install-global.sh" \
      >"$TEST_ROOT/wrong-edge.out" 2>&1; then
  echo "global edge update accepted a noncanonical origin" >&2
  exit 1
fi
grep -Fq 'does not use the canonical agent ecosystem origin' \
  "$TEST_ROOT/wrong-edge.out"

edge_failure_source="$TEST_ROOT/edge-failure-source"
edge_failure_checkout="$TEST_ROOT/edge-failure-checkout"
edge_failure_home="$TEST_ROOT/edge-failure-home"
git clone -q "$release_source" "$edge_failure_source"
git -C "$edge_failure_source" config user.name "Edge Rewrite Test"
git -C "$edge_failure_source" config user.email "edge-rewrite@example.invalid"
git clone -q "$edge_failure_source" "$edge_failure_checkout"
git -C "$edge_failure_checkout" config remote.origin.url \
  'https://github.com/marcus-friction/agents.git'
git -C "$edge_failure_source" checkout -qb rewritten "$release_a"
printf 'rewritten edge\n' > \
  "$edge_failure_source/.agents/skills/example/SKILL.md"
git -C "$edge_failure_source" add .agents/skills/example/SKILL.md
git -C "$edge_failure_source" commit -qm "rewrite edge history"
rewritten_edge="$(git -C "$edge_failure_source" rev-parse HEAD)"
git -C "$edge_failure_source" branch -f master "$rewritten_edge"
mkdir -p "$edge_failure_home"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$edge_failure_home" \
  AGENTS_ECOSYSTEM_HOME="$edge_failure_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$edge_failure_source" \
    bash "$REPO_ROOT/install-global.sh" \
      >"$TEST_ROOT/edge-failure.out" 2>&1; then
  echo "global edge update reported success after a non-fast-forward rewrite" >&2
  exit 1
fi
grep -Fq 'fast-forward' "$TEST_ROOT/edge-failure.out"
if grep -Fq 'Global install complete' "$TEST_ROOT/edge-failure.out"; then
  echo "failed global edge update printed a success report" >&2
  exit 1
fi
[ "$(git -C "$edge_failure_checkout" rev-parse HEAD)" = "$release_b" ]

stash_checkout="$TEST_ROOT/stash-checkout"
stash_home="$TEST_ROOT/stash-home"
cp -a "$stable_checkout" "$stash_checkout"
mkdir -p "$stash_home"
printf 'stash content\n' > "$stash_checkout/.agents/skills/example/SKILL.md"
git -C "$stash_checkout" stash push -qm 'private state'
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$stash_home" \
  AGENTS_ECOSYSTEM_HOME="$stash_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/stash.out" 2>&1; then
  echo "global stable update deleted recoverable private Git state" >&2
  exit 1
fi
[ -n "$(git -C "$stash_checkout" rev-parse --verify refs/stash)" ]

corrupt_checkout="$TEST_ROOT/corrupt-checkout"
corrupt_home="$TEST_ROOT/corrupt-home"
corrupt_object="$corrupt_checkout/.git/objects/aa/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
cp -a "$stable_checkout" "$corrupt_checkout"
mkdir -p "$corrupt_home" "$(dirname "$corrupt_object")"
printf 'corrupt object\n' > "$corrupt_object"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$corrupt_home" \
  AGENTS_ECOSYSTEM_HOME="$corrupt_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/corrupt.out" 2>&1; then
  echo "global stable update discarded a corrupt prior object database" >&2
  exit 1
fi
[ -f "$corrupt_object" ]
[ "$(git -C "$corrupt_checkout" rev-parse HEAD)" = "$release_a" ]
grep -Fq 'object database check failed' "$TEST_ROOT/corrupt.out"

hook_checkout="$TEST_ROOT/hook-checkout"
hook_home="$TEST_ROOT/hook-home"
cp -a "$stable_checkout" "$hook_checkout"
mkdir -p "$hook_home"
printf '#!/bin/sh\nexit 0\n' > "$hook_checkout/.git/hooks/private-hook"
chmod +x "$hook_checkout/.git/hooks/private-hook"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$hook_home" \
  AGENTS_ECOSYSTEM_HOME="$hook_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/hook.out" 2>&1; then
  echo "global stable update deleted private Git hook metadata" >&2
  exit 1
fi
[ -f "$hook_checkout/.git/hooks/private-hook" ]

linked_hooks_checkout="$TEST_ROOT/linked-hooks-checkout"
linked_hooks_home="$TEST_ROOT/linked-hooks-home"
cp -a "$stable_checkout" "$linked_hooks_checkout"
mkdir -p "$linked_hooks_home"
mv "$linked_hooks_checkout/.git/hooks" \
  "$linked_hooks_checkout/.git/private-hooks"
ln -s private-hooks "$linked_hooks_checkout/.git/hooks"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$linked_hooks_home" \
  AGENTS_ECOSYSTEM_HOME="$linked_hooks_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/linked-hooks.out" 2>&1; then
  echo "global stable update accepted a symlinked Git hooks directory" >&2
  exit 1
fi
[ -L "$linked_hooks_checkout/.git/hooks" ]

file_hooks_checkout="$TEST_ROOT/file-hooks-checkout"
file_hooks_home="$TEST_ROOT/file-hooks-home"
cp -a "$stable_checkout" "$file_hooks_checkout"
mkdir -p "$file_hooks_home"
rm -rf "$file_hooks_checkout/.git/hooks"
printf 'private hook metadata\n' > "$file_hooks_checkout/.git/hooks"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$file_hooks_home" \
  AGENTS_ECOSYSTEM_HOME="$file_hooks_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/file-hooks.out" 2>&1; then
  echo "global stable update accepted a non-directory Git hooks path" >&2
  exit 1
fi
grep -qx 'private hook metadata' "$file_hooks_checkout/.git/hooks"

printf '/ignored-local.txt\n' >> "$stable_checkout/.git/info/exclude"
printf 'ignored\n' > "$stable_checkout/ignored-local.txt"
if run_stable_global "$release_b" >"$TEST_ROOT/ignored-stable.out" 2>&1; then
  echo "global installer accepted an ignored entry in an immutable checkout" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
grep -qx 'ignored' "$stable_checkout/ignored-local.txt"
rm "$stable_checkout/ignored-local.txt"

symlink_checkout="$TEST_ROOT/symlink-checkout"
ln -s "$stable_checkout" "$symlink_checkout"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$stable_home" \
  AGENTS_ECOSYSTEM_HOME="$symlink_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/symlink-destination.out" 2>&1; then
  echo "global installer wrote through a symlink destination" >&2
  exit 1
fi
grep -Fq 'destination must not be a symlink' "$TEST_ROOT/symlink-destination.out"
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]

printf 'dirty\n' > "$stable_checkout/local-dirty.txt"
if run_stable_global "$release_b" >"$TEST_ROOT/dirty-stable.out" 2>&1; then
  echo "global installer accepted a dirty immutable checkout" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
grep -qx 'dirty' "$stable_checkout/local-dirty.txt"
rm "$stable_checkout/local-dirty.txt"

filter_marker="$TEST_ROOT/local-filter-ran"
filter_command="$TEST_ROOT/local-filter.sh"
cat > "$filter_command" <<EOF
#!/usr/bin/env bash
cat
printf 'executed\n' > "$filter_marker"
EOF
chmod +x "$filter_command"
git -C "$stable_checkout" config filter.external.smudge "$filter_command"
if run_stable_global "$release_b" >"$TEST_ROOT/filter-config.out" 2>&1; then
  echo "global installer accepted executable local Git configuration" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
[ ! -e "$filter_marker" ]
git -C "$stable_checkout" config --unset-all filter.external.smudge

transport_marker="$TEST_ROOT/local-transport-ran"
git -C "$stable_checkout" config remote.origin.url \
  "ext::sh -c 'printf executed >$transport_marker'"
if run_stable_global "$release_b" >"$TEST_ROOT/transport-config.out" 2>&1; then
  echo "global installer accepted a local transport override" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
[ ! -e "$transport_marker" ]
git -C "$stable_checkout" config --remove-section remote.origin

missing_release=ffffffffffffffffffffffffffffffffffffffff
if run_stable_global "$missing_release" >"$TEST_ROOT/missing-release.out" 2>&1; then
  echo "global installer accepted a missing release commit" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]

install_lock="${stable_checkout}.agents-ecosystem-install.lock"
mkdir "$install_lock"
if run_stable_global "$release_b" >"$TEST_ROOT/concurrent.out" 2>&1; then
  echo "global installer ignored an existing per-destination lock" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
rmdir "$install_lock"

identity_race_checkout="$TEST_ROOT/identity-race-checkout"
identity_race_home="$TEST_ROOT/identity-race-home"
identity_race_original="$TEST_ROOT/identity-race-original"
identity_race_marker="$TEST_ROOT/identity-race-fired"
identity_race_bin="$TEST_ROOT/identity-race-bin"
identity_race_real_mv="$(command -v mv)"
mkdir -p "$identity_race_home" "$identity_race_bin"
cp -a "$stable_checkout" "$identity_race_checkout"
cat > "$identity_race_bin/mv" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
target_path=""
for argument in "$@"; do
  source_path="$target_path"
  target_path="$argument"
done
if [ "$source_path" = "$AGENTS_ECOSYSTEM_TEST_DEST" ] \
  && [[ "$target_path" == "$AGENTS_ECOSYSTEM_TEST_DEST".release.*/prior ]] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_RACE_MARKER" ]; then
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" \
    "$AGENTS_ECOSYSTEM_TEST_DEST" \
    "$AGENTS_ECOSYSTEM_TEST_ORIGINAL"
  mkdir -p "$AGENTS_ECOSYSTEM_TEST_DEST"
  printf 'concurrent replacement\n' \
    > "$AGENTS_ECOSYSTEM_TEST_DEST/concurrent.txt"
  : > "$AGENTS_ECOSYSTEM_TEST_RACE_MARKER"
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
WRAPPER
chmod +x "$identity_race_bin/mv"

transaction_regression_failures=0
if PATH="$identity_race_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$identity_race_home" \
  AGENTS_ECOSYSTEM_HOME="$identity_race_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_REAL_MV="$identity_race_real_mv" \
  AGENTS_ECOSYSTEM_TEST_DEST="$identity_race_checkout" \
  AGENTS_ECOSYSTEM_TEST_ORIGINAL="$identity_race_original" \
  AGENTS_ECOSYSTEM_TEST_RACE_MARKER="$identity_race_marker" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/identity-race.out" 2>&1; then
  echo "global installer accepted a destination replaced after validation" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi
if [ ! -e "$identity_race_marker" ]; then
  echo "global installer identity race fixture did not reach the intended boundary" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi
if [ ! -f "$identity_race_checkout/concurrent.txt" ]; then
  echo "global installer discarded the concurrent destination replacement" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi
if [ ! -d "$identity_race_original" ] \
  || [ "$(git -C "$identity_race_original" rev-parse HEAD 2>/dev/null || true)" != "$release_a" ]; then
  echo "global installer discarded the original checkout during an identity race" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi

signal_checkout="$TEST_ROOT/signal-checkout"
signal_home="$TEST_ROOT/signal-home"
signal_bin="$TEST_ROOT/signal-bin"
signal_marker="$TEST_ROOT/signal-fired"
signal_real_mv="$(command -v mv)"
mkdir -p "$signal_home" "$signal_bin"
cp -a "$stable_checkout" "$signal_checkout"
cat > "$signal_bin/mv" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
source_path=""
target_path=""
for argument in "$@"; do
  source_path="$target_path"
  target_path="$argument"
done
if [ "$source_path" = "$AGENTS_ECOSYSTEM_TEST_DEST" ] \
  && [[ "$target_path" == "$AGENTS_ECOSYSTEM_TEST_DEST".release.*/prior ]] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER" ]; then
  "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
  : > "$AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER"
  kill -TERM "$PPID"
  exit 0
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
WRAPPER
chmod +x "$signal_bin/mv"
signal_status=0
PATH="$signal_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$signal_home" \
  AGENTS_ECOSYSTEM_HOME="$signal_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_REAL_MV="$signal_real_mv" \
  AGENTS_ECOSYSTEM_TEST_DEST="$signal_checkout" \
  AGENTS_ECOSYSTEM_TEST_SIGNAL_MARKER="$signal_marker" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/signal.out" 2>&1 || signal_status="$?"
if [ "$signal_status" -eq 0 ]; then
  echo "global installer completed after TERM interrupted checkout retirement" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi
if [ "$signal_status" -ne 143 ]; then
  echo "global installer did not preserve the deferred TERM exit status" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi
if [ ! -e "$signal_marker" ]; then
  echo "global installer signal fixture did not reach the post-rename boundary" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi
signal_original_recoverable=0
if [ -d "$signal_checkout" ] \
  && [ "$(git -C "$signal_checkout" rev-parse HEAD 2>/dev/null || true)" = "$release_a" ]; then
  signal_original_recoverable=1
else
  for recovery_checkout in "$signal_checkout".release.*/prior; do
    if [ -d "$recovery_checkout" ] \
      && [ "$(git -C "$recovery_checkout" rev-parse HEAD 2>/dev/null || true)" = "$release_a" ]; then
      signal_original_recoverable=1
      break
    fi
  done
fi
if [ "$signal_original_recoverable" -ne 1 ]; then
  echo "global installer discarded the original checkout after an interrupted rename" >&2
  transaction_regression_failures=$((transaction_regression_failures + 1))
fi

if [ "$transaction_regression_failures" -ne 0 ]; then
  exit 1
fi

move_bin="$TEST_ROOT/move-bin"
move_once="$TEST_ROOT/move-failed-once"
real_mv="$(command -v mv)"
mkdir -p "$move_bin"
cat > "$move_bin/mv" <<'WRAPPER'
#!/bin/bash
set -euo pipefail
source_path=""
target_path=""
for argument in "$@"; do
  source_path="$target_path"
  target_path="$argument"
done
if [[ "$source_path" == *.release.*/candidate ]] \
  && [ "$target_path" = "$AGENTS_ECOSYSTEM_TEST_DEST" ] \
  && [ ! -e "$AGENTS_ECOSYSTEM_TEST_MOVE_ONCE" ]; then
  : > "$AGENTS_ECOSYSTEM_TEST_MOVE_ONCE"
  exit 73
fi
exec "$AGENTS_ECOSYSTEM_TEST_REAL_MV" "$@"
WRAPPER
chmod +x "$move_bin/mv"
if PATH="$move_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$stable_home" \
  AGENTS_ECOSYSTEM_HOME="$stable_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_REAL_MV="$real_mv" \
  AGENTS_ECOSYSTEM_TEST_DEST="$stable_checkout" \
  AGENTS_ECOSYSTEM_TEST_MOVE_ONCE="$move_once" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/activation-failure.out" 2>&1; then
  echo "global installer ignored a candidate activation failure" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
grep -Fq 'restored the previous global checkout' \
  "$TEST_ROOT/activation-failure.out"

barrier_bin="$TEST_ROOT/barrier-bin"
barrier_once="$TEST_ROOT/barrier-fired"
barrier_marker="$TEST_ROOT/substitute-registrar-ran"
activated_copy="$TEST_ROOT/activated-copy"
real_bash="$(command -v bash)"
mkdir -p "$barrier_bin"
cat > "$barrier_bin/bash" <<'WRAPPER'
#!/bin/bash
set -euo pipefail
case "${1:-}" in
  *.release.*/trusted-scripts/register-skills.sh)
    if [ ! -e "$AGENTS_ECOSYSTEM_TEST_BARRIER_ONCE" ]; then
      mv "$AGENTS_ECOSYSTEM_TEST_DEST" "$AGENTS_ECOSYSTEM_TEST_ACTIVATED_COPY"
      mkdir -p "$AGENTS_ECOSYSTEM_TEST_DEST/.agents/skills" "$AGENTS_ECOSYSTEM_TEST_DEST/scripts"
      printf '#!/bin/sh\nprintf executed > %s\n' \
        "$AGENTS_ECOSYSTEM_TEST_BARRIER_MARKER" \
        > "$AGENTS_ECOSYSTEM_TEST_DEST/scripts/register-skills.sh"
      chmod +x "$AGENTS_ECOSYSTEM_TEST_DEST/scripts/register-skills.sh"
      : > "$AGENTS_ECOSYSTEM_TEST_BARRIER_ONCE"
    fi
    ;;
esac
exec "$AGENTS_ECOSYSTEM_TEST_REAL_BASH" "$@"
WRAPPER
chmod +x "$barrier_bin/bash"
if PATH="$barrier_bin:$(dirname "$git_wrapper"):$PATH" \
  HOME="$stable_home" \
  AGENTS_ECOSYSTEM_HOME="$stable_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
  AGENTS_ECOSYSTEM_TEST_REAL_BASH="$real_bash" \
  AGENTS_ECOSYSTEM_TEST_DEST="$stable_checkout" \
  AGENTS_ECOSYSTEM_TEST_ACTIVATED_COPY="$activated_copy" \
  AGENTS_ECOSYSTEM_TEST_BARRIER_ONCE="$barrier_once" \
  AGENTS_ECOSYSTEM_TEST_BARRIER_MARKER="$barrier_marker" \
    bash "$REPO_ROOT/install-global.sh" --ref "$release_b" \
      >"$TEST_ROOT/barrier.out" 2>&1; then
  echo "global installer accepted a checkout substituted before registration" >&2
  exit 1
fi
[ ! -e "$barrier_marker" ]
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
[ "$(readlink "$stable_home/.agents/skills")" = \
  "$stable_checkout/.agents/skills" ]

run_stable_global "$release_b"
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_b" ]
grep -qx 'release B' "$stable_checkout/.agents/skills/example/SKILL.md"

run_stable_global "$release_a"
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
grep -qx 'release A' "$stable_checkout/.agents/skills/example/SKILL.md"

if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$stable_home" \
  AGENTS_ECOSYSTEM_HOME="$stable_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref master \
      >"$TEST_ROOT/invalid-ref.out" 2>&1; then
  echo "global installer accepted a mutable ref" >&2
  exit 1
fi
grep -Fq 'full 40-character lowercase commit SHA' "$TEST_ROOT/invalid-ref.out"
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]

printf '#!/usr/bin/env bash\nexit 23\n' \
  > "$release_source/scripts/register-skills.sh"
chmod +x "$release_source/scripts/register-skills.sh"
git -C "$release_source" add scripts/register-skills.sh
git -C "$release_source" commit -qm "release with failing registrar"
failing_release="$(git -C "$release_source" rev-parse HEAD)"
if run_stable_global "$failing_release" >"$TEST_ROOT/registrar-failure.out" 2>&1; then
  echo "global installer ignored a failing release registrar" >&2
  exit 1
fi
[ "$(git -C "$stable_checkout" rev-parse HEAD)" = "$release_a" ]
grep -Fq 'restored the previous global checkout' \
  "$TEST_ROOT/registrar-failure.out"

evil_marker="$TEST_ROOT/evil-registrar-ran"
evil_registrar="$TEST_ROOT/evil-registrar.sh"
cat > "$evil_registrar" <<EOF
#!/usr/bin/env bash
printf 'executed\n' > "$evil_marker"
EOF
chmod +x "$evil_registrar"
git -C "$release_source" switch -q master
rm "$release_source/scripts/register-skills.sh"
ln -s "$evil_registrar" "$release_source/scripts/register-skills.sh"
git -C "$release_source" add -A
git -C "$release_source" commit -qm "release with external registrar symlink"
symlink_release="$(git -C "$release_source" rev-parse HEAD)"
symlink_payload_checkout="$TEST_ROOT/symlink-payload-checkout"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  HOME="$stable_home" \
  AGENTS_ECOSYSTEM_HOME="$symlink_payload_checkout" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
  AGENTS_ECOSYSTEM_TEST_SOURCE="$release_source" \
    bash "$REPO_ROOT/install-global.sh" --ref "$symlink_release" \
      >"$TEST_ROOT/symlink-payload.out" 2>&1; then
  echo "global installer accepted a registrar symlink outside the release" >&2
  exit 1
fi
[ ! -e "$evil_marker" ]

echo "Global installer dirty and immutable-ref tests passed"
