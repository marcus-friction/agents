#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MANIFEST="$REPO_ROOT/tests/distribution-manifest.json"
AUDIT="$REPO_ROOT/scripts/audit-skill-portability.sh"

python3 - "$REPO_ROOT" "$MANIFEST" <<'PY'
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import sys

repo = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
errors: list[str] = []


def complain(message: str) -> None:
    errors.append(message)


def normalized_relative(value: object, label: str) -> str | None:
    if not isinstance(value, str) or not value:
        complain(f"{label} must be a non-empty relative path")
        return None
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or str(path) != value:
        complain(f"{label} is not a normalized repository-relative path: {value!r}")
        return None
    return value


try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
    raise SystemExit(f"Invalid distribution manifest: {exc}")

expected_roots = {
    ".agents/legal",
    ".agents/skills",
    ".agents/tools",
    ".agents/.claude-plugin",
    "project-templates",
}
expected_interfaces = {
    "install.sh",
    "install-global.sh",
    "install-dependencies.sh",
    "CLAUDE.md",
    "README.md",
    "docs/ecosystem-reference.md",
    ".claude-plugin/marketplace.json",
}
expected_entrypoints = {"install.sh", "install-global.sh", "install-dependencies.sh"}
expected_script_roots = {
    ("scripts", "*.sh", False),
    ("scripts/skill-adapters", "*", True),
}
allowed_classifications = {
    "active-provider-neutral-text",
    "binary-asset",
    "legal-notice",
    "provider-adapter",
    "retained-historical-evidence",
    "fixture",
    "dormant-imported-artifact",
    "dormant-adapted-artifact",
}

if manifest.get("schema_version") != 1:
    complain("schema_version must be 1")
if manifest.get("default_classification") != "active-provider-neutral-text":
    complain("ordinary distribution files must default to active-provider-neutral-text")

managed_roots = manifest.get("managed_roots")
root_interfaces = manifest.get("root_interfaces")
graph = manifest.get("executable_graph")
exceptions = manifest.get("exceptions")
if not isinstance(managed_roots, list) or set(managed_roots) != expected_roots:
    complain("managed_roots does not match the approved distribution boundary")
    managed_roots = []
if not isinstance(root_interfaces, list) or set(root_interfaces) != expected_interfaces:
    complain("root_interfaces does not match the approved distribution boundary")
    root_interfaces = []
if not isinstance(graph, dict):
    complain("executable_graph must be an object")
    graph = {}
if not isinstance(exceptions, list):
    complain("exceptions must be an array")
    exceptions = []

entrypoints = graph.get("entrypoints", [])
if not isinstance(entrypoints, list) or set(entrypoints) != expected_entrypoints:
    complain("executable graph must contain exactly the three approved root installers")
    entrypoints = []

script_roots = graph.get("script_roots", [])
actual_script_roots = set()
if isinstance(script_roots, list):
    for index, item in enumerate(script_roots):
        if not isinstance(item, dict):
            complain(f"script_roots[{index}] must be an object")
            continue
        actual_script_roots.add(
            (item.get("path"), item.get("pattern"), item.get("recursive"))
        )
else:
    complain("script_roots must be an array")
    script_roots = []
if actual_script_roots != expected_script_roots:
    complain("script_roots does not match tracked scripts/*.sh and scripts/skill-adapters/")

for index, value in enumerate(managed_roots):
    normalized_relative(value, f"managed_roots[{index}]")
for index, value in enumerate(root_interfaces):
    normalized_relative(value, f"root_interfaces[{index}]")
for index, value in enumerate(entrypoints):
    normalized_relative(value, f"entrypoints[{index}]")

validated_exceptions: list[dict[str, str]] = []
seen_exception_keys: set[tuple[str, str]] = set()
for index, item in enumerate(exceptions):
    label = f"exceptions[{index}]"
    if not isinstance(item, dict):
        complain(f"{label} must be an object")
        continue
    path = normalized_relative(item.get("path"), f"{label}.path")
    path_kind = item.get("path_kind")
    classification = item.get("classification")
    if path_kind not in {"exact", "root"}:
        complain(f"{label}.path_kind must be exact or root")
    if classification not in allowed_classifications - {"active-provider-neutral-text"}:
        complain(f"{label}.classification must be a non-default declared classification")
    for field in ("reason", "owner", "provider_neutral_path"):
        if not isinstance(item.get(field), str) or not item[field].strip():
            complain(f"{label}.{field} must be non-empty")
    neutral_path = normalized_relative(
        item.get("provider_neutral_path"), f"{label}.provider_neutral_path"
    )
    if path and path_kind in {"exact", "root"}:
        key = (path, path_kind)
        if key in seen_exception_keys:
            complain(f"duplicate manifest exception: {path_kind} {path}")
        seen_exception_keys.add(key)
        validated_exceptions.append(item)
    if neutral_path:
        neutral_target = repo / neutral_path
        try:
            mode = neutral_target.lstat().st_mode
        except FileNotFoundError:
            complain(f"{label}.provider_neutral_path does not exist: {neutral_path}")
        else:
            if stat.S_ISLNK(mode) or not (stat.S_ISREG(mode) or stat.S_ISDIR(mode)):
                complain(f"{label}.provider_neutral_path is not a physical file or directory: {neutral_path}")


