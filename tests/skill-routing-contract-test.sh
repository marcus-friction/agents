#!/usr/bin/env bash

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILLS="$ROOT/.agents/skills"

for removed in office-hours stats whats-next changelog brainstorm design-consultation review-gstack ui-accessibility-review; do
  [ ! -e "$SKILLS/$removed" ] || { echo "removed skill still exists: $removed" >&2; exit 1; }
done
for retained in path-to-10 systematic-debugging code-review-excellence compound copywriting contribute-back update-agents; do
  [ -f "$SKILLS/$retained/SKILL.md" ] || { echo "retained skill is missing: $retained" >&2; exit 1; }
done

compound="$SKILLS/compound/SKILL.md"
wrap="$SKILLS/wrap/SKILL.md"
copywriting="$SKILLS/copywriting/SKILL.md"
contribute="$SKILLS/contribute-back/SKILL.md"
update="$SKILLS/update-agents/SKILL.md"
adversarial="$SKILLS/adversarial-review/SKILL.md"

grep -Eqi 'only when the user asks|accepts a proposed durable handoff' "$compound"
grep -Eqi 'Keep the result in chat' "$compound"
grep -Eqi 'substantial troubleshooting|tricky implementation' "$compound"
grep -Eqi 'rate every candidate' "$compound"
grep -Fq 'Report the rating value as `high`, `medium`, or `low`.' "$compound"
grep -Eqi 'Only.*High.*(compound|capture|persist)' "$compound"
grep -Eqi 'authori[sz]ation.*(does not|never).*qualification|qualification.*separate.*authori[sz]ation' "$compound"
grep -Eqi 'compound.*owns.*(rating|relevance)|do not duplicate.*(rating|eligibility)' "$wrap"
python3 - "$wrap" <<'PY'
from pathlib import Path
import sys

content = " ".join(Path(sys.argv[1]).read_text(encoding="utf-8").lower().split())
assert "for every generic wrap where the user did not explicitly exclude both commit and push" in content
assert "prepare its exact read-only preview of atomic commit groups" in content
assert "then ask once which git effects to execute" in content
PY
grep -Eqi 'code or configuration only when it helps' "$compound"
grep -Eqi 'dead ends only when' "$compound"
grep -Eqi 'prevention only when' "$compound"

grep -Eqi 'README.*none is a prerequisite|none is a prerequisite' "$copywriting"
grep -Eqi 'product documentation unless the user asks' "$copywriting"
grep -Eqi 'Return only the artifact requested' "$copywriting"
! grep -Eqi 'No exclamation points|must.*start-project|must.*onboard-project' "$copywriting"

grep -Eqi 'request already identifies' "$contribute"
grep -Eqi 'without another gate' "$contribute"
grep -Eqi 'publication.*separate exact (batch )?approval|separate exact (batch )?approval.*publication' "$contribute"
grep -Eqi 'updates install no host packages' "$update"
grep -Eqi 'managed state' "$update"

# Preserve the independently authored review requirement: a persona swap in the
# implementing agent is not an eligible adversarial pass.
grep -Eqi 'different model|fresh subagent' "$adversarial"
grep -Eqi 'same agent.*same model|same model.*same agent|same-context|same context' "$adversarial"
grep -Eqi 'withhold.*GO|withhold the GO' "$adversarial"

echo "Skill routing contract tests passed."
