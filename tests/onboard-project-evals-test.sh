#!/usr/bin/env bash

set -euo pipefail
umask 022

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVAL_ROOT="$REPO_ROOT/.agents/skills/onboard-project/evals"
CREATE_FIXTURE="$EVAL_ROOT/scripts/create-fixture.sh"
VERIFY_EVAL="$EVAL_ROOT/scripts/verify-eval.sh"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

for required in "$EVAL_ROOT/evals.json" "$CREATE_FIXTURE" "$VERIFY_EVAL"; do
  [ -f "$required" ] && [ ! -L "$required" ] || {
    echo "Onboarding eval input must be a physical file: $required" >&2
    exit 1
  }
done
[ ! -e "$EVAL_ROOT/evidence" ] && [ ! -L "$EVAL_ROOT/evidence" ] || {
  echo "Deterministic onboarding evals must not depend on captured evidence" >&2
  exit 1
}

ambient_template="$TEST_ROOT/ambient-git-template"
ambient_config="$TEST_ROOT/ambient-gitconfig"
ambient_hook_marker="$TEST_ROOT/ambient-hook-ran"
mkdir -p "$ambient_template/hooks"
cat > "$ambient_template/hooks/pre-commit" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
: > "$ONBOARD_EVAL_AMBIENT_HOOK_MARKER"
HOOK
chmod +x "$ambient_template/hooks/pre-commit"
git config --file "$ambient_config" init.templateDir "$ambient_template"
GIT_CONFIG_GLOBAL="$ambient_config" \
ONBOARD_EVAL_AMBIENT_HOOK_MARKER="$ambient_hook_marker" \
  bash "$CREATE_FIXTURE" \
    sparse-python-service \
    "$TEST_ROOT/ambient-fixture" \
    "$TEST_ROOT/ambient-fixture-state" >/dev/null
if [ -e "$ambient_hook_marker" ]; then
  echo "Onboarding fixture creation executed an ambient Git template hook" >&2
  exit 1
fi

fixtures=(
  mature-monorepo
  sparse-python-service
  conflicting-deployment
  approved-readme-merge
  laravel-nuxt-stack
)
for fixture in "${fixtures[@]}"; do
  bash "$CREATE_FIXTURE" \
    "$fixture" "$TEST_ROOT/$fixture" "$TEST_ROOT/$fixture-state" >/dev/null
  git -C "$TEST_ROOT/$fixture" rev-parse --verify HEAD >/dev/null
done

[ -f "$TEST_ROOT/mature-monorepo/packages/api/AGENTS.md" ]
[ -L "$TEST_ROOT/conflicting-deployment/ARCHITECTURE.md" ]
[ "$(readlink "$TEST_ROOT/conflicting-deployment/ARCHITECTURE.md")" = \
  "docs/architecture.md" ]
git -C "$TEST_ROOT/conflicting-deployment" status --short \
  | grep -q '^ M AGENTS.md$'
[ -f "$TEST_ROOT/laravel-nuxt-stack/artisan" ]
[ -f "$TEST_ROOT/laravel-nuxt-stack/composer.json" ]
[ -f "$TEST_ROOT/laravel-nuxt-stack/frontend/nuxt.config.ts" ]
[ -f "$TEST_ROOT/laravel-nuxt-stack/frontend/package.json" ]
[ ! -e "$TEST_ROOT/sparse-python-service/.agents/templates/profiles" ]
[ ! -e "$TEST_ROOT/laravel-nuxt-stack/.agents/templates/profiles" ]

write_report() {
  local path="$1"
  shift
  printf '%s\n' "$@" > "$path"
}

append_hash_evidence() {
  local report="$1"
  local state_dir="$2"
  shift 2

  local relative_path
  local expected_hash
  for relative_path in "$@"; do
    expected_hash="$(awk -F '\t' -v relative_path="$relative_path" '
      $1 == "file" && $2 == relative_path { print $3 }
    ' "$state_dir/manifest.tsv")"
    [ -n "$expected_hash" ] || {
      echo "Missing fixture hash for test evidence: $relative_path" >&2
      exit 1
    }
    printf 'Evidence-SHA256: %s %s\n' \
      "$relative_path" "$expected_hash" >> "$report"
  done
}

