#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$REPO_ROOT/.agents/skills/update-agents/SKILL.md"

python3 - "$SKILL" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")

required = {
    "release input": 'AGENTS_ECOSYSTEM_SHA="${AGENTS_ECOSYSTEM_SHA:?',
    "strict SHA grammar": '^[0-9a-f]{40}$',
    "exact fetch": 'fetch --depth 1 --no-tags origin "$AGENTS_ECOSYSTEM_SHA"',
    "detached checkout": 'checkout --quiet --detach FETCH_HEAD',
    "HEAD equality": 'rev-parse --verify \'HEAD^{commit}\'',
    "detached verification": 'symbolic-ref --quiet HEAD',
    "installer propagation": '--ref "$AGENTS_ECOSYSTEM_SHA"',
    "physical installer check": '[ -L "$UPDATE_TMP/install.sh" ]',
    "project Git isolation": "project_git() (",
    "isolated project root": 'PROJECT_ROOT="$(project_git rev-parse --show-toplevel)"',
    "isolated project status": 'project_git -C "$PROJECT_ROOT" status --short',
    "hidden project index-state rejection": "ls-files -v -- .agents",
    "assume-unchanged and skip-worktree detection": "sed -n '/^[a-zS]/p'",
    "project fsmonitor isolation": "-c core.fsmonitor=false",
    "project replace-ref isolation": "GIT_NO_REPLACE_OBJECTS=1 git --no-replace-objects",
    "ambient config isolation": "GIT_CONFIG_GLOBAL=/dev/null",
    "replace-ref isolation": "--no-replace-objects",
    "ambient credential reset": "-c credential.helper=",
    "Git askpass fallback blocked": "GIT_ASKPASS=/usr/bin/false",
    "SSH askpass fallback blocked": "SSH_ASKPASS=/usr/bin/false",
    "SSH askpass policy neutralized": "SSH_ASKPASS_REQUIRE=never",
    "public repository URL": "https://github.com/marcus-friction/agents.git",
}
for label, fragment in required.items():
    if fragment not in text:
        raise SystemExit(f"update-agents lacks {label}")

for forbidden in (
    "require_private_repository_auth",
    "gh auth git-credential",
    "TomFitAG/tomfit-agents",
):
    if forbidden in text:
        raise SystemExit(f"public update-agents retains private/source coupling: {forbidden}")

if re.search(
    r"git clone[^\n]*marcus-friction/agents(?:\.git)?[^\n]*\"\$UPDATE_TMP\"",
    text,
):
    raise SystemExit("update-agents still clones a mutable default branch")

verify = text.index("rev-parse --verify 'HEAD^{commit}'")
execute = text.index('bash "$UPDATE_TMP/install.sh"')
if verify > execute:
    raise SystemExit("update-agents executes checkout code before ref verification")

hidden_index_check = text.index("ls-files -v -- .agents")
if hidden_index_check > execute:
    raise SystemExit("update-agents checks hidden .agents index state after updating")

print("Update-agents immutable-ref contract tests passed")
PY
