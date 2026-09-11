#!/usr/bin/env bash

set -euo pipefail
umask 077

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/agents-ecosystem-skill-effects.XXXXXX")"
OWNERSHIP_MARKER="$TEST_ROOT/.agents-ecosystem-test-owned"
touch "$OWNERSHIP_MARKER"

cleanup() {
  if [[ -d "$TEST_ROOT" && ! -L "$TEST_ROOT" && -f "$OWNERSHIP_MARKER" ]]; then
    rm -rf -- "$TEST_ROOT"
  else
    echo "Refusing to remove unverified test directory: $TEST_ROOT" >&2
  fi
}
trap cleanup EXIT

python3 - "$REPO_ROOT" "$TEST_ROOT" <<'PY'
import hashlib
import json
import re
import shlex
import sys
from pathlib import Path

repo = Path(sys.argv[1])
test_root = Path(sys.argv[2])

sources = {
    "end2end": repo / ".agents/skills/end2end/SKILL.md",
    "debugging": repo / ".agents/skills/systematic-debugging/SKILL.md",
    "contribute": repo / ".agents/skills/contribute-back/SKILL.md",
    "playwright": repo / ".agents/skills/playwright/SKILL.md",
    "startup": repo / ".agents/skills/build-start-scripts/SKILL.md",
    "tailwind": repo / ".agents/skills/tailwind-v4-shadcn/SKILL.md",
}
contribute_sources = [
    repo / ".agents/skills/contribute-back/SKILL.md",
    repo / ".agents/skills/contribute-back/references/publication-batch.md",
]
tailwind_sources = [
    repo / ".agents/skills/tailwind-v4-shadcn/SKILL.md",
    repo / ".agents/skills/tailwind-v4-shadcn/README.md",
    repo / ".agents/skills/tailwind-v4-shadcn/commands/setup.md",
    repo / ".agents/skills/tailwind-v4-shadcn/rules/tailwind-v4-shadcn.md",
    repo / ".agents/skills/tailwind-v4-shadcn/references/common-gotchas.md",
    repo / ".agents/skills/tailwind-v4-shadcn/references/dark-mode.md",
]
text = {name: path.read_text(encoding="utf-8") for name, path in sources.items()}
text["contribute"] = "\n".join(
    path.read_text(encoding="utf-8") for path in contribute_sources
)
text["tailwind"] = "\n".join(path.read_text(encoding="utf-8") for path in tailwind_sources)

