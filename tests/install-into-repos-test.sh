#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
REAL_GIT="$(command -v git)"
REAL_MKTEMP="$(command -v mktemp)"
BULK_BRANCH="feature/import-agent-ecosystem-skills"
export AGENTS_ECOSYSTEM_BULK_BRANCH="feature/ambient-branch-must-be-ignored"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

if bash "$REPO_ROOT/scripts/install-into-repos.sh" \
  --ref master --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/invalid-plan" owner/repo \
  >"$TEST_ROOT/invalid.out" 2>&1; then
  echo "bulk installer accepted a mutable release ref" >&2
  exit 1
fi
grep -Fq 'full 40-character lowercase commit SHA' "$TEST_ROOT/invalid.out"

if bash "$REPO_ROOT/scripts/install-into-repos.sh" \
  --apply --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/unpinned-plan" owner/repo \
  >"$TEST_ROOT/unpinned-apply.out" 2>&1; then
  echo "bulk installer allowed remote effects from an unpinned source" >&2
  exit 1
fi
grep -Fq 'full 40-character lowercase commit SHA' \
  "$TEST_ROOT/unpinned-apply.out"

source_checkout="$TEST_ROOT/source"
mkdir -p "$source_checkout"
cp -R "$REPO_ROOT/.agents" "$source_checkout/.agents"
cp -R "$REPO_ROOT/project-templates" "$source_checkout/project-templates"
cp -R "$REPO_ROOT/scripts" "$source_checkout/scripts"
cp "$REPO_ROOT/install.sh" "$source_checkout/install.sh"
git -C "$source_checkout" init -q -b master
git -C "$source_checkout" config user.name "Bulk Ref Test"
git -C "$source_checkout" config user.email "bulk-ref@example.invalid"
git -C "$source_checkout" add .
git -C "$source_checkout" commit -qm "release fixture"
release_ref="$(git -C "$source_checkout" rev-parse HEAD)"

if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/attached-plan" \
  owner/repo >"$TEST_ROOT/attached.out" 2>&1; then
  echo "bulk installer accepted an attached release source" >&2
  exit 1
fi
grep -Fq 'detached HEAD' "$TEST_ROOT/attached.out"

git -C "$source_checkout" checkout -q --detach "$release_ref"

if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --plan-dir "$TEST_ROOT/missing-branch-plan" \
  owner/repo >"$TEST_ROOT/missing-branch.out" 2>&1; then
  echo "bulk installer accepted a missing branch decision" >&2
  exit 1
fi
grep -Fq -- '--branch is required' "$TEST_ROOT/missing-branch.out"
[ ! -e "$TEST_ROOT/missing-branch-plan" ]

duplicate_plan="$TEST_ROOT/duplicate-plan"
if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --branch "$BULK_BRANCH" \
  --plan-dir "$duplicate_plan" \
  owner/repo owner/repo >"$TEST_ROOT/duplicate.out" 2>&1; then
  echo "bulk installer accepted a duplicate repository target" >&2
  exit 1
fi
grep -Fq 'duplicate GitHub repository slug alias: owner/repo and owner/repo' \
  "$TEST_ROOT/duplicate.out"
[ ! -e "$duplicate_plan" ]

mkdir -p "$TEST_ROOT/physical-plan-parent"
if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/physical-plan-parent/../escaped-plan" \
  owner/repo >"$TEST_ROOT/dotdot-plan.out" 2>&1; then
  echo "bulk installer accepted a nonnormalized plan path" >&2
  exit 1
fi
grep -Fq -- '--plan-dir must be normalized' "$TEST_ROOT/dotdot-plan.out"
[ ! -e "$TEST_ROOT/escaped-plan" ]

ln -s "$TEST_ROOT/physical-plan-parent" "$TEST_ROOT/linked-plan-parent"
if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/linked-plan-parent/plan" \
  owner/repo >"$TEST_ROOT/symlink-plan.out" 2>&1; then
  echo "bulk installer followed a plan-path ancestor symlink" >&2
  exit 1
fi
grep -Fq -- '--plan-dir must not cross a symlink' \
  "$TEST_ROOT/symlink-plan.out"
[ ! -e "$TEST_ROOT/physical-plan-parent/plan" ]

