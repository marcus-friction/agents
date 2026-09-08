#!/usr/bin/env bash

set -euo pipefail
umask 022

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVAL_ROOT="$REPO_ROOT/.agents/skills/onboard-project/evals"
SKILL_PATH="$REPO_ROOT/.agents/skills/onboard-project/SKILL.md"
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

verifier="$TEST_ROOT/verify-fast-path.py"
cat > "$verifier" <<'PY'
import hashlib
import json
import pathlib
import subprocess
import sys
from collections import Counter

trace_path, repository_path, state_path, evals_path, skill_path = map(
    pathlib.Path, sys.argv[1:]
)
trace = json.loads(trace_path.read_text(encoding="utf-8"))
evals = json.loads(evals_path.read_text(encoding="utf-8"))
case = next(item for item in evals["evals"] if item["id"] == 2)

# These literals are the independently derived clean-additive, narrow-R2
# boundary contract for the sparse fixture.
expected = {
    "path": "clean-additive-fast-path",
    "risk_class": "R2",
    "sole_r2_trigger": "already-supplied-component-applicability",
    "r1_target_policy": "bounded-clean-additive-project-documents",
    "r2_target_policy": "exactly-two-absent-root-agents-and-architecture",
    "proposal_targets": ["AGENTS.md", "ARCHITECTURE.md"],
    "git_cleanliness_scope": "exact-target-candidate-anchor-paths",
    "tracked_index_flag_policy": "reject-assume-unchanged-and-skip-worktree",
    "read_evidence_policy": "exact-sha256-matches-state-and-current-bytes",
    "unrelated_dirty_policy": "preserve-and-continue",
    "existing_file_link_count": 1,
    "approval_decisions": 1,
    "ledger_form": "concise-target-scoped-disposition",
    "preapproval_writes": 0,
    "durable_artifacts_without_audit_need": 0,
    "preapproval_revalidation_batches": 0,
    "unchanged_application_commands": 0,
    "detailed_reference_loads": 0,
    "repeat_direct_anchor_reads": 0,
    "predicate_failure_path": "detailed-reconciliation",
    "predicate_failure_reference": "references/document-reconciliation.md",
    "performance_measurements": [
        "command_batches",
        "elapsed_seconds",
        "total_tokens",
    ],
}
assert case["behavior_contract"] == expected, case["behavior_contract"]

start_marker = "<!-- BEGIN CLEAN-ADDITIVE FAST-PATH CONTRACT -->"
end_marker = "<!-- END CLEAN-ADDITIVE FAST-PATH CONTRACT -->"
skill_source = skill_path.read_text(encoding="utf-8")
assert skill_source.count(start_marker) == 1, "missing or repeated fast-path contract start"
assert skill_source.count(end_marker) == 1, "missing or repeated fast-path contract end"
contract_source = skill_source.split(start_marker, 1)[1].split(end_marker, 1)[0].strip()
assert contract_source.startswith("```json\n") and contract_source.endswith("\n```"), (
    "fast-path contract must be one JSON fence"
)
policy = json.loads(contract_source.removeprefix("```json\n").removesuffix("\n```"))
assert policy == expected, policy
assert trace["fixture"] == "sparse-python-service", trace

repository = repository_path.resolve()
state = state_path.resolve()
expected_manifest = []
manifest_files = {}
manifest_paths = set()
for line in (state / "manifest.tsv").read_text(encoding="utf-8").splitlines():
    row = tuple(line.split("\t", 2))
    assert len(row) == 3, row
    kind, relative, value = row
    assert relative not in manifest_paths, f"duplicate manifest path: {relative}"
    manifest_paths.add(relative)
    expected_manifest.append(row)
    if kind == "file":
        manifest_files[relative] = value
context = trace["context"]
target_states = context["target_states"]
candidate_paths = context["candidate_paths"]
direct_anchor_paths = context["direct_anchor_paths"]

full_sparse_inputs = (
    [".agents/templates/AGENTS.md", ".agents/templates/ARCHITECTURE.md"],
    ["pyproject.toml", "src/ledger_service.py"],
)
scenario_inputs = {
    "measured-sparse-component-applicability": full_sparse_inputs,
    "authorized-unrelated-dirty-state": full_sparse_inputs,
    "relevant-anchor-dirty-state": full_sparse_inputs,
    "hardlinked-direct-anchor": full_sparse_inputs,
    "existing-narrow-r2-target": full_sparse_inputs,
    "assume-unchanged-direct-anchor": full_sparse_inputs,
    "skip-worktree-candidate": full_sparse_inputs,
    "general-clean-r1": ([".agents/templates/AGENTS.md"], ["pyproject.toml"]),
    "symlink-ancestor-target": (
        [".agents/templates/AGENTS.md"],
        ["pyproject.toml"],
    ),
    "symlink-ancestor-direct-anchor": (
        [".agents/templates/AGENTS.md"],
        ["linked-src/sub/anchor.py"],
    ),
}
assert trace["scenario"] in scenario_inputs, trace["scenario"]
expected_candidates, expected_anchors = scenario_inputs[trace["scenario"]]
assert candidate_paths == expected_candidates, candidate_paths
assert direct_anchor_paths == expected_anchors, direct_anchor_paths


def path_parts(relative):
    candidate = pathlib.PurePosixPath(relative)
    if (
        not isinstance(relative, str)
        or candidate.is_absolute()
        or not candidate.parts
        or any(component in {"", ".", ".."} for component in candidate.parts)
    ):
        return None
    return candidate.parts


def has_physical_parent_components(relative):
    parts = path_parts(relative)
    if parts is None:
        return False
    current = repository
    for component in parts[:-1]:
        current /= component
        if current.is_symlink() or not current.is_dir():
            return False
    return True


