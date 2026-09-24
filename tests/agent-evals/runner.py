#!/usr/bin/env python3
"""Small, self-verifying runner for Agents Ecosystem live-agent evaluations."""

from __future__ import annotations

import argparse
import base64
import binascii
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
EVAL_ROOT = ROOT / "tests" / "agent-evals"
REGISTRY_PATH = EVAL_ROOT / "cases.json"
SCHEMA_PATH = EVAL_ROOT / "schema-v2.json"
SUMMARY_PROFILE = "agents-ecosystem-live-agent-summary-v1"
SUBJECT_PROFILE = "agents-ecosystem-live-agent-subject-v2"
LEGACY_SUBJECT_PROFILE = "agents-ecosystem-live-agent-subject-v1"
MIN_ROLLOUT_LIMIT_PER_CALL = 1024
CREDENTIAL_VALIDITY_MARGIN_SECONDS = 600
EXECUTOR_ENVIRONMENT_NAMES = (
    "CODEX_CI",
    "COLORTERM",
    "HOME",
    "LANG",
    "LC_ALL",
    "LC_CTYPE",
    "LOGNAME",
    "NO_COLOR",
    "PATH",
    "SHELL",
    "TERM",
    "TZ",
    "USER",
    "XDG_DATA_DIRS",
    "XDG_RUNTIME_DIR",
    # Deterministic fake-executor controls used only by the regression harness.
    "AGENT_EVAL_EXECUTOR_MARKER",
    "AGENT_EVAL_TIMEOUT_AFTER_OUTPUT",
    "AGENT_EVAL_MUTATE_RUNTIME_AUTH",
    "AGENT_EVAL_MUTATE_PATH",
    "AGENTS_ECOSYSTEM_TEST_RUNTIME_HOME_LOG",
    "AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME",
)
PRIVATE_RUNTIME_PARENT = Path("/tmp")
IGNORED_RUNTIME_EMPTY_DIRECTORIES = {".agents", ".codex", ".git"}
EVIDENCE_FILES = (
    "events.jsonl",
    "executor.stderr",
    "result.json",
    "before.json",
    "after.json",
    "state-content.json",
    "execution.json",
    "grade.json",
)


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()