printf 'dirty\n' > "$source_checkout/local-dirty.txt"
if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/dirty-plan" \
  owner/repo >"$TEST_ROOT/dirty.out" 2>&1; then
  echo "bulk installer accepted a dirty immutable source" >&2
  exit 1
fi
grep -Fq 'immutable bulk source must be clean' "$TEST_ROOT/dirty.out"
rm "$source_checkout/local-dirty.txt"

git -C "$source_checkout" update-index --skip-worktree install.sh
printf '\nhidden local installer change\n' >> "$source_checkout/install.sh"
if bash "$source_checkout/scripts/install-into-repos.sh" \
  --ref "$release_ref" --branch "$BULK_BRANCH" \
  --plan-dir "$TEST_ROOT/hidden-index-plan" \
  owner/repo >"$TEST_ROOT/hidden-index.out" 2>&1; then
  echo "bulk installer accepted hidden immutable-source index state" >&2
  exit 1
fi
grep -Fq 'immutable bulk source has hidden index state' \
  "$TEST_ROOT/hidden-index.out"
[ ! -e "$TEST_ROOT/hidden-index-plan" ]
git -C "$source_checkout" update-index --no-skip-worktree install.sh
git -C "$source_checkout" restore install.sh

target_source="$TEST_ROOT/target-source"
target_remote="$TEST_ROOT/target.git"
mkdir -p "$target_source"
git -C "$target_source" init -q -b master
git -C "$target_source" config user.name "Target Fixture"
git -C "$target_source" config user.email "target@example.invalid"
printf '# Target\n' > "$target_source/README.md"
printf 'README.md filter=ambient\n' > "$target_source/.gitattributes"
git -C "$target_source" add README.md .gitattributes
git -C "$target_source" commit -qm "target fixture"
git clone -q --bare "$target_source" "$target_remote"

git_wrapper="$TEST_ROOT/bin/git"
gh_wrapper="$TEST_ROOT/bin/gh"
mktemp_wrapper="$TEST_ROOT/bin/mktemp"
mkdir -p "$(dirname "$git_wrapper")"
cat > "$git_wrapper" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
args=("$@")
saw_target_url=0
if [ -n "${AGENTS_ECOSYSTEM_TEST_RACE_INSTALLER:-}" ]; then
  saw_clone=0
  saw_source=0
  for argument in "${args[@]}"; do
    [ "$argument" = clone ] && saw_clone=1
    [ "$argument" = "$AGENTS_ECOSYSTEM_TEST_SOURCE_WORKTREE" ] && saw_source=1
  done
  if [ "$saw_clone" -eq 1 ] && [ "$saw_source" -eq 1 ]; then
    printf '#!/usr/bin/env bash\nprintf executed > %q\n' \
      "$AGENTS_ECOSYSTEM_TEST_RACE_MARKER" \
      > "$AGENTS_ECOSYSTEM_TEST_SOURCE_WORKTREE/install.sh"
    chmod +x "$AGENTS_ECOSYSTEM_TEST_SOURCE_WORKTREE/install.sh"
  fi
fi
for index in "${!args[@]}"; do
  if [ "${args[$index]}" = "https://github.com/owner/repo.git" ] \
    || [ "${args[$index]}" = "https://github.com/Owner/Repo.git" ]; then
    saw_target_url=1
    if [ -n "${AGENTS_ECOSYSTEM_TEST_REQUIRE_ASKPASS:-}" ]; then
      response="$("${GIT_ASKPASS:?missing explicit askpass}" 'Password for GitHub')"
      [ "$response" = "$AGENTS_ECOSYSTEM_TEST_ASKPASS_SECRET" ]
      : > "$AGENTS_ECOSYSTEM_TEST_ASKPASS_MARKER"
    fi
    args[$index]="$AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE"
  fi
