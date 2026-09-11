#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

reference="$REPO_ROOT/docs/ecosystem-reference.md"
[ -f "$reference" ] && [ ! -L "$reference" ] || {
  echo "Detailed ecosystem reference must be a physical file" >&2
  exit 1
}

for candidate in AGENTS.md README.md CONTRIBUTING.md ARCHITECTURE.md DESIGN.md; do
  staged="$REPO_ROOT/.agents/templates/$candidate"
  if [ -e "$staged" ] && ! cmp -s \
    "$REPO_ROOT/project-templates/base/$candidate" "$staged"; then
    echo "Staged $candidate differs from its canonical candidate" >&2
    exit 1
  fi
done

grep -Fq 'docs/ecosystem-reference.md' "$REPO_ROOT/README.md" || {
  echo "Root README does not link to the ecosystem reference" >&2
  exit 1
}

python3 - "$REPO_ROOT/README.md" "$reference" <<'PY'
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
            raise SystemExit(f"broken relative link in {path}: {target}")
PY

quickstart="$TEST_ROOT/stable-quickstart.sh"
python3 - "$REPO_ROOT/README.md" "$quickstart" <<'PY'
from pathlib import Path
import re
import sys

readme = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r"(?ms)^<!-- stable-project-quickstart -->\n```bash\n(.*?)\n```$",
    readme,
)
if match is None:
    raise SystemExit("root README lacks its executable stable project quick start")
Path(sys.argv[2]).write_text(match.group(1) + "\n", encoding="utf-8")
PY

snapshot_files="$TEST_ROOT/snapshot-files"
while IFS= read -r -d '' snapshot_path; do
  if [ -e "$REPO_ROOT/$snapshot_path" ] || [ -L "$REPO_ROOT/$snapshot_path" ]; then
    printf '%s\0' "$snapshot_path"
  fi
done < <(git -C "$REPO_ROOT" ls-files --cached --others --exclude-standard -z) \
  > "$snapshot_files"

mkdir -p "$TEST_ROOT/source" "$TEST_ROOT/project" "$TEST_ROOT/bin"
env -u TAR_OPTIONS tar \
  --null --verbatim-files-from \
  -C "$REPO_ROOT" -T "$snapshot_files" -cf - \
  | env -u TAR_OPTIONS tar -C "$TEST_ROOT/source" -xf -
git -c init.defaultBranch=master init --quiet "$TEST_ROOT/source"
git -C "$TEST_ROOT/source" add -A
git -C "$TEST_ROOT/source" \
  -c user.name='Agent Ecosystem Tests' \
  -c user.email='tests@example.invalid' \
  commit --quiet -m 'test fixture'
quickstart_sha="$(git -C "$TEST_ROOT/source" rev-parse HEAD)"
git -C "$TEST_ROOT/source" -c core.hooksPath=/dev/null \
  checkout --quiet --detach "$quickstart_sha"

real_git="$(command -v git)"
cat > "$TEST_ROOT/bin/git" <<'SH'
#!/usr/bin/env bash
for argument in "$@"; do
  if [ "$argument" = 'https://github.com/marcus-friction/agents.git' ]; then
    echo "stable quick start attempted a network operation" >&2
    exit 99
  fi
done
exec "$AGENTS_ECOSYSTEM_TEST_REAL_GIT" "$@"
SH
chmod +x "$TEST_ROOT/bin/git"

output="$TEST_ROOT/stable-quickstart.out"
(
  cd "$TEST_ROOT/project"
  PATH="$TEST_ROOT/bin:$PATH" \
    AGENTS_ECOSYSTEM_TEST_REAL_GIT="$real_git" \
    AGENTS_ECOSYSTEM_SOURCE="$TEST_ROOT/source" \
    AGENTS_ECOSYSTEM_SHA="$quickstart_sha" \
    bash "$quickstart" > "$output" 2>&1
)

[ -d "$TEST_ROOT/project/.agents/skills" ]
[ -d "$TEST_ROOT/project/.agents/templates" ]
grep -Fq '=> Verified immutable source at ' "$output"
grep -Fq '(detached HEAD).' "$output"
[ ! -e "$TEST_ROOT/project/README.md" ]

echo "Documentation interface tests passed"