def digest_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized_text(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def normalized_output_root(value: str) -> Path:
    path = Path(os.path.abspath(value))
    if path == ROOT or ROOT in path.parents:
        raise ValueError("raw evaluation output must stay outside the repository")
    current = Path(path.anchor)
    for part in path.parts[1:]:
        current /= part
        try:
            mode = current.lstat().st_mode
        except FileNotFoundError:
            break
        if stat.S_ISLNK(mode) or not stat.S_ISDIR(mode):
            raise ValueError(f"evidence path crosses an unsafe component: {current}")
    require_trusted_parent(path.parent)
    return path


def require_trusted_parent(path: Path) -> None:
    child = None
    root_owner = Path('/').stat().st_uid
    for current in (path, *path.parents):
        metadata = current.lstat()
        mode = metadata.st_mode
        if not stat.S_ISDIR(mode) or metadata.st_uid not in (root_owner, os.geteuid()):
            raise ValueError(f"private destination has an unsafe ancestor: {current}")
        if mode & 0o022 and not (metadata.st_uid == root_owner and mode & stat.S_ISVTX):
            raise ValueError(f"private destination has a writable ancestor: {current}")
        child = current


def physical_path(path: Path) -> Path:
    for current in (*reversed(path.absolute().parents), path.absolute()):
        if current.is_symlink():
            raise ValueError(f"input crosses a symlink: {current}")
    return path


def ensure_private_output_root(path: Path, create: bool) -> None:
    require_trusted_parent(path.parent)
    if create:
        path.mkdir(mode=0o700, parents=False, exist_ok=False)
    mode = path.lstat().st_mode
    metadata = path.stat()
    if (
        stat.S_ISLNK(mode)
        or not stat.S_ISDIR(mode)
        or stat.S_IMODE(mode) != 0o700
        or metadata.st_uid != os.geteuid()
    ):
        raise ValueError(f"raw evaluation output must be caller-owned mode 0700: {path}")


def normalized_summary_output(value: str, output_root: Path) -> Path:
    path = Path(os.path.abspath(value))
    if path == ROOT or ROOT in path.parents:
        raise ValueError("summary output must stay outside the repository")
    if path == output_root or path in output_root.parents:
        raise ValueError("summary output conflicts with the raw evidence root")
    if output_root in path.parents and path.parent != output_root:
        raise ValueError("summary output may not collide with per-run raw evidence")

    current = Path(path.anchor)
    for part in path.parts[1:]:
        current /= part
        try:
            mode = current.lstat().st_mode
        except FileNotFoundError:
            break
        if current == path:
            raise ValueError(f"summary output already exists: {path}")
        if stat.S_ISLNK(mode) or not stat.S_ISDIR(mode):
            raise ValueError(f"summary path crosses an unsafe component: {current}")

    if path.parent == output_root:
        if path.name in {"current", "comparison"}:
            raise ValueError("summary output conflicts with an evidence directory")
    else:
        ensure_private_output_root(path.parent, create=False)
    return path


def source_codex_home() -> Path:
    configured_home = os.environ.get("CODEX_HOME")
    source_home = Path(os.path.abspath(configured_home)) if configured_home \
        else Path.home() / ".codex"
    try:
        source_home_mode = source_home.lstat().st_mode
    except FileNotFoundError as error:
        raise ValueError(f"Codex home does not exist: {source_home}") from error
    if stat.S_ISLNK(source_home_mode) or not stat.S_ISDIR(source_home_mode):
        raise ValueError(f"unsafe Codex home: {source_home}")
    return source_home


def bound_executor_environment() -> dict[str, str]:
    return {
        name: os.environ[name]
        for name in EXECUTOR_ENVIRONMENT_NAMES
        if name in os.environ
    }


def private_authentication(home: Path) -> bytes:
    source_auth = home / "auth.json"

    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    try:
        descriptor = os.open(source_auth, flags)
    except FileNotFoundError as error:
        raise ValueError(f"Codex authentication is unavailable: {source_auth}") from error
    with os.fdopen(descriptor, "rb") as handle:
        metadata = os.fstat(handle.fileno())
        if (
            not stat.S_ISREG(metadata.st_mode)
            or metadata.st_uid != os.geteuid()
            or stat.S_IMODE(metadata.st_mode) & 0o077
            or metadata.st_nlink != 1
        ):
            raise ValueError("Codex authentication must be a private owned regular file")
        return handle.read()


def jwt_expiry(token: str) -> int:
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Codex ChatGPT access token is not a JWT")
    payload = parts[1] + "=" * (-len(parts[1]) % 4)
    try:
        value = json.loads(base64.urlsafe_b64decode(payload).decode("utf-8"))
    except (binascii.Error, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("Codex ChatGPT access token has an invalid JWT payload") from error
    expiry = value.get("exp") if isinstance(value, dict) else None
    if not isinstance(expiry, int) or isinstance(expiry, bool):
        raise ValueError("Codex ChatGPT access token has no integer expiry")
    return expiry


def credential_identity(authentication: bytes) -> dict[str, Any]:
    try:
        value = json.loads(authentication)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("Codex authentication is not valid JSON") from error
    if not isinstance(value, dict):
        raise ValueError("Codex authentication must contain a JSON object")
    mode = value.get("auth_mode")
    if mode == "chatgpt":
        tokens = value.get("tokens")
        if not isinstance(tokens, dict):
            raise ValueError("Codex ChatGPT authentication has no token set")
        account_id = tokens.get("account_id")
        access_token = tokens.get("access_token")
        refresh_token = tokens.get("refresh_token")
        if not all(isinstance(item, str) and item for item in (
            account_id, access_token, refresh_token,
        )):
            raise ValueError("Codex ChatGPT authentication is incomplete")
        return {
            "source": "codex-auth-file",
            "mode": "chatgpt",
            "principal_sha256": digest_bytes(account_id.encode("utf-8")),
            "access_token_expires_at": jwt_expiry(access_token),
        }
    if mode in {"apikey", "api_key"}:
        api_key = value.get("OPENAI_API_KEY")
        if not isinstance(api_key, str) or not api_key:
            raise ValueError("Codex API-key authentication is incomplete")
        return {
            "source": "codex-auth-file",
            "mode": "api-key",
            "principal_sha256": digest_bytes(api_key.encode("utf-8")),
        }
    raise ValueError(f"unsupported Codex authentication mode: {mode!r}")


def require_credential_window(
    credential: dict[str, Any], planned_executions: int, jobs: int, timeout_seconds: int
) -> None:
    expiry = credential.get("access_token_expires_at")
    if expiry is None:
        return
    waves = (planned_executions + jobs - 1) // jobs
    required_seconds = waves * timeout_seconds + CREDENTIAL_VALIDITY_MARGIN_SECONDS
    if expiry - int(time.time()) < required_seconds:
        raise ValueError(
            "Codex access token is not valid for the planned worst-case execution window"
        )


def materialize_runtime_codex_home(parent: Path, authentication: bytes) -> Path:
    runtime_home = parent / "codex-home"
    runtime_home.mkdir(mode=0o700)
    runtime_home.chmod(0o700)

    runtime_auth = runtime_home / "auth.json"
    descriptor = os.open(runtime_auth, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "wb") as handle:
        handle.write(authentication)
    return runtime_home


def publish_json_exclusive(path: Path, value: dict[str, Any]) -> None:
    data = json.dumps(value, indent=2, sort_keys=True).encode("utf-8") + b"\n"
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=".agents-ecosystem-summary.", dir=path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.link(temporary, path, follow_symlinks=False)
    finally:
        temporary.unlink(missing_ok=True)


def rollout_limits(total: int, planned_executions: int) -> list[int]:
    minimum = planned_executions * MIN_ROLLOUT_LIMIT_PER_CALL
    if total < minimum:
        raise ValueError(
            f"rollout limit sum must be at least {minimum} for "
            f"{planned_executions} planned executions"
        )
    base, remainder = divmod(total, planned_executions)
    return [base + (1 if index < remainder else 0) for index in range(planned_executions)]


def file_record(path: Path, relative: str) -> dict[str, Any]:
    physical_path(path)
    mode = path.lstat().st_mode
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise ValueError(f"expected physical regular file: {path}")
    data = path.read_bytes()
    return {
        "path": relative,
        "sha256": digest_bytes(data),
        "size": len(data),
        "executable": bool(mode & 0o111),
    }


def tree_records(root: Path) -> list[dict[str, Any]]:
    physical_path(root)
    if root.is_symlink() or not root.is_dir():
        raise ValueError(f"expected physical directory: {root}")
    records = []
    for path in sorted(root.rglob("*")):
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode) or (not stat.S_ISDIR(mode) and not stat.S_ISREG(mode)):
            raise ValueError(f"tree contains a symlink or special entry: {path}")
        if stat.S_ISDIR(mode) and not any(path.iterdir()):
            raise ValueError(f"tree contains an untracked empty directory: {path}")
        if stat.S_ISREG(mode):
            records.append(file_record(path, path.relative_to(root).as_posix()))
    return records


def require_same_record(actual: dict[str, Any], expected: dict[str, Any]) -> None:
    if actual != expected:
        raise ValueError(f"bound input changed: {expected['path']}")


def require_same_records(
    actual: list[dict[str, Any]], expected: list[dict[str, Any]], label: str
) -> None:
    if actual != expected:
        raise ValueError(f"bound input tree changed: {label}")


def safe_git(*args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    environment = {
        key: value for key, value in os.environ.items() if not key.startswith("GIT_")
    }
    environment.update(
        GIT_CONFIG_NOSYSTEM="1",
        GIT_CONFIG_GLOBAL=os.devnull,
        GIT_NO_REPLACE_OBJECTS="1",
    )
    return subprocess.run(
        [
            "git",
            "--no-replace-objects",
            "-c",
            "core.hooksPath=/dev/null",
            "-c",
            "core.fsmonitor=false",
            *args,
        ],
        cwd=ROOT,
        env=environment,
        check=check,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def git_text(*args: str) -> str:
    return safe_git(*args).stdout.decode().strip()


def commit_file_record(commit: str, repository_path: str, record_path: str) -> dict[str, Any]:
    entry = safe_git("ls-tree", "-z", commit, "--", repository_path).stdout
    rows = [row for row in entry.split(b"\0") if row]
    if len(rows) != 1:
        raise ValueError(f"commit does not contain one file at {repository_path}")
    metadata, _, listed_path = rows[0].partition(b"\t")
    fields = metadata.split()
    if listed_path.decode() != repository_path or len(fields) != 3 or fields[1] != b"blob":
        raise ValueError(f"commit entry is not a file: {repository_path}")
    data = safe_git("show", f"{commit}:{repository_path}").stdout
    return {
        "path": record_path,
        "sha256": digest_bytes(data),
        "size": len(data),
        "executable": fields[0] == b"100755",
    }


def validate_relative_path(value: str) -> None:
    path = Path(value)
    if not value or path.is_absolute() or ".." in path.parts or value != path.as_posix():
        raise ValueError(f"invalid repository-relative path: {value!r}")


def validate_case_id(value: str) -> None:
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", value):
        raise ValueError(f"invalid case id: {value!r}")


def path_is_covered(rule: dict[str, str], contexts: list[str]) -> bool:
    affected = rule["path"].rstrip("/")
    if rule["path_kind"] == "exact":
        return affected in contexts
    if rule["path_kind"] == "root":
        return any(path == affected or path.startswith(affected + "/") for path in contexts)
    raise ValueError(f"unknown path_kind: {rule['path_kind']}")


def path_matches(rule: dict[str, str], changed: str) -> bool:
    target = rule["path"].rstrip("/")
    if rule["path_kind"] == "exact":
        return changed == target
    if rule["path_kind"] == "root":
        return changed == target or changed.startswith(target + "/")
    raise ValueError(f"unknown path_kind: {rule['path_kind']}")


def load_registry() -> dict[str, Any]:
    physical_path(REGISTRY_PATH)
    value = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    if value.get("schema_version") != 2 or value.get("profile") != "live-agent-v2":
        raise ValueError("unsupported evaluation registry")
    ids: set[str] = set()
    for case in value.get("cases", []):
        case_id = case.get("id")
        validate_case_id(case_id)
        if not isinstance(case_id, str) or case_id in ids:
            raise ValueError(f"duplicate or invalid case id: {case_id!r}")
        ids.add(case_id)
        for key in ("fixture", "prompt"):
            validate_relative_path(case[key])
        for path in case["context_paths"]:
            validate_relative_path(path)
        for assertion in case.get("state_assertions", []):
            validate_relative_path(assertion["path"])
        forbidden_output = case.get("forbidden_output_substrings", [])
        if (
            not isinstance(forbidden_output, list)
            or any(not isinstance(item, str) or not item for item in forbidden_output)
            or len(forbidden_output) != len(set(forbidden_output))
        ):
            raise ValueError(f"invalid forbidden output in {case_id}")
        for path in case.get("permitted_fixture_mutations", []):
            validate_relative_path(path[:-1] if path.endswith('/') else path)
        for rule in case["affected_paths"]:
            validate_relative_path(rule["path"])
            if not path_is_covered(rule, case["context_paths"]):
                raise ValueError(
                    f"{case_id} claims {rule['path']} without evaluating it in context_paths"
                )
        if case["capability_profile"] not in {"read-only", "workspace-write"}:
            raise ValueError(f"unsupported capability profile in {case_id}")
        if case["capability_profile"] == "read-only" and case["permitted_fixture_mutations"]:
            raise ValueError(f"read-only case permits writes: {case_id}")
        threshold = case.get("threshold")
        if (
            not isinstance(threshold, dict)
            or not isinstance(threshold.get("runs"), int)
            or isinstance(threshold.get("runs"), bool)
            or not isinstance(threshold.get("required_passes"), int)
            or isinstance(threshold.get("required_passes"), bool)
            or threshold["runs"] < 1
            or threshold["required_passes"] < 1
            or threshold["required_passes"] > threshold["runs"]
        ):
            raise ValueError(f"invalid threshold in {case_id}")
    return value


def thresholds_met(
    cases: list[dict[str, Any]], results: list[dict[str, Any]], runs: int
) -> bool:
    for case in cases:
        threshold = case["threshold"]
        if runs != threshold["runs"]:
            return False
        current = [
            item
            for item in results
            if item.get("case_id") == case["id"]
            and item.get("configuration") == "current"
        ]
        if len(current) != runs:
            return False
        if sum(item.get("passed") is True for item in current) < threshold["required_passes"]:
            return False
    return bool(cases)


def execute_plan(tasks: list[Any], jobs: int, worker: Any) -> list[Any]:
    results = []
    for offset in range(0, len(tasks), jobs):
        batch = tasks[offset : offset + jobs]
        with ThreadPoolExecutor(max_workers=jobs) as pool:
            futures = [pool.submit(worker, task) for task in batch]
            results.extend(future.result() for future in futures)
    return results


def changed_paths(base: str) -> list[str]:
    resolved = git_text("rev-parse", "--verify", f"{base}^{{commit}}")
    raw = safe_git("diff", "--name-only", "-z", resolved, "--").stdout
    return sorted(item.decode() for item in raw.split(b"\0") if item)


def changed_paths_between(base: str, candidate: str) -> list[str]:
    raw = safe_git("diff", "--name-only", "-z", base, candidate, "--").stdout
    return sorted(item.decode() for item in raw.split(b"\0") if item)


def classify_paths(
    registry: dict[str, Any], paths: list[str]
) -> tuple[list[dict[str, Any]], dict[str, str]]:
    classifications: dict[str, str] = {}
    selected_ids: set[str] = set()
    for path in paths:
        matched_cases = [
            case["id"]
            for case in registry["cases"]
            if any(path_matches(rule, path) for rule in case["affected_paths"])
        ]
        if matched_cases:
            selected_ids.update(matched_cases)
            classifications[path] = "live:" + ",".join(sorted(matched_cases))
            continue
        deterministic = next(
            (rule for rule in registry["deterministic_only"] if path_matches(rule, path)),
            None,
        )
        classifications[path] = (
            "deterministic:" + deterministic["reason"] if deterministic else "unmapped"
        )
    selected = [case for case in registry["cases"] if case["id"] in selected_ids]
    return selected, classifications


def select_cases(
    registry: dict[str, Any], requested: list[str], changed_from: str | None
) -> tuple[list[dict[str, Any]], dict[str, str], str]:
    by_id = {case["id"]: case for case in registry["cases"]}
    if requested and changed_from:
        raise ValueError("use --case or --changed-from, not both")
    if requested:
        missing = sorted(set(requested) - set(by_id))
        if missing:
            raise ValueError(f"unknown cases: {', '.join(missing)}")
        return [by_id[item] for item in dict.fromkeys(requested)], {}, "explicit"
    if not changed_from:
        raise ValueError("select at least one --case or use --changed-from")

    selected, classifications = classify_paths(registry, changed_paths(changed_from))
    if not selected:
        raise ValueError("changed paths select no live evaluation cases")
    return selected, classifications, "changed-from"


def source_state() -> dict[str, Any]:
    status = safe_git("status", "--porcelain=v1", "--untracked-files=all").stdout
    return {
        "head": git_text("rev-parse", "HEAD"),
        "status_sha256": digest_bytes(status),
        "status_size": len(status),
        "clean": not status,
    }


def executable_identity(path: Path) -> dict[str, Any]:
    resolved = path.resolve()
    record = file_record(resolved, resolved.name)
    record["path"] = str(resolved)
    return record


def context_records(case: dict[str, Any]) -> list[dict[str, Any]]:
    return [file_record(ROOT / relative, relative) for relative in case["context_paths"]]


def comparison_context_records(
    case: dict[str, Any], commit: str
) -> dict[str, list[Any]]:
    files = []
    missing = []
    for relative in case["context_paths"]:
        try:
            files.append(commit_file_record(commit, relative, relative))
        except ValueError:
            missing.append(relative)
    return {"files": files, "missing": missing}


def build_subject(
    selected: list[dict[str, Any]],
    classifications: dict[str, str],
    selection_mode: str,
    comparison_ref: str,
    model: str,
    runs: int,
    executor: Path,
    output_root: Path,
    summary_output: Path,
    jobs: int,
    rollout_planned_limit_sum: int,
    timeout_seconds: int,
    credential: dict[str, Any],
    executor_environment: dict[str, str],
) -> dict[str, Any]:
    comparison = git_text("rev-parse", "--verify", f"{comparison_ref}^{{commit}}")
    planned_executions = len(selected) * 2 * runs
    limits = rollout_limits(rollout_planned_limit_sum, planned_executions)
    bound_cases = []
    for case in selected:
        bound_cases.append(
            {
                "id": case["id"],
                "definition": case,
                "prompt": file_record(ROOT / case["prompt"], case["prompt"]),
                "fixture": tree_records(ROOT / case["fixture"]),
                "context": context_records(case),
                "comparison_context": comparison_context_records(case, comparison),
            }
        )
    subject = {
        "profile": SUBJECT_PROFILE,
        "registry": file_record(REGISTRY_PATH, "tests/agent-evals/cases.json"),
        "schema": file_record(SCHEMA_PATH, "tests/agent-evals/schema-v2.json"),
        "runner": file_record(Path(__file__), "tests/agent-evals/runner.py"),
        "source": source_state(),
        "comparison_commit": comparison,
        "selection_mode": selection_mode,
        "classifications": classifications,
        "cases": bound_cases,
        "executor": executable_identity(executor),
        "credential": credential,
        "executor_environment": executor_environment,
        "model": model,
        "runs": runs,
        "execution": {
            "output_root": str(output_root),
            "summary_output": str(summary_output),
            "jobs": jobs,
            "planned_executions": planned_executions,
            "rollout_planned_limit_sum": rollout_planned_limit_sum,
            "rollout_limits": limits,
            "timeout_seconds": timeout_seconds,
        },
    }
    subject["subject_digest"] = digest_bytes(canonical_bytes(subject))
    return subject


def copy_tree(source: Path, target: Path) -> None:
    if source.is_symlink() or not source.is_dir():
        raise ValueError(f"unsafe fixture directory: {source}")
    shutil.copytree(source, target)
    tree_records(target)


def materialize_context(case: dict[str, Any], target: Path, ref: str | None) -> None:
    for relative in case["context_paths"]:
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if ref is None:
            source = ROOT / relative
            destination.write_bytes(source.read_bytes())
            if source.stat().st_mode & 0o111:
                destination.chmod(0o755)
        else:
            result = safe_git("show", f"{ref}:{relative}", check=False)
            if result.returncode == 0:
                destination.write_bytes(result.stdout)


def materialized_context_records(
    case: dict[str, Any], target: Path
) -> tuple[list[dict[str, Any]], list[str]]:
    files = []
    missing = []
    for relative in case["context_paths"]:
        path = target / relative
        if path.exists():
            files.append(file_record(path, relative))
        else:
            missing.append(relative)
    return files, missing


def bound_case(subject: dict[str, Any], case_id: str) -> dict[str, Any]:
    matches = [item for item in subject["cases"] if item["id"] == case_id]
    if len(matches) != 1:
        raise ValueError(f"subject does not bind one case: {case_id}")
    return matches[0]


def verify_live_subject(subject: dict[str, Any]) -> None:
    require_same_record(
        file_record(REGISTRY_PATH, "tests/agent-evals/cases.json"), subject["registry"]
    )
    require_same_record(
        file_record(SCHEMA_PATH, "tests/agent-evals/schema-v2.json"), subject["schema"]
    )
    require_same_record(
        file_record(Path(__file__), "tests/agent-evals/runner.py"), subject["runner"]
    )
    for binding in subject["cases"]:
        case = binding["definition"]
        require_same_record(file_record(ROOT / case["prompt"], case["prompt"]), binding["prompt"])
        require_same_records(
            tree_records(ROOT / case["fixture"]), binding["fixture"], case["fixture"]
        )
        require_same_records(context_records(case), binding["context"], case["id"])


def input_digest(subject: dict[str, Any], case_id: str, configuration: str) -> str:
    binding = bound_case(subject, case_id)
    context = (
        binding["context"]
        if configuration == "current"
        else binding["comparison_context"]
    )
    value = {
        "case": binding["definition"],
        "prompt": binding["prompt"],
        "fixture": binding["fixture"],
        "context": context,
        "schema": subject["schema"],
        "executor": subject["executor"],
        "model": subject["model"],
        "configuration": configuration,
        "execution": subject["execution"],
    }
    if subject.get("profile") == SUBJECT_PROFILE:
        value["credential"] = subject["credential"]
        value["executor_environment"] = subject["executor_environment"]
    return digest_bytes(canonical_bytes(value))


def snapshot(root: Path) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}
    for path in sorted(root.rglob("*")):
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode) or (not stat.S_ISDIR(mode) and not stat.S_ISREG(mode)):
            raise ValueError(f"tree contains a symlink or special entry: {path}")
        relative = path.relative_to(root).as_posix()
        if stat.S_ISREG(mode):
            records[relative] = file_record(path, relative)
        elif not any(path.iterdir()) and relative not in IGNORED_RUNTIME_EMPTY_DIRECTORIES:
            directory = relative + "/"
            records[directory] = {"path": directory, "type": "empty-directory"}
    return records


def pointer(document: Any, path: str) -> Any:
    current = document
    for raw in path.lstrip("/").split("/") if path else []:
        key = raw.replace("~1", "/").replace("~0", "~")
        current = current[int(key)] if isinstance(current, list) else current[key]
    return current


def normalized_whitespace(value: str) -> str:
    return " ".join(value.split())


def grade(
    case: dict[str, Any],
    result: dict[str, Any],
    before: dict[str, dict[str, Any]],
    after: dict[str, dict[str, Any]],
    state_content: dict[str, str | None],
    exit_code: int,
    events: list[dict[str, Any]],
    stderr: str = "",
    raw_events: str = "",
) -> dict[str, Any]:
    checks = []

    def record(check_id: str, passed: bool, evidence: str) -> None:
        checks.append({"id": check_id, "passed": passed, "evidence": evidence})

    record("executor", exit_code == 0, f"exit_code={exit_code}")
    terminal = [event.get("type") for event in events if event.get("type") in {"turn.completed", "turn.failed"}]
    record("turn", terminal == ["turn.completed"], f"terminal={terminal!r}")
    record("case-id", result.get("case_id") == case["id"], f"actual={result.get('case_id')!r}")
    forbidden_output = case.get("forbidden_output_substrings", [])
    if forbidden_output:
        rendered_result = json.dumps(result, sort_keys=True, separators=(",", ":"))
        rendered_events = raw_events or json.dumps(
            events, sort_keys=True, separators=(",", ":")
        )
        passed = not any(
            marker in rendered_result or marker in rendered_events or marker in stderr
            for marker in forbidden_output
        )
        record(
            "forbidden-output",
            passed,
            "forbidden output absent" if passed else "forbidden output detected",
        )
    for assertion in case["result_assertions"]:
        try:
            actual = pointer(result, assertion["pointer"])
            expected = assertion["expected"]
            if assertion["operator"] == "equals":
                passed = type(actual) is type(expected) and actual == expected
            elif assertion["operator"] == "set-equals":
                passed = isinstance(actual, list) and sorted(actual) == sorted(expected)
            elif assertion["operator"] == "contains":
                expected_text = normalized_whitespace(expected) \
                    if isinstance(expected, str) else ""
                passed = isinstance(actual, str) and bool(expected_text) \
                    and expected_text in normalized_whitespace(actual)
            else:
                raise ValueError(f"unknown result operator: {assertion['operator']}")
            evidence = f"actual={actual!r}; expected={expected!r}"
        except (KeyError, IndexError, TypeError, ValueError) as error:
            passed, evidence = False, str(error)
        record(assertion["id"], passed, evidence)

    changed = {path for path in before.keys() | after.keys() if before.get(path) != after.get(path)}
    permitted = set(case["permitted_fixture_mutations"])
    record("scope", changed <= permitted, f"changed={sorted(changed)!r}")
    if case["capability_profile"] == "read-only":
        record("read-only", not changed, f"changed={sorted(changed)!r}")
    for assertion in case.get("state_assertions", []):
        path = assertion["path"]
        actual = after.get(path)
        operator = assertion["operator"]
        if operator == "path-exists":
            passed = actual is not None and actual["size"] > 0
        elif operator == "path-absent":
            passed = actual is None
        elif operator == "path-contains":
            content = state_content.get(path)
            encoded = content.encode("utf-8") if isinstance(content, str) else b""
            expected_text = normalized_whitespace(assertion["expected"])
            passed = actual is not None and isinstance(content, str) \
                and actual["sha256"] == digest_bytes(encoded) \
                and actual["size"] == len(encoded) \
                and bool(expected_text) \
                and expected_text in normalized_whitespace(content)
        elif operator == "path-sha256":
            passed = actual is not None and actual["sha256"] == assertion["expected"]
        else:
            raise ValueError(f"unknown state operator: {operator}")
        rendered_record = json.dumps(actual, sort_keys=True, separators=(",", ":"))
        record(assertion["id"], passed, f"path={path}; record={rendered_record}")
    return {"passed": all(item["passed"] for item in checks), "checks": checks}


def capture_state_content(case: dict[str, Any], fixture: Path) -> dict[str, str | None]:
    content = {}
    for assertion in case.get("state_assertions", []):
        if assertion["operator"] != "path-contains":
            continue
        path = fixture / assertion["path"]
        validate_relative_path(assertion["path"])
        physical_path(path)
        try:
            if not stat.S_ISREG(path.lstat().st_mode):
                raise ValueError(f"state content must be a regular file: {path}")
            content[assertion["path"]] = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            content[assertion["path"]] = None
    return content


def parsed_events(text: str) -> list[dict[str, Any]]:
    events = []
    for line in text.splitlines():
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            events.append(value)
    return events


def render_prompt(case: dict[str, Any], prompt: Path, context: Path, fixture: Path) -> str:
    template = prompt.read_text(encoding="utf-8")
    return template.replace("{context_root}", str(context)).replace(
        "{fixture_root}", str(fixture)
    ) + (
        f"\nUse case_id {case['id']}. Return only one JSON object matching the supplied schema. "
        "The decisions object must contain d1 through d6; set unused keys to null. "
        "Do not use network, browser, remote Git, or external services.\n"
    )


def run_case(
    case: dict[str, Any],
    configuration: str,
    run_number: int,
    subject: dict[str, Any],
    output_root: Path,
    executor: Path,
    timeout_seconds: int,
    rollout_limit: int,
    runtime_codex_home: Path,
) -> dict[str, Any]:
    binding = bound_case(subject, case["id"])
    validate_case_id(case["id"])
    run_dir = output_root / configuration / case["id"] / f"run-{run_number}"
    run_dir.mkdir(mode=0o700, parents=True)
    with tempfile.TemporaryDirectory(
        prefix="agents-ecosystem-agent-case-", dir=PRIVATE_RUNTIME_PARENT
    ) as temporary:
        private = Path(temporary)
        runtime_tmp = private / "runtime-tmp"
        runtime_tmp.mkdir(mode=0o700)
        runtime_tmp.chmod(0o700)
        fixture = private / "workspace"
        context = private / "context"
        prompt = private / "prompt.md"
        schema = private / "schema.json"
        copy_tree(ROOT / case["fixture"], fixture)
        require_same_records(tree_records(fixture), binding["fixture"], case["fixture"])
        context.mkdir()
        materialize_context(
            case,
            context,
            None if configuration == "current" else subject["comparison_commit"],
        )
        actual_context, missing_context = materialized_context_records(case, context)
        expected_context = (
            {"files": binding["context"], "missing": []}
            if configuration == "current"
            else binding["comparison_context"]
        )
        require_same_records(actual_context, expected_context["files"], f"{case['id']} context")
        if missing_context != expected_context["missing"]:
            raise ValueError(f"bound context presence changed: {case['id']}")
        prompt.write_bytes((ROOT / case["prompt"]).read_bytes())
        require_same_record(file_record(prompt, case["prompt"]), binding["prompt"])
        schema.write_bytes(SCHEMA_PATH.read_bytes())
        require_same_record(file_record(schema, subject["schema"]["path"]), subject["schema"])
        before = snapshot(fixture)
        permission = "write" if case["capability_profile"] == "workspace-write" else "read"
        filesystem = {
            ":root": "deny",
            ":minimal": "read",
            ":tmpdir": "write",
            str(fixture): permission,
            str(context): "read",
            str(executor): "read",
            str(runtime_codex_home): "deny",
        }
        filesystem_config = "{" + ",".join(
            f"{json.dumps(path)}={json.dumps(access)}" for path, access in filesystem.items()
        ) + "}"
        result_path = run_dir / "result.json"
        command = [
            str(executor), "exec", "--ephemeral", "--ignore-user-config", "--ignore-rules",
            "--strict-config", "--skip-git-repo-check", "--disable", "apps",
            "--disable", "browser_use", "--disable", "computer_use", "--disable", "hooks",
            "--disable", "image_generation", "--disable", "multi_agent", "--disable", "plugins",
            "--disable", "remote_plugin", "-c", 'approval_policy="never"',
            "-c", 'default_permissions="agent-eval"',
            "-c", f"permissions.agent-eval.filesystem={filesystem_config}",
            "-c", "permissions.agent-eval.network.enabled=false", "-c", 'web_search="disabled"',
            "-c", (
                "features.rollout_budget={enabled=true,"
                f"limit_tokens={rollout_limit},prefill_token_weight=1.0,"
                "sampling_token_weight=1.0,reminder_at_remaining_tokens=[]}"
            ),
            "--cd", str(fixture), "--model", subject["model"], "--output-schema", str(schema),
            "--output-last-message", str(result_path), "--json", render_prompt(case, prompt, context, fixture),
        ]
        require_same_record(executable_identity(executor), subject["executor"])
        started = time.monotonic()
        executor_environment = dict(subject["executor_environment"])
        executor_environment["CODEX_HOME"] = str(runtime_codex_home)
        executor_environment["TMPDIR"] = str(runtime_tmp)
        try:
            completed = subprocess.run(
                command, text=True, capture_output=True, timeout=timeout_seconds,
                env=executor_environment,
            )
            exit_code = completed.returncode
            stdout, stderr = completed.stdout, completed.stderr
        except subprocess.TimeoutExpired as error:
            exit_code = 124
            stdout = normalized_text(error.stdout)
            stderr = normalized_text(error.stderr)
        require_same_record(executable_identity(executor), subject["executor"])
        elapsed = time.monotonic() - started
        (run_dir / "events.jsonl").write_text(stdout, encoding="utf-8")
        (run_dir / "executor.stderr").write_text(stderr, encoding="utf-8")
        events = parsed_events(stdout)
        try:
            result = json.loads(result_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            result = {}
            if not result_path.exists():
                result_path.write_text("{}\n", encoding="utf-8")
        after = snapshot(fixture)
        state_content = capture_state_content(case, fixture)
        graded = grade(
            case, result, before, after, state_content, exit_code, events, stderr, stdout
        )
        record = {
            "case_id": case["id"],
            "configuration": configuration,
            "run": run_number,
            "input_digest": input_digest(subject, case["id"], configuration),
            "elapsed_seconds": elapsed,
            "result": result,
            **graded,
        }
        (run_dir / "before.json").write_text(
            json.dumps(before, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        (run_dir / "after.json").write_text(
            json.dumps(after, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        (run_dir / "state-content.json").write_text(
            json.dumps(state_content, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        (run_dir / "execution.json").write_text(
            json.dumps({"exit_code": exit_code}, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        (run_dir / "grade.json").write_text(
            json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        evidence = {
            "directory": run_dir.relative_to(output_root).as_posix(),
            "files": {
                name: digest_bytes((run_dir / name).read_bytes()) for name in EVIDENCE_FILES
            },
        }
        return {**record, "evidence": evidence}


def add_summary_digest(summary: dict[str, Any]) -> dict[str, Any]:
    value = dict(summary)
    value.pop("summary_digest", None)
    value["summary_digest"] = digest_bytes(canonical_bytes(value))
    return value


def commit_tree_paths(commit: str, root: str) -> list[str]:
    raw = safe_git("ls-tree", "-r", "-z", "--name-only", commit, "--", root).stdout
    return sorted(item.decode() for item in raw.split(b"\0") if item)


def verify_subject_digest(subject: dict[str, Any]) -> None:
    subject_copy = dict(subject)
    claimed_digest = subject_copy.pop("subject_digest", None)
    if claimed_digest != digest_bytes(canonical_bytes(subject_copy)):
        raise ValueError("subject digest mismatch")


def verify_subject_runtime_binding(subject: dict[str, Any]) -> None:
    profile = subject.get("profile")
    if profile not in {SUBJECT_PROFILE, LEGACY_SUBJECT_PROFILE}:
        raise ValueError("unsupported subject profile")
    if profile == LEGACY_SUBJECT_PROFILE:
        if "credential" in subject or "executor_environment" in subject:
            raise ValueError("legacy subject profile has unsupported runtime bindings")
        return

    credential = subject.get("credential")
    if not isinstance(credential, dict):
        raise ValueError("invalid credential identity")
    mode = credential.get("mode")
    expected_keys = {"source", "mode", "principal_sha256"}
    if mode == "chatgpt":
        expected_keys.add("access_token_expires_at")
    if (
        set(credential) != expected_keys
        or credential.get("source") != "codex-auth-file"
        or mode not in {"chatgpt", "api-key"}
        or not isinstance(credential.get("principal_sha256"), str)
        or len(credential["principal_sha256"]) != 64
        or any(
            character not in "0123456789abcdef"
            for character in credential["principal_sha256"]
        )
        or (
            mode == "chatgpt"
            and (
                not isinstance(credential.get("access_token_expires_at"), int)
                or isinstance(credential.get("access_token_expires_at"), bool)
            )
        )
    ):
        raise ValueError("invalid credential identity")
    executor_environment = subject.get("executor_environment")
    if (
        not isinstance(executor_environment, dict)
        or not set(executor_environment) <= set(EXECUTOR_ENVIRONMENT_NAMES)
        or not all(
            isinstance(name, str) and isinstance(value, str)
            for name, value in executor_environment.items()
        )
    ):
        raise ValueError("invalid executor environment")


def verify_subject_commit_binding(subject: dict[str, Any]) -> None:
    verify_subject_digest(subject)
    verify_subject_runtime_binding(subject)
    source_commit = subject.get("source", {}).get("head")
    if not isinstance(source_commit, str) or len(source_commit) != 40:
        raise ValueError("subject has no full source commit")
    for key in ("registry", "schema", "runner"):
        record = subject[key]
        require_same_record(
            commit_file_record(source_commit, record["path"], record["path"]), record
        )

    committed_registry = json.loads(
        safe_git("show", f"{source_commit}:tests/agent-evals/cases.json").stdout
    )
    definitions = {case["id"]: case for case in committed_registry["cases"]}
    for binding in subject["cases"]:
        case = binding["definition"]
        if definitions.get(binding["id"]) != case:
            raise ValueError(f"case definition is not commit-backed: {binding['id']}")
        require_same_record(
            commit_file_record(source_commit, case["prompt"], case["prompt"]),
            binding["prompt"],
        )
        fixture_root = case["fixture"].rstrip("/")
        expected_paths = sorted(
            f"{fixture_root}/{record['path']}" for record in binding["fixture"]
        )
        if commit_tree_paths(source_commit, fixture_root) != expected_paths:
            raise ValueError(f"fixture tree is not commit-backed: {binding['id']}")
        for record, repository_path in zip(binding["fixture"], expected_paths):
            require_same_record(
                commit_file_record(source_commit, repository_path, record["path"]), record
            )
        for record in binding["context"]:
            require_same_record(
                commit_file_record(source_commit, record["path"], record["path"]), record
            )

        comparison = binding["comparison_context"]
        if sorted(
            [record["path"] for record in comparison["files"]] + comparison["missing"]
        ) != sorted(case["context_paths"]):
            raise ValueError(f"comparison context is incomplete: {binding['id']}")
        for record in comparison["files"]:
            require_same_record(
                commit_file_record(
                    subject["comparison_commit"], record["path"], record["path"]
                ),
                record,
            )
        for path in comparison["missing"]:
            if safe_git(
                "cat-file", "-e", f"{subject['comparison_commit']}:{path}", check=False
            ).returncode == 0:
                raise ValueError(f"comparison context is no longer missing: {path}")

    executor = subject.get("executor", {})
    if (
        not isinstance(executor.get("path"), str)
        or not Path(executor["path"]).is_absolute()
        or not isinstance(executor.get("size"), int)
        or executor["size"] <= 0
        or executor.get("executable") is not True
        or not isinstance(executor.get("sha256"), str)
        or len(executor["sha256"]) != 64
    ):
        raise ValueError("invalid executor identity")


def subject_is_commit_backed(subject: dict[str, Any]) -> bool:
    try:
        verify_subject_commit_binding(subject)
        return True
    except (KeyError, OSError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError):
        return False


def expected_check_ids(case: dict[str, Any]) -> list[str]:
    check_ids = ["executor", "turn", "case-id"]
    if case.get("forbidden_output_substrings"):
        check_ids.append("forbidden-output")
    check_ids.extend(assertion["id"] for assertion in case["result_assertions"])
    check_ids.append("scope")
    if case["capability_profile"] == "read-only":
        check_ids.append("read-only")
    check_ids.extend(assertion["id"] for assertion in case.get("state_assertions", []))
    return check_ids


def validate_summary_grade(case: dict[str, Any], result: dict[str, Any]) -> None:
    checks = result.get("checks")
    if not isinstance(checks, list) or not checks:
        raise ValueError("grade checks are incomplete")
    actual_ids = []
    for check in checks:
        if (
            not isinstance(check, dict)
            or not isinstance(check.get("id"), str)
            or not isinstance(check.get("passed"), bool)
            or not isinstance(check.get("evidence"), str)
        ):
            raise ValueError("grade check has an invalid shape")
        actual_ids.append(check["id"])
    if actual_ids != expected_check_ids(case):
        raise ValueError("grade checks are incomplete or out of order")
    recomputed_pass = all(check["passed"] for check in checks)
    if result.get("passed") is not recomputed_pass:
        raise ValueError("grade pass status is inconsistent with its checks")


def load_json_object(path: Path, label: str) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{label} must contain a JSON object")
    return value


def verify_raw_grade(
    subject: dict[str, Any], summary_result: dict[str, Any], evidence_root: Path
) -> None:
    validate_case_id(summary_result["case_id"])
    if summary_result['configuration'] not in ('current', 'comparison'):
        raise ValueError('invalid evidence configuration')
    if type(summary_result['run']) is not int or summary_result['run'] < 1:
        raise ValueError('invalid evidence run')
    case = bound_case(subject, summary_result["case_id"])["definition"]
    expected_directory = (
        f"{summary_result['configuration']}/{summary_result['case_id']}/"
        f"run-{summary_result['run']}"
    )
    evidence = summary_result.get("evidence")
    if (
        not isinstance(evidence, dict)
        or evidence.get("directory") != expected_directory
        or set(evidence.get("files", {})) != set(EVIDENCE_FILES)
    ):
        raise ValueError("grade evidence manifest is incomplete")
    run_dir = evidence_root / expected_directory
    if run_dir.is_symlink() or not run_dir.is_dir():
        raise ValueError(f"grade evidence directory is missing: {expected_directory}")
    for name in EVIDENCE_FILES:
        path = run_dir / name
        record = file_record(path, name)
        if record["sha256"] != evidence["files"][name]:
            raise ValueError(f"grade evidence digest mismatch: {expected_directory}/{name}")

    result_path = run_dir / "result.json"
    try:
        raw_result = load_json_object(result_path, "raw result")
    except json.JSONDecodeError:
        raw_result = {}
    before = load_json_object(run_dir / "before.json", "before snapshot")
    after = load_json_object(run_dir / "after.json", "after snapshot")
    state_content = load_json_object(run_dir / "state-content.json", "state content")
    execution = load_json_object(run_dir / "execution.json", "execution status")
    exit_code = execution.get("exit_code")
    if not isinstance(exit_code, int) or isinstance(exit_code, bool):
        raise ValueError("grade evidence has an invalid executor exit code")
    events = parsed_events((run_dir / "events.jsonl").read_text(encoding="utf-8"))
    stderr = (run_dir / "executor.stderr").read_text(encoding="utf-8")
    raw_events = (run_dir / "events.jsonl").read_text(encoding="utf-8")
    recomputed = grade(
        case,
        raw_result,
        before,
        after,
        state_content,
        exit_code,
        events,
        stderr,
        raw_events,
    )
    raw_grade = load_json_object(run_dir / "grade.json", "raw grade")
    if raw_grade.get("checks") != recomputed["checks"] \
        or raw_grade.get("passed") is not recomputed["passed"]:
        raise ValueError("raw grade does not match the recomputed grade")
    summary_grade = dict(summary_result)
    summary_grade.pop("evidence", None)
    if raw_grade != summary_grade:
        raise ValueError("summary result does not match raw grade evidence")


def verify_summary(
    path: Path,
    require_release_qualified: bool,
    evidence_root: Path | None = None,
) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if value.get("profile") != SUMMARY_PROFILE:
        raise ValueError("unsupported summary profile")
    expected = value.get("summary_digest")
    actual = add_summary_digest(value)["summary_digest"]
    if expected != actual:
        raise ValueError("summary digest mismatch")
    subject = value.get("subject")
    if not isinstance(subject, dict):
        raise ValueError("summary does not contain its bound subject")
    verify_subject_digest(subject)
    verify_subject_runtime_binding(subject)
    actual_commit_backed = subject_is_commit_backed(subject)
    if value.get("commit_backed") is not actual_commit_backed:
        raise ValueError("commit-backed status mismatch")
    if value.get("subject_digest") != subject.get("subject_digest"):
        raise ValueError("summary subject digest mismatch")
    if value.get("source") != subject.get("source"):
        raise ValueError("summary source mismatch")
    if value.get("comparison_commit") != subject.get("comparison_commit"):
        raise ValueError("summary comparison commit mismatch")
    if value.get("selection_mode") != subject.get("selection_mode"):
        raise ValueError("summary selection mode mismatch")
    if value.get("classifications") != subject.get("classifications"):
        raise ValueError("summary classifications mismatch")
    case_ids = [case["id"] for case in subject["cases"]]
    if value.get("case_ids") != case_ids or value.get("runs") != subject.get("runs"):
        raise ValueError("summary case or run selection mismatch")
    if subject.get("selection_mode") == "changed-from":
        committed_registry = json.loads(
            safe_git("show", f"{subject['source']['head']}:tests/agent-evals/cases.json").stdout
        )
        reconstructed, classifications = classify_paths(
            committed_registry,
            changed_paths_between(subject["comparison_commit"], subject["source"]["head"]),
        )
        if [case["id"] for case in reconstructed] != case_ids:
            raise ValueError("selected cases do not match the committed change set")
        if classifications != subject.get("classifications"):
            raise ValueError("classifications do not match the committed change set")
    expected_runs = {
        (case_id, configuration, run)
        for case_id in case_ids
        for configuration in ("current", "comparison")
        for run in range(1, subject["runs"] + 1)
    }
    actual_runs = set()
    for result in value.get("results", []):
        key = (result.get("case_id"), result.get("configuration"), result.get("run"))
        if key in actual_runs:
            raise ValueError(f"duplicate result: {key}")
        actual_runs.add(key)
        if result.get("input_digest") != input_digest(subject, key[0], key[1]):
            raise ValueError(f"result input digest mismatch: {key}")
        validate_summary_grade(bound_case(subject, key[0])["definition"], result)
    if actual_runs != expected_runs:
        raise ValueError("summary result set is incomplete")
    current = [item for item in value["results"] if item["configuration"] == "current"]
    current_pass = bool(current) and all(item.get("passed") is True for item in current)
    if value.get("current_pass") is not current_pass:
        raise ValueError("current-pass status mismatch")
    selection_complete = (
        subject.get("selection_mode") == "changed-from"
        and "unmapped" not in subject.get("classifications", {}).values()
    )
    threshold_complete = thresholds_met(
        [binding["definition"] for binding in subject["cases"]],
        value["results"],
        subject["runs"],
    )
    if value.get("thresholds_met") is not threshold_complete:
        raise ValueError("threshold status mismatch")
    if evidence_root is not None:
        normalized_evidence = normalized_output_root(str(evidence_root))
        if str(normalized_evidence) != subject.get("execution", {}).get("output_root"):
            raise ValueError("evidence root does not match the bound output root")
        ensure_private_output_root(normalized_evidence, create=False)
        for result in value["results"]:
            verify_raw_grade(subject, result, normalized_evidence)
    elif require_release_qualified:
        raise ValueError("release qualification requires the bound raw evidence root")
    release_qualified = (
        selection_complete
        and subject.get("source", {}).get("clean") is True
        and threshold_complete
        and actual_commit_backed
    )
    if value.get("release_qualified") is not release_qualified:
        raise ValueError("release-qualified status mismatch")
    if require_release_qualified and not release_qualified:
        raise ValueError("summary is not release-qualified")
    return value


def main() -> int:
    os.umask(0o077)
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--case", action="append", default=[])
    parser.add_argument("--changed-from")
    parser.add_argument("--comparison-ref")
    parser.add_argument("--runs", type=int, default=1)
    parser.add_argument("--jobs", type=int, default=int(os.environ.get("AGENT_EVAL_JOBS", "1")))
    parser.add_argument("--model", default=os.environ.get("AGENT_EVAL_MODEL", "gpt-5.6-sol"))
    parser.add_argument("--timeout-seconds", type=int, default=300)
    parser.add_argument(
        "--rollout-planned-limit-sum", "--rollout-unit-budget", "--token-budget",
        dest="rollout_planned_limit_sum", type=int,
        default=(
            int(os.environ["AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM"])
            if os.environ.get("AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM") else None
        ),
    )
    parser.add_argument("--output-root")
    parser.add_argument("--evidence-root")
    parser.add_argument("--summary-output")
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--expected-subject-digest")
    parser.add_argument("--expected-executor-sha256")
    parser.add_argument("--require-current-pass", action="store_true")
    parser.add_argument("--require-complete", action="store_true")
    parser.add_argument("--check-summary")
    parser.add_argument("--require-release-qualified", action="store_true")
    args = parser.parse_args()

    try:
        if args.check_summary:
            evidence_root = (
                normalized_output_root(args.evidence_root) if args.evidence_root else None
            )
            verify_summary(
                Path(args.check_summary), args.require_release_qualified, evidence_root
            )
            print(f"Verified summary: {args.check_summary}")
            return 0
        registry = load_registry()
        if args.list:
            print("PROFILE live-agent-v2")
            for case in registry["cases"]:
                print(f"CASE {case['id']}")
            return 0
        if args.runs < 1 or args.runs > 3:
            raise ValueError("--runs must be between 1 and 3")
        if args.jobs < 1:
            raise ValueError("--jobs must be a positive integer")
        if args.timeout_seconds < 1:
            raise ValueError("--timeout-seconds must be a positive integer")
        if args.rollout_planned_limit_sum is None or args.rollout_planned_limit_sum < 1:
            raise ValueError("--rollout-planned-limit-sum must be a positive integer")
        if not args.output_root:
            raise ValueError("--output-root is required so the evidence destination is bound")
        executable_name = os.environ.get("AGENT_EVAL_CODEX_BIN") or shutil.which("codex")
        if not executable_name:
            raise ValueError("Codex executable is unavailable")
        executor = Path(executable_name).resolve(strict=True)
        selected, classifications, selection_mode = select_cases(
            registry, args.case, args.changed_from
        )
        comparison_ref = args.comparison_ref or args.changed_from or "HEAD"
        if args.changed_from and args.comparison_ref:
            changed_commit = git_text("rev-parse", "--verify", f"{args.changed_from}^{{commit}}")
            comparison_commit = git_text(
                "rev-parse", "--verify", f"{args.comparison_ref}^{{commit}}"
            )
            if changed_commit != comparison_commit:
                raise ValueError("--comparison-ref must resolve to --changed-from in changed-path mode")
        planned_executions = len(selected) * 2 * args.runs
        limits = rollout_limits(args.rollout_planned_limit_sum, planned_executions)
        authentication = private_authentication(source_codex_home())
        credential = credential_identity(authentication)
        executor_environment = bound_executor_environment()
        require_credential_window(
            credential, planned_executions, args.jobs, args.timeout_seconds
        )
        output_root = normalized_output_root(args.output_root)
        summary_output = normalized_summary_output(
            args.summary_output or str(output_root / "summary.json"), output_root
        )
        subject = build_subject(
            selected, classifications, selection_mode, comparison_ref,
            args.model, args.runs, executor, output_root, summary_output, args.jobs,
            args.rollout_planned_limit_sum, args.timeout_seconds, credential,
            executor_environment,
        )
        if args.expected_executor_sha256 and subject["executor"]["sha256"] != args.expected_executor_sha256:
            raise ValueError("executor digest does not match the approved value")
        if args.expected_subject_digest and subject["subject_digest"] != args.expected_subject_digest:
            raise ValueError("subject digest does not match the approved value")
        if not args.prepare_only and not args.expected_executor_sha256:
            raise ValueError("execution requires --expected-executor-sha256 from prepare-only")
        if not args.prepare_only and not args.expected_subject_digest:
            raise ValueError("execution requires --expected-subject-digest from prepare-only")
        if args.require_complete and (
            selection_mode != "changed-from" or "unmapped" in classifications.values()
        ):
            raise ValueError("complete mode requires changed-path selection with no unmapped paths")
        if args.require_complete:
            wrong_runs = [
                case["id"] for case in selected if case["threshold"]["runs"] != args.runs
            ]
            if wrong_runs:
                raise ValueError(
                    "complete mode requires registered run counts for: "
                    + ", ".join(wrong_runs)
                )
        if args.prepare_only:
            print(json.dumps({
                "subject_digest": subject["subject_digest"],
                "executor_sha256": subject["executor"]["sha256"],
                "credential": subject["credential"],
                "executor_environment": subject["executor_environment"],
                "case_ids": [case["id"] for case in selected],
                "source_worktree_clean": subject["source"]["clean"],
                "classifications": classifications,
                "planned_executions": planned_executions,
                "jobs": args.jobs,
                "rollout_planned_limit_sum": args.rollout_planned_limit_sum,
                "rollout_limits": limits,
                "timeout_seconds": args.timeout_seconds,
                "output_root": str(output_root),
                "summary_output": str(summary_output),
            }, indent=2, sort_keys=True))
            return 0

        verify_live_subject(subject)

        tasks = []
        execution_index = 0
        for case in selected:
            for configuration in ("current", "comparison"):
                for run_number in range(1, args.runs + 1):
                    tasks.append((case, configuration, run_number, limits[execution_index]))
                    execution_index += 1
        print(
            f"Planned executions: {planned_executions}; jobs={args.jobs}; "
            f"rollout_limit_sum={args.rollout_planned_limit_sum}"
        )
        with tempfile.TemporaryDirectory(
            prefix="agents-ecosystem-agent-batch-", dir=PRIVATE_RUNTIME_PARENT
        ) as runtime_parent_text:
            runtime_parent = Path(runtime_parent_text)
            runtime_codex_home = materialize_runtime_codex_home(
                runtime_parent, authentication
            )
            if credential_identity(
                private_authentication(runtime_codex_home)
            ) != subject["credential"]:
                raise ValueError("runtime credential does not match the approved identity")
            ensure_private_output_root(output_root, create=True)
            def run_bound_task(task: tuple[Any, ...]) -> dict[str, Any]:
                result = run_case(
                    task[0], task[1], task[2], subject, output_root,
                    executor, args.timeout_seconds, task[3], runtime_codex_home,
                )
                if private_authentication(runtime_codex_home) != authentication:
                    raise ValueError("Codex mutated the batch authentication state")
                return result

            results = execute_plan(
                tasks,
                args.jobs,
                run_bound_task,
            )
            if private_authentication(runtime_codex_home) != authentication:
                raise ValueError("Codex mutated the batch authentication state")
        verify_live_subject(subject)
        current = [item for item in results if item["configuration"] == "current"]
        current_pass = bool(current) and all(item["passed"] for item in current)
        complete = selection_mode == "changed-from" and "unmapped" not in classifications.values()
        threshold_complete = thresholds_met(selected, results, args.runs)
        commit_backed = subject_is_commit_backed(subject)
        release_qualified = (
            complete
            and subject["source"]["clean"]
            and threshold_complete
            and commit_backed
        )
        summary = add_summary_digest({
            "profile": SUMMARY_PROFILE,
            "subject_digest": subject["subject_digest"],
            "subject": subject,
            "source": subject["source"],
            "comparison_commit": subject["comparison_commit"],
            "selection_mode": selection_mode,
            "classifications": classifications,
            "case_ids": [case["id"] for case in selected],
            "runs": args.runs,
            "current_pass": current_pass,
            "thresholds_met": threshold_complete,
            "commit_backed": commit_backed,
            "release_qualified": release_qualified,
            "results": results,
        })
        normalized_summary_output(str(summary_output), output_root)
        publish_json_exclusive(summary_output, summary)
        verify_summary(summary_output, False, output_root)
        print(f"Evidence: {output_root}")
        print(f"Summary: {summary_output}")
        if args.require_current_pass and not current_pass:
            return 1
        if args.require_complete and not threshold_complete:
            return 1
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