done
for argument in "${args[@]}"; do
  if [ "$argument" = fetch ] && [ "$saw_target_url" -eq 1 ] \
    && [ -n "${AGENTS_ECOSYSTEM_TEST_FETCH_MARKER:-}" ]; then
    if [ -n "${AGENTS_ECOSYSTEM_TEST_ADVANCE_BASE_BEFORE_FETCH:-}" ] \
      && [ ! -e "$AGENTS_ECOSYSTEM_TEST_BASE_RACE_MARKER" ]; then
      "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" --git-dir="$AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE" \
        update-ref refs/heads/master "$AGENTS_ECOSYSTEM_TEST_ADVANCE_BASE_BEFORE_FETCH"
      : > "$AGENTS_ECOSYSTEM_TEST_BASE_RACE_MARKER"
    fi
    : > "$AGENTS_ECOSYSTEM_TEST_FETCH_MARKER"
  fi
  if [ "$argument" = push ]; then
    if [ -n "${AGENTS_ECOSYSTEM_TEST_CREATE_FEATURE_ON_PUSH:-}" ] \
      && [ ! -e "$AGENTS_ECOSYSTEM_TEST_FEATURE_RACE_MARKER" ]; then
      "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" --git-dir="$AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE" \
        update-ref "refs/heads/$AGENTS_ECOSYSTEM_TEST_BRANCH" \
        "$AGENTS_ECOSYSTEM_TEST_CREATE_FEATURE_ON_PUSH"
      : > "$AGENTS_ECOSYSTEM_TEST_FEATURE_RACE_MARKER"
    fi
    printf 'push\n' >> "$AGENTS_ECOSYSTEM_TEST_EFFECT_LOG"
  fi
done
exec "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" "${args[@]}"
WRAPPER
cat > "$gh_wrapper" <<'WRAPPER'
#!/usr/bin/env bash
printf 'GH_HOST=%s GH_REPO=%s\n' "${GH_HOST-unset}" "${GH_REPO-unset}" \
  >> "$AGENTS_ECOSYSTEM_TEST_EFFECT_LOG"
printf 'gh %s\n' "$*" >> "$AGENTS_ECOSYSTEM_TEST_EFFECT_LOG"
WRAPPER
cat > "$mktemp_wrapper" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
real_mktemp="${AGENTS_ECOSYSTEM_TEST_REAL_MKTEMP:-$(PATH=/usr/bin:/bin command -v mktemp)}"
result="$("$real_mktemp" "$@")"
if [[ "$*" == *agents-ecosystem-bulk-work.* ]] \
  && [ -n "${AGENTS_ECOSYSTEM_TEST_REPLACE_PLAN_AT_WORK:-}" ]; then
  cp "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_PATCH" \
    "$AGENTS_ECOSYSTEM_TEST_REPLACE_PLAN_AT_WORK/owner__repo/changes.patch"
  cp "$AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MANIFEST" \
    "$AGENTS_ECOSYSTEM_TEST_REPLACE_PLAN_AT_WORK/owner__repo/manifest.txt"
  : > "$AGENTS_ECOSYSTEM_TEST_PLAN_RACE_MARKER"
fi
printf '%s\n' "$result"
WRAPPER
chmod +x "$git_wrapper" "$gh_wrapper" "$mktemp_wrapper"

effect_log="$TEST_ROOT/effects.log"

mixed_duplicate_plan="$TEST_ROOT/mixed-duplicate-plan"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$mixed_duplicate_plan" \
      Owner/Repo owner/repo >"$TEST_ROOT/mixed-duplicate.out" 2>&1; then
  echo "bulk installer accepted case-aliased repository targets" >&2
  exit 1
fi
grep -Fq 'duplicate GitHub repository slug alias: Owner/Repo and owner/repo' \
  "$TEST_ROOT/mixed-duplicate.out"
[ ! -e "$mixed_duplicate_plan" ]

spoof_repo="$TEST_ROOT/spoof-repo"
mkdir -p "$spoof_repo"
git -C "$spoof_repo" init -q -b master
git -C "$spoof_repo" config user.name "Spoof Fixture"
git -C "$spoof_repo" config user.email "spoof@example.invalid"
printf 'spoof\n' > "$spoof_repo/spoof.txt"
git -C "$spoof_repo" add spoof.txt
git -C "$spoof_repo" commit -qm "spoof fixture"
spoof_ref="$(git -C "$spoof_repo" rev-parse HEAD)"
git -C "$spoof_repo" checkout -q --detach "$spoof_ref"
if GIT_DIR="$spoof_repo/.git" \
  GIT_WORK_TREE="$spoof_repo" \
  PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$spoof_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$TEST_ROOT/spoof-plan" \
      owner/repo >"$TEST_ROOT/ambient-git.out" 2>&1; then
  echo "bulk installer accepted an ambient Git-directory override" >&2
  exit 1
fi
grep -Fq 'bulk source HEAD' "$TEST_ROOT/ambient-git.out"

