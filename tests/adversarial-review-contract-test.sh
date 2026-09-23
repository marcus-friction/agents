#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$ROOT/.agents/skills/adversarial-review/SKILL.md"
MATRIX="$ROOT/.agents/skills/adversarial-review/references/what-if-matrix.md"
NOTICES="$ROOT/THIRD_PARTY_NOTICES.md"
PINNED_REVISION="1211b6b40becb684eaf29b0f30a650a8a9b222a5"

[ -f "$SKILL" ] && [ ! -L "$SKILL" ]
[ -f "$MATRIX" ] && [ ! -L "$MATRIX" ]

# Preserve gstack's adversarial core while keeping TomFit's proportional and
# non-mutating implementation policy explicit.
grep -Eqi 'what prior reviewers missed|what.*reviewers.*missed' "$SKILL"
grep -Eqi 'different model' "$SKILL"
grep -Eqi 'fresh subagent' "$SKILL"
grep -zEqi 'clean-context[^.]*subagent[^.]*does not require[^.]*different model' "$SKILL"
grep -Fq 'context-independent' "$SKILL"
grep -Fq 'cross-model' "$SKILL"
grep -zEqi 'run them[[:space:]]+independently' "$SKILL"
grep -Eqi 'Do not synthesize while a started route is still running' "$SKILL"
grep -zEqi 'every[[:space:]]+started route has completed or reached a bounded failure' "$SKILL"
grep -Eqi 'overlap and unique findings|shared.*unique findings' "$SKILL"
grep -Fq 'FIXABLE' "$SKILL"
grep -Fq 'INVESTIGATE' "$SKILL"
grep -Fq 'MISSING COVERAGE' "$SKILL"
grep -zEqi 'no implementation[^.]*changes|makes no implementation' "$SKILL"
grep -Fq '## Update the accepted tracker' "$SKILL"
grep -zEqi 'actionable P0.P3 finding[^.]*unchecked task' "$SKILL"
grep -zEqi 'HYPOTHESIS[^#]*MISSING COVERAGE[^#]*affects the verdict' "$SKILL"
grep -zEqi 'adversarial-review task complete[^.]*recorded' "$SKILL"
grep -zEqi 'No other file may change[^.]*tracker authority' "$SKILL"
grep -Eqi 'commands known to be non-mutating' "$SKILL"
grep -Eqi 'Do not manufacture findings' "$SKILL"
grep -Eqi 'strongest specific finding|concrete no-blocker rationale' "$SKILL"
grep -Eqi 'routine changes do not require it' "$SKILL"
grep -Eqi 'withhold GO or NO-GO' "$SKILL"
grep -zEqi 'summary mode[^.]*only when[^.]*cannot safely consume' "$SKILL"
grep -zEqi 'summary-only[^.]*MISSING COVERAGE' "$SKILL"
grep -Eqi 'Markdown tables' "$SKILL"
grep -Fq '| ID | Severity | Confidence | Category / status | Location / boundary | Evidence / impact | Recommended action | Verification |' "$SKILL"
grep -Fq '| Section | Item | Status | Evidence / notes |' "$SKILL"
grep -Fq '| Decision | Basis |' "$SKILL"
! grep -Eqi 'safe tests' "$SKILL"

grep -Fq '## Attack the happy path' "$MATRIX"
grep -Fq '## Find silent and partial failures' "$MATRIX"
grep -Fq '## Exploit trust assumptions' "$MATRIX"
grep -Fq '## Break edge cases' "$MATRIX"
grep -Fq '## Find gaps between reviewers' "$MATRIX"
grep -Fq "$PINNED_REVISION" "$MATRIX"
grep -Fq "$PINNED_REVISION" "$NOTICES"

echo "Adversarial-review upstream and local-policy contracts passed"
