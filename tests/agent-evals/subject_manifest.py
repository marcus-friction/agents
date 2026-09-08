#!/usr/bin/env python3
"""Select live cases and bind the exact repository subject evaluated by v2."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys
from typing import Any


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def physical_mode(path: Path) -> int:
    target = Path(os.path.abspath(path))
    current = Path(target.anchor)
    for part in target.parts[1:]:
        current /= part
        mode = current.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise ValueError(f"manifest input path crosses a symlink: {current}")
    return target.lstat().st_mode


def file_record(path: Path, relative: str) -> dict[str, Any]:
    mode = physical_mode(path)
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise ValueError(f"manifest input must be a physical regular file: {relative}")
    data = path.read_bytes()
    return {
        "path": relative,
        "sha256": digest_bytes(data),
        "size": len(data),
        "mode": stat.S_IMODE(mode),
    }


def executable_record(path: Path) -> dict[str, Any]:
    target = Path(os.path.abspath(path))
    mode = physical_mode(target)
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise ValueError(f"executor must be a physical regular file: {target}")
    data = target.read_bytes()
    return {
        "path": str(target),
        "sha256": digest_bytes(data),
        "size": len(data),
        "mode": stat.S_IMODE(mode),
    }


def git_environment() -> dict[str, str]:
    environment = {
        key: value for key, value in os.environ.items() if not key.startswith("GIT_")
    }
    environment.update(
        {
            "GIT_ASKPASS": "/usr/bin/false",
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_SYSTEM": os.devnull,
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_OPTIONAL_LOCKS": "0",
            "GIT_TERMINAL_PROMPT": "0",
        }
    )
    return environment


def run_git(repo: Path, *arguments: str, text: bool = False) -> bytes | str:
    completed = subprocess.run(
        [
            "git",
            "--no-replace-objects",
            "-c",
            "core.hooksPath=/dev/null",
            "-c",
            "core.fsmonitor=false",
            "-c",
            "credential.helper=",
            *arguments,
        ],
        cwd=repo,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=text,
        env=git_environment(),
    )
    return completed.stdout


def full_commit(repo: Path, value: str) -> str:
    result = run_git(repo, "rev-parse", "--verify", f"{value}^{{commit}}", text=True)
    return str(result).strip()


def changed_paths(repo: Path, base_ref: str) -> list[str]:
    commands = (
        ("diff", "--no-renames", "--name-only", "-z", f"{base_ref}...HEAD"),
        ("diff", "--no-renames", "--cached", "--name-only", "-z"),
        ("diff", "--no-renames", "--name-only", "-z"),
        ("ls-files", "--others", "--exclude-standard", "-z"),
    )
    paths: set[str] = set()
    for command in commands:
        output = run_git(repo, *command)
        assert isinstance(output, bytes)
        for raw in output.split(b"\0"):
            if raw:
                paths.add(raw.decode("utf-8"))
    return sorted(paths)


def path_matches(relative: str, rule: dict[str, Any]) -> bool:
    declared = rule.get("path")
    if not isinstance(declared, str) or not declared:
        return False
    if rule.get("path_kind") == "exact":
        return relative == declared
    if rule.get("path_kind") == "root":
        return relative == declared or relative.startswith(declared + "/")
    return False


CASE_ID_PATTERN = re.compile(r"^v2\.[a-z0-9]+(?:[.-][a-z0-9]+)*$")
RESULT_POINTER_PATTERN = re.compile(r"^/decisions/d[1-6]$")


def safe_relative(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValueError(f"{field} must be a non-empty relative path")
    if "\\" in value or "\0" in value:
        raise ValueError(f"{field} must use normalized POSIX path syntax: {value!r}")
    parts = value.split("/")
    if value.startswith("/") or any(part in {"", ".", ".."} for part in parts):
        raise ValueError(f"{field} must be a normalized repository-relative path: {value!r}")
    if PurePosixPath(value).is_absolute() or PurePosixPath(value).as_posix() != value:
        raise ValueError(f"{field} must be a normalized repository-relative path: {value!r}")
    return value


def validate_path_rule(rule: Any, field: str) -> None:
    if not isinstance(rule, dict) or rule.get("path_kind") not in {"exact", "root"}:
        raise ValueError(f"{field} must contain exact/root path rules")
    safe_relative(rule.get("path"), f"{field}.path")


def load_registry(path: Path) -> dict[str, Any]:
    mode = physical_mode(path)
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise ValueError(f"case registry must be a physical regular file: {path}")
    registry = json.loads(path.read_text(encoding="utf-8"))
    if registry.get("schema_version") != 2 or not isinstance(registry.get("cases"), list):
        raise ValueError("case registry must use schema_version 2")
    case_ids = [case.get("id") for case in registry["cases"]]
    if any(not isinstance(case_id, str) or not case_id for case_id in case_ids):
        raise ValueError("every live case needs a non-empty id")
    if len(case_ids) != len(set(case_ids)):
        raise ValueError("live case ids must be unique and immutable")
    for rule in registry.get("deterministic_only", []):
        validate_path_rule(rule, "deterministic_only")
        if not isinstance(rule.get("reason"), str) or not rule["reason"].strip():
            raise ValueError("deterministic_only rules require a reason")
    required = {
        "id",
        "affected_paths",
        "risk_class",
        "intent",
        "fixture",
        "prompt",
        "context_paths",
        "executor_mode",
        "capability_profile",
        "permitted_fixture_mutations",
        "permitted_fake_services",
        "result_assertions",
        "state_assertions",
        "event_assertions",
        "threshold",
        "risk_cluster",
    }
    for case in registry["cases"]:
        case_id = case["id"]
        if not CASE_ID_PATTERN.fullmatch(case_id):
            raise ValueError(f"case id is not path-safe: {case_id!r}")
        missing = required - case.keys()
        if missing:
            raise ValueError(f"case {case_id} is missing fields: {sorted(missing)!r}")
        if not isinstance(case["affected_paths"], list) or not case["affected_paths"]:
            raise ValueError(f"case {case_id} needs affected paths")
        for rule in case["affected_paths"]:
            validate_path_rule(rule, f"case {case_id} affected_paths")
        fixture = safe_relative(case["fixture"], f"case {case_id} fixture")
        prompt = safe_relative(case["prompt"], f"case {case_id} prompt")
        fixture_prefix = "tests/agent-evals/fixtures/"
        if not fixture.startswith(fixture_prefix) or not prompt.startswith(fixture_prefix):
            raise ValueError(f"case {case_id} fixture and prompt must stay in {fixture_prefix}")
        if not isinstance(case["context_paths"], list) or not case["context_paths"]:
            raise ValueError(f"case {case_id} needs context paths")
        for relative in case["context_paths"]:
            safe_relative(relative, f"case {case_id} context path")
        if not isinstance(case["permitted_fixture_mutations"], list):
            raise ValueError(f"case {case_id} permitted fixture mutations must be a list")
        for relative in case["permitted_fixture_mutations"]:
            safe_relative(relative, f"case {case_id} permitted fixture mutation")
        if case["risk_class"] not in {"R0", "R1", "R2", "R3"}:
            raise ValueError(f"case {case_id} has an invalid risk class")
        if not isinstance(case["risk_cluster"], str) or not case["risk_cluster"].strip():
            raise ValueError(f"case {case_id} needs a risk cluster")
        if case["permitted_fake_services"] != []:
            raise ValueError(f"case {case_id} must not permit external service effects")
        for field in ("result_assertions", "state_assertions", "event_assertions"):
            assertions = case[field]
            if not isinstance(assertions, list) or not assertions:
                raise ValueError(f"case {case_id} needs {field}")
            assertion_ids = [assertion.get("id") for assertion in assertions if isinstance(assertion, dict)]
            if len(assertion_ids) != len(assertions) or any(
                not isinstance(assertion_id, str) or not assertion_id
                for assertion_id in assertion_ids
            ):
                raise ValueError(f"case {case_id} has invalid {field} ids")
            if len(assertion_ids) != len(set(assertion_ids)):
                raise ValueError(f"case {case_id} has duplicate {field} ids")
        result_pointers = [
            assertion.get("pointer") for assertion in case["result_assertions"]
        ]
        if any(
            not isinstance(pointer, str)
            or not RESULT_POINTER_PATTERN.fullmatch(pointer)
            for pointer in result_pointers
        ):
            raise ValueError(f"case {case_id} has an invalid result assertion pointer")
        if len(result_pointers) != len(set(result_pointers)):
            raise ValueError(f"case {case_id} has duplicate result assertion pointers")
        for assertion in case["result_assertions"]:
            operator = assertion.get("operator")
            expected = assertion.get("expected")
            if operator == "equals":
                if not isinstance(expected, (bool, int)):
                    raise ValueError(
                        f"case {case_id} equals assertions must use semantic boolean/integer values"
                    )
            elif operator == "set-equals":
                if (
                    not isinstance(expected, list)
                    or not expected
                    or len(expected) != len(set(expected))
                    or any(not isinstance(item, str) or not item for item in expected)
                ):
                    raise ValueError(
                        f"case {case_id} set-equals assertions need unique non-empty strings"
                    )
            else:
                raise ValueError(f"case {case_id} has an unsupported result assertion operator")
        expected_capability = "read-only" if case["intent"] == "negative" else "workspace-write"
        if case["intent"] not in {"negative", "positive"} or case["capability_profile"] != expected_capability:
            raise ValueError(f"case {case_id} has an invalid intent/capability pair")
        if case["executor_mode"] != "codex-exec-jsonl":
            raise ValueError(f"case {case_id} has an unsupported executor mode")
        if case["threshold"] != {"required_passes": 3, "runs": 3}:
            raise ValueError(f"case {case_id} must use the registered 3/3 threshold")
    return registry


def select_cases(repo: Path, registry: dict[str, Any], base_ref: str) -> dict[str, Any]:
    base_commit = full_commit(repo, base_ref)
    changed = changed_paths(repo, base_commit)
    selected: set[str] = set()
    unmapped: list[str] = []
    classifications: dict[str, dict[str, Any]] = {}
    for relative in changed:
        case_matches = [
            case["id"]
            for case in registry["cases"]
            if any(path_matches(relative, rule) for rule in case.get("affected_paths", []))
        ]
        deterministic_matches = [
            rule
            for rule in registry.get("deterministic_only", [])
            if path_matches(relative, rule)
        ]
        if case_matches:
            selected.update(case_matches)
            classifications[relative] = {
                "classification": "live-cases",
                "case_ids": sorted(case_matches),
            }
        elif deterministic_matches:
            classifications[relative] = {
                "classification": "deterministic-only",
                "reason": deterministic_matches[0].get("reason", ""),
            }
        else:
            unmapped.append(relative)
            classifications[relative] = {"classification": "unmapped"}
    return {
        "base_ref": base_ref,
        "base_commit": base_commit,
        "head": full_commit(repo, "HEAD"),
        "changed_paths": changed,
        "classifications": classifications,
        "selected_case_ids": sorted(selected),
        "unmapped_paths": unmapped,
    }


def tracked_or_worktree_record(repo: Path, relative: str) -> dict[str, Any]:
    path = repo / relative
    if not path.exists() and not path.is_symlink():
        return {"path": relative, "missing": True}
    return file_record(path, relative)


def untracked_record(repo: Path, relative: str) -> dict[str, Any]:
    path = Path(os.path.abspath(repo / relative))
    current = Path(path.anchor)
    for part in path.parts[1:-1]:
        current /= part
        mode = current.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise ValueError(f"untracked path crosses a symlink ancestor: {current}")
        if not stat.S_ISDIR(mode):
            raise ValueError(f"untracked path ancestor is not a directory: {current}")
    mode = path.lstat().st_mode
    if stat.S_ISLNK(mode):
        target = os.readlink(path)
        target_bytes = os.fsencode(target)
        return {
            "path": relative,
            "type": "symlink",
            "target": target,
            "sha256": digest_bytes(target_bytes),
            "size": len(target_bytes),
            "mode": stat.S_IMODE(mode),
        }
    return file_record(path, relative)


def tree_record(repo: Path, commit: str, relative: str) -> dict[str, Any]:
    try:
        data = run_git(repo, "show", f"{commit}:{relative}")
        mode_text = run_git(repo, "ls-tree", commit, "--", relative, text=True)
    except subprocess.CalledProcessError:
        return {"path": relative, "missing": True}
    assert isinstance(data, bytes)
    mode_fields = str(mode_text).split()
    if not mode_fields:
        return {"path": relative, "missing": True}
    if mode_fields[0] not in {"100644", "100755"}:
        raise ValueError(
            f"comparison context must be a regular file or absent: {relative}"
        )
    mode = int(mode_fields[0], 8) & 0o777
    return {
        "path": relative,
        "sha256": digest_bytes(data),
        "size": len(data),
        "mode": mode,
    }


def expand_physical(repo: Path, relative: str) -> list[str]:
    path = repo / relative
    mode = physical_mode(path)
    if stat.S_ISREG(mode):
        return [relative]
    if not stat.S_ISDIR(mode):
        raise ValueError(f"context path does not exist: {relative}")
    records = []
    for base, directories, files in os.walk(path, followlinks=False):
        base_path = Path(base)
        for name in list(directories):
            child = base_path / name
            if child.is_symlink():
                raise ValueError(
                    f"context path contains a symlink: {child.relative_to(repo).as_posix()}"
                )
        for name in files:
            child = base_path / name
            child_relative = child.relative_to(repo).as_posix()
            file_record(child, child_relative)
            records.append(child_relative)
    return sorted(records)


def fixture_manifest(repo: Path, relative_root: str) -> list[dict[str, Any]]:
    return [
        file_record(repo / relative, relative)
        for relative in expand_physical(repo, relative_root)
    ]


def patch_record(repo: Path, arguments: tuple[str, ...]) -> dict[str, Any]:
    data = run_git(repo, *arguments)
    assert isinstance(data, bytes)
    return {"sha256": digest_bytes(data), "size": len(data)}


def repository_state(repo: Path, base_ref: str) -> dict[str, Any]:
    untracked = []
    raw = run_git(repo, "ls-files", "--others", "--exclude-standard", "-z")
    assert isinstance(raw, bytes)
    for value in raw.split(b"\0"):
        if value:
            relative = value.decode("utf-8")
            untracked.append(untracked_record(repo, relative))
    status = run_git(repo, "status", "--porcelain=v2", "-z", "--untracked-files=all")
    assert isinstance(status, bytes)
    return {
        "head": full_commit(repo, "HEAD"),
        "base": full_commit(repo, base_ref),
        "base_to_head_patch": patch_record(
            repo,
            ("diff", "--binary", "--full-index", "--no-ext-diff", f"{base_ref}...HEAD"),
        ),
        "index_patch": patch_record(
            repo, ("diff", "--cached", "--binary", "--full-index", "--no-ext-diff")
        ),
        "worktree_patch": patch_record(
            repo, ("diff", "--binary", "--full-index", "--no-ext-diff")
        ),
        "status_sha256": digest_bytes(status),
        "status_size": len(status),
        "untracked": untracked,
    }


def create_manifest(args: argparse.Namespace) -> dict[str, Any]:
    if args.jobs < 1:
        raise ValueError("jobs must be a positive integer")
    repo = Path(args.repo_root).resolve()
    registry_path = Path(os.path.abspath(args.registry))
    registry = load_registry(registry_path)
    cases_by_id = {case["id"]: case for case in registry["cases"]}
    requested_ids = sorted(set(args.case))
    missing = sorted(set(requested_ids) - cases_by_id.keys())
    if missing:
        raise ValueError(f"unknown case ids: {', '.join(missing)}")
    comparison_commit = full_commit(repo, args.comparison_ref)
    detected_selection = select_cases(repo, registry, args.base_ref)
    if args.selection_mode == "changed-from":
        selection = detected_selection
    else:
        selection = {
            "base_ref": args.base_ref,
            "base_commit": detected_selection["base_commit"],
            "head": detected_selection["head"],
            "changed_paths": [],
            "classifications": {},
            "selected_case_ids": requested_ids,
            "unmapped_paths": [],
        }
    if args.require_selected_cases_match:
        if args.selection_mode != "changed-from":
            raise ValueError("selected-case matching requires changed-from selection")
        if selection["unmapped_paths"]:
            raise ValueError(
                "candidate changed during selection and now contains unmapped paths: "
                + ", ".join(selection["unmapped_paths"])
            )
        if requested_ids != selection["selected_case_ids"]:
            raise ValueError(
                "candidate changed during selection and now maps to a different case set"
            )

    context_paths = sorted(
        {
            relative
            for case_id in requested_ids
            for declared in cases_by_id[case_id]["context_paths"]
            for relative in expand_physical(repo, declared)
        }
    )
    current_context = [tracked_or_worktree_record(repo, path) for path in context_paths]
    comparison_context = [tree_record(repo, comparison_commit, path) for path in context_paths]
    selected_cases = []
    for case_id in requested_ids:
        case = cases_by_id[case_id]
        case_context_paths = sorted(
            {
                relative
                for declared in case["context_paths"]
                for relative in expand_physical(repo, declared)
            }
        )
        selected_cases.append(
            {
                "definition": case,
                "fixture_manifest": fixture_manifest(repo, case["fixture"]),
                "prompt": file_record(repo / case["prompt"], case["prompt"]),
                "context": {
                    "paths": case_context_paths,
                    "current": [
                        tracked_or_worktree_record(repo, path)
                        for path in case_context_paths
                    ],
                    "comparison": [
                        tree_record(repo, comparison_commit, path)
                        for path in case_context_paths
                    ],
                },
            }
        )

    bound_paths = {
        "registry": registry_path,
        "schema": Path(os.path.abspath(args.schema)),
        "runner": Path(os.path.abspath(args.runner)),
        "grader": Path(os.path.abspath(args.grader)),
    }
    bound_files = {
        name: file_record(path, path.relative_to(repo).as_posix())
        for name, path in bound_paths.items()
    }
    for name in ("subject_manifest.py", "verify.py", "aggregate.py", "fake_services.py"):
        path = Path(__file__).resolve().parent / name
        bound_files[name] = file_record(path, path.relative_to(repo).as_posix())

    manifest = {
        "schema_version": 2,
        "candidate": repository_state(repo, args.base_ref),
        "comparison_ref": args.comparison_ref,
        "comparison_commit": comparison_commit,
        "selection": selection,
        "selection_mode": args.selection_mode,
        "selected_cases": selected_cases,
        "context": {
            "paths": context_paths,
            "current": current_context,
            "comparison": comparison_context,
        },
        "bound_files": bound_files,
        "executor": {
            "mode": "codex-exec-jsonl",
            "model": args.model,
            "cli": args.cli,
            "executable": executable_record(Path(args.executor_path)),
            "read_tool": executable_record(Path(args.read_tool_path)),
            "runs_per_configuration": args.runs,
            "parallel_jobs": args.jobs,
            "rollout_planned_limit_sum": args.rollout_planned_limit_sum,
            "rollout_limit_kind": "codex-native-response-boundary",
            "rollout_authoritative_unit_source": "provider-reported-or-noncached-fallback",
            "rollout_evidence_unit_source": "exec-jsonl-noncached-fallback",
            "rollout_fallback_weights": {
                "prefill_token_weight": args.prefill_fallback_weight,
                "sampling_token_weight": args.sampling_fallback_weight,
            },
            "timeout_seconds": args.timeout_seconds,
        },
    }
    manifest["subject_digest"] = digest_bytes(canonical_bytes(manifest))
    return manifest


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    select = subparsers.add_parser("select")
    select.add_argument("--repo-root", required=True)
    select.add_argument("--registry", required=True)
    select.add_argument("--changed-from", required=True)

    create = subparsers.add_parser("create")
    create.add_argument("--repo-root", required=True)
    create.add_argument("--registry", required=True)
    create.add_argument("--schema", required=True)
    create.add_argument("--runner", required=True)
    create.add_argument("--grader", required=True)
    create.add_argument("--base-ref", required=True)
    create.add_argument("--comparison-ref", required=True)
    create.add_argument("--case", action="append", default=[], required=True)
    create.add_argument("--model", required=True)
    create.add_argument("--cli", required=True)
    create.add_argument("--executor-path", required=True)
    create.add_argument("--read-tool-path", required=True)
    create.add_argument("--runs", required=True, type=int)
    create.add_argument("--jobs", type=int, default=1)
    create.add_argument(
        "--selection-mode", choices=("changed-from", "explicit"), required=True
    )
    create.add_argument("--rollout-planned-limit-sum", required=True, type=int)
    create.add_argument("--prefill-fallback-weight", required=True, type=float)
    create.add_argument("--sampling-fallback-weight", required=True, type=float)
    create.add_argument("--timeout-seconds", required=True, type=int)
    create.add_argument("--require-selected-cases-match", action="store_true")
    create.add_argument("--output", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        repo_input = Path(os.path.abspath(args.repo_root))
        repo_mode = physical_mode(repo_input)
        if not stat.S_ISDIR(repo_mode):
            raise ValueError("repository root must be a physical directory")
        repo = repo_input.resolve()
        registry = load_registry(Path(args.registry))
        if args.command == "select":
            result = select_cases(repo, registry, args.changed_from)
            print(json.dumps(result, indent=2, sort_keys=True))
            return 2 if result["unmapped_paths"] else 0
        if args.runs < 1 or args.rollout_planned_limit_sum < 1 or args.timeout_seconds < 1:
            raise ValueError("runs, rollout limit sum, and timeout must be positive integers")
        for name, value in (
            ("prefill fallback weight", args.prefill_fallback_weight),
            ("sampling fallback weight", args.sampling_fallback_weight),
        ):
            if not math.isfinite(value) or value < 0:
                raise ValueError(f"{name} must be finite and non-negative")
        manifest = create_manifest(args)
        output = Path(args.output)
        output.write_bytes(canonical_bytes(manifest))
        print(manifest["subject_digest"])
        return 0
    except (
        OSError,
        ValueError,
        TypeError,
        KeyError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
