#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PATH_SKILL="$ROOT/.agents/skills/path-to-10/SKILL.md"
CONTRIBUTE_SKILL="$ROOT/.agents/skills/contribute-back/SKILL.md"
PUBLICATION="$ROOT/.agents/skills/contribute-back/references/publication-batch.md"

for path in "$PATH_SKILL" "$CONTRIBUTE_SKILL" "$PUBLICATION"; do
  [ -f "$path" ] && [ ! -L "$path" ]
done

grep -Eqi 'path to 10|quality score|quality assessment' "$PATH_SKILL"
grep -Eqi 'accepted intent|acceptance criteria' "$PATH_SKILL"
grep -zEqi 'project rule[^#]*observed behavior|observed behavior[^#]*project rule' "$PATH_SKILL"
grep -Eqi 'smallest.*relevant.*dimension|relevant dimensions' "$PATH_SKILL"
grep -Eqi 'do not invent.*gap|no.*material gaps' "$PATH_SKILL"
grep -zEqi 'report-only[^.]*zero[^.]*writes|zero[^.]*writes[^.]*report-only' "$PATH_SKILL"
! grep -zEqi 'must[^.]*task\.md|must[^.]*implementation_plan\.md' "$PATH_SKILL"
! grep -zEqi 'exactly[^.]*4.?5|determine 4.?5' "$PATH_SKILL"
! grep -zEqi 'every flaw[^.]*project rule|flaw[^.]*must[^.]*project rule' "$PATH_SKILL"

grep -Fq 'references/publication-batch.md' "$CONTRIBUTE_SKILL"
grep -Eqi 'proposal-only|report-only' "$CONTRIBUTE_SKILL"
grep -Eqi 'repository-declared.*managed|managed distribution source' "$CONTRIBUTE_SKILL"
grep -Eqi 'nested.*README\.md|support files' "$CONTRIBUTE_SKILL"
grep -Eqi 'selection is not publication approval|publication.*separate.*approval' "$CONTRIBUTE_SKILL"
grep -Eqi 'presence.*category.*relative path|relative path.*redact' "$CONTRIBUTE_SKILL"
grep -Eqi 'destination owner/repository.*base ref' "$PUBLICATION"
grep -Eqi 'authenticated.*identity' "$PUBLICATION"
grep -Eqi 'exact.*git add' "$PUBLICATION"
grep -Eqi 'verified snapshot|snapshot.*verif' "$PUBLICATION"
grep -zEqi 'changed[^.]*hash[^.]*invalidates|hash[^.]*changed[^.]*invalidates' "$PUBLICATION"
! grep -Eqi 'automatically create a pull request' "$CONTRIBUTE_SKILL" "$PUBLICATION"

echo "Path-to-10 and contribute-back skill contracts passed"