def git_scope_path(relative):
    parts = path_parts(relative)
    assert parts is not None, relative
    current = repository
    prefix = []
    for component in parts:
        prefix.append(component)
        current /= component
        if current.is_symlink():
            return "/".join(prefix)
    return relative


relevant_git_paths = []
for relative in [*target_states, *candidate_paths, *direct_anchor_paths]:
    scoped = git_scope_path(relative)
    if scoped not in relevant_git_paths:
        relevant_git_paths.append(scoped)
git_command = [
    "git", "-C", str(repository), "status", "--porcelain=v1",
    "--untracked-files=all",
]
all_status = subprocess.run(
    git_command,
    check=True,
    capture_output=True,
    text=True,
).stdout.splitlines()
relevant_status = subprocess.run(
    [*git_command, "--", *relevant_git_paths],
    check=True,
    capture_output=True,
    text=True,
).stdout.splitlines()
actual_git_state = {
    "relevant": "dirty" if relevant_status else "clean",
    "unrelated": "dirty" if set(all_status) - set(relevant_status) else "clean",
}
assert context["git_state"] == actual_git_state, (
    context["git_state"], actual_git_state
)

index_output = subprocess.run(
    [
        "git", "-C", str(repository), "ls-files", "-v", "-z", "--",
        *relevant_git_paths,
    ],
    check=True,
    capture_output=True,
).stdout
nondefault_index_flags = []
for record in index_output.split(b"\0"):
    if not record:
        continue
    assert len(record) >= 3 and record[1:2] == b" ", record
    tag = chr(record[0])
    if tag == "S" or tag.islower():
        nondefault_index_flags.append(record)
index_flags_are_default = not nondefault_index_flags


