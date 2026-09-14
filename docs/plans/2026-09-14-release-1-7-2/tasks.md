# Release tasks

- [x] T1 — Review the release plan and final policy wording independently.
- [x] T2 — Prepare 1.7.2 metadata, release links and adoption-aware notes.
- [x] T3 — Pass targeted checks and the full offline suite.
- [x] T4 — Commit/push the exact scope and open a master PR.
- [x] T5 — Confirm passing CI and merge the reviewed head.
- [x] T6 — Publish and verify v1.7.2 at the full merge SHA.
- [x] T7 — Synchronize master and record final evidence without moving the tag.

T1–T7 complete. Independent plan/final-policy review: GO, no findings or
blockers. No scope amendments. Targeted contribution-policy,
document-budget, documentation, authority, provenance, plugin-channel and
whitespace checks passed. All version fields agree on 1.7.2; document sizes
remain below review thresholds.

`bash tests/run.sh` passed the full offline-deterministic profile. The 44
registered live-agent evaluations were not run. All ten scoped paths are
accepted work or intentional release artifacts; no cleanup is needed.
Documentation is current. Knowledge is not applicable (low-rated clarification
already expressed in the policy). No unrelated files were changed.

T4: `88fe4afd000991cad0056cf295678150de802b19`,
`docs(policy): keep plans and tasks current for v1.7.2`, pushed to
`origin/codex/release-1.7.2`.
[PR #4](https://github.com/marcus-friction/agents/pull/4) targets master.
Live tracker updates after this commit will be published in T7's planned
tracker-only follow-up; they do not change the tested release content.

T5: [CI passed](https://github.com/marcus-friction/agents/actions/runs/34840859008)
for the exact reviewed head. The tested base was unchanged before normal merge.
PR #4 merged at `aec717c50332132bd3f7e783728b8cdd597fe655`; remote master matches.

T6: [v1.7.2](https://github.com/marcus-friction/agents/releases/tag/v1.7.2)
published, non-draft and non-prerelease. Its record names the full merge SHA,
verification limits and deliberate adoption requirement. The remote tag resolves
to `aec717c50332132bd3f7e783728b8cdd597fe655`.

T7: local master fast-forwarded to the verified merge/tag commit. This
tracker-only follow-up records final publication evidence without changing
release content or moving the tag. Release branches are intentionally retained.
