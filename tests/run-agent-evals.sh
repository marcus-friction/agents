#!/usr/bin/env bash

# Live Agent Evaluation Profile v2. This runner is never called by tests/run.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
REPO_ROOT="$DEFAULT_REPO_ROOT"
REGISTRY="$SCRIPT_DIR/agent-evals/cases.json"
SCHEMA="$SCRIPT_DIR/agent-evals/schema-v2.json"
SUBJECT_TOOL="$SCRIPT_DIR/agent-evals/subject_manifest.py"
FAKE_SERVICES="$SCRIPT_DIR/agent-evals/fake_services.py"
GRADER="$SCRIPT_DIR/agent-evals/grade.py"
VERIFIER="$SCRIPT_DIR/agent-evals/verify.py"
AGGREGATOR="$SCRIPT_DIR/agent-evals/aggregate.py"
CHANGED_FROM=""
COMPARISON_REF=""
RUNS=1
JOBS="${AGENT_EVAL_JOBS:-1}"
REQUIRE_COMPLETE=0
REQUIRE_CURRENT_PASS=0
PREPARE_ONLY=0
LIST_ONLY=0
SELECTION_FROM_DIFF=0
OUTPUT_ROOT=""
MODEL="${AGENT_EVAL_MODEL:-}"
CODEX_BIN="${AGENT_EVAL_CODEX_BIN:-codex}"
EXPECTED_SUBJECT_DIGEST="${AGENT_EVAL_EXPECTED_SUBJECT_DIGEST:-}"
EXPECTED_EXECUTOR_SHA256="${AGENT_EVAL_EXPECTED_EXECUTOR_SHA256:-}"
ROLLOUT_PLANNED_LIMIT_SUM="${AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM:-${AGENT_EVAL_ROLLOUT_UNIT_BUDGET:-${AGENT_EVAL_TOKEN_BUDGET:-}}}"
TIMEOUT_SECONDS="${AGENT_EVAL_TIMEOUT_SECONDS:-}"
CASE_IDS=()
RUNNER_TMP=""
CLI_PROBE_HOME=""
MIN_ROLLOUT_LIMIT_PER_CALL=1024
PREFILL_FALLBACK_WEIGHT="1.0"
SAMPLING_FALLBACK_WEIGHT="1.0"

for git_variable in "${!GIT_@}"; do
  unset "$git_variable"
done
export GIT_ASKPASS=/usr/bin/false
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_SYSTEM=/dev/null
export GIT_NO_REPLACE_OBJECTS=1
export GIT_OPTIONAL_LOCKS=0
export GIT_TERMINAL_PROMPT=0

usage() {
  cat <<'EOF'
Usage: run-agent-evals.sh [options]

Selection:
  --changed-from REF       Select every case mapped to the complete candidate diff
  --case ID                Select an exact case (repeatable)
  --comparison-ref REF     Commit used for the comparison context

Execution:
  --runs N                 Runs per case and configuration (default: 1)
  --jobs N                 Maximum concurrent executions; bound to the subject
                           identity (default: 1)
  --model MODEL            Explicit model identifier (or AGENT_EVAL_MODEL)
  --rollout-planned-limit-sum N
                           Sum of per-execution Codex response-boundary limits
                           (minimum 1024 configured units per execution)
                           A completed response may overshoot its configured limit
  --rollout-unit-budget N  Compatibility alias for --rollout-planned-limit-sum
  --token-budget N         Compatibility alias for --rollout-planned-limit-sum
  --timeout-seconds N      Wall-clock timeout for each Codex execution
  --expected-subject-digest SHA256
                           Required for execution; prepare-only prints this value
  --expected-executor-sha256 SHA256
                           Required for execution; checked before invoking Codex
  --output-root DIR        Parent for verified evidence; default is retained v2 evidence
  --prepare-only           Build and print the subject identity without model execution
  --require-complete       Require each current case to meet its registered threshold
  --require-current-pass   Fail unless every selected current run passes
  --list                   List registered live cases without running them
EOF
}

cleanup() {
  if [ -n "$CLI_PROBE_HOME" ] && [ -d "$CLI_PROBE_HOME" ]; then
    rm -rf -- "$CLI_PROBE_HOME"
  fi
  if [ -n "$RUNNER_TMP" ] && [ -d "$RUNNER_TMP" ]; then
    chmod -R u+w "$RUNNER_TMP" 2>/dev/null || true
    rm -rf -- "$RUNNER_TMP"
  fi
}
trap cleanup EXIT

