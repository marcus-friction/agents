#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILL="$ROOT/.agents/skills/review/SKILL.md"
FINDINGS="$ROOT/.agents/skills/review/references/finding-contract.md"
ORCHESTRATION="$ROOT/.agents/skills/review/references/scope-and-orchestration.md"
NOTICES="$ROOT/THIRD_PARTY_NOTICES.md"
UPSTREAM_REVISION="b36047e1b4b2123df2f3529bf04b5f2a7c5f84e4"

for path in "$SKILL" "$FINDINGS" "$ORCHESTRATION"; do
  [ -f "$path" ] && [ ! -L "$path" ]
done

grep -Fq 'finding-contract.md' "$SKILL"
grep -Fq 'scope-and-orchestration.md' "$SKILL"
grep -zEqi 'report-only[^.]*no reviewed-code[^.]*changes|no reviewed-code[^.]*report-only' "$SKILL"
grep -zEqi 'accepted[^.]*plan[^.]*tasks\.md[^.]*R1' "$SKILL"
grep -Eqi 'in-scope untracked|accepted.*untracked' "$ORCHESTRATION"
grep -Eqi 'remote.*do not.*checkout|do not.*checkout.*remote' "$ORCHESTRATION"
grep -zEqi 'fresh clean-context[^.]*subagent' "$ORCHESTRATION"
grep -zEqi 'same model[^.]*independent|independent[^.]*same model' "$ORCHESTRATION"
grep -zEqi 'Do not[^.]*synthesize[^.]*still running|still running[^.]*Do not[^.]*synthesize' "$ORCHESTRATION"
grep -Eqi 'missing coverage' "$ORCHESTRATION"
grep -Eqi 'withhold.*verdict|verdict.*withheld' "$ORCHESTRATION"
grep -zEqi 'primary[^#]*secondary[^#]*pre-existing|primary[^#]*secondary[^#]*pre_existing' "$FINDINGS"
grep -zEqi '0[^#]*25[^#]*50[^#]*75[^#]*100' "$FINDINGS"
grep -Eqi 'independent.*promot|promot.*independent' "$FINDINGS"
grep -Eqi 'same.*defect.*fix path|same.*failure.*fix' "$FINDINGS"
grep -Eqi 'external.*model|external.*provider|external.*service' "$SKILL"
grep -Fq '## 5. Update the accepted tracker' "$SKILL"
grep -zEqi 'actionable P0.P3 finding[^.]*unchecked task' "$SKILL"
grep -Eqi 'exclude advisory-only' "$SKILL"
grep -zEqi 'review task complete[^.]*findings[^.]*recorded' "$SKILL"
grep -zEqi 'tracker authority[^.]*never permits[^.]*reviewed code' "$SKILL"
grep -Eqi 'tracker tasks added, deduplicated, or unavailable' "$SKILL"
grep -Fq "$UPSTREAM_REVISION" "$NOTICES"

for delegated in architecture-review performance-review security-review; do
  grep -Eqi 'finding contract|parent review packet' "$ROOT/.agents/skills/$delegated/SKILL.md"
done

echo "Review skill orchestration and upstream contracts passed"
