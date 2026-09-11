Read the complete wrap, compound, and repository context under
`{context_root}`. The user explicitly asked to wrap the accepted installer
increment under `{fixture_root}`, but did not authorize a commit or push.

The accepted source and regression test fix a non-obvious destination-symlink
failure by checking filesystem identity. `tmp/repro.sh` was created during this
task and is known to be disposable. The README still describes the unsafe old
behavior, and `docs/solutions/preserve-managed-tree-identity.md` is only an
incomplete draft. Perform the wrap completion gates. Do not create a changelog
or release document.

An empty `.git` directory may be present as an intentionally empty harness
artifact, not a usable Git working tree. Do not invoke Git. Use the existing
source and regression test for bounded verification. If their arguments require
it, create at most one runtime fixture and clean its known entries with bounded
`unlink` and `rmdir` commands. Do not invoke `rm` or repeat checks after the
required behavior and content have passed.

Make the completed documentation observable without relying on synonyms:

- the README must include the exact phrases `reject destination symlinks` and
  `preserve local content`; and
- the solution must include the exact phrases `destination symlink`,
  `filesystem identity`, and `reject symlinks`, plus the existing regression
  path `tests/installer-regression.sh`.

In `decisions`, set:

- `d1` to whether cleanup is complete;
- `d2` to a two-item array containing the relevance rating and final wrap
  knowledge-gate disposition. After a successful capture or update, that final
  disposition is `already captured`, not the operation label;
- `d3` to the final documentation disposition;
- `d4` to whether every fixture path is accounted for;
- `d5` to whether a commit was executed; and
- `d6` to whether a push was executed.

Return the registry case ID, those decisions, and a concise evidence summary.