def observed_target(relative):
    path = repository / relative
    if path.is_symlink():
        state_name = "symlink"
    elif not path.exists():
        state_name = "absent"
    elif path.is_file():
        target_status = subprocess.run(
            [*git_command, "--", git_scope_path(relative)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        state_name = "dirty-regular" if target_status else "clean-regular"
    elif path.is_dir():
        state_name = "directory"
    else:
        state_name = "special"
    return {
        "state": state_name,
        "parent": (
            "physical" if has_physical_parent_components(relative)
            else "nonphysical"
        ),
    }


actual_target_states = {
    relative: observed_target(relative) for relative in target_states
}
assert target_states == actual_target_states, (target_states, actual_target_states)
clean_targets = bool(target_states) and all(
    value["state"] in {"absent", "clean-regular"}
    and value["parent"] == "physical"
    for value in actual_target_states.values()
)
exact_r2_targets = (
    list(actual_target_states) == policy["proposal_targets"]
    and all(value["state"] == "absent" for value in actual_target_states.values())
)
r1_branch = (
    context["risk_class"] == "R1" and context["r2_triggers"] == []
    and context["component_applicability"] == "none"
)
r2_branch = (
    context["risk_class"] == policy["risk_class"]
    and context["r2_triggers"] == [policy["sole_r2_trigger"]]
    and context["component_applicability"] == "already-supplied"
    and exact_r2_targets
)


parents_are_physical = all(
    has_physical_parent_components(relative) for relative in target_states
)
existing_inputs = [
    (relative, repository / relative)
    for relative in [
        *candidate_paths,
        *direct_anchor_paths,
        *(
            relative for relative, value in actual_target_states.items()
            if value["state"] != "absent"
        ),
    ]
]
inputs_are_single_link_regular_files = all(
    has_physical_parent_components(relative)
    and path.is_file()
    and not path.is_symlink()
    and path.stat().st_nlink == policy["existing_file_link_count"]
    for relative, path in existing_inputs
)
unrelated_state_allowed = (
    actual_git_state["unrelated"] == "clean"
    or policy["unrelated_dirty_policy"] == "preserve-and-continue"
)
disqualifiers = (
    "existing_meaning",
    "conflict",
    "deletion",
    "weakening",
    "new_dependency",
    "boundary_change",
    "external_effect",
)
eligible = (
    (r1_branch or r2_branch)
    and clean_targets
    and parents_are_physical
    and inputs_are_single_link_regular_files
    and context["target_scope"] == "project-documents"
    and context["mutation_shape"] == "additions-only"
    and policy["git_cleanliness_scope"] == "exact-target-candidate-anchor-paths"
    and policy["tracked_index_flag_policy"]
        == "reject-assume-unchanged-and-skip-worktree"
    and policy["read_evidence_policy"]
        == "exact-sha256-matches-state-and-current-bytes"
    and actual_git_state["relevant"] == "clean"
    and index_flags_are_default
    and unrelated_state_allowed
    and context["candidates"] == "physical"
    and context["direct_anchors"] == "physical-nonsensitive"
    and context["scope_resolved"] is True
    and not any(context[name] for name in disqualifiers)
    and (
        trace["scenario"] != "measured-sparse-component-applicability"
        or r2_branch
    )
)

events = trace["events"]
reference_events = [event for event in events if event["type"] == "reference-load"]
if not eligible:
    assert trace["path"] == policy["predicate_failure_path"], trace
    assert reference_events == [
        {
            "type": "reference-load",
            "path": policy["predicate_failure_reference"],
        }
    ], reference_events
    assert events == reference_events, events
else:
    assert trace["path"] == policy["path"], trace
    assert len(reference_events) == policy["detailed_reference_loads"], reference_events

proposal_events = [event for event in events if event["type"] == "proposal"]
if eligible:
    assert len(proposal_events) == 1, proposal_events
    proposal = proposal_events[0]
    assert proposal["targets"] == list(target_states), proposal
    assert proposal["ledger_form"] == policy["ledger_form"], proposal
    assert proposal["exact_diff"] is True, proposal
    approval_events = [event for event in events if event["type"] == "approval-request"]
    assert len(approval_events) == policy["approval_decisions"], approval_events
    assert all(
        event == {"type": "approval-request", "scope": "semantic-and-exact-patch"}
        for event in approval_events
    ), approval_events
else:
    assert not proposal_events, proposal_events

write_events = [event for event in events if event["type"] == "write"]
assert len(write_events) == policy["preapproval_writes"], events
durable_events = [
    event for event in events
    if event["type"] == "artifact" and event.get("durable") is True
]
if eligible and context["audit_need"] is True:
    assert durable_events == [
        {
            "type": "artifact",
            "path": ".agents/project/onboarding/preservation-ledger.md",
            "durable": True,
            "reason": "audit-need",
        }
    ], durable_events
else:
    assert len(durable_events) == policy["durable_artifacts_without_audit_need"], (
        durable_events
    )
if eligible:
    expected_event_types = [
        "command-batch",
        *("read" for _ in [*candidate_paths, *direct_anchor_paths]),
        *( ["artifact"] if context["audit_need"] is True else [] ),
        "proposal",
        "approval-request",
    ]
    assert [event["type"] for event in events] == expected_event_types, events
    assert events[0] == {
        "type": "command-batch",
        "purpose": "freeze-and-discover",
    }, events[0]
revalidation_events = [event for event in events if event["type"] == "revalidation"]
assert len(revalidation_events) == policy["preapproval_revalidation_batches"], events
application_events = [event for event in events if event["type"] == "application-command"]
assert len(application_events) == policy["unchanged_application_commands"], events

direct_reads = Counter()
candidate_reads = Counter()
for event in events:
    if event["type"] == "read" and event.get("role") == "direct-anchor":
        direct_reads[(event["path"], event["sha256"])] += 1
    if event["type"] == "read" and event.get("role") == "candidate":
        candidate_reads[(event["path"], event["sha256"])] += 1
if eligible:
    current_hashes = {}
    for relative in [*candidate_paths, *direct_anchor_paths]:
        assert relative in manifest_files, f"missing manifest file: {relative}"
        digest = hashlib.sha256((repository / relative).read_bytes()).hexdigest()
        assert digest == manifest_files[relative], (
            relative, digest, manifest_files[relative]
        )
        current_hashes[relative] = digest
    expected_direct_reads = Counter({
        (path, current_hashes[path]): 1 + policy["repeat_direct_anchor_reads"]
        for path in direct_anchor_paths
    })
    expected_candidate_reads = Counter({
        (path, current_hashes[path]): 1 for path in candidate_paths
    })
    assert direct_reads == expected_direct_reads, direct_reads
    assert candidate_reads == expected_candidate_reads, candidate_reads

metrics = trace["metrics"]
assert set(metrics) == set(policy["performance_measurements"]), metrics
assert all(value is None or isinstance(value, (int, float)) for value in metrics.values())

repository = repository_path.resolve()
state = state_path.resolve()
actual_manifest = []
for path in sorted(repository.rglob("*")):
    if ".git" in path.relative_to(repository).parts:
        continue
    relative = path.relative_to(repository).as_posix()
    if path.is_symlink():
        actual_manifest.append(("symlink", relative, str(path.readlink())))
    elif path.is_file():
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        actual_manifest.append(("file", relative, digest))

assert actual_manifest == expected_manifest, "the sparse fixture changed before approval"

actual_status = "\n".join(all_status) + ("\n" if all_status else "")
assert actual_status == (state / "git-status.txt").read_text(encoding="utf-8")
PY

snapshotter="$TEST_ROOT/snapshot-fixture.py"
cat > "$snapshotter" <<'PY'
import hashlib
import pathlib
import subprocess
import sys

repository, state = map(lambda value: pathlib.Path(value).resolve(), sys.argv[1:])
manifest = []
for path in sorted(repository.rglob("*")):
    if ".git" in path.relative_to(repository).parts:
        continue
    relative = path.relative_to(repository).as_posix()
    if path.is_symlink():
        manifest.append(("symlink", relative, str(path.readlink())))
    elif path.is_file():
        manifest.append(("file", relative, hashlib.sha256(path.read_bytes()).hexdigest()))
(state / "manifest.tsv").write_text(
    "".join("\t".join(row) + "\n" for row in manifest), encoding="utf-8"
)
status = subprocess.run(
    ["git", "-C", str(repository), "status", "--porcelain=v1", "--untracked-files=all"],
    check=True,
    capture_output=True,
    text=True,
).stdout
(state / "git-status.txt").write_text(status, encoding="utf-8")
PY

fixture_repo="$TEST_ROOT/repository"
state_dir="$TEST_ROOT/state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$fixture_repo" "$state_dir" >/dev/null

good_trace="$TEST_ROOT/good-trace.json"
cat > "$good_trace" <<'JSON'
{
  "fixture": "sparse-python-service",
  "scenario": "measured-sparse-component-applicability",
  "path": "clean-additive-fast-path",
  "context": {
    "risk_class": "R2",
    "r2_triggers": ["already-supplied-component-applicability"],
    "target_states": {
      "AGENTS.md": {"state": "absent", "parent": "physical"},
      "ARCHITECTURE.md": {"state": "absent", "parent": "physical"}
    },
    "target_scope": "project-documents",
    "mutation_shape": "additions-only",
    "git_state": {"relevant": "clean", "unrelated": "clean"},
    "candidates": "physical",
    "candidate_paths": [
      ".agents/templates/AGENTS.md",
      ".agents/templates/ARCHITECTURE.md"
    ],
    "direct_anchors": "physical-nonsensitive",
    "direct_anchor_paths": ["pyproject.toml", "src/ledger_service.py"],
    "component_applicability": "already-supplied",
    "scope_resolved": true,
    "existing_meaning": false,
    "conflict": false,
    "deletion": false,
    "weakening": false,
    "new_dependency": false,
    "boundary_change": false,
    "external_effect": false,
    "audit_need": false
  },
  "events": [
    {"type": "command-batch", "purpose": "freeze-and-discover"},
    {"type": "read", "role": "direct-anchor", "path": "pyproject.toml", "sha256": "1afa0e8ce967412bbaa78639d31e86e18626bceb90bfc3787ed134bed1a031ff"},
    {"type": "read", "role": "direct-anchor", "path": "src/ledger_service.py", "sha256": "47321d5151d55fda3c8780d95ee58096103b27b659b59aa4e39025a95fa94e4a"},
    {"type": "read", "role": "candidate", "path": ".agents/templates/AGENTS.md", "sha256": "e2d2e0afb19964b1ae8d0f7f4a4902f3b75c2511103efebdd331e2f6b7292b55"},
    {"type": "read", "role": "candidate", "path": ".agents/templates/ARCHITECTURE.md", "sha256": "8c1ea19e94cf1694183a45aecfa7da3356da3bc54e771709345291769918cc53"},
    {"type": "proposal", "targets": ["AGENTS.md", "ARCHITECTURE.md"], "ledger_form": "concise-target-scoped-disposition", "exact_diff": true},
    {"type": "approval-request", "scope": "semantic-and-exact-patch"}
  ],
  "metrics": {
    "command_batches": 2,
    "elapsed_seconds": null,
    "total_tokens": null
  }
}
JSON

# Keep the deterministic behavior trace bound to the destination repository's
# adapted fixture/template bytes rather than to the source repository hashes.
python3 - "$good_trace" "$state_dir/manifest.tsv" <<'PY'
import json
import pathlib
import sys

trace_path = pathlib.Path(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2])
digests = {}
for line in manifest_path.read_text(encoding="utf-8").splitlines():
    kind, relative, value = line.split("\t", 2)
    if kind == "file":
        digests[relative] = value
trace = json.loads(trace_path.read_text(encoding="utf-8"))
for event in trace["events"]:
    if event.get("type") == "read":
        event["sha256"] = digests[event["path"]]
trace_path.write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
PY

verify_trace() {
  python3 "$verifier" "${1}" "${2:-$fixture_repo}" "${3:-$state_dir}" \
    "$EVAL_ROOT/evals.json" "${4:-$SKILL_PATH}"
}

verify_trace "$good_trace"

python3 - "$good_trace" "$TEST_ROOT" <<'PY'
import copy
import json
import pathlib
import sys

source = json.load(open(sys.argv[1], encoding="utf-8"))
target = pathlib.Path(sys.argv[2])

mutations = {}

case = copy.deepcopy(source)
case["events"].append({"type": "approval-request"})
mutations["redundant-approval"] = case

case = copy.deepcopy(source)
approval = next(event for event in case["events"] if event["type"] == "approval-request")
approval["scope"] = "semantic-summary-only"
mutations["split-approval"] = case

case = copy.deepcopy(source)
case["events"][4:4] = [{"type": "revalidation", "phase": "preapproval"}]
mutations["premature-revalidation"] = case

case = copy.deepcopy(source)
case["events"].append({"type": "application-command", "reason": "unchanged-behavior"})
mutations["unchanged-application-command"] = case

case = copy.deepcopy(source)
case["events"].append({"type": "artifact", "path": ".agents/project/onboarding/preservation-ledger.md", "durable": True})
mutations["durable-ledger"] = case

case = copy.deepcopy(source)
case["events"].append({"type": "reference-load", "path": "references/document-reconciliation.md"})
mutations["eager-detailed-reference"] = case

case = copy.deepcopy(source)
case["events"].append({"type": "read", "role": "direct-anchor", "path": "pyproject.toml"})
mutations["repeated-anchor-read"] = case

case = copy.deepcopy(source)
case["events"] = [
    event for event in case["events"]
    if not (event["type"] == "read" and event.get("path") == "src/ledger_service.py")
]
mutations["skipped-anchor-read"] = case

case = copy.deepcopy(source)
proposal = next(event for event in case["events"] if event["type"] == "proposal")
proposal["ledger_form"] = "row-level-ledger"
mutations["row-level-ledger"] = case

case = copy.deepcopy(source)
proposal = next(event for event in case["events"] if event["type"] == "proposal")
proposal["targets"].append("README.md")
mutations["expanded-targets"] = case

case = copy.deepcopy(source)
case["events"].append({"type": "write", "path": "AGENTS.md"})
mutations["preapproval-write"] = case

case = copy.deepcopy(source)
case["context"]["candidate_paths"] = []
case["events"] = [
    event for event in case["events"] if event.get("role") != "candidate"
]
mutations["omitted-candidate-inputs"] = case

case = copy.deepcopy(source)
case["context"]["direct_anchor_paths"] = []
case["events"] = [
    event for event in case["events"] if event.get("role") != "direct-anchor"
]
mutations["omitted-direct-anchor-inputs"] = case

case = copy.deepcopy(source)
anchor_read = next(
    event for event in case["events"]
    if event.get("role") == "direct-anchor" and event["path"] == "pyproject.toml"
)
anchor_read.pop("sha256")
mutations["missing-anchor-sha256"] = case

case = copy.deepcopy(source)
candidate_read = next(
    event for event in case["events"]
    if event.get("role") == "candidate"
    and event["path"] == ".agents/templates/AGENTS.md"
)
candidate_read["sha256"] = "0" * 64
mutations["wrong-candidate-sha256"] = case

case = copy.deepcopy(source)
case["events"][0], case["events"][1] = case["events"][1], case["events"][0]
mutations["read-before-discovery"] = case

case = copy.deepcopy(source)
case["events"].append({"type": "network-call", "target": "example.invalid"})
mutations["unknown-event"] = case

case = copy.deepcopy(source)
case["events"].insert(
    -1,
    {"type": "external-effect", "target": "issue-tracker", "action": "create"},
)
mutations["effect-event"] = case

case = copy.deepcopy(source)
proposal_index = next(
    index for index, event in enumerate(case["events"])
    if event["type"] == "proposal"
)
approval = case["events"].pop()
case["events"].insert(proposal_index, approval)
mutations["approval-before-proposal"] = case

case = copy.deepcopy(source)
case["context"]["audit_need"] = True
case["events"].append(
    {
        "type": "artifact",
        "path": ".agents/project/onboarding/preservation-ledger.md",
        "durable": True,
        "reason": "audit-need",
    }
)
mutations["audit-artifact-after-approval"] = case

for name, value in mutations.items():
    (target / f"bad-{name}.json").write_text(
        json.dumps(value, indent=2) + "\n", encoding="utf-8"
    )

r1 = copy.deepcopy(source)
r1["scenario"] = "general-clean-r1"
r1["context"]["risk_class"] = "R1"
r1["context"]["r2_triggers"] = []
r1["context"]["component_applicability"] = "none"
r1["context"]["target_states"] = {
    "AGENTS.md": {"state": "absent", "parent": "physical"},
}
r1["context"]["candidate_paths"] = [".agents/templates/AGENTS.md"]
r1["context"]["direct_anchor_paths"] = ["pyproject.toml"]
r1["events"] = [
    event for event in r1["events"]
    if not (
        event.get("path")
        in {"src/ledger_service.py", ".agents/templates/ARCHITECTURE.md"}
    )
]
r1_proposal = next(event for event in r1["events"] if event["type"] == "proposal")
r1_proposal["targets"] = ["AGENTS.md"]
(target / "good-r1.json").write_text(json.dumps(r1, indent=2) + "\n", encoding="utf-8")

audit = copy.deepcopy(source)
audit["context"]["audit_need"] = True
audit["events"].insert(
    -2,
    {
        "type": "artifact",
        "path": ".agents/project/onboarding/preservation-ledger.md",
        "durable": True,
        "reason": "audit-need",
    },
)
(target / "good-audit-ledger.json").write_text(
    json.dumps(audit, indent=2) + "\n", encoding="utf-8"
)

unrelated_dirty = copy.deepcopy(source)
unrelated_dirty["scenario"] = "authorized-unrelated-dirty-state"
unrelated_dirty["context"]["git_state"]["unrelated"] = "dirty"
(target / "good-unrelated-dirty.json").write_text(
    json.dumps(unrelated_dirty, indent=2) + "\n", encoding="utf-8"
)

relevant_dirty = copy.deepcopy(source)
relevant_dirty["scenario"] = "relevant-anchor-dirty-state"
relevant_dirty["context"]["git_state"]["relevant"] = "dirty"
(target / "fixture-fast-relevant-dirty.json").write_text(
    json.dumps(relevant_dirty, indent=2) + "\n", encoding="utf-8"
)
relevant_dirty_fallback = copy.deepcopy(relevant_dirty)
relevant_dirty_fallback["path"] = "detailed-reconciliation"
relevant_dirty_fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-relevant-dirty.json").write_text(
    json.dumps(relevant_dirty_fallback, indent=2) + "\n", encoding="utf-8"
)