requirements = {
    "end2end": [
        (r"scope already supplied", "derive rather than re-ask supplied scope"),
        (r"test-only.*test-and-fix", "distinguish testing from fixing"),
        (r"fixture.*browser.*credential.*cleanup.*shared-state", "classify every test effect"),
        (r"testing alone.*not authorize.*production", "testing does not imply production mutation"),
        (r"chat.*default", "report in chat by default"),
        (r"durable.*(only|when).*(requested|handoff)", "persist reports only when justified"),
    ],
    "debugging": [
        (r"diagnosis-only.*diagnose-and-fix", "derive debugging intent"),
        (r"existing or redacted evidence", "prefer safe existing evidence"),
        (r"instrumentation.*mutation authority", "gate diagnostic instrumentation"),
        (r"diagnosis-only.*report.*stop", "stop without a fix for diagnosis-only work"),
        (r"non-mutating.*(test|evidence)|test.*non-mutating", "test hypotheses without implied mutation"),
    ],
    "contribute": [
        (r"local and proposal-only", "keep discovery local"),
        (r"destination.*visibility.*exact physical files", "identify the publication boundary"),
        (r"destination owner/repository.*base ref", "bind publication to the approved base ref"),
        (r"authenticated.*identity", "bind publication to the authenticated identity"),
        (r"title.*full (pull-request|PR) body", "approve exact publication copy"),
        (r"one (unchanged )?publication batch", "approve publication once as a batch"),
        (r"revalidate.*(paths|files).*(hashes|content)", "invalidate approval when files change"),
        (r"regular.*not (?:a )?symlink", "reject special publication sources"),
        (r"verified.*snapshot|snapshot.*verif", "publish immutable verified bytes"),
        (r"exact.*git add", "stage only approved files"),
        (r"nested.*README\.md", "allow upstream-managed nested skill documentation"),
        (r"\.agents/project/.*\.agents/templates/", "exclude project-owned and staged candidates"),
        (r"(?:presence|category).*relative path.*(?:redact|never reproduce)", "report sensitive findings without values"),
        (r"each\s+(?:selected\s+)?file.*source.*license\s+or\s+permission.*redistribut", "bind redistribution authority per selected file"),
        (r"unresolved.*(?:exclude|stop)|(?:exclude|stop).*unresolved", "fail closed on unresolved redistribution authority"),
    ],
    "playwright": [
        (r"accessible semantic locators", "prefer user-facing locators"),
        (r"existing stable test IDs", "accept repository-evidenced test IDs"),
        (r"do not add.*test IDs?.*solely", "do not mutate production markup just for a test"),
        (r"proven\s+disposable.*test-owned", "bound fixture cleanup"),
    ],
    "startup": [
        (r"normal startup.*does not.*docker compose down", "do not tear down on ordinary start"),
        (r"explicit reset.*named.*disposable", "allow a bounded reset"),
        (r"reset.*exact (?:effect )?preview.*exact decision", "require a decision for the destructive reset preview"),
        (r"track.*current invocation", "record current-run ownership"),
        (r"pre-existing or shared", "preserve unowned services"),
        (r"STARTED_SERVICES=\(\).*cleanup\(\)", "initialize cleanup ownership state"),
    ],
    "tailwind": [
        (r"package manifest.*lockfile.*package manager", "inspect project dependency evidence"),
        (r"exact.*versions?.*purpose", "plan pinned dependencies and reasons"),
        (r"preview.*(generator|generation).*(removal|migration)", "preview material file effects"),
        (r"approved.*unchanged", "execute only the approved dependency/file batch"),
        (r"preserve.*compatible.*config", "do not delete valid existing configuration"),
        (r"supplied implementation scope.*no (?:second|redundant).*approval", "avoid gating ordinary in-scope edits"),
        (r"Next\.js.{0,120}(?:do not use|exclude|routes? away).{0,120}Vite|Vite-specific.{0,120}(?:do not use|exclude).{0,120}Next\.js", "route Next.js away from the Vite-only setup"),
    ],
}

failures = []
for skill, checks in requirements.items():
    for pattern, purpose in checks:
        if not re.search(pattern, text[skill], re.IGNORECASE | re.DOTALL):
            failures.append(f"{skill}: missing {purpose}")

forbidden = {
    "end2end": [
        (r"before doing anything, ask the user", "redundant scope approval"),
        (r"independently fix(?:ing| issues| obstacles)", "test-only production mutation"),
        (r"revert your changes", "destructive rollback of unrelated work"),
    ],
    "debugging": [
        (r"before proposing fixes, add diagnostic instrumentation", "unauthorized instrumentation"),
        (r"env\s*\|\s*grep\s+IDENTITY", "diagnostic output that can disclose a secret"),
        (r"codesign\s+--sign", "state-changing signing presented as diagnosis"),
        (r"\$\{IDENTITY:-UNSET\}", "secret expansion disguised as a presence check"),
        (r"security\s+find-identity", "unredacted identity enumeration"),
    ],
    "contribute": [
        (r"automatically create a pull request", "automatic publication"),
        (r"TMP_DIR=/tmp/agents-contribute", "fixed shared temporary directory"),
        (r"(?m)^\s*rm -rf ", "unverified recursive cleanup"),
        (r"(?m)^\s*git add \.\s*$", "broad staging"),
        (r"report[\s\S]*including any content[\s\S]*credential", "sensitive proposal content disclosure"),
    ],
    "playwright": [
        (r"mandatory.*every interactive primitive", "mandatory production test IDs"),
        (r"clean up downstream", "unbounded cleanup"),
    ],
    "startup": [
        (r"first operational step.*docker compose up", "unconditional teardown before startup"),
        (r"containers from a previous run are never trustworthy", "blanket teardown rationale"),
    ],
    "tailwind": [
        (r"@latest", "floating generator version"),
        (r"(?m)^\s*rm\s+(?:-f\s+)?tailwind\.config", "unpreviewed config deletion"),
        (r"DON'T[^\n]*Use `?tailwind\.config", "blanket rejection of compatible config"),
        (r"no config file", "blanket no-config promise"),
        (r"Empty config, CSS-only theme", "blanket empty-config migration"),
        (r"Production Ready|Production Tested|production-ready|production-tested", "unsupported production-readiness claim"),
        (r"Tokens Used|~70%|100% reduction|~1 minute, 0 errors", "unsupported efficiency or zero-error claim"),
        (r"623 lines", "stale documentation line count"),
        (r"auto_invoke_threshold|confidence:\s*high|last_tested", "unsupported metadata claim"),
        (r"For Next\.js projects, use.{0,100}as well", "ambiguous Next.js co-routing into Vite setup"),
    ],
}
for skill, checks in forbidden.items():
    for pattern, purpose in checks:
        if re.search(pattern, text[skill], re.IGNORECASE):
            failures.append(f"{skill}: retains {purpose}")

