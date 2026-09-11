# Document Reconciliation

Use this reference only when an active project document conflicts with incoming
guidance, ownership is unclear, the target is non-regular, generated, or
multiply linked, meaning would be superseded, or the effect is elevated.

## Establish ownership and evidence

For each affected document, record:

- physical path, file type, link count, generated-file provenance, parent safety,
  and Git state;
- active meaning and the evidence that depends on it;
- incoming meaning and whether it applies to an adopted component;
- contradiction, weakening, deletion, move, or duplication;
- proposed disposition: retain, clarify, merge, relocate, supersede, or omit.

Do not infer ownership from headings or template markers. Do not read secrets.
Never write through symlinks or special files. Existing meaning remains active
until a concrete disposition is accepted.

For generated output, identify and change the physical authoring source, then
verify the documented regeneration path. For a regular file with more than one
link, inventory the known aliases and treat the shared-file effect as elevated;
do not write until the exact aliases, scope, and recovery path are confirmed.

## Resolve only material conflicts

Prefer the smallest patch that preserves project intent and gives one concept a
clear owner. Ask the user only when repository evidence cannot determine a
choice that changes behavior, authority, architecture, or an elevated boundary.
Keep unresolved alternatives explicit; do not silently select one.

Ordinary reconciliation requested by the user is R1 and needs no second
document-specific approval. Before an R2 effect, confirm the exact target,
action, exposure, credential class, and recovery path. If a relevant fact
changes before the effect, invalidate only that decision and present the new
fact.

Create a durable ledger only when the repository has a real audit or migration
need. A compact table is enough:

| Source meaning | Evidence | Disposition | Destination or unresolved choice |
|---|---|---|---|

## Apply and verify

Immediately before writing, recheck affected targets, authoring sources, link
counts, generated provenance, and parents. Abort if a target became a symlink or
special file, acquired another link, changed provenance, or if a relevant
conflict changed. Preserve unrelated dirty work and apply only the accepted
scope.

Afterward, check the resulting diff, links, commands, duplicated or lost
constraints, component applicability, and consistency with active project
rules. Report unresolved conflicts and do not commit or publish automatically.
