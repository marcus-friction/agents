# Release tasks

- [x] Independently review plan and confirm WRAP-001 resolved.
- [x] Prepare version metadata, release docs and version-aware provenance check.
- [x] Pass targeted checks and full offline suite.
- [x] Commit/push exact scope and open master PR.
- [x] Confirm passing CI and merge the reviewed head.
- [x] Publish and verify v1.7.1 at the full merge SHA.
- [x] Synchronize master and record final evidence without moving the tag.

## Verification

Independent review: GO, no blockers; WRAP-001 resolved. Skill validation,
installed gh 2.45.0 login argument parsing (help only), provenance, plugin-channel,
documentation and whitespace checks passed. `bash tests/run.sh` passed the full
offline-deterministic profile. Document size warnings remained below review
thresholds. Registered live-agent evaluations (44 cases), real tool installation
and interactive login were not run.

## Publication

- Release change: `065bf69d7038a49d1f43d9c50e6f1de9c9517659`,
  `fix(wrap): prepare CLI setup and release v1.7.1`.
- [PR #3](https://github.com/marcus-friction/agents/pull/3) merged after
  [CI passed](https://github.com/marcus-friction/agents/actions/runs/34744607122).
  The reviewed head and tested base were unchanged immediately before merge.
- Merge and verified tag commit:
  `56958802ded443d711bce458c67e0b8c913001b6`.
- [v1.7.1](https://github.com/marcus-friction/agents/releases/tag/v1.7.1)
  published as the latest, non-draft, non-prerelease release. Its record includes
  the full immutable SHA and verification limits.
- Local master fast-forwarded to the merge; this tracker-only follow-up records
  publication without moving the tag. Release branch intentionally retained.
- Workspace accounted for; documentation current; knowledge not applicable
  (low-rated CLI compatibility lesson already explained in setup guidance).