while [ "$#" -gt 0 ]; do
  case "$1" in
    --changed-from)
      [ "$#" -ge 2 ] || { echo "Error: --changed-from requires a value" >&2; exit 2; }
      CHANGED_FROM="$2"
      shift 2
      ;;
    --comparison-ref)
      [ "$#" -ge 2 ] || { echo "Error: --comparison-ref requires a value" >&2; exit 2; }
      COMPARISON_REF="$2"
      shift 2
      ;;
    --case)
      [ "$#" -ge 2 ] || { echo "Error: --case requires a value" >&2; exit 2; }
      CASE_IDS+=("$2")
      shift 2
      ;;
    --runs)
      [ "$#" -ge 2 ] || { echo "Error: --runs requires a value" >&2; exit 2; }
      RUNS="$2"
      shift 2
      ;;
    --jobs)
      [ "$#" -ge 2 ] || { echo "Error: --jobs requires a value" >&2; exit 2; }
      JOBS="$2"
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || { echo "Error: --model requires a value" >&2; exit 2; }
      MODEL="$2"
      shift 2
      ;;
    --rollout-planned-limit-sum|--rollout-unit-budget|--token-budget)
      [ "$#" -ge 2 ] || { echo "Error: $1 requires a value" >&2; exit 2; }
      ROLLOUT_PLANNED_LIMIT_SUM="$2"
      shift 2
      ;;
    --timeout-seconds)
      [ "$#" -ge 2 ] || { echo "Error: --timeout-seconds requires a value" >&2; exit 2; }
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --expected-subject-digest)
      [ "$#" -ge 2 ] || { echo "Error: --expected-subject-digest requires a value" >&2; exit 2; }
      EXPECTED_SUBJECT_DIGEST="$2"
      shift 2
      ;;
    --expected-executor-sha256)
      [ "$#" -ge 2 ] || { echo "Error: --expected-executor-sha256 requires a value" >&2; exit 2; }
      EXPECTED_EXECUTOR_SHA256="$2"
      shift 2
      ;;
    --output-root)
      [ "$#" -ge 2 ] || { echo "Error: --output-root requires a value" >&2; exit 2; }
      OUTPUT_ROOT="$2"
      shift 2
      ;;
    --prepare-only)
      PREPARE_ONLY=1
      shift
      ;;
    --require-complete)
      REQUIRE_COMPLETE=1
      shift
      ;;
    --require-current-pass)
      REQUIRE_CURRENT_PASS=1
      shift
      ;;
    --repo-root)
      [ "$#" -ge 2 ] || { echo "Error: --repo-root requires a value" >&2; exit 2; }
      REPO_ROOT="$2"
      shift 2
      ;;
    --registry)
      [ "$#" -ge 2 ] || { echo "Error: --registry requires a value" >&2; exit 2; }
      REGISTRY="$2"
      shift 2
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$LIST_ONLY" -eq 1 ]; then
  python3 - "$REGISTRY" <<'PY'
import json
import sys

registry = json.load(open(sys.argv[1], encoding="utf-8"))
print("PROFILE live-agent-v2")
for case in registry["cases"]:
    print(
        f"CASE {case['id']}\t{case['risk_class']}\t"
        f"{case['intent']}\t{case['capability_profile']}"
    )
PY
  exit 0
fi