race_marker="$TEST_ROOT/raced-installer-ran"
askpass_marker="$TEST_ROOT/askpass-used"
askpass_script="$TEST_ROOT/git-askpass.sh"
askpass_secret='test-credential-value'
cat > "$askpass_script" <<EOF
#!/usr/bin/env bash
printf '%s\n' '$askpass_secret'
EOF
chmod +x "$askpass_script"
plan_dir="$TEST_ROOT/prepared-plan"
AGENTS_ECOSYSTEM_TEST_RACE_INSTALLER=1 \
  AGENTS_ECOSYSTEM_TEST_RACE_MARKER="$race_marker" \
  AGENTS_ECOSYSTEM_TEST_SOURCE_WORKTREE="$source_checkout" \
  AGENTS_ECOSYSTEM_TEST_REQUIRE_ASKPASS=1 \
  AGENTS_ECOSYSTEM_TEST_ASKPASS_SECRET="$askpass_secret" \
  AGENTS_ECOSYSTEM_TEST_ASKPASS_MARKER="$askpass_marker" \
  PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" \
      --git-askpass "$askpass_script" \
      owner/repo >"$TEST_ROOT/prepare.out"
[ ! -e "$race_marker" ] || {
  echo "bulk preparation executed a concurrently replaced source installer" >&2
  exit 1
}
git -C "$source_checkout" checkout -q -- install.sh
[ -e "$askpass_marker" ]
if grep -Fq "$askpass_secret" "$TEST_ROOT/prepare.out"; then
  echo "bulk preparation printed an askpass credential" >&2
  exit 1
fi

grep -Fq "Verified immutable bulk source at $release_ref" "$TEST_ROOT/prepare.out"
grep -Fq "Verified immutable source at $release_ref" "$TEST_ROOT/prepare.out"
grep -Fq 'Prepared exact artifacts for owner/repo' "$TEST_ROOT/prepare.out"
plan_digest="$(sed -n 's/^Reviewed plan sha256: //p' "$TEST_ROOT/prepare.out")"
[[ "$plan_digest" =~ ^[0-9a-f]{64}$ ]]
[ -f "$plan_dir/owner__repo/manifest.txt" ]
[ -f "$plan_dir/owner__repo/changes.patch" ]
grep -Fxq 'host=github.com' "$plan_dir/owner__repo/manifest.txt"
grep -Fxq "repository=owner/repo" "$plan_dir/owner__repo/manifest.txt"
grep -Fxq "branch=$BULK_BRANCH" "$plan_dir/owner__repo/manifest.txt"
grep -Fxq "source_sha=$release_ref" "$plan_dir/owner__repo/manifest.txt"
if [ -e "$effect_log" ]; then
  echo "prepare-only bulk installation caused a remote effect" >&2
  cat "$effect_log" >&2
  exit 1
fi
[ -z "$(git --git-dir="$target_remote" for-each-ref --format='%(refname)' refs/heads/chore/)" ]
apply_author_args=(
  --author-name "Bulk Apply Test"
  --author-email "bulk-apply@example.invalid"
)

hook_marker="$TEST_ROOT/ambient-post-checkout-ran"
filter_marker="$TEST_ROOT/ambient-filter-ran"
filter_command="$TEST_ROOT/ambient-filter.sh"
hook_template="$TEST_ROOT/git-template"
ambient_config="$TEST_ROOT/ambient-target-gitconfig"
mkdir -p "$hook_template/hooks"
cat > "$hook_template/hooks/post-checkout" <<EOF
#!/usr/bin/env bash
printf 'executed\n' > "$hook_marker"
EOF
chmod +x "$hook_template/hooks/post-checkout"
cat > "$filter_command" <<EOF
#!/usr/bin/env bash
cat
printf 'executed\n' > "$filter_marker"
EOF
chmod +x "$filter_command"
cat > "$ambient_config" <<EOF
[init]
    templateDir = $hook_template
[filter "ambient"]
    smudge = $filter_command
[url "$spoof_repo"]
    insteadOf = $target_remote
EOF
GIT_CONFIG_GLOBAL="$ambient_config" \
PATH="$(dirname "$git_wrapper"):$PATH" \
AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
  bash "$source_checkout/scripts/install-into-repos.sh" \
    --ref "$release_ref" --branch "$BULK_BRANCH" \
    --plan-dir "$TEST_ROOT/ambient-plan" \
    owner/repo >"$TEST_ROOT/ambient-hook.out"
