#!/usr/bin/env bash

set -euo pipefail
umask 077

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
# Mutation and dirty-state scenarios must never write into the source worktree.
REPO_ROOT="$TEST_ROOT/repository"
mkdir "$REPO_ROOT"
cp "$SOURCE_ROOT/AGENTS.md" "$SOURCE_ROOT/CONTRIBUTING.md" "$REPO_ROOT/"
mkdir "$REPO_ROOT/tests" "$REPO_ROOT/.agents" "$REPO_ROOT/project-templates"
cp -R "$SOURCE_ROOT/tests/." "$REPO_ROOT/tests/"
cp -R "$SOURCE_ROOT/.agents/." "$REPO_ROOT/.agents/"
cp -R "$SOURCE_ROOT/project-templates/." "$REPO_ROOT/project-templates/"
git -C "$REPO_ROOT" init -q
git -C "$REPO_ROOT" -c user.name=Test -c user.email=test@example.invalid add -A
git -C "$REPO_ROOT" -c user.name=Test -c user.email=test@example.invalid commit -qm fixture
RUNNER="$REPO_ROOT/tests/run-agent-evals.sh"
AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME="$TEST_ROOT/source-codex-home"
DIRTY_MARKER="$REPO_ROOT/.agent-eval-dirty-fixture.$$"
MUTATED_PROMPT="$REPO_ROOT/tests/agent-evals/fixtures/workflow-negative/prompt.md"
PROMPT_BACKUP=""
ROLLOUT_LIMIT_SUM=65536

cleanup() {
  if [ -n "$PROMPT_BACKUP" ] && [ -f "$PROMPT_BACKUP" ]; then
    cp -p -- "$PROMPT_BACKUP" "$MUTATED_PROMPT"
  fi
  rm -f -- "$DIRTY_MARKER"
  rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -m 700 "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME"
printf '%s\n' '{"auth_mode":"chatgpt","last_refresh":"2099-01-01T00:00:00Z","tokens":{"access_token":"e30.eyJleHAiOjQxMDI0NDQ4MDB9.x","account_id":"test-account","id_token":"test-id","refresh_token":"test"}}' \
  > "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json"
chmod 600 "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json"
export CODEX_HOME="$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME"
export AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME
# The runner must not trust ambient temporary-directory placement or credential
# overrides when it constructs the evaluated executor environment.
export TMPDIR="$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME"
export OPENAI_API_KEY="must-not-reach-executor"
export CODEX_API_KEY="must-not-reach-executor"
export CODEX_ACCESS_TOKEN="must-not-reach-executor"
export OPENAI_BASE_URL="https://unapproved.example.invalid"
export HTTPS_PROXY="https://unapproved-proxy.example.invalid"
export SSL_CERT_FILE="$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/unapproved-ca.pem"
export SENTRY_AUTH_TOKEN="must-not-reach-executor"
export SSH_AUTH_SOCK="$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/unapproved-agent.sock"
AGENTS_ECOSYSTEM_TEST_RUNTIME_HOME_LOG="$TEST_ROOT/runtime-home.log"
export AGENTS_ECOSYSTEM_TEST_RUNTIME_HOME_LOG

python3 - "$REPO_ROOT/tests/agent-evals/runner.py" <<'PY'
from pathlib import Path
import sys
compile(Path(sys.argv[1]).read_text(encoding="utf-8"), sys.argv[1], "exec")
PY

list_output="$(bash "$RUNNER" --list)"
[ "$(grep -c '^CASE v2\.' <<< "$list_output")" -eq 45 ]
grep -q '^PROFILE live-agent-v2$' <<< "$list_output"

# Registry loading itself enforces the important coverage invariant: a case may
# not claim a changed path it does not provide to the evaluated model.
PYTHONDONTWRITEBYTECODE=1 python3 - "$REPO_ROOT" <<'PY'
import importlib.util
from pathlib import Path
import sys
import tempfile

path = Path(sys.argv[1]) / "tests/agent-evals/runner.py"
spec = importlib.util.spec_from_file_location("agent_eval_runner", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
registry = module.load_registry()
assert len(registry["cases"]) == 45
for case in registry["cases"]:
    for rule in case["affected_paths"]:
        assert module.path_is_covered(rule, case["context_paths"]), (case["id"], rule)

tdd_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/tdd-positive/prompt.md"
).read_text(encoding="utf-8")
assert "Retain the generated `.tdd-cycle`" in tdd_prompt

adversarial_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/adversarial-synthesis/prompt.md"
).read_text(encoding="utf-8")
assert "fixture is intentionally not a Git working tree" in adversarial_prompt
assert "Do not invoke Git" in adversarial_prompt
assert "Retain each supplied finding identifier verbatim" in adversarial_prompt

decline_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/wrap-completion-decline/prompt.md"
).read_text(encoding="utf-8")
assert "first item must be `high`" in decline_prompt

