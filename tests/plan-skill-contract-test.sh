#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PLAN="$ROOT/.agents/skills/plan/SKILL.md"

python3 "$ROOT/.agents/skills/skill-creator/scripts/quick_validate.py" \
  "$ROOT/.agents/skills/plan" >/dev/null

# These assertions verify the skill's static workflow contract. They do not
# substitute for a live-agent behavior evaluation.
python3 - "$PLAN" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")

headings = [
    "## 1. Frame discovery",
    "## 2. Build the relevant project picture",
    "## 3. Resolve open questions",
    "## 4. Draft and persist the plan pair",
    "## 5. Review to convergence",
    "## 6. Present",
]
positions = [text.index(heading) for heading in headings]
assert positions == sorted(positions), "plan workflow phases are out of order"

frontmatter = text.split("---", 2)[1]
assert re.search(r"description:.*user asks for a plan", frontmatter, re.I)
assert re.search(r"description:.*multi-step.*cross-boundary.*high-risk", frontmatter, re.I)

frame = text[positions[0]:positions[1]]
assert "docs/plans/<YYYY-MM-DD>-<slug>/" in frame
assert "implementation-plan.md" in frame and "tasks.md" in frame
assert re.search(r"next available numeric suffix", frame)
assert re.search(r"revise\s+an existing plan.*update its two files in place", frame, re.S)
assert re.search(r"explicit request for a plan authorizes only", frame, re.I)

context = text[positions[1]:positions[2]]
for required in (
    "AGENTS.md",
    "README.md",
    ".agents/project/",
    "CONTRIBUTING.md",
    "ARCHITECTURE.md",
    "DESIGN.md",
    "affected implementation",
    "tests",
    "executable configuration",
    "dependency manifests",
):
    assert required in context, f"missing project-context source: {required}"
assert re.search(r"Search `docs/solutions/` by filename and content", context)
assert re.search(r"Read every match.*materially inform or constrain", context, re.S)
assert re.search(r"absent, no relevant\s+match exists", context)
assert re.search(r"validate it against the current\s+implementation", context)
assert re.search(r"missing or unreadable", context)
assert re.search(r"never fabricate the missing context", context)

questions = text[positions[2]:positions[3]]
assert re.search(r"Do not ask\s+the user for facts the project already answers", questions)
assert re.search(r"Ask the user only the remaining material questions", questions)
assert re.search(r"Do not draft, persist, or present the plan artifacts", questions)
assert re.search(r"Wait for answers", questions)
assert re.search(r"best-effort plan under uncertainty", questions)
assert re.search(r"no material question remains, proceed", questions)

draft = text[positions[3]:positions[4]]
assert "concise evidence ledger" in draft
assert re.search(r"compounded knowledge\s+that materially shaped the plan", draft)
assert "resolved decisions" in draft
assert "remaining non-blocking assumptions" in draft
assert re.search(r"checkbox-based execution tracker", draft)
assert re.search(r"Treat `tasks\.md` as live project state", draft)
assert re.search(r"Mark a task complete only when", draft)

review = text[positions[4]:positions[5]]
assert re.search(r"apply `review-plan` to every plan", review)
assert "implementation-plan.md" in review and "tasks.md" in review
PY

echo "Plan skill contract tests passed."
