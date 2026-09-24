# Bulk installer temporary-cleanup race

- [x] T1 — Reconcile both failed GitHub runs, local repetitions, current source,
  PR #7, and checkpoint `5804270691`; confirm the failure is the single-attempt
  cleanup boundary rather than an installer-effect regression.
- [x] T2 — Add the narrow one-time cleanup-failure regression and prove it fails
  against current `cleanup_work` for the expected reason.
  Two harness-only issues were corrected first: a missing real-`rm` fallback and
  an over-broad descendant match. With the wrapper narrowed to the exact
  bulk-work root, the original production function completed installation and
  artifact preparation, then failed solely on the injected first removal.
- [x] T3 — Implement only the bounded exact-path cleanup retry and prove the
  regression green, including persistent-failure and path-safety behavior.
  `cleanup_work` now revalidates the exact physical owned directory before each
  of three attempts, pauses briefly only between failures, succeeds only when
  removal completes, and reports persistent or unsafe targets. The targeted
  regression is green for one-time recovery and three-attempt exhaustion.
- [x] T4 — Pass repeated targeted runs, `git diff --check`, and the complete
  offline deterministic suite.
  The first green targeted run and three consecutive repetitions passed, as did
  shell syntax and whitespace checks. The complete suite reported
  `offline-deterministic=passed` with 66 registered live-agent cases.
- [x] T5 — Complete the repository-local remediation record for the terminal
  handoff. The resulting commit identity, push, checkpoint update, and exact-head
  CI result are external delivery evidence and belong in PR #7's checkpoint and
  the final report. Stop before integration, release, deployment, or
  current-branch cleanup.
