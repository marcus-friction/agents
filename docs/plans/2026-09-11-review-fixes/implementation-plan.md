# Repository review corrections

Accepted scope: resolve findings 1–15 from the full repository review. Preserve
the TomFit v0.2.0 reference, Laravel/Nuxt stack, and pending user changes. No
publication, installed-user migration, dependency installation, or Git commits.

Evidence: README.md, CONTRIBUTING.md, AGENTS.md, review/change-rigor.md,
scripts/install-user-snapshot.sh, scripts/sync-managed-tree.sh,
scripts/register-skills.sh, scripts/install-into-repos.sh, and the evaluation
runner and tests. No docs/solutions directory or active architecture document.

Implementation is ordinary repository work; the resulting code controls
sensitive filesystem boundaries and therefore receives independent security
review. Tests use disposable directories and fake external executors/remotes.

1. Add failing behavioral regressions for real snapshot payloads, edge ancestry,
   protected managed-state paths, prior install formats, unsafe parents, registry
   containment, and concurrent adapter registration.
2. Correct snapshot acquisition and updates. Accept only the known root Cursor
   discovery link, remove it before physical snapshot validation, and prove edge
   ancestry. Recognize clean prior canonical Git checkouts, with revalidation
   before replacement; leave ambiguous or dirty destinations intact.
3. Add explicit adoption of known pre-state project payloads using a committed
   historical inventory. Exact prior content and Git executable state may be
   adopted with the original umask; record actual modes. Edited and unknown
   paths survive as local extensions; current upstream collisions block.
   Protected roots cannot be claimed by state.
4. Reject filesystem ancestry writable by other accounts at private destination
   boundaries, allowing trusted system-owned sticky temporary roots with
   exclusive child creation or verified caller-owned existing children. Publish discovery links with
   no-follow semantics. Keep the documented same-user hostile mutation exclusion.
5. Validate all evaluation IDs and paths; reject symlink ancestors before reads.
   Isolate the test suite's source-mutation scenarios in a disposable checkout.
6. Correct direct-install versus plugin names, remove the nested Tailwind plugin
   metadata, align R2 and Laravel injection guidance, and fix bulk examples.
7. Run targeted tests and bash tests/run.sh; perform independent review, resolve
   retained defects, update the tracker and report limitations.

Acceptance: each prior failure has a regression or documented prose validation;
all applicable deterministic checks pass; protected/local files survive updates;
valid fresh and legacy installation paths work; no executor can read outside
approved inputs or write outside evidence; namespaces match each install route.

Failure/recovery: fail before mutation on ambiguous legacy ownership, unsafe
paths, changed inputs, or divergent edge history. Reuse snapshot rollback and
identity checks. No real installed user data is exercised during verification.
No new dependencies. Human prose and plugin metadata are declarative exclusions
from code coverage; no measured coverage percentage is claimed.

Plan review: hold scope. Strategy, architecture/data, security/operations, and
testing are applicable; product UI/design and application performance are not.
Independent challenge must complete before the affected implementation closes.

Independent challenge incorporated: legacy Git content must match canonical
fetched tree entries; ignored extras and hidden worktree edits block adoption.
Retain the entire old Git checkout as recovery so local refs/index/stashes are
never discarded. Record full prior commit, path, hash and mode in the project
inventory; exclude protected namespaces. Check every existing ancestor with
GNU/BSD stat; exclusively create or verify owned children beneath sticky temporary roots.
Direct adapters keep bare declared names; only the enclosing plugin adds ma:.
These refinements close the plan findings without expanding scope.
