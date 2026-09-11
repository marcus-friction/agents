# Solved installer problem

The installer previously validated a destination pathname before replacement,
but a parent directory could be swapped for a symlink after lexical validation.
Substantial debugging established that the missing invariant was the filesystem
identity of each resolved parent. The fix validates resolved parents immediately
before mutation and a regression test reproduces the symlink swap.

The same replacement boundary is used by project and user installations, so the
failure can recur across repositories. A future maintainer searching the exact
symptom or invariant would benefit from the root-cause explanation. No existing
solution document captures it.