# The CSS-first baseline must remain usable without the optional animation
# dependency. A mandatory example that imports it contradicts the effect gate.
tailwind_skill = sources["tailwind"].read_text(encoding="utf-8")
architecture = re.search(
    r"## 2\.[^\n]*\n(?P<section>.*?)(?=\n## 3\.)",
    tailwind_skill,
    re.IGNORECASE | re.DOTALL,
)
if architecture is None:
    failures.append("tailwind: missing CSS-first architecture section")
else:
    css_example = re.search(r"```css\s*(?P<body>.*?)```", architecture["section"], re.DOTALL)
    if css_example and '@import "tw-animate-css";' in css_example["body"]:
        failures.append("tailwind: mandatory CSS baseline imports optional tw-animate-css")

# Treat runnable package-manager examples as effects: every dependency and CLI
# token must be pinned. Prose may describe resolving a compatible exact version.
exact_package = re.compile(
    r"^(?:@[\w.-]+/[\w.-]+|[\w.-]+)@\d+\.\d+\.\d+"
    r"(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$"
)
options_with_value = {
    "--dir", "--filter", "--prefix", "--registry", "--workspace", "-C", "-w",
}


def unpinned_package_tokens(line):
    stripped = line.strip()
    if stripped.startswith("$ "):
        stripped = stripped[2:]
    if not re.match(r"^(?:npm\s+(?:install|i)\b|pnpm\s+(?:add|dlx)\b|npx\b)", stripped):
        return []
    try:
        tokens = shlex.split(stripped, comments=True)
    except ValueError:
        return ["<unparseable-command>"]
    if len(tokens) < 2:
        return []

    command = None
    args = []
    if tokens[0] == "npm" and tokens[1] in {"install", "i"}:
        command, args = "install", tokens[2:]
    elif tokens[0] == "pnpm" and tokens[1] == "add":
        command, args = "install", tokens[2:]
    elif tokens[0] == "pnpm" and tokens[1] == "dlx":
        command, args = "cli", tokens[2:]
    elif tokens[0] == "npx":
        command, args = "cli", tokens[1:]
    else:
        return []

    packages = []
    skip_value = False
    for token in args:
        if skip_value:
            skip_value = False
            continue
        if token in options_with_value:
            skip_value = True
            continue
        if token.startswith("-"):
            continue
        packages.append(token)
        if command == "cli":
            break
    return [package for package in packages if not exact_package.fullmatch(package)]