if ! [[ "$RUNS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --runs must be a positive integer" >&2
  exit 2
fi
if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --jobs must be a positive integer" >&2
  exit 2
fi
if [ -z "$CHANGED_FROM" ] && [ "${#CASE_IDS[@]}" -eq 0 ]; then
  echo "Error: select cases with --changed-from or --case" >&2
  exit 2
fi
if [ -z "$COMPARISON_REF" ]; then
  echo "Error: --comparison-ref is required" >&2
  exit 2
fi
if [ -z "$MODEL" ]; then
  echo "Error: pin the live model with --model or AGENT_EVAL_MODEL" >&2
  exit 2
fi
if ! [[ "$ROLLOUT_PLANNED_LIMIT_SUM" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --rollout-planned-limit-sum or AGENT_EVAL_ROLLOUT_PLANNED_LIMIT_SUM must be a positive integer" >&2
  exit 2
fi
if ! [[ "$TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: --timeout-seconds or AGENT_EVAL_TIMEOUT_SECONDS must be a positive integer" >&2
  exit 2
fi
if [ -L "$REPO_ROOT" ] || [ ! -d "$REPO_ROOT/.git" ]; then
  echo "Error: --repo-root must be a physical Git worktree" >&2
  exit 2
fi

REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
RUNNER_TMP="$(mktemp -d)"
selection_path="$RUNNER_TMP/selection.json"

if [ -n "$CHANGED_FROM" ]; then
  SELECTION_FROM_DIFF=1
  set +e
  python3 "$SUBJECT_TOOL" select \
    --repo-root "$REPO_ROOT" \
    --registry "$REGISTRY" \
    --changed-from "$CHANGED_FROM" > "$selection_path"
  selection_status="$?"
  set -e
  if [ "$selection_status" -ne 0 ]; then
    cat "$selection_path" >&2
    echo "Error: changed-path selection is incomplete; map or classify every path" >&2
    exit "$selection_status"
  fi
  while IFS= read -r case_id; do
    [ -n "$case_id" ] && CASE_IDS+=("$case_id")
  done < <(python3 - "$selection_path" <<'PY'
import json
import sys
for case_id in json.load(open(sys.argv[1], encoding="utf-8"))["selected_case_ids"]:
    print(case_id)
PY
)
else
  printf '%s\n' '{"selection":"explicit"}' > "$selection_path"
  CHANGED_FROM="HEAD"
fi

mapfile -t CASE_IDS < <(printf '%s\n' "${CASE_IDS[@]}" | LC_ALL=C sort -u)
if [ "${#CASE_IDS[@]}" -eq 0 ]; then
  echo "Error: the selected candidate has no registered live cases" >&2
  exit 2
fi
if [ "$REQUIRE_COMPLETE" -eq 1 ] && [ "$SELECTION_FROM_DIFF" -ne 1 ]; then
  echo "Error: --require-complete requires --changed-from selection" >&2
  exit 2
fi
total_executions=$(( ${#CASE_IDS[@]} * 2 * RUNS ))
minimum_rollout_limit_sum=$((total_executions * MIN_ROLLOUT_LIMIT_PER_CALL))
if [ "$ROLLOUT_PLANNED_LIMIT_SUM" -lt "$minimum_rollout_limit_sum" ]; then
  echo "Error: rollout limit sum must be at least $minimum_rollout_limit_sum for $total_executions planned executions" >&2
  exit 2
fi
if ! command -v timeout >/dev/null 2>&1; then
  echo "Error: timeout executable is required for bounded live evaluation" >&2
  exit 2
fi

if ! CODEX_PATH="$(command -v "$CODEX_BIN")"; then
  echo "Error: live executor is unavailable: $CODEX_BIN" >&2
  exit 2
fi
CODEX_PATH="$(realpath "$CODEX_PATH")"
if [ -L "$CODEX_PATH" ] || [ ! -f "$CODEX_PATH" ]; then
  echo "Error: live executor must resolve to a physical regular file" >&2
  exit 2
fi
READ_TOOL_PATH="$(dirname "$CODEX_PATH")/../codex-path/rg"
if [ ! -x "$READ_TOOL_PATH" ]; then
  if ! READ_TOOL_PATH="$(command -v rg)"; then
    echo "Error: rg executable is required for the controlled evaluation PATH" >&2
    exit 2
  fi
fi
READ_TOOL_PATH="$(realpath "$READ_TOOL_PATH")"
if [ -L "$READ_TOOL_PATH" ] || [ ! -f "$READ_TOOL_PATH" ] || [ ! -x "$READ_TOOL_PATH" ]; then
  echo "Error: rg must resolve to a physical executable file" >&2
  exit 2
fi
CODEX_SHA256="$(sha256sum "$CODEX_PATH" | cut -d' ' -f1)"
if [ "$PREPARE_ONLY" -ne 1 ]; then
  if ! [[ "$EXPECTED_EXECUTOR_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Error: execution requires --expected-executor-sha256 from a reviewed prepare-only run" >&2
    exit 2
  fi
  if [ "$EXPECTED_EXECUTOR_SHA256" != "$CODEX_SHA256" ]; then
    echo "Error: expected executor digest does not match the resolved live executor" >&2
    exit 2
  fi
fi
CLI_VERSION="$("$CODEX_PATH" --version 2>/dev/null | tail -n 1)"
if [ -z "$CLI_VERSION" ]; then
  echo "Error: could not determine live executor version" >&2
  exit 2
fi
CLI_PROBE_HOME="$(mktemp -d "$REPO_ROOT/.agent-eval-cli-probe.XXXXXX")"
cli_features="$(CODEX_HOME="$CLI_PROBE_HOME" "$CODEX_PATH" \
  --disable apps \
  --disable browser_use \
  --disable browser_use_external \
  --disable computer_use \
  --disable hooks \
  --disable image_generation \
  --disable multi_agent \
  --disable plugins \
  --disable remote_plugin \
  --disable tool_suggest \
  --disable view_image \
  --disable workspace_dependencies \
  -c 'default_permissions="agent-eval"' \
  -c 'permissions.agent-eval.filesystem={":root"="deny",":minimal"="read","/tmp/eval-fixture"="read","/tmp/eval-context"="read"}' \
  -c 'permissions.agent-eval.network.enabled=false' \
  -c "features.rollout_budget={enabled=true,limit_tokens=$MIN_ROLLOUT_LIMIT_PER_CALL,prefill_token_weight=$PREFILL_FALLBACK_WEIGHT,sampling_token_weight=$SAMPLING_FALLBACK_WEIGHT,reminder_at_remaining_tokens=[]}" \
  features list)"
if ! grep -Eq '^rollout_budget[[:space:]]+under development[[:space:]]+true$' <<< "$cli_features"; then
  echo "Error: Codex rollout budget feature is unavailable" >&2
  exit 2
fi
rm -rf -- "$CLI_PROBE_HOME"
CLI_PROBE_HOME=""

subject_path="$RUNNER_TMP/subject-manifest.json"
subject_arguments=()
for case_id in "${CASE_IDS[@]}"; do
  subject_arguments+=(--case "$case_id")
done
if [ "$SELECTION_FROM_DIFF" -eq 1 ]; then
  subject_arguments+=(--require-selected-cases-match)
fi

subject_digest="$(python3 "$SUBJECT_TOOL" create \
  --repo-root "$REPO_ROOT" \
  --registry "$REGISTRY" \
  --schema "$SCHEMA" \
  --runner "$SCRIPT_DIR/run-agent-evals.sh" \
  --grader "$GRADER" \
  --base-ref "$CHANGED_FROM" \
  --comparison-ref "$COMPARISON_REF" \
  "${subject_arguments[@]}" \
  --model "$MODEL" \
  --cli "$CLI_VERSION" \
  --executor-path "$CODEX_PATH" \
  --read-tool-path "$READ_TOOL_PATH" \
  --runs "$RUNS" \
  --jobs "$JOBS" \
  --selection-mode "$([ "$SELECTION_FROM_DIFF" -eq 1 ] && printf 'changed-from' || printf 'explicit')" \
  --rollout-planned-limit-sum "$ROLLOUT_PLANNED_LIMIT_SUM" \
  --prefill-fallback-weight "$PREFILL_FALLBACK_WEIGHT" \
  --sampling-fallback-weight "$SAMPLING_FALLBACK_WEIGHT" \
  --timeout-seconds "$TIMEOUT_SECONDS" \
  --output "$subject_path")"

if [ "$REQUIRE_COMPLETE" -eq 1 ]; then
  python3 - "$subject_path" <<'PY'
import json
import sys
subject = json.load(open(sys.argv[1], encoding="utf-8"))
runs = subject["executor"]["runs_per_configuration"]
for selected in subject["selected_cases"]:
    case = selected["definition"]
    if case["threshold"]["runs"] != runs:
        raise SystemExit(
            f"Error: {case['id']} requires {case['threshold']['runs']} runs; requested {runs}"
        )
PY
fi

if [ "$PREPARE_ONLY" -ne 1 ]; then
  if ! [[ "$EXPECTED_SUBJECT_DIGEST" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Error: execution requires --expected-subject-digest from a reviewed prepare-only run" >&2
    exit 2
  fi
  if [ "$EXPECTED_SUBJECT_DIGEST" != "$subject_digest" ]; then
    echo "Error: expected subject digest does not match the current bound subject" >&2
    exit 2
  fi
fi

if [ "$PREPARE_ONLY" -eq 1 ]; then
  python3 - "$subject_path" <<'PY'
import json
import sys
subject = json.load(open(sys.argv[1], encoding="utf-8"))
print(json.dumps({
    "profile": "live-agent-v2",
    "subject_digest": subject["subject_digest"],
    "head": subject["candidate"]["head"],
    "base": subject["candidate"]["base"],
    "comparison_commit": subject["comparison_commit"],
    "model": subject["executor"]["model"],
    "cli": subject["executor"]["cli"],
    "executor_identity": subject["executor"]["executable"],
    "read_tool_identity": subject["executor"]["read_tool"],
    "runs_per_configuration": subject["executor"]["runs_per_configuration"],
    "parallel_jobs": subject["executor"]["parallel_jobs"],
    "rollout_planned_limit_sum": subject["executor"]["rollout_planned_limit_sum"],
    "rollout_limit_kind": subject["executor"]["rollout_limit_kind"],
    "rollout_authoritative_unit_source": subject["executor"]["rollout_authoritative_unit_source"],
    "rollout_evidence_unit_source": subject["executor"]["rollout_evidence_unit_source"],
    "rollout_fallback_weights": subject["executor"]["rollout_fallback_weights"],
    "timeout_seconds": subject["executor"]["timeout_seconds"],
    "selection_mode": subject["selection_mode"],
    "case_ids": [item["definition"]["id"] for item in subject["selected_cases"]],
}, indent=2, sort_keys=True))
PY
  exit 0
fi

staging_parent="$RUNNER_TMP/evidence"
staging_root="$staging_parent/$subject_digest"
mkdir -p "$staging_root/runs"
cp "$subject_path" "$staging_root/subject-manifest.json"
python3 - "$subject_path" "$staging_root/selection.json" <<'PY'
import json
from pathlib import Path
import sys
subject = json.load(open(sys.argv[1], encoding="utf-8"))
Path(sys.argv[2]).write_text(
    json.dumps(subject["selection"], indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY

runtime_tools="$RUNNER_TMP/runtime-tools"
mkdir "$runtime_tools"
python3 - "$REPO_ROOT" "$subject_path" "$runtime_tools" <<'PY'
import hashlib
import json
from pathlib import Path
import shutil
import stat
import sys

repo = Path(sys.argv[1])
subject = json.load(open(sys.argv[2], encoding="utf-8"))
target = Path(sys.argv[3])
destinations = {
    "schema": "schema-v2.json",
    "grader": "grade.py",
    "verify.py": "verify.py",
    "aggregate.py": "aggregate.py",
    "fake_services.py": "fake_services.py",
}
for key, name in destinations.items():
    record = subject["bound_files"][key]
    source = repo / record["path"]
    mode = source.lstat().st_mode
    data = source.read_bytes()
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
        raise SystemExit(f"bound runtime tool is not a physical file: {record['path']}")
    if (
        hashlib.sha256(data).hexdigest() != record["sha256"]
        or len(data) != record["size"]
        or stat.S_IMODE(mode) != record["mode"]
    ):
        raise SystemExit(f"bound runtime tool changed after subject creation: {record['path']}")
    destination = target / name
    destination.write_bytes(data)
    destination.chmod(stat.S_IMODE(mode))
PY
SCHEMA="$runtime_tools/schema-v2.json"
GRADER="$runtime_tools/grade.py"
VERIFIER="$runtime_tools/verify.py"
AGGREGATOR="$runtime_tools/aggregate.py"
FAKE_SERVICES="$runtime_tools/fake_services.py"

real_git="$(command -v git)"
comparison_commit="$(python3 - "$subject_path" <<'PY'
import json
import sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["comparison_commit"])
PY
)"

execution_index=0
base_execution_rollout_limit=$((ROLLOUT_PLANNED_LIMIT_SUM / total_executions))
limit_remainder=$((ROLLOUT_PLANNED_LIMIT_SUM % total_executions))

case_value() {
  local case_id="$1"
  local pointer="$2"
  python3 - "$subject_path" "$case_id" "$pointer" <<'PY'
import json
import sys
subject = json.load(open(sys.argv[1], encoding="utf-8"))
case = next(
    item["definition"]
    for item in subject["selected_cases"]
    if item["definition"]["id"] == sys.argv[2]
)
value = case
for part in sys.argv[3].split("."):
    value = value[part]
if isinstance(value, list):
    for item in value:
        print(item)
else:
    print(value)
PY
}

retain_incomplete_evidence() {
  local reason="$1"
  local launched_csv="$2"
  local completed_csv="$3"
  local failed_csv="$4"
  local requested_root="$OUTPUT_ROOT"
  if [ -z "$requested_root" ]; then
    requested_root="$REPO_ROOT/tests/agent-evals/evidence/v2"
  fi
  python3 - "$requested_root" <<'PY'
import os
from pathlib import Path
import stat
import sys
target = Path(os.path.abspath(sys.argv[1]))
current = Path(target.anchor)
for part in target.parts[1:]:
    current /= part
    try:
        mode = current.lstat().st_mode
    except FileNotFoundError:
        continue
    if stat.S_ISLNK(mode):
        raise SystemExit(f"Error: evidence path crosses a symlink: {current}")
    if not stat.S_ISDIR(mode):
        raise SystemExit(f"Error: evidence path component is not a directory: {current}")
PY
  mkdir -p "$requested_root"
  requested_root="$(cd "$requested_root" && pwd -P)"
  local failure_root="$requested_root/rejected-$subject_digest-execution-$execution_index"
  if [ -e "$failure_root" ] || [ -L "$failure_root" ]; then
    echo "Error: incomplete evidence target already exists: $failure_root" >&2
    return 2
  fi
  python3 - "$staging_root/incomplete.json" "$reason" \
    "$launched_csv" "$completed_csv" "$failed_csv" <<'PY'
import json
from pathlib import Path
import sys
def indices(value):
    return [int(item) for item in value.split(",") if item]
launched = indices(sys.argv[3])
completed = indices(sys.argv[4])
failed = indices(sys.argv[5])
Path(sys.argv[1]).write_text(json.dumps({
    "schema_version": 2,
    "verified": False,
    "reason": sys.argv[2],
    "stopped_after_execution": max(launched, default=0),
    "launched_execution_indices": launched,
    "completed_execution_indices": completed,
    "failed_execution_indices": failed,
    "stop_policy": "finish-in-flight-then-stop-launching",
}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
  cp -a "$staging_root" "$failure_root"
  echo "Retained incomplete evidence: $failure_root"
}

run_execution() (
  local case_id="$1"
  local configuration="$2"
  local run_number="$3"
  local execution_index="$4"
  local execution_rollout_limit="$5"
  capability="$(case_value "$case_id" capability_profile)"
  fixture_relative="$(case_value "$case_id" fixture)"
  prompt_relative="$(case_value "$case_id" prompt)"
      run_work="$RUNNER_TMP/work/$configuration/$case_id/run-$run_number"
      fixture_root="$run_work/fixture"
      context_root="$run_work/context"
      fake_root="$run_work/fake-services"
      fake_state="$fake_root/state"
      sandbox_tmp="$run_work/sandbox-tmp"
      run_dir="$staging_root/runs/$configuration/$case_id/run-$run_number"
      mkdir -p "$run_work" "$context_root" "$run_dir/snapshots"
      mkdir -m 700 "$sandbox_tmp"
      cp -a "$REPO_ROOT/$fixture_relative" "$fixture_root"

      GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$real_git" -C "$fixture_root" init --quiet
      GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$real_git" -C "$fixture_root" \
        -c user.name=agent-eval -c user.email=agent-eval.invalid add -A
      GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$real_git" -C "$fixture_root" \
        -c user.name=agent-eval -c user.email=agent-eval.invalid commit --quiet -m fixture

      python3 "$FAKE_SERVICES" prepare --root "$fake_root" --real-git "$real_git"
      python3 - "$subject_path" "$READ_TOOL_PATH" "$fake_root/bin/rg" <<'PY'
import hashlib
import json
from pathlib import Path
import shutil
import stat
import sys

subject = json.load(open(sys.argv[1], encoding="utf-8"))
expected = subject["executor"]["read_tool"]
source = Path(sys.argv[2])
destination = Path(sys.argv[3])
mode = source.lstat().st_mode
data = source.read_bytes()
actual = {
    "path": str(source),
    "sha256": hashlib.sha256(data).hexdigest(),
    "size": len(data),
    "mode": stat.S_IMODE(mode),
}
if stat.S_ISLNK(mode) or not stat.S_ISREG(mode) or actual != expected:
    raise SystemExit("Error: bound read tool changed before materialization")
shutil.copy2(source, destination, follow_symlinks=False)
copied_mode = destination.lstat().st_mode
copied_data = destination.read_bytes()
if (
    stat.S_ISLNK(copied_mode)
    or not stat.S_ISREG(copied_mode)
    or hashlib.sha256(copied_data).hexdigest() != expected["sha256"]
    or len(copied_data) != expected["size"]
    or stat.S_IMODE(copied_mode) != expected["mode"]
):
    raise SystemExit("Error: materialized read tool differs from the bound source")
PY
      GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$real_git" -C "$fixture_root" \
        remote add origin "$fake_state/git-remote.git"
      GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$real_git" -C "$fixture_root" \
        push --quiet -u origin HEAD:refs/heads/main

      python3 - "$REPO_ROOT" "$subject_path" "$case_id" "$configuration" \
        "$comparison_commit" "$context_root" <<'PY'
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys

repo = Path(sys.argv[1])
subject = json.load(open(sys.argv[2], encoding="utf-8"))
selected = next(
    item
    for item in subject["selected_cases"]
    if item["definition"]["id"] == sys.argv[3]
)
configuration = sys.argv[4]
comparison = sys.argv[5]
target_root = Path(sys.argv[6])
for relative in selected["context"]["paths"]:
    source = repo / relative
    if source.is_symlink() or not source.is_file():
        raise SystemExit(f"context must be a physical file: {relative}")
    target = target_root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if configuration == "current":
        shutil.copy2(source, target, follow_symlinks=False)
    else:
        tree = subprocess.run(
            ["git", "ls-tree", comparison, "--", relative],
            cwd=repo,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        ).stdout.split()
        if not tree:
            continue
        if tree[0] not in {"100644", "100755"}:
            raise SystemExit(f"comparison context must be a regular file: {relative}")
        result = subprocess.run(
            ["git", "show", f"{comparison}:{relative}"],
            cwd=repo,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        target.write_bytes(result.stdout)
        target.chmod(int(tree[0], 8) & 0o777)
PY

      python3 "$VERIFIER" snapshot \
        --repo-root "$REPO_ROOT" \
        --fixture "$fixture_root" \
        --context "$context_root" \
        --fake-state "$fake_state" \
        --output "$run_dir/snapshots/before.json"
      PYTHONDONTWRITEBYTECODE=1 python3 "$VERIFIER" preflight \
        --subject "$staging_root/subject-manifest.json" \
        --snapshot "$run_dir/snapshots/before.json" \
        --case-id "$case_id" \
        --configuration "$configuration" >/dev/null

      if [ "$capability" = "read-only" ]; then
        fixture_access="read"
        fake_state_access="read"
      elif [ "$capability" = "workspace-write" ]; then
        fixture_access="write"
        fake_state_access="write"
      else
        echo "Error: unsupported capability profile: $capability" >&2
        exit 2
      fi
      permission_filesystem="$(python3 - "$fixture_root" "$fixture_access" \
        "$context_root" "$fake_root/bin" "$fake_state" "$fake_state_access" \
        "$runtime_tools" "$CODEX_PATH" <<'PY'
import json
import sys
entries = [
    (":root", "deny"),
    (":minimal", "read"),
    (":tmpdir", "write"),
    (sys.argv[1], sys.argv[2]),
    (sys.argv[3], "read"),
    (sys.argv[4], "read"),
    (sys.argv[5], sys.argv[6]),
    (sys.argv[7], "read"),
    (sys.argv[8], "read"),
]
print("{" + ",".join(f"{json.dumps(path)}={json.dumps(access)}" for path, access in entries) + "}")
PY
)"

      rendered_prompt="$run_dir/prompt.txt"
      python3 - "$REPO_ROOT/$prompt_relative" "$rendered_prompt" \
        "$context_root" "$fixture_root" "$case_id" "$subject_path" <<'PY'
import hashlib
import json
from pathlib import Path
import stat
import sys
source = Path(sys.argv[1])
mode = source.lstat().st_mode
data = source.read_bytes()
subject = json.load(open(sys.argv[6], encoding="utf-8"))
record = next(
    item["prompt"]
    for item in subject["selected_cases"]
    if item["definition"]["id"] == sys.argv[5]
)
if stat.S_ISLNK(mode) or not stat.S_ISREG(mode):
    raise SystemExit("bound prompt is not a physical regular file")
if (
    hashlib.sha256(data).hexdigest() != record["sha256"]
    or len(data) != record["size"]
    or stat.S_IMODE(mode) != record["mode"]
):
    raise SystemExit("bound prompt changed after subject creation")
template = data.decode("utf-8")
rendered = template.replace("{context_root}", sys.argv[3]).replace("{fixture_root}", sys.argv[4])
rendered += (
    "\nUse case_id " + sys.argv[5] + ". Return only one JSON object matching the supplied schema. "
    "The decisions object must contain d1 through d6; populate the decisions named by the task "
    "and set every unused decision key to null. "
    "Do not use real network, browser, Git remote, or GitHub services; local fakes are installed. "
    "Do not invoke Git; all relevant files are materialized. Use only simple read commands, and use "
    "the patch tool, not shell mutation commands, for the one permitted file write.\n"
)
Path(sys.argv[2]).write_text(rendered, encoding="utf-8")
PY

      sentinel="AGENTS_EVAL_SENTINEL_$(python3 -c 'import secrets; print(secrets.token_hex(24))')"
      sentinel_sha="$(printf '%s' "$sentinel" | sha256sum | cut -d' ' -f1)"
      python3 - "$run_dir/input.json" "$subject_digest" "$case_id" \
        "$configuration" "$run_number" "$capability" "$MODEL" "$CLI_VERSION" \
        "$sentinel_sha" "$fixture_root" "$context_root" "$ROLLOUT_PLANNED_LIMIT_SUM" "$TIMEOUT_SECONDS" \
        "$execution_rollout_limit" "$PREFILL_FALLBACK_WEIGHT" "$SAMPLING_FALLBACK_WEIGHT" \
        "$execution_index" "$JOBS" <<'PY'
import json
from pathlib import Path
import sys
value = {
    "schema_version": 2,
    "subject_digest": sys.argv[2],
    "case_id": sys.argv[3],
    "configuration": sys.argv[4],
    "run_number": int(sys.argv[5]),
    "execution_index": int(sys.argv[17]),
    "parallel_jobs": int(sys.argv[18]),
    "capability_profile": sys.argv[6],
    "model": sys.argv[7],
    "cli": sys.argv[8],
    "sentinel_sha256": sys.argv[9],
    "workspace_root": sys.argv[10],
    "context_root": sys.argv[11],
    "rollout_planned_limit_sum": int(sys.argv[12]),
    "rollout_limit_kind": "codex-native-response-boundary",
    "rollout_authoritative_unit_source": "provider-reported-or-noncached-fallback",
    "rollout_evidence_unit_source": "exec-jsonl-noncached-fallback",
    "rollout_fallback_weights": {
        "prefill_token_weight": float(sys.argv[15]),
        "sampling_token_weight": float(sys.argv[16]),
    },
    "timeout_seconds": int(sys.argv[13]),
    "execution_rollout_limit": int(sys.argv[14]),
    "event_capture": "codex-jsonl",
    "permission_profile": "agent-eval",
    "ambient_host_read": "denied",
    "network_policy": {
        "os_network": "denied",
        "web_search": "disabled",
        "external_endpoints": [],
        "fake_services": ["git-remote", "github", "network", "browser"],
    },
    "execution_status": "pending",
}
Path(sys.argv[1]).write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

      python3 - "$subject_path" "$CODEX_PATH" "$READ_TOOL_PATH" "$fake_root/bin/rg" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
subject = json.load(open(sys.argv[1], encoding="utf-8"))
for label, argument, expected in (
    ("live executor", sys.argv[2], subject["executor"]["executable"]),
    ("read tool", sys.argv[3], subject["executor"]["read_tool"]),
):
    path = Path(os.path.abspath(argument))
    mode = path.lstat().st_mode
    data = path.read_bytes()
    actual = {
        "path": str(path),
        "sha256": hashlib.sha256(data).hexdigest(),
        "size": len(data),
        "mode": stat.S_IMODE(mode),
    }
    if stat.S_ISLNK(mode) or not stat.S_ISREG(mode) or actual != expected:
        raise SystemExit(f"Error: bound {label} changed before provider execution")
materialized = Path(sys.argv[4])
materialized_mode = materialized.lstat().st_mode
materialized_data = materialized.read_bytes()
if (
    stat.S_ISLNK(materialized_mode)
    or not stat.S_ISREG(materialized_mode)
    or hashlib.sha256(materialized_data).hexdigest()
    != subject["executor"]["read_tool"]["sha256"]
    or len(materialized_data) != subject["executor"]["read_tool"]["size"]
    or stat.S_IMODE(materialized_mode)
    != subject["executor"]["read_tool"]["mode"]
):
    raise SystemExit("Error: materialized read tool changed before provider execution")
PY

      start_ns="$(python3 -c 'import time; print(time.time_ns())')"
      set +e
      eval_path="$fake_root/bin:/usr/bin:/bin"
      TMPDIR="$sandbox_tmp" PATH="$eval_path" \
        timeout --signal=TERM --kill-after=10s "$TIMEOUT_SECONDS" \
        "$CODEX_PATH" exec \
        --ephemeral \
        --ignore-user-config \
        --ignore-rules \
        --strict-config \
        --skip-git-repo-check \
        --disable apps \
        --disable browser_use \
        --disable browser_use_external \
        --disable computer_use \
        --disable hooks \
        --disable image_generation \
        --disable multi_agent \
        --disable plugins \
        --disable remote_plugin \
        --disable tool_suggest \
        --disable view_image \
        --disable workspace_dependencies \
        -c 'approval_policy="never"' \
        -c 'default_permissions="agent-eval"' \
        -c "permissions.agent-eval.filesystem=$permission_filesystem" \
        -c 'permissions.agent-eval.network.enabled=false' \
        -c "features.rollout_budget={enabled=true,limit_tokens=$execution_rollout_limit,prefill_token_weight=$PREFILL_FALLBACK_WEIGHT,sampling_token_weight=$SAMPLING_FALLBACK_WEIGHT,reminder_at_remaining_tokens=[]}" \
        -c 'web_search="disabled"' \
        -c 'tools.web_search=false' \
        -c 'shell_environment_policy.inherit="core"' \
        -c "shell_environment_policy.set.PATH=\"$eval_path\"" \
        -c "shell_environment_policy.set.TMPDIR=\"$sandbox_tmp\"" \
        -c "shell_environment_policy.set.AGENT_EVAL_SENTINEL=\"$sentinel\"" \
        --cd "$fixture_root" \
        --model "$MODEL" \
        --output-schema "$SCHEMA" \
        --output-last-message "$run_dir/result.json" \
        --json \
        "$(<"$rendered_prompt")" \
        > "$run_dir/events.jsonl" \
        2> "$run_dir/executor.stderr"
      execution_status="$?"
      set -e
      end_ns="$(python3 -c 'import time; print(time.time_ns())')"

      if [ ! -f "$run_dir/result.json" ]; then
        : > "$run_dir/result.json"
      fi
      python3 - "$run_dir/input.json" "$execution_status" <<'PY'
import json
from pathlib import Path
import sys
path = Path(sys.argv[1])
value = json.loads(path.read_text(encoding="utf-8"))
value["execution_status"] = "completed" if int(sys.argv[2]) == 0 else "failed"
value["executor_exit_code"] = int(sys.argv[2])
path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

      python3 "$VERIFIER" snapshot \
        --repo-root "$REPO_ROOT" \
        --fixture "$fixture_root" \
        --context "$context_root" \
        --fake-state "$fake_state" \
        --output "$run_dir/snapshots/after.json"

      python3 - "$run_dir/events.jsonl" "$run_dir/timing.json" \
        "$start_ns" "$end_ns" "$execution_status" \
        "$PREFILL_FALLBACK_WEIGHT" "$SAMPLING_FALLBACK_WEIGHT" <<'PY'
from decimal import Decimal
import json
import math
from pathlib import Path
import sys
events = []
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue
    if isinstance(event, dict):
        events.append(event)
usage = next((event.get("usage") for event in reversed(events) if event.get("type") == "turn.completed"), {})
if not isinstance(usage, dict):
    usage = {}
input_tokens = usage.get("input_tokens")
cached_input_tokens = usage.get("cached_input_tokens")
output_tokens = usage.get("output_tokens")
reasoning_output_tokens = usage.get("reasoning_output_tokens")
counts_valid = all(
    isinstance(value, int) and not isinstance(value, bool) and value >= 0
    for value in (input_tokens, cached_input_tokens, output_tokens)
)
non_cached_input_tokens = (
    max(input_tokens - cached_input_tokens, 0) if counts_valid else None
)
total_tokens = input_tokens + output_tokens if counts_valid else None
portable_units_decimal = (
    Decimal(non_cached_input_tokens) * Decimal(sys.argv[6])
    + Decimal(output_tokens) * Decimal(sys.argv[7])
    if counts_valid
    else None
)
if portable_units_decimal is None:
    portable_fallback_units = None
elif portable_units_decimal == portable_units_decimal.to_integral_value():
    portable_fallback_units = int(portable_units_decimal)
else:
    candidate = float(portable_units_decimal)
    portable_fallback_units = candidate if math.isfinite(candidate) else None
value = {
    "elapsed_seconds": (int(sys.argv[4]) - int(sys.argv[3])) / 1_000_000_000,
    "input_tokens": input_tokens,
    "cached_input_tokens": cached_input_tokens,
    "non_cached_input_tokens": non_cached_input_tokens,
    "output_tokens": output_tokens,
    "reasoning_output_tokens": reasoning_output_tokens,
    "total_tokens": total_tokens,
    "portable_fallback_units": portable_fallback_units,
    "authoritative_rollout_units": None,
    "executor_exit_code": int(sys.argv[5]),
}
Path(sys.argv[2]).write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

      usage_failure="$(python3 - "$run_dir/timing.json" <<'PY'
import json
import math
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
units = value.get("portable_fallback_units")
valid_units = (
    isinstance(units, int) and not isinstance(units, bool) and units >= 0
) or (
    isinstance(units, float) and math.isfinite(units) and units >= 0
)
if not valid_units:
    print("provider usage omitted or invalidated fallback rollout accounting")
PY
)"

      set +e
      PYTHONDONTWRITEBYTECODE=1 python3 "$GRADER" \
        --subject "$staging_root/subject-manifest.json" \
        --run-dir "$run_dir" \
        --output "$run_dir/grading.json"
      grade_status="$?"
      set -e
      if [ "$grade_status" -eq 2 ] || [ ! -f "$run_dir/grading.json" ]; then
        printf '%s\n' \
          "grader could not produce evidence for $case_id $configuration run $run_number" \
          > "$run_work/failure-reason"
        return 2
      fi
      if [ -n "$usage_failure" ]; then
        printf '%s\n' "$usage_failure" > "$run_work/failure-reason"
        return 2
      fi
)

ACTIVE_PIDS=()
BATCH_INDICES=()
BATCH_WORK_ROOTS=()
ALL_LAUNCHED_INDICES=()
ALL_COMPLETED_INDICES=()
ALL_FAILED_INDICES=()

wait_for_execution_batch() {
  local batch_offset
  local execution_status
  local failed_reason=""
  local reason_path
  local launched_csv
  local completed_csv
  local failed_csv

  for ((batch_offset = 0; batch_offset < ${#ACTIVE_PIDS[@]}; batch_offset++)); do
    if wait "${ACTIVE_PIDS[$batch_offset]}"; then
      execution_status=0
    else
      execution_status=$?
    fi
    ALL_COMPLETED_INDICES+=("${BATCH_INDICES[$batch_offset]}")
    if [ "$execution_status" -ne 0 ]; then
      ALL_FAILED_INDICES+=("${BATCH_INDICES[$batch_offset]}")
      reason_path="${BATCH_WORK_ROOTS[$batch_offset]}/failure-reason"
      if [ -z "$failed_reason" ] && [ -f "$reason_path" ]; then
        failed_reason="$(<"$reason_path")"
      fi
      if [ -z "$failed_reason" ]; then
        failed_reason="execution ${BATCH_INDICES[$batch_offset]} failed before producing complete evidence"
      fi
    fi
  done
  ACTIVE_PIDS=()
  BATCH_INDICES=()
  BATCH_WORK_ROOTS=()

  if [ "${#ALL_FAILED_INDICES[@]}" -gt 0 ]; then
    launched_csv="$(IFS=,; printf '%s' "${ALL_LAUNCHED_INDICES[*]}")"
    completed_csv="$(IFS=,; printf '%s' "${ALL_COMPLETED_INDICES[*]}")"
    failed_csv="$(IFS=,; printf '%s' "${ALL_FAILED_INDICES[*]}")"
    retain_incomplete_evidence \
      "$failed_reason" "$launched_csv" "$completed_csv" "$failed_csv"
    echo "Error: $failed_reason; completed in-flight executions and stopped before launching the next batch" >&2
    exit 2
  fi
}

for case_id in "${CASE_IDS[@]}"; do
  for configuration in current comparison; do
    for run_number in $(seq 1 "$RUNS"); do
      execution_index=$((execution_index + 1))
      execution_rollout_limit="$base_execution_rollout_limit"
      if [ "$execution_index" -le "$limit_remainder" ]; then
        execution_rollout_limit=$((execution_rollout_limit + 1))
      fi
      run_execution \
        "$case_id" "$configuration" "$run_number" \
        "$execution_index" "$execution_rollout_limit" &
      ACTIVE_PIDS+=("$!")
      BATCH_INDICES+=("$execution_index")
      BATCH_WORK_ROOTS+=(
        "$RUNNER_TMP/work/$configuration/$case_id/run-$run_number"
      )
      ALL_LAUNCHED_INDICES+=("$execution_index")
      if [ "${#ACTIVE_PIDS[@]}" -ge "$JOBS" ]; then
        wait_for_execution_batch
      fi
    done
  done
done
if [ "${#ACTIVE_PIDS[@]}" -gt 0 ]; then
  wait_for_execution_batch
fi

PYTHONDONTWRITEBYTECODE=1 python3 "$AGGREGATOR" \
  --root "$staging_root" \
  --output "$staging_root/aggregate.json"
PYTHONDONTWRITEBYTECODE=1 python3 "$VERIFIER" seal --root "$staging_root"

verify_arguments=(check --root "$staging_root")
verification="$(PYTHONDONTWRITEBYTECODE=1 python3 "$VERIFIER" "${verify_arguments[@]}")"

if [ -z "$OUTPUT_ROOT" ]; then
  OUTPUT_ROOT="$REPO_ROOT/tests/agent-evals/evidence/v2"
fi
python3 - "$OUTPUT_ROOT" <<'PY'
import os
from pathlib import Path
import stat
import sys

target = Path(os.path.abspath(sys.argv[1]))
current = Path(target.anchor)
for part in target.parts[1:]:
    current /= part
    try:
        mode = current.lstat().st_mode
    except FileNotFoundError:
        continue
    if stat.S_ISLNK(mode):
        raise SystemExit(f"Error: evidence path crosses a symlink: {current}")
    if not stat.S_ISDIR(mode):
        raise SystemExit(f"Error: evidence path component is not a directory: {current}")
PY
mkdir -p "$OUTPUT_ROOT"
OUTPUT_ROOT="$(cd "$OUTPUT_ROOT" && pwd -P)"
final_root="$OUTPUT_ROOT/$subject_digest"
if [ -e "$final_root" ] || [ -L "$final_root" ]; then
  echo "Error: evidence target already exists: $final_root" >&2
  exit 2
fi
cp -a "$staging_root" "$final_root"
final_verify_arguments=(check --root "$final_root")
if [ "$REQUIRE_COMPLETE" -eq 1 ]; then
  final_verify_arguments+=(--require-complete)
fi
if [ "$REQUIRE_CURRENT_PASS" -eq 1 ]; then
  final_verify_arguments+=(--require-current-pass)
fi
set +e
final_verification="$(PYTHONDONTWRITEBYTECODE=1 python3 "$VERIFIER" "${final_verify_arguments[@]}" 2>&1)"
final_status="$?"
set -e

printf '%s\n' "$verification"
echo "Verified evidence: $final_root"
if [ "$final_status" -ne 0 ]; then
  printf '%s\n' "$final_verification" >&2
  exit "$final_status"
fi