append_claim() {
  local report="$1"
  local state_dir="$2"
  local claim_id="$3"
  local relative_path="$4"
  local value="$5"
  local expected_hash

  expected_hash="$(awk -F '\t' -v relative_path="$relative_path" '
    $1 == "file" && $2 == relative_path { print $3 }
  ' "$state_dir/manifest.tsv")"
  [ -n "$expected_hash" ] || {
    echo "Missing fixture hash for test claim: $relative_path" >&2
    exit 1
  }
  printf 'Evidence-Claim: %s %s %s %s\n' \
    "$claim_id" "$relative_path" "$expected_hash" "$value" >> "$report"
}

append_current_hash_evidence() {
  local report="$1"
  local repository="$2"
  shift 2

  local relative_path
  for relative_path in "$@"; do
    printf 'Evidence-SHA256: %s %s\n' \
      "$relative_path" \
      "$(sha256sum "$repository/$relative_path" | cut -d ' ' -f 1)" \
      >> "$report"
  done
}

append_symlink_evidence() {
  local report="$1"
  local state_dir="$2"
  local relative_path="$3"
  local expected_target

  expected_target="$(awk -F '\t' -v relative_path="$relative_path" '
    $1 == "symlink" && $2 == relative_path { print $3 }
  ' "$state_dir/manifest.tsv")"
  [ -n "$expected_target" ] || {
    echo "Missing fixture symlink for test evidence: $relative_path" >&2
    exit 1
  }
  printf 'Evidence-Symlink: %s %s\n' \
    "$relative_path" "$expected_target" >> "$report"
}

append_sparse_diff() {
  local report="$1"
  printf '%s\n' \
    '```diff' \
    'diff --git a/AGENTS.md b/AGENTS.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/AGENTS.md' \
    '@@ -0,0 +1,3 @@' \
    '+# Agent Guidance' \
    '+This Python service uses pytest.' \
    '+Laravel and Nuxt are not applicable.' \
    'diff --git a/ARCHITECTURE.md b/ARCHITECTURE.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/ARCHITECTURE.md' \
    '@@ -0,0 +1,5 @@' \
    '+# Architecture' \
    '+Python service: Adopted.' \
    '+Laravel: Not applicable.' \
    '+Nuxt: Not applicable.' \
    '+Deployment: Unresolved.' \
    '```' >> "$report"
}

append_sparse_heading_diff() {
  local report="$1"
  printf '%s\n' \
    '```diff' \
    'diff --git a/AGENTS.md b/AGENTS.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/AGENTS.md' \
    '@@ -0,0 +1 @@' \
    '+# Agent Guidance' \
    'diff --git a/ARCHITECTURE.md b/ARCHITECTURE.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/ARCHITECTURE.md' \
    '@@ -0,0 +1 @@' \
    '+# Architecture' \
    '```' >> "$report"
}

append_sparse_symlink_diff() {
  local report="$1"
  printf '%s\n' \
    '```diff' \
    'diff --git a/AGENTS.md b/AGENTS.md' \
    'new file mode 120000' \
    '--- /dev/null' \
    '+++ b/AGENTS.md' \
    '@@ -0,0 +1 @@' \
    '+agent-target' \
    '\ No newline at end of file' \
    'diff --git a/ARCHITECTURE.md b/ARCHITECTURE.md' \
    'new file mode 120000' \
    '--- /dev/null' \
    '+++ b/ARCHITECTURE.md' \
    '@@ -0,0 +1 @@' \
    '+architecture-target' \
    '\ No newline at end of file' \
    '```' >> "$report"
}

