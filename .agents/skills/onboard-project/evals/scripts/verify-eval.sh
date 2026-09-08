#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: verify-eval.sh FIXTURE REPOSITORY STATE_DIR REPORT" >&2
  exit 1
fi

FIXTURE="$1"
REPOSITORY="$2"
STATE_DIR="$3"
REPORT="$4"

for git_variable in "${!GIT_@}"; do
  unset "$git_variable"
done
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_NO_REPLACE_OBJECTS=1
export GIT_OPTIONAL_LOCKS=0

safe_git() {
  GIT_CONFIG=/dev/null \
  GIT_ASKPASS=/usr/bin/false \
  GIT_TERMINAL_PROMPT=0 \
  SSH_ASKPASS=/usr/bin/false \
  SSH_ASKPASS_REQUIRE=never \
    git --no-replace-objects \
      -c core.hooksPath=/dev/null \
      -c core.fsmonitor=false \
      -c credential.helper= \
      "$@"
}

require_report_text() {
  local text="$1"
  if ! grep -Fqi -- "$text" "$REPORT"; then
    echo "Report is missing required evidence: $text" >&2
    return 1
  fi
}

manifest_value() {
  local expected_type="$1"
  local relative_path="$2"
  local value

  value="$(awk -F '\t' -v expected_type="$expected_type" -v relative_path="$relative_path" '
    $1 == expected_type && $2 == relative_path { print $3 }
  ' "$STATE_DIR/manifest.tsv")"
  if [ -z "$value" ] || [ "$(printf '%s\n' "$value" | wc -l)" -ne 1 ]; then
    echo "Fixture manifest is missing a unique $expected_type entry: $relative_path" >&2
    return 1
  fi
  printf '%s\n' "$value"
}

require_sha256_evidence() {
  local relative_path="$1"
  local expected_hash

  expected_hash="$(manifest_value file "$relative_path")"
  if ! grep -Fqx -- \
    "Evidence-SHA256: $relative_path $expected_hash" "$REPORT"; then
    echo "Report is missing exact SHA-256 evidence: $relative_path" >&2
    return 1
  fi
}

require_current_sha256_evidence() {
  local relative_path="$1"
  local path="$REPOSITORY/$relative_path"
  local expected_hash

  if [ -L "$path" ] || [ ! -f "$path" ]; then
    echo "Cannot bind report evidence to a physical file: $relative_path" >&2
    return 1
  fi
  expected_hash="$(sha256sum "$path" | cut -d ' ' -f 1)"
  if ! grep -Fqx -- \
    "Evidence-SHA256: $relative_path $expected_hash" "$REPORT"; then
    echo "Report is missing exact current SHA-256 evidence: $relative_path" >&2
    return 1
  fi
}

require_symlink_evidence() {
  local relative_path="$1"
  local expected_target

  expected_target="$(manifest_value symlink "$relative_path")"
  if ! grep -Fqx -- \
    "Evidence-Symlink: $relative_path $expected_target" "$REPORT"; then
    echo "Report is missing exact raw symlink evidence: $relative_path" >&2
    return 1
  fi
}

require_observed_claim() {
  local claim_id="$1"
  local relative_path="$2"
  local expected_value="$3"
  shift 3
  local expected_hash
  local source_path="$REPOSITORY/$relative_path"
  local required_fragment

  expected_hash="$(manifest_value file "$relative_path")"
  if [ -L "$source_path" ] || [ ! -f "$source_path" ]; then
    echo "Claim source is not a physical fixture file: $relative_path" >&2
    return 1
  fi
  for required_fragment in "$@"; do
    if ! grep -Fq -- "$required_fragment" "$source_path"; then
      echo "Fixture does not support claim $claim_id from $relative_path" >&2
      return 1
    fi
  done
  if ! grep -Fqx -- \
    "Evidence-Claim: $claim_id $relative_path $expected_hash $expected_value" \
    "$REPORT"; then
    echo "Report is missing or contradicts observed claim: $claim_id" >&2
    return 1
  fi
}