hardlinked = copy.deepcopy(source)
hardlinked["scenario"] = "hardlinked-direct-anchor"
(target / "fixture-fast-hardlinked-anchor.json").write_text(
    json.dumps(hardlinked, indent=2) + "\n", encoding="utf-8"
)
hardlinked_fallback = copy.deepcopy(hardlinked)
hardlinked_fallback["path"] = "detailed-reconciliation"
hardlinked_fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-hardlinked-anchor.json").write_text(
    json.dumps(hardlinked_fallback, indent=2) + "\n", encoding="utf-8"
)

symlink_ancestor_target = copy.deepcopy(r1)
symlink_ancestor_target["scenario"] = "symlink-ancestor-target"
symlink_ancestor_target["context"]["target_states"] = {
    "docs/team/AGENTS.md": {"state": "absent", "parent": "physical"},
}
target_proposal = next(
    event for event in symlink_ancestor_target["events"]
    if event["type"] == "proposal"
)
target_proposal["targets"] = ["docs/team/AGENTS.md"]
(target / "fixture-fast-symlink-ancestor-target.json").write_text(
    json.dumps(symlink_ancestor_target, indent=2) + "\n", encoding="utf-8"
)
target_fallback = copy.deepcopy(symlink_ancestor_target)
target_fallback["context"]["target_states"]["docs/team/AGENTS.md"][
    "parent"
] = "nonphysical"
target_fallback["path"] = "detailed-reconciliation"
target_fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-symlink-ancestor-target.json").write_text(
    json.dumps(target_fallback, indent=2) + "\n", encoding="utf-8"
)

