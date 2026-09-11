#!/usr/bin/env python3
"""Snapshot, seal, and verify v2 agent-evaluation evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import stat
import subprocess
import sys
from typing import Any

os.environ.setdefault("PYTHONDONTWRITEBYTECODE", "1")
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from grade import case_from_subject, grade_safely, subject_preflight_errors  # noqa: E402
from aggregate import aggregate  # noqa: E402


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


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


def require_physical_path(path: Path, *, directory: bool) -> None:
    target = Path(os.path.abspath(path))
    current = Path(target.anchor)
    for part in target.parts[1:]:
        current /= part
        mode = current.lstat().st_mode
        if stat.S_ISLNK(mode):
            raise ValueError(f"path crosses a symlink: {current}")
    mode = target.lstat().st_mode
    expected = stat.S_ISDIR(mode) if directory else stat.S_ISREG(mode)
    if not expected:
        kind = "directory" if directory else "regular file"
        raise ValueError(f"path must be a physical {kind}: {target}")


def atomic_write_json(path: Path, value: Any) -> None:
    require_physical_path(path.parent, directory=True)
    if path.exists() or path.is_symlink():
        require_physical_path(path, directory=False)
    temporary = path.parent / f".{path.name}.tmp-{os.getpid()}"
    descriptor = None
    try:
        descriptor = os.open(
            temporary,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0),
            0o600,
        )
        with os.fdopen(descriptor, "wb") as output:
            descriptor = None
            output.write(json.dumps(value, indent=2, sort_keys=True).encode("utf-8") + b"\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if descriptor is not None:
            os.close(descriptor)
        if temporary.exists() or temporary.is_symlink():
            temporary.unlink()


def physical_file_records(root: Path, *, exclude_git: bool = False) -> list[dict[str, Any]]:
    require_physical_path(root, directory=True)
    records = []
    for base, directories, files in os.walk(root, followlinks=False):
        base_path = Path(base)
        if exclude_git and base_path == root:
            directories[:] = [name for name in directories if name != ".git"]
        for name in list(directories):
            path = base_path / name
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                raise ValueError(f"snapshot root contains a symlink: {path}")
            if not stat.S_ISDIR(mode):
                raise ValueError(f"snapshot root contains a special entry: {path}")
        for name in files:
            path = base_path / name
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
                raise ValueError(f"snapshot root contains a non-regular file: {path}")
            data = path.read_bytes()
            records.append(
                {
                    "path": path.relative_to(root).as_posix(),
                    "sha256": sha256(data),
                    "size": len(data),
                    "mode": stat.S_IMODE(mode),
                }
            )
    return sorted(records, key=lambda item: item["path"])


def git_output(root: Path, *arguments: str) -> bytes:
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
        cwd=root,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=git_environment(),
    )
    return completed.stdout


def optional_git_output(root: Path, *arguments: str) -> bytes:
    try:
        return git_output(root, *arguments)
    except subprocess.CalledProcessError:
        return b""


def git_snapshot(root: Path, *, bare: bool = False) -> dict[str, Any]:
    head = optional_git_output(root, "rev-parse", "--verify", "HEAD").decode().strip()
    refs = git_output(
        root,
        "for-each-ref",
        "--format=%(refname)%00%(objectname)%00",
    )
    result = {
        "head": head or None,
        "refs_sha256": sha256(refs),
        "refs_size": len(refs),
    }
    if not bare:
        status = git_output(root, "status", "--porcelain=v2", "-z", "--untracked-files=all")
        index_entries = git_output(root, "ls-files", "--stage", "-z")
        index_patch = git_output(
            root, "diff", "--cached", "--binary", "--full-index", "--no-ext-diff"
        )
        worktree_patch = git_output(
            root, "diff", "--binary", "--full-index", "--no-ext-diff"
        )
        result.update(
            {
                "status_sha256": sha256(status),
                "status_size": len(status),
                "index_entries_sha256": sha256(index_entries),
                "index_entries_size": len(index_entries),
                "index_patch_sha256": sha256(index_patch),
                "worktree_patch_sha256": sha256(worktree_patch),
            }
        )
    return result


def repository_snapshot(repo: Path) -> dict[str, Any]:
    result = git_snapshot(repo)
    raw = git_output(repo, "ls-files", "--others", "--exclude-standard", "-z")
    untracked = []
    for value in raw.split(b"\0"):
        if not value:
            continue
        relative = value.decode("utf-8")
        path = repo / relative
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            target = os.readlink(path)
            target_bytes = os.fsencode(target)
            untracked.append(
                {
                    "path": relative,
                    "type": "symlink",
                    "target": target,
                    "sha256": sha256(target_bytes),
                    "size": len(target_bytes),
                    "mode": stat.S_IMODE(mode),
                }
            )
            continue
        if not stat.S_ISREG(mode):
            raise ValueError(f"repository contains an untracked non-regular file: {relative}")
        data = path.read_bytes()
        untracked.append(
            {
                "path": relative,
                "sha256": sha256(data),
                "size": len(data),
                "mode": stat.S_IMODE(mode),
            }
        )
    result["untracked"] = sorted(untracked, key=lambda item: item["path"])
    return result


def snapshot(args: argparse.Namespace) -> dict[str, Any]:
    repo = Path(args.repo_root).resolve()
    fixture = Path(args.fixture).resolve()
    context = Path(args.context).resolve()
    fake_state = Path(args.fake_state).resolve()
    remote = fake_state / "git-remote.git"
    return {
        "schema_version": 2,
        "fixture": {
            "files": physical_file_records(fixture, exclude_git=True),
            "git_files": physical_file_records(fixture / ".git"),
            "git": git_snapshot(fixture),
        },
        "context": {"files": physical_file_records(context)},
        "fake_services": {
            "files": physical_file_records(fake_state),
            "bare_remote": git_snapshot(remote, bare=True),
        },
        "repository": repository_snapshot(repo),
    }


def artifact_records(root: Path) -> list[dict[str, Any]]:
    require_physical_path(root, directory=True)
    records = []
    for base, directories, files in os.walk(root, followlinks=False):
        base_path = Path(base)
        for name in list(directories):
            path = base_path / name
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                raise ValueError(f"evidence contains a symlink: {path.relative_to(root)}")
            if not stat.S_ISDIR(mode):
                raise ValueError(f"evidence contains a special directory entry: {path.relative_to(root)}")
        for name in files:
            path = base_path / name
            relative = path.relative_to(root).as_posix()
            if relative == "root-manifest.json":
                mode = path.lstat().st_mode
                if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
                    raise ValueError("root manifest must be a physical regular file")
                continue
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
                raise ValueError(f"evidence contains a non-regular artifact: {relative}")
            data = path.read_bytes()
            records.append(
                {
                    "path": relative,
                    "sha256": sha256(data),
                    "size": len(data),
                    "mode": stat.S_IMODE(mode),
                }
            )
    return sorted(records, key=lambda item: item["path"])


def verify_subject(subject: dict[str, Any]) -> None:
    if subject.get("schema_version") != 2:
        raise ValueError("subject manifest must use schema_version 2")
    if not subject.get("selected_cases"):
        raise ValueError("subject manifest contains no selected cases")
    if subject.get("selection_mode") not in {"changed-from", "explicit"}:
        raise ValueError("subject manifest has an invalid selection mode")
    executor = subject.get("executor", {})
    if executor.get("rollout_limit_kind") != "codex-native-response-boundary":
        raise ValueError("subject manifest has an invalid rollout limit kind")
    if executor.get("rollout_authoritative_unit_source") != "provider-reported-or-noncached-fallback":
        raise ValueError("subject manifest has an invalid authoritative rollout-unit source")
    if executor.get("rollout_evidence_unit_source") != "exec-jsonl-noncached-fallback":
        raise ValueError("subject manifest has an invalid evidence rollout-unit source")
    executable = executor.get("executable")
    if not isinstance(executable, dict) or set(executable) != {"path", "sha256", "size", "mode"}:
        raise ValueError("subject manifest has an invalid executor identity")
    if not isinstance(executable["path"], str) or not Path(executable["path"]).is_absolute():
        raise ValueError("subject manifest executor path must be absolute")
    if (
        not isinstance(executable["sha256"], str)
        or len(executable["sha256"]) != 64
        or any(character not in "0123456789abcdef" for character in executable["sha256"])
    ):
        raise ValueError("subject manifest has an invalid executor digest")
    for field in ("size", "mode"):
        value = executable[field]
        if not isinstance(value, int) or isinstance(value, bool) or value < 0:
            raise ValueError(f"subject manifest has an invalid executor {field}")
    for field in ("runs_per_configuration", "rollout_planned_limit_sum", "timeout_seconds"):
        value = executor.get(field)
        if not isinstance(value, int) or isinstance(value, bool) or value < 1:
            raise ValueError(f"subject manifest has an invalid executor {field}")
    parallel_jobs = executor.get("parallel_jobs", 1)
    if (
        not isinstance(parallel_jobs, int)
        or isinstance(parallel_jobs, bool)
        or parallel_jobs < 1
    ):
        raise ValueError("subject manifest has an invalid executor parallel_jobs")
    weights = executor.get("rollout_fallback_weights")
    if not isinstance(weights, dict) or set(weights) != {
        "prefill_token_weight",
        "sampling_token_weight",
    }:
        raise ValueError("subject manifest has invalid rollout fallback weights")
    for name, value in weights.items():
        if (
            not isinstance(value, (int, float))
            or isinstance(value, bool)
            or not math.isfinite(value)
            or value < 0
        ):
            raise ValueError(f"subject manifest has an invalid {name}")
    claimed = subject.get("subject_digest")
    unsigned = dict(subject)
    unsigned.pop("subject_digest", None)
    actual = sha256(canonical_bytes(unsigned))
    if claimed != actual:
        raise ValueError(f"subject manifest digest mismatch: {claimed!r} != {actual}")


RUN_ARTIFACTS = {
    "events.jsonl",
    "executor.stderr",
    "grading.json",
    "input.json",
    "prompt.txt",
    "result.json",
    "snapshots/after.json",
    "snapshots/before.json",
    "timing.json",
}


def expected_artifact_paths(subject: dict[str, Any]) -> set[str]:
    expected = {"aggregate.json", "selection.json", "subject-manifest.json"}
    runs = subject["executor"]["runs_per_configuration"]
    if not isinstance(runs, int) or isinstance(runs, bool) or runs < 1:
        raise ValueError("subject manifest has an invalid run count")
    for selected in subject["selected_cases"]:
        case_id = selected["definition"]["id"]
        for configuration in ("current", "comparison"):
            for run_number in range(1, runs + 1):
                prefix = f"runs/{configuration}/{case_id}/run-{run_number}"
                expected.update(f"{prefix}/{relative}" for relative in RUN_ARTIFACTS)
    return expected


def verify_layout(root: Path, subject: dict[str, Any]) -> list[dict[str, Any]]:
    records = artifact_records(root)
    actual = {record["path"] for record in records}
    expected = expected_artifact_paths(subject)
    if actual != expected:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        raise ValueError(f"evidence layout mismatch: missing={missing!r}; extra={extra!r}")
    selection = load_json(root / "selection.json")
    if selection != subject["selection"]:
        raise ValueError("selection artifact differs from the subject manifest")
    return records


def preflight(
    subject_path: Path,
    snapshot_path: Path,
    case_id: str,
    configuration: str,
) -> dict[str, Any]:
    subject = load_json(subject_path)
    verify_subject(subject)
    case = case_from_subject(subject, case_id)
    before = load_json(snapshot_path)
    errors = subject_preflight_errors(
        subject,
        case,
        {"configuration": configuration},
        before,
    )
    if errors:
        raise ValueError("subject preflight failed: " + "; ".join(errors))
    return {
        "subject_digest": subject["subject_digest"],
        "case_id": case_id,
        "configuration": configuration,
        "fresh": True,
    }


def seal(root: Path) -> dict[str, Any]:
    manifest_path = root / "root-manifest.json"
    if manifest_path.exists() or manifest_path.is_symlink():
        mode = manifest_path.lstat().st_mode
        if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
            raise ValueError("root manifest must be a physical regular file")
    subject = load_json(root / "subject-manifest.json")
    verify_subject(subject)
    if root.name != subject["subject_digest"]:
        raise ValueError("evidence directory name does not match subject digest")
    records = verify_layout(root, subject)
    manifest = {
        "schema_version": 2,
        "subject_digest": subject["subject_digest"],
        "artifacts": records,
    }
    manifest["root_digest"] = sha256(canonical_bytes(manifest))
    return manifest


def verify_run_grades(root: Path, subject: dict[str, Any]) -> list[dict[str, Any]]:
    results = []
    for input_path in sorted(root.glob("runs/*/*/run-*/input.json")):
        run_dir = input_path.parent
        retained = load_json(run_dir / "grading.json")
        recomputed = grade_safely(root / "subject-manifest.json", run_dir)
        if retained != recomputed:
            raise ValueError(f"retained grade differs from recomputation: {run_dir.relative_to(root)}")
        if retained.get("subject_digest") != subject["subject_digest"]:
            raise ValueError(f"run grade has stale subject digest: {run_dir.relative_to(root)}")
        results.append(retained)
    if not results:
        raise ValueError("evidence contains no run grades")
    return results


def require_complete(subject: dict[str, Any], grades: list[dict[str, Any]]) -> None:
    if subject.get("selection_mode") != "changed-from":
        raise ValueError("complete evidence requires changed-from selection")
    selection = subject.get("selection", {})
    if selection.get("unmapped_paths") != []:
        raise ValueError("complete evidence contains unmapped changed paths")
    selected_ids = sorted(
        item["definition"]["id"] for item in subject["selected_cases"]
    )
    if selection.get("selected_case_ids") != selected_ids:
        raise ValueError("complete evidence does not cover the exact selected case set")
    cases = {item["definition"]["id"]: item["definition"] for item in subject["selected_cases"]}
    for case_id, case in cases.items():
        current = [
            grade_item
            for grade_item in grades
            if grade_item["case_id"] == case_id and grade_item["configuration"] == "current"
        ]
        expected_runs = case["threshold"]["runs"]
        required_passes = case["threshold"]["required_passes"]
        passed = sum(bool(item["passed"]) for item in current)
        if len(current) != expected_runs:
            raise ValueError(
                f"required case {case_id} has {len(current)} current runs; expected {expected_runs}"
            )
        if passed < required_passes:
            raise ValueError(
                f"required case {case_id} passed {passed}/{expected_runs}; requires {required_passes}"
            )


def require_current_pass(grades: list[dict[str, Any]]) -> None:
    failed = sorted(
        grade_item["case_id"]
        for grade_item in grades
        if grade_item.get("configuration") == "current" and not grade_item.get("passed")
    )
    if failed:
        raise ValueError(f"current configuration has failing runs: {failed!r}")


def check(root: Path, complete: bool, current_pass: bool) -> dict[str, Any]:
    manifest_path = root / "root-manifest.json"
    mode = manifest_path.lstat().st_mode
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise ValueError("root manifest must be a physical regular file")
    root_manifest = load_json(root / "root-manifest.json")
    if set(root_manifest) != {
        "schema_version",
        "subject_digest",
        "artifacts",
        "root_digest",
    } or root_manifest.get("schema_version") != 2:
        raise ValueError("root manifest shape or schema version is invalid")
    unsigned = dict(root_manifest)
    claimed_root_digest = unsigned.pop("root_digest", None)
    actual_root_digest = sha256(canonical_bytes(unsigned))
    if claimed_root_digest != actual_root_digest:
        raise ValueError("root manifest digest is invalid")
    actual_records = artifact_records(root)
    if root_manifest.get("artifacts") != actual_records:
        raise ValueError("evidence artifacts are missing, extra, symlinked, stale, or altered")
    subject = load_json(root / "subject-manifest.json")
    verify_subject(subject)
    if root_manifest.get("subject_digest") != subject["subject_digest"] or root.name != subject["subject_digest"]:
        raise ValueError("evidence is stale or stored under the wrong subject digest")
    verify_layout(root, subject)
    grades = verify_run_grades(root, subject)
    retained_aggregate = load_json(root / "aggregate.json")
    if retained_aggregate != aggregate(root):
        raise ValueError("retained aggregate differs from verified recomputation")
    if complete:
        require_complete(subject, grades)
    if current_pass:
        require_current_pass(grades)
    return {
        "subject_digest": subject["subject_digest"],
        "root_digest": claimed_root_digest,
        "runs": len(grades),
        "complete": complete,
        "current_pass": current_pass,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    snapshot_parser = subparsers.add_parser("snapshot")
    snapshot_parser.add_argument("--repo-root", required=True)
    snapshot_parser.add_argument("--fixture", required=True)
    snapshot_parser.add_argument("--context", required=True)
    snapshot_parser.add_argument("--fake-state", required=True)
    snapshot_parser.add_argument("--output", required=True)
    seal_parser = subparsers.add_parser("seal")
    seal_parser.add_argument("--root", required=True)
    check_parser = subparsers.add_parser("check")
    check_parser.add_argument("--root", required=True)
    check_parser.add_argument("--require-complete", action="store_true")
    check_parser.add_argument("--require-current-pass", action="store_true")
    legacy_parser = subparsers.add_parser("legacy-status")
    legacy_parser.add_argument("--root", required=True)
    preflight_parser = subparsers.add_parser("preflight")
    preflight_parser.add_argument("--subject", required=True)
    preflight_parser.add_argument("--snapshot", required=True)
    preflight_parser.add_argument("--case-id", required=True)
    preflight_parser.add_argument(
        "--configuration", choices=("current", "comparison"), required=True
    )
    args = parser.parse_args()
    try:
        if args.command == "snapshot":
            result = snapshot(args)
            Path(args.output).write_text(
                json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
            )
        elif args.command == "seal":
            result = seal(Path(args.root))
            atomic_write_json(Path(args.root) / "root-manifest.json", result)
        elif args.command == "check":
            result = check(Path(args.root), args.require_complete, args.require_current_pass)
            print(json.dumps(result, sort_keys=True))
        elif args.command == "preflight":
            result = preflight(
                Path(args.subject),
                Path(args.snapshot),
                args.case_id,
                args.configuration,
            )
            print(json.dumps(result, sort_keys=True))
        else:
            root = Path(args.root)
            if not root.exists():
                raise ValueError(f"legacy evidence root is missing: {root}")
            has_evidence = any(root.rglob("*.json"))
            print(
                json.dumps(
                    {
                        "profile": "legacy",
                        "verified_dimensions": (
                            "original-schema-only" if has_evidence else "none-no-evidence-found"
                        ),
                        "grader_integrity": "unverifiable",
                        "output_integrity": "unverifiable",
                        "v2_release_gate": "excluded",
                    },
                    sort_keys=True,
                )
            )
        return 0
    except (OSError, ValueError, KeyError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