require_exact_diff() {
  local work_dir
  local patch_file
  local proposal_root
  work_dir="$(mktemp -d)"
  patch_file="$work_dir/proposal.diff"
  proposal_root="$work_dir/repository"

  if ! python3 - "$REPORT" "$patch_file" "$@" <<'PY'
import pathlib
import re
import sys

report_path = pathlib.Path(sys.argv[1])
patch_path = pathlib.Path(sys.argv[2])
expected_paths = set(sys.argv[3:])
lines = report_path.read_text(encoding="utf-8").splitlines()
starts = [index for index, line in enumerate(lines) if line == "```diff"]
if len(starts) != 1:
    raise SystemExit("report must contain exactly one fenced diff block")

start = starts[0]
try:
    end = lines.index("```", start + 1)
except ValueError as error:
    raise SystemExit("report diff block is not closed") from error

patch_lines = lines[start + 1 : end]
headers = [
    index for index, line in enumerate(patch_lines)
    if line.startswith("diff --git ")
]
if not headers:
    raise SystemExit("report diff block has no Git patch")

actual_paths = set()
for position, header_index in enumerate(headers):
    next_index = headers[position + 1] if position + 1 < len(headers) else len(patch_lines)
    section = patch_lines[header_index:next_index]
    match = re.fullmatch(r"diff --git a/([^\t ]+) b/([^\t ]+)", section[0])
    if match is None or match.group(1) != match.group(2):
        raise SystemExit("report diff contains an unsupported path header")
    relative_path = match.group(1)
    if relative_path.startswith("/") or ".." in pathlib.PurePosixPath(relative_path).parts:
        raise SystemExit("report diff contains an unsafe path")
    if section.count("--- /dev/null") != 1:
        raise SystemExit(f"report diff does not create {relative_path}")
    if section.count(f"+++ b/{relative_path}") != 1:
        raise SystemExit(f"report diff has the wrong destination for {relative_path}")
    if section.count("new file mode 100644") != 1:
        raise SystemExit(f"report diff does not create a regular 100644 document: {relative_path}")
    if not any(line.startswith("@@ ") for line in section):
        raise SystemExit(f"report diff has no hunk for {relative_path}")
    if relative_path in actual_paths:
        raise SystemExit(f"report diff repeats a target: {relative_path}")
    actual_paths.add(relative_path)

if actual_paths != expected_paths:
    raise SystemExit(
        f"report diff targets {sorted(actual_paths)}, expected {sorted(expected_paths)}"
    )

patch_path.write_text("\n".join(patch_lines) + "\n", encoding="utf-8")
PY
  then
    rm -rf "$work_dir"
    echo "Report is missing a valid exact unified diff" >&2
    return 1
  fi

  if ! safe_git -C "$REPOSITORY" \
    apply --check --whitespace=nowarn "$patch_file"; then
    rm -rf "$work_dir"
    echo "Report's exact unified diff does not apply to the fixture" >&2
    return 1
  fi
  mkdir "$proposal_root"
  cp -a "$REPOSITORY/." "$proposal_root/"
  if ! safe_git -C "$proposal_root" apply --whitespace=nowarn "$patch_file" \
    || ! python3 - "$FIXTURE" "$proposal_root" <<'PY'
import pathlib
import stat
import sys

fixture = sys.argv[1]
root = pathlib.Path(sys.argv[2])
contracts = {
    "sparse-python-service": {
        "AGENTS.md": ("Python", "pytest", "Laravel", "Nuxt", "not applicable"),
        "ARCHITECTURE.md": (
            "Python", "Adopted", "Laravel: Not applicable",
            "Nuxt: Not applicable", "Deployment: Unresolved",
        ),
    },
    "laravel-nuxt-stack": {
        "AGENTS.md": (
            "Laravel", "constructor injection", "Pest", "Nuxt",
            "Composition API", "Vitest", "dependency", "network",
        ),
        "ARCHITECTURE.md": (
            "Laravel", "Nuxt", "Adopted", "PostgreSQL", "Redis",
            "dependency", "network", "Deployment: Unresolved",
        ),
        "DESIGN.md": (
            "--background", "--foreground", "--primary", "--space-unit",
            "interaction", "component", "accessibility", "reduced motion",
        ),
    },
}

try:
    contract = contracts[fixture]
except KeyError as error:
    raise SystemExit(f"no proposal contract for {fixture}") from error

for relative, fragments in contract.items():
    path = root / relative
    mode = path.lstat().st_mode
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise SystemExit(f"proposed document is not a physical regular file: {relative}")
    text = path.read_text(encoding="utf-8").casefold()
    for fragment in fragments:
        if fragment.casefold() not in text:
            raise SystemExit(f"{relative} is missing required proposal meaning: {fragment}")
PY
  then
    rm -rf "$work_dir"
    echo "Report's exact diff lacks the fixture's minimal document semantics" >&2
    return 1
  fi
  rm -rf "$work_dir"
}