compound_low_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/compound-relevance-low/prompt.md"
).read_text(encoding="utf-8")
assert "canonical disposition `not applicable`" in compound_low_prompt

onboard_explanation_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/onboard-explanation/prompt.md"
).read_text(encoding="utf-8")
assert "Do not load document-reconciliation" in onboard_explanation_prompt

onboard_generated_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/onboard-generated/prompt.md"
).read_text(encoding="utf-8")
onboard_generated_words = " ".join(onboard_generated_prompt.split())
assert "intentionally not a Git working tree" in onboard_generated_words
assert "Do not invoke Git" in onboard_generated_prompt
assert "generated-file provenance is fully established" in onboard_generated_words

workflow_positive_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/workflow-positive/prompt.md"
).read_text(encoding="utf-8")
workflow_positive_words = " ".join(workflow_positive_prompt.split())
assert "Read each supplied context file once" in workflow_positive_words
assert "Do not use recursive pipelines" in workflow_positive_prompt
assert "Do not invoke Git" in workflow_positive_words

wrap_positive_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/wrap-completion-positive/prompt.md"
).read_text(encoding="utf-8")
wrap_positive_words = " ".join(wrap_positive_prompt.split())
assert "intentionally empty harness artifact" in wrap_positive_words
assert "Do not invoke Git" in wrap_positive_prompt
assert "create at most one runtime fixture" in wrap_positive_words
assert "Do not invoke `rm`" in wrap_positive_prompt

wrap_negative_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/wrap-completion-negative/prompt.md"
).read_text(encoding="utf-8")
assert "exact canonical array `[\"low\", \"not applicable\"]`" in wrap_negative_prompt

wrap_commit_only_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/wrap-completion-commit-only/prompt.md"
).read_text(encoding="utf-8")
assert "exact canonical array `[\"high\", \"required\"]`" in wrap_commit_only_prompt

wrap_generic_preview_prompt = (
    Path(sys.argv[1]) / "tests/agent-evals/fixtures/wrap-completion-generic-preview/prompt.md"
).read_text(encoding="utf-8")
wrap_generic_preview_words = " ".join(wrap_generic_preview_prompt.split())
assert 'unqualified "wrap this up"' in wrap_generic_preview_words
assert "Do not invoke Git" in wrap_generic_preview_words

generic_preview_case = next(
    case for case in registry["cases"]
    if case["id"] == "v2.wrap-completion.generic-preview"
)
commit_only_decision_grade = module.grade(
    generic_preview_case,
    {
        "case_id": generic_preview_case["id"],
        "decisions": {
            "d1": "preview awaiting decision",
            "d2": ["src/wrap-policy.md", "tests/wrap-policy-test.md"],
            "d3": "fix: restore generic wrap commit previews",
            "d4": 1,
            "d5": False,
            "d6": False,
        },
        "summary": "One question asks only whether to commit; push is omitted.",
    },
    {},
    {},
    {},
    0,
    [{"type": "turn.completed"}],
)
assert next(
    check for check in commit_only_decision_grade["checks"]
    if check["id"] == "single-effect-decision"
)["passed"] is False

wrapped_content = "The check preserves filesystem\nidentity across replacement.\n"
wrapped_record = {
    "path": "solution.md",
    "executable": False,
    "sha256": module.digest_bytes(wrapped_content.encode("utf-8")),
    "size": len(wrapped_content.encode("utf-8")),
}
wrapped_grade = module.grade(
    {
        "id": "wrapped-phrase",
        "capability_profile": "workspace-write",
        "permitted_fixture_mutations": ["solution.md"],
        "result_assertions": [],
        "state_assertions": [{
            "id": "wrapped-path-contains",
            "operator": "path-contains",
            "path": "solution.md",
            "expected": "filesystem identity",
        }],
    },
    {"case_id": "wrapped-phrase"},
    {},
    {"solution.md": wrapped_record},
    {"solution.md": wrapped_content},
    0,
    [{"type": "turn.completed"}],
)
assert next(
    check for check in wrapped_grade["checks"]
    if check["id"] == "wrapped-path-contains"
)["passed"] is True

empty_expected_grade = module.grade(
    {
        "id": "empty-expected",
        "capability_profile": "workspace-write",
        "permitted_fixture_mutations": ["solution.md"],
        "result_assertions": [],
        "state_assertions": [{
            "id": "empty-path-contains",
            "operator": "path-contains",
            "path": "solution.md",
            "expected": " \n\t",
        }],
    },
    {"case_id": "empty-expected"},
    {},
    {"solution.md": wrapped_record},
    {"solution.md": wrapped_content},
    0,
    [{"type": "turn.completed"}],
)
assert next(
    check for check in empty_expected_grade["checks"]
    if check["id"] == "empty-path-contains"
)["passed"] is False

