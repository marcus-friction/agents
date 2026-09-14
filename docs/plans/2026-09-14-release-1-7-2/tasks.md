# Release tasks

- [x] T1 — Review the release plan and final policy wording independently.
- [x] T2 — Prepare 1.7.2 metadata, release links and adoption-aware notes.
- [x] T3 — Pass targeted checks and the full offline suite.
- [ ] T4 — Commit/push the exact scope and open a master PR.
- [ ] T5 — Confirm passing CI and merge the reviewed head.
- [ ] T6 — Publish and verify v1.7.2 at the full merge SHA.
- [ ] T7 — Synchronize master and record final evidence without moving the tag.

Current: T4 commit/push and PR. Independent plan/final-policy review: GO, no
findings or blockers. No scope amendments. Targeted contribution-policy,
document-budget, documentation, authority, provenance, plugin-channel and
whitespace checks passed. All version fields agree on 1.7.2; document sizes
remain below review thresholds.

`bash tests/run.sh` passed the full offline-deterministic profile. The 44
registered live-agent evaluations were not run. All ten scoped paths are
accepted work or intentional release artifacts; no cleanup is needed.
Documentation is current. Knowledge is not applicable (low-rated clarification
already expressed in the policy). No unrelated files were changed.
