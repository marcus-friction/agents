# v1.8.0 — Review and wrap handoffs

Release date: 2026-09-23. Use the full commit SHA from the
[release record](https://github.com/marcus-friction/agents/releases/tag/v1.8.0)
with installer `--ref` for stable installation. `master` remains mutable.

Review handoffs now use the same compact Markdown table structure across the
standard and adversarial review skills:

- findings retain stable identifiers, severity, evidence, impact, correction,
  and verification fields;
- results keep requirements, review passes, tests, risks, and tracker outcomes
  independently visible; and
- one final decision table records the evidence-bounded verdict.

Generic wrap requests now reliably prepare an exact read-only Git preview after
completion gates resolve. The preview identifies atomic commit groups,
Conventional Commit messages, exact paths or reviewed hunks, and known push
facts, then asks once which Git effects to execute. A wrap still grants no
authority to commit or push, and explicit exclusions of both effects remain
fully local.

The offline deterministic suite covers both skill contracts and registers 47
live-agent cases. Focused generic-wrap and review-table evaluations passed all
three required runs, including exact preview, non-mutation, canonical table,
no-findings, and missing-coverage assertions. Other live-agent cases were not
run as part of the release verification.

Existing installations are not changed automatically. Edge installations can
update from `master`; stable installations should adopt the full immutable SHA
published in the v1.8.0 release record.