with tempfile.TemporaryDirectory(prefix="agents-ecosystem-snapshot-", dir="/tmp") as root_text:
    root = Path(root_text)
    (root / ".agents").mkdir()
    (root / ".codex").mkdir()
    (root / ".git").mkdir()
    (root / "nested" / ".agents").mkdir(parents=True)
    (root / "nested" / ".git").mkdir(parents=True)
    (root / "unexpected").mkdir()
    snapshot = module.snapshot(root)
    assert ".agents/" not in snapshot
    assert ".codex/" not in snapshot
    assert ".git/" not in snapshot
    assert snapshot["nested/.agents/"] == {
        "path": "nested/.agents/",
        "type": "empty-directory",
    }
    assert snapshot["nested/.git/"] == {
        "path": "nested/.git/",
        "type": "empty-directory",
    }
    assert snapshot["unexpected/"] == {
        "path": "unexpected/",
        "type": "empty-directory",
    }
    (root / ".agents" / "project.md").write_text("runtime state\n")
    (root / ".codex" / "state.json").write_text("{}\n")
    (root / ".git" / "config").write_text("[core]\n")
    snapshot = module.snapshot(root)
    assert ".agents/project.md" in snapshot
    assert ".codex/state.json" in snapshot
    assert ".git/config" in snapshot

cases = [
    {"id": "two-of-three", "threshold": {"required_passes": 2, "runs": 3}},
    {"id": "all-three", "threshold": {"required_passes": 3, "runs": 3}},
]
passing = [
    {"case_id": "two-of-three", "configuration": "current", "passed": value}
    for value in (True, True, False)
] + [
    {"case_id": "all-three", "configuration": "current", "passed": True}
    for _ in range(3)
]
assert module.thresholds_met(cases, passing, 3) is True
passing[-1]["passed"] = False
assert module.thresholds_met(cases, passing, 3) is False
assert module.thresholds_met(cases, passing, 2) is False

import threading
import time
active = 0
maximum = 0
lock = threading.Lock()

def worker(value):
    global active, maximum
    with lock:
        active += 1
        maximum = max(maximum, active)
    time.sleep(0.03)
    with lock:
        active -= 1
    return value * 2

assert module.execute_plan([1, 2, 3, 4], 2, worker) == [2, 4, 6, 8]
assert maximum == 2

started = []
def failing_worker(value):
    with lock:
        started.append(value)
    if value == 2:
        raise RuntimeError("structural failure")
    return value

try:
    module.execute_plan([1, 2, 3, 4], 2, failing_worker)
except RuntimeError:
    pass
else:
    raise AssertionError("structural worker failure was swallowed")
assert sorted(started) == [1, 2], started
PY

fake_codex="$TEST_ROOT/codex"
cat > "$fake_codex" <<'PY'
#!/usr/bin/env python3
import json
import os
from pathlib import Path
import re
import sys
import time

args = sys.argv[1:]
if Path(sys.argv[0]).is_symlink():
    raise SystemExit("runner invoked the executor through an unresolved symlink")
source_codex_home = Path(os.environ["AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME"])
runtime_codex_home = Path(os.environ["CODEX_HOME"])
if runtime_codex_home == source_codex_home or source_codex_home in runtime_codex_home.parents:
    raise SystemExit("runner exposed the source Codex home to the executor")
