#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

check_budget() {
  local label="$1"
  local path="$2"
  local target="$3"
  local ceiling="$4"
  local words
  words="$(wc -w < "$REPO_ROOT/$path")"
  words="${words//[[:space:]]/}"

  if [ "$words" -gt "$ceiling" ]; then
    echo "FAIL - $label: $words words; target $target, ceiling $ceiling"
    failures=$((failures + 1))
  elif [ "$words" -gt "$target" ]; then
    echo "WARN - $label: $words words; target $target, review threshold $ceiling"
  else
    echo "ok - $label: $words words; target $target, review threshold $ceiling"
  fi
}

check_budget "root README" README.md 1500 1800
check_budget "root AGENTS" AGENTS.md 450 550
check_budget "root CONTRIBUTING" CONTRIBUTING.md 400 500
check_budget "base README" project-templates/base/README.md 350 450
check_budget "base AGENTS" project-templates/base/AGENTS.md 500 600
check_budget "base ARCHITECTURE" project-templates/base/ARCHITECTURE.md 900 1050
check_budget "base CONTRIBUTING" project-templates/base/CONTRIBUTING.md 400 500
check_budget "base DESIGN" project-templates/base/DESIGN.md 550 700

combined_words="$(wc -w \
  "$REPO_ROOT/project-templates/base/README.md" \
  "$REPO_ROOT/project-templates/base/AGENTS.md" \
  "$REPO_ROOT/project-templates/base/ARCHITECTURE.md" \
  "$REPO_ROOT/project-templates/base/CONTRIBUTING.md" \
  | awk 'END { print $1 }')"
if [ "$combined_words" -gt 2500 ]; then
  echo "FAIL - combined core base candidates: $combined_words words; target 2200, ceiling 2500"
  failures=$((failures + 1))
elif [ "$combined_words" -gt 2200 ]; then
  echo "WARN - combined core base candidates: $combined_words words; target 2200, review threshold 2500"
else
  echo "ok - combined core base candidates: $combined_words words; target 2200, review threshold 2500"
fi

for candidate in AGENTS.md README.md CONTRIBUTING.md ARCHITECTURE.md DESIGN.md; do
  staged="$REPO_ROOT/.agents/templates/$candidate"
  if [ -e "$staged" ] && ! cmp -s \
    "$REPO_ROOT/project-templates/base/$candidate" "$staged"; then
    echo "FAIL - staged $candidate differs from its canonical candidate"
    failures=$((failures + 1))
  fi
done

reference="$REPO_ROOT/docs/ecosystem-reference.md"
[ -f "$reference" ] || {
  echo "FAIL - detailed ecosystem reference is missing"
  failures=$((failures + 1))
}

for retained in \
  'https://github.com/marcus-friction/agents.git' \
  'install-global.sh' \
  'AGENTS_ECOSYSTEM_HOME=' \
  'scripts/install-into-repos.sh' \
  'scripts/install-cursor-cloud.sh' \
  '--expected-plan-sha256 <reviewed-plan-sha256>' \
  '/plugin marketplace add' \
  '/plugin install ma@marcus-friction-plugins' \
  '/reload-plugins' \
  '## Skills' \
  '## Sources' \
  '## Releases' \
  '## Known Limitations' \
  '## Licensing Status'; do
  if ! grep -Fq -- "$retained" "$reference"; then
    echo "FAIL - README relocation lost: $retained"
    failures=$((failures + 1))
  fi
done

if grep -Fq 'raw.githubusercontent.com/marcus-friction/agents' "$reference"; then
  echo "FAIL - ecosystem reference retains an anonymous public-repository bootstrap"
  failures=$((failures + 1))
fi

grep -Fq 'docs/ecosystem-reference.md' "$REPO_ROOT/README.md" || {
  echo "FAIL - root README does not link to the ecosystem reference"
  failures=$((failures + 1))
}

quickstart_root="$(mktemp -d)"
trap 'rm -rf "$quickstart_root"' EXIT
quickstart_script="$quickstart_root/quickstart.sh"

if ! python3 - "$REPO_ROOT/README.md" "$quickstart_script" <<'PY'
from pathlib import Path
import re
import sys

readme = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r"(?ms)^<!-- stable-project-quickstart -->\n```bash\n(.*?)\n```$",
    readme,
)
if match is None:
    raise SystemExit("FAIL - root README lacks its executable stable project quick start")
Path(sys.argv[2]).write_text(match.group(1) + "\n", encoding="utf-8")
PY
then
  failures=$((failures + 1))
elif ! bash -n "$quickstart_script"; then
  echo "FAIL - root README stable project quick start is not valid shell"
  failures=$((failures + 1))
fi

python3 - "$REPO_ROOT/README.md" "$reference" <<'PY' || failures=$((failures + 1))
from pathlib import Path
import re
import sys

for raw_path in sys.argv[1:]:
    path = Path(raw_path)
    for target in re.findall(r"\[[^]]*\]\(([^)]+)\)", path.read_text()):
        target = target.split("#", 1)[0]
        if not target or "://" in target or target.startswith("mailto:"):
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            raise SystemExit(f"FAIL - broken relative link in {path}: {target}")
PY

if [ "$failures" -ne 0 ]; then
  exit 1
fi

echo "Base document and reference tests passed"