append_stack_diff() {
  local report="$1"
  printf '%s\n' \
    '```diff' \
    'diff --git a/AGENTS.md b/AGENTS.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/AGENTS.md' \
    '@@ -0,0 +1,4 @@' \
    '+# Agent Guidance' \
    '+Laravel controllers use constructor injection and Pest.' \
    '+Nuxt uses Vue Composition API and Vitest.' \
    '+Dependency and network changes require approval.' \
    'diff --git a/ARCHITECTURE.md b/ARCHITECTURE.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/ARCHITECTURE.md' \
    '@@ -0,0 +1,5 @@' \
    '+# Architecture' \
    '+Laravel API and Nuxt UI are Adopted.' \
    '+PostgreSQL and Redis are Adopted.' \
    '+Dependency and network boundaries remain explicit.' \
    '+Deployment: Unresolved.' \
    'diff --git a/DESIGN.md b/DESIGN.md' \
    'new file mode 100644' \
    '--- /dev/null' \
    '+++ b/DESIGN.md' \
    '@@ -0,0 +1,5 @@' \
    '+# Design' \
    '+Tokens: --background --foreground --primary --space-unit.' \
    '+Document interaction and component states.' \
    '+Meet accessibility requirements.' \
    '+Honor reduced motion.' \
    '```' >> "$report"
}

mature_report="$TEST_ROOT/mature-report.md"
write_report "$mature_report" \
  '# R3 onboarding proposal' \
  'README.md and packages/api/AGENTS.md preserve the badge, setup, and license.' \
  'Conflicting package-manager meaning is a deferred-conflict requiring approval.' \
  'Gate: merge-plan-only' \
  'Mutation: none'
append_hash_evidence "$mature_report" "$TEST_ROOT/mature-monorepo-state" \
  "README.md" "packages/api/AGENTS.md" ".agents/templates/README.md"
append_claim "$mature_report" "$TEST_ROOT/mature-monorepo-state" \
  "public-package-manager" "package.json" "npm"
append_claim "$mature_report" "$TEST_ROOT/mature-monorepo-state" \
  "candidate-package-manager" ".agents/templates/AGENTS.md" "pnpm"
bash "$VERIFY_EVAL" mature-monorepo \
  "$TEST_ROOT/mature-monorepo" "$TEST_ROOT/mature-monorepo-state" \
  "$mature_report"

sparse_report="$TEST_ROOT/sparse-report.md"
write_report "$sparse_report" \
  '# R2 onboarding proposal' \
  'AGENTS.md and ARCHITECTURE.md are shown as one exact unified diff.' \
  'Laravel and Nuxt are not applicable; deployment remains unresolved.' \
  'Request one combined approval.' \
  'Gate: combined-proposal' \
  'Mutation: none'
append_hash_evidence "$sparse_report" "$TEST_ROOT/sparse-python-service-state" \
  "pyproject.toml" "src/ledger_service.py" ".agents/templates/AGENTS.md" \
  ".agents/templates/ARCHITECTURE.md"
append_claim "$sparse_report" "$TEST_ROOT/sparse-python-service-state" \
  "python-runtime" "pyproject.toml" "python>=3.12"
append_claim "$sparse_report" "$TEST_ROOT/sparse-python-service-state" \
  "service-language" "src/ledger_service.py" "Python"
append_sparse_diff "$sparse_report"
bash "$VERIFY_EVAL" sparse-python-service \
  "$TEST_ROOT/sparse-python-service" "$TEST_ROOT/sparse-python-service-state" \
  "$sparse_report"

keyword_only_report="$TEST_ROOT/keyword-only-report.md"
write_report "$keyword_only_report" \
  '# Keyword-only false evidence' \
  'AGENTS.md and ARCHITECTURE.md are shown as one exact unified diff.' \
  'Laravel and Nuxt are not applicable; deployment remains unresolved.' \
  'Request one combined approval.' \
  'Gate: combined-proposal' \
  'Mutation: none'
if bash "$VERIFY_EVAL" sparse-python-service \
  "$TEST_ROOT/sparse-python-service" "$TEST_ROOT/sparse-python-service-state" \
  "$keyword_only_report" >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted keyword-only evidence" >&2
  exit 1
fi

prose_diff_report="$TEST_ROOT/prose-diff-report.md"
cp "$keyword_only_report" "$prose_diff_report"
append_hash_evidence "$prose_diff_report" "$TEST_ROOT/sparse-python-service-state" \
  "pyproject.toml" "src/ledger_service.py" ".agents/templates/AGENTS.md" \
  ".agents/templates/ARCHITECTURE.md"