for name in ("OPENAI_API_KEY", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN"):
    if name in os.environ:
        raise SystemExit(f"runner inherited credential override: {name}")
for name in ("OPENAI_BASE_URL", "HTTPS_PROXY", "SSL_CERT_FILE", "SENTRY_AUTH_TOKEN", "SSH_AUTH_SOCK"):
    if name in os.environ:
        raise SystemExit(f"runner inherited unbound executor environment: {name}")
if runtime_codex_home.stat().st_mode & 0o777 != 0o700:
    raise SystemExit("runner Codex home is not private")
runtime_auth = runtime_codex_home / "auth.json"
if runtime_auth.read_bytes() != (source_codex_home / "auth.json").read_bytes():
    raise SystemExit("runner Codex home does not contain the bound authentication copy")
if runtime_auth.stat().st_mode & 0o777 != 0o600:
    raise SystemExit("runner authentication copy is not private")
permission_config = next(
    value for value in args if value.startswith("permissions.agent-eval.filesystem=")
)
runtime_rule = f'{json.dumps(str(runtime_codex_home))}="deny"'
if runtime_rule not in permission_config:
    raise SystemExit("runner exposed the private Codex home to evaluated tools")
runtime_tmp = Path(os.environ["TMPDIR"])
if runtime_tmp == runtime_codex_home or runtime_codex_home in runtime_tmp.parents:
    raise SystemExit("runner did not isolate the Codex sandbox temporary directory")
if source_codex_home in runtime_tmp.parents:
    raise SystemExit("runner placed sandbox temporary state in the source Codex home")
if runtime_tmp.stat().st_mode & 0o777 != 0o700:
    raise SystemExit("runner Codex temporary directory is not private")
if os.environ.get("AGENTS_ECOSYSTEM_TEST_RUNTIME_HOME_LOG"):
    descriptor = os.open(
        os.environ["AGENTS_ECOSYSTEM_TEST_RUNTIME_HOME_LOG"],
        os.O_WRONLY | os.O_CREAT | os.O_APPEND,
        0o600,
    )
    try:
        os.write(descriptor, (str(runtime_codex_home) + "\n").encode())
    finally:
        os.close(descriptor)
if os.environ.get("AGENT_EVAL_EXECUTOR_MARKER"):
    Path(os.environ["AGENT_EVAL_EXECUTOR_MARKER"]).write_text("executed\n")
if os.environ.get("AGENT_EVAL_TIMEOUT_AFTER_OUTPUT"):
    print(json.dumps({"type": "thread.started"}), flush=True)
    print("partial stderr", file=sys.stderr, flush=True)
    time.sleep(5)
output = Path(args[args.index("--output-last-message") + 1])
workspace = Path(args[args.index("--cd") + 1])
if os.environ.get("AGENT_EVAL_MUTATE_RUNTIME_AUTH") and "current" in output.parts:
    runtime_auth.write_text('{"mutated":true}\n')
prompt = args[-1]
case_id = re.search(r"Use case_id ([a-z0-9.-]+)\. Return", prompt).group(1)
if os.environ.get("AGENT_EVAL_MUTATE_PATH"):
    Path(os.environ["AGENT_EVAL_MUTATE_PATH"]).write_text("changed during execution\n")
decisions = {f"d{number}": None for number in range(1, 7)}
if case_id == "v2.workflow-rigor.negative":
    decisions.update(d1=False, d2=False, d3=False, d4=False)
elif case_id == "v2.workflow-rigor.positive":
    decisions.update(d1=0, d2=1, d3=True, d4=True, d5=True, d6=True)
    (workspace / ".codex").mkdir()
    (workspace / "case-note.md").write_text("ordinary and elevated routing\n")
elif case_id == "v2.wrap-completion.positive":
    decisions.update(
        d1=True,
        d2=["high", "already captured"],
        d3="current",
        d4=True,
        d5=False,
        d6=False,
    )
    (workspace / "tmp/repro.sh").unlink()
    (workspace / "tmp").rmdir()
    (workspace / "README.md").write_text(
        "# Installer\n\n"
        "Managed updates reject destination symlinks and preserve local content.\n"
    )
    solution = workspace / "docs/solutions/preserve-managed-tree-identity.md"
    solution.write_text(
        "# Preserve managed-tree identity\n\n"
        "## Symptom\n\nA destination symlink redirected a managed update.\n\n"
        "## Root cause\n\nA pathname did not prove filesystem identity.\n\n"
        "## Fix\n\nValidate physical ancestors and reject symlinks before replacement.\n\n"
        "## Prevention\n\nCovered by `tests/installer-regression.sh`.\n"
    )
else:
    raise SystemExit(f"unsupported fake case: {case_id}")
output.write_text(json.dumps({
    "case_id": case_id,
    "decisions": decisions,
    "summary": "deterministic runner test",
}) + "\n")
print(json.dumps({"type": "thread.started"}))
print(json.dumps({"type": "turn.completed", "usage": {"input_tokens": 1, "output_tokens": 1}}))
PY
chmod +x "$fake_codex"
fake_sha="$(sha256sum "$fake_codex" | cut -d' ' -f1)"
fake_codex_target="$fake_codex"
fake_codex="$TEST_ROOT/codex-link"
ln -s "$fake_codex_target" "$fake_codex"

symlink_parent="$TEST_ROOT/evidence-parent"
mkdir -p -m 700 "$symlink_parent/physical"
ln -s "$symlink_parent/physical" "$symlink_parent/link"
mkdir -m 700 "$symlink_parent/physical/raw"
if symlink_output="$(AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
    --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 \
    --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
    --timeout-seconds 300 --output-root "$symlink_parent/link/raw" \
    --prepare-only 2>&1)"; then
  echo "Runner accepted an evidence root reached through a symlink" >&2
  exit 1
fi
grep -Eq 'unsafe component|symlink' <<< "$symlink_output"

# Exercise workspace-write grading for the wrap completion case, including the
# observable scratch deletion and documentation/knowledge writes.
wrap_raw="$TEST_ROOT/wrap-raw"
wrap_prepare="$TEST_ROOT/wrap-prepare.json"
AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.wrap-completion.positive --comparison-ref HEAD --runs 1 \
  --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
  --timeout-seconds 300 --output-root "$wrap_raw" \
  --summary-output "$TEST_ROOT/wrap-summary.json" --prepare-only > "$wrap_prepare"
