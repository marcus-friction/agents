#!/usr/bin/env bash
# Prepare or apply an exact Agents Ecosystem import for one or more GitHub repositories.
# Preparation writes reviewable local artifacts. Applying requires those artifacts
# and validates the source, target base, host, and patch before each push.

set -euo pipefail
umask 077

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SRC/scripts/trusted-path.sh"
BRANCH=""
RELEASE_REF=""
PLAN_DIR=""
APPLY=0
EXPECTED_PLAN_SHA256=""
TARGET_ASKPASS=""
AUTHOR_NAME=""
AUTHOR_EMAIL=""
REPOSITORIES=()
SOURCE_SNAPSHOT=""
APPLY_PLAN_SNAPSHOT=""
PLAN_ROOT=""

cleanup() {
  local private_dir
  for private_dir in "$SOURCE_SNAPSHOT" "$APPLY_PLAN_SNAPSHOT"; do
    case "$private_dir" in
      /tmp/agents-ecosystem-bulk-*)
        if [ -d "$private_dir" ] && [ ! -L "$private_dir" ]; then
          rm -rf "$private_dir"
        fi
        ;;
    esac
  done
}
trap cleanup EXIT

cleanup_work() {
  case "$1" in
    /tmp/agents-ecosystem-bulk-work.*)
      if [ -d "$1" ] && [ ! -L "$1" ]; then
        rm -rf "$1"
      fi
      ;;
  esac
}

usage() {
  echo "Usage: $0 --ref COMMIT --branch NAME --plan-dir ABSOLUTE-PATH [--apply --expected-plan-sha256 DIGEST --author-name NAME --author-email EMAIL] owner/repo [...]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref)
      RELEASE_REF="${2:-}"
      [ -n "$RELEASE_REF" ] || {
        echo "Error: --ref requires a full 40-character lowercase commit SHA." >&2
        exit 1
      }
      shift 2
      ;;
    --plan-dir)
      PLAN_DIR="${2:-}"
      [ -n "$PLAN_DIR" ] || {
        echo "Error: --plan-dir requires an absolute path." >&2
        exit 1
      }
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      [ -n "$BRANCH" ] || {
        echo "Error: --branch requires a target-policy-compliant branch name." >&2
        exit 1
      }
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --expected-plan-sha256)
      EXPECTED_PLAN_SHA256="${2:-}"
      [ -n "$EXPECTED_PLAN_SHA256" ] || {
        echo "Error: --expected-plan-sha256 requires a 64-character digest." >&2
        exit 1
      }
      shift 2
      ;;
    --git-askpass)
      TARGET_ASKPASS="${2:-}"
      [ -n "$TARGET_ASKPASS" ] || {
        echo "Error: --git-askpass requires an absolute executable path." >&2
        exit 1
      }
      shift 2
      ;;
    --author-name)
      AUTHOR_NAME="${2:-}"
      [ -n "$AUTHOR_NAME" ] || {
        echo "Error: --author-name requires a non-empty value." >&2
        exit 1
      }
      shift 2
      ;;
    --author-email)
      AUTHOR_EMAIL="${2:-}"
      [ -n "$AUTHOR_EMAIL" ] || {
        echo "Error: --author-email requires a non-empty value." >&2
        exit 1
      }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        REPOSITORIES+=("$1")
        shift
      done
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      REPOSITORIES+=("$1")
      shift
      ;;
  esac
done

