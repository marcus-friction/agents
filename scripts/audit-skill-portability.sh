#!/usr/bin/env bash

# Lint active provider-neutral distribution text for host-specific invocation,
# discovery, metadata, and concrete tool API assumptions.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

python3 - "$SCRIPT_DIR" "$@" <<'PY'
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys

script_dir = Path(sys.argv[1])
arguments = sys.argv[2:]


def usage() -> None:
    print(
        "Usage: audit-skill-portability.sh [SKILLS_ROOT]\n"
        "       audit-skill-portability.sh --manifest MANIFEST --repo-root REPO_ROOT",
        file=sys.stderr,
    )


def physical_files(root: Path):
    for base, directories, files in os.walk(root, followlinks=False):
        base_path = Path(base)
        for name in list(directories):
            path = base_path / name
            if path.is_symlink():
                directories.remove(name)
                yield path, "symlink"
        for name in files:
            path = base_path / name
            mode = path.lstat().st_mode
            if stat.S_ISLNK(mode):
                yield path, "symlink"
            elif stat.S_ISREG(mode):
                yield path, "regular"
            else:
                yield path, "special"


def exception_for(relative: str, exceptions: list[dict]) -> dict | None:
    matches = []
    for item in exceptions:
        declared = item.get("path")
        kind = item.get("path_kind")
        if not isinstance(declared, str):
            continue
        if kind == "exact" and relative == declared:
            matches.append((len(PurePosixPath(declared).parts), 1, item))
        elif kind == "root" and (
            relative == declared or relative.startswith(declared + "/")
        ):
            matches.append((len(PurePosixPath(declared).parts), 0, item))
    return max(matches, default=(0, 0, None), key=lambda match: match[:2])[2]


if not arguments:
    scan_root = script_dir.parent / ".agents" / "skills"
    repo_root = scan_root
    manifest_mode = False
    exceptions: list[dict] = []
    candidates = list(physical_files(scan_root)) if scan_root.exists() else []
elif arguments[0] == "--manifest":
    if len(arguments) != 4 or arguments[2] != "--repo-root":
        usage()
        raise SystemExit(2)
    manifest_path = Path(arguments[1])
    repo_root = Path(arguments[3])
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        print(f"Error: invalid distribution manifest: {exc}", file=sys.stderr)
        raise SystemExit(2)
    scan_root = repo_root
    manifest_mode = True
    exceptions = manifest.get("exceptions", [])
    candidates = []
    for relative_root in manifest.get("managed_roots", []):
        root = repo_root / relative_root
        if root.exists():
            candidates.extend(physical_files(root))
    for relative in manifest.get("root_interfaces", []):
        candidates.append((repo_root / relative, "regular"))
    graph = manifest.get("executable_graph", {})
    for item in graph.get("script_roots", []):
        root = repo_root / item["path"]
        iterator = root.rglob(item["pattern"]) if item["recursive"] else root.glob(item["pattern"])
        for path in iterator:
            if path.is_file() and not path.is_symlink():
                candidates.append((path, "regular"))
    for relative in graph.get("entrypoints", []):
        candidates.append((repo_root / relative, "regular"))
elif len(arguments) == 1:
    scan_root = Path(arguments[0])
    repo_root = scan_root
    manifest_mode = False
    exceptions = []
    if scan_root.is_symlink() or not scan_root.is_dir():
        print(f"Error: skill root must be a physical directory: {scan_root}", file=sys.stderr)
        raise SystemExit(2)
    candidates = list(physical_files(scan_root))
else:
    usage()
    raise SystemExit(2)

if manifest_mode and (repo_root.is_symlink() or not repo_root.is_dir()):
    print(f"Error: repository root must be a physical directory: {repo_root}", file=sys.stderr)
    raise SystemExit(2)

