# Detailed Document Reconciliation

Use this reference only after the fast-path preflight in `../SKILL.md` finds a
failed predicate, an R2 trigger beyond the bounded already-supplied
component-applicability case, or any R3 trigger. The always-on boundaries in the
parent skill remain authoritative.

## Phase 0: Inventory and Freeze the Inputs

Before drafting:

1. Resolve the repository root and inspect Git status, including untracked files.
   First record staged, unstaged, and untracked state using metadata-only status,
   name-status, and diff-stat views. Classify environment, credential, key, and
   other potentially sensitive paths before reading any content diff. Inspect
   staged or unstaged content only for active documentation and vetted evidence
   anchors; never display or ingest content diffs for sensitive paths. If the
   project does not use Git, record that fact and rely on hashes and file metadata
   for change detection instead of assuming a clean state.
2. Discover the active documents listed above, nested `AGENTS.md` files, provider
   instruction files, generated-file notices, and legacy `.agents/rules/` or
   `.agent/` content, plus any earlier preservation ledger below
   `.agents/project/onboarding/`. Also inventory project-authored module READMEs,
   ADRs, and relevant Markdown below `docs/`; exclude vendored and generated
   trees, and bring any material cross-document meaning into the evidence model.
3. For each discovered path, record whether it is missing, a regular file, or a
   symlink; whether it is tracked, ignored, untracked, staged, or unstaged; its
   link count; and a content hash for the exact version analyzed. Treat a regular
   file with more than one link as hardlinked. For a symlink, separately record
   its raw link text and link metadata without treating the target hash as proof
   that the link itself is unchanged.
4. Record the scope of nested instructions. More specific `AGENTS.md` files may
   intentionally differ from root guidance.
5. Hash only the targets, parents, and direct evidence anchors that support a
   proposed changed claim. Record other repository evidence without making an
   unrelated change an apply-time blocker.
6. If a generated file or external symlink target is involved, classify the
   change R3 and do not propose a direct edit until its source is identified.

Uncommitted documentation does not prevent read-only analysis, but it blocks the
apply phase unless the user deliberately approves inclusion of the named file at
the recorded hash. Ordinary approval of the later patch is not enough to imply
that consent. Never stash, discard, or normalize uncommitted work automatically.

## Phase 1: Build an Evidence Model

Inspect the actual repository before accepting template assumptions. Relevant
anchors commonly include:

- package and dependency manifests plus lockfiles (for example `pyproject.toml`,
  `requirements*.txt`, `uv.lock`, `poetry.lock`, `package.json`, or Gradle files);
- build files and runtime version files;
- application entry points and key source directories, including ASGI/WSGI
  entry points when relevant;
- test configuration and executable package/build tasks;
- CI workflows, deployment configuration, containers, and infrastructure code;
- example environment files and configuration schemas;
- database migrations, API schemas, authentication configuration, and service
  boundaries;
- local startup scripts and documented operational commands.

Use `rg --files --hidden` to discover anchors so hidden CI and example-config
files are included. Explicitly exclude `.git/`, dependencies, build outputs,
caches, and generated artifacts. Prefer manifests and executable configuration
over filenames or conventions. Verify important commands with safe, non-mutating
checks when practical. Hash targets, parents, and the direct evidence anchors
that support proposed changed claims.

For every architecture statement, label it as one of:

- **Observed current state** — supported by a cited repository path.
- **Declared intent** — stated in existing project documentation or confirmed
  by the user, but not necessarily implemented.
- **Unknown or conflicting** — insufficient or contradictory evidence.

Executable configuration is evidence for current behavior; it does not erase
documented product intent or planned architecture.

### Build the Architecture Applicability Matrix

Treat `.agents/templates/ARCHITECTURE.md` as the preferred distribution target for new
capabilities, not as proof that every component exists or must be introduced.
Classify each target component:

- **Adopted** — required by approved scope and observed or explicitly intended;
- **Optional** — preferred if the capability becomes necessary, but not active;
- **Not applicable** — outside the project's approved scope;
- **Unresolved** — missing a decision; do not invent or implement it.

Cite repository evidence or owner confirmation for each status. Preserve an
established alternative architecture unless its replacement is explicitly
approved. Rules attached to an **Adopted** component may be proposed for active
guidance; **Optional** and **Unresolved** components are not implementation
approval.

Deployment is **Unresolved / TBD** by default. Do not infer a provider,
environment topology, release trigger, or delivery pipeline from the target
architecture. If the repository already contains deployment evidence, classify
it normally as observed current state or declared intent; contradictory sources
remain a deferred conflict. An unresolved deployment decision does not block a
local-only milestone.