symlink_ancestor_anchor = copy.deepcopy(r1)
symlink_ancestor_anchor["scenario"] = "symlink-ancestor-direct-anchor"
symlink_ancestor_anchor["context"]["direct_anchor_paths"] = [
    "linked-src/sub/anchor.py"
]
anchor_read = next(
    event for event in symlink_ancestor_anchor["events"]
    if event["type"] == "read" and event.get("role") == "direct-anchor"
)
anchor_read["path"] = "linked-src/sub/anchor.py"
(target / "fixture-fast-symlink-ancestor-anchor.json").write_text(
    json.dumps(symlink_ancestor_anchor, indent=2) + "\n", encoding="utf-8"
)
anchor_fallback = copy.deepcopy(symlink_ancestor_anchor)
anchor_fallback["context"]["direct_anchors"] = "nonphysical"
anchor_fallback["path"] = "detailed-reconciliation"
anchor_fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-symlink-ancestor-anchor.json").write_text(
    json.dumps(anchor_fallback, indent=2) + "\n", encoding="utf-8"
)

existing_target_fallback = copy.deepcopy(source)
existing_target_fallback["scenario"] = "existing-narrow-r2-target"
existing_target_fallback["context"]["target_states"]["AGENTS.md"] = {
    "state": "clean-regular",
    "parent": "physical",
}
existing_target_fallback["path"] = "detailed-reconciliation"
existing_target_fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-existing-r2-target.json").write_text(
    json.dumps(existing_target_fallback, indent=2) + "\n", encoding="utf-8"
)

