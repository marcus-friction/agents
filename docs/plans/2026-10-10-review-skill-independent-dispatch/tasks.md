# Independent dispatch across review skills

- [x] Inventory all review-named skills and their current dispatch rules.
- [x] Define the bounded dispatch, no-recursion, fallback, and adversarial acceptance criteria.
- [x] Amend all eleven review skills in their normal workflow sections.
- [x] REVIEW-RSD-001 (P1, `.agents/skills/adversarial-review/SKILL.md`):
  require separate authority before a different-model route sends review data
  to an external provider; preserve the independent-executor gate.
- [x] REVIEW-RSD-002 (P2, `implementation-plan.md`): add tool-enabled dispatch
  smoke evidence or explicitly report unavailable behavior evidence instead of
  treating metadata and text contracts as execution proof.
- [x] REVIEW-RSD-003 (P2, direct architecture/performance/security review):
  accept a plan or target evidence when no code diff exists, and select
  applicability before dispatch.
- [x] Update the three stack persona digests in the accepted specialty payload
  manifest and verify the preservation test after the intended skill edits.
- [x] Inspect the full diff for authority and output-contract regressions.
- [x] Validate changed skills and run affected review contracts.
- [x] Run the complete offline suite and `git diff --check`.
- [x] Record the release-relevance and delivery handoff.
- [x] REVIEW-RSD-004 (P2, `.agents/skills/security-review/SKILL.md:17`;
  matching direct-review and stack-persona dispatch clauses): cover every
  already-delegated pass regardless of parent, and mark each child packet as
  an executor that must not delegate again. Direct specialty, `review-plan`,
  and stack-persona smoke passes each completed without a child spawn.
- [x] Complete the 2026-10-10 scoped `ma:review` and record its retained finding.
- [x] Prepare v1.13.0 version, plugin and marketplace metadata, stable install
  documentation, and release notes for the complete unreleased change.
- [x] Capture the High-rated reusable terminal-executor lesson under
  `docs/solutions/` and verify its links.
- [x] Run applicable verification after release preparation and refresh the
  redaction-safe accepted-path inventory.
- [x] Prepare the exact read-only topic-branch, PR, merge, release, checkpoint,
  and cleanup preview; leave Git and external effects pending exact authority.

Review and verification evidence on 2026-10-10: independent standards and
testing passes reviewed the eleven-skill diff. The standards pass found the
external-model authority gap in `adversarial-review`; the testing pass found
that static contracts alone cannot prove tool-level dispatch. Both findings
were corrected in the skill and plan. A direct `security-review` orchestrator
then spawned a fresh clean-context subagent with the bounded diff and rules;
the child completed without re-delegating, writing, or calling an external
service. This observes the available-subagent route for one specialty skill.
The earlier parent `review` also dispatched two fresh clean-context passes.
Tool-level no-subagent and failed-adversarial-executor routes were not exercised;
the existing decision evals cover those decisions but do not execute a
subagent. Those two tool-level behaviors remain unverified. All eleven skills
passed `quick_validate.py`. The first full offline-suite run passed the review
contracts and stopped at the specialty payload manifest because its three
stack persona digests still described the old bytes. The validator's generated
manifest differed only in those three hashes; they were refreshed and
`bash tests/specialty-preservation-test.sh` passed. A later full-suite run was
interrupted by the command host before a result. The final host-shell
`bash tests/run.sh` completed with exit code 0 and
`PROFILE SUMMARY offline-deterministic=passed live-agent-v2=not-run
registered-live-cases=82`; `git diff --check` passed. These consumer-visible
skills require a future versioned release. No commit, push, PR, tag, or release
was requested for this increment, so the current handoff is the uncommitted
workspace diff on `master`.

Remediation and verification on 2026-10-10: the four direct specialty skills,
three stack personas, and the standalone code-review method now stop every
received delegated pass from redelegating. Their parent packets, plus `review`,
`review-plan`, and `adversarial-review`, explicitly identify the recipient as
the terminal executor. A direct specialty pass, a `review-plan` security pass,
and a stack-security persona pass completed in fresh clean-context subagents
without further delegation or writes. The direct and `review-plan` passes were
rerun against the final skill text. These smokes checked authority and found no
new external-egress issue. All eleven skills passed structural
validation; affected review, workflow, specialty, and preservation contracts
passed. The final `bash tests/run.sh` passed with
`offline-deterministic=passed`, `live-agent-v2=not-run`, and 82 registered live
cases; `git diff --check` passed. The three stack persona payload hashes were
refreshed to match their final bytes. Existing behavioral decision evals were
not executed by the offline suite, and tool-level no-subagent and failed
adversarial-executor routes remain unverified.

Wrap preparation on 2026-10-10: release disposition is `required` for the
consumer-visible skill changes. v1.13.0 metadata, stable documentation, and
release notes are prepared in the accepted worktree. `compound` rated the
terminal-executor lesson High because the narrow parent-specific guard recurred
across specialty and stack persona skills; the reusable explanation is captured
in `docs/solutions/review-subagent-terminal-executor.md`. The final
`bash tests/run.sh` passed (`offline-deterministic=passed`, 82 registered live
cases not run); JSON metadata validation, documentation link checks, and
`git diff --check` passed. The 21 accepted paths had no sensitive-artifact
flags. The proposed `feature/independent-review-dispatch-v1.13.0` branch is
absent locally and remotely; `master` remains at the verified v1.12.0 release
commit. GitHub reports a public repository, merge commits enabled, and
automatic branch deletion disabled. One atomic commit, branch publication,
PR/checkpoint, human review, exact-head CI, merge, immutable tag/release, and
owned-branch cleanup remain pending exact authority and their respective gates.