# Mutation examples prove a mixed pinned/floating command cannot satisfy the
# scanner merely because one token is exact.
parser_examples = [
    ("npm install tailwindcss@4.1.12 @tailwindcss/vite@4.1.12", []),
    ("npm install tailwindcss@4.1.12 @tailwindcss/vite", ["@tailwindcss/vite"]),
    ("pnpm dlx shadcn@2.3.0 add button", []),
    ("npx shadcn add button", ["shadcn"]),
]
for command, expected in parser_examples:
    actual = unpinned_package_tokens(command)
    if actual != expected:
        failures.append(
            f"tailwind: package-token parser returned {actual!r}, expected {expected!r} for {command!r}"
        )

for path in tailwind_sources:
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        unpinned = unpinned_package_tokens(line)
        if unpinned:
            failures.append(
                f"tailwind: unpinned runnable package token(s) {unpinned!r} "
                f"at {path.relative_to(repo)}:{number}"
            )

tailwind_readme = (repo / ".agents/skills/tailwind-v4-shadcn/README.md").read_text(
    encoding="utf-8"
)
tailwind_compact = (
    repo / ".agents/skills/tailwind-v4-shadcn/rules/tailwind-v4-shadcn.md"
).read_text(encoding="utf-8")
tailwind_gotchas = (
    repo / ".agents/skills/tailwind-v4-shadcn/references/common-gotchas.md"
).read_text(encoding="utf-8")

tailwind_consistency = {
    "compact rules": (
        tailwind_compact,
        (
            (r"PostCSS.{0,160}(?:supported|valid).{0,160}Vite", "scope the Vite plugin choice without rejecting PostCSS"),
            (r"@config.{0,160}(?:compatible|existing|legacy)", "retain the v4 compatibility path for JavaScript config"),
            (r"ordinary (?:custom )?CSS.{0,100}(?:supported|valid|works)", "allow ordinary custom CSS"),
            (r"@apply.{0,100}(?:supported|valid|works)", "describe @apply as supported"),
            (r"animation.{0,160}(?:only when|required|selected output)", "keep animation dependencies conditional"),
            (r"plugins?.{0,180}(?:@config|JavaScript config).{0,180}(?:supported|compatible|preserve)", "preserve compatible plugins from an explicitly loaded JavaScript config"),
        ),
    ),
    "common gotchas": (
        tailwind_gotchas,
        (
            (r"PostCSS.{0,160}(?:supported|valid).{0,160}Vite", "scope the Vite plugin choice without rejecting PostCSS"),
            (r"ordinary (?:custom )?CSS.{0,100}(?:supported|valid|works)", "allow ordinary custom CSS"),
            (r"multiple `?@layer base`?.{0,100}(?:valid|allowed)", "avoid treating repeated layer blocks as invalid CSS"),
        ),
    ),
}
for label, (source, checks) in tailwind_consistency.items():
    for pattern, purpose in checks:
        if re.search(pattern, source, re.IGNORECASE | re.DOTALL) is None:
            failures.append(f"tailwind {label}: missing {purpose}")

tailwind_false_claims = (
    (r"No PostCSS setup", "blanket rejection of the supported PostCSS integration"),
    (r"@apply.{0,240}Deprecated in v4|Deprecated in v4.{0,240}@apply", "false @apply deprecation claim"),
    (r"strips CSS outside `?@theme`?/`?@layer`?", "false rejection of ordinary custom CSS"),
    (r"postcss[^\n]*Old v3 way", "classification of PostCSS as v3-only"),
    (r"Keep only one base layer section", "false single-layer-block requirement"),
    (r"\|\s*`?tailwindcss-animate`?\s*\|\s*`?tw-animate-css`?\s*\|", "unconditional animation-package substitution"),
    (r"`?@layer base`?[^\n]*doesn.t wrap `?:root`?", "false prohibition on a valid layered root rule"),
    (r"❌.{0,160}plugins:\s*\[\s*require\(", "categorical rejection of compatible JavaScript-config plugins"),
    (r"\|\s*`?require\(['\"]@plugin['\"]\)`?\s*\|\s*`?@plugin\s+['\"]@plugin['\"];?`?\s*\|", "unconditional JavaScript-plugin-to-@plugin table substitution"),
)
for label, source in (("compact rules", tailwind_compact), ("common gotchas", tailwind_gotchas)):
    for pattern, purpose in tailwind_false_claims:
        if re.search(pattern, source, re.IGNORECASE | re.DOTALL) is not None:
            failures.append(f"tailwind {label}: retains {purpose}")