[ ! -e "$hook_marker" ] || {
  echo "prepare-only bulk install executed an ambient target Git hook" >&2
  exit 1
}
[ ! -e "$filter_marker" ] || {
  echo "prepare-only bulk install executed an ambient target Git filter" >&2
  exit 1
}
grep -Fxq "base_sha=$(git --git-dir="$target_remote" rev-parse refs/heads/master)" \
  "$TEST_ROOT/ambient-plan/owner__repo/manifest.txt"

: > "$effect_log"
tampered_plan="$TEST_ROOT/tampered-plan"
cp -R "$plan_dir" "$tampered_plan"
printf '\n# tampered\n' >> "$tampered_plan/owner__repo/changes.patch"
if command -v sha256sum >/dev/null 2>&1; then
  tampered_patch_sha="$(sha256sum "$tampered_plan/owner__repo/changes.patch" | sed 's/[[:space:]].*$//')"
else
  tampered_patch_sha="$(shasum -a 256 "$tampered_plan/owner__repo/changes.patch" | sed 's/[[:space:]].*$//')"
fi
sed "s/^patch_sha256=.*/patch_sha256=$tampered_patch_sha/" \
  "$tampered_plan/owner__repo/manifest.txt" \
  > "$tampered_plan/owner__repo/manifest.updated"
mv "$tampered_plan/owner__repo/manifest.updated" \
  "$tampered_plan/owner__repo/manifest.txt"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$tampered_plan" --apply \
      --expected-plan-sha256 "$plan_digest" \
      "${apply_author_args[@]}" \
      owner/repo >"$TEST_ROOT/tampered-apply.out" 2>&1; then
  echo "bulk apply accepted a modified prepared patch" >&2
  exit 1
fi
grep -Fq 'plan digest mismatch' "$TEST_ROOT/tampered-apply.out"
[ ! -s "$effect_log" ]

if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" --apply \
      owner/repo >"$TEST_ROOT/missing-digest.out" 2>&1; then
  echo "bulk apply accepted a plan without its separately reviewed digest" >&2
  exit 1
fi
grep -Fq -- '--apply requires the reviewed --expected-plan-sha256' \
  "$TEST_ROOT/missing-digest.out"

if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" --apply \
      --expected-plan-sha256 "$plan_digest" \
      owner/repo >"$TEST_ROOT/missing-author.out" 2>&1; then
  echo "bulk apply accepted missing explicit author identity" >&2
  exit 1
fi
grep -Fq -- '--apply requires --author-name and --author-email' \
  "$TEST_ROOT/missing-author.out"
[ ! -s "$effect_log" ]

if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch feature/different-import \
      --plan-dir "$plan_dir" --apply \
      --expected-plan-sha256 "$plan_digest" \
      "${apply_author_args[@]}" \
      owner/repo >"$TEST_ROOT/branch-mismatch.out" 2>&1; then
  echo "bulk apply accepted a branch different from the reviewed plan" >&2
  exit 1
fi
grep -Fq 'prepared manifest does not match the approved boundary' \
  "$TEST_ROOT/branch-mismatch.out"
[ ! -s "$effect_log" ]

base_sha="$(git --git-dir="$target_remote" rev-parse refs/heads/master)"
printf 'drift\n' > "$target_source/drift.txt"
git -C "$target_source" add drift.txt
git -C "$target_source" commit -qm "target drift"
drift_sha="$(git -C "$target_source" rev-parse HEAD)"
git -C "$target_source" push -q "$target_remote" master
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" --apply \
      --expected-plan-sha256 "$plan_digest" \
      "${apply_author_args[@]}" \
      owner/repo >"$TEST_ROOT/drift-apply.out" 2>&1; then
  echo "bulk apply accepted target base drift" >&2
  exit 1
fi
grep -Fq 'base drifted' "$TEST_ROOT/drift-apply.out"
[ ! -s "$effect_log" ]
git --git-dir="$target_remote" update-ref refs/heads/master "$base_sha"

: > "$effect_log"
git --git-dir="$target_remote" update-ref \
  "refs/heads/$BULK_BRANCH" "$base_sha"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" --apply \
      --expected-plan-sha256 "$plan_digest" \
      "${apply_author_args[@]}" \
      owner/repo >"$TEST_ROOT/existing-feature.out" 2>&1; then
  echo "bulk apply advanced an existing feature branch" >&2
  exit 1