# portability-audit-patterns-begin
permission_pattern = re.compile(r"^(?:allowed-tools|permissions)\s*:")
host_metadata_pattern = re.compile(
    r"^(?:preamble-tier|version|triggers|user-invocable|argument-hint|disable-model-invocation)\s*:"
)
nested_host_metadata_pattern = re.compile(
    r"^\s+(?:preamble-tier|triggers|user-invocable|argument-hint|disable-model-invocation)\s*:"
)
tool_api_pattern = re.compile(
    r"\b(?:AskUserQuestion|notify_user|browser_subagent|view_file|write_to_file|"
    r"replace_file_content|list_dir|grep_search|codebase_search|run_command|"
    r"WaitMsBeforeAsync|TodoWrite|WebSearch|WebFetch|TaskCreate|TaskUpdate|"
    r"TaskList|TaskGet|search-docs)\b"
)
slash_names = {
    "adversarial-review", "architecture-review",
    "build-start-scripts", "code-review-excellence", "compound",
    "contribute-back", "copy-editing", "copywriting",
    "design-system", "end2end", "jest", "junit",
    "laravel", "laravel-best-practices", "lfg",
    "migrate-project", "next-best-practices", "nitro", "nuxt",
    "onboard-project", "path-to-10", "performance-review", "plan",
    "pinia", "playwright", "project", "react-best-practices", "review",
    "review-plan", "security-review", "seo-review",
    "skill-creator", "skill-test", "spring-ai-patterns",
    "spring-boot-best-practices", "stack-architecture-review",
    "stack-performance-review", "stack-security-review", "start-project",
    "systematic-debugging", "tailwind-v4-shadcn", "terminal-blindness-fix",
    "test-driven-development", "update-agents",
    "vite", "vitest", "vue", "vue-best-practices",
    "vue-router-best-practices", "vue-testing-best-practices",
    "vueuse-functions", "wrap",
}
slash_command_pattern = re.compile(
    r"(?<![A-Za-z0-9_./~-])/(?:"
    + "|".join(re.escape(name) for name in sorted(slash_names))
    + r")(?![a-z0-9-])"
)
discovery_pattern = re.compile(
    r"(?:~|\$HOME)?/\.(?:claude|cursor|codex)/(?:skills|commands|rules)\b|\bCODEX_HOME\b",
    re.IGNORECASE,
)
runtime_pattern = re.compile(
    r"\b(?:Claude(?: Code|\.ai)?|Cursor(?: Cloud| Agent)|Codex|Antigravity|Cowork)\b"
    r"|\bclaude\s+-p\b|\bclaude-with-access-to-the-skill\b"
    r"|\bclaude-(?:sonnet|opus|haiku)[a-z0-9-]*\b",
    re.IGNORECASE,
)
unconditional_subagent_pattern = re.compile(
    r"\balways use (?:a )?sub-?agent\b",
    re.IGNORECASE,
)
# portability-audit-patterns-end


def visible_lines(relative: str, text: str):
    suppress_patterns = manifest_mode and relative == "scripts/audit-skill-portability.sh"
    suppressed = False
    for number, line in enumerate(text.splitlines(), 1):
        if suppress_patterns and line.strip() == "# portability-audit-patterns-begin":
            suppressed = True
            continue
        if suppress_patterns and line.strip() == "# portability-audit-patterns-end":
            suppressed = False
            continue
        if not suppressed:
            yield number, line


violations: list[tuple[str, str, int, str]] = []
seen: set[Path] = set()
for path, path_type in candidates:
    try:
        path = path.absolute()
        relative = path.relative_to(repo_root.absolute()).as_posix()
    except ValueError:
        violations.append(("outside-scan-root", str(path), 0, ""))
        continue
    if path in seen:
        continue
    seen.add(path)
    if path_type != "regular" or path.is_symlink():
        violations.append((f"{path_type}-input", relative, 0, ""))
        continue
    if not path.is_file():
        violations.append(("missing-input", relative, 0, ""))
        continue
    if not manifest_mode and "/evals/evidence/" in "/" + relative:
        continue
    if manifest_mode:
        item = exception_for(relative, exceptions)
        classification = item["classification"] if item else "active-provider-neutral-text"
        if classification != "active-provider-neutral-text":
            continue
    data = path.read_bytes()
    if b"\0" in data:
        violations.append(("invalid-text", relative, 0, "NUL byte"))
        continue
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        violations.append(("invalid-text", relative, 0, str(exc)))
        continue
    lines = list(visible_lines(relative, text))
    if path.name == "SKILL.md" and lines and lines[0][1] == "---":
        for number, line in lines[1:]:
            if line == "---":
                break
            for category, pattern in (
                ("provider-permission-metadata", permission_pattern),
                ("provider-host-metadata", host_metadata_pattern),
                ("provider-host-metadata", nested_host_metadata_pattern),
            ):
                if pattern.search(line):
                    violations.append((category, relative, number, line))
    for number, line in lines:
        for category, pattern in (
            ("concrete-tool-api", tool_api_pattern),
            ("slash-command-invocation", slash_command_pattern),
            ("provider-discovery-path", discovery_pattern),
            ("provider-runtime-assumption", runtime_pattern),
            ("provider-runtime-assumption", unconditional_subagent_pattern),
        ):
            if pattern.search(line):
                violations.append((category, relative, number, line))

if violations:
    for category, relative, number, line in violations:
        location = f"{relative}:{number}" if number else relative
        detail = f":{line}" if line else ""
        print(f"[{category}] {location}{detail}", file=sys.stderr)
    print(
        f"Canonical skill portability audit found {len(violations)} violation(s).",
        file=sys.stderr,
    )
    raise SystemExit(1)

print("Canonical skill portability audit passed.")
PY