if ! [[ "$RELEASE_REF" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Error: --ref requires a full 40-character lowercase commit SHA." >&2
  exit 1
fi
if [[ "$PLAN_DIR" != /* ]] || [[ "$PLAN_DIR" == */ ]] || [ "$PLAN_DIR" = "/" ]; then
  echo "Error: --plan-dir requires a normalized absolute child path." >&2
  exit 1
fi
if [ "${#REPOSITORIES[@]}" -eq 0 ]; then
  usage >&2
  exit 1
fi
if [ -z "$BRANCH" ]; then
  echo "Error: --branch is required and must comply with every target repository policy." >&2
  exit 1
fi
if [ "$APPLY" -eq 1 ] && ! [[ "$EXPECTED_PLAN_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Error: --apply requires the reviewed --expected-plan-sha256 digest." >&2
  exit 1
fi
if [ "$APPLY" -eq 0 ] && [ -n "$EXPECTED_PLAN_SHA256" ]; then
  echo "Error: --expected-plan-sha256 is only valid with --apply." >&2
  exit 1
fi
if [ "$APPLY" -eq 1 ]; then
  if [ -z "$AUTHOR_NAME" ] || [ -z "$AUTHOR_EMAIL" ]; then
    echo "Error: --apply requires --author-name and --author-email." >&2
    exit 1
  fi
  if [[ "$AUTHOR_NAME" == *$'\n'* ]] \
    || [[ "$AUTHOR_NAME" == *$'\r'* ]] \
    || ! [[ "$AUTHOR_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]]; then
    echo "Error: commit author identity is invalid." >&2
    exit 1
  fi
elif [ -n "$AUTHOR_NAME" ] || [ -n "$AUTHOR_EMAIL" ]; then
  echo "Error: --author-name and --author-email are only valid with --apply." >&2
  exit 1
fi
if [ -n "$TARGET_ASKPASS" ] \
  && { [[ "$TARGET_ASKPASS" != /* ]] \
    || [ -L "$TARGET_ASKPASS" ] \
    || [ ! -f "$TARGET_ASKPASS" ] \
    || [ ! -x "$TARGET_ASKPASS" ]; }; then
  echo "Error: --git-askpass must name a physical executable by absolute path." >&2
  exit 1
fi
for slug in "${REPOSITORIES[@]}"; do
  if ! [[ "$slug" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Error: invalid GitHub repository slug: $slug" >&2
    exit 1
  fi
done
canonical_slug() {
  printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'
}
for ((repo_index = 0; repo_index < ${#REPOSITORIES[@]}; repo_index++)); do
  for ((other_index = repo_index + 1; other_index < ${#REPOSITORIES[@]}; other_index++)); do
    if [ "$(canonical_slug "${REPOSITORIES[$repo_index]}")" = \
      "$(canonical_slug "${REPOSITORIES[$other_index]}")" ]; then
      echo "Error: duplicate GitHub repository slug alias: ${REPOSITORIES[$repo_index]} and ${REPOSITORIES[$other_index]}" >&2
      exit 1
    fi
  done
done
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required." >&2
  exit 1
fi
if ! git check-ref-format --branch "$BRANCH" >/dev/null 2>&1; then
  echo "Error: --branch is not a valid Git branch name: $BRANCH" >&2
  exit 1
fi

source_git() (
  local git_variable
  for git_variable in "${!GIT_@}"; do
    unset "$git_variable"
  done
  export GIT_CONFIG=/dev/null
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_NO_REPLACE_OBJECTS=1
  git --no-replace-objects \
    -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false \
    "$@"
)

target_git() (
  local git_variable
  for git_variable in "${!GIT_@}"; do
    unset "$git_variable"
  done
  if [ "$APPLY" -eq 1 ]; then
    export GIT_AUTHOR_NAME="$AUTHOR_NAME"
    export GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"
    export GIT_COMMITTER_NAME="$AUTHOR_NAME"
    export GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"
  fi
  unset SSH_ASKPASS
  if [ -n "$TARGET_ASKPASS" ]; then
    export GIT_ASKPASS="$TARGET_ASKPASS"
  fi
  export GIT_CONFIG=/dev/null
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_NO_REPLACE_OBJECTS=1
  export GIT_TERMINAL_PROMPT=0
  git --no-replace-objects \
    -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false \
    "$@"
)

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | sed 's/[[:space:]].*$//'
  else
    shasum -a 256 "$1" | sed 's/[[:space:]].*$//'
  fi
}

sha256_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | sed 's/[[:space:]].*$//'
  else
    shasum -a 256 | sed 's/[[:space:]].*$//'
  fi
}

verify_release_source() {
  local actual
  local index_flags
  local status

  if [ -L "$SRC/.git" ] || [ ! -d "$SRC/.git" ]; then
    echo "Error: immutable bulk source must have a physical .git directory." >&2
    return 1
  fi
  actual="$(source_git -C "$SRC" rev-parse --verify 'HEAD^{commit}' 2>/dev/null || true)"
  if [ "$actual" != "$RELEASE_REF" ]; then
    echo "Error: bulk source HEAD $actual does not match expected release commit $RELEASE_REF." >&2
    return 1
  fi
  if source_git -C "$SRC" symbolic-ref --quiet HEAD >/dev/null 2>&1; then
    echo "Error: immutable bulk source must use detached HEAD at $RELEASE_REF." >&2
    return 1
  fi
  status="$(source_git -C "$SRC" status \
    --porcelain=v1 --untracked-files=all --ignored=matching)"
  if [ -n "$status" ]; then
    echo "Error: immutable bulk source must be clean before repository code executes." >&2
    return 1
  fi
  index_flags="$(source_git -C "$SRC" ls-files -v | sed -n '/^[a-zS]/p')"
  if [ -n "$index_flags" ]; then
    echo "Error: immutable bulk source has hidden index state; refusing execution." >&2
    return 1
  fi
  echo "=> Verified immutable bulk source at $RELEASE_REF (detached HEAD)."
}

materialize_release_source() {
  SOURCE_SNAPSHOT="$(mktemp -d /tmp/agents-ecosystem-bulk-source.XXXXXX)"
  # Clone into the existing private directory; releasing its name would let a
  # different user recreate and own the executable source snapshot in /tmp.
  source_git clone --quiet --no-hardlinks --no-checkout "$SRC" "$SOURCE_SNAPSHOT"
  source_git -C "$SOURCE_SNAPSHOT" checkout --quiet --detach "$RELEASE_REF"
  if [ -L "$SOURCE_SNAPSHOT/install.sh" ] \
    || [ ! -f "$SOURCE_SNAPSHOT/install.sh" ] \
    || [ ! -x "$SOURCE_SNAPSHOT/install.sh" ]; then
    echo "Error: immutable release must contain a physical executable install.sh." >&2
    return 1
  fi
}

ensure_plan_boundary() {
  local current=""
  local part
  local parent
  local -a parts

  IFS='/' read -r -a parts <<< "$PLAN_DIR"
  for part in "${parts[@]}"; do
    [ -n "$part" ] || continue
    if [ "$part" = "." ] || [ "$part" = ".." ]; then
      echo "Error: --plan-dir must be normalized: $PLAN_DIR" >&2
      return 1
    fi
    current="$current/$part"
    if [ -L "$current" ]; then
      echo "Error: --plan-dir must not cross a symlink: $current" >&2
      return 1
    fi
    if [ "$current" != "$PLAN_DIR" ] \
      && [ -e "$current" ] \
      && [ ! -d "$current" ]; then
      echo "Error: --plan-dir ancestor is not a directory: $current" >&2
      return 1
    fi
  done
  parent="$(dirname "$PLAN_DIR")"
  require_trusted_parent "$parent"
  if [ -L "$parent" ] || [ ! -d "$parent" ]; then
    echo "Error: --plan-dir parent must be a physical existing directory: $parent" >&2
    return 1
  fi
  if [ "$APPLY" -eq 1 ]; then
    if [ -L "$PLAN_DIR" ] || [ ! -d "$PLAN_DIR" ]; then
      echo "Error: apply requires a physical prepared plan directory: $PLAN_DIR" >&2
      return 1
    fi
  elif [ -e "$PLAN_DIR" ] || [ -L "$PLAN_DIR" ]; then
    echo "Error: preparation refuses to replace an existing plan path: $PLAN_DIR" >&2
    return 1
  else
    mkdir "$PLAN_DIR"
  fi
}

plan_repo_dir() {
  local slug="$1"
  local root="${2:-$PLAN_ROOT}"
  printf '%s/%s\n' "$root" "${slug//\//__}"
}

write_manifest() {
  local file="$1"
  local slug="$2"
  local base="$3"
  local base_sha="$4"
  local patch_sha="$5"

  printf '%s\n' \
    'format=agents-ecosystem-bulk-plan-v2' \
    'host=github.com' \
    "repository=$slug" \
    "base=$base" \
    "base_sha=$base_sha" \
    "branch=$BRANCH" \
    "source_sha=$RELEASE_REF" \
    "patch_sha256=$patch_sha" \
    'patch=changes.patch' > "$file"
}

manifest_value() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$file"
}

load_and_validate_manifest() {
  local repo_plan="$1"
  local requested_slug="$2"
  local manifest="$repo_plan/manifest.txt"
  local expected
  local actual

  if [ -L "$repo_plan" ] \
    || [ ! -d "$repo_plan" ] \
    || [ -L "$manifest" ] \
    || [ ! -f "$manifest" ] \
    || [ -L "$repo_plan/changes.patch" ] \
    || [ ! -f "$repo_plan/changes.patch" ]; then
    echo "Error: missing or unsafe prepared artifacts for $requested_slug." >&2
    return 1
  fi
  PLAN_HOST="$(manifest_value "$manifest" host)"
  PLAN_SLUG="$(manifest_value "$manifest" repository)"
  PLAN_BASE="$(manifest_value "$manifest" base)"
  PLAN_BASE_SHA="$(manifest_value "$manifest" base_sha)"
  PLAN_BRANCH="$(manifest_value "$manifest" branch)"
  PLAN_SOURCE_SHA="$(manifest_value "$manifest" source_sha)"
  PLAN_PATCH_SHA="$(manifest_value "$manifest" patch_sha256)"
  if [ "$PLAN_HOST" != "github.com" ] \
    || [ "$PLAN_SLUG" != "$requested_slug" ] \
    || ! [[ "$PLAN_BASE" =~ ^[A-Za-z0-9._/-]+$ ]] \
    || ! [[ "$PLAN_BASE_SHA" =~ ^[0-9a-f]{40}$ ]] \
    || [ "$PLAN_BRANCH" != "$BRANCH" ] \
    || [ "$PLAN_SOURCE_SHA" != "$RELEASE_REF" ] \
    || ! [[ "$PLAN_PATCH_SHA" =~ ^[0-9a-f]{64}$ ]] \
    || [ "$(manifest_value "$manifest" format)" != "agents-ecosystem-bulk-plan-v2" ] \
    || [ "$(manifest_value "$manifest" patch)" != "changes.patch" ]; then
    echo "Error: prepared manifest does not match the approved boundary for $requested_slug." >&2
    return 1
  fi
  expected="$(printf '%s\n' \
    'format=agents-ecosystem-bulk-plan-v2' \
    'host=github.com' \
    "repository=$PLAN_SLUG" \
    "base=$PLAN_BASE" \
    "base_sha=$PLAN_BASE_SHA" \
    "branch=$PLAN_BRANCH" \
    "source_sha=$RELEASE_REF" \
    "patch_sha256=$PLAN_PATCH_SHA" \
    'patch=changes.patch')"
  actual="$(<"$manifest")"
  if [ "$actual" != "$expected" ]; then
    echo "Error: prepared manifest has duplicate or unexpected fields for $requested_slug." >&2
    return 1
  fi
  if [ "$(sha256_file "$repo_plan/changes.patch")" != "$PLAN_PATCH_SHA" ]; then
    echo "Error: prepared patch digest mismatch for $requested_slug." >&2
    return 1
  fi
}

calculate_plan_digest() {
  local root="${1:-$PLAN_ROOT}"
  local slug
  local repo_plan
  local manifest_sha
  local patch_sha
  local diffstat_sha

  for slug in $(printf '%s\n' "${REPOSITORIES[@]}" | LC_ALL=C sort); do
    repo_plan="$(plan_repo_dir "$slug" "$root")"
    if [ -L "$repo_plan/manifest.txt" ] \
      || [ ! -f "$repo_plan/manifest.txt" ] \
      || [ -L "$repo_plan/changes.patch" ] \
      || [ ! -f "$repo_plan/changes.patch" ] \
      || [ -L "$repo_plan/diffstat.txt" ] \
      || [ ! -f "$repo_plan/diffstat.txt" ]; then
      echo "Error: incomplete plan artifacts for $slug." >&2
      return 1
    fi
    manifest_sha="$(sha256_file "$repo_plan/manifest.txt")"
    patch_sha="$(sha256_file "$repo_plan/changes.patch")"
    diffstat_sha="$(sha256_file "$repo_plan/diffstat.txt")"
    printf '%s manifest=%s patch=%s diffstat=%s\n' \
      "$slug" "$manifest_sha" "$patch_sha" "$diffstat_sha"
  done | sha256_stream
}

snapshot_and_verify_apply_plan() {
  local slug
  local source_repo
  local snapshot_repo
  local artifact
  local actual_plan_sha256

  APPLY_PLAN_SNAPSHOT="$(mktemp -d /tmp/agents-ecosystem-bulk-plan.XXXXXX)"
  for slug in "${REPOSITORIES[@]}"; do
    source_repo="$(plan_repo_dir "$slug" "$PLAN_DIR")"
    snapshot_repo="$(plan_repo_dir "$slug" "$APPLY_PLAN_SNAPSHOT")"
    if [ -L "$source_repo" ] || [ ! -d "$source_repo" ]; then
      echo "Error: missing or unsafe prepared artifacts for $slug." >&2
      return 1
    fi
    mkdir "$snapshot_repo"
    for artifact in manifest.txt changes.patch diffstat.txt; do
      if [ -L "$source_repo/$artifact" ] || [ ! -f "$source_repo/$artifact" ]; then
        echo "Error: incomplete or unsafe plan artifacts for $slug." >&2
        return 1
      fi
      cp -P "$source_repo/$artifact" "$snapshot_repo/$artifact"
    done
  done

  actual_plan_sha256="$(calculate_plan_digest "$APPLY_PLAN_SNAPSHOT")"
  if [ "$actual_plan_sha256" != "$EXPECTED_PLAN_SHA256" ]; then
    echo "Error: plan digest mismatch; expected $EXPECTED_PLAN_SHA256 but found $actual_plan_sha256." >&2
    return 1
  fi
  PLAN_ROOT="$APPLY_PLAN_SNAPSHOT"
  echo "=> Verified private plan snapshot at $EXPECTED_PLAN_SHA256."
}

prepare_one() {
  local slug="$1"
  local url="https://github.com/${slug}.git"
  local work="$2"
  local repo_plan
  local base
  local base_sha
  local patch_sha

  repo_plan="$(plan_repo_dir "$slug")"
  if [ -e "$repo_plan" ] || [ -L "$repo_plan" ]; then
    echo "Error: plan artifacts already exist for $slug: $repo_plan" >&2
    return 1
  fi
  mkdir "$repo_plan"
  target_git clone "$url" "$work/repo"
  cd "$work/repo"
  base="$(target_git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || true)"
  if [ -z "$base" ]; then
    echo "Error: target repository does not advertise a default branch: $slug" >&2
    return 1
  fi
  base_sha="$(target_git rev-parse --verify "refs/remotes/origin/$base^{commit}")"
  target_git checkout --quiet --detach "$base_sha"
  if [ -n "$(target_git status --porcelain --untracked-files=all --ignored=matching)" ]; then
    echo "Error: clone is not clean before installation: $slug" >&2
    return 1
  fi
  bash "$SOURCE_SNAPSHOT/install.sh" \
    --from-local "$SOURCE_SNAPSHOT" --ref "$RELEASE_REF"
  target_git add -A
  if target_git diff --cached --quiet; then
    echo "No changes for $slug (already installed?)."
  fi
  target_git diff --cached --binary --full-index --no-ext-diff \
    > "$repo_plan/changes.patch"
  patch_sha="$(sha256_file "$repo_plan/changes.patch")"
  write_manifest "$repo_plan/manifest.txt" "$slug" "$base" "$base_sha" "$patch_sha"
  target_git diff --cached --stat > "$repo_plan/diffstat.txt"
  echo "Prepared exact artifacts for $slug at $repo_plan"
  echo "  base: $base@$base_sha"
  echo "  patch sha256: $patch_sha"
  echo "  Review changes.patch; it can contain removed private-repository content."
}

apply_one() {
  local slug="$1"
  local url="https://github.com/${slug}.git"
  local work="$2"
  local repo_plan
  local current_base_sha
  local latest_base_sha
  local remote_base_sha
  local remote_feature_sha
  local resulting_patch_sha

  repo_plan="$(plan_repo_dir "$slug")"
  load_and_validate_manifest "$repo_plan" "$slug"
  target_git clone "$url" "$work/repo"
  cd "$work/repo"
  current_base_sha="$(target_git rev-parse --verify \
    "refs/remotes/origin/$PLAN_BASE^{commit}" 2>/dev/null || true)"
  if [ "$current_base_sha" != "$PLAN_BASE_SHA" ]; then
    echo "Error: $slug base drifted from $PLAN_BASE_SHA to ${current_base_sha:-missing}; prepare again." >&2
    return 1
  fi
  target_git checkout -b "$BRANCH" "$PLAN_BASE_SHA"
  target_git apply --index --whitespace=nowarn "$repo_plan/changes.patch"
  resulting_patch_sha="$(target_git diff --cached --binary --full-index --no-ext-diff | \
    { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; } | \
    sed 's/[[:space:]].*$//')"
  if [ "$resulting_patch_sha" != "$PLAN_PATCH_SHA" ]; then
    echo "Error: applied patch does not reproduce the prepared digest for $slug." >&2
    return 1
  fi
  if target_git diff --cached --quiet; then
    echo "No prepared changes to apply for $slug."
    return 0
  fi
  target_git commit -m "chore(agents): import Agents Ecosystem skills

Install the canonical .agents/skills source and register the available
tool adapters for this repository."
  target_git fetch --quiet --no-tags "$url" "refs/heads/$PLAN_BASE"
  latest_base_sha="$(target_git rev-parse --verify 'FETCH_HEAD^{commit}')"
  if [ "$latest_base_sha" != "$PLAN_BASE_SHA" ]; then
    echo "Error: $slug base drifted from $PLAN_BASE_SHA to $latest_base_sha before push; prepare again." >&2
    return 1
  fi
  if ! target_git push \
    "--force-with-lease=refs/heads/$BRANCH:" \
    "$url" \
    "$BRANCH:refs/heads/$BRANCH"; then
    remote_base_sha="$(target_git ls-remote "$url" \
      "refs/heads/$PLAN_BASE" | sed 's/[[:space:]].*$//')"
    remote_feature_sha="$(target_git ls-remote "$url" \
      "refs/heads/$BRANCH" | sed 's/[[:space:]].*$//')"
    if [ "$remote_base_sha" != "$PLAN_BASE_SHA" ]; then
      echo "Error: $slug base changed to ${remote_base_sha:-missing} before the push; the approved push did not complete." >&2
    elif [ -n "$remote_feature_sha" ]; then
      echo "Error: $slug already has $BRANCH at $remote_feature_sha; it was preserved and no PR was created." >&2
    else
      echo "Error: push failed for $slug; no approved remote update completed." >&2
    fi
    return 1
  fi
  if command -v gh >/dev/null 2>&1; then
    if ! env -u GH_REPO -u GH_HOST gh pr create \
      --repo "github.com/$slug" \
      --base "$PLAN_BASE" \
      --head "$BRANCH" \
      --title "chore(agents): import Agents Ecosystem skills" \
      --body "Applies the prepared Agents Ecosystem import from source $RELEASE_REF with patch digest $PLAN_PATCH_SHA."; then
      echo "Error: $BRANCH was pushed to $slug, but PR creation failed; the remote branch was retained for manual retry or cleanup." >&2
      return 1
    fi
  else
    echo "Pushed $BRANCH. Create a PR against $PLAN_BASE (gh not available)."
  fi
}

verify_release_source
ensure_plan_boundary
PLAN_ROOT="$PLAN_DIR"
if [ "$APPLY" -eq 0 ]; then
  materialize_release_source
else
  snapshot_and_verify_apply_plan
fi

failures=0
for slug in "${REPOSITORIES[@]}"; do
  work="$(mktemp -d /tmp/agents-ecosystem-bulk-work.XXXXXX)"
  echo ""
  echo "======== $slug ========"
  set +e
  if [ "$APPLY" -eq 1 ]; then
    (set -e; apply_one "$slug" "$work")
    operation_status="$?"
  else
    (set -e; prepare_one "$slug" "$work")
    operation_status="$?"
  fi
  set -e
  if [ "$operation_status" -ne 0 ]; then
    failures=$((failures + 1))
  fi
  cleanup_work "$work"
done

if [ "$failures" -gt 0 ]; then
  echo "Failed for $failures repo(s); inspect the per-repository output." >&2
  exit 1
fi
if [ "$APPLY" -eq 0 ]; then
  echo ""
  echo "Reviewed plan sha256: $(calculate_plan_digest)"
fi