wrap_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$wrap_prepare")"
AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.wrap-completion.positive --comparison-ref HEAD --runs 1 \
  --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
  --timeout-seconds 300 --require-current-pass \
  --expected-executor-sha256 "$fake_sha" --expected-subject-digest "$wrap_digest" \
  --output-root "$wrap_raw" \
  --summary-output "$TEST_ROOT/wrap-summary.json" >/dev/null
[ "$(stat -c '%a' "$wrap_raw")" = 700 ]

forged_state_summary="$TEST_ROOT/forged-state-summary.json"
cp -- "$TEST_ROOT/wrap-summary.json" "$forged_state_summary"
python3 - "$forged_state_summary" "$wrap_raw" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

summary_path = Path(sys.argv[1])
raw_root = Path(sys.argv[2])
value = json.loads(summary_path.read_text(encoding="utf-8"))
record = value["results"][0]
run_dir = raw_root / record["configuration"] / record["case_id"] / f"run-{record['run']}"
state_path = run_dir / "state-content.json"
state = json.loads(state_path.read_text(encoding="utf-8"))
path = next(name for name, content in state.items() if isinstance(content, str))
state[path] += "\nforged content not present in the retained fixture snapshot\n"
state_path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")
record["evidence"]["files"]["state-content.json"] = hashlib.sha256(
    state_path.read_bytes()
).hexdigest()
value.pop("summary_digest")
value["summary_digest"] = hashlib.sha256(
    (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
).hexdigest()
summary_path.write_text(json.dumps(value), encoding="utf-8")
PY
if bash "$RUNNER" --check-summary "$forged_state_summary" \
    --evidence-root "$wrap_raw" >/dev/null 2>&1; then
  echo "Runner accepted asserted state content that contradicted its fixture snapshot" >&2
  exit 1
fi

bound_raw="$TEST_ROOT/bound-raw"
bound_prepare="$TEST_ROOT/bound-prepare.json"
AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 \
  --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
  --timeout-seconds 300 --output-root "$bound_raw" --prepare-only > "$bound_prepare"
bound_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$bound_prepare")"
cp -p -- "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json" "$TEST_ROOT/auth.backup"
python3 - "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json" <<'PY'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
value = json.loads(path.read_text(encoding="utf-8"))
value["tokens"]["account_id"] = "substituted-account"
path.write_text(json.dumps(value) + "\n", encoding="utf-8")
PY
credential_marker="$TEST_ROOT/credential-substitution-executed"
if credential_output="$(AGENT_EVAL_EXECUTOR_MARKER="$credential_marker" \
    AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
    --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 \
    --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
    --timeout-seconds 300 --expected-executor-sha256 "$fake_sha" \
    --expected-subject-digest "$bound_digest" --output-root "$bound_raw" 2>&1)"; then
  echo "Runner accepted a substituted authentication principal" >&2
  exit 1
fi
grep -Eq 'subject digest|credential' <<< "$credential_output"
[ ! -e "$credential_marker" ] && [ ! -e "$bound_raw" ]
cp -p -- "$TEST_ROOT/auth.backup" "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json"
summary_marker="$TEST_ROOT/summary-destination-executed"
if summary_output="$(AGENT_EVAL_EXECUTOR_MARKER="$summary_marker" \
    AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
    --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 \
    --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
    --timeout-seconds 300 --expected-executor-sha256 "$fake_sha" \
    --expected-subject-digest "$bound_digest" --output-root "$bound_raw" \
    --summary-output "$TEST_ROOT/unreviewed-summary.json" 2>&1)"; then
  echo "Runner accepted a summary destination absent from the reviewed subject" >&2
  exit 1
fi
grep -Eq 'subject digest|summary' <<< "$summary_output"
[ ! -e "$summary_marker" ] && [ ! -e "$bound_raw" ] \
  && [ ! -e "$TEST_ROOT/unreviewed-summary.json" ]

bound_marker="$TEST_ROOT/bound-executed"
if bound_output="$(AGENT_EVAL_EXECUTOR_MARKER="$bound_marker" AGENT_EVAL_CODEX_BIN="$fake_codex" \
    bash "$RUNNER" --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 \
    --model test-model --jobs 2 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
    --timeout-seconds 300 --expected-executor-sha256 "$fake_sha" \
    --expected-subject-digest "$bound_digest" --output-root "$bound_raw" 2>&1)"; then
  echo "Runner accepted changed approved resource facts" >&2
  exit 1
fi
grep -q 'subject digest' <<< "$bound_output"
[ ! -e "$bound_marker" ] && [ ! -e "$bound_raw" ]

