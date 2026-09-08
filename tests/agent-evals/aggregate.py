#!/usr/bin/env python3
"""Aggregate only verified v2 run evidence into compact paired telemetry."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import statistics
from typing import Any


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def metric(values: list[float | int | None]) -> dict[str, Any]:
    present = [value for value in values if value is not None]
    if not present:
        return {"median": None, "range": None, "samples": 0}
    return {
        "median": statistics.median(present),
        "range": [min(present), max(present)],
        "samples": len(present),
    }


def aggregate(root: Path) -> dict[str, Any]:
    subject = load_json(root / "subject-manifest.json")
    groups: dict[tuple[str, str], list[dict[str, Any]]] = {}
    for grade_path in sorted(root.glob("runs/*/*/run-*/grading.json")):
        grade = load_json(grade_path)
        timing = load_json(grade_path.parent / "timing.json")
        key = (grade["case_id"], grade["configuration"])
        groups.setdefault(key, []).append(
            {
                "passed": bool(grade["passed"]),
                "elapsed_seconds": timing.get("elapsed_seconds"),
                "total_tokens": timing.get("total_tokens"),
                "command_count": len(
                    [
                        effect
                        for effect in grade.get("attempted_effects", [])
                        if effect.get("item_type") == "command_execution"
                    ]
                ),
            }
        )

    cases = []
    for item in subject["selected_cases"]:
        case = item["definition"]
        configurations = {}
        for configuration in ("current", "comparison"):
            runs = groups.get((case["id"], configuration), [])
            configurations[configuration] = {
                "runs": len(runs),
                "passes": sum(run["passed"] for run in runs),
                "elapsed_seconds": metric([run["elapsed_seconds"] for run in runs]),
                "total_tokens": metric([run["total_tokens"] for run in runs]),
                "command_count": metric([run["command_count"] for run in runs]),
            }
        cases.append(
            {
                "case_id": case["id"],
                "risk_cluster": case["risk_cluster"],
                "intent": case["intent"],
                "threshold": case["threshold"],
                "configurations": configurations,
            }
        )
    return {
        "schema_version": 2,
        "subject_digest": subject["subject_digest"],
        "interpretation": "paired median and range telemetry; not statistical significance",
        "cases": cases,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    result = aggregate(Path(args.root))
    Path(args.output).write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
