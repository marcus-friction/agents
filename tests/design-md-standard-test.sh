#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

project="$TEST_ROOT/project"
mkdir -p "$project"

bash "$REPO_ROOT/scripts/stage-project-templates.sh" \
  "$REPO_ROOT" \
  "$project" >/dev/null

python3 - "$project/.agents/templates/DESIGN.md" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

assert lines and lines[0] == "---", "DESIGN.md must start with YAML front matter"
try:
    closing = lines.index("---", 1)
except ValueError as error:
    raise AssertionError("DESIGN.md YAML front matter is not closed") from error

frontmatter = lines[1:closing]
assert "version: alpha" in frontmatter, "DESIGN.md must declare the Google alpha format"
assert any(line.startswith("name:") for line in frontmatter), "DESIGN.md must declare a name"

headings = [line[3:] for line in lines[closing + 1:] if line.startswith("## ")]
required = [
    "Overview",
    "Colors",
    "Typography",
    "Layout",
    "Elevation & Depth",
    "Shapes",
    "Components",
    "Do's and Don'ts",
]
positions = [headings.index(heading) for heading in required]
assert positions == sorted(positions), "Google DESIGN.md sections are out of order"
assert len(positions) == len(set(positions)), "Google DESIGN.md sections must be unique"
PY

echo "Google DESIGN.md template tests passed"