if bash "$VERIFY_EVAL" sparse-python-service \
  "$TEST_ROOT/sparse-python-service" "$TEST_ROOT/sparse-python-service-state" \
  "$prose_diff_report" >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted prose in place of an exact diff" >&2
  exit 1
fi

heading_only_report="$TEST_ROOT/heading-only-report.md"
cp "$prose_diff_report" "$heading_only_report"
append_claim "$heading_only_report" "$TEST_ROOT/sparse-python-service-state" \
  "python-runtime" "pyproject.toml" "python>=3.12"
append_claim "$heading_only_report" "$TEST_ROOT/sparse-python-service-state" \
  "service-language" "src/ledger_service.py" "Python"
append_sparse_heading_diff "$heading_only_report"
if bash "$VERIFY_EVAL" sparse-python-service \
  "$TEST_ROOT/sparse-python-service" "$TEST_ROOT/sparse-python-service-state" \
  "$heading_only_report" >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted behavior-free candidate documents" >&2
  exit 1
fi

symlink_mode_report="$TEST_ROOT/symlink-mode-report.md"
cp "$prose_diff_report" "$symlink_mode_report"
append_claim "$symlink_mode_report" "$TEST_ROOT/sparse-python-service-state" \
  "python-runtime" "pyproject.toml" "python>=3.12"
append_claim "$symlink_mode_report" "$TEST_ROOT/sparse-python-service-state" \
  "service-language" "src/ledger_service.py" "Python"
append_sparse_symlink_diff "$symlink_mode_report"
if bash "$VERIFY_EVAL" sparse-python-service \
  "$TEST_ROOT/sparse-python-service" "$TEST_ROOT/sparse-python-service-state" \
  "$symlink_mode_report" >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted symlink-mode project documents" >&2
  exit 1
fi

conflict_report="$TEST_ROOT/conflict-report.md"
write_report "$conflict_report" \
  '# Conflict-aware onboarding report' \
  'AWS intent conflicts with Azure workflow evidence: deferred-conflict.' \
  'Dirty uncommitted AGENTS.md blocks changes pending approval.' \
  'ARCHITECTURE.md remains a symlink to docs/architecture.md.' \
  'Gate: merge-plan-only' \
  'Mutation: none'
append_hash_evidence "$conflict_report" "$TEST_ROOT/conflicting-deployment-state" \
  "AGENTS.md" "README.md" ".github/workflows/deploy.yml" \
  "docs/architecture.md"
append_symlink_evidence "$conflict_report" \
  "$TEST_ROOT/conflicting-deployment-state" "ARCHITECTURE.md"
append_claim "$conflict_report" "$TEST_ROOT/conflicting-deployment-state" \
  "deployment-intent" "README.md" "AWS"
append_claim "$conflict_report" "$TEST_ROOT/conflicting-deployment-state" \
  "deployment-execution" ".github/workflows/deploy.yml" "Azure"
bash "$VERIFY_EVAL" conflicting-deployment \
  "$TEST_ROOT/conflicting-deployment" "$TEST_ROOT/conflicting-deployment-state" \
  "$conflict_report"

reversed_conflict_report="$TEST_ROOT/reversed-conflict-report.md"
cp "$conflict_report" "$reversed_conflict_report"
sed -i 's/ AWS$/ Azure/' "$reversed_conflict_report"
if bash "$VERIFY_EVAL" conflicting-deployment \
  "$TEST_ROOT/conflicting-deployment" "$TEST_ROOT/conflicting-deployment-state" \
  "$reversed_conflict_report" >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted reversed deployment attribution" >&2
  exit 1
fi

stack_report="$TEST_ROOT/laravel-nuxt-report.md"
write_report "$stack_report" \
  '# Laravel/Nuxt R2 onboarding proposal' \
  'Repository evidence identifies Laravel, Nuxt, Vue, PostgreSQL, and Redis.' \
  'ARCHITECTURE.md components adapt without assumed versions.' \
  'Deployment stays unresolved; dependency and network policies require approval.' \
  'The component ledger covers interaction state, token, component, accessibility, and motion policy.' \
  'Present one combined approval with the exact unified diff.' \
  'Gate: combined-proposal' \
  'Mutation: none'