if [ -L "$STATE_DIR/manifest.tsv" ] || [ ! -f "$STATE_DIR/manifest.tsv" ] \
  || [ -L "$REPORT" ] || [ ! -f "$REPORT" ]; then
  echo "Missing fixture state or evaluation report" >&2
  exit 1
fi

while IFS=$'\t' read -r path_type relative_path expected_value; do
  path="$REPOSITORY/$relative_path"

  if [ "$FIXTURE" = "approved-readme-merge" ] \
    && [ "$relative_path" = "README.md" ]; then
    expected_value="$(sha256sum "$STATE_DIR/README.after.md" | cut -d ' ' -f 1)"
  fi

  case "$path_type" in
    file)
      if [ -L "$path" ] || [ ! -f "$path" ]; then
        echo "Expected regular file changed type or disappeared: $relative_path" >&2
        exit 1
      fi
      actual_value="$(sha256sum "$path" | cut -d ' ' -f 1)"
      ;;
    symlink)
      if [ ! -L "$path" ]; then
        echo "Expected symlink changed type or disappeared: $relative_path" >&2
        exit 1
      fi
      actual_value="$(readlink "$path")"
      ;;
    *)
      echo "Unknown manifest type: $path_type" >&2
      exit 1
      ;;
  esac

  if [ "$actual_value" != "$expected_value" ]; then
    echo "Fixture content changed unexpectedly: $relative_path" >&2
    exit 1
  fi
done < "$STATE_DIR/manifest.tsv"

if [ "$FIXTURE" = "approved-readme-merge" ]; then
  status="$(safe_git -C "$REPOSITORY" status --porcelain=v1 --untracked-files=all)"
  expected_status=$' M README.md\n?? .agents/project/onboarding/preservation-ledger.md'
  if [ "$status" != "$expected_status" ]; then
    echo "Approved evaluation changed paths outside README.md and its ledger: $status" >&2
    exit 1
  fi
  ledger="$REPOSITORY/.agents/project/onboarding/preservation-ledger.md"
  if [ -L "$ledger" ] || [ ! -f "$ledger" ]; then
    echo "Approved evaluation did not create a physical preservation ledger" >&2
    exit 1
  fi
  for ledger_item in "README.md" "badge" "operator" "setup" "license" "import"; do
    if ! grep -Fqi -- "$ledger_item" "$ledger"; then
      echo "Preservation ledger is missing: $ledger_item" >&2
      exit 1
    fi
  done
  require_report_text "Gate: applied-approved-patch"
  require_report_text "Mutation: approved-only"
  require_report_text "exact unified diff"
  require_report_text "badge"
  require_report_text "setup"
  require_report_text "license"
  require_report_text "preservation ledger"
  require_current_sha256_evidence "README.md"
  require_current_sha256_evidence ".agents/project/onboarding/preservation-ledger.md"
  require_sha256_evidence ".agents/templates/README.md"
  exit 0
fi

if ! diff -u \
  "$STATE_DIR/git-status.txt" \
  <(safe_git -C "$REPOSITORY" status --porcelain=v1 --untracked-files=all); then
  echo "Pre-approval Git state changed" >&2
  exit 1
fi

require_report_text "Mutation: none"
require_report_text "approval"

case "$FIXTURE" in
  sparse-python-service|laravel-nuxt-stack)
    require_report_text "Gate: combined-proposal"
    require_report_text "exact unified diff"
    require_report_text "one combined approval"
    ;;
  *)
    require_report_text "Gate: merge-plan-only"
    ;;
esac

