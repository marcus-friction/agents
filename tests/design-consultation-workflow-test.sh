#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$REPO_ROOT/.agents/skills/design-consultation/SKILL.md"
failures=0

fail() {
  echo "not ok - $1"
  failures=$((failures + 1))
}

require_text() {
  local pattern="$1"
  local behavior="$2"

  if ! grep -Eqi "$pattern" "$SKILL"; then
    fail "$behavior"
  fi
}

line_of() {
  local pattern="$1"

  grep -Enim 1 "$pattern" "$SKILL" | cut -d: -f1
}

frontmatter="$({
  awk '
    NR == 1 && $0 == "---" { delimiters = 1; next }
    delimiters == 1 && $0 == "---" { exit }
    delimiters == 1 { print }
  ' "$SKILL"
})"

if grep -Eq '^allowed-tools:' <<< "$frontmatter"; then
  fail "frontmatter is consumer-neutral"
fi

require_text '\.agents/templates/DESIGN\.md' \
  "the staged DESIGN candidate is inspected"
require_text 'Google.*DESIGN\.md|google-labs-code/design\.md' \
  "the workflow follows the Google DESIGN.md format"
require_text 'YAML front.?matter' \
  "the workflow preserves machine-readable design tokens"
require_text 'project-owned context (first|before)' \
  "project-owned context is gathered before incoming guidance"
require_text 'inactive candidate|candidate.*not.*authoritative|never overrides' \
  "the staged candidate cannot override project-owned decisions"

context_line="$(line_of 'project-owned context (first|before)' || true)"
candidate_line="$(line_of '\.agents/templates/DESIGN\.md' || true)"
if [ -z "$context_line" ] || [ -z "$candidate_line" ] \
  || [ "$context_line" -ge "$candidate_line" ]; then
  fail "project context precedes the staged candidate"
fi

require_text 'preservation ledger' \
  "existing and incoming meanings are reconciled in a preservation ledger"
require_text 'implementation architecture' \
  "the ledger classifies implementation architecture guidance"
require_text 'component states' \
  "the ledger classifies component-state guidance"
require_text 'accessibility' \
  "the ledger classifies accessibility guidance"
for evidence_status in observed documented inferred proposed; do
  require_text "\\*\\*$evidence_status\\*\\*" \
    "the ledger supports the '$evidence_status' evidence status"
done
require_text 'applicable|not applicable|conflict' \
  "the ledger records applicability without silently resolving conflicts"

require_text 'provider-neutral.*preview|preview.*provider-neutral' \
  "the workflow creates a provider-neutral preview artifact"
require_text 'self-contained.*HTML|HTML.*self-contained' \
  "the preview has a portable self-contained format"
require_text 'responsive' \
  "the preview validation covers responsive layouts"
require_text 'contrast' \
  "the preview validation covers color contrast"
require_text 'keyboard|focus' \
  "the preview validation covers keyboard and focus behavior"
require_text 'reduced.motion' \
  "the preview validation covers reduced motion"

preview_line="$(line_of '^## Phase [0-9]+: .*Preview' || true)"
patch_line="$(line_of '^## Phase [0-9]+: .*Patch DESIGN\.md' || true)"
if [ -z "$preview_line" ] || [ -z "$patch_line" ] \
  || [ "$preview_line" -ge "$patch_line" ]; then
  fail "preview validation and approval precede the DESIGN.md patch phase"
fi

require_text 'approve.*preview|preview.*approval' \
  "the user approves the validated preview before documentation changes"
require_text 'exact unified diff' \
  "the user approves the exact DESIGN.md patch"

if [ "$failures" -ne 0 ]; then
  echo "$failures design-consultation workflow check(s) failed"
  exit 1
fi

echo "Design consultation workflow tests passed"