append_hash_evidence "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "composer.json" "config/cache.php" "config/database.php" \
  "frontend/package.json" "frontend/nuxt.config.ts" \
  "frontend/app/assets/css/main.css" ".agents/templates/AGENTS.md" \
  ".agents/templates/ARCHITECTURE.md" ".agents/templates/DESIGN.md"
append_claim "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "backend-framework" "composer.json" "Laravel-13"
append_claim "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "frontend-frameworks" "frontend/package.json" "Nuxt-4,Vue-3"
append_claim "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "database" "config/database.php" "PostgreSQL"
append_claim "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "cache" "config/cache.php" "Redis"
append_claim "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "css-tokens" "frontend/app/assets/css/main.css" \
  "background,foreground,primary,space-unit"
append_claim "$stack_report" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "reduced-motion" "frontend/app/assets/css/main.css" "present"
append_stack_diff "$stack_report"
bash "$VERIFY_EVAL" laravel-nuxt-stack \
  "$TEST_ROOT/laravel-nuxt-stack" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "$stack_report"

negated_css_report="$TEST_ROOT/negated-css-report.md"
cp "$stack_report" "$negated_css_report"
sed -i 's/ present$/ absent/' "$negated_css_report"
if bash "$VERIFY_EVAL" laravel-nuxt-stack \
  "$TEST_ROOT/laravel-nuxt-stack" "$TEST_ROOT/laravel-nuxt-stack-state" \
  "$negated_css_report" >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted a negated CSS evidence claim" >&2
  exit 1
fi

cp "$TEST_ROOT/approved-readme-merge-state/README.after.md" \
  "$TEST_ROOT/approved-readme-merge/README.md"
mkdir -p "$TEST_ROOT/approved-readme-merge/.agents/project/onboarding"
ledger="$TEST_ROOT/approved-readme-merge/.agents/project/onboarding/preservation-ledger.md"
write_report "$ledger" \
  '# Preservation ledger' \
  '| Origin | Meaning | Disposition |' \
  '|---|---|---|' \
  '| README.md | badge | unchanged |' \
  '| README.md | operator guide link | unchanged |' \
  '| README.md | setup command | unchanged |' \
  '| README.md | license | unchanged |' \
  '| .agents/templates/README.md | product context | import |'
approved_report="$TEST_ROOT/approved-report.md"
write_report "$approved_report" \
  '# Onboarding completion' \
  'The exact unified diff was approved and applied.' \
  'Badge, setup, license, and preservation ledger dispositions are recorded.' \
  'Gate: applied-approved-patch' \
  'Mutation: approved-only'
append_current_hash_evidence "$approved_report" \
  "$TEST_ROOT/approved-readme-merge" \
  "README.md" ".agents/project/onboarding/preservation-ledger.md"
append_hash_evidence "$approved_report" \
  "$TEST_ROOT/approved-readme-merge-state" ".agents/templates/README.md"
bash "$VERIFY_EVAL" approved-readme-merge \
  "$TEST_ROOT/approved-readme-merge" \
  "$TEST_ROOT/approved-readme-merge-state" "$approved_report"

printf 'unauthorized\n' > "$TEST_ROOT/approved-readme-merge/unapproved.txt"
if bash "$VERIFY_EVAL" approved-readme-merge \
  "$TEST_ROOT/approved-readme-merge" \
  "$TEST_ROOT/approved-readme-merge-state" "$approved_report" \
  >/dev/null 2>&1; then
  echo "Onboarding evaluator accepted an unapproved extra path" >&2
  exit 1
fi

python3 - "$EVAL_ROOT/evals.json" <<'PY'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert data["skill_name"] == "onboard-project"
expected = {
    "mature-monorepo",
    "sparse-python-service",
    "conflicting-deployment",
    "approved-readme-merge",
    "laravel-nuxt-stack",
}
actual = set()
for case in data["evals"]:
    assert case.get("files"), case["id"]
    assert case.get("expectations"), case["id"]
    for path in case["files"]:
        actual.add(path.rsplit("/", 1)[-1])
assert actual == expected, (actual, expected)
assert "tomfit-stack" not in json.dumps(data).lower()
PY

echo "Onboard-project deterministic fixture and verifier tests passed"