fi
[ "$(git --git-dir="$target_remote" rev-parse \
  "refs/heads/$BULK_BRANCH")" = "$base_sha" ]
if grep -Eq '^(gh|GH_)' "$effect_log"; then
  echo "bulk apply created a PR for an existing feature branch" >&2
  exit 1
fi
git --git-dir="$target_remote" update-ref -d \
  "refs/heads/$BULK_BRANCH"

: > "$effect_log"
feature_race_marker="$TEST_ROOT/feature-created-during-push"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
  AGENTS_ECOSYSTEM_TEST_CREATE_FEATURE_ON_PUSH="$base_sha" \
  AGENTS_ECOSYSTEM_TEST_FEATURE_RACE_MARKER="$feature_race_marker" \
  AGENTS_ECOSYSTEM_TEST_BRANCH="$BULK_BRANCH" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" --apply \
      --expected-plan-sha256 "$plan_digest" \
      "${apply_author_args[@]}" \
      owner/repo >"$TEST_ROOT/feature-race.out" 2>&1; then
  echo "bulk apply advanced a feature branch created concurrently" >&2
  exit 1
fi
[ -e "$feature_race_marker" ]
[ "$(git --git-dir="$target_remote" rev-parse \
  "refs/heads/$BULK_BRANCH")" = "$base_sha" ]
if grep -Eq '^(gh|GH_)' "$effect_log"; then
  echo "bulk apply created a PR after concurrent feature-branch creation" >&2
  exit 1
fi
git --git-dir="$target_remote" update-ref -d \
  "refs/heads/$BULK_BRANCH"

: > "$effect_log"
base_race_marker="$TEST_ROOT/base-advanced-before-push"
fetch_marker="$TEST_ROOT/base-refetched-before-push"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
  AGENTS_ECOSYSTEM_TEST_ADVANCE_BASE_BEFORE_FETCH="$drift_sha" \
  AGENTS_ECOSYSTEM_TEST_BASE_RACE_MARKER="$base_race_marker" \
  AGENTS_ECOSYSTEM_TEST_FETCH_MARKER="$fetch_marker" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$release_ref" --branch "$BULK_BRANCH" \
      --plan-dir "$plan_dir" --apply \
      --expected-plan-sha256 "$plan_digest" \
      "${apply_author_args[@]}" \
      owner/repo >"$TEST_ROOT/base-race.out" 2>&1; then
  echo "bulk apply pushed after the target base changed before its final check" >&2
  exit 1
fi
[ -e "$base_race_marker" ]
[ -e "$fetch_marker" ]
if grep -Eq '^(gh|GH_)' "$effect_log"; then
  echo "bulk apply created a pull request after target-base drift" >&2
  exit 1
fi
if git --git-dir="$target_remote" rev-parse --verify \
  "refs/heads/$BULK_BRANCH" >/dev/null 2>&1; then
  echo "bulk apply created a remote branch after target-base drift" >&2
  exit 1
fi
git --git-dir="$target_remote" update-ref refs/heads/master "$base_sha"

: > "$effect_log"
race_plan="$TEST_ROOT/race-plan"
cp -R "$plan_dir" "$race_plan"
replacement_work="$TEST_ROOT/replacement-work"
git clone -q "$target_remote" "$replacement_work"
git -C "$replacement_work" checkout -q --detach "$base_sha"
git -C "$replacement_work" apply --index --whitespace=nowarn \
  "$race_plan/owner__repo/changes.patch"
printf 'not approved\n' > "$replacement_work/UNAPPROVED_RACE.txt"
git -C "$replacement_work" add UNAPPROVED_RACE.txt
replacement_patch="$TEST_ROOT/replacement.patch"
git -C "$replacement_work" diff --cached --binary --full-index --no-ext-diff \
  > "$replacement_patch"
if command -v sha256sum >/dev/null 2>&1; then
  replacement_patch_sha="$(sha256sum "$replacement_patch" | sed 's/[[:space:]].*$//')"
else
  replacement_patch_sha="$(shasum -a 256 "$replacement_patch" | sed 's/[[:space:]].*$//')"
fi
replacement_manifest="$TEST_ROOT/replacement-manifest.txt"
sed "s/^patch_sha256=.*/patch_sha256=$replacement_patch_sha/" \
  "$race_plan/owner__repo/manifest.txt" > "$replacement_manifest"