# Exercise the actual release gate from a clean, commit-backed candidate and
# prove a self-consistent lie about changed-path coverage is rejected.
release_repo="$TEST_ROOT/release-repo"
mkdir -p "$release_repo"
cp -a -- "$REPO_ROOT/.agents" "$REPO_ROOT/tests" "$release_repo/"
cp -p -- "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/CONTRIBUTING.md" "$release_repo/"
git -C "$release_repo" init -q
git -C "$release_repo" config user.name Eval-Test
git -C "$release_repo" config user.email eval@example.invalid
git -C "$release_repo" add .
git -C "$release_repo" commit -qm baseline
printf '\n' >> "$release_repo/.agents/skills/plan/SKILL.md"
git -C "$release_repo" add .agents/skills/plan/SKILL.md
git -C "$release_repo" commit -qm candidate
release_summary="$TEST_ROOT/release-summary.json"
release_raw="$TEST_ROOT/release-raw"
release_prepare="$TEST_ROOT/release-prepare.json"
if mismatch_output="$(AGENT_EVAL_CODEX_BIN="$fake_codex" \
    bash "$release_repo/tests/run-agent-evals.sh" --changed-from HEAD^ \
    --comparison-ref HEAD --runs 3 --model test-model --jobs 2 \
    --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
    --output-root "$TEST_ROOT/mismatch-raw" --prepare-only 2>&1)"; then
  echo "Runner accepted an inconsistent changed-from comparison" >&2
  exit 1
fi
grep -q 'comparison.*changed-from' <<< "$mismatch_output"
AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$release_repo/tests/run-agent-evals.sh" \
  --changed-from HEAD^ --runs 3 --model test-model --jobs 2 \
  --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
  --require-complete --output-root "$release_raw" \
  --summary-output "$release_summary" --prepare-only > "$release_prepare"
release_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$release_prepare")"
AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$release_repo/tests/run-agent-evals.sh" \
  --changed-from HEAD^ --runs 3 --model test-model --jobs 2 \
  --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
  --expected-executor-sha256 "$fake_sha" --expected-subject-digest "$release_digest" \
  --require-complete --require-current-pass --output-root "$release_raw" \
  --summary-output "$release_summary" >/dev/null
bash "$release_repo/tests/run-agent-evals.sh" --check-summary "$release_summary" \
  --evidence-root "$release_raw" --require-release-qualified >/dev/null