For each affected trust or data boundary, record exposure, data impact,
privilege, reversibility or availability, control owner, and evidence. Mixed
public/private or disposable/material flows receive separate rows. Missing or
contradictory facts remain unresolved rather than becoming one project-wide
assurance label.

## Phase 2: Read Candidate and Legacy Context

After the project inventory, inspect:

- `.agents/templates/AGENTS.md`
- `.agents/templates/README.md`
- `.agents/templates/CONTRIBUTING.md`
- `.agents/templates/ARCHITECTURE.md`
- `.agents/templates/DESIGN.md` when a user interface exists
- relevant candidates below `.agents/templates/adapters/`
- text instruction and documentation candidates retained in `.agents/rules/`
  and `.agent/`

If a candidate is missing, continue using the project's native structure. Do not
download or invent a replacement silently. Treat examples and placeholders as
prompts to investigate, never as project facts. Inventory other legacy entries by
metadata only; skip secret, generated, cache, log, and binary content.

The architecture candidate carries the component-level target and boundary
policies. Give its backend, frontend, data, search, identity, caching,
background-work, local-runtime, observability, and deployment meanings explicit
ledger dispositions. Keep interaction states, tokens, component contracts,
accessibility, and motion in the `DESIGN.md` candidate rather than duplicating
them in architecture.

## Phase 3: Create the Preservation Ledger

Create a draft ledger outside active project files. Account for every substantive
item from both existing material and incoming candidates. Grouping a cohesive
paragraph or rule is fine; do not collapse unrelated meanings into one row. A
candidate component may share one `inapplicable` row when evidence clearly
excludes it and the row retains the architecture candidate's source hash.

Use this shape:

| ID | Origin and source anchor/hash | Meaning | Evidence | Proposed target | Disposition | Approval |
|---|---|---|---|---|---|---|

Allowed dispositions for existing material:

- `unchanged`
- `merged-equivalent`
- `moved-verbatim`
- `clarified`
- `deferred-conflict`
- `superseded` — requires specific user approval

Allowed dispositions for incoming material:

- `already-covered`
- `import`
- `adapt`
- `inapplicable`
- `deferred-conflict`

An incoming item marked `inapplicable` remains in the upstream candidate but is
not added to the project. It never authorizes removal of existing content.

Apply this precedence when proposing dispositions:

1. Explicit owner decisions and established product intent.
2. Existing project-specific rules, especially stricter safety constraints.
3. Executable evidence for current operational facts.
4. Applicable incoming safety and quality guidance that fills a real gap.

Surface uncertainty instead of using precedence to conceal a conflict.

## Phase 4: Draft a Semantic Merge

Draft changes in a temporary location or in the response, not in active files.
Preserve each document's useful native structure and make the smallest change
that represents the approved meaning.

For a documentation-poor repository, normally propose a minimal `AGENTS.md` and
an evidence-backed `ARCHITECTURE.md`. Propose `README.md` and `CONTRIBUTING.md`
only when repository evidence and project needs justify them. Never create
`DESIGN.md` for a backend-only project.

### `README.md`

Keep its audience and public purpose. Preserve badges, links, installation and
usage details, examples, roadmap, and license information. Enrich missing product
or operational context without forcing the template's heading structure.

### `AGENTS.md` and nested instructions

Keep all local rules by default and preserve stricter constraints. Add only
evidence-backed guardrails for components marked **Adopted**. Do not activate
rules for **Optional**, **Not applicable**, or **Unresolved** components. Respect
nested scope rather than flattening every rule into the root file.

### `ARCHITECTURE.md`

If present, patch it minimally. If absent, propose a new file. Preserve the
opinionated target component map while recording project-specific applicability.
Separate observed architecture from intended changes and cite repository paths
for key claims. Keep deployment **Unresolved / TBD** unless executable evidence
or an explicit owner decision establishes it.

### `DESIGN.md`

Only propose it when the repository has a user interface or established design
assets. Derive tokens and patterns from actual styles, components, fonts, and
configuration. Distinguish current design decisions from recommendations.

### `CONTRIBUTING.md`

Preserve the real contribution model. Verify branch names, package-manager
commands, CI checks, deployment status, and review requirements; never import
assumed providers, environments, ports, or commands. If deployment remains
unresolved, say so instead of drafting a delivery workflow.

### Provider and legacy files