def matching_exception(relative: str) -> dict[str, str] | None:
    matches: list[tuple[int, int, dict[str, str]]] = []
    for item in validated_exceptions:
        declared = item["path"]
        if item["path_kind"] == "exact" and relative == declared:
            matches.append((len(PurePosixPath(declared).parts), 1, item))
        elif item["path_kind"] == "root" and (
            relative == declared or relative.startswith(declared + "/")
        ):
            matches.append((len(PurePosixPath(declared).parts), 0, item))
    if not matches:
        return None
    matches.sort(key=lambda match: (match[0], match[1]), reverse=True)
    if len(matches) > 1 and matches[0][:2] == matches[1][:2]:
        complain(f"ambiguous equally specific exceptions classify {relative}")
    return matches[0][2]


surface_files: set[str] = set()
surface_directories: set[str] = set()


def inspect_physical_chain(relative: str, label: str) -> bool:
    current = repo
    for part in PurePosixPath(relative).parts:
        current = current / part
        try:
            mode = current.lstat().st_mode
        except FileNotFoundError:
            return True
        if stat.S_ISLNK(mode):
            complain(f"{label} crosses a symlink: {current.relative_to(repo).as_posix()}")
            return False
    return True


def inspect_tree(relative_root: str) -> None:
    root = repo / relative_root
    if not inspect_physical_chain(relative_root, "distribution root"):
        return
    try:
        root_mode = root.lstat().st_mode
    except FileNotFoundError:
        complain(f"distribution root is missing: {relative_root}")
        return
    if stat.S_ISLNK(root_mode) or not stat.S_ISDIR(root_mode):
        complain(f"distribution root must be a physical directory: {relative_root}")
        return
    surface_directories.add(relative_root)
    for base, directories, files in os.walk(root, followlinks=False):
        base_path = Path(base)
        for name in list(directories):
            path = base_path / name
            relative = path.relative_to(repo).as_posix()
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                complain(f"symlinked distributable input: {relative}")
                directories.remove(name)
            elif not stat.S_ISDIR(mode):
                complain(f"special distributable input: {relative}")
                directories.remove(name)
            else:
                surface_directories.add(relative)
        for name in files:
            path = base_path / name
            relative = path.relative_to(repo).as_posix()
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                complain(f"symlinked distributable input: {relative}")
            elif not stat.S_ISREG(mode):
                complain(f"special distributable input: {relative}")
            else:
                surface_files.add(relative)


for relative_root in managed_roots:
    inspect_tree(relative_root)

for relative in root_interfaces:
    path = repo / relative
    if not inspect_physical_chain(relative, "root interface"):
        continue
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        complain(f"root interface is missing: {relative}")
        continue
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        complain(f"root interface must be a physical regular file: {relative}")
    else:
        surface_files.add(relative)

graph_nodes: set[str] = set(entrypoints)
for item in script_roots:
    if not isinstance(item, dict):
        continue
    relative_root = item.get("path")
    pattern = item.get("pattern")
    recursive = item.get("recursive")
    if normalized_relative(relative_root, "script root path") is None:
        continue
    root = repo / relative_root
    if not inspect_physical_chain(relative_root, "script root"):
        continue
    try:
        mode = root.lstat().st_mode
    except FileNotFoundError:
        complain(f"script root is missing: {relative_root}")
        continue
    if stat.S_ISLNK(mode) or not stat.S_ISDIR(mode):
        complain(f"script root must be a physical directory: {relative_root}")
        continue
    if recursive:
        inspect_tree(relative_root)
    candidates = root.rglob(pattern) if recursive else root.glob(pattern)
    for path in candidates:
        relative = path.relative_to(repo).as_posix()
        mode = path.lstat().st_mode
        if stat.S_ISLNK(mode):
            complain(f"symlinked executable/helper graph input: {relative}")
        elif stat.S_ISREG(mode):
            graph_nodes.add(relative)
            surface_files.add(relative)
        elif not stat.S_ISDIR(mode):
            complain(f"special executable/helper graph input: {relative}")

exception_match_counts = {id(item): 0 for item in validated_exceptions}
active_text_files: set[str] = set()
classifications: dict[str, str] = {}
for relative in sorted(surface_files):
    item = matching_exception(relative)
    classification = (
        item["classification"] if item else manifest["default_classification"]
    )
    if item:
        exception_match_counts[id(item)] += 1
    classifications[relative] = classification
    data = (repo / relative).read_bytes()
    contains_nul = b"\0" in data
    try:
        data.decode("utf-8")
        valid_utf8 = True
    except UnicodeDecodeError:
        valid_utf8 = False
    if classification == "binary-asset":
        if valid_utf8 and not contains_nul:
            complain(f"binary-asset exception masks an ordinary UTF-8 file: {relative}")
    else:
        if contains_nul:
            complain(f"NUL-containing distributable input lacks a binary-asset exception: {relative}")
        if not valid_utf8:
            complain(f"invalid-UTF-8 distributable input lacks a binary-asset exception: {relative}")
    if classification == "active-provider-neutral-text" and valid_utf8 and not contains_nul:
        active_text_files.add(relative)

