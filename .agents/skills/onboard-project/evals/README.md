# Onboard-project executable evaluations

These evaluations use disposable Git repositories so preservation claims are
checked against bytes, Git state, and raw symlink targets rather than judged
from prose alone.

## Run protocol

For each case, create a repository and an external state snapshot:

```bash
bash evals/scripts/create-fixture.sh CASE /tmp/onboard-CASE /tmp/onboard-CASE-state
```

Run the prompt from `evals.json` with the selected skill version and save the
agent's report outside the fixture repository. R1/R2 cases present their
semantic summary, relevant ledger, and exact diff in one combined decision. R3
conflict, dirty, symlink, deletion, weakening, and supersession cases retain
separate gates. Case 4 is a two-turn R2 run: approve the combined proposal,
then let the agent apply it.

Verify both repository state and report evidence:

```bash
bash evals/scripts/verify-eval.sh \
  CASE /tmp/onboard-CASE /tmp/onboard-CASE-state /tmp/onboard-CASE-report.md
```

Reports must bind factual claims to the frozen fixture using exact, standalone
records:

```text
Evidence-SHA256: relative/path <64-character-lowercase-SHA-256>
Evidence-Symlink: relative/path <raw-readlink-target>
Evidence-Claim: claim-id relative/path <SHA-256> <normalized-observed-value>
```

R2 proposal reports must also contain exactly one fenced `diff` block. The
verifier checks that the patch is syntactically valid, applies in a scratch copy
of the untouched fixture, creates regular `100644` files at exactly the allowed
documentation targets, and contains the fixture's minimum component, status,
and policy meanings. Structured claims bind a normalized observation to its
physical source and exact hash. Mentioning an “exact unified diff” or repeating
source keywords without those records is not evidence.

The verifier rejects pre-approval mutations, changes to the dirty baseline,
symlink replacement or retargeting, missing conflict evidence, and changes
outside the one explicitly approved README patch.

## Comparison evidence

Generate reports, `grading.json`, timing data, and aggregate benchmarks from the
current `evals.json` and fixtures. Use the committed pre-amendment skill snapshot
as the baseline rather than an improvised no-skill prompt, because the regression
of interest is the previous behavior. Generated evidence is deliberately not
vendored from another distribution; publish only results produced from these
adapted Laravel/Nuxt fixtures and identify unavailable timing or token telemetry.