Keep provider-specific integration isolated from canonical project meaning.
Never append a router candidate to an existing provider file automatically.
Retain all legacy files until their ledger rows are reconciled; cleanup is a
separate, explicitly approved action.

## Approval Routing

For **R1 and R2**, present the semantic summary, relevant ledger, and exact
unified diff together for **one combined approval**. R1 may keep its concise
inventory in the proposal; R2 keeps a target-scoped ledger. Neither route needs
a redundant preliminary approval.

For **R3**, retain both gates below, a durable complete relevant ledger, and
strict revalidation. Dirty targets, symlinks, conflicts, deletion, moves,
supersession, weakened constraints, security or permission boundaries, and
relevant concurrent changes always use R3.

For **R0**, report evidence and make zero writes: do not create a ledger, mutate
tasks, ask for a patch approval, or autofix anything.

### R3 Gate 1: Merge Plan

Present a concise plan containing:

- files proposed for creation or modification;
- a summary of additions, moves, clarifications, and any proposed supersessions;
- all conflicts and unknowns requiring owner decisions;
- the preservation ledger, or a readable link to its draft;
- files deliberately left unchanged and why.

Ask the user to approve or revise this file-level semantic plan. Do not generate
active-file changes merely because the original request said to reconcile
automatically.

Before calling the proposed ledger durable, use `git check-ignore` when Git is
available. If `.agents/project/onboarding/preservation-ledger.md` is ignored,
include an explicit `.gitignore` exception in the plan or propose another tracked
project-owned location and ask the user to choose.

### R3 Gate 2: Exact Patch

After Gate 1 approval, prepare and show the exact unified diff, including the
durable R3 ledger proposed at:

`.agents/project/onboarding/preservation-ledger.md`

If that ledger already exists, preserve its decision history. Append a clearly
identified reconciliation run or minimally resolve open rows with an audit note;
never replace prior approved decisions wholesale.

Ask for approval of that exact patch. Highlight every deletion, move, weakening
of a constraint, or `superseded` ledger row. No active project file may change
before this approval.

## Phase 5: Apply Safely

Immediately before editing an approved R1, R2, or R3 patch:

1. Revalidate every recorded attribute for each target, its existing parents,
   and direct evidence anchor supporting a changed claim: hashes, Git state,
   file type and metadata, plus raw symlink text where applicable.
2. Abort and regenerate if a relevant value changed. Preserve unrelated work
   and continue when it cannot affect the patch or its claims.
3. Confirm every target is still a single-link regular file or an approved new
   path, never a symlink. A hardlinked target requires an inventory of its aliases
   and explicit approval of that shared-file effect before any write. For a new
   path, check every existing parent component and abort if a component is a
   symlink or a non-directory collision.
4. Apply only the approved hunks using minimal patches.
5. For R3, write the approved preservation ledger under
   `.agents/project/onboarding/`. Persist an R2 ledger when the project needs an
   audit record; do not create durable state solely for R1 ceremony.

Do not delete legacy context in the same operation. Once every legacy item has a
non-conflicting approved disposition, offer cleanup as a separate exact patch.

## Phase 6: Validate the Result

- Review the final diff against the approved patch and ledger.
- Confirm every original substantive item has a disposition.
- Confirm every imported claim has evidence or explicit owner confirmation.
- Confirm every target architecture component has an applicability status and
  only **Adopted** components activated implementation rules.
- Check that commands, internal links, headings, and referenced paths are valid.
- Check for accidental secrets, contradictory active rules, and broken nested
  instruction scopes.
- Run relevant documentation checks and `git diff --check` when available.
- Perform a second read-only reconciliation pass; it should find no new or
  unledgered changes. Deferred conflicts must recur unchanged until resolved.
- Inspect relevant `.agents/skills/` descriptions for assumptions that contradict
  the verified stack, but do not refactor unrelated skills during onboarding.

Report unresolved conflicts plainly. An explicitly recorded unresolved decision
may remain when it does not block the agreed milestone; a required conflict may
not. Do not claim successful onboarding until the approved documents are
applied, validation passes, and no required ledger rows remain unresolved.

## Completion Report

State:

1. Which documents were created, minimally changed, or left untouched.
2. Where the preservation ledger was saved.
3. Which facts were observed versus owner-confirmed intent.
4. Any deferred conflicts, legacy context, or follow-up decisions.
5. The component applicability matrix, including deployment status.
6. The validation performed and whether a second pass was idempotent.

Then invite the user to review and commit; never commit automatically.