if "references/architecture.md" in tailwind_readme:
    failures.append("tailwind: README still routes agents to inaccurate out-of-scope architecture guidance")

for reference in re.findall(r"\[[^]]+\]\(([^)]+)\)", tailwind_readme):
    if reference.startswith(("https://", "http://", "#")):
        continue
    target = reference.split("#", 1)[0]
    if not (repo / ".agents/skills/tailwind-v4-shadcn" / target).is_file():
        failures.append(f"tailwind: README reference does not resolve: {reference}")

if failures:
    print("Skill effect contract failures:")
    for failure in failures:
        print(f"- {failure}")
    raise SystemExit(1)

# Exercise structured negative and authorized-positive attempts against local
# fake boundaries. Source evidence is required but does not label a decision;
# the generic gate derives its decision only from required and granted facts.
# Expected outcomes never drive the effect. This records effects
# without contacting GitHub, Docker, a browser, a registry, or a real fixture.
def paired(
    negative_id,
    positive_id,
    skill,
    boundary,
    operation,
    required,
    negative_grants,
    deny_evidence,
    allow_evidence,
    sensitive_input=False,
):
    required = sorted(required)
    negative_grants = sorted(negative_grants)
    return [
        {
            "id": negative_id,
            "positive_twin": positive_id,
            "skill": skill,
            "policy_id": f"{skill}:{boundary}:{operation}",
            "evidence_regex": deny_evidence,
            "boundary": boundary,
            "operation": operation,
            "required_authority": required,
            "granted_authority": negative_grants,
            "expected_disposition": "deny",
            "sensitive_input": sensitive_input,
        },
        {
            "id": positive_id,
            "positive_twin": negative_id,
            "skill": skill,
            "policy_id": f"{skill}:{boundary}:{operation}",
            "evidence_regex": allow_evidence,
            "boundary": boundary,
            "operation": operation,
            "required_authority": required,
            "granted_authority": required,
            "expected_disposition": "allow",
            "sensitive_input": sensitive_input,
        },
    ]


