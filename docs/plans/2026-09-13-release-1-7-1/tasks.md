# Release tasks

- [x] Independently review plan and confirm WRAP-001 resolved.
- [x] Prepare version metadata, release docs and version-aware provenance check.
- [x] Pass targeted checks and full offline suite.
- [ ] Commit/push exact scope and open master PR.
- [ ] Confirm passing CI and merge the reviewed head.
- [ ] Publish and verify v1.7.1 at the full merge SHA.
- [ ] Synchronize master and record final evidence without moving the tag.

## Verification

Independent review: GO, no blockers; WRAP-001 resolved. Skill validation,
installed gh 2.45.0 login argument parsing (help only), provenance, plugin-channel,
documentation and whitespace checks passed. `bash tests/run.sh` passed the full
offline-deterministic profile. Document size warnings remained below review
thresholds. Registered live-agent evaluations (44 cases), real tool installation
and interactive login were not run.
