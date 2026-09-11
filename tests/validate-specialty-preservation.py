#!/usr/bin/env python3
"""Validate the destination-only stack and multi-agent specialty contract."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys


MANIFEST_PATH = Path(__file__).with_name("specialty-payload-manifest.json")


REQUIRED_SKILLS = {
    "laravel": {
        "name": "laravel-best-practices",
        "min_files": 21,
        "fragments": (
            "N+1 queries",
            "Form Requests when input is meaningful or complex",
            "Laravel-owned resources",
        ),
    },
    "nuxt": {
        "name": "nuxt",
        "min_files": 20,
        "fragments": ("Nuxt 4", "`app/` srcDir", "useFetch", "useAsyncData"),
    },
    "vue": {
        "name": "vue",
        "min_files": 5,
        "fragments": ("Composition API", '<script setup lang="ts">'),
    },
    "vue-best-practices": {
        "name": "vue-best-practices",
        "min_files": 25,
        "fragments": ("MUST be used for Vue.js tasks", "Composition API", "TypeScript"),
    },
    "vue-router-best-practices": {
        "name": "vue-router-best-practices",
        "min_files": 11,
        "fragments": ("Navigation Guards", "Route Lifecycle"),
    },
    "vue-testing-best-practices": {
        "name": "vue-testing-best-practices",
        "min_files": 14,
        "fragments": ("Vitest", "Vue Test Utils", "Playwright"),
    },
    "vueuse-functions": {
        "name": "vueuse-functions",
        "min_files": 269,
        "fragments": ("VueUse", "AUTO", "EXPLICIT_ONLY"),
    },
    "vite": {
        "name": "vite",
        "min_files": 8,
        "fragments": ("Vite 8", "Rolldown", "vite.config.ts"),
    },
    "vitest": {
        "name": "vitest",
        "min_files": 21,
        "fragments": ("Vitest 5", "Vite-native", "Built-in coverage"),
    },
    "pinia": {
        "name": "pinia",
        "min_files": 11,
        "fragments": ("Pinia v3", "state, getters, actions", "SSR"),
    },
    "nitro": {
        "name": "nitro",
        "min_files": 15,
        "fragments": ("Nitro v3", "H3 v2", "Route rules"),
    },
    "stack-architecture-review": {
        "name": "stack-architecture-review",
        "min_files": 1,
        "fragments": ("# Architecture Persona", "R0 and report-only", "Laravel/Nuxt"),
    },
    "stack-performance-review": {
        "name": "stack-performance-review",
        "min_files": 1,
        "fragments": ("# Performance Persona", "R0 and report-only", "Laravel/Nuxt"),
    },
    "stack-security-review": {
        "name": "stack-security-review",
        "min_files": 1,
        "fragments": ("# Security Persona", "R0 and report-only", "Laravel/Nuxt"),
    },
}

FORBIDDEN_PATHS = (
    ".agents/skills/jest",
    ".agents/skills/junit",
    ".agents/skills/next-best-practices",
    ".agents/skills/react-best-practices",
    ".agents/skills/spring-ai-patterns",
    ".agents/skills/spring-boot-best-practices",
)

DOCUMENT_FRAGMENTS = {
    "AGENTS.md": (
        "Laravel 13",
        "PHP 8.4",
        "Nuxt 4",
        '<script setup lang="ts">',
        "Pest for Laravel, Vitest for Nuxt logic, and Playwright",
    ),
    "project-templates/base/AGENTS.md": (
        "Laravel 13",
        "PHP 8.4",
        "Nuxt 4",
        '<script setup lang="ts">',
        "Pest for Laravel, Vitest for Nuxt logic, and Playwright",
    ),
    "project-templates/base/ARCHITECTURE.md": (
        "Nuxt 4 SSR",
        "Laravel 13",
        "PHP 8.4",
        "PostgreSQL",
        "Redis",
    ),
}


def is_physical_directory(path: Path) -> bool:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return False
    return stat.S_ISDIR(mode) and not stat.S_ISLNK(mode)


def is_physical_file(path: Path) -> bool:
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return False
    return stat.S_ISREG(mode) and not stat.S_ISLNK(mode)


def validate_physical_tree(root: Path, label: str, errors: list[str]) -> list[Path]:
    files: list[Path] = []
    for directory, names, filenames in os.walk(root, followlinks=False):
        directory_path = Path(directory)
        for name in names:
            child = directory_path / name
            if not is_physical_directory(child):
                errors.append(f"{label} contains a non-physical directory: {child.relative_to(root)}")
        for name in filenames:
            child = directory_path / name
            if not is_physical_file(child):
                errors.append(f"{label} contains a non-physical file: {child.relative_to(root)}")
            else:
                files.append(child)
    return files


def payload_contract(root: Path) -> dict[str, object]:
    records: list[bytes] = []

    def add_record(kind: str, path: Path, value: str = "") -> None:
        relative = "." if path == root else path.relative_to(root).as_posix()
        filesystem_mode = path.lstat().st_mode
        if kind == "directory":
            payload_mode = "040000"
        elif kind == "file":
            # Git canonicalizes regular-file mode from the owner execute bit;
            # group/other permission noise is not repository executable intent.
            executable = filesystem_mode & stat.S_IXUSR
            payload_mode = "100755" if executable else "100644"
        elif kind == "symlink":
            payload_mode = "120000"
        else:
            payload_mode = f"{filesystem_mode:o}"
        records.append(
            f"{kind}\t{relative}\t{payload_mode}\t{value}".encode("utf-8")
        )

    add_record("directory", root)
    for directory, names, filenames in os.walk(root, followlinks=False):
        directory_path = Path(directory)
        names.sort()
        filenames.sort()
        for name in list(names):
            child = directory_path / name
            child_mode = child.lstat().st_mode
            if stat.S_ISLNK(child_mode):
                add_record("symlink", child, os.readlink(child))
                names.remove(name)
            elif stat.S_ISDIR(child_mode):
                add_record("directory", child)
            else:
                add_record("special", child)
                names.remove(name)
        for name in filenames:
            child = directory_path / name
            child_mode = child.lstat().st_mode
            if stat.S_ISLNK(child_mode):
                add_record("symlink", child, os.readlink(child))
            elif stat.S_ISREG(child_mode):
                digest = hashlib.sha256(child.read_bytes()).hexdigest()
                add_record("file", child, digest)
            else:
                add_record("special", child)

    records.sort()
    aggregate = hashlib.sha256()
    for record in records:
        aggregate.update(record)
        aggregate.update(b"\0")
    return {"entries": len(records), "sha256": aggregate.hexdigest()}


def generated_manifest(repository: Path) -> dict[str, object]:
    skills_root = repository / ".agents" / "skills"
    return {
        "schema_version": 1,
        "record_format": "NUL-delimited sorted type, relative path, POSIX owner-execute mode, and content SHA-256",
        "roots": {
            name: payload_contract(skills_root / name)
            for name in sorted(REQUIRED_SKILLS)
        },
    }


def validate(repository: Path) -> list[str]:
    errors: list[str] = []
    skills_root = repository / ".agents" / "skills"
    if not is_physical_directory(skills_root):
        return [".agents/skills must be a physical directory"]

    if not is_physical_file(MANIFEST_PATH):
        return [f"missing physical specialty payload manifest: {MANIFEST_PATH}"]
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as error:
        return [f"specialty payload manifest is unreadable: {error}"]
    expected_roots = manifest.get("roots")
    if manifest.get("schema_version") != 1 or not isinstance(expected_roots, dict):
        errors.append("specialty payload manifest has an unsupported schema")
        expected_roots = {}
    if set(expected_roots) != set(REQUIRED_SKILLS):
        errors.append("specialty payload manifest root set does not match the contract")

    for relative in FORBIDDEN_PATHS:
        path = repository / relative
        if os.path.lexists(path):
            errors.append(f"source-only path is present: {relative}")

    for directory_name, contract in REQUIRED_SKILLS.items():
        skill_root = skills_root / directory_name
        label = f"specialty {directory_name}"
        if not is_physical_directory(skill_root):
            errors.append(f"missing physical specialty directory: {directory_name}")
            continue

        files = validate_physical_tree(skill_root, label, errors)
        if len(files) < int(contract["min_files"]):
            errors.append(
                f"{directory_name} payload is incomplete: "
                f"{len(files)} files, expected at least {contract['min_files']}"
            )

        skill_file = skill_root / "SKILL.md"
        if not is_physical_file(skill_file):
            errors.append(f"missing physical SKILL.md: {directory_name}")
            continue
        text = skill_file.read_text(encoding="utf-8")
        name_match = re.search(r"(?m)^name:\s*['\"]?([^'\"\n]+?)['\"]?\s*$", text)
        declared_name = name_match.group(1) if name_match else None
        if declared_name != contract["name"]:
            errors.append(
                f"{directory_name} declares {declared_name!r}, "
                f"expected {contract['name']!r}"
            )
        for fragment in contract["fragments"]:
            if fragment not in text:
                errors.append(f"{directory_name} is missing specialty meaning: {fragment}")
        actual_payload = payload_contract(skill_root)
        if expected_roots.get(directory_name) != actual_payload:
            errors.append(
                f"{directory_name} payload paths, modes, or bytes differ from the accepted manifest"
            )

    for relative, fragments in DOCUMENT_FRAGMENTS.items():
        path = repository / relative
        if not is_physical_file(path):
            errors.append(f"missing physical stack contract: {relative}")
            continue
        text = path.read_text(encoding="utf-8")
        for fragment in fragments:
            if fragment not in text:
                errors.append(f"{relative} is missing stack contract: {fragment}")

    return sorted(set(errors))


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--print-manifest":
        print(json.dumps(generated_manifest(Path(sys.argv[2])), indent=2, sort_keys=True))
        return 0
    if len(sys.argv) != 2:
        print(
            "Usage: validate-specialty-preservation.py [--print-manifest] REPOSITORY",
            file=sys.stderr,
        )
        return 2
    repository = Path(sys.argv[1])
    errors = validate(repository)
    if errors:
        for error in errors:
            print(f"[specialty-preservation] {error}", file=sys.stderr)
        return 1
    print(f"Specialty preservation contract passed ({len(REQUIRED_SKILLS)} skill roots).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