cases = []
cases += paired(
    "e2e-test-only-fix", "e2e-test-and-fix", "end2end", "workspace", "production-fix",
    ["test-and-fix"], [],
    r"Testing alone does not authorize production-code mutation",
    r"Test-and-fix.*?authorizes only bounded\s+local edits",
)
cases += paired(
    "e2e-shared-browser", "e2e-disposable-browser", "end2end", "browser", "browser-write",
    ["disposable-browser"], [],
    r"Do not use real credentials,\s*create shared records, alter production, or perform destructive cleanup unless\s*that exact effect has been approved",
    r"A supplied, safe scope needs no redundant approval gate",
)
cases += paired(
    "e2e-real-credential", "e2e-sentinel-credential", "end2end", "credential", "credential-use",
    ["disposable-environment", "synthetic-credential"], ["disposable-environment"],
    r"Do not use real credentials",
    r"synthetic credentials.*?without a separate approval",
)
cases += paired(
    "e2e-shared-fixture-cleanup", "e2e-test-owned-fixture-cleanup", "end2end", "fixture", "fixture-delete",
    ["disposable", "test-owned"], ["disposable"],
    r"Preserve pre-existing\s*and shared data",
    r"Seed and remove only proven disposable test-owned data",
)
cases += paired(
    "e2e-unapproved-shared-state", "e2e-approved-shared-state", "end2end", "shared-state", "shared-write",
    ["exact-shared-state-approval"], [],
    r"create shared records.*?unless\s*that exact effect has been approved",
    r"unless\s*that exact effect has been approved",
)
cases += paired(
    "debug-diagnosis-fix", "debug-diagnose-and-fix", "debugging", "workspace", "production-fix",
    ["diagnose-and-fix"], [],
    r"diagnosis-only.*?Do not enter Phase 4",
    r"request to fix includes bounded implementation authority",
)
cases += paired(
    "debug-diagnosis-instrument", "debug-authorized-instrument", "debugging", "workspace", "instrumentation-write",
    ["mutation-authority"], [],
    r"permission to diagnose or run a test does not\s*grant it",
    r"Add diagnostic instrumentation only when\s*the request supplies mutation authority",
)
cases += paired(
    "contribute-incomplete-batch", "contribute-exact-batch", "contribute", "github", "publish-pull-request",
    [
        "authenticated-identity", "base-ref", "credential", "destination",
        "exact-files", "full-body", "per-file-redistribution-authority",
        "recovery", "title", "visibility",
    ],
    ["credential", "destination", "exact-files", "recovery", "title", "visibility"],
    r"Do not\s*fork, create a branch, push, or open a pull request before approval",
    r"Publish only the approved batch",
)
cases += paired(
    "contribute-changed-hash", "contribute-revalidated-hash", "contribute", "github", "publish-pull-request",
    ["hash-unchanged", "verified-snapshot"], ["verified-snapshot"],
    r"changed.*?hash\s*invalidates the batch",
    r"materialize a verified snapshot",
)
contribution_redistribution_cases = paired(
    "contribute-unresolved-redistribution", "contribute-authorized-redistribution",
    "contribute", "github", "select-for-publication",
    ["file-source-identified", "license-or-permission-evidence", "redistribution-authorized"],
    ["file-source-identified"],
    r"If\s+any\s+file\s+remains\s+unresolved,\s+exclude\s+it\s+from\s+the\s+batch\s+or\s+stop",
    r"Only\s+files\s+with\s+affirmative\s+redistribution\s+authority\s+may\s+enter\s+the\s+batch",
)
contribution_redistribution_cases[0]["target_path"] = ".agents/skills/example/SKILL.md"
contribution_redistribution_cases[1]["target_path"] = ".agents/skills/example/SKILL.md"
cases += contribution_redistribution_cases
contribution_path_cases = paired(
    "contribute-project-document", "contribute-nested-skill-readme", "contribute", "github", "select-file",
    ["upstream-managed-skill-file"], [],
    r"Exclude project-owned\s+`\.agents/project/`[^.]*staged `\.agents/templates/`",
    r"Include nested(?: skill)? support files such as\s+`\.agents/skills/[^`]+/README\.md`",
)
contribution_path_cases[0]["target_path"] = ".agents/project/README.md"
contribution_path_cases[1]["target_path"] = ".agents/skills/example/README.md"
cases += contribution_path_cases
cases += paired(
    "contribute-raw-sensitive-proposal", "contribute-redacted-sensitive-proposal",
    "contribute", "github", "report-sensitive-candidate",
    ["redacted-metadata-only"], [],
    r"Never reproduce a\s+suspected sensitive value",
    r"report only its presence,\s*category, and relative path",
    sensitive_input=True,
)
cases += paired(
    "playwright-structural-locator", "playwright-semantic-locator", "playwright", "browser", "select-element",
    ["repository-supported-locator"], [],
    r"Structural CSS.*?last resort",
    r"Prefer accessible semantic locators",
)
cases += paired(
    "playwright-new-test-id-mutation", "playwright-existing-test-id", "playwright", "browser", "select-by-test-id",
    ["existing-stable-test-id"], [],
    r"Do not add test IDs.*?solely",
    r"Existing stable test IDs (?:are )?(?:also )?valid",
)
cases += paired(
    "playwright-shared-cleanup", "playwright-test-owned-cleanup", "playwright", "browser", "delete-record",
    ["disposable", "test-owned"], ["disposable"],
    r"preserve pre-existing or shared records",
    r"Clean up only a proven\s+disposable, test-owned scope",
)
cases += paired(
    "startup-normal-down", "startup-explicit-reset", "startup", "docker", "compose-reset",
    ["exact-effect-approval", "explicit-reset", "named-disposable-project"],
    ["named-disposable-project"],
    r"Normal startup does not run `docker compose down`",
    r"After showing the exact effect preview.*?obtain one exact decision.*?Only then",
)
cases += paired(
    "startup-pre-existing-cleanup", "startup-current-run-cleanup", "startup", "docker", "stop-service",
    ["started-current-invocation"], [],
    r"Preserve pre-existing or shared processes",
    r"Stop only services recorded as transitioned by this invocation",
)
cases += paired(
    "tailwind-floating-install", "tailwind-exact-install", "tailwind", "registry", "install-dependency",
    ["exact-version", "purpose-approved"], ["purpose-approved"],
    r"Do not use floating ranges, implicit tags, or an unpinned\s*generator",
    r"resolve project-compatible exact versions and state the purpose",
)
cases += paired(
    "tailwind-unused-animation", "tailwind-required-animation", "tailwind", "registry", "install-animation-dependency",
    ["exact-version", "purpose-approved", "selected-output-requires-animation"],
    ["exact-version", "purpose-approved"],
    r"If selected output does not import `tw-animate-css`, do not add its\s+import or package",
    r"Add the import and an exact compatible package only when selected output\s+requires it",
)
cases += paired(
    "tailwind-unpreviewed-generator", "tailwind-approved-generator", "tailwind", "workspace", "run-generator",
    ["effect-authorized", "exact-cli", "previewed"], ["exact-cli"],
    r"do\s*not experiment on the project",
    r"Execute\s+only the approved unchanged batch",
)
cases += paired(
    "tailwind-unpreviewed-removal", "tailwind-approved-migration", "tailwind", "workspace", "remove-config",
    ["exact-usage-check", "previewed", "removal-authorized", "replacement-or-unused-verified"],
    ["exact-usage-check", "replacement-or-unused-verified"],
    r"Preserve compatible\s*existing config",
    r"migrate or remove it only after an\s*exact usage\s+check, verified replacement or proof that it is unused, and approved preview",
)


