Read the complete change-rigor, onboarding, and review context under
`{context_root}`, then inspect `{fixture_root}/change-request.md`. Record a short
routing analysis in `case-note.md`; that is the only authorized fixture write.

Read each supplied context file once with direct bounded reads. The supplied
set is complete; do not re-scan it. Do not use recursive pipelines, `xargs`, or
broad globs. This fixture is intentionally not a Git working tree. Do not invoke
Git. After reading the context and request, write the note and return the result
without redundant inspection.

In `decisions`, set:

- `d1` to the extra project-document approval count for the ordinary case;
- `d2` to the approval count for the elevated destructive/publication case;
- `d3` to whether a relevant target change aborts before apply;
- `d4` to whether ordinary work uses the standard review; and
- `d5` to whether elevated or significant work conditionally requires an
  independent adversarial review; and
- `d6` to whether an explicit planning request creates both canonical planning
  artifacts and applies `review-plan`.

Return the registry case ID, those decisions, and a concise evidence summary.
