# Contribution Publication Batch

Load this reference only when selected candidates may be published.

## Exact preview

Expand selected directories into explicit files. Verify each source is a
physical regular file, not a symlink or special file, and lies inside a
repository-declared managed distribution source. Record its relative source and
target path and content hash.

Prepare one unchanged publication batch containing:

- destination owner/repository, base ref, fork or branch when used, and
  visibility;
- exact physical files, target paths, and hashes;
- each selected file's source, license or permission, and redistribution
  authority;
- commit message, pull-request title, and full pull-request body;
- authenticated host and identity, expected exposure, exact publication steps,
  and recovery or pull-request closure path.

Show the complete preview and request one decision for that exact batch. Do not
fork, create a branch, push, or open a pull request before approval. A changed
destination, visibility, identity, base ref, title, body, path, or source hash
invalidates the batch and requires a new preview.

## Revalidate

Immediately before publication, revalidate source paths and hashes, per-file
redistribution evidence, destination and base ref, visibility, and the
authenticated identity. Stop when any fact changed or authority is no longer
affirmative. Never substitute a new file, path, identity, or destination into
an old approval.

## Publish only the approved batch

Use an isolated checkout or a host API; never attach a contribution remote to
the user's project. Materialize a verified snapshot of the approved bytes in
the isolated checkout, or verify the exact in-memory bytes sent through the
API. Recheck target paths and hashes before staging or sending them.

With Git, stage only approved target paths using an exact `git add` argument
list; never stage the repository root or `.`. Commit and push only the approved
snapshot, then create the approved pull request. Do not infer authority to
merge, delete branches, tag, release, or change the approved pull-request copy.

Report the resulting links, authenticated identity, and retained recovery
material. If publication stops partway through, report the last confirmed
external effect and the safe recovery or closure action; do not retry with a
changed batch.
