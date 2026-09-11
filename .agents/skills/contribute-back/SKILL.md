---
name: contribute-back
description: Compare local agent-distribution improvements with a named upstream repository and prepare a safe contribution proposal. Use only when the user asks to contribute, upstream, or open a pull request; publication requires a separate exact batch approval.
---

# Contribute Back

Discover portable improvements without publishing project-owned or sensitive
material. Discovery and selection remain local and proposal-only; selection is
not publication approval.

## 1. Resolve comparison scope

Identify the project root, named destination repository, destination base ref,
and requested candidates. Use repository metadata when it establishes those
facts; do not assume a historical hard-coded upstream. If the destination or
base cannot be resolved, report the missing fact rather than comparing against
an arbitrary repository.

Inspect the project rules or distribution manifest for repository-declared
managed distribution sources. Compare only those roots. In this repository that
includes `.agents/skills/` and `project-templates/`; another repository may
declare a different set. Include nested support files such as
`.agents/skills/<name>/README.md`.

Exclude project-owned `.agents/project/`, staged `.agents/templates/`, root
project documents, generated output, and everything under `docs/solutions/`.
Treat removals as candidates only when the user explicitly includes them.

## 2. Inspect safely

Inspect project status first and do not add remotes, branches, commits, or
files to the user's checkout. A public upstream read is not publication. Before
accessing a private destination, resolve the necessary network and credential
boundary without exposing credential values.

Use a fresh system-created temporary directory for a checkout. Mark it as
test/tool-owned, keep it outside the project, and clean up only after verifying
that exact physical directory and marker. Report cleanup failure instead of
broadening deletion.

Compare physical regular files against the intended upstream base. Reject
symlinks and special files. Preserve candidate bytes exactly; do not lint,
generalize, or rewrite them during discovery. If upstream compatibility would
require adaptation, report that as separate future work rather than silently
changing the selected source.

## 3. Propose safe candidates

Report added, changed, and explicitly requested removed files with a concise
reason each might benefit the destination. When the request already identifies
the candidates, use that selection without another gate. Ask which safe
candidates should advance only when selection is materially ambiguous.

For a candidate that may contain project, personal, credential, or customer
information, report only its presence, category, and relative path, with the
value redacted. Never reproduce a suspected sensitive value or include the file
in a publication batch; ask the user to sanitize it separately.

For each selected file, bind its source, license or permission, and affirmative
authority to redistribute those exact bytes to the named destination. Reuse
repository licensing and specific ownership evidence before researching. Only
files with affirmative redistribution authority may enter the batch. If any
file remains unresolved, exclude it from the batch or stop when the requested
contribution cannot proceed without it.

If the user requested only comparison or a proposal, return the result in chat
and stop. If there are no safe differences, say so directly.

## 4. Preview and publish only when requested

When the user asks to publish selected candidates, read
`references/publication-batch.md` completely. Build and show one exact batch,
then obtain one approval for that unchanged batch. Do not infer publication
authority from discovery, candidate selection, a prior general contribution
request, or this skill's invocation.