def authorize(case):
    required = set(case["required_authority"])
    granted = set(case["granted_authority"])
    return required.issubset(granted)


def source_evidence_hash(case):
    match = re.search(
        case["evidence_regex"],
        text[case["skill"]],
        re.IGNORECASE | re.DOTALL,
    )
    if match is None:
        failures.append(f"{case['id']}: policy evidence did not match {case['skill']}")
        return None
    return hashlib.sha256(match.group(0).encode("utf-8")).hexdigest()

boundaries = test_root / "fake-boundaries"
for boundary in {case["boundary"] for case in cases}:
    path = boundaries / boundary
    path.mkdir(parents=True, exist_ok=True)
    (path / "pre-existing-sentinel").write_text(f"owned-before:{boundary}\n", encoding="utf-8")

sentinel_secret = hashlib.sha256(b"agents-ecosystem-skill-effect-sentinel-credential").hexdigest()
sentinel_secret_path = boundaries / "credential" / "sentinel-secret"
sentinel_secret_path.write_text(sentinel_secret, encoding="utf-8")
sentinel_secret_path.chmod(0o600)
github_sensitive_path = boundaries / "github" / "sensitive-candidate"
github_sensitive_path.write_text(f"token={sentinel_secret}\n", encoding="utf-8")
github_sensitive_path.chmod(0o600)

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

