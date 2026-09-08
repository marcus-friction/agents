#!/usr/bin/env python3
"""Create deterministic local substitutes for external agent side effects."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
from typing import Any


SERVICES = ("git", "gh", "curl", "wget", "browser", "open", "xdg-open")
REMOTE_GIT_COMMANDS = {"clone", "fetch", "pull", "push", "ls-remote", "archive"}
GIT_OPTIONS_WITH_VALUES = {
    "-C",
    "-c",
    "--config-env",
    "--exec-path",
    "--git-dir",
    "--namespace",
    "--super-prefix",
    "--work-tree",
}


def append_event(state_root: Path, event: dict[str, Any]) -> bool:
    event_path = state_root / "events.jsonl"
    try:
        with event_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event, sort_keys=True) + "\n")
    except OSError:
        return False
    return True


def git_command(arguments: list[str]) -> str:
    index = 0
    while index < len(arguments):
        argument = arguments[index]
        if argument == "--":
            return arguments[index + 1] if index + 1 < len(arguments) else ""
        if argument in GIT_OPTIONS_WITH_VALUES:
            index += 2
            continue
        if any(
            argument.startswith(prefix)
            for prefix in (
                "-C",
                "-c",
                "--config-env=",
                "--exec-path=",
                "--git-dir=",
                "--namespace=",
                "--super-prefix=",
                "--work-tree=",
            )
        ):
            index += 1
            continue
        if argument.startswith("-"):
            index += 1
            continue
        return argument
    return ""


def redacted_arguments(arguments: list[str]) -> list[str]:
    return [
        "<redacted-sentinel>" if "AGENTS_EVAL_SENTINEL_" in argument else argument
        for argument in arguments
    ]


def prepare(root: Path, real_git: str) -> None:
    if root.exists() or root.is_symlink():
        raise ValueError(f"fake-service root already exists: {root}")
    bin_root = root / "bin"
    state_root = root / "state"
    bin_root.mkdir(parents=True)
    state_root.mkdir()
    (state_root / "events.jsonl").write_text("", encoding="utf-8")
    (state_root / "services.json").write_text(
        json.dumps(
            {
                "schema_version": 2,
                "services": ["git-remote", "github", "network", "browser"],
                "external_network": False,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )
    remote = state_root / "git-remote.git"
    subprocess.run(
        [real_git, "init", "--bare", "--quiet", str(remote)],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    dispatcher = Path(__file__).resolve()
    for service in SERVICES:
        wrapper = bin_root / service
        wrapper.write_text(
            "#!/usr/bin/env bash\n"
            "set -euo pipefail\n"
            f"exec python3 {shlex.quote(str(dispatcher))} dispatch "
            f"--service {shlex.quote(service)} "
            f"--state-root {shlex.quote(str(state_root))} "
            f"--real-git {shlex.quote(real_git)} -- \"$@\"\n",
            encoding="utf-8",
        )
        wrapper.chmod(0o755)


def dispatch(service: str, state_root: Path, real_git: str, arguments: list[str]) -> int:
    if service == "git" and arguments:
        command = git_command(arguments)
        if command and command not in REMOTE_GIT_COMMANDS:
            environment = os.environ.copy()
            environment.update(
                {
                    "GIT_CONFIG_NOSYSTEM": "1",
                    "GIT_CONFIG_GLOBAL": os.devnull,
                    "GIT_TERMINAL_PROMPT": "0",
                }
            )
            return subprocess.run([real_git, *arguments], env=environment, check=False).returncode

    event = {
        "service": "git-remote" if service == "git" else service,
        "arguments": redacted_arguments(arguments),
        "allowed": False,
    }
    recorded = append_event(state_root, event)
    suffix = " and recorded" if recorded else ""
    print(f"agent-eval fake {service}: external effect denied{suffix}", file=sys.stderr)
    return 73


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    prepare_parser = subparsers.add_parser("prepare")
    prepare_parser.add_argument("--root", required=True)
    prepare_parser.add_argument("--real-git", required=True)
    dispatch_parser = subparsers.add_parser("dispatch")
    dispatch_parser.add_argument("--service", choices=SERVICES, required=True)
    dispatch_parser.add_argument("--state-root", required=True)
    dispatch_parser.add_argument("--real-git", required=True)
    dispatch_parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            prepare(Path(args.root), args.real_git)
            return 0
        arguments = args.arguments[1:] if args.arguments[:1] == ["--"] else args.arguments
        return dispatch(args.service, Path(args.state_root), args.real_git, arguments)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
