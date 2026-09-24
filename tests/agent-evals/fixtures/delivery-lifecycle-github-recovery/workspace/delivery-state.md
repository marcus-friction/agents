# GitHub publication collision and partial resume

The verified integrated revision is `merge-sha-9001`.

Record A intended `v1.9.0`, but the peeled remote tag already resolves to
`other-sha-4004`. No destructive correction was authorized.

Record B intended `v1.9.1`. Its peeled remote tag resolves to
`merge-sha-9001`, but GitHub release publication timed out and remains unknown.
The tag effect is complete; only `hosted release publication` could remain after
read-only reconciliation. Stored approval is historical evidence, and no
current mutation authority exists.
