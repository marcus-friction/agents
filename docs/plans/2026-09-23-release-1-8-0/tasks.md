# Release v1.8.0

- [x] T1 — Review this release plan to GO and incorporate every retained issue.
- [x] T2 — Create the release branch and synchronize version metadata, stable
  links, release index, adoption-aware notes, and the live tracker.
- [x] T3 — Review the complete release set and resolve all actionable findings.
- [x] T4 — Pass focused version, documentation, provenance, routing, authority,
  contribution-policy, whitespace, and full offline-suite verification.
- [x] T5 — Commit the exact release-preparation scope; preview and obtain the
  first exact decision for release-branch push and PR publication.
- [x] T6 — Push the exact release head and open the public `master` PR without
  including unrelated work.
- [x] T7 — Verify exact head/base and passing CI; obtain the owner's review and
  separate exact normal-merge decision, then merge and verify remote `master`.
- [x] T8 — Preview, obtain a separate exact decision for, publish, and verify
  latest stable v1.8.0 at the resolved merge SHA.
- [ ] T9 — Prepare and verify the tracker-only evidence commit; obtain the
  separate exact decision to push it and publish its public `master` PR.
- [ ] T10 — Verify the evidence PR's exact head/base and passing CI, obtain owner
  review and a separate exact normal-merge decision, then merge it; treat that
  host merge record as terminal evidence and do not move v1.8.0 or create a
  recursive bookkeeping commit.
- [ ] T11 — Preview cleanup separately; synchronize safe local state and delete
  branches only with exact authorization and no unique or unrelated work loss.
- [x] R180-T01 — Add behavior-level Findings, Results, and Decision table
  assertions to review/adversarial live cases, including a no-findings row;
  prove the grader change red then green, run affected cases 3/3, and rerun the
  focused contracts plus `bash tests/run.sh`.
- [x] R180-002 — Move the mandatory adversarial scenario-bank context from the
  unchanged independence case to the new table-output case, rerun that case at
  current/comparison 3/3, and repeat focused plus full verification.
- [x] R180-T02 — Pin the adversarial table-output case's mandatory scenario-bank
  context in the deterministic profile contract so the live-evidence defect
  cannot recur silently.

Current release source: `a139aa4f5330761381aeba0c72728ba98d03ff20`
on `fix/wrap-commit-preview`. Latest stable release: v1.7.2 at
`aec717c50332132bd3f7e783728b8cdd597fe655`. The untracked generalized lifecycle
plan is preserved as unrelated work and excluded from this release increment.

T1: Independent review converged to GO after splitting every not-yet-known R2
identity into its own authorization gate, adding a PR-safe terminal-evidence
route, allowing only planned release metadata in the previously reviewed
ecosystem reference, defining owner review after CI, and naming exact checks.

T2: Created `feature/release-1.8.0`. `VERSION`, both plugin manifests, README,
the ecosystem reference, and `docs/releases/2026-09-23-review-and-wrap-handoffs.md`
now agree on v1.8.0. The unrelated generalized lifecycle plan remains untracked
and excluded.

T3 review retained R180-T01 as a P2 release blocker: deterministic source
contracts do not prove that consuming agents render the new three-table output.
No other primary finding was retained. T3 remains open until the finding is
implemented, verified, and re-reviewed.

R180-T01 status: the normalized `contains` grader test followed a verified
red-green cycle and the focused offline profile passes. Live verification is
blocked after three attempts at 3,000, 6,000, and 12,000 rollout tokens per
execution all exhausted on the existing multi-skill fixture contexts. No
summary was release-qualified. Owner direction is required before changing the
test strategy or waiving this release gate.

Owner decision: replace the heavyweight prompt changes with two purpose-built
read-only cases covering a standard-review finding/Not-ready report and an
adversarial no-findings/missing-coverage/Withheld report. The lean cases are now
the required live evidence for R180-T01.

R180-002 status: re-review found the adversarial scenario-bank path attached to
the pre-existing independence case rather than the new table-output case. This
is a release blocker until the registry wiring and affected live evidence are
corrected and independently re-reviewed.

R180-T02 is the testing review's duplicate diagnosis of R180-002, with one
additional retained action: assert the mandatory scenario-bank context in the
offline profile contract.

R180-T01, R180-002, and R180-T02 are resolved. The corrected adversarial live
batch at `/tmp/agents-release-adversarial-evals.FYeYLa/` passed current and
comparison 3/3, its summary revalidated against the bound raw output, and both
primary and testing re-reviews returned Ready with no findings. The profile,
review, and adversarial-review contracts plus `git diff --check` pass. The full
offline suite passes with 47 registered live cases, completing T4.

T3: the fresh independent adversarial release challenge returned GO with no
findings. Its GO authorizes only completion of local release preparation; every
public or irreversible effect remains behind the separate exact gates below.

T5–T6: committed release preparation as
`1b2161db3dd2f1030d817101505c694a6abfd374`, confirmed remote `master` remained
`6c4b84dabfd925b6ddae2c1a2ec4f65fb0c26a95`, received the exact push-and-PR
decision, pushed `feature/release-1.8.0`, and opened public PR #5:
https://github.com/marcus-friction/agents/pull/5. GitHub reports the exact
approved head/base and a mergeable PR; CI is pending. Merge remains
unauthorized.

T7 status: `Offline deterministic` passed in 3m21s for exact PR head
`1b2161db3dd2f1030d817101505c694a6abfd374`. PR #5 is clean and mergeable;
remote `master` remains the reviewed base
`6c4b84dabfd925b6ddae2c1a2ec4f65fb0c26a95`. Awaiting the owner's post-CI
review of that exact head and separate normal merge-commit decision.

T7: the owner authorized the normal merge after CI. PR #5 merged at
2026-09-23T14:06:28Z as
`edca625bfad486d32071912c41563cbd54cc927e`; GitHub records the reviewed head
`1b2161db3dd2f1030d817101505c694a6abfd374`, original base
`6c4b84dabfd925b6ddae2c1a2ec4f65fb0c26a95`, and remote `master` now resolves
to the merge SHA. The release branch remains present. Tag/release publication
has not occurred.

T8: after the separate exact publication decision, `v1.8.0` was published at
2026-09-23T14:09:29Z as the latest, non-draft, non-prerelease release:
https://github.com/marcus-friction/agents/releases/tag/v1.8.0. The lightweight
tag, release target, latest-release record, and remote `master` all resolve to
`edca625bfad486d32071912c41563cbd54cc927e`. The release notes include the full
immutable SHA and installer `--ref` guidance.
