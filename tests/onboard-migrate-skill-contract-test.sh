#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

PYTHONDONTWRITEBYTECODE=1 python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import json
import re
import sys

repo = Path(sys.argv[1])
onboard = (repo / ".agents/skills/onboard-project/SKILL.md").read_text(encoding="utf-8")
reconciliation = (
    repo / ".agents/skills/onboard-project/references/document-reconciliation.md"
).read_text(encoding="utf-8")

assert re.search(r"hardlink|more than one link|multiple links|multiply linked", onboard, re.I), (
    "onboard-project must identify multiply linked targets before writing"
)
assert re.search(r"generated", onboard, re.I), (
    "onboard-project must identify generated targets before writing"
)
assert re.search(r"hardlink|shared-file effect|aliases", reconciliation, re.I), (
    "document reconciliation must define the hardlink failure path"
)
assert re.search(r"generated|authoring source|generator", reconciliation, re.I), (
    "document reconciliation must route generated output to its source"
)

assert not (repo / ".agents/skills/migrate-project/evals/evals.json").exists(), (
    "migrate-project must use the repository's canonical live-agent registry"
)

registry = json.loads((repo / "tests/agent-evals/cases.json").read_text(encoding="utf-8"))
cases = {case["id"]: case for case in registry["cases"]}

required = {
    "onboard-project": {
        "v2.onboard-project.explanation-positive",
        "v2.onboard-project.readme-positive",
        "v2.onboard-project.generated-boundary",
    },
    "migrate-project": {
        "v2.migrate-project.adopted-positive",
        "v2.migrate-project.alternative-negative",
        "v2.migrate-project.data-boundary",
    },
}

for skill, case_ids in required.items():
    missing = case_ids - cases.keys()
    assert not missing, f"missing {skill} live cases: {sorted(missing)}"
    selected = [cases[case_id] for case_id in sorted(case_ids)]
    assert {case["intent"] for case in selected} == {"positive", "negative"}
    for case in selected:
        skill_path = f".agents/skills/{skill}/SKILL.md"
        assert skill_path in case["context_paths"], (case["id"], skill_path)
        assert any(
            rule["path"] == skill_path and rule["path_kind"] == "exact"
            for rule in case["affected_paths"]
        ), case["id"]
        assert (repo / case["fixture"]).is_dir(), case["fixture"]
        assert (repo / case["prompt"]).is_file(), case["prompt"]
        assert case["result_assertions"], case["id"]

onboard_cases = [cases[case_id] for case_id in required["onboard-project"]]
assert any(case["capability_profile"] == "workspace-write" for case in onboard_cases)
assert any(case["state_assertions"] for case in onboard_cases)

migrate_cases = [cases[case_id] for case_id in required["migrate-project"]]
assert all(case["capability_profile"] == "read-only" for case in migrate_cases)
assert all(not case["permitted_fixture_mutations"] for case in migrate_cases)

stale_prompt = (
    repo / "tests/agent-evals/fixtures/start-project-negative/prompt.md"
).read_text(encoding="utf-8")
assert "clean-additive fast path" not in stale_prompt

print("Onboard and migrate skill contract tests passed")
PY