for item in validated_exceptions:
    if exception_match_counts[id(item)] == 0:
        complain(f"manifest exception matches no distributable file: {item['path']}")
    if item["classification"] == "dormant-imported-artifact":
        if item["path_kind"] != "exact" or not item.get("sha256"):
            complain(f"dormant artifact must be exact and sha256-bound: {item['path']}")
        elif item["path"] in surface_files:
            actual_hash = hashlib.sha256((repo / item["path"]).read_bytes()).hexdigest()
            if actual_hash != item["sha256"]:
                complain(f"dormant artifact changed bytes: {item['path']}")

try:
    tracked_bytes = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=repo
    )
except (OSError, subprocess.CalledProcessError) as exc:
    complain(f"cannot enumerate tracked files for executable graph: {exc}")
    tracked: set[str] = set()
else:
    tracked = {
        value.decode("utf-8")
        for value in tracked_bytes.split(b"\0")
        if value
    }

for relative in sorted(tracked):
    declared = (
        relative in root_interfaces
        or any(relative == root or relative.startswith(root + "/") for root in managed_roots)
        or relative in graph_nodes
    )
    if declared and relative not in surface_files:
        complain(f"tracked distribution input is missing or not regular: {relative}")

outside_manifest = tracked - surface_files
basename_counts: dict[str, int] = {}
for relative in tracked:
    basename_counts[PurePosixPath(relative).name] = basename_counts.get(PurePosixPath(relative).name, 0) + 1

action_pattern = re.compile(
    r"\b(?:source|execute|exec|run|bash|sh|copy|cp|link|ln|install|use)\b",
    re.IGNORECASE,
)
script_dir_pattern = re.compile(r"\$(?:\{)?SCRIPT_DIR(?:\})?(/[A-Za-z0-9_.${}/-]+)")
repo_root_pattern = re.compile(r"\$(?:\{)?(?:REPO_ROOT|SCRIPT_ROOT)(?:\})?(/[A-Za-z0-9_.${}/-]+)")


def references_outside(line: str, node: str, candidate: str) -> bool:
    if not action_pattern.search(line):
        return False
    if candidate in line:
        return True
    basename = PurePosixPath(candidate).name
    return "." in basename and basename_counts.get(basename) == 1 and re.search(
        rf"(?<![A-Za-z0-9_.-]){re.escape(basename)}(?![A-Za-z0-9_.-])", line
    ) is not None


for node in sorted(graph_nodes):
    if node not in surface_files:
        complain(f"executable/helper graph node is missing from the manifest surface: {node}")
        continue
    data = (repo / node).read_bytes()
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        continue
    for line_number, line in enumerate(text.splitlines(), 1):
        for suffix in script_dir_pattern.findall(line):
            expanded = suffix.replace("${", "").replace("}", "")
            resolved = (repo / PurePosixPath(node).parent / expanded.lstrip("/")).resolve()
            if resolved.is_relative_to(repo):
                relative = resolved.relative_to(repo).as_posix()
                if relative in tracked and relative not in surface_files:
                    complain(f"graph escape {node}:{line_number} references {relative}")
        for suffix in repo_root_pattern.findall(line):
            expanded = suffix.replace("${", "").replace("}", "")
            resolved = (repo / expanded.lstrip("/")).resolve()
            if resolved.is_relative_to(repo):
                relative = resolved.relative_to(repo).as_posix()
                if relative in tracked and relative not in surface_files:
                    complain(f"graph escape {node}:{line_number} references {relative}")
        for candidate in outside_manifest:
            if references_outside(line, node, candidate):
                complain(f"graph escape {node}:{line_number} references {candidate}")

dormant_paths = [
    item["path"]
    for item in validated_exceptions
    if item["classification"] in {
        "dormant-imported-artifact", "dormant-adapted-artifact"
    }
]
for dormant in dormant_paths:
    dormant_basename = PurePosixPath(dormant).name
    for relative in sorted((graph_nodes | active_text_files) - {dormant}):
        data = (repo / relative).read_bytes()
        try:
            text = data.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if dormant in text or dormant_basename in text:
            complain(f"active distribution file references dormant artifact: {relative} -> {dormant}")

# These assertions keep the permissive default honest without adding fixture files
# to the distribution itself.
assert references_outside(
    'source "$SCRIPT_DIR/../private-helper.sh"',
    "scripts/example.sh",
    "private-helper.sh",
) is True
assert b"\0" in b"not-text\0"

if errors:
    for message in sorted(set(errors)):
        print(f"[distribution-manifest] {message}", file=sys.stderr)
    raise SystemExit(f"Distribution manifest check found {len(set(errors))} violation(s).")

print(
    "Distribution manifest check passed "
    f"({len(surface_files)} files; {len(active_text_files)} active neutral text files)."
)
PY

bash "$AUDIT" --manifest "$MANIFEST" --repo-root "$REPO_ROOT" >/dev/null

echo "Distribution text classification tests passed"