forged_summary="$TEST_ROOT/forged-selection.json"
cp -- "$release_summary" "$forged_summary"
python3 - "$forged_summary" <<'PY'
import hashlib
import json
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["subject"]["classifications"] = {}
subject = dict(value["subject"])
subject.pop("subject_digest")
value["subject"]["subject_digest"] = hashlib.sha256(
    (json.dumps(subject, sort_keys=True, separators=(",", ":")) + "\n").encode()
).hexdigest()
value["subject_digest"] = value["subject"]["subject_digest"]
value["classifications"] = {}
value.pop("summary_digest")
value["summary_digest"] = hashlib.sha256(
    (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
).hexdigest()
json.dump(value, open(path, "w", encoding="utf-8"))
PY
if bash "$release_repo/tests/run-agent-evals.sh" --check-summary "$forged_summary" \
  --evidence-root "$release_raw" --require-release-qualified >/dev/null 2>&1; then
  echo "Resealed summary hid a changed path from release selection" >&2
  exit 1
fi

forged_grade="$TEST_ROOT/forged-grade.json"
forged_raw="$release_raw"
cp -- "$release_summary" "$forged_grade"
python3 - "$forged_grade" "$forged_raw" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

summary_path = Path(sys.argv[1])
raw_root = Path(sys.argv[2])
value = json.loads(summary_path.read_text(encoding="utf-8"))
record = value["results"][0]
run_dir = raw_root / record["configuration"] / record["case_id"] / f"run-{record['run']}"
raw_result = json.loads((run_dir / "result.json").read_text(encoding="utf-8"))
decision = next(key for key, current in raw_result["decisions"].items() if current is not None)
raw_result["decisions"][decision] = None
(run_dir / "result.json").write_text(json.dumps(raw_result) + "\n", encoding="utf-8")
raw_grade = json.loads((run_dir / "grade.json").read_text(encoding="utf-8"))
raw_grade["result"] = raw_result
raw_grade["passed"] = True
for check in raw_grade["checks"]:
    check["passed"] = True
(run_dir / "grade.json").write_text(
    json.dumps(raw_grade, indent=2, sort_keys=True) + "\n", encoding="utf-8"
)
summary_record = dict(raw_grade)
summary_record["evidence"] = record.get("evidence", {})
if summary_record["evidence"]:
    for name in ("result.json", "grade.json"):
        summary_record["evidence"]["files"][name] = hashlib.sha256(
            (run_dir / name).read_bytes()
        ).hexdigest()
value["results"][0] = summary_record
value.pop("summary_digest")
value["summary_digest"] = hashlib.sha256(
    (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
).hexdigest()
summary_path.write_text(json.dumps(value), encoding="utf-8")
PY
if forged_output="$(bash "$release_repo/tests/run-agent-evals.sh" \
    --check-summary "$forged_grade" --evidence-root "$forged_raw" \
    --require-release-qualified 2>&1)"; then
  echo "Runner accepted a grade contradicting its raw result" >&2
  exit 1
fi
grep -Eq 'recomputed grade|raw grade|grade evidence' <<< "$forged_output"

# Make dirty-source qualification deterministic instead of depending on the
# developer or CI checkout state.
: > "$DIRTY_MARKER"
prepare="$TEST_ROOT/prepare.json"
summary="$TEST_ROOT/summary.json"
raw="$TEST_ROOT/raw"
AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative \
  --case v2.workflow-rigor.positive \
  --comparison-ref HEAD --runs 1 --model test-model \
  --jobs 2 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
  --timeout-seconds 300 --output-root "$raw" --summary-output "$summary" \
  --prepare-only > "$prepare"

python3 - "$prepare" "$fake_sha" <<'PY'
import json
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["source_worktree_clean"] is False
assert value["executor_sha256"] == sys.argv[2]
assert value["credential"]["mode"] == "chatgpt"
assert len(value["credential"]["principal_sha256"]) == 64
assert value["credential"]["access_token_expires_at"] == 4102444800
assert value["case_ids"] == [
    "v2.workflow-rigor.negative",
    "v2.workflow-rigor.positive",
]
assert len(value["subject_digest"]) == 64
assert value["planned_executions"] == 4
assert value["jobs"] == 2
assert value["rollout_planned_limit_sum"] == 65536
assert value["output_root"] == sys.argv[1].replace("prepare.json", "raw")
assert value["summary_output"] == sys.argv[1].replace("prepare.json", "summary.json")
PY

subject_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$prepare")"
runtime_home_log="$TEST_ROOT/runtime-home.log"
: > "$runtime_home_log"
if ! AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative \
  --case v2.workflow-rigor.positive \
  --comparison-ref HEAD --runs 1 --model test-model \
  --jobs 2 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
  --expected-executor-sha256 "$fake_sha" \
  --expected-subject-digest "$subject_digest" \
  --require-current-pass --output-root "$raw" --summary-output "$summary" >/dev/null; then
  find "$raw/current" -name grade.json -exec sed -n '1,220p' {} \; >&2
  exit 1
fi
[ "$(sort -u "$runtime_home_log" | wc -l)" -eq 1 ]

bash "$RUNNER" --check-summary "$summary" >/dev/null
if bash "$RUNNER" --check-summary "$summary" --require-release-qualified >/dev/null 2>&1; then
  echo "Dirty one-run summary was accepted as release-qualified" >&2
  exit 1
fi

resealed="$TEST_ROOT/resealed.json"
cp -- "$summary" "$resealed"
python3 - "$resealed" <<'PY'
import hashlib
import json
import sys
path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["results"][0]["input_digest"] = "0" * 64
value.pop("summary_digest")
encoded = (json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n").encode()
value["summary_digest"] = hashlib.sha256(encoded).hexdigest()
json.dump(value, open(path, "w", encoding="utf-8"))
PY
if bash "$RUNNER" --check-summary "$resealed" >/dev/null 2>&1; then
  echo "Resealed summary with a false input binding passed verification" >&2
  exit 1
fi

python3 - "$summary" <<'PY'
import json
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["current_pass"] is True
assert value["release_qualified"] is False
assert len(value["results"]) == 4
value["current_pass"] = False
json.dump(value, open(sys.argv[1], "w", encoding="utf-8"))
PY
if bash "$RUNNER" --check-summary "$summary" >/dev/null 2>&1; then
  echo "Tampered summary passed digest verification" >&2
  exit 1
fi

if AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative --comparison-ref HEAD \
  --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
  --timeout-seconds 300 --output-root "$TEST_ROOT/wrong-executor-raw" \
  --expected-executor-sha256 "$(printf '0%.0s' {1..64})" \
  --prepare-only >/dev/null 2>&1; then
  echo "Runner accepted the wrong executor digest" >&2
  exit 1
fi

PROMPT_BACKUP="$TEST_ROOT/prompt.backup"
cp -p -- "$MUTATED_PROMPT" "$PROMPT_BACKUP"
race_prepare="$TEST_ROOT/race-prepare.json"
race_raw="$TEST_ROOT/race"
AGENT_EVAL_MUTATE_PATH="$MUTATED_PROMPT" AGENT_EVAL_CODEX_BIN="$fake_codex" \
  bash "$RUNNER" \
  --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 --model test-model \
  --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
  --output-root "$race_raw" --prepare-only > "$race_prepare"
race_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$race_prepare")"
if AGENT_EVAL_MUTATE_PATH="$MUTATED_PROMPT" AGENT_EVAL_CODEX_BIN="$fake_codex" \
  bash "$RUNNER" --case v2.workflow-rigor.negative --comparison-ref HEAD \
  --runs 1 --model test-model --jobs 1 \
  --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
  --expected-executor-sha256 "$fake_sha" --expected-subject-digest "$race_digest" \
  --output-root "$race_raw" >/dev/null 2>&1; then
  echo "Runner accepted a source input changed during execution" >&2
  exit 1
fi
cp -p -- "$PROMPT_BACKUP" "$MUTATED_PROMPT"
PROMPT_BACKUP=""

timeout_raw="$TEST_ROOT/timeout-raw"
timeout_prepare="$TEST_ROOT/timeout-prepare.json"
timeout_summary="$TEST_ROOT/timeout-summary.json"
AGENT_EVAL_TIMEOUT_AFTER_OUTPUT=1 AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 --model test-model \
  --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 1 \
  --output-root "$timeout_raw" --summary-output "$timeout_summary" \
  --prepare-only > "$timeout_prepare"
timeout_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$timeout_prepare")"
AGENT_EVAL_TIMEOUT_AFTER_OUTPUT=1 AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 --model test-model \
  --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 1 \
  --expected-executor-sha256 "$fake_sha" --expected-subject-digest "$timeout_digest" \
  --output-root "$timeout_raw" --summary-output "$timeout_summary" >/dev/null
grep -q 'thread.started' "$timeout_raw/current/v2.workflow-rigor.negative/run-1/events.jsonl"
grep -q 'partial stderr' "$timeout_raw/current/v2.workflow-rigor.negative/run-1/executor.stderr"
python3 - "$timeout_summary" <<'PY'
import json
import sys
value = json.load(open(sys.argv[1], encoding="utf-8"))
assert value["current_pass"] is False
assert value["results"][0]["passed"] is False
PY

if budget_output="$(AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
    --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 --model test-model \
    --jobs 1 --rollout-planned-limit-sum 2047 --timeout-seconds 300 \
    --output-root "$TEST_ROOT/low-budget" --prepare-only 2>&1)"; then
  echo "Runner accepted an undersized aggregate rollout limit" >&2
  exit 1
fi
grep -q 'at least 2048.*2 planned executions' <<< "$budget_output"

mutation_raw="$TEST_ROOT/runtime-auth-mutation-raw"
mutation_prepare="$TEST_ROOT/runtime-auth-mutation-prepare.json"
AGENT_EVAL_MUTATE_RUNTIME_AUTH=1 AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
  --case v2.workflow-rigor.negative --case v2.workflow-rigor.positive \
  --comparison-ref HEAD --runs 1 --model test-model --jobs 2 \
  --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
  --output-root "$mutation_raw" --prepare-only > "$mutation_prepare"
mutation_digest="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["subject_digest"])' "$mutation_prepare")"
if mutation_output="$(AGENT_EVAL_MUTATE_RUNTIME_AUTH=1 \
    AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
    --case v2.workflow-rigor.negative --case v2.workflow-rigor.positive \
    --comparison-ref HEAD --runs 1 --model test-model --jobs 2 \
    --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" --timeout-seconds 300 \
    --expected-executor-sha256 "$fake_sha" --expected-subject-digest "$mutation_digest" \
    --output-root "$mutation_raw" 2>&1)"; then
  echo "Runner accepted mutated batch authentication state" >&2
  exit 1
fi
grep -q 'mutated.*authentication' <<< "$mutation_output"
[ ! -e "$mutation_raw/current/v2.workflow-rigor.positive" ]
[ ! -e "$mutation_raw/comparison/v2.workflow-rigor.positive" ]

cp -p -- "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json" "$TEST_ROOT/auth.expiry.backup"
python3 - "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json" <<'PY'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
value = json.loads(path.read_text(encoding="utf-8"))
value["tokens"]["access_token"] = "e30.eyJleHAiOjF9.x"
path.write_text(json.dumps(value) + "\n", encoding="utf-8")
PY
if expiry_output="$(AGENT_EVAL_CODEX_BIN="$fake_codex" bash "$RUNNER" \
    --case v2.workflow-rigor.negative --comparison-ref HEAD --runs 1 \
    --model test-model --jobs 1 --rollout-planned-limit-sum "$ROLLOUT_LIMIT_SUM" \
    --timeout-seconds 300 --output-root "$TEST_ROOT/expired-auth" --prepare-only 2>&1)"; then
  echo "Runner accepted a credential that cannot cover the planned execution window" >&2
  exit 1
fi
grep -Eq 'credential|access token|valid.*execution' <<< "$expiry_output"
cp -p -- "$TEST_ROOT/auth.expiry.backup" "$AGENTS_ECOSYSTEM_TEST_SOURCE_CODEX_HOME/auth.json"

echo "Agent evaluation profile tests passed"
