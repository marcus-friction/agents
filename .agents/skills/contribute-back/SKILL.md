---
name: contribute-back
description: Compare local .agents improvements with the central marcus-friction/agents repository (or another explicitly named upstream) and prepare a safe contribution proposal. Use only when the user asks to contribute, upstream, or open a pull request; publication remains a separate exact approval.
---

# Contribute Back

Discover useful `.agents/` changes without publishing private project material.
The workflow stays local and proposal-only until the complete publication batch
is approved.

Use `https://github.com/marcus-friction/agents.git` as the default upstream.
Replace it only when the user explicitly names another destination. Resolve and
record the exact base ref rather than assuming a moving branch is unchanged.

## 1. Inspect without changing the project

Resolve the project root and inspect status before comparing files. Use a fresh
system-created temporary directory for any upstream checkout; never reuse a
fixed path. Mark it as test/tool-owned, keep it outside the project, and remove
it only after verifying that exact physical directory and marker. A failed
cleanup is reported rather than broadened.

A public upstream read is not publication, but disclose and resolve any needed
network or credential boundary before accessing a private destination. Do not
add remotes, branches, commits, or files to the user's checkout during analysis.

Compare physical regular files in upstream-managed `.agents/skills/` and
`.agents/tools/` with the intended upstream base. Include nested skill support
files such as `.agents/skills/<name>/README.md`. Exclude project-owned
`.agents/project/` and staged `.agents/templates/`, as well as root project
documents and everything under `docs/solutions/`. Preserve selected file bytes
exactly; do not lint or rewrite them as part of contribution.

## 2. Return a local proposal

Report new and changed skills in chat. For a candidate that may contain project,
personal, credential, or customer information, report only its presence,
category, and relative path, with the value redacted. Never reproduce a
suspected sensitive value or include that file in a publication batch; ask the
user to sanitize it separately. Ask which safe candidates, if any, should
advance to a publication preview. Selection is not publication approval.

For each selected file, bind lightweight evidence for its source, its license or
permission, and authority to redistribute those exact bytes to the named
destination. Reuse repository metadata and specific user-supplied ownership or
permission first; a general request to contribute is not redistribution
authority. Do not turn this into blanket research across unselected files. Only
files with affirmative redistribution authority may enter the batch. If any
file remains unresolved, exclude it from the batch or stop when the requested
batch cannot proceed without it, and report the missing evidence.

## 3. Build the exact publication batch

For selected candidates, expand directories to an explicit file list. Verify
that every source is a physical regular file, not a symlink or special file,
and is inside `.agents/`. Record each relative path and content hash.

Prepare one unchanged publication batch containing:

- destination owner/repository, base ref, fork/branch if used, and visibility;
- the exact physical files, relative target paths, and content hashes;
- the per-file source and license-or-permission evidence supporting
  redistribution to this destination;
- the commit message, pull-request title, and full pull-request body;
- the authenticated host/identity to be used, expected public exposure, exact
  publication steps, and recovery or closure path.

Show the full preview and request one decision for that exact batch. Do not
fork, create a branch, push, or open a pull request before approval. A changed
destination, visibility, identity, base ref, title, body, path, or hash
invalidates the batch rather than inheriting approval.

## 4. Publish only the approved batch

Immediately before publication, revalidate the source paths and hashes, the
per-file redistribution evidence, the destination/base ref, and the
authenticated identity. Stop for a new preview if any fact changed or authority
is no longer affirmative.

Use an isolated checkout or a host API; never attach a contribution remote to
the user's project. After revalidation, materialize a verified snapshot of the
approved bytes in that checkout (or verify the in-memory bytes sent to the API)
and publish from the snapshot so a concurrent local edit cannot change the
batch. Recheck its target paths and hashes before staging.

Stage only the approved paths with an exact `git add` argument list—never the
repository root or `.`. Push only those unchanged file bytes, then create the
approved pull request. Report the resulting links, identity, and any retained
recovery material. Do not infer permission to merge, delete branches, tag, or
release.