before = {
    boundary.name: digest(boundary / "pre-existing-sentinel")
    for boundary in boundaries.iterdir()
}
sentinel_secret_before = digest(sentinel_secret_path)
github_sensitive_before = digest(github_sensitive_path)
log_path = test_root / "attempted-effects.jsonl"
allowed_paths = []
with log_path.open("w", encoding="utf-8") as log:
    for case in cases:
        evidence_hash = source_evidence_hash(case)
        authority_allows = authorize(case)
        allowed = authority_allows and evidence_hash is not None
        record = {
            "case": case["id"],
            "positive_twin": case["positive_twin"],
            "policy": {
                "id": case["policy_id"],
                "source": case["skill"],
                "evidence_sha256": evidence_hash,
            },
            "attempted_effect": {
                "boundary": case["boundary"],
                "operation": case["operation"],
            },
            "authorization": {
                "required": case["required_authority"],
                "granted": case["granted_authority"],
            },
            "disposition": "allow" if allowed else "deny",
        }
        if allowed and case["boundary"] == "credential":
            record["credential_observation"] = (
                "present" if sentinel_secret_path.read_text(encoding="utf-8") else "missing"
            )
        if case["sensitive_input"]:
            candidate = github_sensitive_path.read_text(encoding="utf-8")
            record["sensitive_candidate_observation"] = (
                "credential-category-detected; value-redacted"
                if sentinel_secret in candidate
                else "no-sensitive-value-detected"
            )
        if "target_path" in case:
            record["attempted_effect"]["target_path"] = case["target_path"]
        log.write(json.dumps(record, sort_keys=True) + "\n")
        if allowed:
            effect = boundaries / case["boundary"] / f"{case['id']}.allowed"
            effect.write_text(json.dumps(record, sort_keys=True) + "\n", encoding="utf-8")
            allowed_paths.append(effect)

case_map = {case["id"]: case for case in cases}
for case in cases:
    twin = case["positive_twin"]
    if twin not in case_map:
        failures.append(f"{case['id']}: missing twin {twin}")
        continue
    twin_case = case_map[twin]
    if (
        twin_case["boundary"] != case["boundary"]
        or twin_case["operation"] != case["operation"]
        or twin_case["required_authority"] != case["required_authority"]
        or twin_case["expected_disposition"] == case["expected_disposition"]
    ):
        failures.append(f"{case['id']}: twin must invert authority for the same exact effect")

    evidence_hash = source_evidence_hash(case)
    authority_allows = authorize(case)
    allowed = authority_allows and evidence_hash is not None
    actual_disposition = "allow" if allowed else "deny"
    if actual_disposition != case["expected_disposition"]:
        failures.append(
            f"{case['id']}: gate returned {actual_disposition}, expected {case['expected_disposition']}"
        )
    unexpected = boundaries / case["boundary"] / f"{case['id']}.allowed"
    if unexpected.exists() != allowed:
        failures.append(f"{case['id']}: fake effect disposition did not match the gate")

    # Mutation-check the gate for every fixture: completing a negative grant set
    # must allow it, while removing a requirement from a positive must deny it.
    mutated = dict(case)
    if case["expected_disposition"] == "deny":
        mutated["granted_authority"] = list(case["required_authority"])
        if not authorize(mutated):
            failures.append(f"{case['id']}: completed authority did not enable its positive path")
    else:
        mutated["granted_authority"] = list(case["granted_authority"][:-1])
        if authorize(mutated):
            failures.append(f"{case['id']}: missing authority did not disable its effect")

after = {
    boundary.name: digest(boundary / "pre-existing-sentinel")
    for boundary in boundaries.iterdir()
}
if before != after:
    failures.append("a fake boundary modified pre-existing state")
if digest(sentinel_secret_path) != sentinel_secret_before:
    failures.append("the fake credential boundary modified its sentinel secret")
if digest(github_sensitive_path) != github_sensitive_before:
    failures.append("the fake GitHub proposal modified its sensitive candidate")

actual_allowed = sorted(boundaries.glob("*/*.allowed"))
if actual_allowed != sorted(allowed_paths):
    failures.append("an effect escaped its exact authorized fake target")

records = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
if len(records) != len(cases) or not all("attempted_effect" in record for record in records):
    failures.append("attempted effects were not recorded as structured events")

observable = log_path.read_text(encoding="utf-8")
for effect in allowed_paths:
    observable += effect.read_text(encoding="utf-8")
if sentinel_secret in observable:
    failures.append("the sentinel credential was disclosed in effect evidence")

if failures:
    print("Skill effect fixture failures:")
    for failure in failures:
        print(f"- {failure}")
    raise SystemExit(1)

print(
    f"Skill effect source-and-fixture contracts passed ({len(cases)} fake-effect cases; "
    "credential and GitHub-proposal sentinel non-disclosure verified)"
)
PY
