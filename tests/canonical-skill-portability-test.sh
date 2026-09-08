#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_SCRIPT="$REPO_ROOT/scripts/audit-skill-portability.sh"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

if [ ! -x "$AUDIT_SCRIPT" ]; then
  echo "Portability audit script is missing or not executable: $AUDIT_SCRIPT" >&2
  exit 1
fi

write_skill() {
  local root="$1"
  local body="$2"

  mkdir -p "$root/example"
  printf '%s\n' \
    '---' \
    'name: example' \
    'description: Portability audit fixture' \
    '---' \
    '' \
    "$body" > "$root/example/SKILL.md"
}

write_skill_with_metadata() {
  local root="$1"
  local metadata="$2"

  mkdir -p "$root/example"
  printf '%s\n' \
    '---' \
    'name: example' \
    'description: Portability audit fixture' \
    "$metadata" \
    '---' \
    '' \
    'Inspect the repository and run relevant checks.' \
    > "$root/example/SKILL.md"
}

assert_violation() {
  local category="$1"
  local body="$2"
  local fixture="$TEST_ROOT/$category"
  local output

  write_skill "$fixture" "$body"
  if output="$(bash "$AUDIT_SCRIPT" "$fixture" 2>&1)"; then
    echo "Audit accepted a $category violation" >&2
    return 1
  fi

  grep -Fq "[$category]" <<< "$output"
  grep -Fq 'example/SKILL.md' <<< "$output"
}

assert_non_markdown_violation() {
  local category="$1"
  local relative_path="$2"
  local body="$3"
  local fixture="$TEST_ROOT/non-markdown-$category"
  local output

  mkdir -p "$fixture/example/$(dirname "$relative_path")"
  printf '%s\n' "$body" > "$fixture/example/$relative_path"
  if output="$(bash "$AUDIT_SCRIPT" "$fixture" 2>&1)"; then
    echo "Audit accepted a $category violation in $relative_path" >&2
    return 1
  fi

  grep -Fq "[$category]" <<< "$output"
  grep -Fq "example/$relative_path" <<< "$output"
}

assert_metadata_violation() {
  local category="$1"
  local metadata="$2"
  local fixture="$TEST_ROOT/$category"
  local output

  write_skill_with_metadata "$fixture" "$metadata"
  if output="$(bash "$AUDIT_SCRIPT" "$fixture" 2>&1)"; then
    echo "Audit accepted a $category violation" >&2
    return 1
  fi

  grep -Fq "[$category]" <<< "$output"
  grep -Fq 'example/SKILL.md' <<< "$output"
}

neutral_fixture="$TEST_ROOT/neutral"
write_skill \
  "$neutral_fixture" \
  'Inspect the repository, ask the user for missing decisions, and run relevant checks.'
bash "$AUDIT_SCRIPT" "$neutral_fixture" >/dev/null

assert_metadata_violation \
  'provider-permission-metadata' \
  'allowed-tools:'
for metadata_key in \
  preamble-tier \
  version \
  triggers \
  user-invocable \
  argument-hint \
  disable-model-invocation; do
  assert_metadata_violation \
    'provider-host-metadata' \
    "$metadata_key: true"
done
assert_metadata_violation \
  'provider-host-metadata' \
  $'metadata:\n  preamble-tier: 3'

portable_metadata_fixture="$TEST_ROOT/portable-metadata"
write_skill_with_metadata \
  "$portable_metadata_fixture" \
  $'metadata:\n  version: 1.0.0'
bash "$AUDIT_SCRIPT" "$portable_metadata_fixture" >/dev/null
assert_violation \
  'concrete-tool-api' \
  'Call AskUserQuestion before continuing.'
assert_violation \
  'slash-command-invocation' \
  'Run /review before merging.'
assert_violation \
  'provider-discovery-path' \
  'Install this skill under ~/.claude/skills.'
assert_violation \
  'provider-runtime-assumption' \
  'Use the Antigravity-specific workflow.'
assert_violation \
  'provider-runtime-assumption' \
  'Run claude-with-access-to-the-skill for every prompt.'
assert_violation \
  'concrete-tool-api' \
  'Verify the installed framework API with search-docs before continuing.'
assert_violation \
  'provider-runtime-assumption' \
  'Always use a sub-agent to inspect the framework rules.'

single_agent_fixture="$TEST_ROOT/single-agent-fallback"
write_skill \
  "$single_agent_fixture" \
  'Inspect framework rules with parallel agents when available; otherwise read the relevant local files inline. Verify APIs from installed-version sources or official documentation using available read or research capabilities.'
bash "$AUDIT_SCRIPT" "$single_agent_fixture" >/dev/null
assert_non_markdown_violation \
  'concrete-tool-api' \
  'instructions.txt' \
  'Call AskUserQuestion before continuing.'
assert_non_markdown_violation \
  'provider-runtime-assumption' \
  'SKILL.md.tmpl' \
  'Use Claude Code to complete this workflow.'
assert_non_markdown_violation \
  'provider-runtime-assumption' \
  'RUNBOOK' \
  'Use Codex to complete this workflow.'

formerly_excluded_fixture="$TEST_ROOT/formerly-excluded"
mkdir -p "$formerly_excluded_fixture/start-project"
printf '%s\n' \
  '---' \
  'name: start-project' \
  'description: Former exclusion fixture' \
  '---' \
  '' \
  'Call AskUserQuestion before continuing.' \
  > "$formerly_excluded_fixture/start-project/SKILL.md"
if bash "$AUDIT_SCRIPT" "$formerly_excluded_fixture" >/dev/null 2>&1; then
  echo "Audit silently excluded a canonical skill from portability checks" >&2
  exit 1
fi

retained_evidence_fixture="$TEST_ROOT/retained-evidence"
write_skill \
  "$retained_evidence_fixture" \
  'Inspect the repository and run relevant checks.'
mkdir -p "$retained_evidence_fixture/example/evals/evidence/legacy"
printf '%s\n' 'Historical output invoked /review.' \
  > "$retained_evidence_fixture/example/evals/evidence/legacy/transcript.md"
bash "$AUDIT_SCRIPT" "$retained_evidence_fixture" >/dev/null

invalid_text_fixture="$TEST_ROOT/invalid-text"
mkdir -p "$invalid_text_fixture/example"
printf 'not text\0' > "$invalid_text_fixture/example/payload"
if bash "$AUDIT_SCRIPT" "$invalid_text_fixture" >/dev/null 2>&1; then
  echo "Audit accepted a NUL-containing active file" >&2
  exit 1
fi

symlink_fixture="$TEST_ROOT/symlink"
mkdir -p "$symlink_fixture/example"
printf '%s\n' 'Use neutral host capabilities.' > "$symlink_fixture/target.txt"
ln -s ../target.txt "$symlink_fixture/example/instructions.txt"
if bash "$AUDIT_SCRIPT" "$symlink_fixture" >/dev/null 2>&1; then
  echo "Audit accepted a symlinked active file" >&2
  exit 1
fi

bash "$AUDIT_SCRIPT" \
  --manifest "$REPO_ROOT/tests/distribution-manifest.json" \
  --repo-root "$REPO_ROOT" \
  >/dev/null

echo "Canonical skill portability audit tests passed"
