#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_contract() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! grep -Eqi "$pattern" "$REPO_ROOT/$file"; then
    echo "Missing policy contract in $file: $message"
    exit 1
  fi
}

require_absent() {
  local pattern="$1"
  shift
  if grep -Eni "$pattern" "$@"; then
    echo "Rigid or stale architecture mandate remains in active guidance"
    exit 1
  fi
}

require_contract .agents/skills/security-review/SKILL.md \
  'applicability preflight|changed trust boundaries' \
  'review boundary applicability before detailed controls'
require_contract .agents/skills/security-review/SKILL.md \
  'exploitability.*exposure.*impact.*reversibility' \
  'derive severity from evidence'
require_contract .agents/skills/security-review/SKILL.md \
  'not applicable.*evidence|evidence-backed.*not applicable' \
  'allow evidence-backed N/A findings'
require_contract .agents/skills/security-review/SKILL.md \
  'server-side.*(URL|outbound)|SSRF' \
  'review server-side URL fetching as an SSRF boundary'
require_contract .agents/skills/security-review/SKILL.md \
  '(allow-list|allowlist).*(scheme|host|destination)|scheme.*(allow-list|allowlist)' \
  'allow only intended outbound schemes and destinations'
require_contract .agents/skills/security-review/SKILL.md \
  '(private|loopback).*(reserved|link-local)|reserved.*(private|loopback)' \
  'reject private and reserved resolved addresses'
require_contract .agents/skills/security-review/SKILL.md \
  'redirect.*revalidat|revalidat.*redirect' \
  'revalidate every outbound redirect'
require_contract .agents/skills/security-review/SKILL.md \
  'DNS rebinding|connection target' \
  'bind or verify the connection target after DNS validation'
require_contract project-templates/base/ARCHITECTURE.md \
  'Exposure.*Data impact.*Privilege.*Reversibility.*Control owner' \
  'record assurance facts independently of component status'
require_contract project-templates/base/ARCHITECTURE.md \
  'Nuxt.*Laravel.*authoritative (API )?contract|authoritative (API )?contract.*Nuxt.*Laravel' \
  'keep the Laravel-to-Nuxt API contract authoritative'
require_contract project-templates/base/ARCHITECTURE.md \
  '(generate|derive).*(client|TypeScript) types.*drift|drift.*(generate|derive).*(client|TypeScript) types' \
  'derive client types and verify contract drift when adopted'
require_contract project-templates/base/AGENTS.md \
  'approved platform|runtime secret|secret boundary' \
  'keep secrets out of source without prescribing .env for deployment'

active_files=(
  "$REPO_ROOT/AGENTS.md"
  "$REPO_ROOT/project-templates/base/AGENTS.md"
  "$REPO_ROOT/project-templates/base/ARCHITECTURE.md"
  "$REPO_ROOT/.agents/skills/architecture-review/SKILL.md"
  "$REPO_ROOT/.agents/skills/ui-accessibility-review/SKILL.md"
  "$REPO_ROOT/.agents/skills/migrate-project/SKILL.md"
)

require_absent \
  'All responses go through Resource classes|Base components.*BaseButton.*BaseInput.*no raw HTML|must specify version mapping|Spring Security \+ JWT|Spring Security \+ NextAuth' \
  "${active_files[@]}"

stale_output="$(PYTHONDONTWRITEBYTECODE=1 python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import re
import sys

repo = Path(sys.argv[1])
pattern = re.compile(
    r"All responses go through Resource classes|"
    r"Base components[^\n]*BaseButton[^\n]*BaseInput[^\n]*no raw HTML|"
    r"must specify version mapping|Spring Security \+ JWT|"
    r"Spring Security \+ NextAuth|"
    r"Every new (function|method)|Delete code\. Start over|Delete means delete|"
    r"Perform a 3-loop|exactly \*\*3 times"
)
roots = [
    repo / ".agents/skills",
    repo / "project-templates",
    repo / "AGENTS.md",
    repo / "CONTRIBUTING.md",
    repo / "README.md",
]


def is_historical_evidence(path: Path) -> bool:
    parts = path.relative_to(repo).parts
    return any(
        parts[index:index + 2] == ("evals", "evidence")
        for index in range(len(parts) - 1)
    )


for root in roots:
    candidates = root.rglob("*.md") if root.is_dir() else [root]
    for path in candidates:
        if path.is_symlink() or not path.is_file() or is_historical_evidence(path):
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if pattern.search(line):
                print(f"{path}:{line_number}:{line}")
PY
)"
if [ -n "$stale_output" ]; then
  echo "$stale_output"
  echo "Repository-wide active guidance contains a stale rigid mandate"
  exit 1
fi

echo "Pragmatism policy tests passed"