predicate_mutations = {}

case = copy.deepcopy(r1)
case["context"]["target_states"]["AGENTS.md"]["parent"] = "symlink"
predicate_mutations["r1-nonphysical-parent"] = case

case = copy.deepcopy(r1)
case["context"]["conflict"] = True
predicate_mutations["r1-conflict"] = case

case = copy.deepcopy(r1)
case["context"]["mutation_shape"] = "replacement"
predicate_mutations["r1-nonadditive"] = case

case = copy.deepcopy(source)
case["context"]["risk_class"] = "R3"
predicate_mutations["r3"] = case

case = copy.deepcopy(source)
case["context"]["risk_class"] = "R1"
predicate_mutations["r1-with-r2-trigger"] = case

case = copy.deepcopy(source)
case["context"]["risk_class"] = "R1"
case["context"]["r2_triggers"] = []
predicate_mutations["r2-context-relabelled-r1"] = case

case = copy.deepcopy(source)
case["context"]["r2_triggers"] = ["public-contract"]
predicate_mutations["other-r2-trigger"] = case

case = copy.deepcopy(source)
case["context"]["r2_triggers"].append("public-contract")
predicate_mutations["multiple-r2-triggers"] = case

case = copy.deepcopy(source)
case["context"]["target_scope"] = "application-source"
predicate_mutations["non-document-target"] = case

case = copy.deepcopy(source)
case["context"]["mutation_shape"] = "replacement"
predicate_mutations["nonadditive"] = case

case = copy.deepcopy(source)
case["context"]["target_states"]["AGENTS.md"]["state"] = "regular"
predicate_mutations["existing-target"] = case

case = copy.deepcopy(source)
case["context"]["target_states"]["README.md"] = {
    "state": "absent",
    "parent": "physical",
}
predicate_mutations["third-target"] = case

case = copy.deepcopy(source)
case["context"]["target_states"]["ARCHITECTURE.md"]["parent"] = "symlink"
predicate_mutations["nonphysical-parent"] = case

case = copy.deepcopy(source)
case["context"]["candidates"] = "symlink"
predicate_mutations["nonphysical-candidate"] = case

case = copy.deepcopy(source)
case["context"]["direct_anchors"] = "sensitive"
predicate_mutations["sensitive-anchor"] = case

case = copy.deepcopy(source)
case["context"]["component_applicability"] = "newly-inferred"
predicate_mutations["new-component-decision"] = case

case = copy.deepcopy(source)
case["context"]["scope_resolved"] = False
predicate_mutations["unresolved-scope"] = case

for field in (
    "existing_meaning",
    "conflict",
    "deletion",
    "weakening",
    "new_dependency",
    "boundary_change",
    "external_effect",
):
    case = copy.deepcopy(source)
    case["context"][field] = True
    predicate_mutations[field.replace("_", "-")] = case

for name, value in predicate_mutations.items():
    (target / f"bad-fast-predicate-{name}.json").write_text(
        json.dumps(value, indent=2) + "\n", encoding="utf-8"
    )
    if name not in {
        "r1-nonphysical-parent",
        "existing-target",
        "nonphysical-parent",
    }:
        fallback = copy.deepcopy(value)
        fallback["path"] = "detailed-reconciliation"
        fallback["events"] = [
            {
                "type": "reference-load",
                "path": "references/document-reconciliation.md",
            }
        ]
        (target / f"good-fallback-{name}.json").write_text(
            json.dumps(fallback, indent=2) + "\n", encoding="utf-8"
        )
PY

verify_trace "$TEST_ROOT/good-r1.json"
verify_trace "$TEST_ROOT/good-audit-ledger.json"
for fallback_trace in "$TEST_ROOT"/good-fallback-*.json; do
  verify_trace "$fallback_trace"
done

for bad_trace in "$TEST_ROOT"/bad-*.json; do
  if verify_trace "$bad_trace" >/dev/null 2>&1; then
    echo "Fast-path verifier accepted invalid behavior: $(basename "$bad_trace")" >&2
    exit 1
  fi
done

unrelated_repo="$TEST_ROOT/unrelated-dirty-repository"
unrelated_state="$TEST_ROOT/unrelated-dirty-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$unrelated_repo" "$unrelated_state" >/dev/null
mkdir -p "$unrelated_repo/docs"
printf 'unrelated tracked evidence\n' > "$unrelated_repo/docs/notes.txt"
git -C "$unrelated_repo" add docs/notes.txt
git -C "$unrelated_repo" commit -qm 'add unrelated tracked fixture'
git -C "$unrelated_repo" update-index --assume-unchanged docs/notes.txt
printf 'hidden unrelated bytes\n' >> "$unrelated_repo/docs/notes.txt"
mkdir -p "$unrelated_repo/.agents/project"
printf 'unrelated local agent state\n' > \
  "$unrelated_repo/.agents/project/local.md"
