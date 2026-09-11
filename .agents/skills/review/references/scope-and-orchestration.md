# Review Scope and Orchestration

## Resolve the target

Use this precedence:

1. exact paths or review target in the user's request;
2. the accepted plan or current implementation increment;
3. an explicit branch, pull request, commit range, or `base:<ref>`; then
4. the current working change against the repository's evidenced base.

For a local review, inventory committed changes after the base, staged changes,
unstaged changes, and accepted in-scope untracked files. Name excluded untracked
and unrelated dirty paths without reviewing them. Conversation history can
identify the accepted increment, but an explicit dependency trace is required
before unrelated work enters scope.

For a remote branch or pull request, inspect the named ref through read-only Git
objects or the host API. Do not checkout or switch to the remote target, and do
not mix an unrelated local working tree into its findings. If the exact base,
head, or diff cannot be established, report the missing evidence.

Summarize intent from the request and accepted plan before reading for defects.
For an explicit requirement set, classify each item complete, partial, missing,
or equivalently met. An inferred requirement is context, not a new merge gate.

## Search for evidence

Start from changed hunks, then read the complete containing behavior and its
direct callers, callees, tests, configuration, and contracts. Prefer
symbol-aware or syntax-aware search when available, then exact text search.
Do not claim every caller or use was checked when dynamic dispatch, generated
code, or text-only search leaves that claim unproven.

## Select and dispatch reviewers

The orchestrator owns correctness and final synthesis. Select domain passes
from the actual change, not a fixed maximum roster. For every selected pass,
record the evidence that made it applicable.

When the execution environment supports subagents, prefer fresh clean-context
subagents for separable domain passes and run independent passes concurrently
within capacity. The same model can provide independent evidence when the
subagent receives only the review packet and has not seen prior reasoning or
conclusions. Merely changing the persona, prompt, or review order in the same
context is not independent.

The canonical workflow must also work without subagents. Run the pass directly
when delegation is unavailable, but label it a same-context perspective. It
cannot corroborate the orchestrator or promote confidence as an independent
witness.

Do not automatically invoke an external model, provider, or service. A skill
invocation changes review method, not egress authority.

## Collect before synthesis

Every started pass must reach a terminal result or a bounded failure. Do not
synthesize while a selected pass is still running. Capacity pressure queues a
pass; it is not reviewer failure. A tool error, unavailable executor, malformed
result, or bounded collection failure is **missing coverage**, not permission
for the orchestrator to invent the absent result.

Record each pass as completed, not applicable, or missing coverage. When a
required pass or its material evidence is missing, preserve usable findings but
withhold the overall verdict. A same-context fallback may add useful evidence;
it does not erase the coverage gap or become independent corroboration.

## Synthesize

Normalize results through `finding-contract.md`. Validate locations and hydrate
the evidence, consequence, correction, and verification before keeping a
finding. Drop malformed or ungrounded items and record the count in coverage.

Deduplicate mechanically similar and semantically identical reports, then sort
by severity, confidence, path, and line and assign stable identifiers. Keep
disagreements visible when the failure or fix path differs. Separate
Pre-existing findings before deciding the verdict.
