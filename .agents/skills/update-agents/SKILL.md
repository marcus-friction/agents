---
name: update-agents
description: Refresh upstream-managed agent skills, inactive documentation candidates, and discovery adapters while preserving project-owned files. Use when asked to update, sync, or pull the latest agent rules in one or more projects.
---

# Update Agent Ecosystem

Refresh the selected project from a known Agents Ecosystem distribution source. Keep
mechanical distribution updates separate from semantic adoption of project
documentation.

## Trigger and authority

A bare update or sync request defaults to the current stable release. Use the
mutable edge channel or a local development checkout only when the user asks for
it or the surrounding task already selected it.

For one project, the request authorizes only the installer's scoped changes to
managed assets, inactive templates, and discovery adapters.
Updates install no host packages or runtime dependencies. They do not authorize
edits to active project context, legacy cleanup, commits, pushes, or publication.
Bulk preparation and bulk publication have separate authority; see
`references/source-and-bulk.md`.

## Ownership contract

| Target | Update behavior |
|---|---|
| Files recorded in `.agents/.agents-ecosystem-managed-state-v2` | Update or retire only while their recorded content and mode remain unchanged; a verified v1 state migrates on success |
| `.agents/templates/` | Regenerate inactive upstream candidates; never activate them as project documents |
| Paths absent from managed state | Preserve as local extensions; a pre-state install may adopt historical paths with exact content and matching Git executable state, allowing the original umask. Unverified paths stay local; upstream collisions block the update |
| `.agents/project/`, root or nested project documents, `.agents/rules/`, and `.agent/` | Leave project-owned and untouched |
| Registered discovery paths | Accept only the expected adapter target; a different link, file, or directory blocks registration |

Use managed state or the installer's historical inventory, never names, banners,
or a match to current upstream content alone. A dirty
`.agents/` tree is not by itself a blocker: the managed state and complete
installer preflight decide whether existing work is safe to preserve.

## Source modes

| Mode | Required evidence | Installer argument |
|---|---|---|
| Stable (default) | Requested release's full 40-character lowercase commit SHA; clean detached physical checkout supplied or materialized at that commit | `--ref <full-commit-sha>` |
| Edge | Explicit choice of the moving branch; clean physical checkout and the resolved commit disclosed as non-reproducible | Omit `--ref` |
| Local development | Exact physical checkout selected for the task; disclose its branch, commit, and dirty state | Omit `--ref` |

Never relabel a tag or branch as an immutable release, silently move an existing
checkout, or turn a stable request into edge. If no suitable source checkout is
already available, read `references/source-and-bulk.md` completely and use its
temporary public-source bootstrap.

## Workflow

1. Resolve and enter the exact target project root. Record relevant pre-update
   status, managed state, local extensions, active and legacy context, target
   types, and adapter paths so existing work is not attributed to the update.
2. Select the source mode. For a supplied checkout, verify its physical source,
   resolved commit, required cleanliness, and regular `install.sh`. For remote
   bootstrap, verify the physical bootstrap and let it validate the materialized
   source before project preflight.
3. From the target root, run stable installation as:

   ```bash
   bash /path/to/agents/install.sh \
     --from-local /path/to/agents \
     --ref <full-commit-sha>
   ```

   For explicitly selected edge or local development, omit `--ref`:

   ```bash
   bash /path/to/agents/install.sh \
     --from-local /path/to/agents
   ```

   Let the installer perform the complete managed-tree, template, and adapter
   preflight. Do not reproduce or weaken that logic in ad hoc copy commands.
4. On any conflict or failure, stop. Do not overwrite, stash, relocate, delete,
   retry with a weaker mode, or classify a changed managed path as local. Report
   the exact blocker and preserve any recovery path printed by the installer.
5. On success, compare post-update status and diffs with the recorded baseline.
   Distinguish updated and retired managed files from preserved local
   extensions. If inactive templates changed, offer `onboard-project` as a
   separate semantic reconciliation only when the user wants active documents
   updated.

For more than one repository, read `references/source-and-bulk.md` and use the
bounded planner. Preparing review artifacts never authorizes its apply mode,
which creates commits, pushes branches, and may open pull requests.

## Report

Report:

- target, selected channel, source path, and resolved commit;
- changed and retired managed files, plus any v1-to-v2 state migration;
- preserved local extensions and unchanged active or legacy project context;
- adapter changes, inactive template candidates, and whether reconciliation is
  still pending;
- conflicts, incomplete effects, and retained recovery paths.

Do not describe a retired managed file as a local extension or claim the project
is fully reconciled merely because its managed distribution is current.