case "$FIXTURE" in
  mature-monorepo)
    require_report_text "README.md"
    require_report_text "packages/api/AGENTS.md"
    require_report_text "badge"
    require_report_text "setup"
    require_report_text "license"
    require_report_text "deferred-conflict"
    require_sha256_evidence "README.md"
    require_sha256_evidence "packages/api/AGENTS.md"
    require_sha256_evidence ".agents/templates/README.md"
    require_observed_claim "public-package-manager" "package.json" "npm" \
      '"test": "npm --workspaces test"'
    require_observed_claim "candidate-package-manager" ".agents/templates/AGENTS.md" \
      "pnpm" "Prefer pnpm"
    ;;
  sparse-python-service)
    require_report_text "AGENTS.md"
    require_report_text "ARCHITECTURE.md"
    require_report_text "Laravel"
    require_report_text "Nuxt"
    require_report_text "deployment"
    require_report_text "unresolved"
    if ! grep -Eqi -- 'inapplicable|not applicable' "$REPORT"; then
      echo "Report is missing required evidence: component marked not applicable" >&2
      exit 1
    fi
    require_sha256_evidence "pyproject.toml"
    require_sha256_evidence "src/ledger_service.py"
    require_sha256_evidence ".agents/templates/AGENTS.md"
    require_sha256_evidence ".agents/templates/ARCHITECTURE.md"
    require_observed_claim "python-runtime" "pyproject.toml" "python>=3.12" \
      'requires-python = ">=3.12"'
    require_observed_claim "service-language" "src/ledger_service.py" "Python" \
      "def health()"
    require_exact_diff "AGENTS.md" "ARCHITECTURE.md"
    ;;
  conflicting-deployment)
    require_report_text "AWS"
    require_report_text "Azure"
    require_report_text "deferred-conflict"
    if ! grep -Eqi -- 'dirty|uncommitted' "$REPORT"; then
      echo "Report is missing required evidence: dirty or uncommitted target" >&2
      exit 1
    fi
    require_report_text "ARCHITECTURE.md"
    require_report_text "docs/architecture.md"
    require_report_text "symlink"
    require_sha256_evidence "AGENTS.md"
    require_sha256_evidence "README.md"
    require_sha256_evidence ".github/workflows/deploy.yml"
    require_sha256_evidence "docs/architecture.md"
    require_symlink_evidence "ARCHITECTURE.md"
    require_observed_claim "deployment-intent" "README.md" "AWS" \
      "Production deploys to AWS ECS"
    require_observed_claim "deployment-execution" ".github/workflows/deploy.yml" \
      "Azure" "az containerapp update"
    ;;
  laravel-nuxt-stack)
    require_report_text "Laravel"
    require_report_text "Nuxt"
    require_report_text "Vue"
    require_report_text "PostgreSQL"
    require_report_text "Redis"
    require_report_text "ARCHITECTURE.md"
    require_report_text "adapt"
    require_report_text "deployment"
    require_report_text "unresolved"
    require_report_text "dependency"
    require_report_text "network"
    require_report_text "interaction"
    require_report_text "token"
    require_report_text "component"
    require_report_text "accessibility"
    require_report_text "motion"
    require_sha256_evidence "composer.json"
    require_sha256_evidence "config/cache.php"
    require_sha256_evidence "config/database.php"
    require_sha256_evidence "frontend/package.json"
    require_sha256_evidence "frontend/nuxt.config.ts"
    require_sha256_evidence "frontend/app/assets/css/main.css"
    require_sha256_evidence ".agents/templates/AGENTS.md"
    require_sha256_evidence ".agents/templates/ARCHITECTURE.md"
    require_sha256_evidence ".agents/templates/DESIGN.md"
    require_observed_claim "backend-framework" "composer.json" "Laravel-13" \
      '"laravel/framework": "^13.0"'
    require_observed_claim "frontend-frameworks" "frontend/package.json" \
      "Nuxt-4,Vue-3" '"nuxt": "^4.0.0"' '"vue": "^3.5.0"'
    require_observed_claim "database" "config/database.php" "PostgreSQL" \
      "'driver' => 'pgsql'"
    require_observed_claim "cache" "config/cache.php" "Redis" \
      "'driver' => 'redis'"
    require_observed_claim "css-tokens" "frontend/app/assets/css/main.css" \
      "background,foreground,primary,space-unit" \
      "--background" "--foreground" "--primary" "--space-unit"
    require_observed_claim "reduced-motion" "frontend/app/assets/css/main.css" \
      "present" "prefers-reduced-motion"
    require_exact_diff "AGENTS.md" "ARCHITECTURE.md" "DESIGN.md"
    ;;
  *)
    echo "Unknown pre-approval fixture: $FIXTURE" >&2
    exit 1
    ;;
esac