printf 'owner scratch state\n' > "$unrelated_repo/LOCAL-NOTES.txt"
python3 "$snapshotter" "$unrelated_repo" "$unrelated_state"
verify_trace "$TEST_ROOT/good-unrelated-dirty.json" \
  "$unrelated_repo" "$unrelated_state"

relevant_repo="$TEST_ROOT/relevant-dirty-repository"
relevant_state="$TEST_ROOT/relevant-dirty-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$relevant_repo" "$relevant_state" >/dev/null
printf '\n# owner work in progress\n' >> "$relevant_repo/pyproject.toml"
python3 "$snapshotter" "$relevant_repo" "$relevant_state"
if verify_trace "$TEST_ROOT/fixture-fast-relevant-dirty.json" \
    "$relevant_repo" "$relevant_state" >/dev/null 2>&1; then
  echo "Fast path accepted a dirty direct evidence anchor" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-relevant-dirty.json" \
  "$relevant_repo" "$relevant_state"

hardlink_repo="$TEST_ROOT/hardlink-repository"
hardlink_state="$TEST_ROOT/hardlink-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$hardlink_repo" "$hardlink_state" >/dev/null
ln "$hardlink_repo/pyproject.toml" "$TEST_ROOT/pyproject-hardlink.toml"
if verify_trace "$TEST_ROOT/fixture-fast-hardlinked-anchor.json" \
    "$hardlink_repo" "$hardlink_state" >/dev/null 2>&1; then
  echo "Fast path accepted a hardlinked direct evidence anchor" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-hardlinked-anchor.json" \
  "$hardlink_repo" "$hardlink_state"

symlink_target_repo="$TEST_ROOT/symlink-target-repository"
symlink_target_state="$TEST_ROOT/symlink-target-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$symlink_target_repo" "$symlink_target_state" >/dev/null
mkdir -p "$symlink_target_repo/real-docs/team"
printf 'tracked physical target parent\n' > \
  "$symlink_target_repo/real-docs/team/README.md"
ln -s real-docs "$symlink_target_repo/docs"
git -C "$symlink_target_repo" add real-docs/team/README.md docs
git -C "$symlink_target_repo" commit -qm 'add symlink-ancestor target fixture'
python3 "$snapshotter" "$symlink_target_repo" "$symlink_target_state"
if verify_trace "$TEST_ROOT/fixture-fast-symlink-ancestor-target.json" \
    "$symlink_target_repo" "$symlink_target_state" >/dev/null 2>&1; then
  echo "Fast path accepted a target below a symlink ancestor" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-symlink-ancestor-target.json" \
  "$symlink_target_repo" "$symlink_target_state"

symlink_anchor_repo="$TEST_ROOT/symlink-anchor-repository"
symlink_anchor_state="$TEST_ROOT/symlink-anchor-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$symlink_anchor_repo" "$symlink_anchor_state" >/dev/null
mkdir -p "$symlink_anchor_repo/real-src/sub"
printf 'ANCHOR = true\n' > "$symlink_anchor_repo/real-src/sub/anchor.py"
ln -s real-src "$symlink_anchor_repo/linked-src"
git -C "$symlink_anchor_repo" add real-src/sub/anchor.py linked-src
git -C "$symlink_anchor_repo" commit -qm 'add symlink-ancestor anchor fixture'
python3 "$snapshotter" "$symlink_anchor_repo" "$symlink_anchor_state"
if verify_trace "$TEST_ROOT/fixture-fast-symlink-ancestor-anchor.json" \
    "$symlink_anchor_repo" "$symlink_anchor_state" >/dev/null 2>&1; then
  echo "Fast path accepted a direct anchor below a symlink ancestor" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-symlink-ancestor-anchor.json" \
  "$symlink_anchor_repo" "$symlink_anchor_state"

existing_target_repo="$TEST_ROOT/existing-target-repository"
existing_target_state="$TEST_ROOT/existing-target-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$existing_target_repo" "$existing_target_state" >/dev/null
printf '# Existing agent guidance\n' > "$existing_target_repo/AGENTS.md"
git -C "$existing_target_repo" add AGENTS.md
git -C "$existing_target_repo" commit -qm 'add existing fast-path target fixture'
python3 "$snapshotter" "$existing_target_repo" "$existing_target_state"
if verify_trace "$good_trace" \
    "$existing_target_repo" "$existing_target_state" >/dev/null 2>&1; then
  echo "Fast path trusted a trace that falsely claimed an existing target was absent" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-existing-r2-target.json" \
  "$existing_target_repo" "$existing_target_state"

assume_unchanged_repo="$TEST_ROOT/assume-unchanged-repository"
assume_unchanged_state="$TEST_ROOT/assume-unchanged-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$assume_unchanged_repo" \
  "$assume_unchanged_state" >/dev/null
git -C "$assume_unchanged_repo" update-index --assume-unchanged pyproject.toml
printf '\n# bytes hidden from git status\n' >> \
  "$assume_unchanged_repo/pyproject.toml"
python3 "$snapshotter" "$assume_unchanged_repo" "$assume_unchanged_state"
python3 - "$good_trace" "$TEST_ROOT" "$assume_unchanged_repo" <<'PY'
import copy
import hashlib
import json
import pathlib
import sys