plan_race_marker="$TEST_ROOT/plan-replaced-after-snapshot"
GH_REPO="wrong/elsewhere" \
GH_HOST="attacker.example" \
GIT_AUTHOR_NAME="Ambient Wrong Author" \
GIT_AUTHOR_EMAIL="ambient-wrong@example.invalid" \
GIT_COMMITTER_NAME="Ambient Wrong Committer" \
GIT_COMMITTER_EMAIL="ambient-wrong@example.invalid" \
PATH="$(dirname "$git_wrapper"):$PATH" \
AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
AGENTS_ECOSYSTEM_TEST_REAL_MKTEMP="$REAL_MKTEMP" \
AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
AGENTS_ECOSYSTEM_TEST_REPLACE_PLAN_AT_WORK="$race_plan" \
AGENTS_ECOSYSTEM_TEST_REPLACEMENT_PATCH="$replacement_patch" \
AGENTS_ECOSYSTEM_TEST_REPLACEMENT_MANIFEST="$replacement_manifest" \
AGENTS_ECOSYSTEM_TEST_PLAN_RACE_MARKER="$plan_race_marker" \
  bash "$source_checkout/scripts/install-into-repos.sh" \
    --ref "$release_ref" --branch "$BULK_BRANCH" \
    --plan-dir "$race_plan" --apply \
    --expected-plan-sha256 "$plan_digest" \
    "${apply_author_args[@]}" \
    owner/repo >"$TEST_ROOT/apply.out"
[ -e "$plan_race_marker" ] || {
  echo "bulk apply did not exercise the post-verification plan race" >&2
  exit 1
}
grep -qx 'push' "$effect_log"
grep -Fxq 'GH_HOST=unset GH_REPO=unset' "$effect_log"
grep -Fq 'gh pr create --repo github.com/owner/repo ' "$effect_log" || {
  echo "bulk apply did not bind PR creation to the approved repository" >&2
  cat "$effect_log" >&2
  exit 1
}
[ -n "$(git --git-dir="$target_remote" rev-parse \
  "refs/heads/$BULK_BRANCH")" ]
[ "$(git --git-dir="$target_remote" log -1 \
  --format='%an <%ae>|%cn <%ce>' \
  "refs/heads/$BULK_BRANCH")" = \
  'Bulk Apply Test <bulk-apply@example.invalid>|Bulk Apply Test <bulk-apply@example.invalid>' ]
if git --git-dir="$target_remote" cat-file -e \
  "refs/heads/$BULK_BRANCH:UNAPPROVED_RACE.txt" 2>/dev/null; then
  echo "bulk apply used plan artifacts replaced after verification" >&2
  exit 1
fi

evil_marker="$TEST_ROOT/evil-installer-ran"
evil_installer="$TEST_ROOT/evil-install.sh"
cat > "$evil_installer" <<EOF
#!/usr/bin/env bash
printf 'executed\n' > "$evil_marker"
EOF
chmod +x "$evil_installer"
git -C "$source_checkout" switch -q master
rm "$source_checkout/install.sh"
ln -s "$evil_installer" "$source_checkout/install.sh"
git -C "$source_checkout" add -A
git -C "$source_checkout" commit -qm "release with external installer symlink"
symlink_release="$(git -C "$source_checkout" rev-parse HEAD)"
git -C "$source_checkout" checkout -q --detach "$symlink_release"
if PATH="$(dirname "$git_wrapper"):$PATH" \
  AGENTS_ECOSYSTEM_TEST_REAL_GIT="$REAL_GIT" \
  AGENTS_ECOSYSTEM_TEST_TARGET_REMOTE="$target_remote" \
  AGENTS_ECOSYSTEM_TEST_EFFECT_LOG="$effect_log" \
    bash "$source_checkout/scripts/install-into-repos.sh" \
      --ref "$symlink_release" --branch "$BULK_BRANCH" \
      --plan-dir "$TEST_ROOT/symlink-plan" \
      owner/repo \
      >"$TEST_ROOT/symlink-installer.out" 2>&1; then
  echo "bulk installer accepted an installer symlink outside the release" >&2
  exit 1
fi
[ ! -e "$evil_marker" ]

echo "Bulk installer immutable-ref and effect-boundary tests passed"