source = json.load(open(sys.argv[1], encoding="utf-8"))
target = pathlib.Path(sys.argv[2])
repository = pathlib.Path(sys.argv[3])
fast = copy.deepcopy(source)
fast["scenario"] = "assume-unchanged-direct-anchor"
anchor = next(
    event for event in fast["events"]
    if event.get("role") == "direct-anchor" and event["path"] == "pyproject.toml"
)
anchor["sha256"] = hashlib.sha256(
    (repository / "pyproject.toml").read_bytes()
).hexdigest()
(target / "fixture-fast-assume-unchanged.json").write_text(
    json.dumps(fast, indent=2) + "\n", encoding="utf-8"
)
fallback = copy.deepcopy(fast)
fallback["path"] = "detailed-reconciliation"
fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-assume-unchanged.json").write_text(
    json.dumps(fallback, indent=2) + "\n", encoding="utf-8"
)
PY
if verify_trace "$TEST_ROOT/fixture-fast-assume-unchanged.json" \
    "$assume_unchanged_repo" "$assume_unchanged_state" >/dev/null 2>&1; then
  echo "Fast path accepted assume-unchanged bytes hidden from git status" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-assume-unchanged.json" \
  "$assume_unchanged_repo" "$assume_unchanged_state"

skip_worktree_repo="$TEST_ROOT/skip-worktree-repository"
skip_worktree_state="$TEST_ROOT/skip-worktree-state"
bash "$EVAL_ROOT/scripts/create-fixture.sh" \
  sparse-python-service "$skip_worktree_repo" "$skip_worktree_state" >/dev/null
git -C "$skip_worktree_repo" update-index --skip-worktree \
  .agents/templates/AGENTS.md
printf '\nHidden candidate bytes.\n' >> \
  "$skip_worktree_repo/.agents/templates/AGENTS.md"
python3 "$snapshotter" "$skip_worktree_repo" "$skip_worktree_state"
python3 - "$good_trace" "$TEST_ROOT" "$skip_worktree_repo" <<'PY'
import copy
import hashlib
import json
import pathlib
import sys

source = json.load(open(sys.argv[1], encoding="utf-8"))
target = pathlib.Path(sys.argv[2])
repository = pathlib.Path(sys.argv[3])
fast = copy.deepcopy(source)
fast["scenario"] = "skip-worktree-candidate"
candidate = next(
    event for event in fast["events"]
    if event.get("role") == "candidate"
    and event["path"] == ".agents/templates/AGENTS.md"
)
candidate["sha256"] = hashlib.sha256(
    (repository / ".agents/templates/AGENTS.md").read_bytes()
).hexdigest()
(target / "fixture-fast-skip-worktree.json").write_text(
    json.dumps(fast, indent=2) + "\n", encoding="utf-8"
)
fallback = copy.deepcopy(fast)
fallback["path"] = "detailed-reconciliation"
fallback["events"] = [
    {"type": "reference-load", "path": "references/document-reconciliation.md"}
]
(target / "fixture-fallback-skip-worktree.json").write_text(
    json.dumps(fallback, indent=2) + "\n", encoding="utf-8"
)
PY
if verify_trace "$TEST_ROOT/fixture-fast-skip-worktree.json" \
    "$skip_worktree_repo" "$skip_worktree_state" >/dev/null 2>&1; then
  echo "Fast path accepted skip-worktree bytes hidden from git status" >&2
  exit 1
fi
verify_trace "$TEST_ROOT/fixture-fallback-skip-worktree.json" \
  "$skip_worktree_repo" "$skip_worktree_state"

python3 - "$SKILL_PATH" "$TEST_ROOT" <<'PY'
import json
import pathlib
import sys

skill_path = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
source = skill_path.read_text(encoding="utf-8")
start = "<!-- BEGIN CLEAN-ADDITIVE FAST-PATH CONTRACT -->"
end = "<!-- END CLEAN-ADDITIVE FAST-PATH CONTRACT -->"
prefix, remainder = source.split(start, 1)
contract_source, suffix = remainder.split(end, 1)
contract = json.loads(
    contract_source.strip().removeprefix("```json\n").removesuffix("\n```")
)

(target / "mutated-skill-contract-removed.md").write_text(
    prefix + suffix, encoding="utf-8"
)
for field in (
    "git_cleanliness_scope",
    "tracked_index_flag_policy",
    "read_evidence_policy",
    "unrelated_dirty_policy",
    "existing_file_link_count",
    "approval_decisions",
    "predicate_failure_reference",
):
    mutation = dict(contract)
    mutation.pop(field)
    replacement = "\n```json\n" + json.dumps(mutation, indent=2) + "\n```\n"
    (target / f"mutated-skill-without-{field}.md").write_text(
        prefix + start + replacement + end + suffix, encoding="utf-8"
    )

mutation = dict(contract)
mutation["git_cleanliness_scope"] = "whole-worktree-and-index"
mutation["unrelated_dirty_policy"] = "detailed-reconciliation"
replacement = "\n```json\n" + json.dumps(mutation, indent=2) + "\n```\n"
(target / "mutated-skill-whole-worktree-reversion.md").write_text(
    prefix + start + replacement + end + suffix, encoding="utf-8"
)
PY

for mutated_skill in "$TEST_ROOT"/mutated-skill-*.md; do
  if verify_trace "$good_trace" "$fixture_repo" "$state_dir" \
      "$mutated_skill" >/dev/null 2>&1; then
    echo "Verifier accepted removed or reverted SKILL.md contract: $(basename "$mutated_skill")" >&2
    exit 1
  fi
done
verify_trace "$good_trace"

if [ "${1:-}" = "--verify" ]; then
  [ "$#" -eq 4 ] || {
    echo "Usage: $0 --verify TRACE REPOSITORY STATE_DIR" >&2
    exit 2
  }
  python3 "$verifier" "$2" "$3" "$4" "$EVAL_ROOT/evals.json" "$SKILL_PATH"
fi

echo "Onboard-project clean-additive fast-path behavior contract passed"
